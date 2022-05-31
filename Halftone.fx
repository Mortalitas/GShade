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
	
uniform float Gamma<
	ui_type = "slider";
	ui_label = "Gamma";
	ui_tooltip = "Helps make the colors of the halftone conversion appear more accurate.";
	ui_min = 0; ui_max = 3;
	ui_step = 0.001;
> = 2.2;
	
uniform float Angle<
	ui_type = "slider";
	ui_label = "Angle";
	ui_tooltip = "Changles the angle that the dots are laid out in, helps with aliasing patterns.";
	ui_min = 0; ui_max = 1;
	ui_step = 0.001;
> = 0.09;

uniform float Scale<
		ui_type = "slider";
		ui_label = "Scale";
		ui_tooltip = "Changes the size of the dots in the halftone pattern.";
		ui_min = 1; ui_max = 9;
		ui_step = 1;
	> = 2;



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

void scaledTexcoord(float2 texcoord, float angle, float scale, out float2 scaledTexcoords[4])
{
	float2x2 rot = rotationMatrix(angle);
	
	float2 offset[4];
	
	offset[0] = 0;
	offset[1] = 1;
	offset[2] = float2(0, 1);
	offset[3] = float2(1, 0);
	
	for(int i = 0; i < 4; i++)
	{
		scaledTexcoords[i] = mul((texcoord) * ASPECT_RATIO, rot);
		scaledTexcoords[i] = (floor(scaledTexcoords[i] / scale) + offset[i]) * scale;
		scaledTexcoords[i] = mul(scaledTexcoords[i], transpose(rot)) / ASPECT_RATIO;
	}
	
}

float4 sRGBToCMYK(float3 sRGB)
{
	float4 cmyk;
	
	
	cmyk.w = 1 - max(max(sRGB.r, sRGB.g), sRGB.b);
	cmyk.xyz = (1 - sRGB - cmyk.w) / (1 - cmyk.w);
	return cmyk;
}

float coveragePercent(float2 dotCenter, float2 pixelCenter, float tonalValue, float scale)
{
	//dots in halftoning meet at 70%
	float radius = (scale * tonalValue * 0.5) / 0.7;
	
	float2 fromCenter = (pixelCenter - dotCenter) * ASPECT_RATIO / radius;
	
	float dist = length(fromCenter);
	
	float wd = dist * PI /  float(BUFFER_HEIGHT);
	
	return smoothstep(1 + wd, 1 - wd, dist);//coverage;				  
}

float4 CMYKSample(const float4 value[4], const float2 texcoord, const float scale)
{
	float4 output;
	
	float2 coords[4];
	
	output = 0;
	
	scaledTexcoord(texcoord.xy, 0 + Angle, scale, coords);
	output.z = coveragePercent(coords[0], texcoord, value[0].z, scale);
	output.z += coveragePercent(coords[1], texcoord, value[1].z, scale);
	output.z += coveragePercent(coords[2], texcoord, value[2].z, scale);
	output.z += coveragePercent(coords[3], texcoord, value[3].z, scale);
	
	scaledTexcoord(texcoord.xy, PI/12 + Angle, scale, coords);
	output.x = coveragePercent(coords[0], texcoord, value[0].x, scale);
	output.x += coveragePercent(coords[1], texcoord, value[1].x, scale);
	output.x += coveragePercent(coords[2], texcoord, value[2].x, scale);
	output.x += coveragePercent(coords[3], texcoord, value[3].x, scale);
	
	scaledTexcoord(texcoord.xy, PI/4 + Angle, scale, coords);
	output.w = coveragePercent(coords[0], texcoord, value[0].w, scale);
	output.w += coveragePercent(coords[1], texcoord, value[1].w, scale);
	output.w += coveragePercent(coords[2], texcoord, value[2].w, scale);
	output.w += coveragePercent(coords[3], texcoord, value[3].w, scale);
	
	scaledTexcoord(texcoord.xy, (5*PI)/12 + Angle, scale, coords);
	output.y = coveragePercent(coords[0], texcoord, value[0].y, scale);
	output.y += coveragePercent(coords[1], texcoord, value[1].y, scale);
	output.y += coveragePercent(coords[2], texcoord, value[2].y, scale);
	output.y += coveragePercent(coords[3], texcoord, value[3].y, scale);
	
	return output;
}

void OutputPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 output : SV_TARGET0)
{
	float scale = (1 / (BUFFER_HEIGHT / Scale));
	
	output = 0;
	
	float4 values[4];
	float2 coords[4];
	
	scaledTexcoord(texcoord.xy, 0, scale, coords);
	values[0] = sRGBToCMYK(tex2D(sBackBuffer, coords[0]).rgb);
	values[1] = sRGBToCMYK(tex2D(sBackBuffer, coords[1]).rgb);
	values[2] = sRGBToCMYK(tex2D(sBackBuffer, coords[2]).rgb);
	values[3] = sRGBToCMYK(tex2D(sBackBuffer, coords[3]).rgb);
	
	[unroll]
	for(int i = 0; i < 4; i++)
	{
		[unroll]
		for(int j = 0; j < 4; j++)
		{
			float2 offset = (float2(i, j) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) / 4) - (3 * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)) / 8;
			output += CMYKSample(values, texcoord + offset, scale);
		}
	}

	output /= 16;
	float4 value = sRGBToCMYK(tex2D(sBackBuffer, texcoord).rgb);
	
	output.xyz = (output.w > 0.99) ? 0 : output.xyz;
	output = pow(abs(output), 1/Gamma);
	output = lerp(value, output, Strength);
	
	output.rgb = ((1 - output.xyz) * (1 - output.w));
	output.a = 1;
	
}

technique Halftone <ui_tooltip = "This shader emulates the CMYK halftoning commonly found in offset printing, \n"
								   "to give the image a printer-like effect.\n\n"
								   "Warning: This shader is performance intensive as it internally performs calculations at 16x res.\n\n"
								   "Part of Insane Shaders\n"
								   "By: Lord Of Lunacy";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = OutputPS;
	}
}