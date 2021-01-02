#include "FXShadersAspectRatio.fxh"
#include "FXShadersCommon.fxh"
#include "FXShadersConvolution.fxh"
#include "FXShadersMath.fxh"
#include "FXShadersTonemap.fxh"

#ifndef MAGIC_LENS_BLUR_SAMPLES
#define MAGIC_LENS_BLUR_SAMPLES 9
#endif

#ifndef MAGIC_LENS_DOWNSCALE
#define MAGIC_LENS_DOWNSCALE 4
#endif

namespace FXShaders
{

static const int BlurSamples = MAGIC_LENS_BLUR_SAMPLES;
static const int Downscale = MAGIC_LENS_DOWNSCALE;

FXSHADERS_WIP_WARNING();

uniform float Intensity
<
	ui_category = "Appearance";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 3.0;
> = 0.1;

uniform int Tonemapper
<
	ui_category = "Appearance";
	ui_type = "combo";
	ui_items = FXSHADERS_TONEMAPPER_LIST;
> = 0;

uniform float FisheyeAmount
<
	ui_category = "Fisheye Lens";
	ui_label = "Amount";
	ui_type = "slider";
	ui_min = -1.0;
	ui_max = 1.0;
> = 1.0;

uniform int FisheyeScaleType
<
	ui_category = "Fisheye Lens";
	ui_label = " ";
	ui_text = "Scale Type";
	ui_type = "radio";
	ui_items = FXSHADERS_ASPECT_RATIO_SCALE_TYPE_LIST;
> = AspectRatio::ScaleType::Cover;

uniform float BokehAngle
<
	ui_category = "Bokeh Blur";
	ui_label = "Angle";
	ui_type = "slider";
	ui_min = 0;
	ui_max = 359;
	ui_step = 1;
> = 15;

uniform float BokehSize
<
	ui_category = "Bokeh Blur";
	ui_label = "Size";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 10.0;
> = 3.0;

uniform float4 Tint1
<
	ui_category = "Flares";
	ui_category_closed = true;
	ui_label = "Flare 1 Tint";
	ui_type = "color";
> = float4(1.0, 0.0, 0.0, 1.0);

uniform float4 Tint2
<
	ui_category = "Flares";
	ui_label = "Flare 2 Tint";
	ui_type = "color";
> = float4(1.0, 0.0, 1.0, 1.0);

uniform float4 Tint3
<
	ui_category = "Flares";
	ui_label = "Flare 3 Tint";
	ui_type = "color";
> = float4(1.0, 1.0, 0.0, 1.0);

uniform float4 Tint4
<
	ui_category = "Flares";
	ui_label = "Flare 4 Tint";
	ui_type = "color";
> = float4(0.0, 1.0, 1.0, 1.0);

uniform float Scale1
<
	ui_category = "Flares";
	ui_label = "Flare 1 Scale";
	ui_type = "slider";
	ui_min = -3.0;
	ui_max = 3.0;
> = -3.0;

uniform float Scale2
<
	ui_category = "Flares";
	ui_label = "Flare 2 Scale";
	ui_type = "slider";
	ui_min = -3.0;
	ui_max = 3.0;
> = -1.5;

uniform float Scale3
<
	ui_category = "Flares";
	ui_label = "Flare 3 Scale";
	ui_type = "slider";
	ui_min = -3.0;
	ui_max = 3.0;
> = -1.0;

uniform float Scale4
<
	ui_category = "Flares";
	ui_label = "Flare 4 Scale";
	ui_type = "slider";
	ui_min = -3.0;
	ui_max = 3.0;
> = 2.0;

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
};

float2 ApplyFisheye(float2 uv, float amount, float zoom)
{
	uv = uv * 2.0 - 1.0;

	float2 fishUv = uv * AspectRatio::ApplyScale(FisheyeScaleType, uv);
	float distort = sqrt(1.0 - fishUv.x * fishUv.x - fishUv.y * fishUv.y);

	uv *= lerp(1.0, distort * zoom, amount);

	uv = (uv + 1.0) * 0.5;

	return uv;
}

float4 PreparePS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float4 color = tex2D(BackBuffer, uv);
	color.rgb = Tonemap::Inverse(Tonemapper, color.rgb);

	return color;
}

float4 FishLensPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	#define _GET_FLARE(id) \
	(tex2D(LensA, ApplyFisheye(uv, FisheyeAmount, Scale##id)) * \
	float4(Tint##id##.rgb * Tint##id##.a, 1.0))

	float4 color = _GET_FLARE(1);
	color += _GET_FLARE(2);
	color += _GET_FLARE(3);
	color += _GET_FLARE(4);

	#undef _GET_FLARE

	color /= 4;

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
	return LinearBlur1D(tex, uv, dir, BlurSamples); \
}

_HEX_BLUR_SHADER(1, LensB, BokehAngle + 30)
_HEX_BLUR_SHADER(2, LensA, BokehAngle - 30)
_HEX_BLUR_SHADER(3, LensB, BokehAngle - 90)

#undef _HEX_BLUR_SHADER

float4 BlendPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float4 color = tex2D(BackBuffer, uv);
	color.rgb = Tonemap::Inverse(Tonemapper, color.rgb);

	float4 lens = tex2D(LensA, uv);

	color.rgb = ShowLens
		? lens.rgb
		: color.rgb + lens.rgb * log(1.0 + Intensity) / log(10); 

	color.rgb = Tonemap::Apply(Tonemapper, color.rgb);

	return color;
}

technique MagicLens
{
	pass Prepare
	{
		VertexShader = ScreenVS;
		PixelShader = PreparePS;
		RenderTarget = LensATex;
	}
	pass FishLens
	{
		VertexShader = ScreenVS;
		PixelShader = FishLensPS;
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

} // Namespace.
