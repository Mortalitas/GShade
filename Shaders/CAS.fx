// LICENSE
// =======
// Copyright (c) 2017-2019 Advanced Micro Devices, Inc. All rights reserved.
// -------
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// -------
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// -------
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

//Initial port to ReShade: SLSNe	https://gist.github.com/SLSNe/bbaf2d77db0b2a2a0755df581b3cf00c

//Optimizations by Marty McFly:
//	vectorized math, even with scalar gcn hardware this should work
//	out the same, order of operations has not changed
//	For some reason, it went from 64 to 48 instructions, a lot of MOV gone
//	Also modified the way the final window is calculated
//	  
//	reordered min() and max() operations, from 11 down to 9 registers	
//
//	restructured final weighting, 49 -> 48 instructions
//
//     delayed RCP to replace SQRT with RSQRT
//
//	removed the saturate() from the control var as it is clamped
//	by UI manager already, 48 -> 47 instructions
//
//	replaced tex2D with tex2Doffset intrinsic (address offset by immediate integer)
//	47 -> 43 instructions
//	9 -> 8 registers

//Further modified by OopyDoopy and Lord of Lunacy:
//	Changed wording in the UI for the existing variable and added a new variable and relevant code to adjust sharpening strength.

//Fix by Lord of Lunacy:
//	Made the shader use a linear colorspace rather than sRGB, as recommended by the original AMD documentation from FidelityFX.

//Modified by CeeJay.dk:
//	Included a label and tooltip description. I followed AMDs official naming guidelines for FidelityFX.
//
//	Used gather trick to reduce the number of texture operations by one (9 -> 8). It's now 42 -> 51 instructions but still faster
//	because of the texture operation that was optimized away.

//Fix by CeeJay.dk
//	Fixed precision issues with the gather at super high resolutions
//	Also tried to refactor the samples so more work can be done while they are being sampled, but it's not so easy and the gains
//	I'm seeing are so small they might be statistical noise. So it MIGHT be faster - no promises.

uniform float Contrast <
	ui_type = "slider";
	ui_label = "Contrast Adaptation";
	ui_tooltip = "Adjusts the range the shader adapts to high contrast (0 is not all the way off).  Higher values = more high contrast sharpening.";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

uniform float Sharpening <
	ui_type = "slider";
	ui_label = "Sharpening intensity";
	ui_tooltip = "Adjusts sharpening intensity by averaging the original pixels to the sharpened result.  1.0 is the unmodified default.";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

#include "ReShade.fxh"
#define pixel float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

texture TexCASColor : COLOR;
sampler sTexCASColor {Texture = TexCASColor; SRGBTexture = true;};

float3 CASPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{	
	// fetch a 3x3 neighborhood around the pixel 'e',
	//  a b c
	//  d(e)f
	//  g h i
	

	const float3 b = tex2Doffset(sTexCASColor, texcoord, int2(0, -1)).rgb;
	const float3 d = tex2Doffset(sTexCASColor, texcoord, int2(-1, 0)).rgb;
	
 
#if __RENDERER__ >= 0xa000 // If DX10 or higher
	const float4 red_efhi = tex2DgatherR(sTexCASColor, texcoord + 0.5 * pixel);
	const float4 green_efhi = tex2DgatherG(sTexCASColor, texcoord + 0.5 * pixel);
	const float4 blue_efhi = tex2DgatherB(sTexCASColor, texcoord + 0.5 * pixel);

	const float3 e = float3( red_efhi.w, green_efhi.w, blue_efhi.w);
	const float3 f = float3( red_efhi.z, green_efhi.z, blue_efhi.z);
	const float3 h = float3( red_efhi.x, green_efhi.x, blue_efhi.x);
	const float3 i = float3( red_efhi.y, green_efhi.y, blue_efhi.y);


#else // If DX9
	const float3 e = tex2D(sTexCASColor, texcoord).rgb;
	const float3 f = tex2Doffset(sTexCASColor, texcoord, int2(1, 0)).rgb;

	const float3 h = tex2Doffset(sTexCASColor, texcoord, int2(0, 1)).rgb;
	const float3 i = tex2Doffset(sTexCASColor, texcoord, int2(1, 1)).rgb;

#endif

	const float3 g = tex2Doffset(sTexCASColor, texcoord, int2(-1, 1)).rgb; 
	const float3 a = tex2Doffset(sTexCASColor, texcoord, int2(-1, -1)).rgb;
	const float3 c = tex2Doffset(sTexCASColor, texcoord, int2(1, -1)).rgb;
   

	// Soft min and max.
	//  a b c			 b
	//  d e f * 0.5  +  d e f * 0.5
	//  g h i			 h
	// These are 2.0x bigger (factored out the extra multiply).
	float3 mnRGB = min(min(min(d, e), min(f, b)), h);
	mnRGB += min(mnRGB, min(min(a, c), min(g, i)));

	float3 mxRGB = max(max(max(d, e), max(f, b)), h);
	mxRGB += max(mxRGB, max(max(a, c), max(g, i)));

	// Smooth minimum distance to signal limit divided by smooth max.
	// Shaping amount of sharpening.
	const float3 wRGB = -rcp(rsqrt(saturate(min(mnRGB, 2.0 - mxRGB) * rcp(mxRGB))) * (-3.0 * Contrast + 8.0));

	//						  0 w 0
	//  Filter shape:		   w 1 w
	//						  0 w 0  
	return lerp(e, saturate((((b + d) + (f + h)) * wRGB + e) * rcp(4.0 * wRGB + 1.0)), Sharpening);
}

technique ContrastAdaptiveSharpen
	<
	ui_label = "AMD FidelityFX Contrast Adaptive Sharpening";
	ui_tooltip = 
	"CAS is a low overhead adaptive sharpening algorithm that AMD includes with their drivers.\n"
	"This port to Reshade works with all cards from all vendors,\n"
	"but cannot do the optional scaling that CAS is normally also capable of when activated in the AMD drivers.\n"
	"\n"
	"The algorithm adjusts the amount of sharpening per pixel to target an even level of sharpness across the image.\n"
	"Areas of the input image that are already sharp are sharpened less, while areas that lack detail are sharpened more.\n"
	"This allows for higher overall natural visual sharpness with fewer artifacts.";
	>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CASPass;
		SRGBWriteEnable = true;
	}
}
