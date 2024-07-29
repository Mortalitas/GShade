/**
 * Tonemap version 1.1
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 * License: MIT
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

uniform float Gamma <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Adjust midtones. 1.0 is neutral. This setting does exactly the same as the one in Lift Gamma Gain, only with less control.";
> = 1.0;
uniform float Exposure <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Adjust exposure";
> = 0.0;
uniform float Saturation <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Adjust saturation";
> = 0.0;

uniform float Bleach <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Brightens the shadows and fades the colors";
> = 0.0;

uniform float Defog <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "How much of the color tint to remove";
> = 0.0;
uniform float3 FogColor <
	ui_type = "color";
	ui_label = "Defog Color";
	ui_tooltip = "Which color tint to remove";
> = float3(0.0, 0.0, 1.0);


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 TonemapPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = saturate(tex2D(ReShade::BackBuffer, texcoord).rgb - Defog * FogColor * 2.55); // Defog
	color *= pow(2.0f, Exposure); // Exposure
	color = pow(color, Gamma); // Gamma

	const float lum = dot(float3(0.2126, 0.7152, 0.0722), color);

	const float3 A2 = Bleach * color;

	color += ((1.0f - A2) * (A2 * lerp(2.0f * color * lum, 1.0f - 2.0f * (1.0f - lum) * (1.0f - color), saturate(10.0 * (lum - 0.45)))));

	// !!! could possibly branch this with fast_ops
	// !!! to pre-calc 1.0/3.0 and skip calc'ing it each pass
	// !!! and have fast_ops != 1 have it calc each pass.
	// !!! can pre-calc once to use twice below
	const float3 diffcolor = (color - dot(color, (1.0 / 3.0))) * Saturation;

	color = (color + diffcolor) / (1 + diffcolor); // Saturation

#if GSHADE_DITHER
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return color;
#endif
}

technique Tonemap
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = TonemapPass;
	}
}
