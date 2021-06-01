/*
   WinUAE Mask Glow Shader
   
   Copyright (C) 2020 guest(r) - guest.r@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform int shadowMask <
	ui_type = "slider";
	ui_min = -1; ui_max = 10;
	ui_label = "CRT Mask Type";
	ui_tooltip = "CRT Mask Type";
> = 0;

uniform float MaskGamma <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 3.0;
	ui_label = "Mask Gamma";
	ui_tooltip = "Mask Gamma";
> = 2.2;

uniform float CGWG <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Mask 0,1,2,3 Strength";
	ui_tooltip = "Mask 0,1,2,3 Strength";
> = 0.33;

uniform float maskDark <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Mask Dark";
	ui_tooltip = "Mask Dark";
> = 0.50;

uniform float maskLight <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Mask Light";
	ui_tooltip = "Mask Light";
> = 1.40;

uniform float slotmask <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Slotmask Strength";
	ui_tooltip = "Slotmask Strength";
> = 0.0;

uniform int slotwidth <
	ui_type = "slider";
	ui_min = 2; ui_max = 6;
	ui_label = "Slot Mask Width";
	ui_tooltip = "Slot Mask Width";
> = 2; 

uniform int masksize <
	ui_type = "slider";
	ui_min = 1; ui_max = 2;
	ui_label = "CRT Mask Size";
	ui_tooltip = "CRT Mask Size";
> = 1; 

uniform int smasksize <
	ui_type = "slider";
	ui_min = 1; ui_max = 2;
	ui_label = "Slot Mask Size";
	ui_tooltip = "Slot Mask Size";
> = 1; 

uniform float bloom <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Bloom Strength";
	ui_tooltip = "Bloom Strength";
> = 0.0;

uniform float glow <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.25;
	ui_label = "Glow Strength";
	ui_tooltip = "Glow Strength";
> = 0.0;


uniform float glow_size <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 6.0;
	ui_label = "Glow Size";
	ui_tooltip = "Glow Size";
> = 1.0;



texture Shinra01L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler Shinra01SL { Texture = Shinra01L; MinFilter = Linear; MagFilter = Linear; }; 

texture Shinra02L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Shinra02SL { Texture = Shinra02L; MinFilter = Linear; MagFilter = Linear; }; 

texture Shinra03L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Shinra03SL { Texture = Shinra03L; MinFilter = Linear; MagFilter = Linear; };  


float4 PASS_SH0(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	return float4 (pow(abs(tex2D(ReShade::BackBuffer, uv).rgb), float3(1.0, 1.0, 1.0) * MaskGamma),1.0);
}


float4 PASS_SH1(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
		float4 color = tex2D(Shinra01SL, uv) * 0.382925;
		color += tex2D(Shinra01SL, uv + float2(1.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.241730;
		color += tex2D(Shinra01SL, uv - float2(1.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.241730;
		color += tex2D(Shinra01SL, uv + float2(2.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.060598;
		color += tex2D(Shinra01SL, uv - float2(2.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.060598;
		color += tex2D(Shinra01SL, uv + float2(3.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.005977;
		color += tex2D(Shinra01SL, uv - float2(3.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.005977;
		color += tex2D(Shinra01SL, uv + float2(4.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.000229;
		color += tex2D(Shinra01SL, uv - float2(4.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.000229;
		color += tex2D(Shinra01SL, uv + float2(5.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.000003;
		color += tex2D(Shinra01SL, uv - float2(5.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.000003;
		
	return color;
}

float4 PASS_SH2(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
		float4 color = tex2D(Shinra02SL, uv) * 0.382925;
		color += tex2D(Shinra02SL, uv + float2(0.0, 1.0*glow_size * ReShade::PixelSize.y)) * 0.241730;
		color += tex2D(Shinra02SL, uv - float2(0.0, 1.0*glow_size * ReShade::PixelSize.y)) * 0.241730;
		color += tex2D(Shinra02SL, uv + float2(0.0, 2.0*glow_size * ReShade::PixelSize.y)) * 0.060598;
		color += tex2D(Shinra02SL, uv - float2(0.0, 2.0*glow_size * ReShade::PixelSize.y)) * 0.060598;
		color += tex2D(Shinra02SL, uv + float2(0.0, 3.0*glow_size * ReShade::PixelSize.y)) * 0.005977;
		color += tex2D(Shinra02SL, uv - float2(0.0, 3.0*glow_size * ReShade::PixelSize.y)) * 0.005977;
		color += tex2D(Shinra02SL, uv + float2(0.0, 4.0*glow_size * ReShade::PixelSize.y)) * 0.000229;
		color += tex2D(Shinra02SL, uv - float2(0.0, 4.0*glow_size * ReShade::PixelSize.y)) * 0.000229;
		color += tex2D(Shinra02SL, uv + float2(0.0, 5.0*glow_size * ReShade::PixelSize.y)) * 0.000003;
		color += tex2D(Shinra02SL, uv - float2(0.0, 5.0*glow_size * ReShade::PixelSize.y)) * 0.000003;
		
	return color;
} 


#define double_slot  1.00     // Slot Mask Height (1.0 or 2.0)

 
// Shadow mask (4-7 from PD CRT Lottes shader).
float3 Mask(float2 pos, float3 c)
{
	pos = floor(pos/float(masksize));
	float3 mask = float3(maskDark, maskDark, maskDark);
	float mc;
	float mx;
	float fTemp;
	float adj;
	
	// No mask
	switch (shadowMask)
	{
		case -1:
			mask = float3(1.0,1.0,1.0);
			break;
		// Phosphor.
		case 0:
			pos.x = frac(pos.x*0.5);
			mc = 1.0 - CGWG;
			if (pos.x < 0.5) { mask.r = 1.1; mask.g = mc; mask.b = 1.1; }
			else { mask.r = mc; mask.g = 1.1; mask.b = mc; }
			break;
		// RGB Mask.
		case 1:
			pos.x = frac(pos.x/3.0);
			mc = 1.1 - CGWG;
			mask = float3(mc, mc, mc);
		
			if      (pos.x < 0.333) mask.r = 1.0;
			else if (pos.x < 0.666) mask.g = 1.0;
			else                    mask.b = 1.0;
			break;
		// Phosphor.
		case 2:
			pos.x = frac(pos.x*0.5);
			mc = 1.0 - CGWG;
			if (pos.x < 0.5) { mask.r = 1.1; mask.g = mc; mask.b = 1.1; }
			else { mask.r = mc; mask.g = 1.1; mask.b = mc; }
			break;
		// Phosphor.
		case 3:
			pos.x = frac((pos.x + pos.y)*0.5);
			mc = 1.0 - CGWG;
			if (pos.x < 0.5) { mask.r = 1.1; mask.g = mc; mask.b = 1.1; }
			else { mask.r = mc; mask.g = 1.1; mask.b = mc; }
			break;
		// Very compressed TV style shadow mask.
		case 4:
			float line1 = maskLight;
			float odd  = 0.0;

			if (frac(pos.x/6.0) < 0.5)
				odd = 1.0;
			if (frac((pos.y + odd)/2.0) < 0.5)
				line1 = maskDark;

			pos.x = frac(pos.x/3.0);
    
			if      (pos.x < 0.333) mask.r = maskLight;
			else if (pos.x < 0.666) mask.g = maskLight;
			else                    mask.b = maskLight;
		
			mask*=line1;
			break;
		// Aperture-grille.
		case 5:
			pos.x = frac(pos.x/3.0);

			if      (pos.x < 0.333) mask.r = maskLight;
			else if (pos.x < 0.666) mask.g = maskLight;
			else                    mask.b = maskLight;
			break;
		// Stretched VGA style shadow mask (same as prior shaders).
		case 6:
			pos.x += pos.y*3.0;
			pos.x  = frac(pos.x/6.0);

			if      (pos.x < 0.333) mask.r = maskLight;
			else if (pos.x < 0.666) mask.g = maskLight;
			else                    mask.b = maskLight;
			break;
		// VGA style shadow mask.
		case 7:
			pos.xy = floor(pos.xy*float2(1.0, 0.5));
			pos.x += pos.y*3.0;
			pos.x  = frac(pos.x/6.0);

			if      (pos.x < 0.333) mask.r = maskLight;
			else if (pos.x < 0.666) mask.g = maskLight;
			else                    mask.b = maskLight;
			break;
		// Alternate mask 8
		case 8:
			mx = max(max(c.r,c.g),c.b);
			fTemp = min( 1.25*max(mx-0.25,0.0)/(1.0-0.25) ,maskDark + 0.2*(1.0-maskDark)*mx);
			adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);	
			mask = float3(fTemp,fTemp,fTemp);
			pos.x = frac(pos.x/2.0);
			if  (pos.x < 0.5)
			{	mask.r  = adj;
				mask.b  = adj;
			}
			else     mask.g = adj;
			break;
		// Alternate mask 9
		case 9:
			mx = max(max(c.r,c.g),c.b);
			fTemp = min( 1.33*max(mx-0.25,0.0)/(1.0-0.25) ,maskDark + 0.225*(1.0-maskDark)*mx);
			adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);
			mask = float3(fTemp,fTemp,fTemp);
			pos.x = frac(pos.x/3.0);
			if      (pos.x < 0.333) mask.r = adj;
			else if (pos.x < 0.666) mask.g = adj;
			else                    mask.b = adj;
			break;
		// Alternate mask 10
		case 10:
			mx = max(max(c.r,c.g),c.b);
			const float maskTmp = min(1.6*max(mx-0.25,0.0)/(1.0-0.25) ,1.0 + 0.6*(1.0-mx));
			mask = float3(maskTmp,maskTmp,maskTmp);
			pos.x = frac(pos.x/2.0);
			const float mTemp = 1.0 + 0.6*(1.0-mx);
			if  (pos.x < 0.5) mask = float3(mTemp,mTemp,mTemp);
			break;
	}
	
	return mask;
}   


float SlotMask(float2 pos, float3 c)
{
	if (slotmask == 0.0) return 1.0;
	
	pos = floor(pos/float(smasksize));
	
	const float mx = pow(abs(max(max(c.r,c.g),c.b)),1.33);
	const float px = frac(pos.x/(float(slotwidth)*2.0));
	const float py = floor(frac(pos.y/(2.0*double_slot))*2.0*double_slot);
	const float slot_dark = lerp(1.0-slotmask, 1.0-0.80*slotmask, mx);
	float slot = 1.0 + 0.7*slotmask*(1.0-mx);
	if (py == 0.0 && px <  0.5) slot = slot_dark; else
	if (py == double_slot && px >= 0.5) slot = slot_dark;		
	
	return slot;
}


float3 WMASK(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{	
	float3 color = tex2D(Shinra01SL, uv).rgb;
	const float3 b11 = tex2D(Shinra03SL, uv).rgb;
	
	const float2 pos1 = floor(uv/ReShade::PixelSize);
	
	const float3 cmask = Mask(pos1, pow(abs(color), float3(1.0,1.0,1.0)/MaskGamma));
	
	const float3 orig1 = color;
	
	if (shadowMask == 0 || shadowMask == 1 || shadowMask == 3) color = pow(abs(color), float3(1.0,1.0,1.0)/MaskGamma);
	
	color*=cmask;

	if (shadowMask == 0 || shadowMask == 1 || shadowMask == 3) color = pow(abs(color), float3(1.0,1.0,1.0)*MaskGamma);
	
	color = min(color, 1.0);
	
	color*=SlotMask(pos1, color);

	float3 Bloom1 = 2.0*b11*b11;
	Bloom1 = min(Bloom1, 0.75);
	Bloom1 = min(Bloom1, 0.85*max(max(Bloom1.r,Bloom1.g),Bloom1.b))/0.85;
	
	Bloom1 = lerp(min( Bloom1, color), Bloom1, 0.5*(orig1+color));
	
	Bloom1 = bloom*Bloom1;
	
	color = color + Bloom1;
	color = color + glow*b11;
	
	color = min(color, 1.0); 
	
	color = min(color, lerp(min(cmask,1.0),float3(1.0,1.0,1.0),0.6));
	
	color = pow(abs(color), float3(1.0,1.0,1.0)/MaskGamma);
	
#if GSHADE_DITHER
	return color + TriDither(color, uv, BUFFER_COLOR_BIT_DEPTH);
#else
	return color;
#endif
}

technique WinUaeMask
{
	
	pass bloom1
	{
		VertexShader = PostProcessVS;
		PixelShader = PASS_SH0;
		RenderTarget = Shinra01L; 		
	}
	
	pass bloom2
	{
		VertexShader = PostProcessVS;
		PixelShader = PASS_SH1;
		RenderTarget = Shinra02L; 		
	}

	pass bloom3
	{
		VertexShader = PostProcessVS;
		PixelShader = PASS_SH2;
		RenderTarget = Shinra03L; 		
	}	 
	
	pass mask
	{
		VertexShader = PostProcessVS;
		PixelShader = WMASK;
	}
}
