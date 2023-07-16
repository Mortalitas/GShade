/*------------------.
| :: Description :: |
'-------------------/

Blue Noise Dither Library (version 1.4.0)

Copyright:
This code © 2022-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by/3.0/
*/

#pragma once

/*-------------.
| :: Macros :: |
'-------------*/

// Change this, if you load bigger texture
#define DITHER_SIZE_TEX 64u
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
		Width = DITHER_SIZE_TEX;
		Height = DITHER_SIZE_TEX;
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
	   	return BlueNoise::dither(uint2(pos.xy), color);
	   where "pos.xy" is a variable mapped to
	   SV_Position input from a pixel shader. */
	float dither(uint2 pixelPos, float gradient)
	{
		// Scale to quantization range
		gradient *= QUANTIZATION_LEVEL;
		// Get blue noise repeated texture
		float noise = tex2Dfetch(BlueNoiseTexSmp, pixelPos%DITHER_SIZE_TEX).r;
		// Dither quantization
		gradient = frac(gradient) >= noise ? ceil(gradient) : floor(gradient);
		// Normalize
		return gradient/QUANTIZATION_LEVEL;
	}
	float3 dither(uint2 pixelPos, float3 color)
	{
		// Scale to quantization range
		color *= QUANTIZATION_LEVEL;
		// Get blue noise repeated texture
		float3 noise = tex2Dfetch(BlueNoiseTexSmp, pixelPos%DITHER_SIZE_TEX).rgb;
		// Get threshold for noise amount
		float3 slope = frac(color);
		// Dither quantization
		[unroll] for (uint i=0u; i<3u; i++)
			color[i] = slope[i] >= noise[i] ? ceil(color[i]) : floor(color[i]);
		// Normalize
		return color/QUANTIZATION_LEVEL;
	}
	float4 dither(uint2 pixelPos, float4 color)
	{
		// Scale to quantization range
		color *= QUANTIZATION_LEVEL;
		// Get blue noise repeated texture
		float4 noise = tex2Dfetch(BlueNoiseTexSmp, pixelPos%DITHER_SIZE_TEX);
		// Get threshold for noise amount
		float4 slope = frac(color);
		// Dither quantization
		[unroll] for (uint i=0u; i<4u; i++)
			color[i] = slope[i] >= noise[i] ? ceil(color[i]) : floor(color[i]);
		// Normalize
		return color/QUANTIZATION_LEVEL;
	}
}