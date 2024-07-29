////////////////////////////////////////////////////////
// FXShadersBlending.fxh
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

namespace FXShaders
{

/**
 * Standard screen blend mode.
 *
 * @param a The original color, normalized.
 * @param b The color to blend with the original color, normalized.
 * @param w How much to blend with the original color.
 *          If set to 0.0 the result will be the original color left intact.
 */
float3 BlendScreen(float3 a, float3 b, float w)
{
	return 1.0 - (1.0 - a) * (1.0 - b * w);
}

/**
 * Standard overlay blend mode.
 *
 * @param a The original color, normalized.
 * @param b The color to blend with the original color, normalized.
 * @param w How much to blend with the original color.
 *          If set to 0.0 the result will be the original color left intact.
 */
float3 BlendOverlay(float3 a, float3 b, float w)
{
	float3 color;
	if (a.x < 0.5 || a.y < 0.5 || a.z < 0.5)
		color = 2.0 * a * b;
	else
		color = 1.0 - 2.0 * (1.0 - a) * (1.0 - b);

	return lerp(a, color, w);
}

/**
 * Standard soft light blend mode.
 *
 * @param a The original color, normalized.
 * @param b The color to blend with the original color, normalized.
 * @param w How much to blend with the original color.
 *          If set to 0.0 the result will be the original color left intact.
 */
float3 BlendSoftLight(float3 a, float3 b, float w)
{
	return lerp(a, (1.0 - 2.0 * b) * (a * a) + 2.0 * b * a, w);
}

/**
 * Standard hard light blend mode.
 *
 * @param a The original color, normalized.
 * @param b The color to blend with the original color, normalized.
 * @param w How much to blend with the original color.
 *          If set to 0.0 the result will be the original color left intact.
 */
float3 BlendHardLight(float3 a, float3 b, float w)
{
	float3 color;
	if (a.x > 0.5 || a.y > 0.5 || a.z > 0.5)
		color = 2.0 * a * b;
	else
		color = 1.0 - 2.0 * (1.0 - a) * (1.0 - b);

	return lerp(a, color, w);
}

}
