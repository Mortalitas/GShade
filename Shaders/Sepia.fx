/*------------------.
| :: Description :: |
'-------------------/

	Sepia

	Author: CeeJay.dk
	License: MIT

	About:
	Lightly optimized by Marot Satil for the GShade project.


	The MIT License (MIT)

	Copyright (c) 2014 CeeJayDK

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

uniform float3 Tint <
	ui_type = "color";
> = float3(0.55, 0.43, 0.42);

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Adjust the strength of the effect.";
> = 0.58;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 TintPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
#if GSHADE_DITHER
	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	col = lerp(col, col * Tint * 2.55, Strength);
	return col + TriDither(col, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	const float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	return lerp(col, col * Tint * 2.55, Strength);
#endif
}

technique Tint
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = TintPass;
	}
}
