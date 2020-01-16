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
	ui_items = "GShade [Angelite-Compatible]\0ReShade 4\0ReShade 3\0Johto\0Espresso Glow\0Faeshade/Dark Veil/HQ Shade/MoogleShade\0ninjafada Gameplay\0seri14\0Yomi\0Neneko\0";
	ui_label = "The MultiLUT file to use.";
	ui_tooltip = "Set this to whatever build your preset was made with!";
> = 0;

uniform int fLUT_LutSelector < 
	ui_category = "Pass 1";
	ui_type = "combo";
	ui_items = "Color0 (Usually Neutral)\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10 | Colors above 10\0Color11 | may not work for\0Color12 | all MultiLUT files.\0Color13\0Color14\0Color15\0Color16\0Color17\0";
	ui_label = "LUT to use. Names may not be accurate.";
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
> = 0;

uniform int fLUT_MultiLUTSelector2 <
	ui_category = "Pass 2";
	ui_type = "combo";
	ui_items = "GShade [Angelite-Compatible]\0ReShade 4\0ReShade 3\0Johto\0Espresso Glow\0Faeshade/Dark Veil/HQ Shade/MoogleShade\0ninjafada Gameplay\0seri14\0Yomi\0Neneko\0";
	ui_label = "The MultiLUT file to use.";
	ui_tooltip = "The MultiLUT table to use on Pass 2.";
> = 1;

uniform int fLUT_LutSelector2 < 
	ui_category = "Pass 2";
	ui_type = "combo";
	ui_items = "Color0 (Usually Neutral)\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10 | Colors above 10\0Color11 | may not work for\0Color12 | all MultiLUT files.\0Color13\0Color14\0Color15\0Color16\0Color17\0";
	ui_label = "LUT to use. Names may not be accurate.";
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

uniform bool fLUT_MultiLUTPass3 <
	ui_category = "Pass 3";
	ui_label = "Enable Pass 3";
> = 0;

uniform int fLUT_MultiLUTSelector3 <
	ui_category = "Pass 3";
	ui_type = "combo";
	ui_items = "GShade [Angelite-Compatible]\0ReShade 4\0ReShade 3\0Johto\0Espresso Glow\0Faeshade/Dark Veil/HQ Shade/MoogleShade\0ninjafada Gameplay\0seri14\0Yomi\0Neneko\0";
	ui_label = "The MultiLUT file to use.";
	ui_tooltip = "The MultiLUT table to use on Pass 3.";
> = 1;

uniform int fLUT_LutSelector3 < 
	ui_category = "Pass 3";
	ui_type = "combo";
	ui_items = "Color0 (Usually Neutral)\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10 | Colors above 10\0Color11 | may not work for\0Color12 | all MultiLUT files.\0Color13\0Color14\0Color15\0Color16\0Color17\0";
	ui_label = "LUT to use. Names may not be accurate.";
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

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"

texture texGSMultiLUT < source = fLUT_GSTextureName; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmount; Format = RGBA8; };
sampler SamplerGSMultiLUT { Texture = texGSMultiLUT; };

texture texRESMultiLUT < source = fLUT_RESTextureName; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmount; Format = RGBA8; };
sampler SamplerRESMultiLUT { Texture = texRESMultiLUT; };

texture texJOHMultiLUT < source = fLUT_JOHTextureName; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmountEx; Format = RGBA8; };
sampler SamplerJOHMultiLUT { Texture = texJOHMultiLUT; };

texture texEGMultiLUT < source = fLUT_EGTextureName; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmount; Format = RGBA8; };
sampler SamplerEGMultiLUT { Texture = texEGMultiLUT; };

texture texMSMultiLUT < source = fLUT_MSTextureName; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmountLow; Format = RGBA8; };
sampler SamplerMSMultiLUT { Texture = texMSMultiLUT; };

texture texNFGMultiLUT < source = fLUT_NFGTextureName; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmountLow; Format = RGBA8; };
sampler SamplerNFGMultiLUT { Texture = texNFGMultiLUT; };

texture texS14MultiLUT < source = fLUT_S14TextureName; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmountLower; Format = RGBA8; };
sampler SamplerS14MultiLUT { Texture = texS14MultiLUT; };

texture texYOMMultiLUT < source = fLUT_YOMTextureName; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmountLow; Format = RGBA8; };
sampler SamplerYOMMultiLUT { Texture = texYOMMultiLUT; };

texture texNENMultiLUT < source = fLUT_NENTextureName; > { Width = fLUT_TileSizeXY * fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmountLow; Format = RGBA8; };
sampler SamplerNENMultiLUT { Texture = texNENMultiLUT; };

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

float4 apply(in const float4 color, in const int tex, in const float lut)
{
	const float2 texelsize = 1.0 / float2(fLUT_TileSizeXY * fLUT_TileAmount, fLUT_TileSizeXY);
	float3 lutcoord = float3((color.xy * fLUT_TileSizeXY - color.xy + 0.5) * texelsize, (color.z  * fLUT_TileSizeXY - color.z));
	float4 lutcolor;

	const float lerpfact = frac(lutcoord.z);
	lutcoord.x += (lutcoord.z - lerpfact) * texelsize.y;

//Default GShade MultiLut_GShade.png
	switch (fLUT_MultiLUTSelector)
	{
		// GShade/Angelite MultiLut_GShade.png
		default:
			lutcoord.y = lut / fLUT_LutAmount + lutcoord.y / fLUT_LutAmount;
			lutcolor   = lerp(tex2D(SamplerGSMultiLUT, lutcoord.xy), tex2D(SamplerGSMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
		//ReShade 4 MultiLut_atlas4.png
		case 1:
			lutcoord.y = lut / fLUT_LutAmount + lutcoord.y / fLUT_LutAmount;
			lutcolor = lerp(tex2D(SamplerRESMultiLUT, lutcoord.xy), tex2D(SamplerRESMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
		//ReShade 3 MultiLut_atlas4.png
		case 2:
			lutcoord.y = lut / fLUT_LutAmount + lutcoord.y / fLUT_LutAmount;
			lutcolor   = lerp(tex2D(SamplerRESMultiLUT, lutcoord.xy), tex2D(SamplerRESMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
		//Johto MultiLut_Johto.png
		case 3:
			lutcoord.y = lut / fLUT_LutAmountEx + lutcoord.y / fLUT_LutAmountEx;
			lutcolor   = lerp(tex2D(SamplerJOHMultiLUT, lutcoord.xy), tex2D(SamplerJOHMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
		//EG FFXIVLUTAtlas.png
		case 4:
			lutcoord.y = lut / fLUT_LutAmount + lutcoord.y / fLUT_LutAmount;
			lutcolor   = lerp(tex2D(SamplerEGMultiLUT, lutcoord.xy), tex2D(SamplerEGMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
		//MS TMP_MultiLUT.png
		case 5:
			lutcoord.y = lut / fLUT_LutAmountLow + lutcoord.y / fLUT_LutAmountLow;
			lutcolor   = lerp(tex2D(SamplerMSMultiLUT, lutcoord.xy), tex2D(SamplerMSMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
		//ninjafada Gameplay MultiLut_ninjafadaGameplay.png
		case 6:
			lutcoord.y = lut / fLUT_LutAmountLow + lutcoord.y / fLUT_LutAmountLow;
			lutcolor   = lerp(tex2D(SamplerNFGMultiLUT, lutcoord.xy), tex2D(SamplerNFGMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
		//seri14 MultiLut_seri14.png
		case 7:
			lutcoord.y = lut / fLUT_LutAmountLower + lutcoord.y / fLUT_LutAmountLower;
			lutcolor   = lerp(tex2D(SamplerS14MultiLUT, lutcoord.xy), tex2D(SamplerS14MultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
		//Yomi MultiLut_Yomi.png
		case 8:
			lutcoord.y = lut / fLUT_LutAmountLow + lutcoord.y / fLUT_LutAmountLow;
			lutcolor   = lerp(tex2D(SamplerYOMMultiLUT, lutcoord.xy), tex2D(SamplerYOMMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
		//Neneko MultiLut_Neneko.png
		case 9:
			lutcoord.y = lut / fLUT_LutAmountLow + lutcoord.y / fLUT_LutAmountLow;
			lutcolor   = lerp(tex2D(SamplerNENMultiLUT, lutcoord.xy), tex2D(SamplerNENMultiLUT, float2(lutcoord.x + texelsize.y, lutcoord.y)), lerpfact);
			break;
	}
	
	lutcolor.a = color.a;
	return lutcolor;
}

void PS_MultiLUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target)
{
	const float4 color = tex2D(ReShade::BackBuffer, texcoord);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Pass 1
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	float4 lutcolor = lerp(color, apply(color, fLUT_MultiLUTSelector, fLUT_LutSelector), fLUT_Intensity);

	res = lerp(normalize(color), normalize(lutcolor), fLUT_AmountChroma)
	    * lerp(   length(color),    length(lutcolor),   fLUT_AmountLuma);

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Pass 2
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	if (fLUT_MultiLUTPass2)
	{
		res = saturate(res);
		lutcolor = lerp(res, apply(res, fLUT_MultiLUTSelector2, fLUT_LutSelector2), fLUT_Intensity2);

		res = lerp(normalize(res), normalize(lutcolor), fLUT_AmountChroma2)
		    * lerp(   length(res),    length(lutcolor),   fLUT_AmountLuma2);
	}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  Pass 3
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	if (fLUT_MultiLUTPass3)
	{
		res = saturate(res);
		lutcolor = lerp(res, apply(res, fLUT_MultiLUTSelector3, fLUT_LutSelector3), fLUT_Intensity3);

		res = lerp(normalize(res), normalize(lutcolor), fLUT_AmountChroma3)
		    * lerp(   length(res),    length(lutcolor),   fLUT_AmountLuma3);
	}
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
