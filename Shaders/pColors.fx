///////////////////////////////////////////////////////////////////////////////////
// pColors.fx by Gimle Larpes
// Shader with tools for color correction and grading.
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

static const float PI = pUtils::PI;

//White balance
uniform float WBTemperature <
	ui_type = "slider";
	ui_min = -0.25; ui_max = 0.25;
	ui_label = "Temperature";
	ui_tooltip = "Color temperature adjustment (Blue <-> Yellow)";
	ui_category = "White balance";
> = 0.0;
uniform float WBTint <
	ui_type = "slider";
	ui_min = -0.25; ui_max = 0.25;
	ui_label = "Tint";
	ui_tooltip = "Color tint adjustment (Magenta <-> Green)";
	ui_category = "White balance";
> = 0.0;
//Global adjustments
uniform float GlobalSaturation <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Saturation";
	ui_tooltip = "Saturation adjustment";
	ui_category = "Global adjustments";
> = 0.0;
uniform float GlobalBrightness <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Brightness";
	ui_tooltip = "Brightness adjustment";
	ui_category = "Global adjustments";
> = 0.0;


//Advanced color correction
#ifndef ENABLE_ADVANCED_COLOR_CORRECTION
	#define ENABLE_ADVANCED_COLOR_CORRECTION 0
#endif
#if ENABLE_ADVANCED_COLOR_CORRECTION == 1
	//Hue 1
	uniform float3 Hue1 <
		ui_type = "color";
		ui_label = "Hue 1";
		ui_tooltip = "Hue to adjust";
		ui_category = "Advanced Color Correction";
	> = float3(1.0, 0.0, 0.0);
	uniform float Hue1Shift <
	ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Hue Shift";
		ui_tooltip = "Hue 1 shift +-180°";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue1Saturation <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Saturation";
		ui_tooltip = "Hue 1 saturation adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue1Brightness <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Brightness";
		ui_tooltip = "Hue 1 brightness adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	//Hue 2
	uniform float3 Hue2 <
		ui_type = "color";
		ui_label = "Hue 2";
		ui_tooltip = "Hue to adjust";
		ui_category = "Advanced Color Correction";
	> = float3(1.0, 1.0, 0.0);
	uniform float Hue2Shift <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Hue Shift";
		ui_tooltip = "Hue 2 shift +-180°";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue2Saturation <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Saturation";
		ui_tooltip = "Hue 2 saturation adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue2Brightness <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Brightness";
		ui_tooltip = "Hue 2 brightness adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	//Hue 3
	uniform float3 Hue3 <
		ui_type = "color";
		ui_label = "Hue 3";
		ui_tooltip = "Hue to adjust";
		ui_category = "Advanced Color Correction";
	> = float3(0.0, 1.0, 0.0);
	uniform float Hue3Shift <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Hue Shift";
		ui_tooltip = "Hue 3 shift +-180°";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue3Saturation <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Saturation";
		ui_tooltip = "Hue 3 saturation adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue3Brightness <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Brightness";
		ui_tooltip = "Hue 3 brightness adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	//Hue 4
	uniform float3 Hue4 <
		ui_type = "color";
		ui_label = "Hue 4";
		ui_tooltip = "Hue to adjust";
		ui_category = "Advanced Color Correction";
	> = float3(0.0, 1.0, 1.0);
	uniform float Hue4Shift <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Hue Shift";
		ui_tooltip = "Hue 4 shift +-180°";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue4Saturation <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Saturation";
		ui_tooltip = "Hue 4 saturation adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue4Brightness <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Brightness";
		ui_tooltip = "Hue 4 brightness adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	//Hue 5
	uniform float3 Hue5 <
		ui_type = "color";
		ui_label = "Hue 5";
		ui_tooltip = "Hue to adjust";
		ui_category = "Advanced Color Correction";
	> = float3(0.0, 0.0, 1.0);
	uniform float Hue5Shift <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Hue Shift";
		ui_tooltip = "Hue 5 shift +-180°";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue5Saturation <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Saturation";
		ui_tooltip = "Hue 5 saturation adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue5Brightness <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Brightness";
		ui_tooltip = "Hue 5 brightness adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	//Hue 6
	uniform float3 Hue6 <
		ui_type = "color";
		ui_label = "Hue 6";
		ui_tooltip = "Hue to adjust";
		ui_category = "Advanced Color Correction";
	> = float3(1.0, 0.0, 1.0);
	uniform float Hue6Shift <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Hue Shift";
		ui_tooltip = "Hue 6 shift +-180°";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue6Saturation <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Saturation";
		ui_tooltip = "Hue 6 saturation adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
	uniform float Hue6Brightness <
		ui_type = "slider";
		ui_min = -1.0; ui_max = 1.0;
		ui_label = "Brightness";
		ui_tooltip = "Hue 6 brightness adjustment";
		ui_category = "Advanced Color Correction";
	> = 0.0;
#endif


//Shadows midtones highlights
//Shadows
uniform float3 ShadowTintColor <
	ui_type = "color";
	ui_label = "Tint";
	ui_tooltip = "Color to which shadows are tinted";
	ui_category = "Shadows";
> = float3(0.69, 0.82, 1.0);
uniform float ShadowSaturation <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Saturation";
	ui_tooltip = "Saturation adjustment for shadows";
	ui_category = "Shadows";
> = 0.0;
uniform float ShadowBrightness <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Brightness";
	ui_tooltip = "Brightness adjustment for shadows";
	ui_category = "Shadows";
> = 0.0;
uniform float ShadowThreshold <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Threshold";
	ui_tooltip = "Threshold for what is considered shadows";
	ui_category = "Shadows";
> = 0.25;
uniform float ShadowCurveSlope <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 5.0;
	ui_label = "Curve Slope";
	ui_tooltip = "How steep the transition to shadows is";
	ui_category = "Shadows";
> = 2.5;
//Midtones
uniform float3 MidtoneTintColor <
	ui_type = "color";
	ui_label = "Tint";
	ui_tooltip = "Color to which midtones are tinted";
	ui_category = "Midtones";
> = float3(1.0, 1.0, 1.0);
uniform float MidtoneSaturation <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Saturation";
	ui_tooltip = "Saturation adjustment for midtones";
	ui_category = "Midtones";
> = 0.0;
uniform float MidtoneBrightness <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Brightness";
	ui_tooltip = "Brightness adjustment for midtones";
	ui_category = "Midtones";
> = 0.0;
//Highlights
uniform float3 HighlightTintColor <
	ui_type = "color";
	ui_label = "Tint";
	ui_tooltip = "Color to which highlights are tinted";
	ui_category = "Highlights";
> = float3(1.0, 0.98, 0.90);
uniform float HighlightSaturation <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Saturation";
	ui_tooltip = "Saturation adjustment for highlights";
	ui_category = "Highlights";
> = 0.0;
uniform float HighlightBrightness <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_label = "Brightness";
	ui_tooltip = "Brightness adjustment for highlights";
	ui_category = "Highlights";
> = 0.0;
uniform float HighlightThreshold <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Threshold";
	ui_tooltip = "Threshold for what is considered highlights";
	ui_category = "Highlights";
> = 0.75;
uniform float HighlightCurveSlope <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 5.0;
	ui_label = "Curve Slope";
	ui_tooltip = "How steep the transition to highlights is";
	ui_category = "Highlights";
> = 2.5;


//LUT
uniform bool EnableLUT <
	ui_type = "bool";
	ui_label = "Enable LUT";
	ui_tooltip = "Apply a LUT as a final processing step\n\nIncrease HDR_PEAK_LUMINANCE_NITS if enabling this causes clipping";
	ui_category = "LUT";
> = false;

#if BUFFER_COLOR_SPACE > 1	//Show LUT whitepoint setting if in HDR
	uniform float LUT_WhitePoint <
	ui_type = "slider";
		ui_min = 0.0; ui_max = 1.0;
		ui_label = "LUT White point";
		ui_tooltip = "Adjusts what range of brightness LUT affects, useful when applying SDR LUTs to HDR\n\n(0= apply LUT to nothing, 1= apply LUT to entire image)";
		ui_category = "LUT";
	> = 1.0;
#else
	static const float LUT_WhitePoint = 1.0;
#endif

#ifndef fLUT_TextureName //Use same name as LUT.fx and MultiLUT.fx for compatability
	#define fLUT_TextureName "lut.png"
#endif
#ifndef fLUT_Resolution
	#define fLUT_Resolution 32
#endif
#ifndef fLUT_Format
	#define fLUT_Format RGBA8
#endif
texture LUT < source = fLUT_TextureName; > { Height = fLUT_Resolution; Width = fLUT_Resolution * fLUT_Resolution; Format = fLUT_Format; };
sampler sLUT { Texture = LUT; };


//Performance
uniform bool UseApproximateTransforms <
	ui_type = "bool";
	ui_label = "Fast colorspace transform";
	ui_tooltip = "Use less accurate approximations instead of the full transform functions";
	ui_category = "Performance";
> = false;



float get_Weight(float v, float t, float s) //value, threshold, curve slope
{
	v = (v - t) * s;
	return (v > 1.0)
		? 1.0
		: (v < 0.0)
			? 0.0
			: v * v * (3.0 - 2.0 * v);
}

float3 Apply_LUT(float3 c) //Adapted from LUT.fx by Marty McFly
{
	static const float EXPANSION_FACTOR = Oklab::INVNORM_FACTOR;
	float3 LUT_coord = c / EXPANSION_FACTOR / LUT_WhitePoint;

	float bounds = max(LUT_coord.x, max(LUT_coord.y, LUT_coord.z));
	
	if (bounds <= 1.0) //Only apply LUT if value is in LUT range
	{
		float2 texel_size = rcp(fLUT_Resolution);
		texel_size.x /= fLUT_Resolution;

		const float3 oc = LUT_coord;
		LUT_coord.xy = (LUT_coord.xy * fLUT_Resolution - LUT_coord.xy + 0.5) * texel_size;
		LUT_coord.z *= (fLUT_Resolution - 1.0);
	
		float lerp_factor = frac(LUT_coord.z);
		LUT_coord.x += floor(LUT_coord.z) * texel_size.y;
		c = lerp(tex2D(sLUT, LUT_coord.xy).rgb, tex2D(sLUT, float2(LUT_coord.x + texel_size.y, LUT_coord.y)).rgb, lerp_factor);

		if (bounds > 0.9 && LUT_WhitePoint != 1.0) //Fade out LUT to avoid banding
		{
			c = lerp(c, oc, 10.0 * (bounds - 0.9));
		}

		return c * LUT_WhitePoint * EXPANSION_FACTOR;
	}

	return c;
}

float3 Manipulate_By_Hue(float3 color, float3 hue, float hue_shift, float hue_saturation, float hue_brightness)
{
	float weight = max(1.0 - pUtils::cdistance(color.z, hue.z), 0.0); //Linear with coverage of ~60deg

	if (weight != 0.0)
	{
		color.z += hue_shift * weight;
		color.xy *= 1.0 + float2(hue_brightness, hue_saturation) * weight; 
		color = Oklab::Saturate_LCh(color);
	}

	return color;
}



float3 ColorsPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	color = (UseApproximateTransforms)
		? Oklab::Fast_DisplayFormat_to_Linear(color)
		: Oklab::DisplayFormat_to_Linear(color);
	float adapted_luminance = Oklab::get_Adapted_Luminance_RGB(color, 1.0);
	color = Oklab::RGB_to_Oklab(color);

	
	////Processing
	//White balance
	if (WBTemperature != 0.0 || WBTint != 0.0)
	{
		color.g = color.g - WBTint;
		color.b = (WBTint < 0.0)
			? color.b + WBTemperature + WBTint
			: color.b + WBTemperature;
	}


	//Global adjustments
	color.r *= (1.0 + GlobalBrightness);
	color.gb *= (1.0 + GlobalSaturation);


	////Advanced color correction - Adjustments by hue
	#if ENABLE_ADVANCED_COLOR_CORRECTION == 1
		color = Oklab::Oklab_to_LCh(color);

		if (Hue1Shift != 0.0 || Hue1Saturation != 0.0 || Hue1Brightness != 0.0)
		{
			color = Manipulate_By_Hue(color, Oklab::RGB_to_LCh(Hue1), Hue1Shift * PI, Hue1Saturation, Hue1Brightness);
		}
		if (Hue2Shift != 0.0 || Hue2Saturation != 0.0 || Hue2Brightness != 0.0)
		{
			color = Manipulate_By_Hue(color, Oklab::RGB_to_LCh(Hue2), Hue2Shift * PI, Hue2Saturation, Hue2Brightness);
		}
		if (Hue3Shift != 0.0 || Hue3Saturation != 0.0 || Hue3Brightness != 0.0)
		{
			color = Manipulate_By_Hue(color, Oklab::RGB_to_LCh(Hue3), Hue3Shift * PI, Hue3Saturation, Hue3Brightness);
		}
		if (Hue4Shift != 0.0 || Hue4Saturation != 0.0 || Hue3Brightness != 0.0)
		{
			color = Manipulate_By_Hue(color, Oklab::RGB_to_LCh(Hue4), Hue4Shift * PI, Hue4Saturation, Hue4Brightness);
		}
		if (Hue5Shift != 0.0 || Hue5Saturation != 0.0 || Hue5Brightness != 0.0)
		{
			color = Manipulate_By_Hue(color, Oklab::RGB_to_LCh(Hue5), Hue5Shift * PI, Hue5Saturation, Hue5Brightness);
		}
		if (Hue6Shift != 0.0 || Hue6Saturation != 0.0 || Hue6Brightness != 0.0)
		{
			color = Manipulate_By_Hue(color, Oklab::RGB_to_LCh(Hue6), Hue6Shift * PI, Hue6Saturation, Hue6Brightness);
		}
	
		color = Oklab::LCh_to_Oklab(color);
	#endif


	//Shadows-midtones-highlights colors
	static const float3 ShadowTintColor = Oklab::RGB_to_Oklab(ShadowTintColor) * (1 + GlobalSaturation);
	static const float ShadowTintColorC = Oklab::get_Oklab_Chromacity(ShadowTintColor);
	static const float3 MidtoneTintColor = Oklab::RGB_to_Oklab(MidtoneTintColor) * (1 + GlobalSaturation);
	static const float MidtoneTintColorC = Oklab::get_Oklab_Chromacity(MidtoneTintColor);
	static const float3 HighlightTintColor = Oklab::RGB_to_Oklab(HighlightTintColor) * (1 + GlobalSaturation);
	static const float HighlightTintColorC = Oklab::get_Oklab_Chromacity(HighlightTintColor);

	////Shadows-midtones-highlights
	//Shadows
	float shadow_weight = get_Weight(adapted_luminance, ShadowThreshold, -ShadowCurveSlope);
	if (shadow_weight != 0.0)
	{
		color.r *= (1.0 + ShadowBrightness * shadow_weight);
		color.g = lerp(color.g, ShadowTintColor.g + (1.0 - ShadowTintColorC) * color.g, shadow_weight) * (1.0 + ShadowSaturation * shadow_weight);
		color.b = lerp(color.b, ShadowTintColor.b + (1.0 - ShadowTintColorC) * color.b, shadow_weight) * (1.0 + ShadowSaturation * shadow_weight);
	}
	//Highlights
	float highlight_weight = get_Weight(adapted_luminance, HighlightThreshold, HighlightCurveSlope);
	if (highlight_weight != 0.0)
	{
		color.r *= (1.0 + HighlightBrightness * highlight_weight);
		color.g = lerp(color.g, HighlightTintColor.g + (1.0 - HighlightTintColorC) * color.g, highlight_weight) * (1.0 + HighlightSaturation * highlight_weight);
		color.b = lerp(color.b, HighlightTintColor.b + (1.0 - HighlightTintColorC) * color.b, highlight_weight) * (1.0 + HighlightSaturation * highlight_weight);
	}
	//Midtones
	float midtone_weight = max(1.0 - (shadow_weight + highlight_weight), 0.0);
	if (midtone_weight != 0.0)
	{
		color.r *= (1.0 + MidtoneBrightness * midtone_weight);
		color.g = lerp(color.g, MidtoneTintColor.g + (1.0 - MidtoneTintColorC) * color.g, midtone_weight) * (1.0 + MidtoneSaturation * midtone_weight);
		color.b = lerp(color.b, MidtoneTintColor.b + (1.0 - MidtoneTintColorC) * color.b, midtone_weight) * (1.0 + MidtoneSaturation * midtone_weight);
	}
	color = Oklab::Oklab_to_RGB(color);


	////LUT
	if (EnableLUT)
	{
		color = Apply_LUT(Oklab::Saturate_RGB(color));
	}
	
	if (!Oklab::IS_HDR) { color = Oklab::Saturate_RGB(color); }
	color = (UseApproximateTransforms)
		? Oklab::Fast_Linear_to_DisplayFormat(color)
		: Oklab::Linear_to_DisplayFormat(color);
	return color.rgb;
}



technique Colors <ui_tooltip = 
"Shader with tools for advanced color correction and grading.\n\n"
"(HDR compatible)";>
{
	pass
	{
		VertexShader = PostProcessVS; PixelShader = ColorsPass;
	}
}