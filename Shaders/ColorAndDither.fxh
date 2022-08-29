/** Color conversion matrix and blue noise dither library, version 1.0.6

This code © 2022 Jakub Maksymilian Fober

This work is licensed under the Creative Commons
Attribution 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by/3.0/.
*/

	/* MACROS */

#pragma once
// Change this, if you load bigger texture
#define DITHER_SIZE_TEX 64u

	/* CONSTANTS */

/* Get color conversion matrix
Usage:
First define ITU_REC:

#ifndef ITU_REC
	#define ITU_REC 601
#endif

Then use following functions in code:

mul( YCbCrMtx, color.rgb) will give you float3 color in YCbCr from sRGB input
mul(   RgbMtx, color.xyz) will give you float3 color in sRGB from YCbCr input
mul(ChromaMtx, color.rgb) will give you float2 chroma component of YCbCr from sRGB color input
dot(  LumaMtx, color.rgb) will give you float luma component of YCbCr from sRGB color input
*/
#ifdef ITU_REC
	// YCbCr coefficients
	#if ITU_REC==601
		#define KR 0.299
		#define KB 0.114
	#elif ITU_REC==709
		#define KR 0.2126
		#define KB 0.0722
	#elif ITU_REC==2020
		#define KR 0.2627
		#define KB 0.0593
	#endif
	// ...more in the future

	// RGB to YCbCr matrix
	static const float3x3 YCbCrMtx =
		float3x3(
			float3(KR, 1f-KR-KB, KB), // Luma (Y)
			float3(-0.5*KR/(1f-KB), -0.5*(1f-KR-KB)/(1f-KB), 0.5), // Chroma (Cb)
			float3(0.5, -0.5*(1f-KR-KB)/(1f-KR), -0.5*KB/(1f-KR))  // Chroma (Cr)
		);
	// RGB to YCbCr-luma matrix
	static const float3 LumaMtx = float3(KR, 1f-KR-KB, KB); // Luma (Y)
	// RGB to YCbCr-chroma matrix
	static const float3x2 ChromaMtx =
		float3x2(
			float3(-0.5*KR/(1f-KB), -0.5*(1f-KR-KB)/(1f-KB), 0.5), // Chroma (Cb)
			float3(0.5, -0.5*(1f-KR-KB)/(1f-KR), -0.5*KB/(1f-KR))  // Chroma (Cr)
		);
	// YCbCr to RGB matrix
	static const float3x3 RgbMtx =
		float3x3(
			float3(1f, 0f, 2f-2f*KR), // Red
			float3(1f, -KB/(1f-KR-KB)*(2f-2f*KB), -KR/(1f-KR-KB)*(2f-2f*KR)), // Green
			float3(1f, 2f-2f*KB, 0f) // Blue
		);
#endif

	/* FUNCTIONS */

// Convert display gamma for all vector types (approximate)
#define TO_DISPLAY_GAMMA(g) pow(abs(g), rcp(2.2))
#define TO_LINEAR_GAMMA(g) pow(abs(g), 2.2)
/* Convert display gamma for all vector types (sRGB)
Sourced from International Color Consortium, at:
https://color.org/chardata/rgb/srgb.xalter
*/
#define TO_DISPLAY_GAMMA_HQ(g) ((g)<=0.0031308? (g)*12.92 : pow(abs(g), rcp(2.4))*1.055-0.055)
#define TO_LINEAR_GAMMA_HQ(g) ((g)<=0.04049936? (g)/12.92 : pow((abs(g)+0.055)/1.055, 2.4))

// Dither
namespace BlueNoise
{
	/* The blue noise texture
	Obtained under CC0, from
	https://momentsingraphics.de/BlueNoise.html
	*/
	texture BlueNoiseTex
	<
		source = "bluenoise.png";
		pooled = true;
	>{
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

	/* Dither functions
	Usage:
	Transform final color by this function, at the very end of a pixel shader:
		return BlueNoise::dither(uint2(pos.xy), color);
	where "pos.xy" is a variable mapped to
	SV_Position input from a pixel shader.
	*/
	float dither(int2 pixelPos, float gradient)
	{
		// Scale to 8-bit range
		gradient *= 255f;
		// Dither quantization
		return frac(gradient) >= tex2Dfetch(BlueNoiseTexSmp, pixelPos%DITHER_SIZE_TEX)[0] ?
			 ceil(gradient)/255f :
			floor(gradient)/255f;
	}
	float3 dither(int2 pixelPos, float3 color)
	{
		// Scale to 8-bit range
		color *= 255f;
		// Get blue noise repeated texture
		float3 noise = tex2Dfetch(BlueNoiseTexSmp, pixelPos%DITHER_SIZE_TEX).rgb;
		// Get threshold for noise amount
		float3 slope = frac(color);
		// Dither quantization
		[unroll]
		for (uint i=0u; i<3u; i++)
			color[i] = slope[i] >= noise[i] ? ceil(color[i])/255f : floor(color[i])/255f;

		// Dithered color
		return color;
	}
	float4 dither(int2 pixelPos, float4 color)
	{
		// Scale to 8-bit range
		color *= 255f;
		// Get blue noise repeated texture
		float4 noise = tex2Dfetch(BlueNoiseTexSmp, pixelPos%DITHER_SIZE_TEX);
		// Get threshold for noise amount
		float4 slope = frac(color);
		// Dither quantization
		[unroll]
		for (uint i=0u; i<4u; i++)
			color[i] = slope[i] >= noise[i] ? ceil(color[i])/255f : floor(color[i])/255f;

		// Dithered color
		return color;
	}
}