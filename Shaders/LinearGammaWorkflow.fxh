/*------------------.
| :: Description :: |
'-------------------/

Linear Gamma Workflow Library (version 1.4.0)

Copyright:
This code © 2022-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by/3.0/.
*/

#pragma once

/*----------------.
| :: Functions :: |
'----------------*/

namespace GammaConvert
{
	// Convert display gamma for all vector types
	#if BUFFER_COLOR_SPACE == 1 || BUFFER_COLOR_SPACE == 2 // Transform from and to sRGB gamma
		// Sourced from International Color Consortium, at https://color.org/chardata/rgb/srgb.xalter
		#define _TO_DISPLAY_GAMMA(g) ((g)<=0.0031308? (g)*12.92 : pow(abs(g), rcp(2.4))*1.055-0.055)
		#define _TO_LINEAR_GAMMA(g)  ((g)<=0.04049936? (g)/12.92 : pow((abs(g)+0.055)/1.055, 2.4))
//	#elif BUFFER_COLOR_SPACE == 3 // Transform from and to HDR10 ST 2084
//		#define _TO_DISPLAY_GAMMA(g) (pow(abs((0.8359375+18.8515625*pow(abs(g), 0.1593017578125))/(1f+18.6875*pow(abs(g), 0.1593017578125))), 78.84375))
//		#define _TO_LINEAR_GAMMA(g)  (pow(abs(max(pow(abs(g), 32f/2523f)-0.8359375, 0f)/(18.8515625-18.6875*pow(abs(g), 32f/2523f))), 8192f/1305f))
	#else // Bypass transform
		#define _TO_DISPLAY_GAMMA(g) (g)
		#define _TO_LINEAR_GAMMA(g)  (g)
	#endif
	// Gamma transform function: linear ↦ gammaRGB
	float  to_display(float  g) { return _TO_DISPLAY_GAMMA(g); }
	float2 to_display(float2 g) { return _TO_DISPLAY_GAMMA(g); }
	float3 to_display(float3 g) { return _TO_DISPLAY_GAMMA(g); }
	float4 to_display(float4 g) { return _TO_DISPLAY_GAMMA(g); }
	// Gamma transform function: gammaRGB ↦ linear
	float  to_linear( float  g) { return _TO_LINEAR_GAMMA(g); }
	float2 to_linear( float2 g) { return _TO_LINEAR_GAMMA(g); }
	float3 to_linear( float3 g) { return _TO_LINEAR_GAMMA(g); }
	float4 to_linear( float4 g) { return _TO_LINEAR_GAMMA(g); }
}
