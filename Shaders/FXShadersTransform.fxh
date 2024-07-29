////////////////////////////////////////////////////////
// FXShadersTransform.fxh
// Author: luluco250
// License: MIT
// Repository: https://github.com/luluco250/FXShaders
////////////////////////////////////////////////////////
/*
MIT License

Copyright (c) 2017 Lucas Melo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#pragma once

#include "FXShadersAspectRatio.fxh"

namespace FXShaders { namespace Transform
{

float2 FisheyeLens(
	int aspectRatioScaleType,
	float2 uv,
	float amount,
	float zoom)
{
	uv = uv * 2.0 - 1.0;

	const float2 fishUv = uv * AspectRatio::ApplyScale(aspectRatioScaleType, uv);

	uv = ((uv * lerp(1.0, sqrt(1.0 - fishUv.x * fishUv.x - fishUv.y * fishUv.y) * zoom, amount)) + 1.0) * 0.5;

	return uv;
}

}
}
