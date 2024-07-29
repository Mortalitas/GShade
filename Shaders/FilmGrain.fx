/**
 * FilmGrain version 1.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 * License: MIT
 *
 * Computes a noise pattern and blends it with the image to create a film grain look.
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

uniform float Intensity <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "How visible the grain is. Higher is more visible.";
> = 0.50;
uniform float Variance <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Controls the variance of the Gaussian noise. Lower values look smoother.";
> = 0.40;
uniform float Mean <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Affects the brightness of the noise.";
> = 0.5;

uniform int SignalToNoiseRatio <
	ui_type = "slider";
	ui_min = 0; ui_max = 16;
	ui_label = "Signal-to-Noise Ratio";
	ui_tooltip = "Higher Signal-to-Noise Ratio values give less grain to brighter pixels. 0 disables this feature.";
> = 6;

uniform float Timer < source = "timer"; >;

#include "ReShade.fxh"

float3 FilmGrainPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float inv_luma = dot(color, float3(-1.0/3.0, -1.0/3.0, -1.0/3.0)) + 1.0; //Calculate the inverted luma so it can be used later to control the variance of the grain
  
	/*---------------------.
	| :: Generate Grain :: |
	'---------------------*/

	const float PI = 3.1415927;
	
	//time counter using requested counter from ReShade
	const float t = Timer * 0.0022337;
	
	//PRNG 2D - create two uniform noise values and save one DP2ADD
	const float seed = dot(texcoord, float2(12.9898, 78.233));// + t;
	const float sine = sin(seed);
	const float cosine = cos(seed);
	float uniform_noise1 = frac(sine * 43758.5453 + t); //I just salt with t because I can
	const float uniform_noise2 = frac(cosine * 53758.5453 - t); // and it doesn't cost any extra ASM

	//Get settings
	float stn;
	if (SignalToNoiseRatio != 0)
		stn = pow(abs(inv_luma), (float)SignalToNoiseRatio);
	else
		stn = 1.0;
	const float variance = (Variance*Variance) * stn;
	const float mean = Mean;

	//Box-Muller transform
	if (uniform_noise1 < 0.0001)
		uniform_noise1 = 0.0001; //fix log(0)
		
	float r = sqrt(-log(uniform_noise1));
	if (uniform_noise1 < 0.0001)
		r = PI; //fix log(0) - PI happened to be the right answer for uniform_noise == ~ 0.0000517.. Close enough and we can reuse a constant.
	const float theta = (2.0 * PI) * uniform_noise2;
	
	const float gauss_noise1 = variance * r * cos(theta) + mean;

	//Calculate how big the shift should be
	const float grain = lerp(1.0 + Intensity,  1.0 - Intensity, gauss_noise1);
  
	//float grain2 = (2.0 * Intensity) * gauss_noise1 + (1.0 - Intensity);
	 
	//Apply grain
	color = color * grain;
  
	//color = (grain-1.0) *2.0 + 0.5;
  
	//color = lerp(color,colorInput.rgb,sqrt(luma));

	/*-------------------------.
	| :: Debugging features :: |
	'-------------------------*/

	//color.rgb = frac(gauss_noise1).xxx; //show the noise
	//color.rgb = (gauss_noise1 > 0.999) ? float3(1.0,1.0,0.0) : 0.0 ; //does it reach 1.0?
	
	return color.rgb;
}

technique FilmGrain
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FilmGrainPass;
	}
}
