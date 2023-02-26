//#region Preprocessor

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

//#endregion

//#region Uniforms

uniform int Mode
<
	ui_type = "combo";
	ui_text =
		"How to use:\n"
		"\n"
		"First, choose what kind of chromatic aberration you wish to use by "
		"setting the Mode. Check it's description for details.\n"
		"\n"
		"Secondly, define the Ratio. This controls the chromatic aberration's "
		"\"colors\".\n"
		"\n"
		"Finally, set how large the chromatic aberration will be by setting "
		"the Multiplier.\n"
		" ";
	ui_tooltip =
		"Mode defining how the chromatic aberration is created.   \n"
		"\n"
		"  Translate:\n"
		"    Move channels horizontally and vertically.   \n"
		"\n"
		"  Scale:\n"
		"    Zoom channels from the center.   \n"
		"\n"
		"Default: Scale";
	ui_items = "Translate\0Scale\0";
> = 1;

uniform float3 Ratio
<
	ui_type = "slider";
	ui_tooltip =
		"Ratio of how each channel is distorted.\n"
		"The values control the red, green and blue channels respectively.   \n"
		"\n"
		"Default: -1.0 0.0 1.0";
	ui_min = -1.0;
	ui_max = 1.0;
> = float3(-1.0, 0.0, 1.0);

uniform float Multiplier
<
	ui_type = "slider";
	ui_tooltip =
		"Multiplier of the ratio, defining how much distortion there is.   \n"
		"\n"
		"Default: 1.0";
	ui_min = 0.0;
	ui_max = 6.0;
	ui_step = 0.001;
> = 1.0;

uniform float Amount
<
	ui_type = "slider";
	ui_tooltip =
		"Amount applied to CA effect.   \n"
		"\n"
		"Default: 1.0";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 1.0;

uniform float2 CenterPos <
    ui_label = "Center Position";
    ui_tooltip = "Coordinates for center of chromatic aberration with Scale option selected.   ";
    ui_type = "slider";
    ui_min = 0.0;
	ui_max = 1.0;
    ui_step = 0.001;
> = float2(0.5, 0.5);

//#endregion

//#region Functions

float2 scale_uv(float2 uv, float2 scale, float2 center)
{
	return (uv - float2(CenterPos.x, CenterPos.y)) * scale + float2(CenterPos.x, CenterPos.y);
}

//#endregion

//#region Shaders

float4 MainPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	const float2 ps = ReShade::PixelSize;

	float2 uv_r = uv;
	float2 uv_g = uv;
	float2 uv_b = uv;

	float3 ratio;

	switch (Mode)
	{
		case 0: // Translate
			ratio = Ratio * Multiplier;

			uv_r += ps * ratio.r;
			uv_g += ps * ratio.g;
			uv_b += ps * ratio.b;
			break;
		case 1: // Scale
			ratio = Multiplier * length(ps) + 1.0;
			ratio = lerp(ratio, 1.0 / ratio, Ratio * 0.5 + 0.5);

			uv_r = scale_uv(uv_r, ratio.r, 0.5);
			uv_g = scale_uv(uv_g, ratio.g, 0.5);
			uv_b = scale_uv(uv_b, ratio.b, 0.5);
			break;
	}

	const float3 colorCA = float3(
		tex2D(ReShade::BackBuffer, uv_r).r,
		tex2D(ReShade::BackBuffer, uv_g).g,
		tex2D(ReShade::BackBuffer, uv_b).b);

    float3 backColor = tex2D(ReShade::BackBuffer, uv).rgb;
	float3 color = lerp(backColor, colorCA, Amount);

#if GSHADE_DITHER
	return float4(color + TriDither(color, uv, BUFFER_COLOR_BIT_DEPTH), 1.0);
#else
	return float4(color, 1.0);
#endif
}

//#endregion

//#region Technique

technique FlexibleCA
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MainPS;
	}
}

//#endregion