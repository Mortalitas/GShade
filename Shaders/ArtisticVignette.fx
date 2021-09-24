//#region Includes

#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//#endregion

//#region Constants

static const float Pi = 3.14159;
static const float HalfPi = Pi * 0.5;

static const int BlendMode_Mix = 0;
static const int BlendMode_Multiply = 1;
static const int BlendMode_DarkenOnly = 2;
static const int BlendMode_LightenOnly = 3;
static const int BlendMode_Overlay = 4;
static const int BlendMode_Screen = 5;
static const int BlendMode_HardLight = 6;
static const int BlendMode_SoftLight = 7;

static const int VignetteShape_None = 0;
static const int VignetteShape_Radial = 1;
static const int VignetteShape_TopBottom = 2;
static const int VignetteShape_LeftRight = 3;
static const int VignetteShape_Box = 4;
static const int VignetteShape_Sky = 5;
static const int VignetteShape_Ground = 6;

//#endregion

//#region Uniforms

uniform int _Help
<
	ui_text =
		"This effect provides a flexible way to create a vignatte overlay.\n"
		"\n"
		"Specific help for each option can be found by moving the mouse over "
		"the option's name.\n"
		"\n"
		"The appearance can be controlled using a color, with opacity support "
		"through the alpha channel, and a blending mode, like Photoshop/GIMP.\n"
		"\n"
		"Various shapes can be used, with adjustable aspect ratio and gradient "
		"points.\n"
		;
	ui_category = "Help";
	ui_category_closed = true;
	ui_label = " ";
	ui_type = "radio";
>;

uniform float4 VignetteColor
<
	ui_type = "color";
	ui_label = "Color";
	ui_tooltip =
		"Color of the vignette.\n"
		"Supports opacity control through the alpha channel.\n"
		"\nDefault: 0 0 0 255";
	ui_category = "Appearance";
> = float4(0.0, 0.0, 0.0, 1.0);

BLENDING_COMBO(BlendMode, "Blending Mode", "Determines the way the vignette is blended with the image.\n\nDefault: Mix", "Appearance", false, 0, 0)

uniform float2 VignetteStartEnd
<
	ui_type = "slider";
	ui_label = "Start/End";
	ui_tooltip =
		"The start and end points of the vignette gradient.\n"
		"The longer the distance, the smoother the vignette effect is.\n"
		"\nDefault: 0.0 1.0";
	ui_category = "Shape";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_step = 0.01;
> = float2(0.0, 1.0);

uniform float VignetteDepth
<
	ui_type = "slider";
	ui_label = "Depth";
	ui_tooltip =
		"The distance from the camera at which the effect is applied.\n"
		"The lower the value, the further away the vignette effect is.\n"
		"\nDefault: 1.0";
	ui_category = "Depth";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.0001;
> = 1.0;

uniform float VignetteRatio
<
	ui_type = "slider";
	ui_label = "Ratio";
	ui_tooltip =
		"The aspect ratio of the vignette.\n"
		"0.0: Anamorphic.\n"
		"1.0: Corrected.\n"
		"\n"
		"For example, with 1.0 the radial shape produces a perfect circle.\n"
		"\nDefault: 0.0";
	ui_category = "Shape";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.0;

uniform int VignetteShape
<
	ui_type = "combo";
	ui_label = "Shape";
	ui_tooltip =
		"The shape of the vignette.\n"
		"\nDefault: Radial";
	ui_category = "Shape";
	ui_items = "None\0Radial\0Top/Bottom\0Left/Right\0Box\0Sky\0Ground\0";
> = 1;

//#endregion

//#region Shaders

float4 MainPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	const float4 color = tex2D(ReShade::BackBuffer, uv);
	const float depth = 1 - ReShade::GetLinearizedDepth(uv).r;
	if (depth < VignetteDepth)
	{
		if (ReShade::AspectRatio > 1.0)
			const float2 ratio = float2(BUFFER_WIDTH * BUFFER_RCP_HEIGHT, 1.0);
		else
			const float2 ratio = float2(1.0, BUFFER_HEIGHT * BUFFER_RCP_WIDTH);

		uv = lerp(uv, (uv - 0.5) * ratio + 0.5, VignetteRatio);

		float vignette = 1.0;

		switch (VignetteShape)
		{
			case VignetteShape_Radial:
				vignette = distance(0.5, uv) * HalfPi;
				break;
			case VignetteShape_TopBottom:
				vignette = abs(uv.y - 0.5) * 2.0;
				break;
			case VignetteShape_LeftRight:
				vignette = abs(uv.x - 0.5) * 2.0;
				break;
			case VignetteShape_Box:
				float2 vig = abs(uv - 0.5) * 2.0;
				vignette = max(vig.x, vig.y);
				break;
			case VignetteShape_Sky:
				vignette = distance(float2(0.5, 1.0), uv);
				break;
			case VignetteShape_Ground:
				vignette = distance(float2(0.5, 0.0), uv);
				break;
		}

		vignette = smoothstep(VignetteStartEnd.x, VignetteStartEnd.y, vignette);

#if GSHADE_DITHER
		const float3 vig_color = ComHeaders::Blending::Blend(BlendMode, color.rgb, VignetteColor.rgb, vignette * VignetteColor.a);

		return float4(vig_color + TriDither(vig_color, uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
		return float4(ComHeaders::Blending::Blend(BlendMode, color.rgb, VignetteColor.rgb, vignette * VignetteColor.a), color.a);
#endif
	}
	else
	{
#if GSHADE_DITHER
		return float4(color.rgb + TriDither(color.rgb, uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
		return color;
#endif
	}
}

//#endregion

//#region Technique

technique ArtisticVignette
<
	ui_tooltip =
		"Flexible vignette overlay effect with multiple shapes and blend modes."
		;
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MainPS;
	}
}

//#endregion