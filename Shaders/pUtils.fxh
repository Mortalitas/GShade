///////////////////////////////////////////////////////////////////////////////////
// pUils.fxh by Gimle Larpes
// License: MIT
// Repository: https://github.com/GimleLarpes/potatoFX
//
// MIT License
//
// Copyright (c) 2023 Gimle Larpes
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///////////////////////////////////////////////////////////////////////////////////

//Version check
#ifndef _P_UTILS_VERSION
	#define _P_UTILS_VERSION 100
#endif

#if _P_UTILS_VERSION < P_UTILS_VERSION_REQUIRE
	#error "Outdated pUtils.fxh installation - Download update from: github.com/GimleLarpes/potatoFX/"
#endif
#if !defined(P_UTILS_VERSION_REQUIRE)
	#error "Incompatible Oklab.fxh file - Download update from: github.com/GimleLarpes/potatoFX/"
#endif


namespace pUtils
{
	//Uniforms
	uniform float FrameTime < source = "frametime"; >;
	uniform int FrameCount < source = "framecount"; >;

	//Constants
	static const float PI = 3.1415927;
	static const float EPSILON = 1e-10;
	static const float2 ASPECT_RATIO = float2(1.0, 1.0/BUFFER_ASPECT_RATIO);


	//Functions
	//--fastatan2
	float fastatan2(float y, float x)//error < 0.2 degrees, saves about 40% vs atan2 developed by Lord of Lunacy and Marty McFly
	{
		bool a = abs(y) < abs(x);    
		float i = (a) ? (y * rcp(x)) : (x * rcp(y));    
		i = i * (1.0584 + abs(i) * -0.273);
		float piadd = y > 0 ? PI : -PI;     
		i = a ? (x < 0 ? piadd : 0) + i : 0.5 * piadd - i;
		return i;
	}

	//--cbrt
	float cbrt(float v)
	{
		return sign(v) * pow(abs(v), 0.33333333);
	}
	float3 cbrt(float3 v)
	{
		return sign(v) * pow(abs(v), 0.33333333);
	}

	//--clerp, lerps the shortest way between two angles
	float clerp(float v, float t, float w)
	{   
		return v + (((t - v) % PI + 1.5 * PI) % PI) * w;
	}

	//--cdistance, returns the shortest distance between two angles
	float cdistance(float v, float t)
	{   
		float d = abs(t - v);
		return (d > PI)
			? 2.0 * PI - d
			: d;
	}

	//--wnoise, returns time variable white noise
	float wnoise(float2 uv, float2 d)
	{
		float t = float(FrameCount % 1000 + 1);
		return frac(sin(dot(uv - 0.5, d) * t) * 143758.5453);
	}
}