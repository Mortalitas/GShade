// Made by Marot Satil, seri14, & Uchu Suzume for the GShade ReShade package!
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
// Copyright (c) 2019, Marot Satil
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
#include "Blending.fxh"

#define TEXFORMAT RGBA8

#ifndef Stage3Tex
#define Stage3Tex "LayerStage.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif
#ifndef STAGE3_SIZE_X
#define STAGE3_SIZE_X BUFFER_WIDTH
#endif
#ifndef STAGE3_SIZE_Y
#define STAGE3_SIZE_Y BUFFER_HEIGHT
#endif

uniform int Stage3_BlendMode <
    ui_type = "combo";
    ui_label = "Blending Mode";
    ui_tooltip = "Select the blending mode applied to the layer.";
    ui_items = "Normal\0"
               "Multiply\0"
               "Screen\0"
               "Overlay\0"
               "Darken\0"
               "Lighten\0"
               "Color Dodge\0"
               "Color Burn\0"
               "Hard Light\0"
               "Soft Light\0"
               "Difference\0"
               "Exclusion\0"
               "Hue\0"
               "Saturation\0"
               "Color\0"
               "Luminosity\0"
               "Linear Burn\0"
               "Linear Dodge\0"
               "Vivid Light\0"
               "Linear Light\0"
               "Pin Light\0"
               "Hard Mix\0"
               "Reflect\0"
               "Glow\0"
               "Grain Merge\0"
               "Grain Extract\0"
               "Addition\0"
               "Subtract\0"
               "Divide\0";
> = 0;

uniform float Stage3_Opacity <
    ui_label = "Blending";
    ui_tooltip = "The amount of blending applied to the image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform float Stage3_depth <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_label = "Depth";
> = 0.97;

uniform float Stage3_Scale <
  ui_type = "slider";
    ui_label = "Scale X & Y";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.001;

uniform float Stage3_ScaleX <
  ui_type = "slider";
    ui_label = "Scale X";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float Stage3_ScaleY <
  ui_type = "slider";
    ui_label = "Scale Y";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float Stage3_PosX <
  ui_type = "slider";
    ui_label = "Position X";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform float Stage3_PosY <
  ui_type = "slider";
    ui_label = "Position Y";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform int Stage3_SnapRotate <
    ui_type = "combo";
	ui_label = "Snap Rotation";
    ui_items = "None\0"
               "90 Degrees\0"
               "-90 Degrees\0"
               "180 Degrees\0"
               "-180 Degrees\0";
	ui_tooltip = "Snap rotation to a specific angle.";
> = false;

uniform float Stage3_Rotate <
    ui_label = "Rotate";
    ui_type = "slider";
    ui_min = -180.0;
    ui_max = 180.0;
    ui_step = 0.01;
> = 0;

texture Stage3_texture <source=Stage3Tex;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };

sampler Stage3_sampler { Texture = Stage3_texture; };

void PS_StageDepth3(in float4 position : SV_Position, in float2 texCoord : TEXCOORD, out float4 passColor : SV_Target)
{
    passColor = tex2D(ReShade::BackBuffer, texCoord);
    const float depth = 1 - ReShade::GetLinearizedDepth(texCoord).r;

    if (depth < Stage3_depth)
    {
        const float3 backColor = tex2D(ReShade::BackBuffer, texCoord).rgb;
        const float3 pivot = float3(0.5, 0.5, 0.0);
        const float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT));
        const float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH));
        const float3 mulUV = float3(texCoord.x, texCoord.y, 1);
        const float2 ScaleSize = (float2(STAGE3_SIZE_X, STAGE3_SIZE_Y) * Stage3_Scale / BUFFER_SCREEN_SIZE);
        const float ScaleX =  ScaleSize.x * AspectX * Stage3_ScaleX;
        const float ScaleY =  ScaleSize.y * AspectY * Stage3_ScaleY;
        float Rotate = Stage3_Rotate * (3.1415926 / 180.0);

        switch(Stage3_SnapRotate)
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
            -Stage3_PosX, -Stage3_PosY, 1
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
        passColor = tex2D(Stage3_sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));

        switch (Stage3_BlendMode)
        {
            // Normal
            default:
                passColor = lerp(backColor.rgb, passColor.rgb, passColor.a * Stage3_Opacity);
                break;
            // Multiply
            case 1:
                passColor = lerp(backColor.rgb, Multiply(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Screen
            case 2:
                passColor = lerp(backColor.rgb, Screen(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Overlay
            case 3:
                passColor = lerp(backColor.rgb, Overlay(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Darken
            case 4:
                passColor = lerp(backColor.rgb, Darken(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Lighten
            case 5:
                passColor = lerp(backColor.rgb, Lighten(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // ColorDodge
            case 6:
                passColor = lerp(backColor.rgb, ColorDodge(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // ColorBurn
            case 7:
                passColor = lerp(backColor.rgb, ColorBurn(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // HardLight
            case 8:
                passColor = lerp(backColor.rgb, HardLight(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // SoftLight
            case 9:
                passColor = lerp(backColor.rgb, SoftLight(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Difference
            case 10:
                passColor = lerp(backColor.rgb, Difference(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Exclusion
            case 11:
                passColor = lerp(backColor.rgb, Exclusion(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Hue
            case 12:
                passColor = lerp(backColor.rgb, Hue(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Saturation
            case 13:
                passColor = lerp(backColor.rgb, Saturation(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Color
            case 14:
                passColor = lerp(backColor.rgb, ColorB(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Luminosity
            case 15:
                passColor = lerp(backColor.rgb, Luminosity(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Linear Dodge
            case 16:
                passColor = lerp(backColor.rgb, LinearDodge(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Linear Burn
            case 17:
                passColor = lerp(backColor.rgb, LinearBurn(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Vivid Light
            case 18:
                passColor = lerp(backColor.rgb, VividLight(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Linear Light
            case 19:
                passColor = lerp(backColor.rgb, LinearLight(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Pin Light
            case 20:
                passColor = lerp(backColor.rgb, PinLight(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Hard Mix
            case 21:
                passColor = lerp(backColor.rgb, HardMix(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Reflect
            case 22:
                passColor = lerp(backColor.rgb, Reflect(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Glow
            case 23:
                passColor = lerp(backColor.rgb, Glow(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Grain Merge
            case 24:
                passColor = lerp(backColor.rgb, GrainMerge(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Grain Extract
            case 25:
                passColor = lerp(backColor.rgb, GrainExtract(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Addition
            case 26:
                passColor = lerp(backColor.rgb, Addition(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Subtract
            case 27:
                passColor = lerp(backColor.rgb, Subtract(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
            // Divide
            case 28:
                passColor = lerp(backColor.rgb, Divide(backColor.rgb, passColor.rgb), passColor.a * Stage3_Opacity);
                break;
        }
    }
}

technique StageDepth3
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_StageDepth3;
    }
}