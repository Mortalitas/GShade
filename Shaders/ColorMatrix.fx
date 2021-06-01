/**
 * Color Matrix version 1.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * ColorMatrix allow the user to transform the colors using a color matrix
 */
 // Lightly optimized by Marot Satil for the GShade project.

uniform float3 ColorMatrix_Red <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Matrix Red";
	ui_tooltip = "How much of a red, green and blue tint the new red value should contain. Should sum to 1.0 if you don't wish to change the brightness.";
> = float3(0.817, 0.183, 0.000);
uniform float3 ColorMatrix_Green <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Matrix Green";
	ui_tooltip = "How much of a red, green and blue tint the new green value should contain. Should sum to 1.0 if you don't wish to change the brightness.";
> = float3(0.333, 0.667, 0.000);
uniform float3 ColorMatrix_Blue <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Matrix Blue";
	ui_tooltip = "How much of a red, green and blue tint the new blue value should contain. Should sum to 1.0 if you don't wish to change the brightness.";
> = float3(0.000, 0.125, 0.875);

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 ColorMatrixPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float3x3 ColorMatrix = float3x3(ColorMatrix_Red, ColorMatrix_Green, ColorMatrix_Blue);

#if GSHADE_DITHER
	const float3 outcolor = saturate(lerp(color, mul(ColorMatrix, color), Strength));
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(lerp(color, mul(ColorMatrix, color), Strength));
#endif
}

technique ColorMatrix
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ColorMatrixPass;
	}
}
