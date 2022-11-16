/**
Halftone Conversion for ReShade
By: Lord Of Lunacy
This shader attempts to emulate an amplitude based CMYK halftoning similar to that of offset printing.
https://en.wikipedia.org/wiki/Halftone
*/

#define PI 3.14159265
#define ASPECT_RATIO float2(float(BUFFER_WIDTH) / float(BUFFER_HEIGHT), 1)

texture BackBuffer:COLOR;


sampler sBackBuffer{Texture = BackBuffer;};

uniform float Strength<
		ui_type = "slider";
		ui_label = "Strength";
		ui_tooltip = "Changes how much of the color is from the dots vs. the original image.";
		ui_min = 0; ui_max = 1;
		ui_step = 0.001;
> = 1;
	
uniform float KStrength<
		ui_type = "slider";
		ui_label = "K-Strength";
		ui_tooltip = "Changes how much K is used to subtract from the color dots";
		ui_min = 0; ui_max = 1;
		ui_step = 0.001;
> = 0.5;

uniform float3 PaperColor<
		ui_type = "color";
		ui_label = "Paper Color";
		ui_min = 0; ui_max = 1;
> = 1;
	
uniform float Angle<
	ui_type = "slider";
	ui_label = "Angle";
	ui_tooltip = "Changles the angle that the dots are laid out in, helps with aliasing patterns.";
	ui_min = 0; ui_max = 1;
	ui_step = 0.001;
> = 0.33;

uniform float Scale<
		ui_type = "slider";
		ui_label = "Scale";
		ui_tooltip = "Changes the size of the dots in the halftone pattern.";
		ui_min = 1; ui_max = 9;
		ui_step = 1;
> = 3;

uniform bool SuperSample = true;



// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

float2x2 rotationMatrix(float angle)
{
	float2 trig;
	sincos(angle, trig.x, trig.y);
	
	return float2x2(float2(trig.x, -trig.y), float2(trig.y, trig.x));
}

float2 scaledTexcoord(float2 texcoord, float angle, float scale)
{
	float2x2 rot = rotationMatrix(angle);
	

	float2 scaledTexcoord = mul((texcoord) * ASPECT_RATIO, rot);
	scaledTexcoord = (round(scaledTexcoord / scale)) * scale;
	scaledTexcoord = mul(scaledTexcoord, transpose(rot)) / ASPECT_RATIO;
	
	return scaledTexcoord;
}

float4 sRGBToCMYK(float3 sRGB)
{
	float4 cmyk;
	cmyk.xyz = saturate(PaperColor - sRGB);
	cmyk.w = (min(min(cmyk.x, cmyk.y), cmyk.z)) * KStrength;
	cmyk.xyz = (PaperColor - sRGB - cmyk.w) / (1 - cmyk.w);
	return saturate(cmyk);
}

float coveragePercent(float2 dotCenter, float2 pixelCenter, float tonalValue, float scale)
{
	//Dots meet at 70% tonal coverage
	float radius = (scale * tonalValue * 0.5) / 0.7;
	
	float2 fromCenter = (pixelCenter - dotCenter) * ASPECT_RATIO;
	
	float dist = length(fromCenter);
	
	float wd = fwidth(dist) * sqrt(0.5);
	//wd = dist * 3 / float(BUFFER_HEIGHT);
	return smoothstep(radius+wd, radius-wd, dist);				  
}

float4 CMYKSample(const float2 texcoord, const float scale)
{
	float4 output;
	
	float2 coord;
	float4 value;
	
	output = 0;
	float2 rotatedCoord = mul(texcoord * ASPECT_RATIO, rotationMatrix(PI/4)) / ASPECT_RATIO;
	coord = scaledTexcoord(texcoord.xy, 0 + Angle, scale);
	value = sRGBToCMYK(tex2D(sBackBuffer, coord).rgb);
	output.z = coveragePercent(coord, texcoord, value.z, scale);
	
	coord = scaledTexcoord(texcoord.xy, PI/12 + Angle, scale);
	value = sRGBToCMYK(tex2D(sBackBuffer, coord).rgb);
	output.x = coveragePercent(coord, texcoord, value.x, scale);
	
	coord = scaledTexcoord(texcoord.xy, PI/4 + Angle, scale);
	value = sRGBToCMYK(tex2D(sBackBuffer, coord).rgb);
	output.w = coveragePercent(coord, texcoord, value.w, scale);
	
	coord = scaledTexcoord(texcoord.xy, (5*PI)/12 + Angle, scale);
	value = sRGBToCMYK(tex2D(sBackBuffer, coord).rgb);
	output.y = coveragePercent(coord, texcoord, value.y, scale);
	
	return output;
}

void OutputPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 output : SV_TARGET0)
{
	float scale = (1 / (BUFFER_HEIGHT / Scale));
	
	output = 0;
	
	float4 values[4];
	float2 coords[4];
	
	
	for(int i = 0; i < 4; i++)
	{
		values[i] = sqrt(values[i]);
	}
	if(SuperSample)
	{
		
		[unroll]
		for(int i = 1; i <= 2; i++)
		{
			[unroll]
			for(int j = 1; j <= 2; j++)
			{
				float2 offset = (float2(i, j) / 3.0) - 0.5;
				offset *= float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
				output += CMYKSample(texcoord + offset, scale);
			}
		}
		output /= 4;
	}
	else
	{
	
		output += CMYKSample(texcoord, scale);
	}

	float4 value = sRGBToCMYK(tex2D(sBackBuffer, texcoord).rgb);
	
	output.xyz = (output.w > 0.99) ? 0 : output.xyz;
	output = lerp(value, output, Strength);
	//output.xyw = 0;
	output.rgb = ((1 - output.xyz) * (1 - output.w));
	output.rgb = (output.rgb - (1 - PaperColor));
	output.a = 1;
	
}

technique Halftone <ui_tooltip = "This shader emulates the CMYK halftoning commonly found in offset printing, \n"
								   "to give the image a printer-like effect.\n\n"
								   "Part of Insane Shaders\n"
								   "By: Lord Of Lunacy";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = OutputPS;
	}
}
