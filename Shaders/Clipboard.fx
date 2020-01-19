// -------------------------------------
// Clipboard (c) 2020 seri14
// -------------------------------------

// -------------------------------------
// Includes
// -------------------------------------

#include "ReShade.fxh"

// -------------------------------------
// Textures
// -------------------------------------

texture Clipboard_Texture
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

// -------------------------------------
// Samplers
// -------------------------------------

sampler Clipboard_Sampler
{
	Texture = Clipboard_Texture;
};

// -------------------------------------
// Variables
// -------------------------------------

uniform bool Transparent = true;

// -------------------------------------
// Entrypoints
// -------------------------------------

void PS_Copy(float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 frontColor : SV_Target)
{
	frontColor = tex2D(ReShade::BackBuffer, texCoord);

	if (!Transparent)
		frontColor.a = 1.0;
}

void PS_Paste(float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 frontColor : SV_Target)
{
	const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);

	frontColor = tex2D(Clipboard_Sampler, texCoord);
	frontColor = lerp(backColor, frontColor, frontColor.a);
}

// -------------------------------------
// Techniques
// -------------------------------------

technique Copy
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Copy;
		RenderTarget = Clipboard_Texture;
	}
}

technique Paste
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Paste;
	}
}
