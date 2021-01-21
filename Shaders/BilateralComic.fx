/*
	Bilateral Comic for ReShade
	By: Lord of Lunacy
*/

#include "ReShade.fxh"

texture BackBuffer : COLOR;
texture Sobel <Pooled = true;> {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};

sampler sBackbuffer {Texture = BackBuffer;};
sampler sSobel {Texture = Sobel;};

uniform float Sigma0 <
	ui_type = "slider";
	ui_category = "Bilateral";
	ui_label = "Spatial Blur Strength";
	ui_min = 0; ui_max = 2;
> = 0.5;

uniform float Sigma1 <
	ui_type = "slider";
	ui_category = "Bilateral";
	ui_label = "Gradient Blur Strength";
	ui_min = 0.001; ui_max = 10;
> = 10;

uniform bool UseAnisotropy <
	ui_category = "Bilateral";
	ui_label = "Use Anisotropy";
> = 1;

uniform float EdgeThreshold <
	ui_type = "slider";
	ui_category = "Edges";
	ui_label = "Edge Threshold";
	ui_min = 0; ui_max = 1.001;
> = 0.2;

uniform float EdgeStrength <
	ui_type = "slider";
	ui_category = "Edges";
	ui_label = "Edge Strength";
	ui_min = 0; ui_max = 2;
> = 1.4;

uniform bool QuantizeLuma <
	ui_category = "Quantization";
	ui_label = "Quantize Luma";
> = 1;

uniform int LevelCount<
	ui_type = "slider";
	ui_category = "Quantization";
	ui_label = "Quantization Depth";
	ui_min = 1; ui_max = 255;
> = 48;

uniform bool IgnoreSky<
	ui_category = "Quantization";
	ui_label = "Don't Quantize Sky";
> = 1;

float3 NormalVector(float2 texcoord)
{
	float3 offset = float3(BUFFER_PIXEL_SIZE, 0.0);
	float2 posCenter = texcoord.xy;
	float2 posNorth  = posCenter - offset.zy;
	float2 posEast   = posCenter + offset.xz;

	float3 vertCenter = float3(posCenter - 0.5, 1) * ReShade::GetLinearizedDepth(posCenter);
	float3 vertNorth  = float3(posNorth - 0.5,  1) * ReShade::GetLinearizedDepth(posNorth);
	float3 vertEast   = float3(posEast - 0.5,   1) * ReShade::GetLinearizedDepth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

void SobelFilterPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float edges : SV_Target0)
{
	float2 sums;
	float sobel[9] = {1, 2, 1, 0, 0, 0, -1, -2, -1};
	[unroll]
	for(int i = -1; i <= 1; i++)
	{
		[unroll]
		for(int j = -1; j <= 1; j++)
		{
			int2 indexes = int2((i + 1) * 3 + (j + 1), (j + 1) * 3 + (i + 1));
			float3 color = tex2D(sBackbuffer, texcoord, int2(i, j)).rgb;
			float x = dot(color * sobel[indexes.x], float3(0.333, 0.333, 0.333));
			float y = dot(color * sobel[indexes.y], float3(0.333, 0.333, 0.333));
			sums += float2(x, y);
		}
	}
	
	edges = saturate(length(sums));
}

void BilateralFilterPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
{
	float sigma0 = max(Sigma0, 0.001);
	float sigma1 = exp(Sigma1);
	color = float4(0, 0, 0, 1);
	float3 center = tex2D(sBackbuffer, texcoord).rgb;
	color += center; 
	float3 weightSum = 1;
	center = dot(center, float3(0.299, 0.587, 0.114)).xxx * 255;
	float2 normals;
	if(UseAnisotropy)
	{
		normals = (NormalVector(texcoord).xy);
	}
	else
	{
		normals = 1;
	}
	[unroll]
	for(int i = -1; i <= 1; i ++)
	{
		[unroll]
		for(int j = -1; j <= 1; j ++)
		{
			if(all(abs(float2(i, j)) != 0))
			{
				float2 offset = (float2(i, j) * normals.xy) * 3 / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
				float3 s = tex2D(sBackbuffer, texcoord + offset).rgb;
				float luma = dot(s, float3(0.299, 0.587, 0.114));
				float3 w = exp(((-(i * i + j * j) / (sigma0 * sigma0)) - ((center - luma) * (center - luma) / (sigma1 * sigma1))) * 0.5);
				color.rgb += s * w;
				weightSum += w;
			}
		}
	}
	color.rgb /= weightSum;
}


void OutputPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0)
{
	float sobel = tex2D(sSobel, texcoord).x;
	if(1 - sobel > (1 - EdgeThreshold)) sobel = 0;
	sobel *= exp(-(2 - EdgeStrength));
	sobel = 1 - sobel;
	color = tex2D(sBackbuffer, texcoord).rgba * sobel;
	if (QuantizeLuma == true)
	{
		float depth = ReShade::GetLinearizedDepth(texcoord);
		if(!IgnoreSky || depth < 1)
		{
			//color = round(color * LevelCount) / LevelCount;
			float luma = round(dot(color.rgb, float3(0.299, 0.587, 0.114)) * LevelCount)/LevelCount;//float(y) / 32;
			float cb = -0.168736 * color.r - 0.331264 * color.g + 0.500000 * color.b;
			float cr = +0.500000 * color.r - 0.418688 * color.g - 0.081312 * color.b;
			color = float3(
				luma + 1.402 * cr,
				luma - 0.344136 * cb - 0.714136 * cr,
				luma + 1.772 * cb);
		}
	}

		
}

technique BilateralComic<ui_tooltip = "Cel-shading shader that uses a combination of bilateral filtering, posterization,\n"
									  "and edge detection to create a comic book style effect in games.\n\n"
									  "Part of Insane Shaders\n"
									  "By: Lord of Lunacy";>
{	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = SobelFilterPS;
		RenderTarget0 = Sobel;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BilateralFilterPS;
	}
	
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BilateralFilterPS;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BilateralFilterPS;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = OutputPS;
	}
}