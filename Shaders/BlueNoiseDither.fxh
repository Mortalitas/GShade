/* Blue Noise Dither Library (version 1.6.0)
__________.__                   _______         .__
\______   \  |  __ __   ____    \      \   ____ |__| ______ ____
 |    |  _/  | |  |  \_/ __ \   /   |   \ /  _ \|  |/  ___// __ \
 |    |   \  |_|  |  /\  ___/  /    |    (  <_> )  |\___ \\  ___/
 |______  /____/____/  \___  > \____|__  /\____/|__/____  >\___  >
        \/                 \/          \/               \/     \/
> Copyright notice:
© 2022-2026 Jakub Maksymilian Fober

> Licensing:
Licensed under the Open Community License v1.1 + Research & Development v1
(OCL v1.1 + RnD v1). To view the authoritative license text, visit these links:
https://github.com/OpenCommunityLicence/OpenCommunityLicence/blob/main/LICENSE
https://github.com/OpenCommunityLicence/OpenCommunityLicence/blob/main/addons/RnD-v1.md
For a summary, visit this link:
https://github.com/OpenCommunityLicence/OpenCommunityLicence

> About info:
This effect dithers the colors of an image, when quantized from higher bit-depth
source, to lower one, mainly of the display. It should be used at the very end
of the shader output. It uses type of noise called "blue", to switch between
quantized values of color, to give impression of a gradient step. The blue
noise corresponds to the distribution of light-sensitive cells in the eye, and
therefore is least noticeable, compared to other types. The noise, I've heard,
is hard to calculate, so I use a texture instead, which thanks to the nature of
blue noise, even doe small, tiles without seams.

> Usage instruction:
Simply call the following function, where `vpos` is a texel pixel position:
	`return BlueNoise::dither(outColor, vpos);`
	`return BlueNoise::dither(outColor, vpos.xy);`
	`return BlueNoise::dither(outColor, uint2(vpos.xy));`
in place of this,
	`return outColor;`
Where
	- `outColor` - is the final color value you would typically return.
	- `vpos` - is a texel pixel position from `SV_Position` shader input.
*/

#pragma once

/* >> Macros << */

// Change this to turn dithering ON/OFF
#ifndef DITHER_ENABLE
	#define DITHER_ENABLE 1
#endif
// Change this for a custom noise texture
#ifndef DITHER_TEX_SOURCE
	#define DITHER_TEX_SOURCE "blueNoise64.png"
#endif
// Change this, if you load bigger texture
#ifndef DITHER_TEX_SIZE
	#define DITHER_TEX_SIZE 64u
#endif
// Change this to limit color palette
#if BUFFER_COLOR_SPACE <= 1 // 8-bit quantization
	#define DITHER_QUANTIZATION 255u
#else // 10-bit quantization
	#define DITHER_QUANTIZATION 1023u
#endif

/* >> Textures << */

namespace BlueNoise
{
#if DITHER_ENABLE
	/* The blue noise texture
	Obtained under CC0, from:
	https://momentsingraphics.de/BlueNoise.html
	*/
	texture t_blueNoise
	<
		source = DITHER_TEX_SOURCE;
		pooled = true;
	>{
		Width  = DITHER_TEX_SIZE;
		Height = DITHER_TEX_SIZE;
		Format = RGBA8;
	};
	// Sampler for blue noise texture
	sampler s_blueNoise
	{
		Texture = t_blueNoise;
		// Repeat texture coordinates
		AddressU = REPEAT;
		AddressV = REPEAT;
	};

	/* >> Functions << */

	// Scale to quantization range, quantize with dithering by noise and normalize
	#define _NOISE_DITHERING ceil(mad(color, DITHER_QUANTIZATION, -noise)) / DITHER_QUANTIZATION

	/* Dither functions
	Usage:
	Transform final color by this function, at the very end of a pixel shader:
		`return BlueNoise::dither(color, pixelPos);`
	where `pixelPos` is a variable mapped to SV_Position input of a pixel shader.
	*/
	float dither(float color, float4 pixelPos)
	{
		// Get blue noise repeated texture
		float noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			uint2(pixelPos.xy) % DITHER_TEX_SIZE // tile texture
		).r;
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
	float2 dither(float2 color, float4 pixelPos)
	{
		// Get blue noise repeated texture
		float2 noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			uint2(pixelPos.xy) % DITHER_TEX_SIZE // tile texture
		).rg;
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
	float3 dither(float3 color, float4 pixelPos)
	{
		// Get blue noise repeated texture
		float3 noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			uint2(pixelPos.xy) % DITHER_TEX_SIZE // tile texture
		).rgb;
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
	float4 dither(float4 color, float4 pixelPos)
	{
		// Get blue noise repeated texture
		float4 noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			uint2(pixelPos.xy) % DITHER_TEX_SIZE // tile texture
		);
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}

	/* Dither functions
	Usage:
	Transform final color by this function, at the very end of a pixel shader:
		`return BlueNoise::dither(color, pixelPos);`
	where `pixelPos` is a variable mapped to SV_Position input of a pixel shader.
	*/
	float dither(float color, float2 pixelPos)
	{
		// Get blue noise repeated texture
		float noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			uint2(pixelPos) % DITHER_TEX_SIZE // tile texture
		).r;
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
	float2 dither(float2 color, float2 pixelPos)
	{
		// Get blue noise repeated texture
		float2 noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			uint2(pixelPos) % DITHER_TEX_SIZE // tile texture
		).rg;
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
	float3 dither(float3 color, float2 pixelPos)
	{
		// Get blue noise repeated texture
		float3 noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			uint2(pixelPos) % DITHER_TEX_SIZE // tile texture
		).rgb;
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
	float4 dither(float4 color, float2 pixelPos)
	{
		// Get blue noise repeated texture
		float4 noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			uint2(pixelPos) % DITHER_TEX_SIZE // tile texture
		);
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}

	/* Dither functions
	Usage:
	Transform final color by this function, at the very end of a pixel shader:
		`return BlueNoise::dither(color, uint2(pixelPos.xy));`
	where `pixelPos` is a variable mapped to SV_Position input of a pixel shader.
	*/
	float dither(float color, uint2 pixelPos)
	{
		// Get blue noise repeated texture
		float noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			pixelPos % DITHER_TEX_SIZE // tile texture
		).r;
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
	float2 dither(float2 color, uint2 pixelPos)
	{
		// Get blue noise repeated texture
		float2 noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			pixelPos % DITHER_TEX_SIZE // tile texture
		).rg;
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
	float3 dither(float3 color, uint2 pixelPos)
	{
		// Get blue noise repeated texture
		float3 noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			pixelPos % DITHER_TEX_SIZE // tile texture
		).rgb;
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
	float4 dither(float4 color, uint2 pixelPos)
	{
		// Get blue noise repeated texture
		float4 noise = tex2Dfetch(
			s_blueNoise, // noise sampler
			pixelPos % DITHER_TEX_SIZE // tile texture
		);
		return _NOISE_DITHERING; // if fractional is brighter than noise, quantize up, else down
	}
#else // don't even bother, bypass dithering
	float dither(float color, float4 pixelPos)
	{ return color; }
	float2 dither(float2 color, float4 pixelPos)
	{ return color; }
	float3 dither(float3 color, float4 pixelPos)
	{ return color; }
	float4 dither(float4 color, float4 pixelPos)
	{ return color; }

	float dither(float color, float2 pixelPos)
	{ return color; }
	float2 dither(float2 color, float2 pixelPos)
	{ return color; }
	float3 dither(float3 color, float2 pixelPos)
	{ return color; }
	float4 dither(float4 color, float2 pixelPos)
	{ return color; }

	float dither(float color, uint2 pixelPos)
	{ return color; }
	float2 dither(float2 color, uint2 pixelPos)
	{ return color; }
	float3 dither(float3 color, uint2 pixelPos)
	{ return color; }
	float4 dither(float4 color, uint2 pixelPos)
	{ return color; }
#endif
}
