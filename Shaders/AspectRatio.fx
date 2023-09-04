/*------------------.
| :: Description :: |
'-------------------/

Aspect Ratio PS (version 1.3.1)

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

#ifndef ASPECT_RATIO_USE_TEXTURE
	#define ASPECT_RATIO_USE_TEXTURE 0
#endif
#if ASPECT_RATIO_USE_TEXTURE
	#ifndef ASPECT_RATIO_TEX
		#define ASPECT_RATIO_TEX "TestPattern.png"
	#endif
	#ifndef ASPECT_RATIO_TEX_WIDTH
		#define ASPECT_RATIO_TEX_WIDTH 1920
	#endif
	#ifndef ASPECT_RATIO_TEX_HEIGHT
		#define ASPECT_RATIO_TEX_HEIGHT 1080
	#endif
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
	ui_units = "x";
	ui_label = "Scale image to borders";
	ui_category = "Aspect ratio";
> = 1f;

uniform float4 Color
<
	ui_type = "color";
	ui_label = "Background color";
	ui_category = "Borders";
> = float4(0.027, 0.027, 0.027, 0.17);

/*---------------.
| :: Textures :: |
'---------------*/

#if ASPECT_RATIO_USE_TEXTURE
texture AspectBgTex
< source = ASPECT_RATIO_TEX; >
{
	Width = ASPECT_RATIO_TEX_WIDTH;
	Height = ASPECT_RATIO_TEX_HEIGHT;
};
sampler AspectBgSampler { Texture = AspectBgTex; };
#endif

/*--------------.
| :: Shaders :: |
'--------------*/

float3 AspectRatioPS(
	float4 pixelPos : SV_Position,
	float2 texCoord : TEXCOORD
) : SV_Target
{
	// Center coordinates
	float2 aspectCoord = texCoord-0.5;

	// Calculate squeeze parameters
	float deformation = abs(A)+1f;
	float scaling = abs(A)*Zoom+1f;

	// Squeeze horizontally or vertically
	float Mask, pixelScale;
	if (A<0f)
	{
		// Apply deformation
		aspectCoord.x *= deformation;
		// Scale to borders
		aspectCoord /= scaling;
		// Mask image borders
		Mask = 0.5-abs(aspectCoord.x);
		pixelScale = BUFFER_WIDTH*scaling/deformation;
		// Create smooth mask
		Mask = saturate(Mask*pixelScale+0.5);
	}
	else if (A>0f)
	{
		// Apply deformation
		aspectCoord.y *= deformation;
		// Scale to borders
		aspectCoord /= scaling;
		// Mask image borders
		Mask = 0.5-abs(aspectCoord.y);
		pixelScale = BUFFER_HEIGHT*scaling/deformation;
		// Create smooth mask
		Mask = saturate(Mask*pixelScale+0.5);
	}
	else // bypass
		return tex2Dfetch(ReShade::BackBuffer, uint2(pixelPos.xy)).rgb;

	// Coordinates back to the corner
	aspectCoord += 0.5;

	// Sample display image and return
#if ASPECT_RATIO_USE_TEXTURE
	if (Zoom<1f) // If borders are visible
		return lerp(
				lerp(tex2D(AspectBgSampler, texCoord).rgb, Color.rgb, Color.a),
				tex2D(ReShade::BackBuffer, aspectCoord).rgb,
				Mask
			);
	else
#endif
		return lerp(Color.rgb, tex2D(ReShade::BackBuffer, aspectCoord).rgb, Mask);
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
