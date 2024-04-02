////////////////////////////////////////////////////////
// CathodeRayTube
// Author: EDCVBNM
// Repository: https://github.com/EDCVBNM/ED-shaders
////////////////////////////////////////////////////////

#include "ReShade.fxh"

uniform int mask <
    ui_label = "Type";
    ui_type  = "combo";
    ui_items = "Aperture Grille\0Slot Mask\0Shadow Mask\0Bigger Shadow Mask\0";
> = 0;

uniform bool blurToggle <
    ui_label = "Blur";
> = true;

texture AGSUt { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler AGSUs { Texture = AGSUt; AddressU = BORDER; AddressV = BORDER; };

texture AGt { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler AGs { Texture = AGt; AddressU = BORDER; AddressV = BORDER; };

texture SMSUt { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SMSUs { Texture = SMSUt; AddressU = BORDER; AddressV = BORDER; };

texture SMt { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler SMs { Texture = SMt; AddressU = BORDER; AddressV = BORDER; };

texture ShMt { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler ShMs { Texture = ShMt; AddressU = BORDER; AddressV = BORDER; };

float3 blur(int radius, float2 texcoord1)
{
    int divisor = 0;
	float3 blur = float3(0.0, 0.0, 0.0);

    for(int x = -radius; x <= radius; x++)
    {
        for(int y = -floor(sqrt(radius * (radius + 1) - x * x)); y <= floor(sqrt(radius * (radius + 1) - x * x)); y++)
        {
            blur += tex2Dlod(ReShade::BackBuffer, float4(texcoord1.x + (BUFFER_RCP_WIDTH * x), texcoord1.y + (BUFFER_RCP_HEIGHT * y), 0.0, 0.0)).rgb;
            divisor++;
        }
    }

    return blur / divisor;
}

float3 ApertureGrilleSetUp(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	if((pos.x + 2) % 3 <= 1)
    {
        if(blurToggle)
        {
		    return blur(2, texcoord);
        }
        else
        {
            return tex2D(ReShade::BackBuffer, texcoord).rgb;
        }
	}

	return 0;
}

float3 ApertureGrille(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float3 color = tex2D(AGSUs, texcoord).rgb
	+ tex2D(AGSUs, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y)).rgb
	+ tex2D(AGSUs, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y)).rgb;

    if(pos.x % 3 <= 1 && pos.y % 3 <= 1)
    {
        return color *= float3(1.0, 0.0, 0.0);
    }
    if((pos.x + 2) % 3 <= 1 && pos.y % 3 <= 1)
    {
        return color *= float3(0.0, 1.0, 0.0);
    }
    if((pos.x + 1) % 3 <= 1 && pos.y % 3 <= 1)
    {
        return color *= float3(0.0, 0.0, 1.0);
    }

	return 0;
}

float3 SlotMaskSetUp(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	if((pos.x + 3) % 4 <= 1)
    {
        if(blurToggle)
        {
		    return blur(2, texcoord);
        }
        else
        {
            return tex2D(ReShade::BackBuffer, texcoord).rgb;
        }
	}

	return 0;
}

float3 SlotMask(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float3 color = tex2D(SMSUs, texcoord).rgb
	+ tex2D(SMSUs, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y)).rgb
	+ tex2D(SMSUs, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y)).rgb;

    if(pos.x % 8 <= 1 && pos.y % 4 <= 1)
    {
        return color *= float3(1.0, 0.0, 0.0);
    }
    if((pos.x + 7) % 8 <= 1 && pos.y % 4 <= 1)
    {
        return color *= float3(0.0, 1.0, 0.0);
    }
    if((pos.x + 6) % 8 <= 1 && pos.y % 4 <= 1)
    {
        return color *= float3(0.0, 0.0, 1.0);
    }
    if((pos.x + 4) % 8 <= 1 && (pos.y + 2) % 4 <= 1)
    {
        return color *= float3(1.0, 0.0, 0.0);
    }
    if((pos.x + 11) % 8 <= 1 && (pos.y + 2) % 4 <= 1)
    {
        return color *= float3(0.0, 1.0, 0.0);
    }
    if((pos.x + 10) % 8 <= 1 && (pos.y + 2) % 4 <= 1)
    {
        return color *= float3(0.0, 0.0, 1.0);
    }

    return 0;
}

float3 ShadowMask(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
    float3 color;

    if(mask == 2)
	{
        if(blurToggle)
        {
            color = blur(2, texcoord);
        }
        else
        {
            color = tex2D(ReShade::BackBuffer, texcoord).rgb;
        }
    }
    if(mask == 3)
	{
        if(blurToggle)
        {
            color = blur(4, texcoord);
        }
        else
        {
            color = tex2D(ReShade::BackBuffer, texcoord).rgb;
        }
    }

	if(mask == 2)
	{
		if(pos.x % 6 <= 1 && pos.y % 4 <= 1)
		{
			return color *= float3(1.0, 0.0, 0.0);
		}
		if((pos.x + 4) % 6 <= 1 && pos.y % 4 <= 1)
		{
			return color *= float3(0.0, 1.0, 0.0);
		}
		if((pos.x + 2) % 6 <= 1 && pos.y % 4 <= 1)
		{
			return color *= float3(0.0, 0.0, 1.0);
		}
		if((pos.x + 3) % 6 <= 1 && (pos.y + 2) % 4 <= 1)
		{
			return color *= float3(1.0, 0.0, 0.0);
		}
		if((pos.x + 7) % 6 <= 1 && (pos.y + 2) % 4 <= 1)
		{
			return color *= float3(0.0, 1.0, 0.0);
		}
		if((pos.x + 5) % 6 <= 1 && (pos.y + 2) % 4 <= 1)
		{
			return color *= float3(0.0, 0.0, 1.0);
		}
	}
	else if(mask == 3)
	{
		if(pos.x % 12 <= 1 && pos.y % 6 <= 1)
		{
			return color *= float3(1.0, 0.0, 0.0);
		}
		if((pos.x + 8) % 12 <= 1 && pos.y % 6 <= 1)
		{
			return color *= float3(0.0, 1.0, 0.0);
		}
		if((pos.x + 4) % 12 <= 1 && pos.y % 6 <= 1)
		{
			return color *= float3(0.0, 0.0, 1.0);
		}
		if((pos.x + 6) % 12 <= 1 && (pos.y + 3) % 6 <= 1)
		{
			return color *= float3(1.0, 0.0, 0.0);
		}
		if((pos.x + 14) % 12 <= 1 && (pos.y + 3) % 6 <= 1)
		{
			return color *= float3(0.0, 1.0, 0.0);
		}
		if((pos.x + 10) % 12 <= 1 && (pos.y + 3) % 6 <= 1)
		{
			return color *= float3(0.0, 0.0, 1.0);
		}
	}

	return 0;
}

float3 main(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    if(mask == 0)
	{
        return tex2D(AGs, texcoord).rgb
		+ tex2D(AGs, float2(texcoord.x, texcoord.y + BUFFER_RCP_HEIGHT)).rgb
		+ tex2D(AGs, float2(texcoord.x, texcoord.y - BUFFER_RCP_HEIGHT)).rgb;
    }
    else if(mask == 1)
	{
        return tex2D(SMs, texcoord).rgb
        + tex2D(SMs, float2(texcoord.x, texcoord.y + BUFFER_RCP_HEIGHT)).rgb
		+ tex2D(SMs, float2(texcoord.x, texcoord.y - BUFFER_RCP_HEIGHT)).rgb;
    }
    else
	{
		if(mask == 2)
		{
			return tex2D(ShMs, texcoord).rgb;
		}
		else
		{
			return tex2D(ShMs, texcoord).rgb
			+ tex2D(ShMs, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y)).rgb
			+ tex2D(ShMs, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y)).rgb
			+ tex2D(ShMs, float2(texcoord.x, texcoord.y + BUFFER_RCP_HEIGHT)).rgb
			+ tex2D(ShMs, float2(texcoord.x, texcoord.y - BUFFER_RCP_HEIGHT)).rgb
			+ tex2D(ShMs, float2(texcoord.x - (BUFFER_RCP_WIDTH * 2), texcoord.y)).rgb
			+ tex2D(ShMs, float2(texcoord.x, texcoord.y - (BUFFER_RCP_HEIGHT * 2))).rgb
			+ tex2D(ShMs, float2(texcoord.x + BUFFER_RCP_WIDTH, texcoord.y - BUFFER_RCP_HEIGHT)).rgb
			+ tex2D(ShMs, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y + BUFFER_RCP_HEIGHT)).rgb
			+ tex2D(ShMs, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y - BUFFER_RCP_HEIGHT)).rgb
			+ tex2D(ShMs, float2(texcoord.x - BUFFER_RCP_WIDTH, texcoord.y - (BUFFER_RCP_HEIGHT * 2))).rgb
			+ tex2D(ShMs, float2(texcoord.x - (BUFFER_RCP_WIDTH * 2), texcoord.y - BUFFER_RCP_HEIGHT)).rgb;
		}
	}

    return 0;
}

technique CathodeRayTube
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = ApertureGrilleSetUp;
		RenderTarget = AGSUt;
	}
    pass pass1
	{
		VertexShader = PostProcessVS;
		PixelShader = ApertureGrille;
		RenderTarget = AGt;
	}
	pass pass2
	{
		VertexShader = PostProcessVS;
		PixelShader = SlotMaskSetUp;
		RenderTarget = SMSUt;
	}
    pass pass3
	{
		VertexShader = PostProcessVS;
		PixelShader = SlotMask;
		RenderTarget = SMt;
	}
	pass pass4
	{
		VertexShader = PostProcessVS;
		PixelShader = ShadowMask;
		RenderTarget = ShMt;
	}
	pass pass5
	{
		VertexShader = PostProcessVS;
		PixelShader = main;
	}
}
