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

uniform int BlendMode
<
	ui_type = "combo";
	ui_label = "Blending Mode";
	ui_tooltip =
		"Determines the way the vignette is blended with the image.\n"
		"\nDefault: Mix";
	ui_category = "Appearance";
	ui_items = "Mix\0"
               "Darken\0"
               "Multiply\0"
               "Color Burn\0"
               "Linear Burn\0"
               "Lighten\0"
               "Screen\0"
               "Color Dodge\0"
               "Linear Dodge\0"
               "Addition\0"
               "Glow\0"
               "Overlay\0"
               "Soft Light\0"
               "Hard Light\0"
               "Vivid Light\0"
               "Linear Light\0"
               "Pin Light\0"
               "Hard Mix\0"
               "Difference\0"
               "Exclusion\0"
               "Subtract\0"
               "Divide\0"
               "Reflect\0"
               "Grain Merge\0"
               "Grain Extract\0"
               "Hue\0"
               "Saturation\0"
               "Color\0"
               "Luminosity\0";
> = 0;

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

		float3 vig_color;

		switch (BlendMode)
		{
			// Mix
			default:
				vig_color = VignetteColor.rgb;
				break;
			// Darken
			case 1:
				vig_color = Darken(color.rgb, VignetteColor.rgb);
				break;
			// Multiply
			case 2:
				vig_color = Multiply(color.rgb, VignetteColor.rgb);
				break;
			// Color Burn
			case 3:
				vig_color = ColorBurn(color.rgb, VignetteColor.rgb);
				break;
			// Linear Burn
			case 4:
				vig_color = LinearBurn(color.rgb, VignetteColor.rgb);
				break;
			// Lighten
			case 5:
				vig_color = Lighten(color.rgb, VignetteColor.rgb);
				break;
			// Screen
			case 6:
				vig_color = Screen(color.rgb, VignetteColor.rgb);
				break;
			// Color Dodge
			case 7:
				vig_color = ColorDodge(color.rgb, VignetteColor.rgb);
				break;
			// Linear Dodge
			case 8:
				vig_color = LinearDodge(color.rgb, VignetteColor.rgb);
				break;
			// Addition
			case 9:
				vig_color = Addition(color.rgb, VignetteColor.rgb);
				break;
			// Glow
			   case 10:
				vig_color = Glow(color.rgb, VignetteColor.rgb);
				break;
			// Overlay
			case 11:
				vig_color = Overlay(color.rgb, VignetteColor.rgb);
				break;
			// Soft Light
			case 12:
				vig_color = SoftLight(color.rgb, VignetteColor.rgb);
				break;
			// Hard Light
			case 13:
				vig_color = HardLight(color.rgb, VignetteColor.rgb);
				break;
			// Vivid Light
			case 14:
				vig_color = VividLight(color.rgb, VignetteColor.rgb);
				break;
			// Linear Light
			case 15:
				vig_color = LinearLight(color.rgb, VignetteColor.rgb);
				break;
			// Pin Light
			case 16:
				vig_color = PinLight(color.rgb, VignetteColor.rgb);
				break;
			// Hard Mix
			case 17:
				vig_color = HardMix(color.rgb, VignetteColor.rgb);
				break;
			// Difference
			case 18:
				vig_color = Difference(color.rgb, VignetteColor.rgb);
				break;
			// Exclusion
			case 19:
				vig_color = Exclusion(color.rgb, VignetteColor.rgb);
				break;
			// Subtract
			case 20:
				vig_color = Subtract(color.rgb, VignetteColor.rgb);
				break;
			// Divide
			case 21:
				vig_color = Divide(color.rgb, VignetteColor.rgb);
				break;
			// Reflect
			case 22:
				vig_color = Reflect(color.rgb, VignetteColor.rgb);
				break;
			// Grain Merge
			case 23:
				vig_color = GrainMerge(color.rgb, VignetteColor.rgb);
				break;
			// Grain Extract
			case 24:
				vig_color = GrainExtract(color.rgb, VignetteColor.rgb);
				break;
			// Hue
			case 25:
				vig_color = Hue(color.rgb, VignetteColor.rgb);
				break;
			// Saturation
			case 26:
				vig_color = Saturation(color.rgb, VignetteColor.rgb);
				break;
			// Color
			case 27:
				vig_color = ColorB(color.rgb, VignetteColor.rgb);
				break;
			// Luminosity
			case 28:
				vig_color = Luminosity(color.rgb, VignetteColor.rgb);
				break;
		}

#if GSHADE_DITHER
		const float3 outcolor = lerp(color.rgb, vig_color, vignette * VignetteColor.a);
		return float4(outcolor + TriDither(outcolor, uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
		return float4(lerp(color.rgb, vig_color, vignette * VignetteColor.a), color.a);
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