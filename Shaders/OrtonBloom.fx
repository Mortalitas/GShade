#ifndef ORTON_BLOOM_DOWNSCALE_BLUR_RES
	#define ORTON_BLOOM_DOWNSCALE_BLUR_RES 1	// [0 to 3]	Change to value higher than 0 to improve performance at high resolutions
												//			Recommended for 4K: 1 or 2. Leave at 0 for lower resolutions
#endif

uniform bool GammaCorrectionEnable <
	ui_label = "Enable Gamma Correction";
	toggle = true;
> = true;
uniform float BlurMulti <
	ui_label = "Blur Multiplier";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "Blur strength";
> = 1.0;
uniform int BlackPoint <
	ui_type = "slider";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "The new black point for blur texture. Everything darker than this becomes completely black.";
> = 60;
uniform int WhitePoint <
	ui_type = "slider";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "The new white point for blur texture. Everything brighter than this becomes completely white.";
> = 150;
uniform float MidTonesShift <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Adjust midtones for blur texture.";
> = -0.84;
uniform float BlendStrength <
	ui_label = "Blend Strength";
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.0;
	ui_tooltip = "Opacity of blur texture. Keep this value low, or image will get REALLY blown out.";
> = 0.07;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

texture OrtonGaussianBlurTex { Width = BUFFER_WIDTH / (1 + ORTON_BLOOM_DOWNSCALE_BLUR_RES); Height = BUFFER_HEIGHT / (1 + ORTON_BLOOM_DOWNSCALE_BLUR_RES); Format = RGBA8; };
sampler OrtonGaussianBlurSampler { Texture = OrtonGaussianBlurTex; };

texture OrtonGaussianBlurTex2 { Width = BUFFER_WIDTH / (1 + ORTON_BLOOM_DOWNSCALE_BLUR_RES); Height = BUFFER_HEIGHT / (1 + ORTON_BLOOM_DOWNSCALE_BLUR_RES); Format = RGBA8; };
sampler OrtonGaussianBlurSampler2 { Texture = OrtonGaussianBlurTex2; };

float CalcLuma(float3 color)
{
	if (GammaCorrectionEnable)
		return pow(abs((color.r*2 + color.b + color.g*3) / 6), 1/2.2);
	
	return (color.r*2 + color.b + color.g*3) / 6;
}

float3 GaussianBlur1(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	const float blurPower = CalcLuma(color);

	const float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	const float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * blurPower * BlurMulti).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * blurPower * BlurMulti).rgb * weight[i];
	}

	return saturate(color);
}

float3 GaussianBlur2(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
	float3 color = tex2D(OrtonGaussianBlurSampler, texcoord).rgb;
	const float blurPower = CalcLuma(color);

	const float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	const float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(OrtonGaussianBlurSampler, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * blurPower * BlurMulti).rgb * weight[i];
		color += tex2D(OrtonGaussianBlurSampler, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * blurPower * BlurMulti).rgb * weight[i];
	}

	return saturate(color);
}

float3 LevelsAndBlend(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float black_point_float = BlackPoint / 255.0;
	
	float white_point_float;
	if (WhitePoint == BlackPoint) // Avoid division by zero if the white and black point are the same
		white_point_float = 255.0 / 0.00025;
	else
		white_point_float = 255.0 / (WhitePoint - BlackPoint);
	
	float mid_point_float = (white_point_float + black_point_float) / 2.0 + MidTonesShift;
	if (mid_point_float > white_point_float)
		mid_point_float = white_point_float;
	else if (mid_point_float < black_point_float)
		mid_point_float = black_point_float;

	const float3 original = tex2D(ReShade::BackBuffer, texcoord).rgb;
	const float3 color = (tex2D(OrtonGaussianBlurSampler2, texcoord).rgb * white_point_float - (black_point_float * white_point_float)) * mid_point_float;

#if GSHADE_DITHER
	const float3 outcolor = saturate(max(0.0, max(original, lerp(original, (1 - (1 - saturate(color)) * (1 - saturate(color))), BlendStrength))));
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(max(0.0, max(original, lerp(original, (1 - (1 - saturate(color)) * (1 - saturate(color))), BlendStrength))));
#endif
}

technique OrtonBloom
{
	pass GaussianBlur1
	{
		VertexShader = PostProcessVS;
		PixelShader = GaussianBlur1;
		RenderTarget = OrtonGaussianBlurTex;
	}
	pass GaussianBlur2
	{
		VertexShader = PostProcessVS;
		PixelShader = GaussianBlur2;
		RenderTarget = OrtonGaussianBlurTex2;
	}
	pass LevelsAndBlend
	{
		VertexShader = PostProcessVS;
		PixelShader = LevelsAndBlend;
	}
}
