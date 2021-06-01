/*
	Full credits to the ReShade team
	Ported by Insomnia
*/

uniform float fEmbossPower <
	ui_type = "slider";
	ui_min = 0.01; ui_max = 2.0;
	ui_label = "Emboss Power";
> = 0.150;
uniform float fEmbossOffset <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 5.0;
	ui_label = "Emboss Offset";
> = 1.00;
uniform float iEmbossAngle <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 360.0;
	ui_label = "Emboss Angle";
> = 90.00;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 EmbossPass(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

        float2 offset;
	sincos(radians( iEmbossAngle), offset.y, offset.x);
	const float3 col1 = tex2D(ReShade::BackBuffer, texcoord - BUFFER_PIXEL_SIZE*fEmbossOffset*offset).rgb;
	const float3 col3 = tex2D(ReShade::BackBuffer, texcoord + BUFFER_PIXEL_SIZE*fEmbossOffset*offset).rgb;

	const float3 colEmboss = col1 * 2.0 - color - col3;

	const float colDot = max(0,dot(colEmboss, 0.333))*fEmbossPower;

	const float3 colFinal = color - colDot;

	const float luminance = dot( color, float3( 0.6, 0.2, 0.2 ) );

#if GSHADE_DITHER
	const float3 outcolor = lerp( colFinal, color, luminance * luminance ).xyz;
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp( colFinal, color, luminance * luminance ).xyz;
#endif
}

technique Emboss_Tech
{
	pass Emboss
	{
		VertexShader = PostProcessVS;
		PixelShader = EmbossPass;
	}
}
