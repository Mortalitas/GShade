// Made by Marot Satil for GShade, a fork of ReShade.
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much and if you message me directly it's very likely to get flagged as spam.
// If you have questions about this shader or need to contact me for any other reason, reaching out to me via the username Marot on Discord is likely a better bet.
//
// A simple shader for rotating, scaling, and moving the entire frame.
//
// Copyright © 2023 Marot Satil
// This work is free. You can redistribute it and/or modify it under the
// terms of the Do What The Fuck You Want To Public License, Version 2,
// as published by Sam Hocevar.
//
//            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                    Version 2, December 2004
//
// Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
//
// Everyone is permitted to copy and distribute verbatim or modified
// copies of this license document, and changing it is allowed as long
// as the name is changed.
//
//            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
//  0. You just DO WHAT THE FUCK YOU WANT TO.

#include "ReShade.fxh"

uniform float Display_Scale <
  ui_type = "slider";
    ui_label = "Scale X & Y";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.001;

uniform float Display_ScaleX <
  ui_type = "slider";
    ui_label = "Scale X";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float Display_ScaleY <
  ui_type = "slider";
    ui_label = "Scale Y";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float Display_PosX <
  ui_type = "slider";
    ui_label = "Position X";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform float Display_PosY <
  ui_type = "slider";
    ui_label = "Position Y";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform int Display_SnapRotate <
    ui_type = "combo";
	ui_label = "Snap Rotation";
    ui_items = "None\0"
               "90 Degrees\0"
               "-90 Degrees\0"
               "180 Degrees\0"
               "-180 Degrees\0";
	ui_tooltip = "Snap rotation to a specific angle.";
> = false;

uniform float Display_Rotate <
    ui_label = "Rotate";
    ui_type = "slider";
    ui_min = -180.0;
    ui_max = 180.0;
    ui_step = 0.01;
> = 0;

void PS_DisplayMod(in float4 position : SV_Position, in float2 texCoord : TEXCOORD, out float4 passColor : SV_Target)
{
	const float3 pivot = float3(0.5, 0.5, 0.0);
	const float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT));
	const float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH));
	const float3 mulUV = float3(texCoord.x, texCoord.y, 1);
	const float2 ScaleSize = (float2(BUFFER_WIDTH, BUFFER_HEIGHT) * Display_Scale / BUFFER_SCREEN_SIZE);
	const float ScaleX =  ScaleSize.x * AspectX * Display_ScaleX;
	const float ScaleY =  ScaleSize.y * AspectY * Display_ScaleY;
	float Rotate = Display_Rotate * (3.1415926 / 180.0);

	switch(Display_SnapRotate)
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
		case 5:
			Rotate = -180.0 * (3.1415926 / 180.0);
			break;
	}

	const float3x3 positionMatrix = float3x3 (
		1, 0, 0,
		0, 1, 0,
		-Display_PosX, -Display_PosY, 1
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
	passColor = tex2D(ReShade::BackBuffer, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));
}

technique DisplayMod
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_DisplayMod;
    }
}