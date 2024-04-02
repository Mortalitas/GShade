////////////////////////////////////////////////////////
// LumaLines
// Author: EDCVBNM
// Repository: https://github.com/EDCVBNM/ED-shaders
////////////////////////////////////////////////////////

#include "ReShade.fxh"

uniform int lineDensity <
	ui_type = "slider";
	ui_min = 1; ui_max = 100;
	ui_tooltip = "if you put this at 0 your game crashes";
> = 10;

uniform float blackThreshold <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.1;

uniform float whiteThreshold <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.9;

uniform bool blend <
> = false;

float3 lumaLines(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	int OneBitLuma, OneBitLumaShift, lines;
	float luma = dot(tex2D(ReShade::BackBuffer, texcoord).rgb, 1.0 / 3.0);

	for(float i = 1.0 / lineDensity; i <= 1.0 - (1.0 / lineDensity); i += (1.0 / lineDensity))
	{
		OneBitLuma = ceil(1.0 - step(luma, i));

		OneBitLumaShift = ceil(1.0 - step(dot(tex2Dlod(ReShade::BackBuffer, float4(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y, 0.0, 0.0)).rgb, 1.0 / 3.0), i));
		lines += OneBitLumaShift - OneBitLuma;

		OneBitLumaShift = ceil(1.0 - step(dot(tex2Dlod(ReShade::BackBuffer, float4(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y, 0.0, 0.0)).rgb, 1.0 / 3.0), i));
		lines += OneBitLumaShift - OneBitLuma;

		OneBitLumaShift = ceil(1.0 - step(dot(tex2Dlod(ReShade::BackBuffer, float4(texcoord.x, texcoord.y + BUFFER_RCP_HEIGHT, 0.0, 0.0)).rgb, 1.0 / 3.0), i));
		lines += OneBitLumaShift - OneBitLuma;

		OneBitLumaShift = ceil(1.0 - step(dot(tex2Dlod(ReShade::BackBuffer, float4(texcoord.x, texcoord.y - BUFFER_RCP_HEIGHT, 0.0, 0.0)).rgb, 1.0 / 3.0), i));
		lines += OneBitLumaShift - OneBitLuma;
	}

	lines = max(lines, ceil(step(luma, blackThreshold)));
	lines = min(lines, ceil(step(luma, whiteThreshold)));

	if(blend)
	{
		return (1.0 - lines) * tex2D(ReShade::BackBuffer, texcoord).rgb;
	}
	else
	{
		return 1.0 - lines;
	}
}

technique LumaLines
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = lumaLines;
	}
}
