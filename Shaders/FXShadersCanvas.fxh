////////////////////////////////////////////////////////
// FXShadersCanvas.fxh
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

/*

	FXShaders headers for common primitive functions.

*/

namespace FXShaders
{

/**
 * Fill a rectangle with color into a given buffer.
 *
 * @param color The current pixel color of the buffer to draw on.
 * @param coord The current pixel coordinate in the range 0<->resolution.
 * @param rect The rectangle of the area to fill in.
 * @param fillColor The color to fill the rectangle area with.
 */
void FillRect(inout float4 color, float2 coord, float4 rect, float4 fillColor)
{
	if (
		coord.x >= rect.x && coord.x <= rect.z &&
		coord.y >= rect.y && coord.y <= rect.w)
	{
		color = fillColor;
	}
}

/**
 * Convert a position and size to a rectangle type.
 *
 * @param pos The center position of the rectangle.
 * @param size The size of the rectangle.
 */
float4 ConvertToRect(float2 pos, float2 size)
{
	return mad(float2(-0.5, 0.5).xxyy, size.xyxy, pos.xyxy);
}

/*
    y           y
  +---+       +---+
x | A | z   x | B | z
  +---+       +---+
    w           w
*/
/**
 * Test collision between two rects.
 *
 * @param a The first rect in the collision test.
 * @param b The second rect in the collision test.
 */
bool AABBCollision(float4 a, float4 b)
{
	return
		a.x < b.z && b.x < a.z &&
		a.y < b.w && b.y < a.w;
}

}
