/*------------------.
| :: Description :: |
'-------------------/

	DropShadow

	Authors: CeeJay.dk, seri14, Marot Satil, Uchu Suzume, prod80, originalnicodr
	License: MIT
	
	Based off of Layer.fx, this shader uses depth to create a simple, solid-color adjustable drop shadow.
*/

#include "ReShade.fxh"

texture DropShadow_Texture { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler DropShadow_Sampler {
	Texture = DropShadow_Texture;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

uniform float fTargetDepth <
	ui_type = "slider";
	ui_label = "Target Depth";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.0001;
> = 0.0;

uniform float4 fColor < 
	ui_label = "Color";
	ui_type = "color";
> = float4(0, 1.0, 0, 1.0);

uniform float fPosX <
	ui_type = "slider";
	ui_label = "Position X";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

uniform float fPosY <
	ui_type = "slider";
	ui_label = "Position Y";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

uniform float fScaleXY <
	ui_type = "slider";
	ui_label = "Scale X & Y";
	ui_min = 0.001; ui_max = 5.0;
	ui_step = 0.001;
> = 1.001;

uniform float fScaleX <
	ui_type = "slider";
	ui_label = "Scale X";
	ui_min = 0.001; ui_max = 5.0;
	ui_step = 0.001;
> = 1.0;

uniform float fScaleY <
	ui_type = "slider";
	ui_label = "Scale Y";
	ui_min = 0.001; ui_max = 5.0;
	ui_step = 0.001;
> = 1.0;

uniform int iSnapRotate <
	ui_type = "combo";
	ui_label = "Snap Rotation";
	ui_items = "None\0"
			   "90 Degrees\0"
			   "-90 Degrees\0"
			   "180 Degrees\0"
			   "-180 Degrees\0";
	ui_tooltip = "Snap rotation to a specific angle.";
> = false;

uniform float iRotate <
	ui_label = "Rotate";
	ui_type = "slider";
	ui_min = -180.0;
	ui_max = 180.0;
	ui_step = 0.01;
> = 0;

void PS_DropShadowBack(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {

	if (ReShade::GetLinearizedDepth(texCoord) < fTargetDepth)
	{
		passColor = fColor;
	}
	else
	{
		passColor = 0.0;
	}
}

void PS_DropShadow(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
	if (ReShade::GetLinearizedDepth(texCoord) > fTargetDepth)
	{
		const float3 pivot = float3(0.5, 0.5, 0.0);
		const float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT));
		const float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH));
		const float3 mulUV = float3(texCoord.x, texCoord.y, 1);
		const float2 ScaleSize = (float2(BUFFER_WIDTH, BUFFER_HEIGHT) * fScaleXY / BUFFER_SCREEN_SIZE);
		const float ScaleX =  ScaleSize.x * AspectX * fScaleX;
		const float ScaleY =  ScaleSize.y * AspectY * fScaleY;
		float Rotate = iRotate * (3.1415926 / 180.0);

		switch(iSnapRotate)
		{
			default:
				break;
			case 1:
				Rotate = -90.0 * (3.1415926 / 180.0);
				break;
			case 2:
				Rotate = 90.0 * (3.1415926 / 180.0);
				break;
			case 3:
				Rotate = 0.0;
				break;
			case 4:
				Rotate = 180.0 * (3.1415926 / 180.0);
				break;
		}

		const float3x3 positionMatrix = float3x3 (
			1, 0, 0,
			0, 1, 0,
			-fPosX, -fPosY, 1
		);
		const float3x3 scaleMatrix = float3x3 (
			1/ScaleX, 0, 0,
			0,  1/ScaleY, 0,
			0, 0, 1
		);
		const float3x3 rotateMatrix = float3x3 (
		   (cos (Rotate) * AspectX), (sin(Rotate) * AspectX), 0,
			(-sin(Rotate) * AspectY), (cos(Rotate) * AspectY), 0,
			0, 0, 1
		);

		const float3 SumUV = mul (mul (mul (mulUV, positionMatrix), rotateMatrix), scaleMatrix);
		const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);
		passColor = tex2D(DropShadow_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));
		
		passColor = lerp(backColor.rgb, passColor.rgb, passColor.a);
	}
	else
	{
		discard;
	}
}


technique DropShadow {
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_DropShadowBack;
		RenderTarget = DropShadow_Texture;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_DropShadow;
	}
}