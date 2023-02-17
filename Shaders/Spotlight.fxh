/*
	Spotlight shader based on the Flashlight shader by luluco250

	MIT Licensed.

  Modifications by ninjafada and Marot Satil
*/

sampler2D sColor {
	Texture = ReShade::BackBufferTex;
	SRGBTexture = true;
	MinFilter = POINT;
	MagFilter = POINT;
};

#define SPOTLIGHT_SUMMONING(Spotlight_Category, Spotlight_Center_X, Spotlight_Center_Y, Spotlight_Brightness, Spotlight_Size, Spotlight_Color, Spotlight_InvertDepthCutoff, Spotlight_DepthCutoff, Spotlight_Distance, Spotlight_BlendFix, Spotlight_ToggleTexture, Spotlight_ToggleDepth, Spotlight_ToggleDepthCutoff, Spotlight_PS, Spotlight_Name) \
uniform float Spotlight_Center_X < \
	ui_category = Spotlight_Category; \
	ui_category_closed = true; \
	ui_label = "X Position"; \
	ui_type = "slider"; \
	ui_min = -1.0; ui_max = 1.0; \
	ui_tooltip = "X coordinate of beam center. Axes start from upper left screen corner."; \
> = 0; \
\
uniform float Spotlight_Center_Y < \
	ui_category = Spotlight_Category; \
	ui_label = "Y Position"; \
	ui_type = "slider"; \
	ui_min = -1.0; ui_max = 1.0; \
	ui_tooltip = "Y coordinate of beam center. Axes start from upper left screen corner."; \
> = 0; \
\
uniform float Spotlight_Brightness < \
	ui_category = Spotlight_Category; \
	ui_label = "Brightness"; \
	ui_tooltip = \
		"Spotlight halo brightness.\n" \
		"\nDefault: 10.0"; \
	ui_type = "slider"; \
	ui_min = 0.0; \
	ui_max = 100.0; \
	ui_step = 0.01; \
> = 10.0; \
\
uniform float Spotlight_Size < \
	ui_category = Spotlight_Category; \
	ui_label = "Size"; \
	ui_tooltip = \
		"Spotlight halo size in pixels.\n" \
		"\nDefault: 420.0"; \
	ui_type = "slider"; \
	ui_min = 10.0; \
	ui_max = 1000.0; \
	ui_step = 1.0; \
> = 420.0; \
\
uniform float3 Spotlight_Color < \
	ui_category = Spotlight_Category; \
	ui_label = "Color"; \
	ui_tooltip = \
		"Spotlight halo color.\n" \
		"\nDefault: R:255 G:230 B:200"; \
	ui_type = "color"; \
> = float3(255, 230, 200) / 255.0; \
\
uniform bool Spotlight_InvertDepthCutoff < \
	ui_category = Spotlight_Category; \
	ui_label = "Invert Depth Cutoff"; \
> = 0; \
\
uniform float Spotlight_DepthCutoff < \
	ui_category = Spotlight_Category; \
	ui_label = "Depth Cutoff"; \
	ui_tooltip = \
		"The distance at which the spotlight is visible.\n" \
		"Only works if the game has depth buffer access."; \
	ui_type = "slider"; \
	ui_min = 0.0; \
	ui_max = 1.0; \
> = 0.97; \
\
uniform float Spotlight_Distance < \
	ui_category = Spotlight_Category; \
	ui_label = "Distance"; \
	ui_tooltip = \
		"The distance that the spotlight can illuminate.\n" \
		"Only works if the game has depth buffer access.\n" \
		"\nDefault: 0.1"; \
	ui_type = "slider"; \
	ui_min = 0.0; \
	ui_max = 1.0; \
	ui_step = 0.001; \
> = 0.1; \
\
uniform bool Spotlight_BlendFix < \
	ui_category = Spotlight_Category; \
	ui_label = "Toggle Blend Fix"; \
	ui_tooltip = "Enable to use the original blending mode."; \
> = 0; \
\
uniform bool Spotlight_ToggleTexture < \
	ui_category = Spotlight_Category; \
	ui_label = "Toggle Texture"; \
	ui_tooltip = "Enable or disable the spotlight texture."; \
> = 1; \
\
uniform bool Spotlight_ToggleDepth < \
	ui_category = Spotlight_Category; \
	ui_label = "Toggle Depth"; \
	ui_tooltip = "Enable or disable depth."; \
> = 1; \
\
uniform bool Spotlight_ToggleDepthCutoff < \
	ui_category = Spotlight_Category; \
	ui_label = "Toggle Depth Cutoff"; \
	ui_tooltip = "Enable or disable depth cutoff."; \
> = 0; \
\
\
float4 Spotlight_PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET \
{ \
	const float depth = Spotlight_InvertDepthCutoff ? ReShade::GetLinearizedDepth(uv).r : 1 - ReShade::GetLinearizedDepth(uv).r; \
\
	if (!Spotlight_ToggleDepthCutoff || depth < Spotlight_DepthCutoff) \
	{ \
		const float2 res = BUFFER_SCREEN_SIZE; \
		const float2 coord = res * (uv - float2(Spotlight_Center_X, -Spotlight_Center_Y)); \
		const float halo = distance(coord, res * 0.5); \
		float spotlight = Spotlight_Size - min(halo, Spotlight_Size); \
		spotlight /= Spotlight_Size; \
\
		if (Spotlight_ToggleTexture == 0) \
		{ \
			float defects = sin(spotlight * 30.0) * 0.5 + 0.5; \
			defects = lerp(defects, 1.0, spotlight * 2.0); \
\
			static const float contrast = 0.125; \
\
			defects = 0.5 * (1.0 - contrast) + defects * contrast; \
			spotlight *= defects * 4.0; \
		} \
		else \
		{ \
			spotlight *= 2.0; \
		} \
\
		if (Spotlight_ToggleDepth == 1) \
		{ \
			const float sdepth = pow(max(1.0 - ReShade::GetLinearizedDepth(uv), 0.0), 1.0 / Spotlight_Distance); \
			spotlight *= sdepth; \
		} \
\
		float3 colored_spotlight = spotlight * Spotlight_Color; \
		colored_spotlight *= colored_spotlight * colored_spotlight; \
\
		const float3 result = 1.0 + colored_spotlight * Spotlight_Brightness; \
\
		float3 color = tex2D(sColor, uv).rgb; \
		color *= result; \
\
		if (!Spotlight_BlendFix) \
			color = max(color, (result - 1.0) * 0.001); \
\
		return float4(color, 1.0); \
	} \
	else \
	{ \
		discard; \
	} \
} \
\
technique Spotlight_Name { \
	pass { \
		VertexShader = PostProcessVS; \
		PixelShader = Spotlight_PS; \
		SRGBWriteEnable = true; \
	} \
} \
