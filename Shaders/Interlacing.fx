////////////////////////////////////////////////////////
// Interlacing
// Author: EDCVBNM
// Repository: https://github.com/EDCVBNM/ED-shaders
////////////////////////////////////////////////////////

#include "ReShade.fxh"

uniform int lineHeight <
	ui_type = "slider";
	ui_min = 1; ui_max = 100;
	ui_label = "Line height";
	ui_tooltip = "Most of the time you'll want this at 1";
> = 1;

uniform bool lineCheck <
	ui_label = "Line check";
> = false;

uniform float framecount < source = "framecount"; >;

texture currentTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler currentSamp { Texture = currentTex; };

texture previousTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler previousSamp { Texture = previousTex; };

float3 currentFrame(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	return tex2D(ReShade::BackBuffer, texcoord).rgb;
}

float3 interlacing(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	if(lineCheck == true)
	{
		if(pos.y % (lineHeight * 2) <= lineHeight)
		{
			return 0;
		}
		else
		{
			return tex2D(ReShade::BackBuffer, texcoord).rgb;
		}
	}
	else
	{
		if(framecount / 2.0 <= 0.0)
		{
			if(pos.y % (lineHeight * 2) <= lineHeight)
			{
				return tex2D(previousSamp, texcoord).rgb;
			}
			else
			{
				return tex2D(ReShade::BackBuffer, texcoord).rgb;
			}
		}
		else
		{
			if((pos.y + lineHeight) % (lineHeight * 2) <= lineHeight)
			{
				return tex2D(previousSamp, texcoord).rgb;
			}
			else
			{
				return tex2D(ReShade::BackBuffer, texcoord).rgb;
			}
		}
	}
}

float3 previousFrame(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	return tex2D(currentSamp, texcoord).rgb;
}

technique Interlacing
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = currentFrame;
		RenderTarget = currentTex;
	}

	pass pass1
	{
		VertexShader = PostProcessVS;
		PixelShader = interlacing;
	}

	pass pass2
	{
		VertexShader = PostProcessVS;
		PixelShader = previousFrame;
		RenderTarget = previousTex;
	}
}
