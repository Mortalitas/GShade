////////////////////////////////////////////////////////
// FXShadersAspectRatio.fxh
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

#define FXSHADERS_ASPECT_RATIO_SCALE_TYPE_LIST \
"Cover\0" \
"Fit\0" \
"Stretch\0"

namespace FXShaders { namespace AspectRatio
{

namespace ScaleType
{
	static const int Cover = 0;
	static const int Fit = 1;
	static const int Stretch = 2;
}

float2 CoverScale(float2 uv)
{
	if (BUFFER_WIDTH > BUFFER_HEIGHT)
		return float2(1.0, BUFFER_HEIGHT * BUFFER_RCP_WIDTH);
	else
		return float2(BUFFER_WIDTH * BUFFER_RCP_HEIGHT, 1.0);
}

float2 FitScale(float2 uv)
{
	if (BUFFER_WIDTH > BUFFER_HEIGHT)
		return float2(BUFFER_WIDTH * BUFFER_RCP_HEIGHT, 1.0);
	else
		return float2(1.0, BUFFER_HEIGHT * BUFFER_RCP_WIDTH);
}

float2 ApplyScale(int type, float2 uv)
{
	switch (type)
	{
		case ScaleType::Cover:
			return CoverScale(uv);
		case ScaleType::Fit:
			return FitScale(uv);
		// case ScaleType::Stretch:
		default:
			return uv;
	}
}

}} // Namespace.
