//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade 4.0 effect file
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Multi-LUT shader, using a texture atlas with multiple LUTs
// by Otis / Infuse Project.
// Based on Marty's LUT shader 1.0 for ReShade 3.0
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// MultiLut_GShade.png is a modified version of miiok's Angelite MultiLUT table made for GShade!
// Follow miiolk on Twitter here: https://twitter.com/miiolk
// And GPOSERS here: https://twitter.com/GPOSERS_FFXIV
// For GShade news and updates, join our Discord: https://twitter.com/GPOSERS_FFXIV
//
// MultiLut_Johto.png was provided by Johto!
// Follow them on Twitter here: https://twitter.com/JohtoFFXIV
//
// FFXIVLUTAtlas.png was provided by Espresso Lalaqo'te from their Espresso Glow Build!
// Follow them on Twitter here: https://twitter.com/espressolala
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef fLUT_GSTextureName
	#define fLUT_GSTextureName "MultiLut_GShade.png"
#endif
#ifndef fLUT_RESTextureName
	#define fLUT_RESTextureName "MultiLut_atlas4.png"
#endif
#ifndef fLUT_JOHTextureName
	#define fLUT_JOHTextureName "MultiLut_Johto.png"
#endif
#ifndef fLUT_EGTextureName
	#define fLUT_EGTextureName "FFXIVLUTAtlas.png"
#endif
#ifndef fLUT_MSTextureName
	#define fLUT_MSTextureName "TMP_MultiLUT.png"
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

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int fLUT_MultiLUTSelector <
  ui_type = "combo";
  ui_items = "GShade [Angelite-Compatible]\0ReShade 4\0ReShade 3\0Johto\0Espresso Glow\0MS\0";
  ui_label = "The MultiLUT file to use.";
  ui_tooltip = "Set this to whatever build your preset was made with!";
> = 0;

uniform int fLUT_LutSelector < 
	ui_type = "combo";
	ui_items="Color0\0Color1\0Color2\0Color3\0Color4\0Color5\0Color6\0Color7\0Color8\0Color9\0Color10\0Color11\0Color12\0Color13\0Sepia\0\B&W mid constrast\0\B&W high contrast\0\An Extra One for Johto lol\0";
	ui_label = "LUT to use. Names may not be accurate.";
	ui_tooltip = "LUT to use for color transformation. 'Neutral' doesn't do any color transformation.";
> = 0;

uniform float fLUT_AmountChroma <
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "LUT chroma amount.";
	ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float fLUT_AmountLuma <
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "LUT luma amount.";
	ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#include "ReShade.fxh"
texture texGSMultiLUT < source = fLUT_GSTextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmount; Format = RGBA8; };
sampler	SamplerGSMultiLUT { Texture = texGSMultiLUT; };

texture texRESMultiLUT < source = fLUT_RESTextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmount; Format = RGBA8; };
sampler	SamplerRESMultiLUT { Texture = texRESMultiLUT; };

texture texJOHMultiLUT < source = fLUT_JOHTextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmountEx; Format = RGBA8; };
sampler	SamplerJOHMultiLUT { Texture = texJOHMultiLUT; };

texture texEGMultiLUT < source = fLUT_EGTextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmount; Format = RGBA8; };
sampler	SamplerEGMultiLUT { Texture = texEGMultiLUT; };

texture texMSMultiLUT < source = fLUT_MSTextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY * fLUT_LutAmountLow; Format = RGBA8; };
sampler	SamplerMSMultiLUT { Texture = texMSMultiLUT; };

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_MultiLUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
	float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);
	float2 texelsize = 1.0 / fLUT_TileSizeXY;
	texelsize.x /= fLUT_TileAmount;
	float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);

//Default GShade MultiLut_GShade.png
	if (fLUT_MultiLUTSelector == 0)
	{
    lutcoord.y /= fLUT_LutAmount;
    lutcoord.y += (float(fLUT_LutSelector)/ fLUT_LutAmount);
    float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;
    float3 lutcolor = lerp(tex2D(SamplerGSMultiLUT, lutcoord.xy).xyz, tex2D(SamplerGSMultiLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);
    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);
    res.xyz = color.xyz;
    res.w = 1.0;
	}

//ReShade 4/3 MultiLut_atlas4.png
	else if (fLUT_MultiLUTSelector == 1 || 2)
	{
    lutcoord.y /= fLUT_LutAmount;
    lutcoord.y += (float(fLUT_LutSelector)/ fLUT_LutAmount);
    float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;
    float3 lutcolor = lerp(tex2D(SamplerRESMultiLUT, lutcoord.xy).xyz, tex2D(SamplerRESMultiLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);
    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);
    res.xyz = color.xyz;
    res.w = 1.0;
	}

//Johto MultiLut_Johto.png
	else if (fLUT_MultiLUTSelector == 3)
	{
    lutcoord.y /= fLUT_LutAmountEx;
    lutcoord.y += (float(fLUT_LutSelector)/ fLUT_LutAmountEx);
    float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;
    float3 lutcolor = lerp(tex2D(SamplerJOHMultiLUT, lutcoord.xy).xyz, tex2D(SamplerJOHMultiLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);
    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);
    res.xyz = color.xyz;
    res.w = 1.0;
	}

//EG FFXIVLUTAtlas.png
	else if (fLUT_MultiLUTSelector == 4)
	{
    lutcoord.y /= fLUT_LutAmount;
    lutcoord.y += (float(fLUT_LutSelector)/ fLUT_LutAmount);
    float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;
    float3 lutcolor = lerp(tex2D(SamplerEGMultiLUT, lutcoord.xy).xyz, tex2D(SamplerEGMultiLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);
    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);
    res.xyz = color.xyz;
    res.w = 1.0;
	}

//MS TMP_MultiLUT.png
	else
	{
    lutcoord.y /= fLUT_LutAmountLow;
    lutcoord.y += (float(fLUT_LutSelector)/ fLUT_LutAmountLow);
    float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;
    float3 lutcolor = lerp(tex2D(SamplerMSMultiLUT, lutcoord.xy).xyz, tex2D(SamplerMSMultiLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);
    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);
    res.xyz = color.xyz;
    res.w = 1.0;
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