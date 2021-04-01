//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade 4.0 effect file
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Multi-LUT shader, using a texture atlas with multiple LUTs
// by Otis / Infuse Project.
// Based on Marty's LUT shader 1.0 for ReShade 3.0
// Further improvements including overall intensity, multiple texture support, and increased precision added by seri14 and Marot Satil.
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// MultiLut_GShade.png is a modified version of miiok's Angelite MultiLUT table made for GShade!
// Follow miiolk on Twitter here: https://twitter.com/miiolk
// And GPOSERS here: https://twitter.com/GPOSERS_FFXIV
// For GShade news and updates, join our Discord: https://twitter.com/GPOSERS_FFXIV
//
// MultiLut_Johto.png was created by Johto!
// Follow them on Twitter here: https://twitter.com/JohtoFFXIV
//
// FFXIVLUTAtlas.png was created by Espresso Lalaqo'te from their Espresso Glow Build!
// Follow them on Twitter here: https://twitter.com/espressolala
//
// MultiLut_ninjafadaGameplay.png was created by ninjafada!
// You can see their ReShade-related work here: http://sfx.thelazy.net/users/u/ninjafada/
//
// MultiLut_seri14.png was created by seri14!
// Follow their work on Github here: https://github.com/seri14
// And follow them on Twitter here: https://twitter.com/seri_haruna
//
// MultiLut_Ipsusu.png was provided by Ipsusu!
// You can find them here: https://twitter.com/ipsusu
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Lightly optimized by Marot Satil for the GShade project.

#ifndef fLUT_GSTextureName
    #define fLUT_GSTextureName "MultiLut_GShade.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 17 rows at 32px.
#endif
#ifndef fLUT_RESTextureName
    #define fLUT_RESTextureName "MultiLut_atlas4.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 17 rows at 32px.
#endif
#ifndef fLUT_JOHTextureName
    #define fLUT_JOHTextureName "MultiLut_Johto.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 18 rows at 32px.
#endif
#ifndef fLUT_EGTextureName
    #define fLUT_EGTextureName "FFXIVLUTAtlas.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 17 rows at 32px.
#endif
#ifndef fLUT_MSTextureName
    #define fLUT_MSTextureName "TMP_MultiLUT.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 12 rows at 32px.
#endif
#ifndef fLUT_NFGTextureName
    #define fLUT_NFGTextureName "MultiLut_ninjafadaGameplay.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 12 rows at 32px.
#endif
#ifndef fLUT_S14TextureName
    #define fLUT_S14TextureName "MultiLut_seri14.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 11 rows at 32px.
#endif
#ifndef fLUT_YOMTextureName
    #define fLUT_YOMTextureName "MultiLut_Yomi.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 12 rows at 32px.
#endif
#ifndef fLUT_NENTextureName
    #define fLUT_NENTextureName "MultiLut_Neneko.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 12 rows at 32px.
#endif
#ifndef fLUT_YAETextureName
    #define fLUT_YAETextureName "MultiLut_yaes.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 12 rows at 32px.
#endif
#ifndef fLUT_IPSTextureName
    #define fLUT_IPSTextureName "MultiLut_Ipsusu.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 12 rows at 32px.
#endif
#ifndef fLUT_NGETextureName
    #define fLUT_NGETextureName "MultiLut_Nightingale.png" // Add your own MultiLUT atlas to \reshade-shaders\Textures\ and provide the new file name in quotes to change the MultiLUT used! This one uses 12 rows at 32px.
#endif
#ifndef fLUT_TileSizeXY
    #define fLUT_TileSizeXY 32
#endif
#ifndef fLUT_TileAmount
    #define fLUT_TileAmount 32
#endif
#ifndef fLUT_LutAmount
    #define fLUT_LutAmount 17
#endif
#ifndef fLUT_LutAmountEx
    #define fLUT_LutAmountEx 18
#endif
#ifndef fLUT_LutAmountLow
    #define fLUT_LutAmountLow 12
#endif
#ifndef fLUT_LutAmountLower
    #define fLUT_LutAmountLower 11
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int fLUT_MultiLUTSelector <
    ui_category = "Pass 1";
    ui_type = "combo";
    ui_items = "GShade [Angelite-Compatible]\0ReShade 4\0ReShade 3\0Johto\0Espresso Glow\0Faeshade/Dark Veil/HQ Shade/MoogleShade\0ninjafada Gameplay\0seri14\0Yomi\0Neneko\0Yaes\0Ipsusu\0Nightingale\0";
    ui_label = "The MultiLUT file to use.";
    ui_tooltip = "Set this to whatever build your preset was made with!";
    ui_bind = "MultiLUTTexture_Source";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef MultiLUTTexture_Source
    #undef MultiLutTexture_Source // No idea why yet but if this isn't here, it causes issues under DirectX 9.
    #define MultiLUTTexture_Source 0
#endif

uniform int fLUT_LutSelector < 
    ui_category = "Pass 1";
    ui_type = "combo";
#if MultiLUTTexture_Source == 0 // GShade/Angelite
    ui_items = "Color0\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Sepia\0Color10\0Color11\0Cross process\0Azure Red Dual Tone\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
#elif MultiLUTTexture_Source == 1 || MultiLUTTexture_Source == 2 // ReShade 3 & 4
    ui_items = "Neutral\0Color1\0Color2\0Color3 (Blue oriented)\0Color4 (Hollywood)\0Color5\0Color6\0Color7\0Color8\0Cool light\0Flat & green\0Red lift matte\0Cross process\0Azure Red Dual Tone\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
#elif MultiLUTTexture_Source == 3 // Johto
    ui_items = "Neutral\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0Color11\0Color12\0Color13\0Color14\0Color15\0Color16\0Color17\0";
#elif MultiLUTTexture_Source == 4 // Espresso Glow
    ui_items = "Neutral\0Darklite (Realism, Day, Outdoors)\0Shadownite (Realism, Night, Indoors)\0Ambient Memories (Bright, Warm)\0Faded Memories (Desaturated, Dark)\0Pastel Memories (Cartoony, Colorful, Bright)\0Nostalgic \ Radiance (Bright, Colorful, Studio, Lights)\0";
#elif MultiLUTTexture_Source == 5 // MS
    ui_items = "Neutral\0Lela\0Brienne\0Color3\0Light\0Pink\0Angelite\0Cool Light\0Flat & Green\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
#elif MultiLUTTexture_Source == 6 // ninjafada
    ui_items = "Color0\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0Color11\0";
#elif MultiLUTTexture_Source == 7 // seri14
    ui_items = "Neutral\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0";
#elif MultiLUTTexture_Source == 8 // Yomi
    ui_items = "Neutral\0Nature's Call\0Cherry Blossom\0Bleach\0Golden Hour\0Vibrant Sands\0Azure\0Macaron\0Vintage Film\0Bubble Gum\0Fountain\0Clear Skies\0Action\0Pastel Purity\0Lens Clarity\0Heart\0Teal and Orange\0Haunt\0";
#elif MultiLUTTexture_Source == 9 // Neneko
    ui_items = "Neutral\0Cinnamon\0Autumn\0Pumpkin Spice\0Harley\0Banshee\0Forsaken\0Blood\0Vampire\0Curse\0Poison Ivy\0Monster\0";
#elif MultiLUTTexture_Source == 10 // Yaes
    ui_items = "Neutral\0Faded Light\0Faded Muted\0Balanced green\0Balanced purple\0Brain freeze\0Burnt brown\0All purple\0Muted green\0Mono tinted\0True BW\0Faded BW";
#elif MultiLUTTexture_Source == 11 // Ipsusu
    ui_items = "Neutral\0Ipsusu\0IpsusuWarm\0IpsusuPastel\0IpsusuVanilla\0";
#elif MultiLUTTexture_Source == 12 // Nightingale
    ui_items = "Day\0DarkOrange\0Daydream\0Orange\0Bluelight\0Sweet\0Summer\0Spring\0Melancholia\0Film\0Brown\0Light\0";
#else
    ui_items = "Color0 (Usually Neutral)\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10 | Colors above 10\0Color11 | may not work for\0Color12 | all MultiLUT files.\0Color13\0Color14\0Color15\0Color16\0Color17\0";
#endif
    ui_label = "LUT to use.";
    ui_tooltip = "LUT to use for color transformation. ReShade 4's 'Neutral' doesn't do any color transformation.";
> = 0;

uniform float fLUT_Intensity <
    ui_category = "Pass 1";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Intensity";
    ui_tooltip = "Overall intensity of the LUT effect.";
> = 1.00;

uniform float fLUT_AmountChroma <
    ui_category = "Pass 1";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Chroma Amount";
    ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma <
    ui_category = "Pass 1";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Luma Amount";
    ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;

uniform bool fLUT_MultiLUTPass2 <
    ui_category = "Pass 2";
    ui_label = "Enable Pass 2";
    ui_bind = "MultiLUTTexture2";
> = 0;

#ifndef MultiLUTTexture2
    #define MultiLUTTexture2 0
#endif

#if MultiLUTTexture2
uniform int fLUT_MultiLUTSelector2 <
    ui_category = "Pass 2";
    ui_type = "combo";
    ui_items = "GShade [Angelite-Compatible]\0ReShade 4\0ReShade 3\0Johto\0Espresso Glow\0Faeshade/Dark Veil/HQ Shade/MoogleShade\0ninjafada Gameplay\0seri14\0Yomi\0Neneko\0Yaes\0Ipsusu\0Nightingale\0";
    ui_label = "The MultiLUT file to use.";
    ui_tooltip = "The MultiLUT table to use on Pass 2.";
    ui_bind = "MultiLUTTexture2_Source";
> = 1;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef MultiLUTTexture2_Source
    #undef MultiLutTexture2_Source // No idea why yet but if this isn't here, it causes issues under DirectX 9.
    #define MultiLUTTexture2_Source 1
#endif

uniform int fLUT_LutSelector2 < 
    ui_category = "Pass 2";
    ui_type = "combo";
#if MultiLUTTexture2_Source == 0 // GShade/Angelite
    ui_items = "Color0\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Sepia\0Color10\0Color11\0Cross process\0Azure Red Dual Tone\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
#elif MultiLUTTexture2_Source == 1 || MultiLUTTexture_Source == 2 // ReShade 3 & 4
    ui_items = "Neutral\0Color1\0Color2\0Color3 (Blue oriented)\0Color4 (Hollywood)\0Color5\0Color6\0Color7\0Color8\0Cool light\0Flat & green\0Red lift matte\0Cross process\0Azure Red Dual Tone\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
#elif MultiLUTTexture2_Source == 3 // Johto
    ui_items = "Neutral\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0Color11\0Color12\0Color13\0Color14\0Color15\0Color16\0Color17\0";
#elif MultiLUTTexture2_Source == 4 // Espresso Glow
    ui_items = "Neutral\0Darklite (Realism, Day, Outdoors)\0Shadownite (Realism, Night, Indoors)\0Ambient Memories (Bright, Warm)\0Faded Memories (Desaturated, Dark)\0Pastel Memories (Cartoony, Colorful, Bright)\0Nostalgic \ Radiance (Bright, Colorful, Studio, Lights)\0";
#elif MultiLUTTexture2_Source == 5 // MS
    ui_items = "Neutral\0Lela\0Brienne\0Color3\0Light\0Pink\0Angelite\0Cool Light\0Flat & Green\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
#elif MultiLUTTexture2_Source == 6 // ninjafada
    ui_items = "Color0\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0Color11\0";
#elif MultiLUTTexture2_Source == 7 // seri14
    ui_items = "Neutral\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0";
#elif MultiLUTTexture2_Source == 8 // Yomi
    ui_items = "Neutral\0Nature's Call\0Cherry Blossom\0Bleach\0Golden Hour\0Vibrant Sands\0Azure\0Macaron\0Vintage Film\0Bubble Gum\0Fountain\0Clear Skies\0Action\0Pastel Purity\0Lens Clarity\0Heart\0Teal and Orange\0Haunt\0";
#elif MultiLUTTexture2_Source == 9 // Neneko
    ui_items = "Neutral\0Cinnamon\0Autumn\0Pumpkin Spice\0Harley\0Banshee\0Forsaken\0Blood\0Vampire\0Curse\0Poison Ivy\0Monster\0";
#elif MultiLUTTexture2_Source == 10 // Yaes
    ui_items = "Neutral\0Faded Light\0Faded Muted\0Balanced green\0Balanced purple\0Brain freeze\0Burnt brown\0All purple\0Muted green\0Mono tinted\0True BW\0Faded BW";
#elif MultiLUTTexture2_Source == 11 // Ipsusu
    ui_items = "Neutral\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0Color11\0Color12\0Color13\0Color14\0Color15\0Color16\0";
#elif MultiLUTTexture_Source == 12 // Nightingale
    ui_items = "Day\0DarkOrange\0Daydream\0Orange\0Bluelight\0Sweet\0Summer\0Spring\0Melancholia\0Film\0Brown\0Light\0";
#else
    ui_items = "Color0 (Usually Neutral)\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10 | Colors above 10\0Color11 | may not work for\0Color12 | all MultiLUT files.\0Color13\0Color14\0Color15\0Color16\0Color17\0";
#endif
    ui_label = "LUT to use.";
    ui_tooltip = "LUT to use for color transformation on Pass 2. ReShade 4's 'Neutral' doesn't do any color transformation.";
> = 0;

uniform float fLUT_Intensity2 <
    ui_category = "Pass 2";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Intensity";
    ui_tooltip = "Overall intensity of the LUT effect.";
> = 1.00;

uniform float fLUT_AmountChroma2 <
    ui_category = "Pass 2";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Chroma Amount";
    ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma2 <
    ui_category = "Pass 2";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Luma Amount";
    ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;
#endif

uniform bool fLUT_MultiLUTPass3 <
    ui_category = "Pass 3";
    ui_label = "Enable Pass 3";
    ui_bind = "MultiLUTTexture3";
> = 0;

#ifndef MultiLUTTexture3
    #define MultiLUTTexture3 0
#endif

#if MultiLUTTexture3
uniform int fLUT_MultiLUTSelector3 <
    ui_category = "Pass 3";
    ui_type = "combo";
    ui_items = "GShade [Angelite-Compatible]\0ReShade 4\0ReShade 3\0Johto\0Espresso Glow\0Faeshade/Dark Veil/HQ Shade/MoogleShade\0ninjafada Gameplay\0seri14\0Yomi\0Neneko\0Yaes\0Ipsusu\0Nightingale\0";
    ui_label = "The MultiLUT file to use.";
    ui_tooltip = "The MultiLUT table to use on Pass 3.";
    ui_bind = "MultiLUTTexture3_Source";
> = 1;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef MultiLUTTexture3_Source
    #undef MultiLutTexture3_Source // No idea why yet but if this isn't here, it causes issues under DirectX 9.
    #define MultiLUTTexture3_Source 1
#endif

uniform int fLUT_LutSelector3 < 
    ui_category = "Pass 3";
    ui_type = "combo";
#if MultiLUTTexture3_Source == 0 // GShade/Angelite
    ui_items = "Color0\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Sepia\0Color10\0Color11\0Cross process\0Azure Red Dual Tone\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
#elif MultiLUTTexture3_Source == 1 || MultiLUTTexture_Source == 2 // ReShade 3 & 4
    ui_items = "Neutral\0Color1\0Color2\0Color3 (Blue oriented)\0Color4 (Hollywood)\0Color5\0Color6\0Color7\0Color8\0Cool light\0Flat & green\0Red lift matte\0Cross process\0Azure Red Dual Tone\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
#elif MultiLUTTexture3_Source == 3 // Johto
    ui_items = "Neutral\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0Color11\0Color12\0Color13\0Color14\0Color15\0Color16\0Color17\0";
#elif MultiLUTTexture3_Source == 4 // Espresso Glow
    ui_items = "Neutral\0Darklite (Realism, Day, Outdoors)\0Shadownite (Realism, Night, Indoors)\0Ambient Memories (Bright, Warm)\0Faded Memories (Desaturated, Dark)\0Pastel Memories (Cartoony, Colorful, Bright)\0Nostalgic \ Radiance (Bright, Colorful, Studio, Lights)\0";
#elif MultiLUTTexture3_Source == 5 // MS
    ui_items = "Neutral\0Lela\0Brienne\0Color3\0Light\0Pink\0Angelite\0Cool Light\0Flat & Green\0Sepia\0\B&W mid constrast\0\B&W high contrast\0";
#elif MultiLUTTexture3_Source == 6 // ninjafada
    ui_items = "Color0\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0Color11\0";
#elif MultiLUTTexture3_Source == 7 // seri14
    ui_items = "Neutral\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0";
#elif MultiLUTTexture3_Source == 8 // Yomi
    ui_items = "Neutral\0Nature's Call\0Cherry Blossom\0Bleach\0Golden Hour\0Vibrant Sands\0Azure\0Macaron\0Vintage Film\0Bubble Gum\0Fountain\0Clear Skies\0Action\0Pastel Purity\0Lens Clarity\0Heart\0Teal and Orange\0Haunt\0";
#elif MultiLUTTexture3_Source == 9 // Neneko
    ui_items = "Neutral\0Cinnamon\0Autumn\0Pumpkin Spice\0Harley\0Banshee\0Forsaken\0Blood\0Vampire\0Curse\0Poison Ivy\0Monster\0";
#elif MultiLUTTexture3_Source == 10 // Yaes
    ui_items = "Neutral\0Faded Light\0Faded Muted\0Balanced green\0Balanced purple\0Brain freeze\0Burnt brown\0All purple\0Muted green\0Mono tinted\0True BW\0Faded BW";
#elif MultiLUTTexture3_Source == 11 // Ipsusu
    ui_items = "Neutral\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0Color11\0Color12\0Color13\0Color14\0Color15\0Color16\0";
#elif MultiLUTTexture_Source == 12 // Nightingale
    ui_items = "Day\0DarkOrange\0Daydream\0Orange\0Bluelight\0Sweet\0Summer\0Spring\0Melancholia\0Film\0Brown\0Light\0";
#else
    ui_items = "Color0 (Usually Neutral)\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10 | Colors above 10\0Color11 | may not work for\0Color12 | all MultiLUT files.\0Color13\0Color14\0Color15\0Color16\0Color17\0";
#endif
    ui_label = "LUT to use.";
    ui_tooltip = "LUT to use for color transformation on Pass 3. ReShade 4's 'Neutral' doesn't do any color transformation.";
> = 0;

uniform float fLUT_Intensity3 <
    ui_category = "Pass 3";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Intensity";
    ui_tooltip = "Overall intensity of the LUT effect.";
> = 1.00;

uniform float fLUT_AmountChroma3 <
    ui_category = "Pass 3";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Chroma Amount";
    ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma3 <
    ui_category = "Pass 3";
    ui_type = "slider";
    ui_min = 0.00; ui_max = 1.00;
    ui_label = "LUT Luma Amount";
    ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

#if MultiLUTTexture_Source == 0 // GShade/Angelite MultiLut_GShade.png
    #define _SOURCE_MULTILUT_FILE fLUT_GSTextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmount
#elif MultiLUTTexture_Source == 1 || MultiLUTTexture_Source == 2 // ReShade 3 & 4 MultiLut_atlas4.png
    #define _SOURCE_MULTILUT_FILE fLUT_RESTextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmount
#elif MultiLUTTexture_Source == 3 // Johto MultiLut_Johto.png
    #define _SOURCE_MULTILUT_FILE fLUT_JOHTextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmountEx
#elif MultiLUTTexture_Source == 4 // Espresso Glow FFXIVLUTAtlas.png
    #define _SOURCE_MULTILUT_FILE fLUT_EGTextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmount
#elif MultiLUTTexture_Source == 5 // MS TMP_MultiLUT.png
    #define _SOURCE_MULTILUT_FILE fLUT_MSTextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmountLow
#elif MultiLUTTexture_Source == 6 // ninjafada Gameplay MultiLut_ninjafadaGameplay.png
    #define _SOURCE_MULTILUT_FILE fLUT_NFGTextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmountLow
#elif MultiLUTTexture_Source == 7 // seri14 MultiLut_seri14.png
    #define _SOURCE_MULTILUT_FILE fLUT_S14TextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmountLower
#elif MultiLUTTexture_Source == 8 // Yomi MultiLut_Yomi.png
    #define _SOURCE_MULTILUT_FILE fLUT_YOMTextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmountEx
#elif MultiLUTTexture_Source == 9 // Neneko MultiLut_Neneko.png
    #define _SOURCE_MULTILUT_FILE fLUT_NENTextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmountLow
#elif MultiLUTTexture_Source == 10 // Yaes MultiLut_yaes.png
    #define _SOURCE_MULTILUT_FILE fLUT_YAETextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmountLow
#elif MultiLUTTexture_Source == 11 // Ipsusu MultiLut_Ipsusu.png
    #define _SOURCE_MULTILUT_FILE fLUT_IPSTextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmount
#elif MultiLUTTexture_Source == 12 // Nightingale MultiLut_Nightingale.png
    #define _SOURCE_MULTILUT_FILE fLUT_NGETextureName
    #define _SOURCE_MULTILUT_AMOUNT fLUT_LutAmountLow
#endif

#if MultiLUTTexture2_Source == 0 // GShade/Angelite MultiLut_GShade.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_GSTextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmount
#elif MultiLUTTexture2_Source == 1 || MultiLUTTexture2_Source == 2 // ReShade 3 & 4 MultiLut_atlas4.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_RESTextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmount
#elif MultiLUTTexture2_Source == 3 // Johto MultiLut_Johto.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_JOHTextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmountEx
#elif MultiLUTTexture2_Source == 4 // Espresso Glow FFXIVLUTAtlas.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_EGTextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmount
#elif MultiLUTTexture2_Source == 5 // MS TMP_MultiLUT.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_MSTextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmountLow
#elif MultiLUTTexture2_Source == 6 // ninjafada Gameplay MultiLut_ninjafadaGameplay.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_NFGTextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmountLow
#elif MultiLUTTexture2_Source == 7 // seri14 MultiLut_seri14.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_S14TextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmountLower
#elif MultiLUTTexture2_Source == 8 // Yomi MultiLut_Yomi.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_YOMTextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmountEx
#elif MultiLUTTexture2_Source == 9 // Neneko MultiLut_Neneko.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_NENTextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmountLow
#elif MultiLUTTexture2_Source == 10 // Yaes MultiLut_yaes.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_YAETextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmountLow
#elif MultiLUTTexture2_Source == 11 // Ipsusu MultiLut_Ipsusu.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_IPSTextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmount
#elif MultiLUTTexture2_Source == 12 // Nightingale MultiLut_Nightingale.png
    #define _SOURCE_MULTILUT_FILE2 fLUT_NGETextureName
    #define _SOURCE_MULTILUT_AMOUNT2 fLUT_LutAmountLow
#endif

#if MultiLUTTexture3_Source == 0 // GShade/Angelite MultiLut_GShade.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_GSTextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmount
#elif MultiLUTTexture3_Source == 1 || MultiLUTTexture3_Source == 2 // ReShade 3 & 4 MultiLut_atlas4.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_RESTextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmount
#elif MultiLUTTexture3_Source == 3 // Johto MultiLut_Johto.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_JOHTextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmountEx
#elif MultiLUTTexture3_Source == 4 // Espresso Glow FFXIVLUTAtlas.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_EGTextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmount
#elif MultiLUTTexture3_Source == 5 // MS TMP_MultiLUT.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_MSTextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmountLow
#elif MultiLUTTexture3_Source == 6 // ninjafada Gameplay MultiLut_ninjafadaGameplay.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_NFGTextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmountLow
#elif MultiLUTTexture3_Source == 7 // seri14 MultiLut_seri14.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_S14TextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmountLower
#elif MultiLUTTexture3_Source == 8 // Yomi MultiLut_Yomi.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_YOMTextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmountEx
#elif MultiLUTTexture3_Source == 9 // Neneko MultiLut_Neneko.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_NENTextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmountLow
#elif MultiLUTTexture3_Source == 10 // Yaes MultiLut_yaes.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_YAETextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmountLow
#elif MultiLUTTexture3_Source == 11 // Ipsusu MultiLut_Ipsusu.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_IPSTextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmount
#elif MultiLUTTexture3_Source == 12 // Nightingale MultiLut_Nightingale.png
    #define _SOURCE_MULTILUT_FILE3 fLUT_NGETextureName
    #define _SOURCE_MULTILUT_AMOUNT3 fLUT_LutAmountLow
#endif

texture texMultiLUT < source = _SOURCE_MULTILUT_FILE; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * _SOURCE_MULTILUT_AMOUNT; Format = RGBA8; };
sampler SamplerMultiLUT { Texture = texMultiLUT; };

#if MultiLUTTexture2
    texture texMultiLUT2 < source = _SOURCE_MULTILUT_FILE2; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * _SOURCE_MULTILUT_AMOUNT2; Format = RGBA8; };
    sampler SamplerMultiLUT2{ Texture = texMultiLUT2; };
#endif

#if MultiLUTTexture3
    texture texMultiLUT3 < source = _SOURCE_MULTILUT_FILE3; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * _SOURCE_MULTILUT_AMOUNT3; Format = RGBA8; };
    sampler SamplerMultiLUT3{ Texture = texMultiLUT3; };
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float4 apply(in const float4 color, in const int tex, in const float lut)
{
    const float2 texelsize = 1.0 / float2(fLUT_TileSizeXY * fLUT_TileAmount, fLUT_TileSizeXY);
    float3 lutcoord = float3((color.xy * fLUT_TileSizeXY - color.xy + 0.5) * texelsize, (color.z  * fLUT_TileSizeXY - color.z));

    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;
    lutcoord.y = lut / _SOURCE_MULTILUT_AMOUNT + lutcoord.y / _SOURCE_MULTILUT_AMOUNT;

    return float4(lerp(tex2D(SamplerMultiLUT, lutcoord.xy), tex2D(SamplerMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact).rgb, color.a);
}

#if MultiLUTTexture2
float4 apply2(in const float4 color, in const int tex, in const float lut)
{
    const float2 texelsize = 1.0 / float2(fLUT_TileSizeXY * fLUT_TileAmount, fLUT_TileSizeXY);
    float3 lutcoord = float3((color.xy * fLUT_TileSizeXY - color.xy + 0.5) * texelsize, (color.z * fLUT_TileSizeXY - color.z));

    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;
    lutcoord.y = lut / _SOURCE_MULTILUT_AMOUNT2 + lutcoord.y / _SOURCE_MULTILUT_AMOUNT2;

    return float4(lerp(tex2D(SamplerMultiLUT2, lutcoord.xy), tex2D(SamplerMultiLUT2, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact).rgb, color.a);
}
#endif

#if MultiLUTTexture3
float4 apply3(in const float4 color, in const int tex, in const float lut)
{
    const float2 texelsize = 1.0 / float2(fLUT_TileSizeXY * fLUT_TileAmount, fLUT_TileSizeXY);
    float3 lutcoord = float3((color.xy * fLUT_TileSizeXY - color.xy + 0.5) * texelsize, (color.z * fLUT_TileSizeXY - color.z));

    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;
    lutcoord.y = lut / _SOURCE_MULTILUT_AMOUNT3 + lutcoord.y / _SOURCE_MULTILUT_AMOUNT3;

    return float4(lerp(tex2D(SamplerMultiLUT3, lutcoord.xy), tex2D(SamplerMultiLUT3, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact).rgb, color.a);
}
#endif

void PS_MultiLUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target)
{
    const float4 color = tex2D(ReShade::BackBuffer, texcoord);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Pass 1
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#if !MultiLUTTexture2 && !MultiLUTTexture3
    const float4 lutcolor = lerp(color, apply(color, fLUT_MultiLUTSelector, fLUT_LutSelector), fLUT_Intensity);
#else
    float4 lutcolor = lerp(color, apply(color, fLUT_MultiLUTSelector, fLUT_LutSelector), fLUT_Intensity);
#endif

    res = lerp(normalize(color), normalize(lutcolor), fLUT_AmountChroma)
        * lerp(   length(color),    length(lutcolor),   fLUT_AmountLuma);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Pass 2
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#if MultiLUTTexture2
    res = saturate(res);
    lutcolor = lerp(res, apply2(res, fLUT_MultiLUTSelector2, fLUT_LutSelector2), fLUT_Intensity2);

    res = lerp(normalize(res), normalize(lutcolor), fLUT_AmountChroma2)
        * lerp(   length(res),    length(lutcolor),   fLUT_AmountLuma2);
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Pass 3
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#if MultiLUTTexture3
    res = saturate(res);
    lutcolor = lerp(res, apply3(res, fLUT_MultiLUTSelector3, fLUT_LutSelector3), fLUT_Intensity3);

    res = lerp(normalize(res), normalize(lutcolor), fLUT_AmountChroma3)
        * lerp(   length(res),    length(lutcolor),   fLUT_AmountLuma3);
#endif
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

technique MultiLUT
{
    pass MultiLUT_Apply
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MultiLUT_Apply;
    }
}
