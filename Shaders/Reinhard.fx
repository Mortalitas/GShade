/*
	Original code by Marty McFly
	Amateur port by Insomnia 
*/

uniform float ReinhardWhitepoint <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 10.0;
	ui_tooltip = "how steep the color curve is at linear point";
> = 1.250;
uniform float ReinhardScale <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 3.0;
	ui_tooltip = "how steep the color curve is at linear point";
> = 0.50;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 ReinhardPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 x = tex2D(ReShade::BackBuffer, texcoord).rgb;
	const float W =  ReinhardWhitepoint;	// Linear White Point Value
	const float K =  ReinhardScale;        // Scale

	// gamma space or not?
#if GSHADE_DITHER
	const float3 outcolor = (1 + K * x / (W * W)) * x / (x + K);
	return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return (1 + K * x / (W * W)) * x / (x + K);
#endif
}

technique Reinhard
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ReinhardPass;
	}
}
