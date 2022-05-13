/**
Filmic Sharpen PS v1.3.0 (c) 2018 Jakub Maximilian Fober

This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/4.0/.
*/


  ////////////
 /// MENU ///
////////////

uniform uint Strength <
	ui_type = "slider";
	ui_label = "Strength";
	ui_min = 1u; ui_max = 64u;
> = 32u;

uniform float Offset <
	ui_type = "slider";
	ui_label = "Radius";
	ui_tooltip = "High-pass cross offset in pixels";
	ui_min = 0.05; ui_max = 0.25; ui_step = 0.01;
> = 0.1;

uniform bool UseMask <
	ui_type = "input";
	ui_label = "Sharpen only center";
	ui_tooltip = "Sharpen only in center of the image";
> = false;

uniform float Clamp <
	ui_type = "slider";
	ui_label = "Clamping highlights";
	ui_min = 0.5; ui_max = 1.0; ui_step = 0.1;
	ui_category = "Additional settings";
	ui_category_closed = true;
> = 0.6;

uniform uint Coefficient <
	ui_type = "radio";
	ui_tooltip = "For digital video signal use BT.709, for analog (like VGA) use BT.601";
	ui_label = "YUV coefficients";
	ui_items = "BT.601 - analog\0BT.709 - digital\0";
	ui_category = "Additional settings";
> = 0u;

uniform bool Preview <
	ui_type = "input";
	ui_label = "Preview sharpen layer";
	ui_tooltip = "Preview sharpen layer and mask for adjustment.\n"
		"If you don't see red strokes,\n"
		"try changing Preprocessor Definitions in the Settings tab.";
	ui_category = "Debug View";
	ui_category_closed = true;
> = false;

  ////////////////
 /// TEXTURES ///
////////////////

#include "ReShade.fxh"

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
	AddressU = MIRROR;
	AddressV = MIRROR;
	#if BUFFER_COLOR_BIT_DEPTH != 10
		SRGBTexture = true;
	#endif
};

  /////////////////
 /// FUNCTIONS ///
/////////////////

// RGB to YUV709 luma
static const float3 Luma709 = float3(0.2126, 0.7152, 0.0722);
// RGB to YUV601 luma
static const float3 Luma601 = float3(0.299, 0.587, 0.114);

// Overlay blending mode
float Overlay(float LayerA, float LayerB)
{
	float MinA = min(LayerA, 0.5);
	float MinB = min(LayerB, 0.5);
	float MaxA = max(LayerA, 0.5);
	float MaxB = max(LayerB, 0.5);
	return 2f*((MinA*MinB+MaxA)+(MaxB-MaxA*MaxB))-1.5;
}

// Convert to linear gamma
float gamma(float grad) { return pow(abs(grad), 2.2); }

  //////////////
 /// SHADER ///
//////////////

// Sharpen pass
float3 FilmicSharpenPS(float4 pos : SV_Position, float2 UvCoord : TEXCOORD) : SV_Target
{
	// Sample display image
	float3 Source = tex2D(BackBuffer, UvCoord).rgb;

	// Generate and apply radial mask
	float Mask;
	if (UseMask)
	{
		// Center coordinates
		float2 viewCoord = UvCoord*2f-1f;
		viewCoord.y *= BUFFER_HEIGHT*BUFFER_RCP_WIDTH;
		// Generate radial mask
		Mask = Strength-min(dot(viewCoord, viewCoord), 1f)*Strength;
	}
	else Mask = Strength;

	// Get pixel size
	float2 Pixel = BUFFER_PIXEL_SIZE*Offset;

	// Sampling coordinates
	float2 NorSouWesEst[4] = {
		float2(UvCoord.x, UvCoord.y+Pixel.y),
		float2(UvCoord.x, UvCoord.y-Pixel.y),
		float2(UvCoord.x+Pixel.x, UvCoord.y),
		float2(UvCoord.x-Pixel.x, UvCoord.y)
	};

	// Choose luma coefficient, if False BT.709 luma, else BT.601 luma
	const float3 LumaCoefficient = bool(Coefficient) ? Luma709 : Luma601;

	// Luma high-pass
	float HighPass = 0f;
	[unroll]
	for(uint i=0u; i<4u; i++)
		HighPass += dot(tex2D(BackBuffer, NorSouWesEst[i]).rgb, LumaCoefficient);

	HighPass = 0.5-0.5*(HighPass*0.25-dot(Source, LumaCoefficient));

	// Sharpen strength
	HighPass = lerp(0.5, HighPass, Mask);

	// Clamp sharpening
	HighPass = Clamp!=1f? clamp(HighPass, 1f-Clamp, Clamp) : HighPass;

	float3 Sharpen = float3(
		Overlay(Source.r, HighPass),
		Overlay(Source.g, HighPass),
		Overlay(Source.b, HighPass)
	);

	return Preview? gamma(HighPass) : Sharpen;
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
		SRGBWriteEnable = true;
	}
}
