/*
	Oilify Shader for ReShade
	
	By: Lord of Lunacy
	
	This shader applies a Kuwahara filter using an optimized method for extracting the image mean and variance
	seperably.
	
	Kuwahara filter. (2020, May 01). Retrieved October 17, 2020, from https://en.wikipedia.org/wiki/Kuwahara_filter
	
	Kyprianidis, J. E., Kang, H., &amp; Dã¶Llner, J. (2009). Image and Video Abstraction by Anisotropic Kuwahara Filtering.
	Computer Graphics Forum, 28(7), 1955-1963. doi:10.1111/j.1467-8659.2009.01574.x
*/

#include "ReShade.fxh"


#ifndef OILIFY_RADIUS
	#define OILIFY_RADIUS 7
#endif

#if OILIFY_RADIUS > 1023
	#undef OILIFY_RADIUS
	#define OILIFY_RADIUS 1023
#endif


#define OILIFY_RADIUS_SQUARED (OILIFY_RADIUS * OILIFY_RADIUS)

#ifndef OILIFY_ITERATIONS
	#define OILIFY_ITERATIONS 1
#endif

#if OILIFY_ITERATIONS > 4
	#undef OILIFY_ITERATIONS
	#define OILIFY_ITERATIONS 4
#endif

#define OILIFY_ITERATIONS_MACRO \
	pass Value\
	{\
		VertexShader = PostProcessVS;\
		PixelShader = ValuePS;\
		RenderTarget0 = Value;\
	}\
	\
	pass MeanAndVariance\
	{\
		VertexShader = PostProcessVS;\
		PixelShader = MeanAndVariancePS0;\
		RenderTarget0 = MeanAndVariance;\
	}\
	\
	pass MeanAndVariance\
	{\
		VertexShader = PostProcessVS;\
		PixelShader = MeanAndVariancePS1;\
		RenderTarget0 = Mean;\
		RenderTarget1 = Variance;\
	}\
	\
	pass KuwaharaFilter\
	{\
		VertexShader = PostProcessVS;\
		PixelShader = KuwaharaFilterPS;\
	}\

namespace KuwaharaFilter
{
texture BackBuffer : COLOR;
texture Value {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32f;};
texture MeanAndVariance {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16f;};
texture CoordNormals {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16f;};
texture Mean {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};
texture Variance {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};

sampler sBackBuffer {Texture = BackBuffer;};
sampler sValue {Texture = Value;};
sampler sMeanAndVariance {Texture = MeanAndVariance;};
sampler sMean {Texture = Mean;};
sampler sVariance {Texture = Variance;};
sampler sCoordNormals {Texture = CoordNormals;};

uniform float Strength<
	ui_type = "slider";
	ui_label = "Opacity";
	ui_tooltip = "Opacity of the Oilify effect";
	ui_min = 0; ui_max = 1;
	ui_step = 0.001;
> = 1;

uniform float SampleDistance<
	ui_type = "slider";
	ui_label = "Blending";
	ui_tooltip = "Changes how the image blends by adjusting the size of the sample patch.";
	ui_min = 1; ui_max = 8;
> = 2.5;

uniform bool Shear<
	ui_label = "Alternative Look";
	ui_tooltip = "Uses a shear transform to shape the sampling and add some directionality\n";
> = 0;

uniform int SampleCount<
	ui_type = "slider";
	ui_label = "Sample Count";
	ui_min = 1; ui_max = 30;
> = 15;

uniform int Anisotropy<
	ui_type = "radio";
	ui_items = "None \0 Depth \0 Gradient\0";
	ui_category = "Anisotropy";
> = 2;


//https://vec3.ca/bicubic-filtering-in-fewer-taps/
float3 BSplineBicubicFilter(sampler sTexture, float2 texcoord)
{
	float2 textureSize = tex2Dsize(sTexture);
	float2 coord = texcoord * textureSize;
	float2 x = frac(coord);
	coord = floor(coord) - 0.5;
	float2 x2 = x * x;
	float2 x3 = x2 * x;
	//compute the B-Spline weights
 
	float2 w0 = x2 - 0.5 * (x3 + x);
	float2 w1 = 1.5 * x3 - 2.5 * x2 + 1.0;
	float2 w3 = 0.5 * (x3 - x2);
	float2 w2 = 1.0 - w0 - w1 - w3;

	//get our texture coordinates
 
	float2 s0 = w0 + w1;
	float2 s1 = w2 + w3;
 
	float2 f0 = w1 / (w0 + w1);
	float2 f1 = w3 / (w2 + w3);
 
	float2 t0 = coord - 1 + f0;
	float2 t1 = coord + 1 + f1;
	t0 /= textureSize;
	t1 /= textureSize;
	
	
	return
		(tex2D(sTexture, float2(t0.x, t0.y)).rgb * s0.x
		 +  tex2D(sTexture, float2(t1.x, t0.y)).rgb * s1.x) * s0.y
		 + (tex2D(sTexture, float2(t0.x, t1.y)).rgb * s0.x
		 +  tex2D(sTexture, float2(t1.x, t1.y)).rgb * s1.x) * s1.y;

}


//https://atyuwen.github.io/posts/normal-reconstruction/
float3 NormalVector(float2 texcoord)
{
	float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
	float c;
	float4 h;
	float4 v;
	if(Anisotropy == 1)
	{
		c = ReShade::GetLinearizedDepth(texcoord);
		
		if(c == 0)
		{
			return 1;
		}
		
		h.x = ReShade::GetLinearizedDepth(texcoord - offset.xz);
		h.y = ReShade::GetLinearizedDepth(texcoord + offset.xz);
		h.z = ReShade::GetLinearizedDepth(texcoord - 2 * offset.xz);
		h.w = ReShade::GetLinearizedDepth(texcoord + 2 * offset.xz);
		
		v.x = ReShade::GetLinearizedDepth(texcoord - offset.zy);
		v.y = ReShade::GetLinearizedDepth(texcoord + offset.zy);
		v.z = ReShade::GetLinearizedDepth(texcoord - 2 * offset.zy);
		v.w = ReShade::GetLinearizedDepth(texcoord + 2 * offset.zy);
	}
	else if(Anisotropy == 2)
	{
		c = tex2Dlod(sValue, float4(texcoord, 0, 0)).x;

		h.x = tex2Dlod(sValue, float4(texcoord, 0, 0), int2(-1, 0)).x;
		h.y = tex2Dlod(sValue, float4(texcoord, 0, 0), int2(1, 0)).x;
		h.z = tex2Dlod(sValue, float4(texcoord, 0, 0), int2(-2, 0)).x;
		h.w = tex2Dlod(sValue, float4(texcoord, 0, 0), int2(2, 0)).x;
		
		v.x = tex2Dlod(sValue, float4(texcoord, 0, 0), int2(0, -1)).x;
		v.y = tex2Dlod(sValue, float4(texcoord, 0, 0), int2(0, 1)).x;
		v.z = tex2Dlod(sValue, float4(texcoord, 0, 0), int2(0, -2)).x;
		v.w = tex2Dlod(sValue, float4(texcoord, 0, 0), int2(0, 2)).x;
	}
	
	float2 he = abs(h.xy *h.zw * rcp(2 * h.zw - h.xy) - c);
	float3 hDeriv;
	
	if(he.x > he.y)
	{
		float3 pos1 = float3(texcoord.xy - offset.xz, 1);
		float3 pos2 = float3(texcoord.xy - 2 * offset.xz, 1);
		hDeriv = pos1 * h.x - pos2 * h.z;
	}
	else
	{
		float3 pos1 = float3(texcoord.xy - offset.xz, 1);
		float3 pos2 = float3(texcoord.xy - 2 * offset.xz, 1);
		hDeriv = pos1 * h.x - pos2 * h.z;
	}
	
	float2 ve = abs(v.xy *v.zw * rcp(2 * v.zw - v.xy) - c);
	float3 vDeriv;
	
	if(ve.x > ve.y)
	{
		float3 pos1 = float3(texcoord.xy - offset.zy, 1);
		float3 pos2 = float3(texcoord.xy - 2 * offset.zy, 1);
		vDeriv = pos1 * v.x - pos2 * v.z;
	}
	else
	{
		float3 pos1 = float3(texcoord.xy - offset.zy, 1);
		float3 pos2 = float3(texcoord.xy - 2 * offset.zy, 1);
		vDeriv = pos1 * v.x - pos2 * v.z;
	}
	
	return (normalize(cross(-vDeriv, hDeriv)) * 0.5 + 0.5);
}

void ValueBicubicPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float value : SV_TARGET0)
{
	if(Anisotropy == 2)
	{
		value = dot(BSplineBicubicFilter(sBackBuffer, texcoord), float3(0.299, 0.587, 0.114));
	}
	else discard;
}

void CoordinateNormalsPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float2 coordNormals : SV_TARGET0)
{
	if(Anisotropy != 0)
	{
	coordNormals = NormalVector(texcoord).rg;
	}
	else discard;
}

void ValuePS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float value : SV_TARGET0)
{
	value = dot(tex2D(sBackBuffer, texcoord).rgb, float3(0.299, 0.587, 0.114));
}

void MeanAndVariancePS0(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float2 meanAndVariance : SV_TARGET0)
{
	float value;
	float sum = 0;
	float squaredSum = 0;
	float2 coordNormals = 1;
	if(Anisotropy != 0)coordNormals = tex2D(sCoordNormals, texcoord).rg;
	for(int i = -(OILIFY_RADIUS / 2); i < ((OILIFY_RADIUS + 1) / 2); i++)
	{
			float2 offset = float2(i * BUFFER_RCP_WIDTH, 0);
			if(Anisotropy != 0) offset *= coordNormals;
			if(Shear && Anisotropy != 0) offset = float2(offset.x + offset.y * (coordNormals.x), offset.y + offset.x * (coordNormals.y));
			value = tex2D(sValue, texcoord + offset).r;
			float valueSquared = value * value;
			sum += value;
			squaredSum += valueSquared;
			
	}
	meanAndVariance = float2(sum, squaredSum);
}


void MeanAndVariancePS1(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float mean : SV_TARGET0, out float variance : SV_TARGET1)
{
	float2 meanAndVariance;
	float sum = 0;
	float squaredSum = 0;
	float2 coordNormals = 1;
	if(Anisotropy != 0)coordNormals = tex2D(sCoordNormals, texcoord).rg;
	for(int i = -(OILIFY_RADIUS / 2); i < ((OILIFY_RADIUS + 1) / 2); i++)
	{
			float2 offset = float2(0, i * BUFFER_RCP_HEIGHT);
			if(Anisotropy != 0) offset *= coordNormals;
			if(Shear && Anisotropy != 0) offset = float2(offset.x + offset.y * (coordNormals.x), offset.y + offset.x * (coordNormals.y));
			meanAndVariance = tex2D(sMeanAndVariance, texcoord + offset).rg;
			sum += meanAndVariance.r;
			squaredSum += meanAndVariance.g;
	}
	float sumSquared = sum * sum;
	
	mean = sum / OILIFY_RADIUS_SQUARED;
	variance = (squaredSum - ((sumSquared) / OILIFY_RADIUS_SQUARED));
	variance /= OILIFY_RADIUS_SQUARED;
	variance = saturate(1-abs(log10(sqrt(variance))) / pow(10, 0.4));
}

static const float PI = 3.14159;
void KuwaharaFilterPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float3 color : SV_TARGET0)
{
	float2 coord;
	float minimum = 1;
	float variance;
	float2 coordNormals = 1;
	if(Anisotropy != 0)coordNormals = tex2D(sCoordNormals, texcoord).rg;
	[unroll]
	for(int i = 0; i < 30; i++)
	{
		if(i < SampleCount)
		{
				float2 values;
				sincos((2 * i * PI) / float(SampleCount), values.y, values.x);
				float2 offset = length(float2(BUFFER_RCP_WIDTH * (OILIFY_RADIUS/(2*SampleDistance)), BUFFER_RCP_HEIGHT * (OILIFY_RADIUS/(2*SampleDistance)))) * values.xy;
				offset *= coordNormals;
				variance = tex2D(sVariance, texcoord + offset).r;
				minimum = min(variance, minimum);
				if(minimum == variance)
				{
					coord = texcoord + offset;
				}
		}
	}
	
	float y = tex2D(sMean, coord).r;
	float3 i = tex2D(sBackBuffer, texcoord).rgb;
	float cb = -0.168736 * i.r - 0.331264 * i.g + 0.500000 * i.b;
	float cr = +0.500000 * i.r - 0.418688 * i.g - 0.081312 * i.b;
    color = float3(
        y + 1.402 * cr,
        y - 0.344136 * cb - 0.714136 * cr,
        y + 1.772 * cb);
        
	color = lerp(i, color, Strength);
}

technique Oilify<ui_tooltip = "This shader applies a variation on the anisotropic Kuwahara filter to give an effect\n"
							  "similar to an oil painting.\n\n"
							  "OILIFY_RADIUS: Changes the size of the filter used.\n"
							  "OILIFY_ITERATIONS: Ranges from 1 to 4.";>
{

	pass Value
	{
		VertexShader = PostProcessVS;
		PixelShader = ValueBicubicPS;
		RenderTarget0 = Value;
	}
	pass CoordNormals
	{
		VertexShader = PostProcessVS;
		PixelShader = CoordinateNormalsPS;
		RenderTarget0 = CoordNormals;
	}
	OILIFY_ITERATIONS_MACRO
#if OILIFY_ITERATIONS > 1
	OILIFY_ITERATIONS_MACRO
#endif
#if OILIFY_ITERATIONS > 2
	OILIFY_ITERATIONS_MACRO
#endif
#if OILIFY_ITERATIONS > 3
	OILIFY_ITERATIONS_MACRO
#endif
}
}
	
	
