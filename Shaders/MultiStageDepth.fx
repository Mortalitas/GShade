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


#include "ReShade.fxh"

#define MULTISTAGEDEPTH_TEX_FORMAT RGBA8

uniform int Tex_Select <
    ui_label = "Texture";
    ui_tooltip = "The image to use.";
    ui_type = "combo";
    ui_items = "Fire1.png\0Fire2.png\0Snow1.png\0Snow2.png\0Shatter1.png\0Lightrays1.png\0VignetteSharp.png\0VignetteSoft.png\0Metal1.jpg\0Ice1.jpg\0";
    ui_bind = "MultiStageDepthTexture_Source";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef MultiStageDepthTexture_Source
#define MultiStageDepthTexture_Source 0
#endif

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

#if   MultiStageDepthTexture_Source == 0 // Fire1.png
#define _SOURCE_MULTILUT_FILE "Fire1.png"
#elif MultiStageDepthTexture_Source == 1 // Fire2.png
#define _SOURCE_MULTILUT_FILE "Fire2.png"
#elif MultiStageDepthTexture_Source == 2 // Snow1.png
#define _SOURCE_MULTILUT_FILE "Snow1.png"
#elif MultiStageDepthTexture_Source == 3 // Snow2.png
#define _SOURCE_MULTILUT_FILE "Snow2.png"
#elif MultiStageDepthTexture_Source == 4 // Shatter1.png
#define _SOURCE_MULTILUT_FILE "Shatter1.png"
#elif MultiStageDepthTexture_Source == 5 // Lightrays1.png
#define _SOURCE_MULTILUT_FILE "Lightrays1.png"
#elif MultiStageDepthTexture_Source == 6 // VignetteSharp.png
#define _SOURCE_MULTILUT_FILE "VignetteSharp.png"
#elif MultiStageDepthTexture_Source == 7 // VignetteSoft.png
#define _SOURCE_MULTILUT_FILE "VignetteSoft.png"
#elif MultiStageDepthTexture_Source == 8 // Metal1.jpg
#define _SOURCE_MULTILUT_FILE "Metal1.jpg"
#elif MultiStageDepthTexture_Source == 9 // Ice1.jpg
#define _SOURCE_MULTILUT_FILE "Ice1.jpg"
#endif

texture MultiStageDepth_texture <source = _SOURCE_MULTILUT_FILE;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format= MULTISTAGEDEPTH_TEX_FORMAT; };
sampler MultiStageDepth_sampler { Texture = MultiStageDepth_texture; };

void PS_StageDepth(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float3 color : SV_Target)
{
    color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    const float depth = 1 - ReShade::GetLinearizedDepth(texcoord).r;

    if (depth < Stage_depth)
    {
        const float4 Multi_stage = tex2D(MultiStageDepth_sampler, texcoord);
        color = lerp(color, Multi_stage.rgb, Multi_stage.a * Stage_Opacity);
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