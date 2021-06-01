/* 
SunsetFilter PS v1.0.0 (c) 2018 Jacob Maximilian Fober, 

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/
// Lightly optimized by Marot Satil for the GShade project.

uniform float3 ColorA <
	ui_label = "Colour (A)";
	ui_type = "color";
	ui_category = "Colors";
> = float3(1.0, 0.0, 0.0);

uniform float3 ColorB <
	ui_label = "Colour (B)";
	ui_type = "color";
	ui_category = "Colors";
> = float3(0.0, 0.0, 0.0);

uniform bool Flip <
	ui_label = "Color flip";
	ui_category = "Colors";
> = false;

uniform int Axis <
	ui_label = "Angle";
	ui_type = "slider";
	ui_step = 1;
	ui_min = -180; ui_max = 180;
	ui_category = "Controls";
> = -7;

uniform float Scale <
	ui_label = "Gradient sharpness";
	ui_type = "slider";
	ui_min = 0.5; ui_max = 1.0; ui_step = 0.005;
	ui_category = "Controls";
> = 1.0;

uniform float Offset <
	ui_label = "Position";
	ui_type = "slider";
  ui_step = 0.002;
	ui_min = 0.0; ui_max = 0.5;
	ui_category = "Controls";
> = 0.0;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

// Overlay blending mode
float Overlay(float Layer)
{
	const float Min = min(Layer, 0.5);
	const float Max = max(Layer, 0.5);
	return 2 * (Min * Min + 2 * Max - Max * Max) - 1.5;
}

// Screen blending mode
float3 Screen(float3 LayerA, float3 LayerB)
{ return 1.0 - (1.0 - LayerA) * (1.0 - LayerB); }

void SunsetFilterPS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float3 Image : SV_Target)
{
	// Grab screen texture
	Image.rgb = tex2D(ReShade::BackBuffer, UvCoord).rgb;
	// Correct Aspect Ratio
	float2 UvCoordAspect = UvCoord;
	UvCoordAspect.y += BUFFER_ASPECT_RATIO * 0.5 - 0.5;
	UvCoordAspect.y /= BUFFER_ASPECT_RATIO;
	// Center coordinates
	UvCoordAspect = UvCoordAspect * 2 - 1;
	UvCoordAspect *= Scale;

	// Tilt vector
	const float Angle = radians(-Axis);
	const float2 TiltVector = float2(sin(Angle), cos(Angle));

	// Blend Mask
	float BlendMask = dot(TiltVector, UvCoordAspect) + Offset;
	BlendMask = Overlay(BlendMask * 0.5 + 0.5); // Linear coordinates

	// Color image
	if (Flip)
		Image = Screen(Image.rgb, lerp(ColorA.rgb, ColorB.rgb, 1 - BlendMask));
	else
		Image = Screen(Image.rgb, lerp(ColorA.rgb, ColorB.rgb, BlendMask));

#if GSHADE_DITHER
	Image += TriDither(Image, UvCoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

technique SunsetFilter
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = SunsetFilterPS;
	}
}
