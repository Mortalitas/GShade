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

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int fLUT_Selector <
  ui_type = "combo";
  ui_items = "GShade/Angelite\0LUT - Warm.fx\0Autumn\0ninjafada Gameplay\0ReShade 3/4\0Sleeps_Hungry\0Feli\0";
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

texture texLUTautumn < source = fLUT_A_TextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTautumn 	{ Texture = texLUTautumn; };

texture texLUTNFG < source = fLUT_NFG_TextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTNFG 	{ Texture = texLUTNFG; };

texture texLUTRS < source = fLUT_RS_TextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTRS 	{ Texture = texLUTRS; };

texture texLUTSL < source = fLUT_SL_TextureName; > { Width = fLUT_W_TileSizeXY*fLUT_W_TileAmount; Height = fLUT_W_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTSL 	{ Texture = texLUTSL; };

texture texLUTFE < source = fLUT_FE_TextureName; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTFE 	{ Texture = texLUTFE; };

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
    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    const float3 lutcolor = lerp(tex2D(SamplerLUT, lutcoord.xy).xyz, tex2D(SamplerLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }

//LUT from LUT - Warm.fx
  else if (fLUT_Selector == 1)
  {
    float2 texelsize = 1.0 / fLUT_W_TileSizeXY;
    texelsize.x /= fLUT_W_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_W_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_W_TileSizeXY-color.z);
    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    const float3 lutcolor = lerp(tex2D(SamplerLUTwarm, lutcoord.xy).xyz, tex2D(SamplerLUTwarm, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }

//MS Autumn LUT
  else if (fLUT_Selector == 2)
  {
    float2 texelsize = 1.0 / fLUT_TileSizeXY;
    texelsize.x /= fLUT_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    const float3 lutcolor = lerp(tex2D(SamplerLUTautumn, lutcoord.xy).xyz, tex2D(SamplerLUTautumn, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }

//ninjafada Gameplay LUT
  else if (fLUT_Selector == 3)
  {
    float2 texelsize = 1.0 / fLUT_TileSizeXY;
    texelsize.x /= fLUT_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    const float3 lutcolor = lerp(tex2D(SamplerLUTNFG, lutcoord.xy).xyz, tex2D(SamplerLUTNFG, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }
  else if (fLUT_Selector == 4)
  {
    float2 texelsize = 1.0 / fLUT_TileSizeXY;
    texelsize.x /= fLUT_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    const float3 lutcolor = lerp(tex2D(SamplerLUTRS, lutcoord.xy).xyz, tex2D(SamplerLUTRS, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }
  else if (fLUT_Selector == 5)
  {
    float2 texelsize = 1.0 / fLUT_W_TileSizeXY;
    texelsize.x /= fLUT_W_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_W_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_W_TileSizeXY-color.z);
    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    const float3 lutcolor = lerp(tex2D(SamplerLUTSL, lutcoord.xy).xyz, tex2D(SamplerLUTSL, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

    color.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), fLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    fLUT_AmountLuma);

    res.xyz = color.xyz;
    res.w = 1.0;
  }

  else
  {
    float2 texelsize = 1.0 / fLUT_TileSizeXY;
    texelsize.x /= fLUT_TileAmount;

    float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
    const float lerpfact = frac(lutcoord.z);
    lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

    const float3 lutcolor = lerp(tex2D(SamplerLUTFE, lutcoord.xy).xyz, tex2D(SamplerLUTFE, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);

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