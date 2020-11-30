// VRS_Map.fxh
//
// Copyright (c) 2020 Advanced Micro Devices, Inc. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

/*
	Variable Rate Shading Map for ReShade
	Port and Framework by: Lord of Lunacy
	https://github.com/LordOfLunacy/Insane-Shaders
	
	This is a port of the VRS Image generation shader in AMD's FidelityFX,
	currently it is lacking support for tile sizes besides 8, and the
	option for more shading rates.
	https://github.com/GPUOpen-Effects/FidelityFX-VariableShading
	
	To make the shader compatible with ReshadeFX, I had to replace the wave intrinsics
	with atomic intrinsics.
	
	
	The method used for the optical flow was provided by Jose Negrete AKA BlueSkyDefender
	<UntouchableBlueSky@gmail.com>
	https://github.com/BlueSkyDefender/
*/
	
	
	
	
/*	
	This header file contains all the common functions and variables that
	should be needed to allow the implementation of optimizations based on
	the map that is generated.
*/


/*
//--------------------------------------------------------------------------------------//
// Common Intercept Code
// (Copy and paste this code into your shader to help with interception of it)
//--------------------------------------------------------------------------------------//
#define __SUPPORTED_VRS_MAP_COMPATIBILITY__ 10

#if exists "VRS_Map.fxh"                                          
    #include "VRS_Map.fxh"
	#ifndef VRS_MAP
		#define VRS_MAP 1
	#endif
#else
    #define VRS_MAP 0
#endif

//Define the necessary functions and constants so the code can't break when the .fxh isn't present
#if VRS_MAP == 0
static const uint VRS_RATE1D_1X = 0x0;
static const uint VRS_RATE1D_2X = 0x1;
static const uint VRS_RATE1D_4X = 0x2;
#define VRS_MAKE_SHADING_RATE(x,y) ((x << 2) | (y))

static const uint VRS_RATE_1X1 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, VRS_RATE1D_1X); // 0;
static const uint VRS_RATE_1X2 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, VRS_RATE1D_2X); // 0x1;
static const uint VRS_RATE_2X1 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_1X); // 0x4;
static const uint VRS_RATE_2X2 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_2X); // 0x5;
//Only up to 2X2 is implemented currently
static const uint VRS_RATE_2X4 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_4X); // 0x6;
static const uint VRS_RATE_4X2 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_4X, VRS_RATE1D_2X); // 0x9;
static const uint VRS_RATE_4X4 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_4X, VRS_RATE1D_4X); // 0xa;

namespace VRS_Map
{
	uint ShadingRate(float2 texcoord, bool UseVRS)
	{
		return 0;
	}
	uint ShadingRate(float2 texcoord, float VarianceCutoff, bool UseVRS)
	{
		return 0;
	}
	uint ShadingRate(float2 texcoord, bool UseVRS, uint offRate)
	{
		return offRate;
	}
	uint ShadingRate(float2 texcoord, float VarianceCutoff, bool UseVRS, uint offRate)
	{
		return offRate;
	}
	float3 DebugImage(float3 originalImage, float2 texcoord, float VarianceCutoff, bool DebugView)
	{
		return originalImage;
	}
}
#endif //VRS_MAP
*/

#define RENDERER __RENDERER__


#define __VRS_MAP_COMPATIBILITY_VERSION__ 10 

#if __VRS_MAP_COMPATIBILITY_VERSION__ != __SUPPORTED_VRS_MAP_COMPATIBILITY__
	#define _VRS_INCOMPATIBLE 1
#else
	#define _VRS_INCOMPATIBLE 0
#endif

#if (((RENDERER >= 0xb000 && RENDERER < 0x10000) || (RENDERER >= 0x14300)) && __RESHADE__ >=40802)
	#ifndef _VRS_COMPUTE
	#define _VRS_COMPUTE 1
	#endif
#else
	#ifndef _VRS_COMPUTE
	#define _VRS_COMPUTE 0
	#endif
#endif

#ifndef VRS_USE_OPTICAL_FLOW
	#define VRS_USE_OPTICAL_FLOW 0
#endif

#if (_VRS_COMPUTE != 0 && _VRS_INCOMPATIBLE == 0)

uniform int VRS_FrameCount < source = "framecount";>;
#define DIVIDE_ROUNDING_UP(a, b) (uint(uint(a + b - 1) / uint(b)))

#define TILE_SIZE 8

#define VRS_IMAGE_SIZE (uint2(DIVIDE_ROUNDING_UP(BUFFER_WIDTH, TILE_SIZE), DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, TILE_SIZE)))
#define THREAD_GROUPS (uint2(DIVIDE_ROUNDING_UP(VRS_IMAGE_SIZE.x, 2), DIVIDE_ROUNDING_UP(VRS_IMAGE_SIZE.y, 2)))

#define VRS_LAST_UPDATE (asint(tex2Dfetch(sVRSUpdated, int2(0, 0)).x))
#define VRS_IS_UPDATED (bool((int(VRS_LAST_UPDATE) == VRS_FrameCount) || (int(VRS_LAST_UPDATE) == (VRS_FrameCount - 1))))


texture VRS {Width = VRS_IMAGE_SIZE.x; Height = VRS_IMAGE_SIZE.y; Format = RGBA8;};
texture VRSUpdated {Width = 1; Height = 1; Format = R32f;};

sampler sVRS {Texture = VRS;};
sampler sVRSUpdated {Texture = VRSUpdated;};


static const uint VRS_RATE1D_1X = 0x0;
static const uint VRS_RATE1D_2X = 0x1;
static const uint VRS_RATE1D_4X = 0x2;
#define VRS_MAKE_SHADING_RATE(x,y) ((x << 2) | (y))

static const uint VRS_RATE_1X1 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, VRS_RATE1D_1X); // 0;
static const uint VRS_RATE_1X2 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, VRS_RATE1D_2X); // 0x1;
static const uint VRS_RATE_2X1 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_1X); // 0x4;
static const uint VRS_RATE_2X2 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_2X); // 0x5;
//Only up to 2X2 is implemented currently
static const uint VRS_RATE_2X4 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_4X); // 0x6;
static const uint VRS_RATE_4X2 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_4X, VRS_RATE1D_2X); // 0x9;
static const uint VRS_RATE_4X4 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_4X, VRS_RATE1D_4X); // 0xa;

namespace VRS_Map
{
	//uses the uniform set by VariableRateShading for the VarianceCutoff
	uint ShadingRate(float2 texcoord, bool UseVRS)
	{
		if(!VRS_IS_UPDATED || !UseVRS)
		{
			return 0;
		}
		else
		{
			return uint(tex2Dfetch(sVRS, int2(texcoord * VRS_IMAGE_SIZE)).w * 255);
		}
	}
	
	//uses a custom input for the variance cutoff, the custom cutoff must be less than 0.25
	//otherwise the shading rate will be reduced everywhere
	uint ShadingRate(float2 texcoord, float VarianceCutoff, bool UseVRS)
	{
		if(!VRS_IS_UPDATED || !UseVRS)
		{
			return 0;
		}
		else
		{
			float3 variances = (tex2Dfetch(sVRS, int2(texcoord * VRS_IMAGE_SIZE)).xyz / 4);
			float varH = variances.x;
			float varV = variances.y;
			float var = variances.z;
			uint shadingRate = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, VRS_RATE1D_1X);

			if (var < VarianceCutoff)
			{
				shadingRate = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_2X);
			}
			else
			{
				if (varH > varV)
				{
					shadingRate = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, (varV > VarianceCutoff) ? VRS_RATE1D_1X : VRS_RATE1D_2X);
				}
				else
				{
					shadingRate = VRS_MAKE_SHADING_RATE((varH > VarianceCutoff) ? VRS_RATE1D_1X : VRS_RATE1D_2X, VRS_RATE1D_1X);
				}
			}
			return shadingRate;
		}
	}
	
	//uses the uniform set by VariableRateShading for the VarianceCutoff, also, it defines a custom shading rate that
	//will be used when it is disabled rather than the default 0.
	uint ShadingRate(float2 texcoord, bool UseVRS, uint offRate)
	{
		if(!VRS_IS_UPDATED || !UseVRS)
		{
			return offRate;
		}
		else
		{
			return uint(tex2Dfetch(sVRS, int2(texcoord * VRS_IMAGE_SIZE)).w * 255);
		}
	}
	
	//uses a custom input for the variance cutoff, the custom cutoff must be less than 0.25
	//otherwise the shading rate will be reduced everywhere, also, it defines a custom shading rate that
	//will be used when it is disabled rather than the default 0.
	uint ShadingRate(float2 texcoord, float VarianceCutoff, bool UseVRS, uint offRate)
	{
		if(!VRS_IS_UPDATED || !UseVRS)
		{
			return offRate;
		}
		else
		{
			float3 variances = (tex2Dfetch(sVRS, int2(texcoord * VRS_IMAGE_SIZE)).xyz / 4);
			float varH = variances.x;
			float varV = variances.y;
			float var = variances.z;
			uint shadingRate = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, VRS_RATE1D_1X);

			if (var < VarianceCutoff)
			{
				shadingRate = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_2X);
			}
			else
			{
				if (varH > varV)
				{
					shadingRate = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, (varV > VarianceCutoff) ? VRS_RATE1D_1X : VRS_RATE1D_2X);
				}
				else
				{
					shadingRate = VRS_MAKE_SHADING_RATE((varH > VarianceCutoff) ? VRS_RATE1D_1X : VRS_RATE1D_2X, VRS_RATE1D_1X);
				}
			}
			return shadingRate;
		}
	}
	float3 DebugImage(float3 originalImage, float2 texcoord, float VarianceCutoff, bool DebugView)
	{
		if(DebugView)
		{
			// encode different shading rates as colors
			float3 color = float3(1, 1, 1);

			switch (ShadingRate(texcoord, VarianceCutoff, true))
			{
				case VRS_RATE_1X1:
					color = float3(0.5, 0.0, 0.0);
					break;
				case VRS_RATE_1X2:
					color = float3(0.5, 0.5, 0.0);
					break;
				case VRS_RATE_2X1:
					color = float3(0.5, 0.25, 0.0);
					break;
				case VRS_RATE_2X2:
					color = float3(0.0, 0.5, 0.0);
					break;
				case VRS_RATE_2X4:
					color = float3(0.25, 0.25, 0.5);
					break;
				case VRS_RATE_4X2:
					color = float3(0.5, 0.25, 0.5);
					break;
				case VRS_RATE_4X4:
					color = float3(0.0, 0.5, 0.5);
					break;
			}
			// add grid
			color = lerp(color, originalImage, 0.35);
			int2 grid = uint2(texcoord.xy * float2(BUFFER_WIDTH, BUFFER_HEIGHT)) % TILE_SIZE;
			bool border = (grid.x == 0) || (grid.y == 0);
			return color * (border ? 0.5f : 1.0f);
		}
		else
		{
			return originalImage;
		}
	}
}
#elif _VRS_INCOMPATIBLE != 0
	#define VRS_MAP 0
#else
static const uint VRS_RATE1D_1X = 0x0;
static const uint VRS_RATE1D_2X = 0x1;
static const uint VRS_RATE1D_4X = 0x2;
#define VRS_MAKE_SHADING_RATE(x,y) ((x << 2) | (y))

static const uint VRS_RATE_1X1 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, VRS_RATE1D_1X); // 0;
static const uint VRS_RATE_1X2 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_1X, VRS_RATE1D_2X); // 0x1;
static const uint VRS_RATE_2X1 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_1X); // 0x4;
static const uint VRS_RATE_2X2 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_2X); // 0x5;
//Only up to 2X2 is implemented currently
static const uint VRS_RATE_2X4 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_2X, VRS_RATE1D_4X); // 0x6;
static const uint VRS_RATE_4X2 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_4X, VRS_RATE1D_2X); // 0x9;
static const uint VRS_RATE_4X4 = VRS_MAKE_SHADING_RATE(VRS_RATE1D_4X, VRS_RATE1D_4X); // 0xa;

namespace VRS_Map
{
	uint ShadingRate(float2 texcoord, bool UseVRS)
	{
		return 0;
	}
	uint ShadingRate(float2 texcoord, float VarianceCutoff, bool UseVRS)
	{
		return 0;
	}
	uint ShadingRate(float2 texcoord, bool UseVRS, uint offRate)
	{
		return offRate;
	}
	uint ShadingRate(float2 texcoord, float VarianceCutoff, bool UseVRS, uint offRate)
	{
		return offRate;
	}
	float3 DebugImage(float3 originalImage, float2 texcoord, float VarianceCutoff, bool DebugView)
	{
		return originalImage;
	}
}
#endif //(_VRS_COMPUTE != 0 && _VRS_INCOMPATIBLE == 0)
