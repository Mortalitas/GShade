//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Multi-LUT shader, using a texture atlas with multiple LUTs
// by Otis / Infuse Project.
// Based on Marty's LUT shader 1.0 for ReShade 3.0
// Copyright © 2008-2016 Marty McFly
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#ifndef faLUT_TextureName
	#define faLUT_TextureName "Faustus86_MultiLUT.png"
#endif
#ifndef faLUT_TileSizeXY
	#define faLUT_TileSizeXY 32
#endif
#ifndef faLUT_TileAmount
	#define faLUT_TileAmount 32
#endif
#ifndef faLUT_LutAmount
	#define faLUT_LutAmount 82
#endif

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

uniform int faLUT_LutSelector < 
	ui_type = "combo";
	ui_items="Neutral\0Color1\0Color2\0Color3 (Blue oriented)\0Color4 (Hollywood)\0Color5\0Color6\0Color7\0Color8\0Cool light\0Flat & green\0Red lift matte\0Cross process\0Azure Red Dual Tone\0Sepia\0B&W mid constrast\0B&W high contrast\0Bleak Tension\0Bleak Bright\0Boba\0Bobs Fallout\0Bobs Bright\0Arabica\0Ava\0Azrael\0test\0Bleach Bypass\0Bourbon\0Byers\0Candelight\0Chemical\0Clayton\0Clouseu\0Cobi\0Contrail\0Crisb Warm\0Crisb Winter\0Cubicle\0Django\0Domingo\0Drop Blues\0Egypt Ember\0Faded\0Fall Colors\0FGCine Basic\0FGCine Bright\0FGCine Cold\0FGCine Drama\0FGCine TealOrange\0FGCine TealOrange2\0FGCine Vibrant\0FGCine Warm\0Filmstock\0Foggy Night\0Folger\0Fusion\0Futuristic Bleak\0Horror Blue\0Hyla\0Korben\0Late Sunset\0Lenox\0Lucky\0MCKinnon\0Milo\0Moonlight\0Neon\0Night from Day\0Paladin\0Pasadena\0Pitaja\0Reeve\0Remy\0Soft Warming\0Sprocket\0Teal Orange Contrast\0Teigen\0Tension Green\0Trent\0Tweet\0Vireo\0Zed\0Zeke\0";
	ui_label = "The LUT to use";
	ui_tooltip = "The LUT to use for color transformation. 'Neutral' doesn't do any color transformation.";
> = 0;

uniform float faLUT_AmountChroma <
  ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "LUT chroma amount";
	ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float faLUT_AmountLuma <
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

texture texFaMultiLUT < source = faLUT_TextureName; > { Width = faLUT_TileSizeXY*faLUT_TileAmount; Height = faLUT_TileSizeXY * faLUT_LutAmount; Format = RGBA8; };
sampler	SamplerFaMultiLUT { Texture = texFaMultiLUT; };

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

void PS_MultiLUT_Apply(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float3 res : SV_Target0)
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord.xy).xyz;
	float2 texelsize = 1.0 / faLUT_TileSizeXY;
	texelsize.x /= faLUT_TileAmount;

	float3 lutcoord = float3((color.xy*faLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*faLUT_TileSizeXY-color.z);
	lutcoord.y /= faLUT_LutAmount;
	lutcoord.y += (float(faLUT_LutSelector)/ faLUT_LutAmount);
	const float lerpfact = frac(lutcoord.z);
	lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;

	const float3 lutcolor = lerp(tex2D(SamplerFaMultiLUT, lutcoord.xy).xyz, tex2D(SamplerFaMultiLUT, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz, lerpfact);

	res.xyz = lerp(normalize(color.xyz), normalize(lutcolor.xyz), faLUT_AmountChroma) * 
	            lerp(length(color.xyz),    length(lutcolor.xyz),    faLUT_AmountLuma);

#if GSHADE_DITHER
	res += TriDither(res, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


technique MultiLUTFaustus < ui_label = "Faustus86 MultiLUT"; >
{
	pass MultiLUT_Apply
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_MultiLUT_Apply;
	}
}
