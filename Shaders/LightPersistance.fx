////////////////////////////////////////////////////////
// LightPersistance
// Author: EDCVBNM
// Repository: https://github.com/EDCVBNM/ED-shaders
////////////////////////////////////////////////////////

#include "ReShade.fxh"

uniform float persistance <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Persistance";
> = 0.1;

texture LPt { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler LPs { Texture = LPt; };

float3 lightPersistance(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	return max(tex2D(LPs, texcoord).rgb, tex2D(ReShade::BackBuffer, texcoord).rgb);
}

float3 previousFrame(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	if(persistance == 0.0)
	{
		return tex2D(ReShade::BackBuffer, texcoord).rgb;
	}
	else
	{
		return (tex2D(ReShade::BackBuffer, texcoord).rgb / (1 + persistance)) - 0.002;
	}
}

technique LightPersistance
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = lightPersistance;
	}

	pass pass1
	{
		VertexShader = PostProcessVS;
		PixelShader = previousFrame;
		RenderTarget = LPt;
	}
}
