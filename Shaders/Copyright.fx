/*------------------.
| :: Description :: |
'-------------------/

    Copyright (based on Layer) (version 1.1)

    Authors: CeeJay.dk, seri14, Marot Satil, uchu suzume, prod80, originalnicodr
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

    Version 0.5 by uchu suzume & Marot Satil
    * Rotation added.

    Version 0.6 by uchu suzume & Marot Satil
    * Added multiple blending modes thanks to the work of uchu suzume, prod80, and originalnicodr.

    Version 0.7 by uchu suzume & Marot Satil
    * Added Addition, Subtract, Divide blending modes.

    Version 0.8 by uchu suzume & Marot Satil
    * Sorted blending modes in a more logical fashion, grouping by type.

    Version 0.9 by uchu suzume
    * Added some texures.
    * Fixed blend option applying correctly to alpha pixels by changing the order of code blocks.
    * Add space of UI and collapsed some parameters for visibility.
    * Changed the order of parameter in snap rotate.
    * Experimental features added:
         * Coloring textures(invert, any color for white / black pixels).
         * Move texture to mouse position.
         * Merge and blend background pixels into logo texture(Not sure I said it correctly in English).
         * Added layer with Gaussian blur can be used for drop shadows or bloom.
         * Added chromatic aberration layer with gaussian blur.

    Version 1.0 by Marot Satil & uchu suzume
    + Implemented Blending.fxh preprocessor macros.
    
    Version 1.1 by Marot Satil & uchu suzume
    + Implemented game-based *Tex.fxh headers containing preprocessor macros along with supported game auto-detection.
    * Added a gaussian blur radius option that allows you to adjust the applied area.
    * Improved the accuracy of the BG Blend mode option.

    Version 1.2
    * Added scale option to gaussian layer.
    * Added more blending option to CAb layer.
    * Added Custom List.
    + Adjusted default value of CAb to more natural look and usable.
    + Adjusted gaussian blur radius opiton #3 to reduce afterglow.
    + Expanded moving range of Gaussian layer.
    + Improved the formulas of Gaussian and CAb layers to keep the coordinate base even after rotation.
*/

#include "ReShade.fxh"
#include "Blending.fxh"


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

#if TEXTURE_SELECTION == 0
  #if __APPLICATION__ == 0x6f24790f
    #undef TEXTURE_SELECTION
    #define TEXTURE_SELECTION 1
  #elif __APPLICATION__ == 0x31d39829
    #undef TEXTURE_SELECTION
    #define TEXTURE_SELECTION 2
  #else
    #undef TEXTURE_SELECTION
    #define TEXTURE_SELECTION 0
  #endif
#endif

#if TEXTURE_SELECTION == 0
  #warning "No valid game was detected."
  #include "CopyrightTex_XIV.fxh"
#elif TEXTURE_SELECTION == 1
  #include "CopyrightTex_XIV.fxh"
#elif TEXTURE_SELECTION == 2
  #include "CopyrightTex_PSO2.fxh"
#elif TEXTURE_SELECTION == 3
  #include "CopyrightTex_Custom.fxh"
#endif

uniform int cLayer_SelectGame <
    ui_label = "List Select";
    ui_tooltip = "Select a name of a game to show copyright logo for.   ";
    ui_category = "List Selection";
    ui_category_closed = true;
    ui_type = "combo";
    ui_items = "Auto-Select\0"
               "Final Fantasy XIV\0"
               "Phantasy Star Online 2:NGS\0"
               "Custom List\0"
               ;
    ui_bind = "TEXTURE_SELECTION";
> = TEXTURE_SELECTION;

TEXTURE_COMBO(
    cLayer_Select,
    "Copyright Logo Selection",
    "The image/texture you'd like to use.   ",
);

uniform float cLayer_Scale <
    ui_label = "Scale";
    ui_tooltip = "If you need to increase more scale value,    \nyou can use Scale X&Y combined below.   \nExcessive scaling might degrade the texture   \nhowever.";
    ui_type = "slider";
    ui_min = 0.500; ui_max = 1.0;
    ui_step = 0.001;
> = 0.780;

 uniform float cLayer_ScaleX <
    ui_label = "Scale X";    
    ui_category = "ScaleXY";
    ui_category_closed = true;
    ui_type = "slider";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

 uniform float cLayer_ScaleY <
    ui_label = "Scale Y";
    ui_category = "ScaleXY";
    ui_type = "slider";
    ui_min = 0.001; ui_max = 5.0;
    ui_step = 0.001;
> = 1.0;

uniform bool  cLayer_Mouse <
    ui_label = "Mouse Following Mode";
    ui_tooltip = "Press right click to logo texture follow the mouse cursor.   \nRight click again to back to Position X and Y coord.";
    ui_spacing = 2;
> = false;

uniform float cLayer_PosX <
    ui_label = "Position X";
    ui_tooltip = "X & Y coordinates of the textures.\nAxes start upper left screen corner.   ";
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
> = 0.680;

uniform float cLayer_PosY <
    ui_label = "Position Y";
    ui_tooltip = "X & Y coordinates of the textures.\nAxes start upper left screen corner.   ";
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
> = 0.970;

uniform int cLayer_SnapRotate <
    ui_label = "Snap Rotation";
    ui_tooltip = "Snap rotation to a specific angle.\nPress arrow button to rotate 90° each direction.   ";
    ui_type = "combo";
    ui_spacing = 2;
    ui_items = "-90 Degrees\0"
               "0 Degrees\0"
               "90 Degrees\0"
               "180 Degrees\0"
               ;
> = 1;

uniform float cLayer_Rotate <
    ui_label = "Rotate";
    ui_tooltip = "Rotate the texture to desired angle.   ";
    ui_type = "slider";
    ui_min = -180.0;
    ui_max = 180.0;
    ui_step = 0.01;
> = 0;

uniform int cLayer_Color_Override <
    ui_label = "Recolor";
    ui_tooltip = "Can be invert the color (and) colorize   \nto any color to black/white areas.";
    ui_type = "combo";
    ui_spacing = 2;
    ui_items = "None\0"
               "Invert Color\0"
               "Recolor White Part\0"
               "Recolor Black Part\0"
               "Invert --> Recolor White Part\0"
               "Invert --> Recolor Black Part\0"
               ;
> = false;

uniform float3 ColorOverride <
    ui_label = "Color";
    ui_tooltip = "Color applied to recolor.   ";
    ui_type = "color";
> = float3(0.0, 1.0, 1.0);

BLENDING_COMBO(
    cLayer_BlendMode,
    "Blending Mode",
    "Select the blending mode applied to the texture.   ",
    "",
    false,
    2,
    0
);

uniform float cLayer_Blend <
    ui_label = "Blending Amount";
    ui_tooltip = "The amount of blending applied to the texture.   ";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;


uniform float Gauss_Blend <
    ui_label = "Blending Amount Gaussian Layer";
    ui_tooltip = "The amount of blending applied to the   \nGaussian Layer.";
    ui_category = "Gaussian Layer";
    ui_category_closed = true;
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 3.0;
    ui_step = 0.001;
> = 0.0;

uniform float cLayer_PosX_Gauss <
    ui_label = "Gaussian Layer Offset X";
    ui_tooltip = "Offset of the Gaussian layer based on texture's    \ncoordinates.";
    ui_category = "Gaussian Layer";
    ui_type = "slider";
    ui_spacing = 2;
    ui_min = -0.35; ui_max = 0.35;
    ui_step = 0.001;
> = 0.025;

uniform float cLayer_PosY_Gauss <
    ui_label = "Gaussian Layer Offset Y";
    ui_tooltip = "Offset of the Gaussian layer based on texture's    \ncoordinates.";
    ui_category = "Gaussian Layer";
    ui_type = "slider";
    ui_min = -0.35; ui_max = 0.35;
    ui_step = 0.001;
> = 0.050;

uniform float cLayer_Scale_Gauss <
    ui_label = "Gaussian Layer Scale";
    ui_tooltip = "Scale of the Gaussian layer.   ";
    ui_category = "Gaussian Layer";
    ui_type = "slider";
    ui_min = 0.75; ui_max = 1.5;
    ui_step = 0.001;
> = 1.000;

uniform int GaussianBlurRadius <
    ui_label = "Gaussian Blur Radius";
    ui_tooltip = "[0|1|2|3] Adjusts the blur radius.\nEach values Assumed to use for better results accord to   \ndifferent sizes of logos.   \nValue 3 is intended as some challenge.";
    ui_category = "Gaussian Layer";
    ui_type = "slider";
    ui_spacing = 2;
    ui_min = 0;
    ui_max = 3;
    ui_step = 1;
> = 1;

uniform float GaussWeight <
    ui_label = "Gaussian Weight";
    ui_tooltip = "Weight based on Gaussian Radius.   \nIncreasing value makes more blur.   ";
    ui_category = "Gaussian Layer";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 3.0;
    ui_step = 0.001;
> = 0.600;

uniform float GaussWeightH <
    ui_label = "Gaussian Weight X";
    ui_tooltip = "Weight based on Gaussian Radius.   \nIncreasing value makes more blur.   ";
    ui_category = "Gaussian Layer";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 10.0;
    ui_step = 0.001;
> = 0.001;

uniform float GaussWeightV <
    ui_label = "Gaussian Weight Y";
    ui_tooltip = "Weight based on Gaussian Radius.   \nIncreasing value makes more blur.   ";
    ui_category = "Gaussian Layer";
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 10.0;
    ui_step = 0.001;
> = 0.001;

uniform float3 GaussColor <
    ui_label = "Gaussian Layer Color";
    ui_tooltip = "Color applied to the Gaussian Layer.   ";
    ui_category = "Gaussian Layer";
    ui_type = "color";
    ui_spacing = 2;
    ui_tooltip = "Color of the shadow layer";
> = float3(0.0, 0.0, 0.0);

BLENDING_COMBO(
    cLayer_BlendMode_Gauss,
    "Gaussian Layer Blending Mode",
    "Select the blending mode applied to the Gaussian Layer.   ",
    "Gaussian Layer",
    false,
    2,
    0
);


BLENDING_COMBO(
    cLayer_BlendMode_BG,
    "BG Blending Mode",
        "Select the blending mode applied to the bg-texture.   \n\
    - note -   \nWhen using this mode, it requires reducing blending\namount of logo texture.   \nThe priority of this mode is to be set to later.   ",
    "BG Blending Mode",
    false,
    2,
    0
);

uniform float cLayer_Blend_BG <
    ui_label = "BG Blending Amount";
    ui_tooltip = "The amount of blending applied to the bg-texture.   ";
    ui_category = "BG Blending Mode";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.0;


uniform float4 cLayer_CAb_Color_A <
    ui_label = "CAb Color A";
    ui_tooltip = "A Color appling to Chromatic Aberration layer.   ";
    ui_category = "Chromatic Aberration";
    ui_category_closed = true;
    ui_type = "color";
> = float4(1.0, 0.0, 0.0, 1.0);

uniform float4 cLayer_CAb_Color_B <
    ui_label = "CAb Color B";
    ui_tooltip = "A Color appling to Chromatic Aberration layer.   ";
    ui_category = "Chromatic Aberration";
    ui_category_closed = true;
    ui_type = "color";
> = float4(0.0, 1.0, 1.0, 1.0);

uniform float2 cLayer_CAb_Shift <
    ui_label = "CAb Shift";
    ui_tooltip = "Degree of Chromatic Aberration.   ";
    ui_category = "Chromatic Aberration";
    ui_type = "slider";
    ui_min = -0.2;
    ui_max = 0.2;
    > = float2(0.015, -0.015);

uniform float cLayer_CAb_Strength <
    ui_label = "CAb Strength";
    ui_tooltip = "Blending Amount of Chromatic Aberration layer.   ";
    ui_category = "Chromatic Aberration";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.0;

uniform float cLayer_CAb_Blur <
    ui_label = "CAb Blur";
    ui_tooltip = "A Simplistic blur for Chromatic Aberration Layer .   ";
    ui_category = "Chromatic Aberration";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.5;
> = 0.015;

uniform int cLayer_BlendMode_CAb <
    ui_label = "CAb Blending Mode";
    ui_tooltip = "Select the blending mode applied to the CAb layer.\nDifferent look according to the brightness of background.   ";
    ui_category = "Chromatic Aberration";
    ui_type = "combo";
    ui_items = "Screen\0"
               "LinearDodge\0"
               "Glow\0"
               "LinearLight\0"
               "Color\0"
               "Grain Merge\0"
               "Divide\0"
               "Divide(Alternative)\0"
               "Normal\0"
               ;
> = 0;


uniform float cLayer_Depth <
    ui_label = "Depth Position";
    ui_type = "slider";
    ui_tooltip = "Place the texture behind characters,   \nterrains, etc.";
    ui_spacing = 2;
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float2 MouseCoords < source = "mousepoint"; >;
uniform bool LeftMouseDown < source = "mousebutton"; keycode = 0; toggle = true; >;
uniform bool RightMouseDown < source = "mousebutton"; keycode = 1; toggle = true; >;


// If you get an error about _SOURCE_COPYRIGHT_FILE, check to make sure you're not missing a referenced *Tex.fxh game header.
texture Copyright_Texture <
    source = _SOURCE_COPYRIGHT_FILE;
> {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
};

texture Copyright_Texture_Gauss_H
{
        Width = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA8; 
};

texture Copyright_Texture_Gauss_V
{
        Width = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA8; 
};

texture Copyright_Texture_Gauss_Out
{
        Width = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA8; 
};

texture Copyright_Texture_CAb_Gauss_H
{
        Width = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA8; 
};

texture Copyright_Texture_CAb_Gauss_Out
{
        Width = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA8; 
};

texture Copyright_Texture_CAb_A
{
        Width = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA8; 
};

texture Copyright_Texture_CAb_B
{
        Width = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = RGBA8; 
};

sampler Copyright_Sampler
{ 
    Texture = Copyright_Texture;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler Copyright_Sampler_Gauss_H
{ 
    Texture = Copyright_Texture_Gauss_H;
};

sampler Copyright_Sampler_Gauss_V
{ 
    Texture = Copyright_Texture_Gauss_Out;
};

sampler Copyright_Sampler_CAb_Gauss_H
{ 
    Texture = Copyright_Texture_CAb_Gauss_H;
};

sampler Copyright_Sampler_CAb_Gauss_V
{ 
    Texture = Copyright_Texture_CAb_Gauss_Out;
};

sampler Copyright_Sampler_CAb_A
{ 
    Texture = Copyright_Texture_CAb_A;
};

sampler Copyright_Sampler_CAb_B
{ 
    Texture = Copyright_Texture_CAb_B;
};

// -------------------------------------
// Entrypoints
// -------------------------------------

#define PIXEL_SIZE float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

#define pivot float3(0.5, 0.5, 0.0)
#define AspectX float(1.0 - (BUFFER_WIDTH) * (1.0 / BUFFER_HEIGHT))
#define AspectY float(1.0 - (BUFFER_HEIGHT) * (1.0 / BUFFER_WIDTH))
#define mulUV float3(texCoord.x, texCoord.y, 1)
#define ScaleSize float2(float2(_SOURCE_COPYRIGHT_SIZE) * cLayer_Scale / BUFFER_SCREEN_SIZE)
#define ScaleX float(ScaleSize.x * AspectX * cLayer_ScaleX)
#define ScaleY float(ScaleSize.y * AspectY * cLayer_ScaleY)
#define PosX float(cLayer_Mouse && RightMouseDown? MouseCoords.x * BUFFER_PIXEL_SIZE.x : cLayer_PosX)
#define PosY float(cLayer_Mouse && RightMouseDown? MouseCoords.y * BUFFER_PIXEL_SIZE.y : cLayer_PosY)
#define PosX_Gauss float(cLayer_PosX_Gauss * 0.1)
#define PosY_Gauss float(cLayer_PosY_Gauss * 0.1)
#define ScaleSize_Gauss float2(float2(_SOURCE_COPYRIGHT_SIZE) * ((cLayer_Scale) + (-1 + cLayer_Scale_Gauss)) / BUFFER_SCREEN_SIZE)
#define ScaleX_Gauss float(AspectX * ScaleSize_Gauss.x)
#define ScaleY_Gauss float(AspectY * ScaleSize_Gauss.y)


float3x3 positionMatrix (in float coord_X, in float coord_Y) {
    return float3x3 (
    1, 0, 0,
    0, 1, 0,
    -coord_X, -coord_Y, 1
    );
}

float3x3 scaleMatrix (in float width_X, in float width_Y) {
    return float3x3 (
        1/width_X, 0, 0,
        0,  1/width_Y, 0,
        0, 0, 1
    );
}

float3x3 rotateMatrix (in float angle) {
    float Rotate = angle * (3.1415926 / 180.0);
    switch(cLayer_SnapRotate)
    {
        case 0:
            Rotate = (angle * (3.1415926 / 180.0)) + (-90.0 * (3.1415926 / 180.0));
            break;
        case 1:
            break;
        case 2:
            Rotate = (angle * (3.1415926 / 180.0)) + (90.0 * (3.1415926 / 180.0));
            break;
        case 3:
            Rotate = (angle * (3.1415926 / 180.0)) + (180.0 * (3.1415926 / 180.0));
            break;
    }
    
    return float3x3 (
    (cos(Rotate) * AspectX), (sin(Rotate) * AspectX), 0,
    (-sin(Rotate) * AspectY), (cos(Rotate) * AspectY), 0,
    0, 0, 1
    );
}
 
float3x3 rotateMatrix_Alt (in float angle) {
    return float3x3 (
    (cos(angle) * AspectX), (sin(angle) * AspectX), 0,
    (-sin(angle) * AspectY), (cos(angle) * AspectY), 0,
    0, 0, 1
    );
}


float4 PS_cLayer_Gauss_H(in float4 pos : SV_Position, in float2 texCoord : TEXCOORD) : COLOR  {

        float4 color = tex2D(Copyright_Sampler_Gauss_V, texCoord);
        switch(GaussianBlurRadius)
        {
             default:
                 const float sampleOffsets[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
                 const float sampleWeights[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
                 color *= sampleWeights[0];
                 for(int i = 1; i < 4; ++i)
                 {
                 color += tex2Dlod(Copyright_Sampler_Gauss_V, float4(texCoord + float2(sampleOffsets[i] * (GaussWeight * (GaussWeightH + 0.5)) * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
                 color += tex2Dlod(Copyright_Sampler_Gauss_V, float4(texCoord - float2(sampleOffsets[i] * (GaussWeight * (GaussWeightH + 0.5)) * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
                 }
                 break;
             case 1:
                 const float sampleOffsets[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
                 const float sampleWeights[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
                 color *= sampleWeights[0];
                 for(int i = 1; i < 6; ++i)
                 {
                 color += tex2Dlod(Copyright_Sampler_Gauss_V, float4(texCoord + float2(sampleOffsets[i] * (GaussWeight * (GaussWeightH + 0.5)) * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
                 color += tex2Dlod(Copyright_Sampler_Gauss_V, float4(texCoord - float2(sampleOffsets[i] * (GaussWeight * (GaussWeightH + 0.5)) * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
                 }
                 break;
             case 2:
                 const float sampleOffsets[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
                 const float sampleWeights[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
                 color *= sampleWeights[0];
                 for(int i = 1; i < 11; ++i)
                 {
                 color += tex2Dlod(Copyright_Sampler_Gauss_V, float4(texCoord + float2(sampleOffsets[i] * (GaussWeight * (GaussWeightH + 0.5)) * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
                 color += tex2Dlod(Copyright_Sampler_Gauss_V, float4(texCoord - float2(sampleOffsets[i] * (GaussWeight * (GaussWeightH + 0.5)) * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
                 }
                 break;
             case 3:
                 const float sampleOffsets[6] = { 0.0, 0.25, 0.50, 0.75, 1.00, 1.25 };
                 const float sampleWeights[6] = { 0.15, 0.25, 0.135, 0.055, 0.0135, 0.0015 };
                 color *= sampleWeights[0];
                 for(int i = 1; i < 6; ++i)
                 {
                 color += tex2Dlod(Copyright_Sampler_Gauss_V, float4(texCoord + float2(sampleOffsets[i] * (GaussWeight * (GaussWeightH + 0.5)) * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
                 color += tex2Dlod(Copyright_Sampler_Gauss_V, float4(texCoord - float2(sampleOffsets[i] * (GaussWeight * (GaussWeightH + 0.5)) * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
                 }
                 break;
        }
        color.rgb = (GaussColor.rgb);
        return color;
}

float4 PS_cLayer_Gauss_V(in float4 pos : SV_Position, in float2 texCoord : TEXCOORD) : COLOR  {

        const float3 SumUV = mul (mul (mul (mulUV, positionMatrix(0.5 + PosX_Gauss, 0.5 + PosY_Gauss)), rotateMatrix_Alt(0)), scaleMatrix(ScaleX_Gauss, ScaleY_Gauss));
        float4 color = tex2D(Copyright_Sampler, SumUV.rg + pivot.rg);
        switch(GaussianBlurRadius)
        {
             default:
                 const float sampleOffsets[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
                 const float sampleWeights[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
                 color *= sampleWeights[0];
                 for(int i = 1; i < 4; ++i)
                 {
                 color += tex2Dlod(Copyright_Sampler_Gauss_H, float4(texCoord + float2(0.0, sampleOffsets[i] * (GaussWeight * (GaussWeightV + 0.5)) * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
                 color += tex2Dlod(Copyright_Sampler_Gauss_H, float4(texCoord - float2(0.0, sampleOffsets[i] * (GaussWeight * (GaussWeightV + 0.5)) * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
                 }
                 break;
             case 1:
                 const float sampleOffsets[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
                 const float sampleWeights[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
                 color *= sampleWeights[0];
                 for(int i = 1; i < 6; ++i)
                 {
                 color += tex2Dlod(Copyright_Sampler_Gauss_H, float4(texCoord + float2(0.0, sampleOffsets[i] * (GaussWeight * (GaussWeightV + 0.5)) * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
                 color += tex2Dlod(Copyright_Sampler_Gauss_H, float4(texCoord - float2(0.0, sampleOffsets[i] * (GaussWeight * (GaussWeightV + 0.5)) * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
                 }
                 break;
             case 2:
                 const float sampleOffsets[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
                 const float sampleWeights[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
                 color *= sampleWeights[0];
                 for(int i = 1; i < 11; ++i)
                 {
                 color += tex2Dlod(Copyright_Sampler_Gauss_H, float4(texCoord + float2(0.0, sampleOffsets[i] * (GaussWeight * (GaussWeightV + 0.5)) * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
                 color += tex2Dlod(Copyright_Sampler_Gauss_H, float4(texCoord - float2(0.0, sampleOffsets[i] * (GaussWeight * (GaussWeightV + 0.5)) * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
                 }
                 break;
             case 3:
                 const float sampleOffsets[6] = { 0.0, 0.25, 0.50, 0.75, 1.00, 1.25 };
                 const float sampleWeights[6] = { 0.15, 0.25, 0.135, 0.055, 0.0135, 0.0015 };
                 color *= sampleWeights[0];
                 for(int i = 1; i < 6; ++i)
                 {
                 color += tex2Dlod(Copyright_Sampler_Gauss_H, float4(texCoord + float2(0.0, sampleOffsets[i] * (GaussWeight * (GaussWeightV + 0.5)) * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
                 color += tex2Dlod(Copyright_Sampler_Gauss_H, float4(texCoord - float2(0.0, sampleOffsets[i] * (GaussWeight * (GaussWeightV + 0.5)) * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
                 }
                 break;
        }
        color.rgb = (GaussColor.rgb);
        return color;
}

float4 PS_cLayer_CAb_Gauss_H(in float4 pos : SV_Position, in float2 texCoord : TEXCOORD) : COLOR  {

        float4 color = tex2D(Copyright_Sampler_CAb_Gauss_V, texCoord);
        const float sampleOffsets[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
        const float sampleWeights[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
        color *= sampleWeights[0];
        for(int i = 1; i < 6; ++i)
        {
        color += tex2Dlod(Copyright_Sampler_CAb_Gauss_V, float4(texCoord + float2(sampleOffsets[i] * cLayer_CAb_Blur * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
        color += tex2Dlod(Copyright_Sampler_CAb_Gauss_V, float4(texCoord - float2(sampleOffsets[i] * cLayer_CAb_Blur * PIXEL_SIZE.x, 0.0), 0.0, 0.0)) * sampleWeights[i];
        }
        return color;
}

float4 PS_cLayer_CAb_Gauss_V(in float4 pos : SV_Position, in float2 texCoord : TEXCOORD) : COLOR  {

        const float3 SumUV = mul (mul (mul (mulUV, positionMatrix(0.5, 0.5)), rotateMatrix_Alt(0)), scaleMatrix(ScaleX, ScaleY));
        float4 color = tex2D(Copyright_Sampler, SumUV.rg + float2(0.5, 0.5));
        const float sampleOffsets[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
        const float sampleWeights[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
        color *= sampleWeights[0];
        for(int i = 1; i < 6; ++i)
        {
        color += tex2Dlod(Copyright_Sampler_CAb_Gauss_H, float4(texCoord + float2(0.0, sampleOffsets[i] * cLayer_CAb_Blur * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
        color += tex2Dlod(Copyright_Sampler_CAb_Gauss_H, float4(texCoord - float2(0.0, sampleOffsets[i] * cLayer_CAb_Blur * PIXEL_SIZE.y), 0.0, 0.0)) * sampleWeights[i];
        }
        return color;
}

float4 PS_cLayer_CAb_A(in float4 pos : SV_Position, in float2 texCoord : TEXCOORD) : COLOR  {

        const float2 CAb_Shift = cLayer_CAb_Shift * 0.05;
        const float3 SumUV = mul (mul (mulUV, positionMatrix(0.5 + CAb_Shift.x, 0.5 + CAb_Shift.y)), scaleMatrix(1, 1));
        float4 color = tex2D(Copyright_Sampler_CAb_Gauss_H, SumUV.rg + pivot.rg) * all(SumUV.rg + pivot.rg == saturate(SumUV.rg + pivot.rg));
        color = float4(cLayer_CAb_Color_A.r, cLayer_CAb_Color_A.g, cLayer_CAb_Color_A.b, color.a * cLayer_CAb_Color_A.a);
        return color;
}

float4 PS_cLayer_CAb_B(in float4 pos : SV_Position, in float2 texCoord : TEXCOORD) : COLOR  {

        const float2 CAb_Shift = cLayer_CAb_Shift * 0.05;
        const float3 SumUV = mul (mul (mulUV, positionMatrix(0.5 - CAb_Shift.x, 0.5 - CAb_Shift.y)), scaleMatrix(1, 1));
        float4 color = tex2D(Copyright_Sampler_CAb_Gauss_H, SumUV.rg + pivot.rg) * all(SumUV.rg + pivot.rg == saturate(SumUV.rg + pivot.rg));
        color = float4(cLayer_CAb_Color_B.r, cLayer_CAb_Color_B.g, cLayer_CAb_Color_B.b, color.a * cLayer_CAb_Color_B.a);
        return color;
}

void PS_cLayer(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {

    const float Depth = 0.999 - ReShade::GetLinearizedDepth(texCoord).x;
    float4 backColorOrig = tex2D(ReShade::BackBuffer, texCoord);
    if (Depth < cLayer_Depth)
    {
        const float3 SumUV = mul (mul (mul (mulUV, positionMatrix(PosX, PosY)), rotateMatrix(cLayer_Rotate)), scaleMatrix(ScaleX, ScaleY));
        const float3 SumUV_Gauss = mul (mul (mul (mulUV, positionMatrix(PosX, PosY)), rotateMatrix(cLayer_Rotate)), scaleMatrix(AspectX, AspectY));
        float4 GaussOut = tex2D(Copyright_Sampler_Gauss_H, SumUV_Gauss.rg + pivot.rg);       
        const float3 SumUV_CAb = mul (mul (mul (mulUV, positionMatrix(PosX, PosY)), rotateMatrix(cLayer_Rotate)), scaleMatrix(AspectX, AspectY));
        float4 CAb_A = tex2D(Copyright_Sampler_CAb_A, SumUV_CAb.rg + pivot.rg);
        float4 CAb_B = tex2D(Copyright_Sampler_CAb_B, SumUV_CAb.rg + pivot.rg);
        float4 DrawTex = tex2D(Copyright_Sampler, SumUV.rg + pivot.rg) * all(SumUV.rg + pivot.rg == saturate(SumUV.rg + pivot.rg));

        GaussOut.rgb = ComHeaders::Blending::Blend(cLayer_BlendMode_Gauss, backColorOrig.rgb, GaussOut.rgb, GaussOut.a * Gauss_Blend);

        switch(cLayer_BlendMode_CAb)
        {
            case 0:
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::Screen(GaussOut.rgb, CAb_A.rgb), CAb_A.a * cLayer_CAb_Strength);
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::Screen(GaussOut.rgb, CAb_B.rgb), CAb_B.a * cLayer_CAb_Strength);
                break;
            case 1:
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::LinearDodge(GaussOut.rgb, CAb_A.rgb), CAb_A.a * cLayer_CAb_Strength);
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::LinearDodge(GaussOut.rgb, CAb_B.rgb), CAb_B.a * cLayer_CAb_Strength);
                break;
            case 2:
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::Glow(GaussOut.rgb, CAb_A.rgb), CAb_A.a * cLayer_CAb_Strength);
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::Glow(GaussOut.rgb, CAb_B.rgb), CAb_B.a * cLayer_CAb_Strength);
                break;
            case 3:
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::LinearLight(GaussOut.rgb, CAb_A.rgb), CAb_A.a * cLayer_CAb_Strength);
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::LinearLight(GaussOut.rgb, CAb_B.rgb), CAb_B.a * cLayer_CAb_Strength);
                break;
            case 4:
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::ColorB(GaussOut.rgb, CAb_A.rgb), CAb_A.a * cLayer_CAb_Strength);
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::ColorB(GaussOut.rgb, CAb_B.rgb), CAb_B.a * cLayer_CAb_Strength);
                break;
            case 5:
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::GrainMerge(GaussOut.rgb, CAb_A.rgb), CAb_A.a * cLayer_CAb_Strength);
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::GrainMerge(GaussOut.rgb, CAb_B.rgb), CAb_B.a * cLayer_CAb_Strength);
                break;
            case 6:
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::Divide(GaussOut.rgb, CAb_A.rgb), CAb_A.a * cLayer_CAb_Strength);
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::Divide(GaussOut.rgb, CAb_B.rgb), CAb_B.a * cLayer_CAb_Strength);
                break;
            case 7:
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::DivideAlt(GaussOut.rgb, CAb_A.rgb), CAb_A.a * cLayer_CAb_Strength);
                GaussOut = lerp(GaussOut.rgb, ComHeaders::Blending::DivideAlt(GaussOut.rgb, CAb_B.rgb), CAb_B.a * cLayer_CAb_Strength);
                break;
            case 8:
                GaussOut = lerp(GaussOut.rgb, CAb_A.rgb, CAb_A.a * cLayer_CAb_Strength);
                GaussOut = lerp(GaussOut.rgb, CAb_B.rgb, CAb_B.a * cLayer_CAb_Strength);
                break;
        }

        float4 ColorFactor = DrawTex;

        switch(cLayer_Color_Override)
        {
            default:
                break;
            case 1:
                ColorFactor = float3(1, 1, 1) - DrawTex.rgb;
                break;
            case 2:
                ColorFactor =  saturate(DrawTex.rgb * ColorOverride.rgb); 
                break;
            case 3:
                ColorFactor =  DrawTex.rgb + ColorOverride.rgb;
                break;
            case 4:
                ColorFactor =  float4(-1, -1, -1, 1) * DrawTex;
                ColorFactor =  saturate(DrawTex.rgb * ColorOverride.rgb); 
                break;
            case 5:
                ColorFactor =  float4(-1, -1, -1, 1) * DrawTex;
                ColorFactor =  DrawTex.rgb + ColorOverride.rgb;
                break;
        }

        float4 backColor = GaussOut;
        passColor = lerp(GaussOut, backColorOrig, DrawTex.a);

        passColor.rgb = ComHeaders::Blending::Blend(cLayer_BlendMode_BG, backColor.rgb, passColor.rgb, DrawTex.a * cLayer_Blend_BG);

        switch (cLayer_BlendMode)
        {
            // Normal
            default:
                passColor = lerp(passColor.rgb, ColorFactor.rgb, DrawTex.a * cLayer_Blend);
                break;
            // Darken
            case 1:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Darken(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Multiply
            case 2:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Multiply(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Color Burn
            case 3:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::ColorBurn(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Linear Burn
            case 4:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::LinearBurn(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Lighten
            case 5:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Lighten(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Screen
            case 6:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Screen(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Color Dodge
            case 7:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::ColorDodge(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Linear Dodge
            case 8:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::LinearDodge(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Addition
            case 9:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Addition(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Glow
            case 10:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Glow(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Overlay
            case 11:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Overlay(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Soft Light
            case 12:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::SoftLight(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Hard Light
            case 13:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::HardLight(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Vivid Light
            case 14:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::VividLight(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Linear Light
            case 15:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::LinearLight(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Pin Light
            case 16:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::PinLight(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Hard Mix
            case 17:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::HardMix(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Difference
            case 18:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Difference(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Exclusion
            case 19:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Exclusion(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Subtract
            case 20:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Subtract(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Divide
            case 21:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Divide(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Divide (Alternative)
            case 22:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::DivideAlt(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Divide (Photoshop)
            case 23:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::DividePS(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Reflect
            case 24:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Reflect(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Grain Merge
            case 25:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::GrainMerge(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Grain Extract
            case 26:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::GrainExtract(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Hue
            case 27:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Hue(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Saturation
            case 28:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Saturation(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Color
            case 29:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::ColorB(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            // Luminosity
            case 30:
                passColor = lerp(passColor.rgb, ComHeaders::Blending::Luminosity(backColorOrig.rgb, ColorFactor.rgb), DrawTex.a * cLayer_Blend);
                break;
            }
        passColor.a = backColorOrig.a;
    }
   else
   passColor = backColorOrig;
}

// -------------------------------------
// Techniques
// -------------------------------------

technique Copyright< ui_label = "Copyright"; >
{
    pass pass0
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_cLayer_Gauss_H;
        RenderTarget = Copyright_Texture_Gauss_H;
    }
    pass pass1
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_cLayer_Gauss_V;
        RenderTarget = Copyright_Texture_Gauss_Out;
    }

    pass pass2
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_cLayer_CAb_Gauss_H;
        RenderTarget = Copyright_Texture_CAb_Gauss_H;
    }
    pass pass3
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_cLayer_CAb_Gauss_V;
        RenderTarget = Copyright_Texture_CAb_Gauss_Out;
    }
    pass pass4
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_cLayer_CAb_A;
        RenderTarget = Copyright_Texture_CAb_A;
    }
    pass pass5
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_cLayer_CAb_B;
        RenderTarget = Copyright_Texture_CAb_B;
    }
    pass pass6
   {
        VertexShader = PostProcessVS;
        PixelShader = PS_cLayer;
    }
}
