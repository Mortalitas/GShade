// -------------------------------------
// Clipboard (c) seri14
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

sampler Sampler
{
	Texture = Clipboard_Texture;
};

// -------------------------------------
// Variables
// -------------------------------------

uniform float BlendIntensity <
	ui_label = "Alpha blending level";
	ui_type = "drag";
	ui_min = 0.001; ui_max = 1000.0;
	ui_step = 0.001;
> = 1.0;

// -------------------------------------
// Entrypoints
// -------------------------------------

void PS_Copy(float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 frontColor : SV_Target)
{
	frontColor = tex2D(ReShade::BackBuffer, texCoord);
}

void PS_Paste(float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 frontColor : SV_Target)
{
	const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);

	frontColor = tex2D(Sampler, texCoord);
	frontColor = lerp(backColor, frontColor, min(1.0, frontColor.a * BlendIntensity));
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
