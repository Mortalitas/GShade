/**
  Vibrance
  by Christian Cann Schuldt Jensen ~ CeeJay.dk
 
  Vibrance intelligently boosts the saturation of pixels so pixels that had little color get a larger boost than pixels that had a lot.
  This avoids oversaturation of pixels that were already very saturated.

  History:

  Version 1.0 by Ceejay.dk
  - Original 
  Version 1.1 by CeeJay.dk
  - Introduced RBG balance to help colorblind users
  Version 1.1.1
  - Minor UI improvements for Reshade 3.x
  Version 1.1.2
  - Modified by Marot for ReShade 4.0 compatibility and lightly optimized for GShade.
 */

uniform float Vibrance <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Intelligently saturates (or desaturates if you use negative values) the pixels depending on their original saturation.";
> = 0.15;

uniform float3 VibranceRGBBalance <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 10.0;
	ui_label = "RGB Balance";
	ui_tooltip = "A per channel multiplier to the Vibrance strength so you can give more boost to certain colors over others.\nThis is handy if you are colorblind and less sensitive to a specific color.\nYou can then boost that color more than the others.";
> = float3(1.0, 1.0, 1.0);

/*
uniform int Vibrance_Luma <
	ui_type = "combo";
	ui_label = "Luma type";
	ui_items = "Perceptual\0Even\0";
> = 0;
*/

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 VibrancePass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float luma = dot(float3(0.212656, 0.715158, 0.072186), color);

	// Extrapolate between luma and original by 1 + (1-saturation) - current
	const float3 coeffVibrance = float3(VibranceRGBBalance * Vibrance);

#if GSHADE_DITHER
	const float3 outcolor = lerp(luma, color, 1.0 + (coeffVibrance * (1.0 - (sign(coeffVibrance) * (max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b)))))));
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp(luma, color, 1.0 + (coeffVibrance * (1.0 - (sign(coeffVibrance) * (max(color.r, max(color.g, color.b)) - min(color.r, min(color.g, color.b)))))));
#endif
}

technique Vibrance
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = VibrancePass;
	}
}
