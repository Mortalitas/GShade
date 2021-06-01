//#region Preprocessor

#include "ReShade.fxh"
#include "FXShadersCommon.fxh"
#include "FXShadersMath.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

/*
	0: Manual
	1: Colorpicker
	2: Automatic
*/
#ifndef WHITEPOINT_FIXER_MODE
#define WHITEPOINT_FIXER_MODE 0
#endif

#ifndef WHITEPOINT_FIXER_DOWNSAMPLE_SIZE
#define WHITEPOINT_FIXER_DOWNSAMPLE_SIZE 16
#endif

#define WHITEPOINT_FIXER_MODE_1_OR_2 \
(WHITEPOINT_FIXER_MODE == 1 || WHITEPOINT_FIXER_MODE == 2)

//#endregion

namespace FXShaders
{

//#region Constants

static const float2 ShowWhitepointSize = 300.0;

#if WHITEPOINT_FIXER_MODE == 1

static const float2 ColorPickerTooltipOffset = float2(0.0, -100.0);
static const float ColorPickerTooltipRadius = 50.0;

static const float ColorPickerCrosshairThickness = 5.0;

#endif

#if WHITEPOINT_FIXER_MODE == 2

static const int DownsampleSize = WHITEPOINT_FIXER_DOWNSAMPLE_SIZE;
static const int DownsampleMaxMip =
	FXSHADERS_LOG2(WHITEPOINT_FIXER_DOWNSAMPLE_SIZE) + 1;

#endif

#if WHITEPOINT_FIXER_MODE_1_OR_2

static const int GrayscaleFormula_Average = 0;
static const int GrayscaleFormula_Max = 1;
static const int GrayscaleFormula_Luma = 2;

#endif

//#endregion

//#region Uniforms

FXSHADERS_HELP(
	"The different modes can be used by setting WHITEPOINT_FIXER_MODE to:\n"
	"  0: Manual color selection, using a parameter.\n"
	"  1: Use a color picker on the image to select the whitepoint color.\n"
	"  2: Automatically try to guess the whitepoint by finding the brightest "
	"color in the image.\n"
);

uniform int WhitepointFixerMode
<
	ui_type = "combo";
	ui_label = "Whitepoint Fixer Mode";
	ui_items = 	"Manual\0Color Select\0Automatic\0";
	ui_bind = "WHITEPOINT_FIXER_MODE";
> = 0;

#if WHITEPOINT_FIXER_MODE == 0

uniform float Whitepoint
<
	ui_type = "slider";
	ui_tooltip =
		"Manual whitepoint value.\n"
		"\nDefault: 1.0";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.00392156; //1.0 / 255.0;
> = 1.0;

#elif WHITEPOINT_FIXER_MODE == 1

uniform bool RunColorPicker
<
	ui_label = "Run Color Picker";
	ui_tooltip =
		"While this option is enabled, pressing right mouse click will use the "
		"color of the pixel under the cursor for the whitepoint.\n"
		"\nDefault: Off";
> = false;

uniform float2 MousePoint <source = "mousepoint";>;

uniform bool MouseRightDown <source = "mousebutton"; keycode = 1;>;

#endif

#if WHITEPOINT_FIXER_MODE == 2

uniform float TransitionSpeed
<
	ui_type = "slider";
	ui_label = "Transition Speed";
	ui_tooltip =
		"The time in seconds that it takes to transition from the last picked "
		"whitepoint to the next.\n"
		"Set to 0.0 to make transitions instantaneous.\n"
		"\nDefault: 1.0";
	ui_min = 0.0;
	ui_max = 5.0;
	ui_step = 1.0 / 100.0;
> = 1.0;

uniform float FrameTime <source = "frametime";>;

#endif

#if WHITEPOINT_FIXER_MODE_1_OR_2

uniform int GrayscaleFormula
<
	ui_type = "combo";
	ui_label = "Grayscale Formula";
	ui_tooltip =
		"The formula used for getting a grayscale color for the whitepoint "
		"value.\n"
		"\nDefault: Average";
	ui_items = "Average\0Max\0Luma\0";
> = 0;

uniform float MinimumWhitepoint
<
	ui_type = "slider";
	ui_label = "Minimum Whitepoint";
	ui_tooltip =
		"The minimum whitepoint that can be used.\n"
		"Any whitepoint that goes below this will be remapped to the value of "
		"Remapped Whitepoint.\n"
		"\nDefault: 0.8";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 1.0 / 255.0;
> = 0.8;

uniform float RemappedWhitepoint
<
	ui_type = "slider";
	ui_label = "Remapped Whitepoint";
	ui_tooltip =
		"The whitepoint value that should be used when the whitepoint falls "
		"falls below the value of Minimum Whitepoint.\n"
		"\nDefault: 1.0";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 1.0 / 255.0;
> = 1.0;

uniform bool ShowWhitepoint
<
	ui_label = "Show Whitepoint";
	ui_tooltip =
		"Display the whitepoint color on the screen.\n"
		"\nDefault: Off";
> = false;

#endif

//#endregion

//#region Textures

#if WHITEPOINT_FIXER_MODE_1_OR_2

texture PickedColorTex //<pooled = true;>
{
	Format = R32F;
};

sampler PickedColor
{
	Texture = PickedColorTex;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

#endif

#if WHITEPOINT_FIXER_MODE == 2

texture DownsampleTex <pooled = true;>
{
	Width = DownsampleSize;
	Height = DownsampleSize;
	Format = R8;
};

sampler Downsample
{
	Texture = DownsampleTex;
};

texture LastPickedColorTex
{
	Format = R32F;
};

sampler LastPickedColor
{
	Texture = LastPickedColorTex;
	MinFilter = POINT;
	MagFilter = POINT;
	MipFilter = POINT;
};

#endif

//#endregion

//#region Functions

#if WHITEPOINT_FIXER_MODE_1_OR_2

float GetGrayscale(float3 color)
{
    float cout = 0.0;
	switch (GrayscaleFormula)
	{
		case GrayscaleFormula_Average:
			cout = dot(color, 0.333);
			break;
		case GrayscaleFormula_Max:
			cout = max(color.r, max(color.g, color.b));
			break;
		case GrayscaleFormula_Luma:
			cout = GetLumaGamma(color);
			break;
	}

	return cout;
}

#endif

float GetWhitepoint()
{
	#if WHITEPOINT_FIXER_MODE == 0
		return Whitepoint;
	#elif WHITEPOINT_FIXER_MODE_1_OR_2
		return tex2Dfetch(PickedColor, 0).x;
	#else
		#error "Invalid mode"
	#endif
}

/**
 * Check if a contains b within a size margin.
 */
float Contains(float size, float a, float b)
{
	return step(a - size, b) * step(b, a + size);
}

//#endregion

//#region Shaders

#if WHITEPOINT_FIXER_MODE == 2

float DownsamplePS(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{
	return GetGrayscale(tex2D(ReShade::BackBuffer, uv).rgb);
}

#endif

#if WHITEPOINT_FIXER_MODE_1_OR_2

float PickColorPS(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{
	float value;

	#if WHITEPOINT_FIXER_MODE == 1
	{
		if (!(RunColorPicker && MouseRightDown))
			discard;

		value = GetGrayscale(tex2D(ReShade::BackBuffer, MousePoint * GetPixelSize()).rgb);
	}
	#elif WHITEPOINT_FIXER_MODE == 2
	{
		value = 0.0;

		for (int x = 0; x < DownsampleSize; ++x)
		{
			for (int y = 0; y < DownsampleSize; ++y)
			{
				value = max(value, tex2Dfetch(Downsample, int2(x, y)).x);
			}
		}
	}
	#else
		#error "Invalid mode"
	#endif

	if (value < MinimumWhitepoint)
		value = RemappedWhitepoint;

	#if WHITEPOINT_FIXER_MODE == 2
		if (abs(TransitionSpeed) > 1e-6)
		{
			value = FXSHADERS_INTERPOLATE(
				tex2Dfetch(LastPickedColor, 0).x,
				value,
				TransitionSpeed,
				FrameTime * 0.001);
		}
	#endif

	return value;
}

#endif

#if WHITEPOINT_FIXER_MODE == 2

float SavePickedColorPS(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{
	return tex2Dfetch(PickedColor, 0).x;
}

#endif

float4 MainPS(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{

	const float2 res = GetResolution();
	const float2 coord = uv * res;

	float4 color = tex2D(ReShade::BackBuffer, uv);
	const float whitepoint = GetWhitepoint();
	color.rgb /= max(whitepoint, 1e-6);

	#if WHITEPOINT_FIXER_MODE == 1
		if (RunColorPicker && MouseRightDown)
		{
			const float size = ColorPickerCrosshairThickness * 0.5;

			color.rgb = lerp(
				color.rgb,
				1.0 - color.rgb,
				saturate(
					Contains(size, MousePoint.x, coord.x) +
					Contains(size, MousePoint.y, coord.y)));

			float2 picker_pos = MousePoint;
			const float2 offset = ColorPickerTooltipOffset;

			// Make the tooltip always visible on the screen by flipping the
			// offset if it's gone outside the screen bounds.
			if (picker_pos.x + offset.x < 0.0 || picker_pos.y + offset.y < 0.0 || picker_pos.x + offset.x > res.x || picker_pos.y + offset.y > res.y)
				picker_pos += -offset;
			else
				picker_pos += offset;

			color.rgb = lerp(color.rgb, whitepoint, step(distance(coord, picker_pos), ColorPickerTooltipRadius));
		}
	#endif

	#if WHITEPOINT_FIXER_MODE_1_OR_2
		if (ShowWhitepoint)
		{
			const float2 whitepoint_pos =
				(1.0 - abs(uv - 0.5) * 2.0) * res;

			if (
				whitepoint_pos.x < ShowWhitepointSize.x &&
				whitepoint_pos.y < ShowWhitepointSize.y)
			{
				color.rgb = whitepoint;
			}
		}
	#endif

#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
	return color;
#endif
}

//#endregion

//#region Technique

technique WhitepointerFixer
{
	#if WHITEPOINT_FIXER_MODE == 2

	pass Downsample
	{
		VertexShader = PostProcessVS;
		PixelShader = DownsamplePS;
		RenderTarget = DownsampleTex;
	}

	#endif

	#if WHITEPOINT_FIXER_MODE_1_OR_2

	pass PickColor
	{
		VertexShader = PostProcessVS;
		PixelShader = PickColorPS;
		RenderTarget = PickedColorTex;
	}

	#if WHITEPOINT_FIXER_MODE == 2

	pass SavePickedColor
	{
		VertexShader = PostProcessVS;
		PixelShader = SavePickedColorPS;
		RenderTarget = LastPickedColorTex;
	}

	#endif

	#endif

	pass Main
	{
		VertexShader = PostProcessVS;
		PixelShader = MainPS;
	}
}

//#endregion

}
