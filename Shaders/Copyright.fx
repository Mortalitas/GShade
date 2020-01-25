/*------------------.
| :: Description :: |
'-------------------/

    Copyright based on Layer (version 0.3)

    Authors: CeeJay.dk, seri14, Marot Satil
    License: MIT

    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
    
    Version 0.2 by seri14 & Marot Satil
    * Added the ability to scale and move the layer around on an x, y axis.
    
    Version 0.3
    * Added a number of copyright textures for Phantasty Star Online 2 created by Uchu Suzume.

    Version 0.4
    * Implemented seri14 DLL's preprocessor menu options to minimize loaded textures.
*/

#include "ReShade.fxh"

uniform int cLayer_Select <
    ui_label = "Layer Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "FFXIV Horizontal\0"
              "FFXIV Vertical\0"
              "FFXIV Nalukai Horizontal\0"
              "FFXIV Yomi Black Horizontal\0"
              "FFXIV Yomi White Horizontal\0"
              "PSO2 Horizontal\0"
              "PSO2 Vertical\0"
              "PSO2 with GShade Black Horizontal\0"
              "PSO2 with GShade Black Vertical\0"
              "PSO2 with GShade White Horizontal\0"
              "PSO2 with GShade White Vertical\0"
              "PSO2 with GShade Horizontal\0"
              "PSO2 Eurostyle Left Horizontal\0"
              "PSO2 Eurostyle Left Vertical\0"
              "PSO2 Eurostyle Right Horizontal\0"
              "PSO2 Eurostyle Right Vertical\0"
              "PSO2 Futura Center Horizontal\0"
              "PSO2 Futura Center Vertical\0"
              "PSO2 Futura Tri Black Horizontal\0"
              "PSO2 Futura Tri Black Vertical\0"
              "PSO2 Futura Tri White Horizontal\0"
              "PSO2 Futura Tri White Vertical\0"
              "PSO2 Rockwell Nova Black Horizontal\0"
              "PSO2 Rockwell Nova Black Vertical\0"
              "PSO2 Rockwell Nova White Horizontal\0"
              "PSO2 Rockwell Nova White Vertical\0"
              "PSO2 Swis721 Square Black Horizontal\0"
              "PSO2 Swis721 Square Black Vertical\0"
              "PSO2 Swis721 Square White Horizontal\0"
              "PSO2 Swis721 Square White Vertical\0"
              "PSO2 Swiss911 Horizontal\0"
              "PSO2 Swiss911 Vertical\0";
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

#if   CopyrightTexture_Source == 0 // FFXIV Horizontal Vanilla
#define _SOURCE_FILE "Copyright4kH.png"
#define _SOURCE_SIZE 411.0, 22.0
#elif CopyrightTexture_Source == 1 // FFXIV Vertical Vanilla
#define _SOURCE_FILE "Copyright4kV.png"
#define _SOURCE_SIZE 22.0, 412.0
#elif CopyrightTexture_Source == 2 // FFXIV Nalukai Horizontal
#define _SOURCE_FILE "CopyrightF4kH.png"
#define _SOURCE_SIZE 1162.0, 135.0
#elif CopyrightTexture_Source == 3 // FFXIV Yomi Black Horizontal
#define _SOURCE_FILE "CopyrightYBlH.png"
#define _SOURCE_SIZE 1162.0, 135.0
#elif CopyrightTexture_Source == 4 // FFXIV Yomi White Horizontal
#define _SOURCE_FILE "CopyrightYWhH.png"
#define _SOURCE_SIZE 1162.0, 135.0
#elif CopyrightTexture_Source == 5 // PSO2 Horizontal
#define _SOURCE_FILE "copyright_pso2.png"
#define _SOURCE_SIZE 435.0, 31.0
#elif CopyrightTexture_Source == 6 // PSO2 Vertical
#define _SOURCE_FILE "copyright_pso2_v.png"
#define _SOURCE_SIZE 31.0, 435.0
#elif CopyrightTexture_Source == 7 // PSO2 with GShade Black Horizontal
#define _SOURCE_FILE "copyright_pso2_by_gshade.png"
#define _SOURCE_SIZE 1280.0, 66.0
#elif CopyrightTexture_Source == 8 // PSO2 with GShade Black Vertical
#define _SOURCE_FILE "copyright_pso2_by_gshade_v.png"
#define _SOURCE_SIZE 66.0, 1280.0
#elif CopyrightTexture_Source == 9 // PSO2 with GShade White Horizontal
#define _SOURCE_FILE "copyright_pso2_by_gshade_w.png"
#define _SOURCE_SIZE 1280.0, 66.0
#elif CopyrightTexture_Source == 10 // PSO2 with GShade White Vertical
#define _SOURCE_FILE "copyright_pso2_by_gshade_w_v.png"
#define _SOURCE_SIZE 66.0, 1280.0
#elif CopyrightTexture_Source == 11 // PSO2 with GShade
#define _SOURCE_FILE "copyright_pso2_by_GShade_r.png"
#define _SOURCE_SIZE 300.0, 128.0
#elif CopyrightTexture_Source == 12 // PSO2 Eurostyle Left Horizontal
#define _SOURCE_FILE "copyright_pso2_Eurostyle_left.png"
#define _SOURCE_SIZE 800.0, 183.0
#elif CopyrightTexture_Source == 13 // PSO2 Eurostyle Left Vertical
#define _SOURCE_FILE "copyright_pso2_Eurostyle_left_v.png"
#define _SOURCE_SIZE 183.0, 800.0
#elif CopyrightTexture_Source == 14 // PSO2 Eurostyle Right Horizontal
#define _SOURCE_FILE "copyright_pso2_Eurostyle_right.png"
#define _SOURCE_SIZE 800.0, 183.0
#elif CopyrightTexture_Source == 15 // PSO2 Eurostyle Right Vertical
#define _SOURCE_FILE "copyright_pso2_Eurostyle_right_v.png"
#define _SOURCE_SIZE 183.0, 800.0
#elif CopyrightTexture_Source == 16 // PSO2 Futura Center Horizontal
#define _SOURCE_FILE "copyright_pso2_futura_center.png"
#define _SOURCE_SIZE 535.0, 134.0
#elif CopyrightTexture_Source == 17 // PSO2 Futura Center Vertical
#define _SOURCE_FILE "copyright_pso2_futura_center_v.png"
#define _SOURCE_SIZE 134.0, 535.0
#elif CopyrightTexture_Source == 18 // PSO2 Futura Tri Black Horizontal
#define _SOURCE_FILE "copyright_pso2_futura_tri_b.png"
#define _SOURCE_SIZE 319.0, 432.0
#elif CopyrightTexture_Source == 19 // PSO2 Futura Tri Black Vertical
#define _SOURCE_FILE "copyright_pso2_futura_tri_b_v.png"
#define _SOURCE_SIZE 432.0, 319.0
#elif CopyrightTexture_Source == 20 // PSO2 Futura Tri White Horizontal
#define _SOURCE_FILE "copyright_pso2_futura_tri_w.png"
#define _SOURCE_SIZE 319.0, 432.0
#elif CopyrightTexture_Source == 21 // PSO2 Futura Tri White Vertical
#define _SOURCE_FILE "copyright_pso2_futura_tri_w_v.png"
#define _SOURCE_SIZE 432.0, 319.0
#elif CopyrightTexture_Source == 22 // PSO2 Rockwell Nova Black Horizontal
#define _SOURCE_FILE "copyright_pso2_Rockwell_nova_b.png"
#define _SOURCE_SIZE 471.0, 122.0
#elif CopyrightTexture_Source == 23 // PSO2 Rockwell Nova Black Vertical
#define _SOURCE_FILE "copyright_pso2_Rockwell_nova_b_v.png"
#define _SOURCE_SIZE 122.0, 471.0
#elif CopyrightTexture_Source == 24 // PSO2 Rockwell Nova White Horizontal
#define _SOURCE_FILE "copyright_pso2_Rockwell_nova_w.png"
#define _SOURCE_SIZE 471.0, 122.0
#elif CopyrightTexture_Source == 25 // PSO2 Rockwell Nova White Vertical
#define _SOURCE_FILE "copyright_pso2_Rockwell_nova_w_v.png"
#define _SOURCE_SIZE 122.0, 471.0
#elif CopyrightTexture_Source == 26 // PSO2 Swis721 Square Black Horizontal
#define _SOURCE_FILE "copyright_pso2_Swis721_square_b.png"
#define _SOURCE_SIZE 261.0, 285.0
#elif CopyrightTexture_Source == 27 // PSO2 Swis721 Square Black Vertical
#define _SOURCE_FILE "copyright_pso2_Swis721_square_b_v.png"
#define _SOURCE_SIZE 285.0, 261.0
#elif CopyrightTexture_Source == 28 // PSO2 Swis721 Square White Horizontal
#define _SOURCE_FILE "copyright_pso2_Swis721_square_w.png"
#define _SOURCE_SIZE 261.0, 285.0
#elif CopyrightTexture_Source == 29 // PSO2 Swis721 Square White Vertical
#define _SOURCE_FILE "copyright_pso2_Swis721_square_w_v.png"
#define _SOURCE_SIZE 285.0, 261.0
#elif CopyrightTexture_Source == 30 // PSO2 Swiss911 Horizontal
#define _SOURCE_FILE "copyright_pso2_Swiss911_UCm_BT_Cn.png"
#define _SOURCE_SIZE 540.0, 54.0
#elif CopyrightTexture_Source == 31 // PSO2 Swiss911 Vertical
#define _SOURCE_FILE "copyright_pso2_Swiss911_UCm_BT_Cn_v.png"
#define _SOURCE_SIZE 54.0, 540.0
#endif

texture Copyright_Texture <
    source = _SOURCE_FILE;
> {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
};
sampler CopyrightSampler { 
    Texture = Copyright_Texture;
};

// -------------------------------------
// Entrypoints
// -------------------------------------

#define scale(_) (_ / (float2(_SOURCE_SIZE) / BUFFER_SCREEN_SIZE * cLayer_Scale))

void PS_cLayer(in float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
    const float4 back = tex2D(ReShade::BackBuffer, texcoord);
    color = tex2D(CopyrightSampler, scale(texcoord) + (1.0 - scale(1.0)) * float2(cLayer_PosX, cLayer_PosY));
    color = lerp(back, color, color.a * cLayer_Blend);
    color.a = back.a;
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