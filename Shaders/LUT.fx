//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Marty's LUT shader 1.0 for ReShade 3.0
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_ninjafadaGameplay.png was provided by ninjafada!
// You can see their ReShade-related work here: http://sfx.thelazy.net/users/u/ninjafada/
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_Sleepy.png was provided by Sleeps_Hungry!
// You can find them here: https://twitter.com/advent1013
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_Feli.png was provided by Feli!
// You can find them here: https://twitter.com/ffxivfeli
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_IpsusuGameplay.png was provided by Ipsusu!
// You can find them here: https://twitter.com/ipsusu
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Lightly optimized by Marot Satil for the GShade project.

#ifndef fLUT_TextureName
    #define fLUT_TextureName "lut_GShade.png" // Add your own LUT file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the LUT used! This one uses 32 tiles at 32px.
#endif
#ifndef fLUT_TileSizeXY
    #define fLUT_TileSizeXY 32
#endif
#ifndef fLUT_TileAmount
    #define fLUT_TileAmount 32
#endif
#ifndef fLUT_W_TextureName
    #define fLUT_W_TextureName "lut_warm.png" // Add your own LUT file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the LUT used! This one uses 64 tiles at 64px.
#endif
#ifndef fLUT_W_TileSizeXY
    #define fLUT_W_TileSizeXY 64
#endif
#ifndef fLUT_W_TileAmount
    #define fLUT_W_TileAmount 64
#endif
#ifndef fLUT_A_TextureName
    #define fLUT_A_TextureName "lut.png" // Add your own LUT file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the LUT used! This one uses 32 tiles at 32px.
#endif
#ifndef fLUT_NFG_TextureName
    #define fLUT_NFG_TextureName "lut_ninjafadaGameplay.png" // Add your own LUT file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the LUT used! This one uses 32 tiles at 32px.
#endif
#ifndef fLUT_RS_TextureName
    #define fLUT_RS_TextureName "lut_ReShade.png" // Add your own LUT file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the LUT used! This one uses 32 tiles at 32px.
#endif
#ifndef fLUT_SL_TextureName
    #define fLUT_SL_TextureName "lut_Sleepy.png" // Add your own LUT file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the LUT used! This one uses 64 tiles at 64px.
#endif
#ifndef fLUT_FE_TextureName
    #define fLUT_FE_TextureName "lut_Feli.png" // Add your own LUT file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the LUT used! This one uses 32 tiles at 32px.
#endif
#ifndef fLUT_LE_TextureName
    #define fLUT_LE_TextureName "lut_Legacy.png" // Add your own LUT file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the LUT used! This one uses 32 tiles at 32px.
#endif
#ifndef fLUT_IP_TextureName
    #define fLUT_IP_TextureName "lut_IpsusuGameplay.png" // Add your own LUT file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the LUT used! This one uses 32 tiles at 32px.
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int fLUT_Selector <
  ui_type = "combo";
  ui_items = "GShade/Angelite\0LUT - Warm.fx\0Autumn\0ninjafada Gameplay\0ReShade 3/4\0Sleeps_Hungry\0Feli\0Lufreine Legacy\0Ipsusu Gameplay\0";
  ui_label = "The LUT file to use.";
  ui_tooltip = "Set this to whichever your preset requires!";
  ui_bind = "LUTTexture_Source";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef LUTTexture_Source
#define LUTTexture_Source 0
#endif

uniform float fLUT_AmountChroma <
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT chroma amount";
    ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma <
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT luma amount";
    ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

#if   LUTTexture_Source == 0 // GShade/Angelite LUT
#define _SOURCE_LUT_FILE fLUT_TextureName
#define _SOURCE_LUT_SIZE fLUT_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_TileAmount
#elif LUTTexture_Source == 1 // LUT from LUT - Warm.fx
#define _SOURCE_LUT_FILE fLUT_W_TextureName
#define _SOURCE_LUT_SIZE fLUT_W_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_W_TileAmount
#elif LUTTexture_Source == 2 // MS Autumn LUT
#define _SOURCE_LUT_FILE fLUT_A_TextureName
#define _SOURCE_LUT_SIZE fLUT_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_TileAmount
#elif LUTTexture_Source == 3 // ninjafada Gameplay LUT
#define _SOURCE_LUT_FILE fLUT_NFG_TextureName
#define _SOURCE_LUT_SIZE fLUT_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_TileAmount
#elif LUTTexture_Source == 4 // Default ReShade 3-4 LUT
#define _SOURCE_LUT_FILE fLUT_RS_TextureName
#define _SOURCE_LUT_SIZE fLUT_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_TileAmount
#elif LUTTexture_Source == 5 // Sleepy LUT
#define _SOURCE_LUT_FILE fLUT_SL_TextureName
#define _SOURCE_LUT_SIZE fLUT_W_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_W_TileAmount
#elif LUTTexture_Source == 6 // Feli LUT
#define _SOURCE_LUT_FILE fLUT_FE_TextureName
#define _SOURCE_LUT_SIZE fLUT_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_TileAmount
#elif LUTTexture_Source == 7 // Lufreine Legacy LUT
#define _SOURCE_LUT_FILE fLUT_LE_TextureName
#define _SOURCE_LUT_SIZE fLUT_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_TileAmount
#elif LUTTexture_Source == 8 // Ipsusu Gameplay LUT
#define _SOURCE_LUT_FILE fLUT_IP_TextureName
#define _SOURCE_LUT_SIZE fLUT_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_TileAmount
#endif


texture texLUT < source = _SOURCE_LUT_FILE; > { Width = _SOURCE_LUT_SIZE * _SOURCE_LUT_AMOUNT; Height = _SOURCE_LUT_SIZE; Format = RGBA8; };
sampler	SamplerLUT 	{ Texture = texLUT; };

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_LUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
    res = tex2D(ReShade::BackBuffer, texcoord.xy);

    float2 texelsize = 1.0 / _SOURCE_LUT_SIZE;
    texelsize.x /= _SOURCE_LUT_AMOUNT;

    float3 lutcoord = float3((res.xy * _SOURCE_LUT_SIZE - res.xy + 0.5) * texelsize.xy, res.z * _SOURCE_LUT_SIZE - res.z);
    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;

    const float3 lutcolor = lerp(tex2D(SamplerLUT, lutcoord.xy).xyz, tex2D(SamplerLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    res.xyz = lerp(normalize(res.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
              lerp(length(res.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);
    res.w = 1.0;
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique LUT
{
    pass LUT_Apply
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_LUT_Apply;
    }
}