/**
 * Technicolor2 version 1.0
 * Original by Prod80
 * Optimized by CeeJay.dk
 * Further optimized by Marot Satil for the GShade project.
 * License: MIT
 *
 *
 * MIT License
 *
 * Copyright (c) 2020 prod80
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

uniform float3 ColorStrength <
	ui_type = "color";
	ui_tooltip = "Higher means darker and more intense colors.";
> = float3(0.2, 0.2, 0.2);

uniform float Brightness <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 1.5;
	ui_tooltip = "Higher means brighter image.";
> = 1.0;
uniform float Saturation <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.5;
	ui_tooltip = "Additional saturation control since this effect tends to oversaturate the image.";
> = 1.0;

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Adjust the strength of the effect.";
> = 1.0;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 TechnicolorPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = saturate(tex2D(ReShade::BackBuffer, texcoord).rgb);
	
	float3 temp = 1.0 - color;
	float3 target = temp.grg;
	float3 target2 = temp.bbr;
	float3 temp2 = color * target;
	temp2 *= target2;

	temp = temp2 * ColorStrength;
	temp2 *= Brightness;

	target = temp.grg;
	target2 = temp.bbr;

	temp = color - target;
	temp += temp2;
	temp2 = temp - target2;

	color = lerp(color, temp2, Strength);

#if GSHADE_DITHER
	const float3 outcolor = lerp(dot(color, 0.333), color, Saturation);
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp(dot(color, 0.333), color, Saturation);
#endif
}

technique Technicolor2
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = TechnicolorPass;
	}
}
