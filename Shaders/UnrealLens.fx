////////////////////////////////////////////////////////
// Unreal Lens
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

#include "FXShadersCommon.fxh"
#include "FXShadersConvolution.fxh"
#include "FXShadersMath.fxh"
#include "FXShadersTonemap.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#ifndef MAGIC_LENS_BLUR_SAMPLES
#define MAGIC_LENS_BLUR_SAMPLES 9
#endif

#ifndef MAGIC_LENS_DOWNSCALE
#define MAGIC_LENS_DOWNSCALE 4
#endif

namespace FXShaders { namespace UnrealLens
{

static const int BlurSamples = MAGIC_LENS_BLUR_SAMPLES;
static const int Downscale = MAGIC_LENS_DOWNSCALE;
static const float BaseFlareDownscale = 4.0;

FXSHADERS_WIP_WARNING();

uniform float Brightness
<
	ui_category = "Appearance";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.1;

uniform float Saturation
<
	ui_category = "Appearance";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.7;

uniform float Threshold
<
	ui_category = "Appearance";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.7;

uniform float EdgesMasking
<
	ui_category = "Appearance";
	ui_label = "Edges Masking";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.3;

uniform int Tonemapper
<
	ui_category = "Appearance";
	ui_type = "combo";
	ui_items = FXSHADERS_TONEMAPPER_LIST;
> = Tonemap::Type::BakingLabACES;

uniform float BokehAngle
<
	ui_category = "Bokeh Blur";
	ui_label = "Angle";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 15.0 / 60.0;

uniform float BokehSize
<
	ui_category = "Bokeh Blur";
	ui_label = "Size";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 1.0;

uniform float BokehDefinition
<
	ui_category = "Bokeh Blur";
	ui_label = "Definition";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.2;

#define _FLARE_TINT(id, defaultValue) \
uniform float4 Tint##id \
< \
	ui_category = "Flares"; \
	ui_label = "Tint " #id; \
	ui_type = "color"; \
> = defaultValue

_FLARE_TINT(1, float4(1.0, 1.0, 1.0, 1.0));
_FLARE_TINT(2, float4(1.0, 1.0, 1.0, 1.0));
_FLARE_TINT(3, float4(1.0, 1.0, 1.0, 1.0));
_FLARE_TINT(4, float4(1.0, 1.0, 1.0, 1.0));
_FLARE_TINT(5, float4(1.0, 1.0, 1.0, 1.0));
_FLARE_TINT(6, float4(1.0, 1.0, 1.0, 0.0));
_FLARE_TINT(7, float4(1.0, 1.0, 1.0, 0.0));

#undef _FLARE_TINT

#define _FLARE_SCALE(id, defaultValue) \
uniform float Scale##id \
< \
	ui_category = "Flares"; \
	ui_label = "Scale " #id; \
	ui_type = "slider"; \
	ui_min = -1.0; \
	ui_max = 1.0; \
> = defaultValue

_FLARE_SCALE(1, 0.6);
_FLARE_SCALE(2, 0.2);
_FLARE_SCALE(3, 0.1);
_FLARE_SCALE(4, 0.05);
_FLARE_SCALE(5, -1.0);
_FLARE_SCALE(6, -1.0);
_FLARE_SCALE(7, -1.0);

#undef _FLARE_SCALE

uniform bool ShowLens
<
	ui_category = "Debug";
	ui_category_closed = true;
	ui_label = "Show Lens Flare Texture";
> = false;

texture BackBufferTex : COLOR;

sampler BackBuffer
{
	Texture = BackBufferTex;
	SRGBTexture = true;
	AddressU = BORDER;
	AddressV = BORDER;
};

texture LensATex// <pooled = true;>
{
	Width = BUFFER_WIDTH / Downscale;
	Height = BUFFER_HEIGHT / Downscale;
	Format = RGBA16F;
};

sampler LensA
{
	Texture = LensATex;
	AddressU = BORDER;
	AddressV = BORDER;
};

texture LensBTex// <pooled = true;>
{
	Width = BUFFER_WIDTH / Downscale;
	Height = BUFFER_HEIGHT / Downscale;
	Format = RGBA16F;
};

sampler LensB
{
	Texture = LensBTex;
	AddressU = BORDER;
	AddressV = BORDER;
};

float3 MaskEdges(float3 color, float2 uv)
{
	float mask = 1.0 - distance(uv, 0.5);
	mask = saturate(lerp(1.0, mask, EdgesMasking * 3.0));
	color.rgb *= mask;

	return color;
}

float4 PreparePS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	uv = ScaleCoord(1.0 - uv, BaseFlareDownscale);
	float4 color = tex2D(BackBuffer, uv);
	color.rgb = Tonemap::Inverse(Tonemapper, color.rgb);

	color.rgb = MaskEdges(color.rgb, uv);
	color.rgb = ApplySaturation(color.rgb, Saturation);
	color.rgb *= color.rgb >= Tonemap::Inverse(Tonemapper, Threshold).x;
	color.rgb *= Brightness * 0.1;

	return color;
}

#define _HEX_BLUR_SHADER(id, tex, angle) \
float4 HexBlur##id##PS( \
	float4 p : SV_POSITION, \
	float2 uv : TEXCOORD) : SV_TARGET \
{ \
	float2 dir = float2(BokehSize * Downscale, 0); \
	dir = RotatePoint(dir, angle + 30, 0); \
	dir *= GetPixelSize(); \
	\
	return SharpBlur1D(tex, uv, dir, BlurSamples, BokehDefinition); \
}

_HEX_BLUR_SHADER(1, LensB, BokehAngle * 60 + 30)
_HEX_BLUR_SHADER(2, LensA, BokehAngle * 60 - 30)
_HEX_BLUR_SHADER(3, LensB, BokehAngle * 60 - 90)

#undef _HEX_BLUR_SHADER

float4 BlendPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float4 color = tex2D(BackBuffer, uv);
	color.rgb = Tonemap::Inverse(Tonemapper, color.rgb);

	#define _GET_FLARE(id) \
	(tex2D(LensA, ScaleCoord(uv, Scale##id * BaseFlareDownscale)) * \
	float4(Tint##id##.rgb * Tint##id##.a, 1.0))

	float4 lens =
		_GET_FLARE(1) +
		_GET_FLARE(2) +
		_GET_FLARE(3) +
		_GET_FLARE(4) +
		_GET_FLARE(5) +
		_GET_FLARE(6) +
		_GET_FLARE(7);
	lens /= 7;

	#undef _GET_FLARE

	color.rgb = ShowLens
		? lens.rgb
		: color.rgb + lens.rgb; 

	color.rgb = Tonemap::Apply(Tonemapper, color.rgb);

#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
	return color;
#endif
}

technique UnrealLens
{
	pass Prepare
	{
		VertexShader = ScreenVS;
		PixelShader = PreparePS;
		RenderTarget = LensBTex;
	}
	pass HexBlur1
	{
		VertexShader = ScreenVS;
		PixelShader = HexBlur1PS;
		RenderTarget = LensATex;
	}
	pass HexBlur2
	{
		VertexShader = ScreenVS;
		PixelShader = HexBlur2PS;
		RenderTarget = LensBTex;
	}
	pass HexBlur3
	{
		VertexShader = ScreenVS;
		PixelShader = HexBlur3PS;
		RenderTarget = LensATex;
	}
	pass Blend
	{
		VertexShader = ScreenVS;
		PixelShader = BlendPS;
		SRGBWriteEnable = true;
	}
}

}} // Namespace.
