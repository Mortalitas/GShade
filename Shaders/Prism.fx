/** Chromatic Aberration (Prism) PS, version 2.1.1

This code © 2018-2023 Jakub Maksymilian Fober

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

For updates visit GitHub repository at
https://github.com/Fubaxiusz/fubax-shaders.

inspired by Marty McFly YACA shader
*/

	/* MACROS */

// Maximum number of samples for chromatic aberration
#define CHROMATIC_ABERRATION_MAX_SAMPLES 128u

	/* COMMONS */

#include "ReShade.fxh"
#include "ColorAndDither.fxh"

	/* MENU */

uniform float4 K <
	ui_type = "drag";
	ui_min = -0.1; ui_max =  0.1;
	ui_label = "Radial 'k' coefficients";
	ui_tooltip = "Radial distortion coefficients k1, k2, k3, k4.";
	ui_category = "Chromatic aberration";
> = float4(0.016, 0f, 0f, 0f);

uniform float AchromatAmount <
	ui_type = "slider";
	ui_min = 0f; ui_max =  1f;
	ui_label = "Achromat amount";
	ui_tooltip = "Achromat strength factor.";
	ui_category = "Chromatic aberration";
> = 0f;

// Performance

uniform uint ChromaticSamplesLimit <
	ui_type = "slider";
	ui_min = 6u; ui_max = CHROMATIC_ABERRATION_MAX_SAMPLES; ui_step = 2u;
	ui_label = "Samples limit";
	ui_tooltip =
		"Sample count is generated automatically per pixel, based on visible distortion amount.\n"
		"This option limits maximum sample (steps) count allowed for color fringing.\n"
		"Only even numbers are accepted, odd numbers will be clamped.";
	ui_category = "Performance";
	ui_category_closed = true;
> = 64u;

	/* FUNCTIONS */

/* Chromatic aberration hue color generator by Fober J. M.
   hue = index/samples;
   where index ∊ [0, samples-1] and samples is an even number */
float3 Spectrum(float hue)
{
	float3 hueColor;
	hue *= 4f; // Slope
	hueColor.rg = hue-float2(1f, 2f);
	hueColor.rg = saturate(1.5-abs(hueColor.rg));
	hueColor.r += saturate(hue-3.5);
	hueColor.b = 1f-hueColor.r;
	return hueColor;
}

	/* TEXTURES */

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
#if BUFFER_COLOR_SPACE <= 2 && BUFFER_COLOR_BIT_DEPTH != 10 // Linear workflow
	SRGBTexture = true;
#endif
	// Border style
	AddressU = MIRROR;
	AddressV = MIRROR;
};

	/* SHADERS */

// Vertex shader generating a triangle covering the entire screen
void ChromaticAberrationVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 viewCoord : TEXCOORD)
{
	// Define vertex position
	const float2 vertexPos[3] =
	{
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	// Export screen centered texture coordinates
	viewCoord.x =  vertexPos[id].x;
	viewCoord.y = -vertexPos[id].y;
	// Correct aspect ratio, normalized to the corner
	viewCoord *= normalize(BUFFER_SCREEN_SIZE);
	// Export vertex position
	position = float4(vertexPos[id], 0f, 1f);
}

// Main pixel shader for chromatic aberration
void ChromaticAberrationPS(float4 pixelPos : SV_Position, float2 viewCoord : TEXCOORD, out float3 color : SV_Target)
{
	// Get radius at increasing even powers
	float4 pow_radius;
	pow_radius[0] = dot(viewCoord, viewCoord); // r²
	pow_radius[1] = pow_radius[0]*pow_radius[0]; // r⁴
	pow_radius[2] = pow_radius[1]*pow_radius[0]; // r⁶
	pow_radius[3] = pow_radius[2]*pow_radius[0]; // r⁸
	// Brown-Conrady division model distortion
	float2 distortion = viewCoord*(rcp(1f+dot(K, pow_radius))-1f)/normalize(BUFFER_SCREEN_SIZE)*0.5; // Radial distortion
	// Get texture coordinates
	viewCoord = pixelPos.xy*BUFFER_PIXEL_SIZE;
	// Get maximum number of samples allowed
	uint evenSampleCount = min(ChromaticSamplesLimit-ChromaticSamplesLimit%2u, CHROMATIC_ABERRATION_MAX_SAMPLES); // Clamp value
	// Get total offset in pixels for automatic sample amount
	uint totalPixelOffset = uint(ceil(length(distortion*BUFFER_SCREEN_SIZE)));
	// Set dynamic even number sample count, limited in range
	evenSampleCount = clamp(totalPixelOffset+totalPixelOffset%2u, 4u, evenSampleCount);

	// Sample background with multiple color filters at multiple offsets
	color = 0f; // initialize color
	for (uint i=0u; i<evenSampleCount; i++)
	{
		float progress = i/float(evenSampleCount-1u)-0.5;
		progress = lerp(progress, 0.5-abs(progress), AchromatAmount);
		color +=
#if BUFFER_COLOR_SPACE <= 2 && BUFFER_COLOR_BIT_DEPTH == 10 // Manual gamma correction
			to_linear_gamma(
#endif
				tex2Dlod(
					BackBuffer, // Image source
					float4(
						progress // Aberration offset
						*distortion // Distortion coordinates
						+viewCoord, // Original coordinates
					0f, 0f)).rgb
#if BUFFER_COLOR_SPACE <= 2 && BUFFER_COLOR_BIT_DEPTH == 10 // Manual gamma correction
			)
#endif
			*Spectrum(i/float(evenSampleCount)); // Blur layer color
	}
	// Preserve brightness
	color *= 2f/evenSampleCount;
#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
	color = to_display_gamma(color);
#endif
	color = BlueNoise::dither(uint2(pixelPos.xy), color); // Dither
}

	/* SHADER */

technique ChromaticAberration
<
	ui_label = "Chromatic Aberration";
	ui_tooltip =
		"Chromatic aberration color split at the screen borders.\n"
		"\n"
		"	· Dynamic minimal sample count per pixel.\n"
		"	· Accurate color split.\n"
		"	· Driven by lens distortion Brown-Conrady division model.\n"
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-NC-ND 3.0 +\n"
		"for additional permissions see the source.";
>
{
	pass ChromaticColorSplit
	{
		VertexShader = ChromaticAberrationVS;
		PixelShader  = ChromaticAberrationPS;
	}
}
