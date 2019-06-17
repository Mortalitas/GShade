/*
Filmic Sharpen PS v1.1.0 (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// Lightly optimized by Marot Satil for the GShade project.

  ////////////
 /// MENU ///
//////////// 	 

#ifndef ShaderAnalyzer
uniform float Strength <
	ui_label = "Sharpen strength";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 100.0; ui_step = 0.01;
> = 60.0;

uniform int Coefficient <
	ui_label = "Luma coefficient";
	ui_tooltip = "Change if objects with relatively same brightness but different color get sharpened";
	ui_type = "radio";
	ui_items = "BT.709 - digital\0BT.601 - analog\0";
> = 0;

uniform float Clamp <
	ui_label = "Sharpen clamping";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0; ui_step = 0.001;
> = 0.65;

uniform float Offset <
	ui_label = "High-pass offset";
	ui_tooltip = "High-pass cross offset in pixels";
	ui_type = "slider";
	ui_min = 0.01; ui_max = 2; ui_step = 0.002;
> = 0.1;

uniform bool Preview <
	ui_label = "Preview sharpen layer";
	ui_category = "Debug View";
> = false;
#endif

   //////////////
  /// SHADER ///
 //////////////

#include "ReShade.fxh"

// RGB to YUV709 luma
static const float3 Luma709 = float3(0.2126, 0.7152, 0.0722);
// RGB to YUV601 luma
static const float3 Luma601 = float3(0.299, 0.587, 0.114);

// Overlay blending mode
float Overlay(float LayerA, float LayerB)
{
	static float MinA = min(LayerA, 0.5);
	static float MinB = min(LayerB, 0.5);
	static float MaxA = max(LayerA, 0.5);
	static float MaxB = max(LayerB, 0.5);
	return 2.0 * (MinA * MinB + MaxA + MaxB - MaxA * MaxB) - 1.5;
}

// Sharpen pass
float3 FilmicSharpenPS(float4 vois : SV_Position, float2 UvCoord : TexCoord) : SV_Target
{
	static float2 Pixel = ReShade::PixelSize * Offset;
	// Sample display image
	static float3 Source = tex2D(ReShade::BackBuffer, UvCoord).rgb;

	static float2 NorSouWesEst[4] = {
		float2(UvCoord.x, UvCoord.y + Pixel.y),
		float2(UvCoord.x, UvCoord.y - Pixel.y),
		float2(UvCoord.x + Pixel.x, UvCoord.y),
		float2(UvCoord.x - Pixel.x, UvCoord.y)
	};

	// Choose luma coefficient, if False BT.709 luma, else BT.601 luma
	static float3 LumaCoefficient = bool(Coefficient) ? Luma601 : Luma709;

	// Luma high-pass
	float HighPass = 0.0;
	[unroll]
	for(int i=0; i<4; i++) HighPass += dot(tex2D(ReShade::BackBuffer, NorSouWesEst[i]).rgb, LumaCoefficient);
	HighPass = 0.5 - 0.5 * (HighPass * 0.25 - dot(Source, LumaCoefficient));

	// Sharpen strength
	HighPass = lerp(0.5, HighPass, Strength);

	// Clamping sharpen
	HighPass = (Clamp != 1.0) ? max(min(HighPass, Clamp), 1.0 - Clamp) : HighPass;

	static float3 Sharpen = float3(
		Overlay(Source.r, HighPass),
		Overlay(Source.g, HighPass),
		Overlay(Source.b, HighPass)
	);

	return Preview ? HighPass : Sharpen;
}

  //////////////
 /// OUTPUT ///
//////////////
	
technique FilmicSharpen < ui_label = "Filmic Sharpen"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FilmicSharpenPS;
	}
}
