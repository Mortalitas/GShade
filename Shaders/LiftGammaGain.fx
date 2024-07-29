/**
 * Lift Gamma Gain version 1.1
 * by 3an and CeeJay.dk
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

uniform float3 RGB_Lift <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "RGB Lift";
	ui_tooltip = "Adjust shadows for red, green and blue.";
> = float3(1.0, 1.0, 1.0);
uniform float3 RGB_Gamma <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "RGB Gamma";
	ui_tooltip = "Adjust midtones for red, green and blue.";
> = float3(1.0, 1.0, 1.0);
uniform float3 RGB_Gain <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "RGB Gain";
	ui_tooltip = "Adjust highlights for red, green and blue.";
> = float3(1.0, 1.0, 1.0);


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 LiftGammaGainPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	// -- Lift --
	color = color * (1.5 - 0.5 * RGB_Lift) + 0.5 * RGB_Lift - 0.5;
	color = saturate(color); // Is not strictly necessary, but does not cost performance
	
	// -- Gain --
	color *= RGB_Gain; 
	
	// -- Gamma --
#if GSHADE_DITHER
	color = saturate(pow(abs(color), 1.0 / RGB_Gamma));
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(pow(abs(color), 1.0 / RGB_Gamma));
#endif
}


technique LiftGammaGain
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LiftGammaGainPass;
	}
}
