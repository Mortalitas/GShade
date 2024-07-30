///////////////////////////////////////////////////////////////////////////////////
// pPalettePosterize.fx by Gimle Larpes
// Posterizes an image to a custom color palette.
// License: MIT
// Repository: https://github.com/GimleLarpes/potatoFX
//
// MIT License
//
// Copyright (c) 2023 Gimle Larpes
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///////////////////////////////////////////////////////////////////////////////////

#define P_OKLAB_VERSION_REQUIRE 100
#include "ReShade.fxh"
#include "Oklab.fxh"

//Clamp invnorm factor to prevent fp precision errors
#ifndef _POSTERIZE_MAX_INVNORM_FACTOR
	#define _POSTERIZE_MAX_INVNORM_FACTOR 12.5 //1000 nits
#endif

uniform int PaletteType <
	ui_type = "radio";
	ui_label = "Color palette";
	ui_tooltip = "Type of color palette to use";
	ui_items = "Monochrome\0Analogous\0Complementary\0Triadic\0All colors\0";
	ui_category = "Settings";
> = 2;
uniform float3 BaseColor <
	ui_type = "color";
	ui_label = "Base Color";
	ui_tooltip = "Color from which other colors are calculated";
	ui_category = "Settings";
> = float3(0.52, 0.05, 0.05);
uniform float NumColors <
	ui_type = "slider";
	ui_label = "Number of colors";
	ui_min = 2.0; ui_max = 16.0; ui_step = 1.0;
	ui_tooltip = "Number of colors to posterize to";
	ui_category = "Settings";
> = 4;
uniform float PaletteBalance <
	ui_type = "slider";
	ui_label = "Palette Balance";
	ui_min = 0.001; ui_max = 1.0;
	ui_tooltip = "Adjusts thresholds for color palette";
	ui_category = "Settings";
> = 0.5;
uniform float DitheringFactor <
	ui_type = "slider";
	ui_label = "Dithering";
	ui_min = 0.0; ui_max = 0.1;
	ui_tooltip = "Amount of dithering to be applied";
	ui_category = "Settings";
> = 0.02;
uniform bool DesaturateHighlights <
	ui_type = "bool";
	ui_label = "Desaturate highlights";
	ui_tooltip = "Creates a less harsh image";
	ui_category = "Settings";
> = false;
uniform float DesaturateFactor <
	ui_type = "slider";
	ui_label = "Desaturate amount";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "How much to desaturate highlights";
	ui_category = "Settings";
> = 0.75;
uniform bool UseApproximateTransforms <
	ui_type = "bool";
	ui_label = "Fast colorspace transform";
	ui_tooltip = "Use less accurate approximations instead of the full transform functions";
	ui_category = "Performance";
> = false;


//2x2 Bayer
static const int bayer[2 * 2] = {
	0, 2,
	3, 1
};

float3 PosterizeDitherPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	static const float PI = 3.1415927;

	static const float INVNORM_FACTOR = min(Oklab::INVNORM_FACTOR, _POSTERIZE_MAX_INVNORM_FACTOR);
	static const float HDR_PAPER_WHITE = Oklab::HDR_PAPER_WHITE;

	static const float3 BaseColor = Oklab::RGB_to_LCh(BaseColor);
	color = (UseApproximateTransforms)
		? Oklab::Fast_DisplayFormat_to_LCh(color)
		: Oklab::DisplayFormat_to_LCh(color);


	//Dithering
	float m;
	if (DitheringFactor != 0.0)
	{
		int2 xy = int2(texcoord * ReShade::ScreenSize) % 2;
		m = (bayer[xy.x + 2 * xy.y] * 0.25 - 0.5) * INVNORM_FACTOR * DitheringFactor;
	}
	else
	{
		m = 0.0;
	}

	float luminance = color.r + m;
	float adapted_luminance = (Oklab::IS_HDR) ? min(2.0 * luminance / HDR_PAPER_WHITE, 1.0) : luminance;
	static const float PW_COMPENSATION = 2.2 - HDR_PAPER_WHITE / INVNORM_FACTOR;
	static const float PALETTE_CONTROL = PW_COMPENSATION * PaletteBalance;
	float hue_range;
	float hue_offset = 0.0;
	
	switch (PaletteType)
	{
		case 0: //Monochrome
		{
			hue_range = 0.0;
		} break;
		case 1: //Analogous
		{
			hue_range = PI/2.0;
		} break;
		case 2: //Complementary
		{
			hue_range = PI/2.0;
			hue_offset = (adapted_luminance > 0.5 * PALETTE_CONTROL)
				? PI*0.75
				: 0.0;
		} break;
		case 3: //Triadic
		{
			hue_range = PI/2.0;
			hue_offset = (adapted_luminance > 0.33 * PALETTE_CONTROL)
				? PI*0.4167 * floor(adapted_luminance * 3.0 / PALETTE_CONTROL)
				: 0.0;
		} break;
		case 4: //All colors
		{
			hue_range = PI*2.0;
		} break;
	}

	color.r = ceil(luminance * NumColors) / NumColors;
	color.g = (DesaturateHighlights)
		? BaseColor.g * (1.0 - (adapted_luminance * adapted_luminance) * DesaturateFactor)
		: BaseColor.g;
	color.b = BaseColor.b + (color.r - rcp(NumColors)) * hue_range + hue_offset;
	
	color = (UseApproximateTransforms)
		? Oklab::Fast_LCh_to_DisplayFormat(color)
		: Oklab::LCh_to_DisplayFormat(color);
	return color.rgb;
}

technique PalettePosterize <ui_tooltip = 
"Posterizes an image to a custom color palette.\n\n"
"(HDR compatible)";>
{
	pass
	{
		VertexShader = PostProcessVS; PixelShader = PosterizeDitherPass;
	}
}
