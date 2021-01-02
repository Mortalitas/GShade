#include "FXShaders/Common.fxh"
#include "FXShaders/Convolution.fxh"
#include "FXShaders/Math.fxh"
#include "FXShaders/Tonemap.fxh"

namespace FXShaders
{

static const int BlurSamples = 9;
static const int Downsample = 2;

static const int ScaleType_VertMinus = 0;
static const int ScaleType_HorPlus = 1;
static const int ScaleType_Stretch = 2;

static const int Tonemapper_Reinhard = 0;
static const int Tonemapper_Uncharted2Filmic = 1;
static const int Tonemapper_BakingLabACES = 2;
static const int Tonemapper_NarkowiczACES = 3;
static const int Tonemapper_Unreal3 = 4;
static const int Tonemapper_Lottes = 5;

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
	ui_items =
		"Reinhard\0"
		"Uncharted 2 Filmic\0"
		"BakingLab ACES\0"
		"Narkowicz ACES\0"
		"Unreal3\0"
		"Lottes\0";	
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
	ui_items = "Vert-\0Hor+\0Stretch\0";
> = ScaleType_VertMinus;

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
	Width = BUFFER_WIDTH / Downsample;
	Height = BUFFER_HEIGHT / Downsample;
	Format = RGBA16F;
};

sampler LensA
{
	Texture = LensATex;
};

texture LensBTex// <pooled = true;>
{
	Width = BUFFER_WIDTH / Downsample;
	Height = BUFFER_HEIGHT / Downsample;
	Format = RGBA16F;
};

sampler LensB
{
	Texture = LensBTex;
};

float2 AspectRatioScaleByLesserAxis()
{
	return BUFFER_WIDTH > BUFFER_HEIGHT
		? float2(1.0, BUFFER_HEIGHT * BUFFER_RCP_WIDTH)
		: float2(BUFFER_WIDTH * BUFFER_RCP_HEIGHT, 1.0);
}

float2 AspectRatioScaleByGreaterAxis()
{
	return BUFFER_WIDTH > BUFFER_HEIGHT
		? float2(BUFFER_WIDTH * BUFFER_RCP_HEIGHT, 1.0)
		: float2(1.0, BUFFER_HEIGHT * BUFFER_RCP_WIDTH);
}

float2 GetAspectRatioScale()
{
	switch (FisheyeScaleType)
	{
		case ScaleType_VertMinus:
			return AspectRatioScaleByLesserAxis();
		case ScaleType_HorPlus:
			return AspectRatioScaleByGreaterAxis();
		case ScaleType_Stretch:
		default:
			return 1.0;
	}
}

float2 ApplyFisheye(float2 uv, float amount, float zoom)
{
	uv = uv * 2.0 - 1.0;
	//uv /= zoom;

	float2 fishUv = uv * GetAspectRatioScale();
	float distort = sqrt(1.0 - fishUv.x * fishUv.x - fishUv.y * fishUv.y);

	uv *= lerp(1.0, distort * zoom, amount);

	uv = (uv + 1.0) * 0.5;

	return uv;
}

float3 InverseTonemap(float3 color)
{
	switch (Tonemapper)
	{
		case Tonemapper_Reinhard:
			return Tonemap::Reinhard::Inverse(color);
		case Tonemapper_Uncharted2Filmic:
			return Tonemap::Uncharted2Filmic::Inverse(color);
		case Tonemapper_BakingLabACES:
			return Tonemap::BakingLabACES::Inverse(color);
		case Tonemapper_NarkowiczACES:
			return Tonemap::NarkowiczACES::Inverse(color);
		case Tonemapper_Unreal3:
			return Tonemap::Unreal3::Inverse(color);
		case Tonemapper_Lottes:
			return Tonemap::Lottes::Inverse(color);
	}

	return color;
}

float3 Tonemap(float3 color)
{
	switch (Tonemapper)
	{
		case Tonemapper_Reinhard:
			return Tonemap::Reinhard::Apply(color);
		case Tonemapper_Uncharted2Filmic:
			return Tonemap::Uncharted2Filmic::Apply(color);
		case Tonemapper_BakingLabACES:
			return Tonemap::BakingLabACES::Apply(color);
		case Tonemapper_NarkowiczACES:
			return Tonemap::NarkowiczACES::Apply(color);
		case Tonemapper_Unreal3:
			return Tonemap::Unreal3::Apply(color);
		case Tonemapper_Lottes:
			return Tonemap::Lottes::Apply(color);
	}

	return color;
}

float4 PreparePS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float4 color = tex2D(BackBuffer, uv);
	color.rgb = InverseTonemap(color.rgb);

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
	float2 dir = float2(BokehSize * Downsample, 0); \
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
	color.rgb = InverseTonemap(color.rgb);

	float4 lens = tex2D(LensA, uv);

	color.rgb = ShowLens
		? lens.rgb
		: color.rgb + lens.rgb * log(1.0 + Intensity) / log(10); 

	color.rgb = Tonemap(color.rgb);

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
