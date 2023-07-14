/*------------------.
| :: Description :: |
'-------------------/

Color conversion library (version 1.4.0)

Copyright:
This code © 2022-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by/3.0/.
*/

#pragma once

/*-------------.
| :: Macros :: |
'-------------*/

#ifndef ITU_REC
	#define ITU_REC 601
	// #define ITU_REC 709
	// #define ITU_REC 2020
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
