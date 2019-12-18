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

float3 fHDRPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 bloom_sum1 = tex2D(ReShade::BackBuffer, texcoord + float2(1.5, -1.5) * fradius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5, -1.5) * fradius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 1.5,  1.5) * fradius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5,  1.5) * fradius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0, -2.5) * fradius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0,  2.5) * fradius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2(-2.5,  0.0) * fradius1 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum1 += tex2D(ReShade::BackBuffer, texcoord + float2( 2.5,  0.0) * fradius1 * BUFFER_PIXEL_SIZE).rgb;

	bloom_sum1 *= 0.005;

	float3 bloom_sum2 = tex2D(ReShade::BackBuffer, texcoord + float2(1.5, -1.5) * fradius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5, -1.5) * fradius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 1.5,  1.5) * fradius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2(-1.5,  1.5) * fradius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0, -2.5) * fradius2 * BUFFER_PIXEL_SIZE).rgb;	
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 0.0,  2.5) * fradius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2(-2.5,  0.0) * fradius2 * BUFFER_PIXEL_SIZE).rgb;
	bloom_sum2 += tex2D(ReShade::BackBuffer, texcoord + float2( 2.5,  0.0) * fradius2 * BUFFER_PIXEL_SIZE).rgb;

	bloom_sum2 *= 0.010;

	const float dist = fradius2 - fradius1;
	const float3 HDR = (color + (bloom_sum2 - bloom_sum1)) * dist;
	const float3 blend = HDR + color;

	// pow - don't use fractions for fHDRpower
	return saturate(pow(abs(blend), fHDRPower) + HDR);
}

technique FakeHDR
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = fHDRPass;
	}
}
