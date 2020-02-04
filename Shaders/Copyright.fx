/*------------------.
| :: Description :: |
'-------------------/

    Copyright based on Layer (version 0.5)

    Authors: CeeJay.dk, seri14, Marot Satil, Uchu Suzume
    License: MIT

    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
    
    Version 0.2 by seri14 & Marot Satil
    * Added the ability to scale and move the layer around on an x, y axis.
    
    Version 0.3
    * Added a number of copyright textures for Phantasty Star Online 2 created by Uchu Suzume.

    Version 0.4 by seri14 & Marot Satil
    * Added support for the additional seri14 DLL preprocessor options to minimize loaded textures.

    Version 0.5 by Uchu Suzume & Marot Satil
    * Rotation added.
*/

#include "ReShade.fxh"

uniform int cLayer_Select <
    ui_label = "Layer Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "FFXIV\0"
              "FFXIV Nalukai\0"
              "FFXIV Yomi Black\0"
              "FFXIV Yomi White\0"
              "PSO2\0"
              "PSO2 with GShade Black\0"
              "PSO2 with GShade White\0"
              "PSO2 with GShade\0"
              "PSO2 Eurostyle Left\0"
              "PSO2 Eurostyle Right\0"
              "PSO2 Futura Center\0"
              "PSO2 Futura Tri Black\0"
              "PSO2 Futura Tri White\0"
              "PSO2 Rockwell Nova Black\0"
              "PSO2 Rockwell Nova White\0"
              "PSO2 Swis721 Square Black\0"
              "PSO2 Swis721 Square White\0"
              "PSO2 Swiss911\0";
    // Bind to the effect-scoped preprocessor definitions
    ui_bind = "CopyrightTexture_Source";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef CopyrightTexture_Source
#define CopyrightTexture_Source 0
#endif

uniform float cLayer_Blend <
    ui_label = "Opacity";
    ui_tooltip = "The transparency of the copyright notice.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float cLayer_Scale <
    ui_type = "slider";
    ui_label = "Scale";
    ui_min = 0.01; ui_max = 3.0;
    ui_step = 0.001;
> = 1.001;

uniform float cLayer_PosX <
    ui_type = "slider";
    ui_label = "Position X";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
> = 0.5;

uniform float cLayer_PosY <
    ui_type = "slider";
    ui_label = "Position Y";
    ui_min = 0.0; ui_max = 1.0;
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
#elif CopyrightTexture_Source == 4 // PSO2
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2.png"
#define _SOURCE_COPYRIGHT_SIZE 435.0, 31.0
#elif CopyrightTexture_Source == 5 // PSO2 with GShade Black
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_by_gshade.png"
#define _SOURCE_COPYRIGHT_SIZE 1280.0, 66.0
#elif CopyrightTexture_Source == 6 // PSO2 with GShade White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_by_gshade_w.png"
#define _SOURCE_COPYRIGHT_SIZE 1280.0, 66.0
#elif CopyrightTexture_Source == 7 // PSO2 with GShade
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_by_GShade_r.png"
#define _SOURCE_COPYRIGHT_SIZE 300.0, 128.0
#elif CopyrightTexture_Source == 8 // PSO2 Eurostyle Left
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Eurostyle_left.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 183.0
#elif CopyrightTexture_Source == 9 // PSO2 Eurostyle Right
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Eurostyle_right.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 183.0
#elif CopyrightTexture_Source == 10 // PSO2 Futura Center
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_center.png"
#define _SOURCE_COPYRIGHT_SIZE 535.0, 134.0
#elif CopyrightTexture_Source == 11 // PSO2 Futura Tri Black
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_tri_b.png"
#define _SOURCE_COPYRIGHT_SIZE 319.0, 432.0
#elif CopyrightTexture_Source == 12 // PSO2 Futura Tri White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_tri_w.png"
#define _SOURCE_COPYRIGHT_SIZE 319.0, 432.0
#elif CopyrightTexture_Source == 13 // PSO2 Rockwell Nova Black
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Rockwell_nova_b.png"
#define _SOURCE_COPYRIGHT_SIZE 471.0, 122.0
#elif CopyrightTexture_Source == 14 // PSO2 Rockwell Nova White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Rockwell_nova_w.png"
#define _SOURCE_COPYRIGHT_SIZE 471.0, 122.0
#elif CopyrightTexture_Source == 15 // PSO2 Swis721 Square Black
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Swis721_square_b.png"
#define _SOURCE_COPYRIGHT_SIZE 261.0, 285.0
#elif CopyrightTexture_Source == 16 // PSO2 Swis721 Square White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Swis721_square_w.png"
#define _SOURCE_COPYRIGHT_SIZE 261.0, 285.0
#elif CopyrightTexture_Source == 17 // PSO2 Swiss911
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_Swiss911_UCm_BT_Cn.png"
#define _SOURCE_COPYRIGHT_SIZE 540.0, 54.0
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

void PS_cLayer(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
    const float3 pivot = float3(0.5, 0.5, 0.0);
    const float AspectX = (1.0 - BUFFER_WIDTH * (1.0 / BUFFER_HEIGHT));
    const float AspectY = (1.0 - BUFFER_HEIGHT * (1.0 / BUFFER_WIDTH));
    const float3 mulUV = float3(texCoord.x, texCoord.y, 1);
    const float2 ScaleSize = (float2(_SOURCE_COPYRIGHT_SIZE) / BUFFER_SCREEN_SIZE) * cLayer_Scale;
    const float ScaleX =  ScaleSize.x * AspectX;
    const float ScaleY =  ScaleSize.y * AspectY;
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
    passColor = lerp(backColor, passColor, passColor.a * cLayer_Blend);
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