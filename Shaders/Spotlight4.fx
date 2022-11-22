/*
	Spotlight shader based on the Flashlight shader by luluco250

	MIT Licensed.

  Modifications by ninjafada and Marot Satil
*/

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float u4XCenter <
  ui_label = "X Position";
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "X coordinate of beam center. Axes start from upper left screen corner.";
> = 0;

uniform float u4YCenter <
  ui_label = "Y Position";
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Y coordinate of beam center. Axes start from upper left screen corner.";
> = 0;

uniform float u4Brightness <
	ui_label = "Brightness";
	ui_tooltip =
		"Spotlight halo brightness.\n"
		"\nDefault: 10.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 100.0;
	ui_step = 0.01;
> = 10.0;

uniform float u4Size <
	ui_label = "Size";
	ui_tooltip =
		"Spotlight halo size in pixels.\n"
		"\nDefault: 420.0";
	ui_type = "slider";
	ui_min = 10.0;
	ui_max = 1000.0;
	ui_step = 1.0;
> = 420.0;

uniform float3 u4Color <
	ui_label = "Color";
	ui_tooltip =
		"Spotlight halo color.\n"
		"\nDefault: R:255 G:230 B:200";
	ui_type = "color";
> = float3(255, 230, 200) / 255.0;

uniform float u4Distance <
	ui_label = "Distance";
	ui_tooltip =
		"The distance that the spotlight can illuminate.\n"
		"Only works if the game has depth buffer access.\n"
		"\nDefault: 0.1";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 0.1;

uniform bool u4BlendFix <
  ui_label = "Toggle Blend Fix";
	ui_tooltip = "Enable to use the original blending mode.";
> = 0;

uniform bool u4ToggleTexture <
	ui_label = "Toggle Texture";
	ui_tooltip = "Enable or disable the spotlight texture.";
> = 1;

uniform bool u4ToggleDepth <
	ui_label = "Toggle Depth";
	ui_tooltip = "Enable or disable depth.";
> = 1;

sampler2D s4Color {
	Texture = ReShade::BackBufferTex;
	SRGBTexture = true;
	MinFilter = POINT;
	MagFilter = POINT;
};

#define nsin(x) (sin(x) * 0.5 + 0.5)

float4 PS_4Spotlight(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
	const float2 res = BUFFER_SCREEN_SIZE;
	const float2 uCenter = uv - float2(u4XCenter, -u4YCenter);
	const float2 coord = res * uCenter;

	const float halo = distance(coord, res * 0.5);
	float spotlight = u4Size - min(halo, u4Size);
	spotlight /= u4Size;
	
	// Add some texture to the halo by using some sin lines + reduce intensity
	// when nearing the center of the halo.
	if (u4ToggleTexture == 0)
	{
		float defects = sin(spotlight * 30.0) * 0.5 + 0.5;
		defects = lerp(defects, 1.0, spotlight * 2.0);

		static const float contrast = 0.125;

		defects = 0.5 * (1.0 - contrast) + defects * contrast;
		spotlight *= defects * 4.0;
	}
	else
	{
    spotlight *= 2.0;
  }

	if (u4ToggleDepth == 1)
  {
    const float depth = pow(abs(1.0 - ReShade::GetLinearizedDepth(uv)), 1.0 / u4Distance);
    spotlight *= depth;
  }

	float3 colored_spotlight = spotlight * u4Color;
	colored_spotlight *= colored_spotlight * colored_spotlight;

	const float3 result = 1.0 + colored_spotlight * u4Brightness;

	float3 color = tex2D(s4Color, uv).rgb;
	color *= result;

	if (!u4BlendFix)
    // Add some minimum amount of light to very dark pixels.	
    color = max(color, (result - 1.0) * 0.001);

#if GSHADE_DITHER
	return float4(color + TriDither(color, uv, BUFFER_COLOR_BIT_DEPTH), 1.0);
#else
	return float4(color, 1.0);
#endif
}

technique Spotlight4 {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_4Spotlight;
		SRGBWriteEnable = true;
	}
}
