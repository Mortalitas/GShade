/*------------------.
| :: Description :: |
'-------------------/

Aspect Ratio PS (version 1.1.2)

Copyright:
This code © 2019-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution 4.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by/4.0/
*/

/*-------------.
| :: Macros :: |
'-------------*/

#ifndef ASPECT_RATIO_TEX
	#define ASPECT_RATIO_TEX "AspectRatio.jpg"
#endif
#ifndef ASPECT_RATIO_TEX_WIDTH
	#define ASPECT_RATIO_TEX_WIDTH 1351
#endif
#ifndef ASPECT_RATIO_TEX_HEIGHT
	#define ASPECT_RATIO_TEX_HEIGHT 1013
#endif

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

uniform float A
<
	ui_type = "slider";
	ui_label = "Correct proportions";
	ui_category = "Aspect ratio";
	ui_min = -1f; ui_max = 1f;
> = 0f;

uniform float Zoom
<
	ui_type = "slider";
	ui_label = "Scale image";
	ui_category = "Aspect ratio";
	ui_min = 1f; ui_max = 1.5;
> = 1f;

uniform bool FitScreen
<
	ui_type = "input";
	ui_label = "Scale image to borders";
	ui_category = "Borders";
> = true;

uniform bool UseBackground
<
	ui_type = "input";
	ui_label = "Use background image";
	ui_category = "Borders";
> = true;

uniform float4 Color
<
	ui_type = "color";
	ui_label = "Background color";
	ui_category = "Borders";
> = float4(0.027, 0.027, 0.027, 0.17);

/*---------------.
| :: Textures :: |
'---------------*/

texture AspectBgTex
< source = ASPECT_RATIO_TEX; >
{
	Width = ASPECT_RATIO_TEX_WIDTH;
	Height = ASPECT_RATIO_TEX_HEIGHT;
};
sampler AspectBgSampler { Texture = AspectBgTex; };

/*--------------.
| :: Shaders :: |
'--------------*/

float3 AspectRatioPS(
	float4 pos : SV_Position,
	float2 texcoord : TEXCOORD
) : SV_Target
{
	bool Mask = false;

	// Center coordinates
	float2 coord = texcoord-0.5;

	// if (Zoom != 1f) coord /= Zoom;
	if (Zoom != 1f) coord /= clamp(Zoom, 1f, 1.5); // Anti-cheat

	// Squeeze horizontally
	if (A<0)
	{
		coord.x *= abs(A)+1f; // Apply distortion

		// Scale to borders
		if (FitScreen) coord /= abs(A)+1f;
		else // Mask image borders
			Mask = abs(coord.x)>0.5;
	}
	// Squeeze vertically
	else if (A>0)
	{
		coord.y *= A+1f; // Apply distortion

		// Scale to borders
		if (FitScreen) coord /= abs(A)+1f;
		else // Mask image borders
			Mask = abs(coord.y)>0.5;
	}
	
	// Coordinates back to the corner
	coord += 0.5;

	// Sample display image and return
	if (UseBackground && !FitScreen) // If borders are visible
		return Mask
			? lerp(tex2D(AspectBgSampler, texcoord).rgb, Color.rgb, Color.a)
			: tex2D(ReShade::BackBuffer, coord).rgb;
	else
		if (Mask)
			return Color.rgb;
		else
			return tex2D(ReShade::BackBuffer, coord).rgb;
}

/*-------------.
| :: Output :: |
'-------------*/

technique AspectRatioPS
<
	ui_label = "Aspect Ratio";
	ui_tooltip =
		"Correct image aspect ratio.\n"
		"\n"
		"This effect © 2019-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY 4.0";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AspectRatioPS;
	}
}
