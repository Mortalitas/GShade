/**
 * Color Matrix version 1.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 * License: MIT
 *
 * ColorMatrix allow the user to transform the colors using a color matrix
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
 // Lightly optimized by Marot Satil for the GShade project.

uniform float3 ColorMatrix_Red <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Matrix Red";
	ui_tooltip = "How much of a red, green and blue tint the new red value should contain. Should sum to 1.0 if you don't wish to change the brightness.";
> = float3(0.817, 0.183, 0.000);
uniform float3 ColorMatrix_Green <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Matrix Green";
	ui_tooltip = "How much of a red, green and blue tint the new green value should contain. Should sum to 1.0 if you don't wish to change the brightness.";
> = float3(0.333, 0.667, 0.000);
uniform float3 ColorMatrix_Blue <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Matrix Blue";
	ui_tooltip = "How much of a red, green and blue tint the new blue value should contain. Should sum to 1.0 if you don't wish to change the brightness.";
> = float3(0.000, 0.125, 0.875);

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 ColorMatrixPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float3x3 ColorMatrix = float3x3(ColorMatrix_Red, ColorMatrix_Green, ColorMatrix_Blue);

#if GSHADE_DITHER
	const float3 outcolor = saturate(lerp(color, mul(ColorMatrix, color), Strength));
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(lerp(color, mul(ColorMatrix, color), Strength));
#endif
}

technique ColorMatrix
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ColorMatrixPass;
	}
}
