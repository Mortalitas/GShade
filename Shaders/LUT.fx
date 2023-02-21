//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
// visit facebook.com/MartyMcModding for news/updates
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Marty's LUT shader 1.0 for ReShade 3.0
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_GShade.png is a modified version of Mori's Angelite MultiLUT table made for GShade!
// Follow them on Twitter here: https://twitter.com/moripudding
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_ninjafadaGameplay.png was provided by ninjafada!
// You can see their ReShade-related work here: http://sfx.thelazy.net/users/u/ninjafada/
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_Sleepy.png was provided by Sleeps_Hungry!
// Follow them on Twitter here: https://twitter.com/advent1013
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_Feli.png was provided by Feli!
// Follow them on Twitter here: https://twitter.com/ffxivfeli
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_Legacy.png was provided by Lufreine!
// Follow them on Twitter here: https://twitter.com/Lufreine
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// lut_IpsusuGameplay.png was provided by Ipsusu!
// Follow them on Twitter here: https://twitter.com/ipsusu
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// EGGameplayLut.png was created by Espresso Lalafell from their Espresso Glow Build!
// Follow them on Twitter here: https://twitter.com/espressolala
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Lightly optimized by Marot Satil for the GShade project.

#ifndef LUTTexture_Source
	#define LUTTexture_Source 0
#endif

#if LUTTexture_Source == 4
	#ifndef fLUT_TextureName
		#define fLUT_TextureName "lut_ReShade.png" // Add your own LUT with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes under the Preprocessor Definitions under the shader's normal settings on the Home tab to change the LUT used!
	#endif
	#ifndef fLUT_TileSizeXY
		#define fLUT_TileSizeXY 32
	#endif
	#ifndef fLUT_TileAmount
		#define fLUT_TileAmount 32
	#endif
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int fLUT_Selector <
  ui_type = "combo";
  ui_items = "GShade/Angelite\0LUT - Warm.fx\0Autumn\0ninjafada Gameplay\0ReShade | Custom\0Sleeps_Hungry\0Feli\0Lufreine Legacy\0Ipsusu Gameplay\0Potatoshade\0Espresso Glow\0";
  ui_label = "The LUT file to use.";
  ui_tooltip = "Select a LUT!\n\nPlease note that the Potatoshade option will require you to obtain a copy of \"seilut.png\" from the Potoshade zip and place it in the \"?:\\Users\\Public\\GShade Custom Shaders\\Textures\" folder before it becomes usable.";
  ui_bind = "LUTTexture_Source";
> = 0;

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

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#if   LUTTexture_Source == 0 // GShade/Angelite LUT
#define _SOURCE_LUT_FILE "lut_GShade.png"
#define _SOURCE_LUT_SIZE 32
#define _SOURCE_LUT_AMOUNT 32
#elif LUTTexture_Source == 1 // LUT from LUT - Warm.fx
#define _SOURCE_LUT_FILE "lut_warm.png"
#define _SOURCE_LUT_SIZE 64
#define _SOURCE_LUT_AMOUNT 64
#elif LUTTexture_Source == 2 // MS Autumn LUT
#define _SOURCE_LUT_FILE "lut.png"
#define _SOURCE_LUT_SIZE 32
#define _SOURCE_LUT_AMOUNT 32
#elif LUTTexture_Source == 3 // ninjafada Gameplay LUT
#define _SOURCE_LUT_FILE "lut_ninjafadaGameplay.png"
#define _SOURCE_LUT_SIZE 32
#define _SOURCE_LUT_AMOUNT 32
#elif LUTTexture_Source == 4 // Default ReShade 3-4 LUT
#define _SOURCE_LUT_FILE fLUT_TextureName
#define _SOURCE_LUT_SIZE fLUT_TileSizeXY
#define _SOURCE_LUT_AMOUNT fLUT_TileAmount
#elif LUTTexture_Source == 5 // Sleepy LUT
#define _SOURCE_LUT_FILE "lut_Sleepy.png"
#define _SOURCE_LUT_SIZE 64
#define _SOURCE_LUT_AMOUNT 64
#elif LUTTexture_Source == 6 // Feli LUT
#define _SOURCE_LUT_FILE "lut_Feli.png"
#define _SOURCE_LUT_SIZE 32
#define _SOURCE_LUT_AMOUNT 32
#elif LUTTexture_Source == 7 // Lufreine Legacy LUT
#define _SOURCE_LUT_FILE "lut_Legacy.png"
#define _SOURCE_LUT_SIZE 32
#define _SOURCE_LUT_AMOUNT 32
#elif LUTTexture_Source == 8 // Ipsusu Gameplay LUT
#define _SOURCE_LUT_FILE "lut_IpsusuGameplay.png"
#define _SOURCE_LUT_SIZE 32
#define _SOURCE_LUT_AMOUNT 32
#elif LUTTexture_Source == 9 // Potatoshade LUT
#define _SOURCE_LUT_FILE "seilut.png"
#define _SOURCE_LUT_SIZE 64
#define _SOURCE_LUT_AMOUNT 64
#elif LUTTexture_Source == 10 // Espresso Glow LUT
#define _SOURCE_LUT_FILE "EGGameplayLut.png"
#define _SOURCE_LUT_SIZE 32
#define _SOURCE_LUT_AMOUNT 32
#endif


texture texLUT < source = _SOURCE_LUT_FILE; > { Width = _SOURCE_LUT_SIZE * _SOURCE_LUT_AMOUNT; Height = _SOURCE_LUT_SIZE; Format = RGBA8; };
sampler	SamplerLUT 	{ Texture = texLUT; };

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_LUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float3 res : SV_Target0)
{
    res = tex2D(ReShade::BackBuffer, texcoord.xy).xyz;

    float2 texelsize = 1.0 / _SOURCE_LUT_SIZE;
    texelsize.x /= _SOURCE_LUT_AMOUNT;

    float3 lutcoord = float3((res.xy * _SOURCE_LUT_SIZE - res.xy + 0.5) * texelsize.xy, res.z * _SOURCE_LUT_SIZE - res.z);
    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;

    const float3 lutcolor = lerp(tex2D(SamplerLUT, lutcoord.xy).xyz, tex2D(SamplerLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz, lerpfact);

    res = lerp(normalize(res), normalize(lutcolor), fLUT_AmountChroma) * 
              lerp(length(res),    length(lutcolor),    fLUT_AmountLuma);

#if GSHADE_DITHER
	res += TriDither(res, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
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