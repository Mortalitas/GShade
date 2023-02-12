/** Contrast Limited Sharpening PS, version 1.1.1

This code © 2023 Jakub Maksymilian Fober

This work is licensed under the Creative Commons,
Attribution-NonCommercial-NoDerivs 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-nc-nd/3.0/.

§ The copyright owner further grants permission for commercial reuse
of image recordings based on the work (e.g. Let's Play videos,
gameplay streams, and screenshots featuring ReShade filters) provided
that any use is accompanied by the name of the used shader and a link
to the ReShade website https://reshade.me.
§ This is intended to make the effect available free of charge for
non-corporate, common use.
§ The desired outcome is for the work to be easily recognizable in any
derivative images.

If you need additional licensing for your commercial product, contact
me at jakub.m.fober@protonmail.com.
*/

	/* MACROS */

// Luminosity transformation
#ifndef ITU_REC
	#define ITU_REC 601
#endif
// Fixed sharpen radius for performance
#ifndef CONTRAST_SHARPEN_RADIUS
	#define CONTRAST_SHARPEN_RADIUS 0
#endif

	/* COMMONS */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ColorAndDither.fxh"

	/* MENU */

#if !CONTRAST_SHARPEN_RADIUS
uniform uint SharpenRadius < __UNIFORM_SLIDER_INT1
	ui_label = "sharpening radius";
	ui_tooltip =
		"Sharpening sampling radius in pixels,\n"
		"with Gaussian falloff.\n"
		"This setting directly affects performance.";
	ui_min = 2u; ui_max = 32u;
	ui_category = "sharpening settings";
> = 16u;
#endif

uniform float SharpenAmount < __UNIFORM_SLIDER_FLOAT1
	ui_label = "sharpening amount";
	ui_tooltip =
		"High-pass layer multiplier.\n"
		"Values higher than 1.0 may increase noise.";
	ui_min = 0f; ui_max = 2f;
	ui_step = 0.01;
	ui_category = "sharpening settings";
> = 1f;

uniform uint BlendingMode < __UNIFORM_RADIO_INT1
	ui_label = "sharpening mode";
	ui_tooltip = "Blending mode for the high-pass layer.";
	ui_items =
		"hard light\0"
		"overlay\0";
	ui_category = "sharpening settings";
> = 0u;

uniform float ContrastAmount < __UNIFORM_SLIDER_FLOAT1
	ui_label = "contrast amount";
	ui_tooltip =
		"Contrast limiting threshold.\n"
		"Lower values remove 'halos'.";
	ui_min = 0.01; ui_max = 1f;
	ui_step = 0.01;
	ui_category = "additional settings";
	ui_category_closed = true;
> = 0.16;

uniform bool DitheringEnabled < __UNIFORM_INPUT_BOOL1
	ui_label = "remove banding";
	ui_tooltip =
		"Applies invisible dithering effect, to\n"
		"increase perceivable image bit-depth.";
	ui_category = "additional settings";
> = true;

	/* TEXTURES */

// Render target for two-pass blur
texture ContrastSharpenTarget
{
	Width  = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

	Format = R8;
};
sampler ContrastSharpenSampler
{ Texture = ContrastSharpenTarget; };

	/* FUNCTIONS */

/* Exponential bell weight falloff by JMF
   Generates smooth bell falloff for blur, with perfect weights
   distribution for a given number of samples.
   Input: position ∈ [-1, 1]² */
float bellWeight(float2 position)
{
	// Get deviation for minimum value for a given step size
	const float deviation = log(rcp(256u)); // Logarithm of base e for an 8-bit final weight
	// Get smooth bell falloff without aliasing or zero value at the last sample
	return exp(dot(position, position)*deviation); // Gaussian bell falloff
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

	/* SHADERS */

// Vertex shader generating a triangle covering the entire screen
void ContrastSharpenVS(
	in  uint   vertexId  : SV_VertexID,
	out float4 vertexPos : SV_Position)
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
	out float luminosity : SV_Target)
{
	// Get current pixel coordinates
	uint2 texelPos = uint2(pixCoord.xy);
	// Get current pixel luminosity value
	luminosity = dot(LumaMtx, tex2Dfetch(ReShade::BackBuffer, texelPos).rgb);
	// Prepare cumulative variables
	float cumilativeLuminosity = 0f;
	static float cumilativeWeight = 0f;
#if CONTRAST_SHARPEN_RADIUS // Fixed contrast sharpen radius
	static float sampleWeight[CONTRAST_SHARPEN_RADIUS*2u+1u];
	const uint SharpenRadius = CONTRAST_SHARPEN_RADIUS;
#endif
	// Sample blur kernel
	for (uint yPos=0u; yPos<=SharpenRadius*2u; yPos++)
	{
		// Sample back-buffer luminosity
		float sampleLuminosity = dot(LumaMtx,
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
			bellWeight(float2(
				mad(yPos, stepSize, -1f), // Y radius
				abs(sampleLuminosity-luminosity)/ContrastAmount // Contrast
			));
		// Apply weight and add to blurred luminosity
		cumilativeLuminosity += sampleLuminosity*
#if CONTRAST_SHARPEN_RADIUS // for fixed contrast sharpen radius
			sampleWeight[yPos];
		cumilativeWeight += sampleWeight[yPos];
#else // for dynamic contrast sharpen radius
			sampleWeight;
		cumilativeWeight += sampleWeight;
#endif
	}
	// Save output and restore brightness
	luminosity = cumilativeLuminosity/cumilativeWeight;

	// Dither output to increase perceivable picture bit-depth
	if (DitheringEnabled)
		luminosity = BlueNoise::dither(uint2(pixCoord.xy), luminosity);
}

// Horizontal luminance blur and contrast sharpening pass
void ContrastSharpenPassVerticalPS(
	in  float4 pixCoord : SV_Position,
	out float3    color : SV_Target)
{
	// Get current pixel coordinates
	uint2 texelPos = uint2(pixCoord.xy);
	// Get current pixel YCbCr color value
	color = mul(YCbCrMtx, tex2Dfetch(ReShade::BackBuffer, texelPos).rgb);
	// Prepare cumulative variables
	float cumilativeLuminosity = 0f;
	static float cumilativeWeight = 0f;
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
			bellWeight(float2(
				mad(xPos, stepSize, -1f), // X position
				abs(sampleLuminosity-color.x)/ContrastAmount // Contrast
			));
		// Apply weight and add to blurred luminosity
		cumilativeLuminosity += sampleLuminosity*
#if CONTRAST_SHARPEN_RADIUS // for fixed contrast sharpen radius
		sampleWeight[xPos];
		cumilativeWeight += sampleWeight[xPos];
#else // for dynamic contrast sharpen radius
		sampleWeight;
		cumilativeWeight += sampleWeight;
#endif
	}
	// Restore brightness
	cumilativeLuminosity /= cumilativeWeight;
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
	color = saturate(mul(RgbMtx, color)); // and clamp result

	// Dither output to increase perceivable picture bit-depth
	if (DitheringEnabled)
		color = BlueNoise::dither(uint2(pixCoord.xy), color);
}

	/* OUTPUT */

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
		"for additional permissions see the source.";
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
