// Chance 'Valeour' Millar
// Updated for Reshade 4.0 on 17/01/2019
// Follow me on Twitter @ValeourM for whatever reasons you can imagine.
// Slider added & modified by Marot for ReShade 4.0 compatibility.

// Colour of the green screen
uniform int3 greenScreen <
    ui_label = "Green Screen Color";
    ui_min = 0;
    ui_max = 255;
> = int3(0, 255, 0);

// How far into the depth to be cut off.
uniform float depthCutoff <
	ui_type = "slider";
	ui_min = 0.97;
	ui_max = .987;
	ui_label = "Depth Cutoff Slider";
> = 0.97;

// Need the reshade header.
#include "Reshade.fxh"

// Pixel shader
void PS_GreenScreenDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float3 color : SV_Target)
{
	// Fairly standard shader. Get the colour, get the depth.
	// If the depth is less than the cutoff, change the colour to green.
	color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	// Reverse the depth
	float depth = 1 - ReShade::GetLinearizedDepth(texcoord).r;

	if( depth < depthCutoff )
	{
		color = greenScreen.rgb * 0.00392;
	}
}

technique GreenScreen_Tech
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_GreenScreenDepth;
	}
}