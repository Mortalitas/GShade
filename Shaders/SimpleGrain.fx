/*------------------.
| :: Description :: |
'-------------------/

Simple Grain PS version (version 1.0.10)

Copyright:
This code © 2018-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/4.0/
*/

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"
#include "ColorConversion.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

uniform float Intensity
<
	ui_type = "slider";
	ui_label = "Noise intensity";
	ui_min = 0f; ui_max = 1f; ui_step = 0.002;
> = 0.4;

uniform int Framerate
<
	ui_type = "slider";
	ui_label = "Noise framerate";
	ui_tooltip = "Zero will match in-game framerate";
	ui_step = 1;
	ui_min = 0; ui_max = 120;
> = 12;

/*---------------.
| :: Uniforms :: |
'---------------*/

uniform float Timer < source = "timer"; >;
uniform int FrameCount < source = "framecount"; >;

/*----------------.
| :: Functions :: |
'----------------*/

// Overlay blending mode
float Overlay(float LayerA, float LayerB)
{
	float MinA = min(LayerA, 0.5);
	float MinB = min(LayerB, 0.5);
	float MaxA = max(LayerA, 0.5);
	float MaxB = max(LayerB, 0.5);
	return 2*(MinA*MinB+MaxA+MaxB-MaxA*MaxB)-1.5;
}

// Noise generator
float SimpleNoise(float p)
{ return frac(sin(dot(p, float2(12.9898, 78.233)))*43758.5453); }

/*--------------.
| :: Shaders :: |
'--------------*/

// Shader pass
void SimpleGrainPS(
	float4 vois      : SV_Position,
	float2 TexCoord  : TEXCOORD,
	out float3 Image : SV_Target
)
{
	// Sample image
	Image = tex2D(ReShade::BackBuffer, TexCoord).rgb;
	// Mask out bright pixels  gamma: (sqrt(5)+1)/2
	const float GoldenAB = sqrt(5f)*0.5+0.5;
	float Mask = pow(
		abs(1f-ColorConvert::RGB_to_Luma(Image)),
		GoldenAB
	);
	// Calculate seed change
	float Seed = Framerate == 0
		? FrameCount
		: floor(Timer*0.001*Framerate);
	// Protect from enormous numbers
	// Seed = frac(Seed*0.0001)*10000;
	Seed %= 10000;
	// Generate noise*(sqrt(5)+1)/4 (to retain brightness)
	const float GoldenABh = sqrt(5f)*0.25+0.25;
	float Noise = saturate(SimpleNoise(Seed*TexCoord.x*TexCoord.y)*GoldenABh);
	Noise = lerp(0.5, Noise, Intensity*0.1*Mask);
	// Blend noise with image
	Image.rgb = float3(
		Overlay(Image.r, Noise),
		Overlay(Image.g, Noise),
		Overlay(Image.b, Noise)
	);
}

/*-------------.
| :: Output :: |
'-------------*/

technique SimpleGrain
<
	ui_label = "Simple Grain";
	ui_tooltip =
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 4.0";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = SimpleGrainPS;
	}
}
