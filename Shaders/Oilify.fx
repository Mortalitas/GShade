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
	#define OILIFY_RADIUS 5
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
texture Value {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
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
	ui_min = 1; ui_max = 4;
> = 1;

uniform bool ExtraSamples<
	ui_label = "Use more samples";
	ui_tooltip = "Use 9 samples instead of 4 for the mean of least variance selection";
> = 1;

uniform bool NoDepth<
	ui_label = "Disable anisotropy";
	ui_tooltip = "The shader no longer uses the depth buffer and disables the anisotropy\n"
				 "done by the shader.";
> = 0;

float3 RGBToHSV(float3 c)
{
    const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);

    float4 p;
	if (c.g < c.b)
		p = float4(c.bg, K.wz);
	else
		p = float4(c.gb, K.xy);
    
	float4 q;
	if (c.r < p.x)
		q = float4(p.xyw, c.r);
	else
		q = float4(c.r, p.yzx);

    const float d = q.x - min(q.w, q.y);
    const float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVToRGB(float3 c)
{
    const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    return c.z * lerp(K.xxx, saturate((abs(frac(c.xxx + K.xyz) * 6.0 - K.www)) - K.xxx), c.y);
}

void CoordinateNormalsPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float2 coordNormals : SV_TARGET0)
{
	if(NoDepth) discard;
	coordNormals = float2((ReShade::GetLinearizedDepth(float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y)) - ReShade::GetLinearizedDepth(float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y))), (ReShade::GetLinearizedDepth(float2(texcoord.x, texcoord.y - BUFFER_RCP_HEIGHT)) - ReShade::GetLinearizedDepth(float2(texcoord.x, texcoord.y + BUFFER_RCP_HEIGHT))));
	if(any(coordNormals != 0))
	{
		coordNormals = normalize(coordNormals);
	}
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
	float2 coordNormals = 0;
	if(!NoDepth)coordNormals = tex2D(sCoordNormals, texcoord).rg;
	for(int i = -(OILIFY_RADIUS / 2); i < ((OILIFY_RADIUS + 1) / 2); i++)
	{
			float2 offset = float2(i * BUFFER_RCP_WIDTH, 0);
			offset = float2(offset.x - offset.y * coordNormals.x, offset.y - offset.x * coordNormals.y);
			value = tex2D(sValue, texcoord + offset).r;
			sum += value;
			squaredSum += value * value;
			
	}
	meanAndVariance = float2(sum, squaredSum);
}


void MeanAndVariancePS1(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float mean : SV_TARGET0, out float variance : SV_TARGET1)
{
	float2 meanAndVariance;
	float sum = 0;
	float squaredSum = 0;
	float2 coordNormals = 0;
	if(!NoDepth)coordNormals = tex2D(sCoordNormals, texcoord).rg;
	for(int i = -(OILIFY_RADIUS / 2); i < ((OILIFY_RADIUS + 1) / 2); i++)
	{
			float2 offset = float2(0, i * BUFFER_RCP_HEIGHT);
			offset = float2(offset.x - offset.y * coordNormals.x, offset.y - offset.x * coordNormals.y);
			meanAndVariance = tex2D(sMeanAndVariance, texcoord + offset).rg;
			sum += meanAndVariance.r;
			squaredSum += meanAndVariance.g;
	}
	float sumSquared = sum * sum;
	
	mean = sum / OILIFY_RADIUS_SQUARED;
	variance = (squaredSum - ((sumSquared) / OILIFY_RADIUS_SQUARED));
	variance /= OILIFY_RADIUS_SQUARED;
}

void KuwaharaFilterPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float3 color : SV_TARGET0)
{
	float2 coord;
	float minimum = 1;
	float variance;
	float2 coordNormals = 0;
	for(int i = -1; i <= 1; i++)
	{
		for(int j = -1; j <= 1; j++)
		{
			if(ExtraSamples || (i != 0 && j != 0))
			{
				float2 offset = float2(i * BUFFER_RCP_WIDTH * (OILIFY_RADIUS/(2*SampleDistance)), j * BUFFER_RCP_HEIGHT * (OILIFY_RADIUS/(2*SampleDistance)));
				variance = tex2D(sVariance, texcoord + offset).r;
				minimum = min(variance, minimum);
				if(minimum == variance)
				{
					coord = texcoord + offset;
				}
			}
		}	
	}
	
	const float y = tex2D(sMean, coord).r;
	const float3 i = tex2D(sBackBuffer, texcoord).rgb;
	const float cb = -0.168736 * i.r - 0.331264 * i.g + 0.500000 * i.b;
	const float cr = +0.500000 * i.r - 0.418688 * i.g - 0.081312 * i.b;
    color = float3(
        y + 1.402 * cr,
        y - 0.344136 * cb - 0.714136 * cr,
        y + 1.772 * cb);
        
	//color = RGBToHSV(tex2D(sBackBuffer, texcoord).rgb);
	color = lerp(i, color, Strength);
	//color = RGBToHSV(tex2D(sBackBuffer, color).rgb);
}

technique Oilify<ui_tooltip = "This shader applies a variation on the anisotropic Kuwahara filter to give an effect\n"
							  "similar to an oil painting.\n\n"
							  "OILIFY_RADIUS: Changes the size of the filter used.\n"
							  "OILIFY_ITERATIONS: Ranges from 1 to 4.";>
{
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
	
	