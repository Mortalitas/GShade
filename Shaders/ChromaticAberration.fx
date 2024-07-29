/**
 * Chromatic Aberration
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 * License: MIT
 *
 * Distorts the image by shifting each color component, which creates color artifacts similar to those in a very cheap lens or a cheap sensor.
 *
 *
 * The MIT License (MIT)
 * 
 * Copyright (c) 2014 CeeJayDK
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

uniform float2 Shift <
	ui_type = "slider";
	ui_min = -10; ui_max = 10;
	ui_tooltip = "Distance (X,Y) in pixels to shift the color components. For a slightly blurred look try fractional values (.5) between two pixels.";
> = float2(2.5, -0.5);
uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.5;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 ChromaticAberrationPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color, colorInput = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// Sample the color components
	color.r = tex2D(ReShade::BackBuffer, texcoord + (BUFFER_PIXEL_SIZE * Shift)).r;
	color.g = colorInput.g;
	color.b = tex2D(ReShade::BackBuffer, texcoord - (BUFFER_PIXEL_SIZE * Shift)).b;

#if GSHADE_DITHER
	// Adjust the strength of the effect
	color = lerp(colorInput, color, Strength);
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	// Adjust the strength of the effect
	return lerp(colorInput, color, Strength);
#endif
}

technique CA
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromaticAberrationPass;
	}
}
