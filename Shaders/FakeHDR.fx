/**
 * HDR
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * Not actual HDR - It just tries to mimic an HDR look (relatively high performance cost)
 */
 // Lightly optimized by Marot Satil for the GShade project.

uniform float fHDRPower <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0;
	ui_label = "Power";
> = 1.30;
uniform float fradius1 <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0;
	ui_label = "Radius 1";
> = 0.793;
uniform float fradius2 <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0;
	ui_label = "Radius 2";
	ui_tooltip = "Raising this seems to make the effect stronger and also brighter.";
> = 0.87;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

// !!! modified - Craig - Jul 6th, 2020
float3 fHDRPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	// !!! pre-calc radius * BPS values
	const float2 rad1 = fradius1 * BUFFER_PIXEL_SIZE;
	const float2 rad2 = fradius2 * BUFFER_PIXEL_SIZE;

	// !!! updated to use new pre-calc'ed rad value
	const float3 bloom_sum1  = (
		tex2D(ReShade::BackBuffer, texcoord + float2( 1.5, -1.5) * rad1).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2(-1.5, -1.5) * rad1).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2( 1.5,  1.5) * rad1).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2(-1.5,  1.5) * rad1).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2( 0.0, -2.5) * rad1).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2( 0.0,  2.5) * rad1).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2(-2.5,  0.0) * rad1).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2( 2.5,  0.0) * rad1).rgb
		) * 0.005;

	// !!! updated to use new pre-calc'ed rad value
	const float3 bloom_sum2  = (
		tex2D(ReShade::BackBuffer, texcoord + float2( 1.5, -1.5) * rad2).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2(-1.5, -1.5) * rad2).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2( 1.5,  1.5) * rad2).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2(-1.5,  1.5) * rad2).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2( 0.0, -2.5) * rad2).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2( 0.0,  2.5) * rad2).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2(-2.5,  0.0) * rad2).rgb +
		tex2D(ReShade::BackBuffer, texcoord + float2( 2.5,  0.0) * rad2).rgb
		) * 0.01;

	const float3 HDR = (color + (bloom_sum2 - bloom_sum1)) * (fradius2 - fradius1);

#if GSHADE_DITHER
	const float3 outcolor = saturate(pow(abs(HDR + color), abs(fHDRPower)) + HDR); // pow - don't use fractions for HDRpower
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(pow(abs(HDR + color), abs(fHDRPower)) + HDR); // pow - don't use fractions for HDRpower
#endif
}

technique FakeHDR
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = fHDRPass;
	}
}
