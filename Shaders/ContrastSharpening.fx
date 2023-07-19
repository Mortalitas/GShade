/*------------------.
| :: Description :: |
'-------------------/

Contrast Limited Sharpening PS (version 1.1.8)

Copyright:
This code © 2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons Attribution-NonCommercial-
NoDerivs 3.0 Unported License. To view a copy of this license, visit
http://creativecommons.org/licenses/by-nc-nd/3.0/

Additional permissions under Creative Commons Plus (CC+):

§ 1. The copyright owner further grants permission for commercial reuse of image
recordings based on the work (e.g., Let's Play videos, gameplay streams, and
screenshots featuring ReShade filters). Any such use must include credit to the
creator and the name of the used shader.
 Intent §: To facilitate non-corporate, common use of the shader at no cost.
Outcome §: That recognition of the work in any derivative images is ensured.

§ 2. Additionally, permission is granted for the translation of the front-end UI
text within this shader.
 Intent §: To increase accessibility and understanding across different
languages.
Outcome §: That usability across users from diverse linguistic backgrounds is
promoted, allowing them to fully engage with the shader.

Contact:
If you want additional licensing for your commercial product, please contact me:
jakub.m.fober@protonmail.com
*/

/*-------------.
| :: Macros :: |
'-------------*/

// Fixed sharpen radius for performance
#ifndef CONTRAST_SHARPEN_RADIUS
	#define CONTRAST_SHARPEN_RADIUS 0
#endif

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"
#include "ColorConversion.fxh"
#include "BlueNoiseDither.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

#if !CONTRAST_SHARPEN_RADIUS
uniform uint SharpenRadius
<
	ui_type = "slider";
	ui_label = "sharpening radius";
	ui_tooltip =
		"Sharpening sampling radius in pixels,\n"
		"with Gaussian falloff.\n"
		"This setting directly affects performance.";
	ui_min = 2u; ui_max = 32u;
	ui_category = "sharpening settings";
> = 16u;
#endif

uniform float SharpenAmount
<
	ui_type = "slider";
	ui_label = "sharpening amount";
	ui_tooltip =
		"High-pass layer multiplier.\n"
		"Values higher than 1.0 may increase noise.";
	ui_min = 0f; ui_max = 2f;
	ui_step = 0.01;
	ui_category = "sharpening settings";
> = 1f;

uniform uint BlendingMode
<
	ui_type = "radio";
	ui_label = "sharpening mode";
	ui_tooltip = "Blending mode for the high-pass layer.";
	ui_items =
		"hard light\0"
		"overlay\0";
	ui_category = "sharpening settings";
> = 0u;

uniform float ContrastAmount
<
	ui_type = "slider";
	ui_label = "contrast amount";
	ui_tooltip =
		"Contrast limiting threshold.\n"
		"Lower values remove 'halos'.";
	ui_min = 0.01; ui_max = 1f;
	ui_step = 0.01;
	ui_category = "additional settings";
	ui_category_closed = true;
> = 0.16;

uniform bool DitheringEnabled
<
	ui_type = "input";
	ui_label = "remove banding";
	ui_tooltip =
		"Applies invisible dithering effect, to\n"
		"increase perceivable image bit-depth.";
	ui_category = "additional settings";
> = true;

/*---------------.
| :: Textures :: |
'---------------*/

// Render target for two-pass blur
texture ContrastSharpenTarget
{
	Width  = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

	Format = R8;
};
sampler ContrastSharpenSampler
{ Texture = ContrastSharpenTarget; };

/*----------------.
| :: Functions :: |
'----------------*/

/* Exponential bell weight falloff by JMF
   Generates smooth bell falloff for blur, with perfect weights
   distribution for a given number of samples.
   Input: position ∈ [-1, 1] */
float bellWeight(float position)
{
	// Get deviation for minimum value for a given step size
	const float deviation = log(rcp(256u)); // Logarithm of base e for an 8-bit final weight
	// Get smooth bell falloff without aliasing or zero value at the last sample
	return exp(position*position*deviation); // Gaussian bell falloff
}

/* Overlay blending function.
   Base and blend layers are in [0,1] range. */
float overlay(float baseLayer, float blendLayer)
{
	baseLayer *= 2f;
	return mad(mad(
		-min(baseLayer, 1f), blendLayer, 1f), // Multiply filter
		 max(baseLayer, 1f)-2f,               // Screen filter
		1f);
}

/*--------------.
| :: Shaders :: |
'--------------*/

// Vertex shader generating a triangle covering the entire screen
void ContrastSharpenVS(
	in  uint   vertexId  : SV_VertexID,
	out float4 vertexPos : SV_Position
)
{
	// Define vertex position
	const float2 vertexPosList[3] =
	{
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	// Export  vertex position,
	vertexPos.xy = vertexPosList[vertexId];
	vertexPos.zw = float2(0f, 1f); // Export vertex position
}

// Horizontal luminosity blur pass
void ContrastSharpenPassHorizontalPS(
	in  float4  pixCoord : SV_Position,
	out float luminosity : SV_Target
)
{
	// Get current pixel coordinates
	uint2 texelPos = uint2(pixCoord.xy);
	// Get current pixel luminosity value
	luminosity = ColorConvert::RGB_to_Luma(tex2Dfetch(ReShade::BackBuffer, texelPos).rgb);
	// Prepare cumulative variables
	float cumilativeLuminosity = 0f, cumulativeWeight = 0f;
#if CONTRAST_SHARPEN_RADIUS // Fixed contrast sharpen radius
	static float sampleWeight[CONTRAST_SHARPEN_RADIUS*2u+1u];
	const uint SharpenRadius = CONTRAST_SHARPEN_RADIUS;
#endif
	// Sample blur kernel
	for (uint yPos=0u; yPos<=SharpenRadius*2u; yPos++)
	{
		// Sample back-buffer luminosity
		float sampleLuminosity = ColorConvert::RGB_to_Luma(
			tex2Dfetch(ReShade::BackBuffer, uint2(
				texelPos.x,
				// Offset coordinates
				clamp(int(texelPos.y+yPos)-SharpenRadius, 0, int(BUFFER_HEIGHT)-1)
			)).rgb
		);
		// Get step size
		const float stepSize = rcp(SharpenRadius);
		// Get current sample weight
#if CONTRAST_SHARPEN_RADIUS // for fixed contrast sharpen radius
		sampleWeight[yPos] =
#else // for dynamic contrast sharpen radius
		float sampleWeight =
#endif
			bellWeight(mad(yPos, stepSize, -1f));// Y radius
		float sampleContrastWeight = saturate(abs(sampleLuminosity-luminosity)/ContrastAmount); // Contrast
		sampleContrastWeight = bellWeight(sampleContrastWeight); // Natural falloff
		// Apply weight and add to blurred luminosity
		sampleContrastWeight *=
#if CONTRAST_SHARPEN_RADIUS // for fixed contrast sharpen radius
			sampleWeight[yPos];
#else // for dynamic contrast sharpen radius
			sampleWeight;
#endif
		cumilativeLuminosity += sampleLuminosity*sampleContrastWeight;
		cumulativeWeight += sampleContrastWeight;
	}
	// Save output and restore brightness
	luminosity = cumilativeLuminosity/cumulativeWeight;

	// Dither output to increase perceivable picture bit-depth
	if (DitheringEnabled)
		luminosity = BlueNoise::dither(luminosity, uint2(pixCoord.xy));
}

// Horizontal luminance blur and contrast sharpening pass
void ContrastSharpenPassVerticalPS(
	in  float4 pixCoord : SV_Position,
	out float3    color : SV_Target
)
{
	// Get current pixel coordinates
	uint2 texelPos = uint2(pixCoord.xy);
	// Get current pixel YCbCr color value
	color = ColorConvert::RGB_to_YCbCr(tex2Dfetch(ReShade::BackBuffer, texelPos).rgb);
	// Prepare cumulative variables
	float cumilativeLuminosity = 0f, cumulativeWeight = 0f;
#if CONTRAST_SHARPEN_RADIUS // Fixed contrast sharpen radius
	static float sampleWeight[CONTRAST_SHARPEN_RADIUS*2u+1u];
	const uint SharpenRadius = CONTRAST_SHARPEN_RADIUS;
#endif
	// Sample blur kernel
	for (uint xPos=0u; xPos<=SharpenRadius*2u; xPos++)
	{
		// Sample back-buffer luminosity
		float sampleLuminosity = tex2Dfetch(ContrastSharpenSampler, uint2(
				// Offset coordinates
				clamp(int(texelPos.x+xPos)-SharpenRadius, 0, int(BUFFER_WIDTH)-1),
				texelPos.y
			)).r;
		// Get step size
		const float stepSize = rcp(SharpenRadius);
		// Get current sample weight
#if CONTRAST_SHARPEN_RADIUS // for fixed contrast sharpen radius
		sampleWeight[xPos] =
#else // for dynamic contrast sharpen radius
		float sampleWeight =
#endif
			bellWeight(mad(xPos, stepSize, -1f)); // X position
		float sampleContrastWeight = saturate(abs(sampleLuminosity-color.x)/ContrastAmount); // Contrast
		sampleContrastWeight = bellWeight(sampleContrastWeight); // Natural falloff
		// Apply weight and add to blurred luminosity
		sampleContrastWeight *=
#if CONTRAST_SHARPEN_RADIUS // for fixed contrast sharpen radius
			sampleWeight[xPos];
#else // for dynamic contrast sharpen radius
			sampleWeight;
#endif
		cumilativeLuminosity += sampleLuminosity*sampleContrastWeight;
		cumulativeWeight += sampleContrastWeight;
	}
	// Restore brightness
	cumilativeLuminosity /= cumulativeWeight;
	// Generate high-pass filter
	float highPass = mad(color.x-cumilativeLuminosity, SharpenAmount*0.5, 0.5);
	// Blend high-pass with the base image luminosity
	switch (BlendingMode)
	{
		case 1: // blend using overlay method
			color.x = overlay(color.x, highPass);
			break;
		default: // blend using hard-light method
			color.x = overlay(highPass, color.x);
			break;
	}
	// Convert to RGB color space
	color = saturate(ColorConvert::YCbCr_to_RGB(color)); // and clamp result

	// Dither output to increase perceivable picture bit-depth
	if (DitheringEnabled)
		color = BlueNoise::dither(color, uint2(pixCoord.xy));
}

/*-------------.
| :: Output :: |
'-------------*/

technique ContrastSharpen
<
	ui_label = "Contrast Limited Sharpening";
	ui_tooltip =
		"Contrast Limited Sharpening effect.\n"
		"\n"
		"Increases local contrast without enhancing\n"
		"already sharp edges.\n"
		"\n"
		"	· dynamic or fixed per-pixel sampling.\n"
		"	· removes 'halo' effect.\n"
		"	· removes 'banding' effect.\n"
		"\n"
		"This effect © 2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-NC-ND 3.0 +\n"
		"for additional permissions see the source code.";
>
{
	pass GaussianContrastBlurHorizontal
	{
		RenderTarget = ContrastSharpenTarget;

		VertexShader = ContrastSharpenVS;
		PixelShader  = ContrastSharpenPassHorizontalPS;
	}
	pass GaussianContrastBlurVerticalAndSharpening
	{
		VertexShader = ContrastSharpenVS;
		PixelShader  = ContrastSharpenPassVerticalPS;
	}
}
