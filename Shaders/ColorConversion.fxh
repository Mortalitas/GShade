/*------------------.
| :: Description :: |
'-------------------/

Color conversion library (version 1.5.0)

Author:
Jakub Maksymilian Fober

First publication:
2022-2023

Copyright:
This work is free of known copyright restrictions.
https://creativecommons.org/publicdomain/mark/1.0/
*/

#pragma once

/*-------------.
| :: Macros :: |
'-------------*/

// These are from the "color_space" enum in ReShade.
// They can be compared against "BUFFER_COLOR_SPACE", which is defined by ReShade shaders.
#ifndef RESHADE_COLOR_SPACE_UNKNOWN
#define RESHADE_COLOR_SPACE_UNKNOWN     0
#endif
#ifndef RESHADE_COLOR_SPACE_SRGB
#define RESHADE_COLOR_SPACE_SRGB        1
#endif
#ifndef RESHADE_COLOR_SPACE_SCRGB
#define RESHADE_COLOR_SPACE_SCRGB       2
#endif
#ifndef RESHADE_COLOR_SPACE_BT2020_PQ
#define RESHADE_COLOR_SPACE_BT2020_PQ   3
#endif

#ifndef ITU_REC
#if BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_BT2020_PQ
	#define ITU_REC 2020
#else
	#define ITU_REC 709
	//#define ITU_REC 601
#endif
#endif

/*----------------.
| :: Constants :: |
'----------------*/

namespace ColorConvert
{
	// YCbCr coefficients
	#if ITU_REC==601
		#define _KR 0.299
		#define _KB 0.114
	#elif ITU_REC==709
		#define _KR 0.2126
		#define _KB 0.0722
	#elif ITU_REC==2020
		#define _KR 0.2627
		#define _KB 0.0593
	#endif

	// RGB to YCbCr matrix
	static const float3x3 YCbCrMtx =
		float3x3(
			float3(_KR, 1f-_KR-_KB, _KB), // Luma (Y)
			float3(-0.5*_KR/(1f-_KB), -0.5*(1f-_KR-_KB)/(1f-_KB), 0.5), // Chroma (Cb)
			float3(0.5, -0.5*(1f-_KR-_KB)/(1f-_KR), -0.5*_KB/(1f-_KR))  // Chroma (Cr)
		);

	// YCbCr to RGB matrix
	static const float3x3 RGBMtx =
		float3x3(
			float3(1f, 0f, 2f-2f*_KR), // Red
			float3(1f, -_KB/(1f-_KR-_KB)*(2f-2f*_KB), -_KR/(1f-_KR-_KB)*(2f-2f*_KR)), // Green
			float3(1f, 2f-2f*_KB, 0f) // Blue
		);

/*----------------.
| :: Functions :: |
'----------------*/

	float3 RGB_to_YCbCr(float3 color)  // color in YCbCr from sRGB input
	{ return mul(YCbCrMtx, color);}
	float  RGB_to_Luma(float3 color)   // luma component of YCbCr from sRGB color input
	{ return dot(YCbCrMtx[0], color);}
	float2 RGB_to_Chroma(float3 color) // chroma component of YCbCr from sRGB color input
	{ return float2(dot(YCbCrMtx[1], color), dot(YCbCrMtx[2], color));}

	float3 YCbCr_to_RGB(float3 color)  // color in sRGB from YCbCr input
	{ return mul(RGBMtx, color);}
}
