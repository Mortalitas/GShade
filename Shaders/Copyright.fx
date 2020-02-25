/*------------------.
| :: Description :: |
'-------------------/

    Copyright (based on Layer) (version 0.7)

    Authors: CeeJay.dk, seri14, Marot Satil, Uchu Suzume, prod80, originalnicodr
    License: MIT

    About:
    Blends an image with the game.
    The idea is to give users with graphics skills the ability to create effects using a layer just like in an image editor.
    Maybe they could use this to create custom CRT effects, custom vignettes, logos, custom hud elements, toggable help screens and crafting tables or something I haven't thought of.

    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
    
    Version 0.2 by seri14 & Marot Satil
    * Added the ability to scale and move the layer around on an x, y axis.

    Version 0.3 by seri14
    * Reduced the problem of layer color is blending with border color

    Version 0.4 by seri14 & Marot Satil
    * Added support for the additional seri14 DLL preprocessor options to minimize loaded textures.

    Version 0.5 by Uchu Suzume & Marot Satil
    * Rotation added.

    Version 0.6 by Uchu Suzume & Marot Satil
    * Added multiple blending modes thanks to the work of Uchu Suzume, prod80, and originalnicodr.

    Version 0.7 by Uchu Suzume & Marot Satil
    * Added Addition, Subtract, Divide blending modes.
*/

#include "ReShade.fxh"

#ifndef cLayerTex
#define cLayerTex "cLayerA.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif
#ifndef cLayer_SIZE_X
#define cLayer_SIZE_X BUFFER_WIDTH
#endif
#ifndef cLayer_SIZE_Y
#define cLayer_SIZE_Y BUFFER_HEIGHT
#endif

#if cLayer_SINGLECHANNEL
#define TEXFORMAT R8
#else
#define TEXFORMAT RGBA8
#endif

uniform int cLayer_Select <
    ui_label = "cLayer Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "FFXIV\0"
              "FFXIV Nalukai\0"
              "FFXIV Yomi Black\0"
              "FFXIV Yomi White\0"
              "FFXIV with GShade Black\0"
              "PSO2\0"
              "PSO2 with GShade Black\0"
              "PSO2 with GShade White\0"
              "PSO2 with GShade\0"
              "PSO2 Eurostyle Left\0"
              "PSO2 Eurostyle Right\0"
              "PSO2 Futura Center\0"
              "PSO2 Futura Tri White\0"
              "PSO2 Rockwell Nova White\0"
              "PSO2 Swis721 Square White\0"
              "PSO2 Swiss911\0";
    ui_bind = "CopyrightTexture_Source";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef cLayerTexture_Source
#define cLayerTexture_Source 0
#endif

uniform int cLayer_BlendMode <
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

uniform float cLayer_Blend <
    ui_label = "Blending Amount";
    ui_tooltip = "The amount of blending applied to the copyright layer.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float cLayer_Scale <
  ui_type = "slider";
    ui_label = "Scale X & Y";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.001;

uniform float cLayer_ScaleX <
  ui_type = "slider";
    ui_label = "Scale X";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float cLayer_ScaleY <
  ui_type = "slider";
    ui_label = "Scale Y";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform float cLayer_PosX <
  ui_type = "slider";
    ui_label = "Position X";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform float cLayer_PosY <
  ui_type = "slider";
    ui_label = "Position Y";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform int cLayer_SnapRotate <
    ui_type = "combo";
    ui_label = "Snap Rotation";
    ui_items = "None\0"
               "90 Degrees\0"
               "-90 Degrees\0"
               "180 Degrees\0"
               "-180 Degrees\0";
    ui_tooltip = "Snap rotation to a specific angle.";
> = false;

uniform float cLayer_Rotate <
    ui_label = "Rotate";
    ui_type = "slider";
    ui_min = -180.0;
    ui_max = 180.0;
    ui_step = 0.01;
> = 0;


#if   CopyrightTexture_Source == 0 // FFXIV Vanilla
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 411.0, 22.0
#elif CopyrightTexture_Source == 1 // FFXIV Nalukai
#define _SOURCE_COPYRIGHT_FILE "CopyrightF4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1162.0, 135.0
#elif CopyrightTexture_Source == 2 // FFXIV Yomi Black
#define _SOURCE_COPYRIGHT_FILE "CopyrightYBlH.png"
#define _SOURCE_COPYRIGHT_SIZE 1162.0, 135.0
#elif CopyrightTexture_Source == 3 // FFXIV Yomi White
#define _SOURCE_COPYRIGHT_FILE "CopyrightYWhH.png"
#define _SOURCE_COPYRIGHT_SIZE 1162.0, 135.0
#elif CopyrightTexture_Source == 4 // FFXIV with GShade Black
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_by_gshade.png"
#define _SOURCE_COPYRIGHT_SIZE 1300.0, 66.0
#elif CopyrightTexture_Source == 5 // PSO2
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2.png"
#define _SOURCE_COPYRIGHT_SIZE 435.0, 31.0
#elif CopyrightTexture_Source == 6 // PSO2 with GShade Black
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_by_gshade.png"
#define _SOURCE_COPYRIGHT_SIZE 1092.0, 66.0
#elif CopyrightTexture_Source == 7 // PSO2 with GShade White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_by_gshade_w.png"
#define _SOURCE_COPYRIGHT_SIZE 1092.0, 66.0
#elif CopyrightTexture_Source == 8 // PSO2 with GShade
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_by_GShade_r.png"
#define _SOURCE_COPYRIGHT_SIZE 375.0, 150.0
#elif CopyrightTexture_Source == 9 // PSO2 Eurostyle Left
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Eurostyle_left.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 183.0
#elif CopyrightTexture_Source == 10 // PSO2 Eurostyle Right
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Eurostyle_right.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 183.0
#elif CopyrightTexture_Source == 11 // PSO2 Futura Center
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_center.png"
#define _SOURCE_COPYRIGHT_SIZE 535.0, 134.0
#elif CopyrightTexture_Source == 12 // PSO2 Futura Tri White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_tri_w.png"
#define _SOURCE_COPYRIGHT_SIZE 319.0, 432.0
#elif CopyrightTexture_Source == 13 // PSO2 Rockwell Nova White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Rockwell_nova_w.png"
#define _SOURCE_COPYRIGHT_SIZE 471.0, 122.0
#elif CopyrightTexture_Source == 14 // PSO2 Swis721 Square White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Swis721_square_w.png"
#define _SOURCE_COPYRIGHT_SIZE 261.0, 285.0
#elif CopyrightTexture_Source == 15 // PSO2 Swiss911
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Swiss911_UCm_BT_Cn.png"
#endif

texture Copyright_Texture <
    source = _SOURCE_COPYRIGHT_FILE;
> {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
};
sampler Copyright_Sampler { 
    Texture = Copyright_Texture;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

// -------------------------------------
// Entrypoints
// -------------------------------------

#include "ReShade.fxh"
#include "Blending.fxh"

void PS_cLayer(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
    const float3 pivot = float3(0.5, 0.5, 0.0);
    const float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT));
    const float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH));
    const float3 mulUV = float3(texCoord.x, texCoord.y, 1);
    const float2 ScaleSize = (float2(_SOURCE_COPYRIGHT_SIZE) * cLayer_Scale / BUFFER_SCREEN_SIZE);
    const float ScaleX =  ScaleSize.x * AspectX * cLayer_ScaleX;
    const float ScaleY =  ScaleSize.y * AspectY * cLayer_ScaleY;
    float Rotate = cLayer_Rotate * (3.1415926 / 180.0);

    switch(cLayer_SnapRotate)
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
        -cLayer_PosX, -cLayer_PosY, 1
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
    passColor = tex2D(Copyright_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));

    switch (cLayer_BlendMode)
    {
        // Normal
        default:
            passColor = lerp(backColor.rgb, passColor.rgb, passColor.a * cLayer_Blend);
            break;
        // Multiply
        case 1:
            passColor = lerp(backColor.rgb, Multiply(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Screen
        case 2:
            passColor = lerp(backColor.rgb, Screen(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Overlay
        case 3:
            passColor = lerp(backColor.rgb, Overlay(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Darken
        case 4:
            passColor = lerp(backColor.rgb, Darken(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Lighten
        case 5:
            passColor = lerp(backColor.rgb, Lighten(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // ColorDodge
        case 6:
            passColor = lerp(backColor.rgb, ColorDodge(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // ColorBurn
        case 7:
            passColor = lerp(backColor.rgb, ColorBurn(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // HardLight
        case 8:
            passColor = lerp(backColor.rgb, HardLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // SoftLight
        case 9:
            passColor = lerp(backColor.rgb, SoftLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Difference
        case 10:
            passColor = lerp(backColor.rgb, Difference(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Exclusion
        case 11:
            passColor = lerp(backColor.rgb, Exclusion(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Hue
        case 12:
            passColor = lerp(backColor.rgb, Hue(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Saturation
        case 13:
            passColor = lerp(backColor.rgb, Saturation(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Color
        case 14:
            passColor = lerp(backColor.rgb, ColorB(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Luminosity
        case 15:
            passColor = lerp(backColor.rgb, Luminosity(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Linear Dodge
        case 16:
            passColor = lerp(backColor.rgb, LinearDodge(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Linear Burn
        case 17:
            passColor = lerp(backColor.rgb, LinearBurn(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Vivid Light
        case 18:
            passColor = lerp(backColor.rgb, VividLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Linear Light
        case 19:
            passColor = lerp(backColor.rgb, LinearLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Pin Light
        case 20:
            passColor = lerp(backColor.rgb, PinLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Hard Mix
        case 21:
            passColor = lerp(backColor.rgb, HardMix(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Reflect
        case 22:
            passColor = lerp(backColor.rgb, Reflect(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Glow
        case 23:
            passColor = lerp(backColor.rgb, Glow(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Grain Merge
        case 24:
            passColor = lerp(backColor.rgb, GrainMerge(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Grain Extract
        case 25:
            passColor = lerp(backColor.rgb, GrainExtract(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Addition
        case 26:
            passColor = lerp(backColor.rgb, Addition(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Subtract
        case 27:
            passColor = lerp(backColor.rgb, Subtract(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Divide
        case 28:
            passColor = lerp(backColor.rgb, Divide(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
    }

    passColor.a = backColor.a;
}

// -------------------------------------
// Techniques
// -------------------------------------

technique Copyright {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_cLayer;
    }
}
