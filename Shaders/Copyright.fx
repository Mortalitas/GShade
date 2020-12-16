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

    Version 0.8 by Uchu Suzume & Marot Satil
    * Sorted blending modes in a more logical fashion, grouping by type.
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
    ui_label = "Copyright Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "FFXIV\0"
              "FFXIV Nalukai\0"
              "FFXIV Yomi Black\0"
              "FFXIV Yomi White\0"
              "FFXIV With GShade Dark\0"
              "FFXIV With GShade White\0"
              "PSO2\0"
              "PSO2 Century\0"
              "PSO2 Schoolbell\0"
              "PSO2 Helvetica Condensed\0"
              "PSO2 with GShade Dark\0"
              "PSO2 with GShade White\0"
              "PSO2 Montserrat\0"
              "PSO2 Montserrat Simple\0"
              "PSO2 With Flat Logo\0"
              "PSO2 Eurostile\0"
              "PSO2 Metro No. 2 Cutout\0"
              "PSO2 Kranky\0"
              "PSO2 GN Fuyu-iro Script\0"
              "PSO2 Sacramento\0"
              "PSO2 Century Rectangle\0"
              "PSO2 Eurostile Left\0"
              "PSO2 Eurostile Right\0"
              "PSO2 Eurostile Center\0"
              "PSO2 Futura Center\0"
              "PSO2 Neuzeit Grotesk\0"
              "PSO2 Krona One\0"
              "PSO2 Mouse Memories\0"
              "PSO2 Swanky And Moo Moo\0"
              "PSO2 Staccato555 A\0"
              "PSO2 Staccato555 B\0"
              "PSO2 PSO2 Lato Cutout\0"
              "PSO2 Rockwell Nova\0"
              "PSO2 Kabel Heavy\0"
              "PSO2 Poiret One Small\0"
              "PSO2 Poiret One Large\0"
              "PSO2 Kranky Large\0"
              "PSO2 Futura Triangle\0"
              "PSO2 Helvetica Square\0"
              "PSO2 Righteous\0"
              "PSO2 Poppins\0"
              "PSO2 Flat Logo\0"
              "PSO2 Yanone Kaffeesatz A\0"
              "PSO2 Yanone Kaffeesatz B\0"
              "PSO2 Yanone Kaffeesatz C\0"
              "Custom\0";
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
               "Darken\0"
               "Multiply\0"
               "Color Burn\0"
               "Linear Burn\0"
               "Lighten\0"
               "Screen\0"
               "Color Dodge\0"
               "Linear Dodge\0"
               "Addition\0"
               "Glow\0"
               "Overlay\0"
               "Soft Light\0"
               "Hard Light\0"
               "Vivid Light\0"
               "Linear Light\0"
               "Pin Light\0"
               "Hard Mix\0"
               "Difference\0"
               "Exclusion\0"
               "Subtract\0"
               "Divide\0"
               "Reflect\0"
               "Grain Merge\0"
               "Grain Extract\0"
               "Hue\0"
               "Saturation\0"
               "Color\0"
               "Luminosity\0";
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
#define _SOURCE_COPYRIGHT_SIZE 1363.0, 68.0
#elif CopyrightTexture_Source == 1 // FFXIV Nalukai
#define _SOURCE_COPYRIGHT_FILE "CopyrightF4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1162.0, 135.0
#elif CopyrightTexture_Source == 2 // FFXIV Yomi Black
#define _SOURCE_COPYRIGHT_FILE "CopyrightYBlH.png"
#define _SOURCE_COPYRIGHT_SIZE 1162.0, 135.0
#elif CopyrightTexture_Source == 3 // FFXIV Yomi White
#define _SOURCE_COPYRIGHT_FILE "CopyrightYWhH.png"
#define _SOURCE_COPYRIGHT_SIZE 1162.0, 135.0
#elif CopyrightTexture_Source == 4 // FFXIV With GShade Dark
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_w_gshade_dark.png"
#define _SOURCE_COPYRIGHT_SIZE 1300.0, 70.0
#elif CopyrightTexture_Source == 5 // FFXIV With GShade White
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_w_gshade_white.png"
#define _SOURCE_COPYRIGHT_SIZE 1300.0, 70.0
#elif CopyrightTexture_Source == 6 // PSO2
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2.png"
#define _SOURCE_COPYRIGHT_SIZE 435.0, 31.0
#elif CopyrightTexture_Source == 7 // PSO2 Century
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_century.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 40.0
#elif CopyrightTexture_Source == 8 // PSO2 Schoolbell
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_schoolbell.png"
#define _SOURCE_COPYRIGHT_SIZE 435.0, 31.0
#elif CopyrightTexture_Source == 9 // PSO2 Helvetica Condensed
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_helvetica_condenced.png"
#define _SOURCE_COPYRIGHT_SIZE 540.0, 54.0
#elif CopyrightTexture_Source == 10 // PSO2 With GShade Dark
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_w_gshade_dark.png"
#define _SOURCE_COPYRIGHT_SIZE 1092.0, 66.0
#elif CopyrightTexture_Source == 11 // PSO2 With GShade White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_w_gshade_white.png"
#define _SOURCE_COPYRIGHT_SIZE 1092.0, 66.0
#elif CopyrightTexture_Source == 12 // PSO2 Montserrat
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_montserrat.png"
#define _SOURCE_COPYRIGHT_SIZE 880.0, 90.0
#elif CopyrightTexture_Source == 13 // PSO2 Montserrat Simple
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_montserrat_simple.png"
#define _SOURCE_COPYRIGHT_SIZE 1030.0, 90.0
#elif CopyrightTexture_Source == 14 // PSO2 With Flat Logo
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_w_flat_logo.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 70.0
#elif CopyrightTexture_Source == 15 // PSO2 Eurostile
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 120.0
#elif CopyrightTexture_Source == 16 // PSO2 Metro No. 2 Cutout
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_metro_no2_cutout.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 100.0
#elif CopyrightTexture_Source == 17 // PSO2 Kranky
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_kranky.png"
#define _SOURCE_COPYRIGHT_SIZE 1280.0, 120.0
#elif CopyrightTexture_Source == 18 // PSO2 GN Fuyu-iro Script
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_gn-fuyu-iro_script.png"
#define _SOURCE_COPYRIGHT_SIZE 820.0, 160.0
#elif CopyrightTexture_Source == 19 // PSO2 Sacramento
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sacramento.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 150.0
#elif CopyrightTexture_Source == 20 // PSO2 Century Rectangle
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_century_rectangle.png"
#define _SOURCE_COPYRIGHT_SIZE 580.0, 150.0
#elif CopyrightTexture_Source == 21 // PSO2 Eurostile Left
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile_left.png"
#define _SOURCE_COPYRIGHT_SIZE 960.0, 216.0
#elif CopyrightTexture_Source == 22 // PSO2 Eurostile Right
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile_right.png"
#define _SOURCE_COPYRIGHT_SIZE 960.0, 216.0
#elif CopyrightTexture_Source == 23 // PSO2 Eurostile Center
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile_center.png"
#define _SOURCE_COPYRIGHT_SIZE 960.0, 216.0
#elif CopyrightTexture_Source == 24 // PSO2 Futura Center
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_center.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 190.0
#elif CopyrightTexture_Source == 25 // PSO2 Neuzeit Grotesk
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_neuzeit_grotesk.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 350.0
#elif CopyrightTexture_Source == 26 // PSO2 Krona One
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_krona_one.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 300.0
#elif CopyrightTexture_Source == 27 // PSO2 Mouse Memories
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_mouse_memories.png"
#define _SOURCE_COPYRIGHT_SIZE 660.0, 240.0
#elif CopyrightTexture_Source == 28 // PSO2 Swanky And Moo Moo
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_swanky_and_moo_moo.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 150.0
#elif CopyrightTexture_Source == 29 // PSO2 Staccato555 A
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_staccato555_a.png"
#define _SOURCE_COPYRIGHT_SIZE 820.0, 350.0
#elif CopyrightTexture_Source == 30 // PSO2 Staccato555 B
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_staccato555_b.png"
#define _SOURCE_COPYRIGHT_SIZE 870.0, 320.0
#elif CopyrightTexture_Source == 31 // PSO2 Lato Cutout
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_lato_cutout.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 180.0
#elif CopyrightTexture_Source == 32 // PSO2 Rockwell Nova
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_rockwell_nova.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 130.0
#elif CopyrightTexture_Source == 33 // PSO2 Kabel Heavy
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_kabel_heavy.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 240.0
#elif CopyrightTexture_Source == 34 // PSO2 Poiret One Small
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_poiret_one_s.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 210.0
#elif CopyrightTexture_Source == 35 // PSO2 Poiret One Large
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_poiret_one_l.png"
#define _SOURCE_COPYRIGHT_SIZE 1440.0, 500.0
#elif CopyrightTexture_Source == 36 // PSO2 Kranky Large
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_kranky_l.png"
#define _SOURCE_COPYRIGHT_SIZE 830.0, 340.0
#elif CopyrightTexture_Source == 37 // PSO2 Futura Triangle
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_tri.png"
#define _SOURCE_COPYRIGHT_SIZE 329.0, 432.0
#elif CopyrightTexture_Source == 38 // PSO2 Helvetica Square
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_helvetica_square.png"
#define _SOURCE_COPYRIGHT_SIZE 360.0, 400.0
#elif CopyrightTexture_Source == 39 // PSO2 Righteous
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_righteous.png"
#define _SOURCE_COPYRIGHT_SIZE 550.0, 300.0
#elif CopyrightTexture_Source == 40 // PSO2 Poppins
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_poppins.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 200.0
#elif CopyrightTexture_Source == 41 // PSO2 Bank Gothic
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_bank_gothic.png"
#define _SOURCE_COPYRIGHT_SIZE 650.0, 300.0
#elif CopyrightTexture_Source == 42 // PSO2 Flat Logo
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_flat_logo.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 400.0
#elif CopyrightTexture_Source == 43 // PSO2 Yanone Kaffeesatz A
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_yanone_kaffeesatz_a.png"
#define _SOURCE_COPYRIGHT_SIZE 300.0, 300.0
#elif CopyrightTexture_Source == 44 // PSO2 Yanone Kaffeesatz B
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_yanone_kaffeesatz_b.png"
#define _SOURCE_COPYRIGHT_SIZE 300.0, 300.0
#elif CopyrightTexture_Source == 45 // Custom
#define _SOURCE_COPYRIGHT_FILE cLayerTex
#define _SOURCE_COPYRIGHT_SIZE cLayer_SIZE_X, cLayer_SIZE_Y
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
        // Darken
        case 1:
            passColor = lerp(backColor.rgb, Darken(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Multiply
        case 2:
            passColor = lerp(backColor.rgb, Multiply(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Color Burn
        case 3:
            passColor = lerp(backColor.rgb, ColorBurn(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Linear Burn
        case 4:
            passColor = lerp(backColor.rgb, LinearBurn(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Lighten
        case 5:
            passColor = lerp(backColor.rgb, Lighten(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Screen
        case 6:
            passColor = lerp(backColor.rgb, Screen(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Color Dodge
        case 7:
            passColor = lerp(backColor.rgb, ColorDodge(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Linear Dodge
        case 8:
            passColor = lerp(backColor.rgb, LinearDodge(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Addition
        case 9:
            passColor = lerp(backColor.rgb, Addition(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Glow
        case 10:
            passColor = lerp(backColor.rgb, Glow(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Overlay
        case 11:
            passColor = lerp(backColor.rgb, Overlay(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Soft Light
        case 12:
            passColor = lerp(backColor.rgb, SoftLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Hard Light
        case 13:
            passColor = lerp(backColor.rgb, HardLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Vivid Light
        case 14:
            passColor = lerp(backColor.rgb, VividLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Linear Light
        case 15:
            passColor = lerp(backColor.rgb, LinearLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Pin Light
        case 16:
            passColor = lerp(backColor.rgb, PinLight(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Hard Mix
        case 17:
            passColor = lerp(backColor.rgb, HardMix(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Difference
        case 18:
            passColor = lerp(backColor.rgb, Difference(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Exclusion
        case 19:
            passColor = lerp(backColor.rgb, Exclusion(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Subtract
        case 20:
            passColor = lerp(backColor.rgb, Subtract(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Divide
        case 21:
            passColor = lerp(backColor.rgb, Divide(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Reflect
        case 22:
            passColor = lerp(backColor.rgb, Reflect(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Grain Merge
        case 23:
            passColor = lerp(backColor.rgb, GrainMerge(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Grain Extract
        case 24:
            passColor = lerp(backColor.rgb, GrainExtract(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Hue
        case 25:
            passColor = lerp(backColor.rgb, Hue(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Saturation
        case 26:
            passColor = lerp(backColor.rgb, Saturation(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Color
        case 27:
            passColor = lerp(backColor.rgb, ColorB(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
            break;
        // Luminosity
        case 28:
            passColor = lerp(backColor.rgb, Luminosity(backColor.rgb, passColor.rgb), passColor.a * cLayer_Blend);
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
