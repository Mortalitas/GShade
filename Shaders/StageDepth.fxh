// Made by Marot Satil for GShade, a fork of ReShade.
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much and if you message me directly it's very likely to get flagged as spam.
// If you have questions about this shader or need to contact me for any other reason, reaching out to me via the username Marot on Discord is likely a better bet.
//
// This shader was designed in the same vein as GreenScreenDepth.fx, but instead of applying a
// green screen with adjustable distance, it applies a PNG texture with adjustable opacity.
//
// PNG transparency is fully supported, so you could for example add another moon to the sky
// just as readily as create a "green screen" stage like in real life.
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

#define STAGEDEPTH_SUMMONING(StageDepth_Texture, StageDepthTex, StageDepth_Size_X, StageDepth_Size_Y, StageDepth_Texformat, StageDepth_Sampler, StageDepth_BlendMode, StageDepth_Category, StageDepth_Opacity, StageDepth_Depth, STAGEDEPTH_SCALE, StageDepth_ScaleX, StageDepth_ScaleY, StageDepth_PosX, StageDepth_PosY, StageDepth_SnapRotate, StageDepth_Rotate, StageDepth_InvertDepth, PS_StageDepth, STAGEDEPTH_NAME) \
texture StageDepth_Texture <source=StageDepthTex;> { Width = StageDepth_Size_X; Height = StageDepth_Size_Y; Format=StageDepth_Texformat; }; \
\
sampler StageDepth_Sampler { Texture = StageDepth_Texture; }; \
\
BLENDING_COMBO(StageDepth_BlendMode, "Blending Mode", "Select the blending mode applied to the layer.", StageDepth_Category, true, 0, 0) \
\
uniform float StageDepth_Opacity < \
	ui_category = StageDepth_Category; \
	ui_label = "Blending"; \
	ui_tooltip = "The amount of blending applied to the image."; \
	ui_type = "slider"; \
	ui_min = 0.0; \
	ui_max = 1.0; \
	ui_step = 0.002; \
> = 1.0; \
\
uniform float StageDepth_Depth < \
	ui_category = StageDepth_Category; \
	ui_type = "slider"; \
	ui_min = 0.0; \
	ui_max = 1.0; \
	ui_label = "Depth"; \
> = 0.97; \
\
uniform float STAGEDEPTH_SCALE < \
	ui_category = StageDepth_Category; \
	ui_type = "slider"; \
	ui_label = "Scale X & Y"; \
	ui_min = 0.001; ui_max = 5.0; \
	ui_step = 0.001; \
> = 1.001; \
\
uniform float StageDepth_ScaleX < \
	ui_category = StageDepth_Category; \
	ui_type = "slider"; \
	ui_label = "Scale X"; \
	ui_min = 0.001; ui_max = 5.0; \
	ui_step = 0.001; \
> = 1.0; \
\
uniform float StageDepth_ScaleY < \
	ui_category = StageDepth_Category; \
	ui_type = "slider"; \
	ui_label = "Scale Y"; \
	ui_min = 0.001; ui_max = 5.0; \
	ui_step = 0.001; \
> = 1.0; \
\
uniform float StageDepth_PosX < \
	ui_category = StageDepth_Category; \
	ui_type = "slider"; \
	ui_label = "Position X"; \
	ui_min = -2.0; ui_max = 2.0; \
	ui_step = 0.001; \
> = 0.5; \
\
uniform float StageDepth_PosY < \
	ui_category = StageDepth_Category; \
	ui_type = "slider"; \
	ui_label = "Position Y"; \
	ui_min = -2.0; ui_max = 2.0; \
	ui_step = 0.001; \
> = 0.5; \
\
uniform int StageDepth_SnapRotate < \
	ui_category = StageDepth_Category; \
	ui_type = "combo"; \
	ui_label = "Snap Rotation"; \
	ui_items = "None\0" \
			   "90 Degrees\0" \
			   "-90 Degrees\0" \
			   "180 Degrees\0" \
			   "-180 Degrees\0"; \
	ui_tooltip = "Snap rotation to a specific angle."; \
> = false; \
\
uniform float StageDepth_Rotate < \
	ui_category = StageDepth_Category; \
	ui_label = "Rotate"; \
	ui_type = "slider"; \
	ui_min = -180.0; \
	ui_max = 180.0; \
	ui_step = 0.01; \
> = 0; \
\
uniform bool StageDepth_InvertDepth < \
	ui_category = StageDepth_Category; \
	ui_label = "Invert Depth"; \
	ui_tooltip = "Inverts the depth buffer so that the texture is applied to the foreground instead."; \
> = false; \
\
void PS_StageDepth(in float4 position : SV_Position, in float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) \
{ \
	passColor = tex2D(ReShade::BackBuffer, texCoord); \
	const float depth = StageDepth_InvertDepth ? ReShade::GetLinearizedDepth(texCoord).r : 1 - ReShade::GetLinearizedDepth(texCoord).r; \
\
	if (depth < StageDepth_Depth) \
	{ \
		const float3 backColor = tex2D(ReShade::BackBuffer, texCoord).rgb; \
		const float3 pivot = float3(0.5, 0.5, 0.0); \
		const float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT)); \
		const float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH)); \
		const float3 mulUV = float3(texCoord.x, texCoord.y, 1); \
		const float2 ScaleSize = (float2(StageDepth_Size_X, StageDepth_Size_Y) * STAGEDEPTH_SCALE / BUFFER_SCREEN_SIZE); \
		const float ScaleX =  ScaleSize.x * AspectX * StageDepth_ScaleX; \
		const float ScaleY =  ScaleSize.y * AspectY * StageDepth_ScaleY; \
		float Rotate = StageDepth_Rotate * (3.1415926 / 180.0); \
\
		switch(StageDepth_SnapRotate) \
		{ \
			default: \
				break; \
			case 1: \
				Rotate = -90.0 * (3.1415926 / 180.0); \
				break; \
			case 2: \
				Rotate = 90.0 * (3.1415926 / 180.0); \
				break; \
			case 3: \
				Rotate = 0.0; \
				break; \
			case 4: \
				Rotate = 180.0 * (3.1415926 / 180.0); \
				break; \
		} \
\
		const float3x3 positionMatrix = float3x3 ( \
			1, 0, 0, \
			0, 1, 0, \
			-StageDepth_PosX, -StageDepth_PosY, 1 \
		); \
		const float3x3 scaleMatrix = float3x3 ( \
			1/ScaleX, 0, 0, \
			0,  1/ScaleY, 0, \
			0, 0, 1 \
		); \
		const float3x3 rotateMatrix = float3x3 ( \
			(cos (Rotate) * AspectX), (sin(Rotate) * AspectX), 0, \
			(-sin(Rotate) * AspectY), (cos(Rotate) * AspectY), 0, \
			0, 0, 1 \
		); \
\
		const float3 SumUV = mul (mul (mul (mulUV, positionMatrix), rotateMatrix), scaleMatrix); \
		passColor = tex2D(StageDepth_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot)); \
\
		passColor.rgb = ComHeaders::Blending::Blend(StageDepth_BlendMode, backColor, passColor.rgb, passColor.a * StageDepth_Opacity); \
	} \
} \
\
technique STAGEDEPTH_NAME \
{ \
	pass \
	{ \
		VertexShader = PostProcessVS; \
		PixelShader = PS_StageDepth; \
	} \
} \