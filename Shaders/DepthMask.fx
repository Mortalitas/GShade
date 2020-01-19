// -------------------------------------
// DepthMask (c) 2020 seri14
// -------------------------------------

// -------------------------------------
// Includes
// -------------------------------------

#include "ReShade.fxh"

// -------------------------------------
// Variables
// -------------------------------------

uniform float3 A <
	ui_type = "slider";
	ui_min = float3(0.0, 0.0, 0.0); ui_max = float3(1.0, 1.0, 1.0);
	ui_step = 0.001;
> = float3(0.0, 0.0, 0.0);

uniform float3 B <
	ui_type = "slider";
	ui_min = float3(0.0, 0.0, 0.0); ui_max = float3(1.0, 1.0, 1.0);
	ui_step = 0.001;
> = float3(1.0, 1.0, 1.0);

uniform bool Reversed = true;

// -------------------------------------
// Entrypoints
// -------------------------------------

void PS_DepthMask(float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 frontColor : SV_Target)
{
	const float3 gameCoord = float3(texCoord, ReShade::GetLinearizedDepth(texCoord));

	if (all(A <= gameCoord && gameCoord <= B) != Reversed)
	{
		frontColor = tex2D(ReShade::BackBuffer, gameCoord.xy);
		frontColor.a = 1.0 - gameCoord.z;
	}
	else
	{
		frontColor = 0.0;
	}
}

// -------------------------------------
// Techniques
// -------------------------------------

technique DepthMask
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DepthMask;
	}
}
