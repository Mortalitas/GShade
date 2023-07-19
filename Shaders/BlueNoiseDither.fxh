/*------------------.
| :: Description :: |
'-------------------/

Blue Noise Dither Library (version 1.5.0)

Copyright:
This code © 2022-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by/3.0/

About:
This effect dithers the colors of an image, when quantized from higher bit-depth
source, to lower one, mainly of the display. It should be used at the very end
of the shader output. It uses type of noise called "blue", to switch between
quantized values of color, to give impression of a gradient step. The blue
noise corresponds to the distribution of light-sensitive cells in the eye, and
therefore is least noticeable, compared to other types. The noise, I've heard,
is hard to calculate, so I use a texture instead, which thanks to the nature of
blue noise, even doe small, tiles seamlessly.

Instruction:
Simply call the following function,
	`return BlueNoise::dither(outColor, uint2(vpos.xy));`
in place of this,
	`return outColor;`
Where
	• `outColor` - is the value you would typically return.
	• `vpos` - is the shader input mapped to pixel 2D index SV_Position.
*/

#pragma once

/*-------------.
| :: Macros :: |
'-------------*/

// Change this, if you load bigger texture
#define DITHER_TEX_SIZE 64u
#if BUFFER_COLOR_SPACE <= 2 // 8-bit quantization
	#define QUANTIZATION_LEVEL 255
#else // 10-bit quantization
	#define QUANTIZATION_LEVEL 1023
#endif

/*---------------.
| :: Textures :: |
'---------------*/

namespace BlueNoise
{
	/* The blue noise texture
	   Obtained under CC0, from:
	   https://momentsingraphics.de/BlueNoise.html */
	texture BlueNoiseTex
	<
		source = "bluenoise.png";
		pooled = true;
	>
	{
		Width = DITHER_TEX_SIZE;
		Height = DITHER_TEX_SIZE;
		Format = RGBA8;
	};
	// Sampler for blue noise texture
	sampler BlueNoiseTexSmp
	{
		Texture = BlueNoiseTex;
		// Repeat texture coordinates
		AddressU = REPEAT;
		AddressV = REPEAT;
	};

/*----------------.
| :: Functions :: |
'----------------*/

	/* Dither functions
	Usage:
	Transform final color by this function, at the very end of a pixel shader:
		return BlueNoise::dither(color, uint2(pos.xy));
	where "pos.xy" is a variable mapped to SV_Position input of a pixel shader. */
	float dither(float gradient, uint2 pixelPos)
	{
		// Scale to quantization range
		gradient *= QUANTIZATION_LEVEL;
		// Get blue noise repeated texture
		float noise = tex2Dfetch(BlueNoiseTexSmp, pixelPos%DITHER_TEX_SIZE).r;
		// Dither quantization
		gradient = frac(gradient) >= noise ? ceil(gradient) : floor(gradient);
		// Normalize
		return gradient/QUANTIZATION_LEVEL;
	}
	float3 dither(float3 color, uint2 pixelPos)
	{
		// Scale to quantization range
		color *= QUANTIZATION_LEVEL;
		// Get blue noise repeated texture
		float3 noise = tex2Dfetch(BlueNoiseTexSmp, pixelPos%DITHER_TEX_SIZE).rgb;
		// Get threshold for noise amount
		float3 slope = frac(color);
		// Dither quantization
		[unroll] for (uint i=0u; i<3u; i++)
			color[i] = slope[i] >= noise[i] ? ceil(color[i]) : floor(color[i]);
		// Normalize
		return color/QUANTIZATION_LEVEL;
	}
	float4 dither(float4 color, uint2 pixelPos)
	{
		// Scale to quantization range
		color *= QUANTIZATION_LEVEL;
		// Get blue noise repeated texture
		float4 noise = tex2Dfetch(BlueNoiseTexSmp, pixelPos%DITHER_TEX_SIZE);
		// Get threshold for noise amount
		float4 slope = frac(color);
		// Dither quantization
		[unroll] for (uint i=0u; i<4u; i++)
			color[i] = slope[i] >= noise[i] ? ceil(color[i]) : floor(color[i]);
		// Normalize
		return color/QUANTIZATION_LEVEL;
	}
}