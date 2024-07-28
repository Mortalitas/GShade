////////////////////////////////////////////////////////
// Grain Spread
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

#include "ReShade.fxh"

uniform float Opacity
<
	ui_type = "slider";
	ui_label = "Opacity";
	ui_tooltip = "Default: 0.5";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.5;

uniform float Spread
<
	ui_type = "slider";
	ui_label = "Spread";
	ui_tooltip = "Default: 0.5";
	ui_min = 0.0;
	ui_max = 500.0;
> = 1.0;

uniform float Speed
<
	ui_type = "slider";
	ui_label = "Speed";
	ui_tooltip = "Default: 1.0";
	ui_min = 0.0;
	ui_max = 1.0;
> = 1.0;

uniform float GlobalGrain
<
	ui_type = "slider";
	ui_label = "Global Grain";
	ui_tooltip = "Default: 0.5";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.5;

uniform int BlendMode
<
	ui_type = "combo";
	ui_label = "Blend Mode";
	ui_items = "Mix\0Addition\0Screen\0Lighten-Only\0";
> = 0;

uniform float Timer <source = "timer";>;

float rand(float2 uv, float t) {
    return frac(sin(dot(uv, float2(1225.6548, 321.8942))) * 4251.4865 + t);
}

float4 MainPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	const float t = Timer * 0.001 * Speed;
	const float2 scale = Spread;
	float2 offset = float2(rand(uv, t), rand(uv.yx, t));
	offset = min(max(offset * scale - scale * 0.5, 7), -8);

	float3 grain = tex2Doffset(ReShade::BackBuffer, uv, int2(offset)).rgb;
	grain *= log10(Spread * 0.5 - distance(uv, uv + offset * ReShade::PixelSize));
	grain *= lerp(1.0, rand(uv + uv.yx, t), GlobalGrain);
	//grain *= saturate(length(offset));

	float3 color = tex2D(ReShade::BackBuffer, uv).rgb;

	switch (BlendMode)
	{
		case 0: // Mix
			color = lerp(color, max(color, grain), Opacity);
			break;
		case 1: // Addition
			color += grain * Opacity;
			break;
		case 2: // Screen
			color = 1.0 - (1.0 - color) * (1.0 - grain * Opacity);
			break;
		case 3: // Lighten-Only
			color = max(color, grain * Opacity);
			break;
	}
	
	return float4(color, 1.0);
}

technique GrainSpread
{
	pass MainPS
	{
		VertexShader = PostProcessVS;
		PixelShader = MainPS;
	}
}