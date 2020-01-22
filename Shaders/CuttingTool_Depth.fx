// -------------------------------------
// Depth-based Cutting Tool (c) seri14
// -------------------------------------

// -------------------------------------
// Includes
// -------------------------------------

#include "ReShade.fxh"

// -------------------------------------
// Variables
// -------------------------------------

uniform float3 Point1 <
	ui_label = "Point 1 (near)";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.00001;
> = 0.0;

uniform float3 Point2 <
	ui_label = "Point 2 (far)";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.00001;
> = 1.0;

// -------------------------------------
// Depth-based Selection
// -------------------------------------

void PS_Main(float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 frontColor : SV_Target)
{
	const float3 gameCoord = float3(texCoord, ReShade::GetLinearizedDepth(texCoord));
	frontColor = tex2D(ReShade::BackBuffer, texCoord);
	frontColor.a = 1.0 - gameCoord.z;
	frontColor *= step(1.0, 1.0 - (gameCoord - clamp(gameCoord, Point1, Point2)));
}

// -------------------------------------
// Techniques
// -------------------------------------

technique CuttingTool_Depth <
	ui_label = "Cutting Tool (Depth-based)";
> {
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Main;
	}
}
