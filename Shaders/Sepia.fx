// Lightly optimized by Marot Satil for the GShade project.
uniform float3 Tint <
	ui_type = "color";
> = float3(0.55, 0.43, 0.42);

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Adjust the strength of the effect.";
> = 0.58;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 TintPass(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
#if GSHADE_DITHER
	float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	col = lerp(col, col * Tint * 2.55, Strength);
	return col + TriDither(col, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	const float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb;

	return lerp(col, col * Tint * 2.55, Strength);
#endif
}

technique Tint
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = TintPass;
	}
}
