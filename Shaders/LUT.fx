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

#ifndef fLUT_TextureName
	#define fLUT_TextureName "lut_GShade.png"
#endif
#ifndef fLUT_TileSizeXY
	#define fLUT_TileSizeXY 32
#endif
#ifndef fLUT_TileAmount
	#define fLUT_TileAmount 32
#endif
#ifndef fLUT_W_TextureName
	#define fLUT_W_TextureName "lut_warm.png"
#endif
#ifndef fLUT_W_TileSizeXY
	#define fLUT_W_TileSizeXY 64
#endif
#ifndef fLUT_W_TileAmount
	#define fLUT_W_TileAmount 64
#endif
#ifndef fLUT_A_TextureName
	#define fLUT_A_TextureName "lut.png"
#endif
#ifndef fLUT_NFG_TextureName
	#define fLUT_NFG_TextureName "lut_ninjafadaGameplay.png"
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int fLUT_Selector <
  ui_type = "combo";
  ui_items = "Standard\0LUT - Warm.fx\0Autumn\0ninjafada Gameplay\0";
  ui_label = "The LUT file to use.";
  ui_tooltip = "Set this to whichever your preset requires!";
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
texture texLUT < source = fLUT_TextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUT 	{ Texture = texLUT; };

texture texLUTwarm < source = fLUT_W_TextureName; > { Width = fLUT_W_TileSizeXY*fLUT_W_TileAmount; Height = fLUT_W_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTwarm 	{ Texture = texLUTwarm; };

texture texLUTautumn < source = fLUT_A_TextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_W_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTautumn 	{ Texture = texLUTautumn; };

texture texLUTNFG < source = fLUT_NFG_TextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTNFG 	{ Texture = texLUTNFG; };

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_LUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 res : SV_Target0)
{
  float4 color = tex2D(ReShade::BackBuffer, texcoord.xy);

//Default ReShade 3-4 LUT
  if (fLUT_Selector == 0)
  {
    float2 texelsize = 1.0 / fLUT_TileSizeXY;
    texelsize.x /= fLUT_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
    float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    float3 lutcolor = lerp(tex2D(SamplerLUT, lutcoord.xy).xyz, tex2D(SamplerLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }
  
  else if (fLUT_Selector == 1)
  {
    float2 texelsize = 1.0 / fLUT_W_TileSizeXY;
    texelsize.x /= fLUT_W_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_W_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_W_TileSizeXY-color.z);
    float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    float3 lutcolor = lerp(tex2D(SamplerLUTwarm, lutcoord.xy).xyz, tex2D(SamplerLUTwarm, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }

//LUT from LUT - Warm.fx
  else if (fLUT_Selector == 2)
  {
    float2 texelsize = 1.0 / fLUT_TileSizeXY;
    texelsize.x /= fLUT_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
    float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    float3 lutcolor = lerp(tex2D(SamplerLUTautumn, lutcoord.xy).xyz, tex2D(SamplerLUTautumn, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }

//ninjafada Gameplay LUT
  else
  {
    float2 texelsize = 1.0 / fLUT_TileSizeXY;
    texelsize.x /= fLUT_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
    float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    float3 lutcolor = lerp(tex2D(SamplerLUTNFG, lutcoord.xy).xyz, tex2D(SamplerLUTNFG, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }
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