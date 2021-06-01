// Lightly optimized by Marot Satil for the GShade project.
#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float fCurve <
	ui_label = "Curve";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 3.0;
	ui_step = 0.001;
> = 1.0;

uniform float4 f4Offsets <
	ui_label = "Offsets";
	ui_tooltip = "{ Low Color, High Color, Both, Unused }";
	ui_type = "slider";
	ui_min = -1.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = float4(0.0, 0.0, 0.0, 0.0);

float4 PS_SCurve(
	const float4 pos : SV_POSITION,
	const float2 uv : TEXCOORD
) : SV_TARGET {
	float3 col = tex2D(ReShade::BackBuffer, uv).rgb;
	const float lum = max(col.r, max(col.g, col.b));

	//col = lerp(pow(col, fCurve), pow(col, 1.0 / fCurve), lum);
	
	const float3 low = pow(abs(col), fCurve) + f4Offsets.x;
	const float3 high = pow(abs(col), 1.0 / fCurve) + f4Offsets.y;

	col.r = lerp(low.r, high.r, col.r + f4Offsets.z);
	col.g = lerp(low.g, high.g, col.g + f4Offsets.z);
	col.b = lerp(low.b, high.b, col.b + f4Offsets.z);

#if GSHADE_DITHER
	return float4(col.rgb + TriDither(col.rgb, uv, BUFFER_COLOR_BIT_DEPTH), 1.0);
#else
	return float4(col, 1.0);
#endif
}

technique SCurve {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_SCurve;
	}
}
