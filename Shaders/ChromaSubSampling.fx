////////////////////////////////////////////////////////
// ChromaSubSampling
// Author: EDCVBNM
// Repository: https://github.com/EDCVBNM/ED-shaders
////////////////////////////////////////////////////////

#include "ReShade.fxh"

uniform int chromaSubType <
    ui_label = "Type";
    ui_type  = "combo";
    ui_items = " 4:2:2\0 4:2:0\0 4:1:1\0 idk how to name this one\0";
> = 0;

uniform bool showChroma <
    ui_label = "Show Only Chroma";
> = false;

texture chromaSubTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler chromaSubSamp { Texture = chromaSubTex; };

float3 chromaSubSetup(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	if(chromaSubType == 0)
	{
		if(pos.x % 2 <= 1)
		{
			return tex2D(ReShade::BackBuffer, texcoord).rgb;
		}
	}
	else if(chromaSubType == 1)
	{
		if(pos.x % 2 <= 1 && pos.y % 2 <= 1)
		{
			return tex2D(ReShade::BackBuffer, texcoord).rgb;
		}
	}
	else if(chromaSubType == 2)
	{
		if(pos.x % 4 <= 1)
		{
			return tex2D(ReShade::BackBuffer, texcoord).rgb;
		}
	}
	else
	{
		if(pos.x % 3 <= 1 && pos.y % 3 <= 1)
		{
			return tex2D(ReShade::BackBuffer, texcoord).rgb;
		}
	}

	return 0;
}

float3 chromaSubSampling(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float luma = (tex2D(ReShade::BackBuffer, texcoord).r + tex2D(ReShade::BackBuffer, texcoord).g + tex2D(ReShade::BackBuffer, texcoord).b) / 3;
	float3 color = tex2D(chromaSubSamp, texcoord).rgb;

	if(chromaSubType == 0)
	{
		color += tex2D(chromaSubSamp, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y)).rgb;
	}
	else if(chromaSubType == 1)
	{
		color += tex2D(chromaSubSamp, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x, texcoord.y + BUFFER_RCP_HEIGHT)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y + BUFFER_RCP_HEIGHT)).rgb;
	}
	else if(chromaSubType == 2)
	{
		color += tex2D(chromaSubSamp, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x + BUFFER_RCP_WIDTH * 2, texcoord.y)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x + BUFFER_RCP_WIDTH * 3, texcoord.y)).rgb;
	}
	else
	{
		color += tex2D(chromaSubSamp, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x, texcoord.y + BUFFER_RCP_HEIGHT)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x, texcoord.y - BUFFER_RCP_HEIGHT)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y + BUFFER_RCP_HEIGHT)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y - BUFFER_RCP_HEIGHT)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y - BUFFER_RCP_HEIGHT)).rgb;
		color += tex2D(chromaSubSamp, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y + BUFFER_RCP_HEIGHT)).rgb;
	}

	float lumaSubSampling = (color.r + color.g + color.b) / 3;

	color -= lumaSubSampling;

    if(showChroma)
    {
        return color;
    }
    else
    {
        return color + luma;
    }
}

technique ChromaSubSampling
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = chromaSubSetup;
		RenderTarget = chromaSubTex;
	}
	pass pass1
	{
		VertexShader = PostProcessVS;
		PixelShader = chromaSubSampling;
	}
}
