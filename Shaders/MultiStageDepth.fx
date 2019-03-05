// Made by Marot Satil for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
// Follow @GPOSERS_FFXIV on Twitter and join us on Discord (https://discord.gg/39WpvU2)
// for the latest GShade package updates!
//
// This shader was designed in the same vein as GreenScreenDepth.fx, but instead of applying a
// green screen with adjustable distance, it applies a PNG texture with adjustable opacity.
//
// PNG transparency is fully supported, so you could for example add another moon to the sky
// just as readily as create a "green screen" stage like in real life.
//
// Textures provided by Yomigami Okami & Johnni Maestro.
// You can follow Yomi via @Yomigammy on Twitter!
//
// Copyright (c) 2019, Marot Satil
// All rights reserved.
//
// Backglow1.png, Fire1.png, Fire2.png, Lightrays1.png, Shatter1.png, Snow1.png, Snow2.png Copyright (c) 2019, Yomigami Okami
// All rights reserved.
//
// VignetteSharp.png, VignetteSoft.png (c) 2019, Johnni Maestro
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#include "Reshade.fxh"

#define TEXFORMAT RGBA8

uniform int Tex_Select <
    ui_label = "Texture";
    ui_tooltip = "The image to use.";
    ui_type = "combo";
    ui_items = "Fire1.png\0Fire2.png\0Snow1.png\0Snow2.png\0Shatter1.png\0Lightrays1.png\0VignetteSharp.png\0VignetteSoft.png\0Metal1.jpg\0Ice1.jpg\0";
> = 0;

uniform float Stage_Opacity <
    ui_label = "Opacity";
    ui_tooltip = "Set the transparency of the image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform float Stage_depth <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Depth";
> = 0.97;

texture Fire_one_texture <source="Fire1.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Fire_one_sampler { Texture = Fire_one_texture; };

texture Fire_two_texture <source="Fire2.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Fire_two_sampler { Texture = Fire_two_texture; };

texture Snow_one_texture <source="Snow1.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Snow_one_sampler { Texture = Snow_one_texture; };

texture Snow_two_texture <source="Snow2.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Snow_two_sampler { Texture = Snow_two_texture; };

texture Shatter_one_texture <source="Shatter1.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Shatter_one_sampler { Texture = Shatter_one_texture; };

texture Lightrays_one_texture <source="Lightrays1.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Lightrays_one_sampler { Texture = Lightrays_one_texture; };

texture Vignette_sharp_texture <source="VignetteSharp.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Vignette_sharp_sampler { Texture = Vignette_sharp_texture; };

texture Vignette_soft_texture <source="VignetteSoft.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Vignette_soft_sampler { Texture = Vignette_soft_texture; };

texture Metal_one_texture <source="Metal1.jpg";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Metal_one_sampler { Texture = Metal_one_texture; };

texture Ice_one_texture <source="Ice1.jpg";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Ice_one_sampler { Texture = Ice_one_texture; };


void PS_StageDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float3 color : SV_Target)
{
  float4 Fire_one_stage = tex2D(Fire_one_sampler, texcoord).rgba;
  float4 Fire_two_stage = tex2D(Fire_two_sampler, texcoord).rgba;
  float4 Snow_one_stage = tex2D(Snow_one_sampler, texcoord).rgba;
  float4 Snow_two_stage = tex2D(Snow_two_sampler, texcoord).rgba;
  float4 Shatter_one_stage = tex2D(Shatter_one_sampler, texcoord).rgba;
  float4 Lightrays_one_stage = tex2D(Lightrays_one_sampler, texcoord).rgba;
  float4 Vignette_sharp_stage = tex2D(Vignette_sharp_sampler, texcoord).rgba;
  float4 Vignette_soft_stage = tex2D(Vignette_soft_sampler, texcoord).rgba;
  float4 Metal_one_stage = tex2D(Metal_one_sampler, texcoord).rgba;
  float4 Ice_one_stage = tex2D(Ice_one_sampler, texcoord).rgba;

	color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float depth = 1 - ReShade::GetLinearizedDepth(texcoord).r;

	if ((Tex_Select == 0) && (depth < Stage_depth))
	{
		color = lerp(color, Fire_one_stage.rgb, Fire_one_stage.a * Stage_Opacity);
	}
	else if ((Tex_Select == 1) && (depth < Stage_depth))
	{
		color = lerp(color, Fire_two_stage.rgb, Fire_two_stage.a * Stage_Opacity);
	}
	else if ((Tex_Select == 2) && (depth < Stage_depth))
	{
    color = lerp(color, Snow_one_stage.rgb, Snow_one_stage.a * Stage_Opacity);
	}
	else if ((Tex_Select == 3) && (depth < Stage_depth))	
	{
    color = lerp(color, Snow_two_stage.rgb, Snow_two_stage.a * Stage_Opacity);
	}
	else if ((Tex_Select == 4) && (depth < Stage_depth))	
	{
    color = lerp(color, Shatter_one_stage.rgb, Shatter_one_stage.a * Stage_Opacity);
	}
	else if ((Tex_Select == 5) && (depth < Stage_depth))	
	{
    color = lerp(color, Lightrays_one_stage.rgb, Lightrays_one_stage.a * Stage_Opacity);
	}
	else if ((Tex_Select == 6) && (depth < Stage_depth))	
	{
    color = lerp(color, Vignette_sharp_stage.rgb, Vignette_sharp_stage.a * Stage_Opacity);
	}
	else if ((Tex_Select == 7) && (depth < Stage_depth))	
	{
    color = lerp(color, Vignette_soft_stage.rgb, Vignette_soft_stage.a * Stage_Opacity);
	}
	else if ((Tex_Select == 8) && (depth < Stage_depth))	
	{
    color = lerp(color, Metal_one_stage.rgb, Metal_one_stage.a * Stage_Opacity);
	}
	else if ((Tex_Select == 9) && (depth < Stage_depth))	
	{
    color = lerp(color, Ice_one_stage.rgb, Ice_one_stage.a * Stage_Opacity);
	}
}

technique MultiStageDepth
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_StageDepth;
	}
}