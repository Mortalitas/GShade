/**
 * Chromatic Aberration
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Distorts the image by shifting each color component, which creates color artifacts similar to those in a very cheap lens or a cheap sensor.
 *
 * Updated for Reshade 4.0
 */

uniform float2 Shift <
	ui_type = "slider";
	ui_min = -10; ui_max = 10;
	ui_tooltip = "Distance (X,Y) in pixels to shift the color components. For a slightly blurred look try fractional values (.5) between two pixels.";
> = float2(2.5, -0.5);
uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.5;

#include "ReShade.fxh"

float3 ChromaticAberrationPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color, colorInput = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// Sample the color components
	color.r = tex2D(ReShade::BackBuffer, texcoord + (BUFFER_PIXEL_SIZE * Shift)).r;
	color.g = colorInput.g;
	color.b = tex2D(ReShade::BackBuffer, texcoord - (BUFFER_PIXEL_SIZE * Shift)).b;

	// Adjust the strength of the effect
	return lerp(colorInput, color, Strength);
}

technique CAb
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromaticAberrationPass;
	}
}
