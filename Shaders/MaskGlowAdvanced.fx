/*
   Mask Glow Shader (Advanced)
   
   Copyright (C) 2020-2022 guest(r)

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


uniform float aarange  <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 4.0; ui_step = 0.05;
	ui_label = "Smoothing/AA range";
	ui_tooltip = "Smoothing/AA range";
> = 1.0;

uniform float gamma_c  <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0; ui_step = 0.05;
	ui_label = "Gamma Correct";
	ui_tooltip = "Gamma Correct";
> = 1.0;

uniform float brightboost  <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0; ui_step = 0.01;
	ui_label = "Bright Boost";
	ui_tooltip = "Bright Boost";
> = 1.0;

uniform float saturation  <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.5; ui_step = 0.01;
	ui_label = "Saturation Adjustment";
	ui_tooltip = "Saturation Adjustment";
> = 1.0;

uniform float warpX  <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.5;
	ui_label = "CurvatureX";
	ui_tooltip = "CurvatureX";
> = 0.0;

uniform float warpY  <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.5;
	ui_label = "CurvatureY";
	ui_tooltip = "CurvatureY";
> = 0.0;

uniform float c_shape  <
	ui_type = "slider";
	ui_min = 0.05; ui_max = 0.6;
	ui_label = "Curvature Shape";
	ui_tooltip = "Curvature Shape";
> = 0.25;

uniform float bsize1  <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 3.0;
	ui_label = "Border Size";
	ui_tooltip = "Border Size";
> = 0.02;

uniform float sborder  <
	ui_type = "slider";
	ui_min = 0.25; ui_max = 2.0;
	ui_label = "Border Intensity";
	ui_tooltip = "Border Intensity";
> = 0.75;

uniform int shadowMask <
	ui_type = "slider";
	ui_min = -1; ui_max = 12;
	ui_label = "CRT Mask Type";
	ui_tooltip = "CRT Mask Type";
> = 0;

uniform float MaskGamma <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 3.0; ui_step = 0.05;
	ui_label = "Mask Gamma";
	ui_tooltip = "Mask Gamma";
> = 2.2;

uniform float maskstr <
	ui_type = "slider";
	ui_min = -0.5; ui_max = 1.0; ui_step = 0.05;
	ui_label = "Mask Strength masks: 0, 5-12";
	ui_tooltip = "Mask Strength masks: 0, 5-12";
> = 0.33;

uniform float mcut <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.05;
	ui_label = "Mask Strength Low (masks: 0, 5-12)";
	ui_tooltip = "Mask Strength Low (masks: 0, 5-12)";
> = 1.10;

uniform float maskboost <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 3.0; ui_step = 0.05;
	ui_label = "CRT Mask Boost";
	ui_tooltip = "CRT Mask Boost";
> = 1.0;

uniform float mshift <
	ui_type = "drag";
	ui_min = -8.0;
	ui_max = 8.0;
	ui_step = 0.5;
	ui_label = "Mask Shift/Stagger";
> = 0.0;

uniform int mask_layout <
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_label = "Mask Layout: RGB or BGR (check LCD panel)";
	ui_tooltip = "Mask Layout: RGB or BGR (check LCD panel)";
> = 0;

uniform float maskDark <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.05;
	ui_label = "Mask Dark (masks 1-4)";
	ui_tooltip = "Mask Dark (masks 1-4)";
> = 0.50;

uniform float maskLight <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.05;
	ui_label = "Mask Light";
	ui_tooltip = "Mask Light";
> = 1.50;

uniform float slotmask <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
	ui_label = "Slotmask Strength Bright Pixels";
	ui_tooltip = "Slotmask Strength Bright Pixels";
> = 0.0;

uniform float slotmask1 <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
	ui_label = "Slotmask Strength Dark Pixels";
	ui_tooltip = "Slotmask Strength Dark Pixels";
> = 0.0;

uniform int slotwidth <
	ui_type = "slider";
	ui_min = 1; ui_max = 8;
	ui_label = "Slot Mask Width";
	ui_tooltip = "Slot Mask Width";
> = 2;

uniform int double_slot <
	ui_type = "slider";
	ui_min = 1; ui_max = 4;
	ui_label = "Slot Mask Heigth";
	ui_tooltip = "Slot Mask Heigth";
> = 1;

uniform int masksize <
	ui_type = "slider";
	ui_min = 1; ui_max = 3;
	ui_label = "CRT Mask Size";
	ui_tooltip = "CRT Mask Size";
> = 1;

uniform int smasksize <
	ui_type = "slider";
	ui_min = 1; ui_max = 3;
	ui_label = "Slot Mask Size";
	ui_tooltip = "Slot Mask Size";
> = 1;

uniform float bloom <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.05;
	ui_label = "Bloom Strength";
	ui_tooltip = "Bloom Strength";
> = 0.0;

uniform float bdist <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 3.0; ui_step = 0.05;
	ui_label = "Bloom Distribution";
	ui_tooltip = "Bloom Distribution";
> = 1.0;

uniform float halation <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
	ui_label = "Halation Strength";
	ui_tooltip = "Halation Strength";
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
> = 2.0;


uniform float decons <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0; ui_step = 0.1;
	ui_label = "Deconvergence Strength";
	ui_tooltip = "Deconvergence Strength";
> = 1.0;


uniform float deconrr <
	ui_type = "slider";
	ui_min = -8.0; ui_max = 8.0; ui_step = 0.25;
	ui_label = "Deconvergence Red Horizontal";
	ui_tooltip = "Deconvergence Red Horizontal";
> = 0.0;

uniform float deconrg <
	ui_type = "slider";
	ui_min = -8.0; ui_max = 8.0; ui_step = 0.25;
	ui_label = "Deconvergence Green Horizontal";
	ui_tooltip = "Deconvergence Green Horizontal";
> = 0.0;

uniform float deconrb <
	ui_type = "slider";
	ui_min = -8.0; ui_max = 8.0; ui_step = 0.25;
	ui_label = "Deconvergence Blue Horizontal";
	ui_tooltip = "Deconvergence Blue Horizontal";
> = 0.0;

uniform float deconrry <
	ui_type = "slider";
	ui_min = -8.0; ui_max = 8.0; ui_step = 0.25;
	ui_label = "Deconvergence Red Vertical";
	ui_tooltip = "Deconvergence Red Vertical";
> = 0.0;

uniform float deconrgy <
	ui_type = "slider";
	ui_min = -8.0; ui_max = 8.0; ui_step = 0.25;
	ui_label = "Deconvergence Green Vertical";
	ui_tooltip = "Deconvergence Green Vertical";
> = 0.0;

uniform float deconrby <
	ui_type = "slider";
	ui_min = -8.0; ui_max = 8.0; ui_step = 0.25;
	ui_label = "Deconvergence Blue Vertical";
	ui_tooltip = "Deconvergence Blue Vertical";
> = 0.0;


texture ShinraAdvanced01L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler ShinraAdvanced01SL { Texture = ShinraAdvanced01L; MinFilter = Linear; MagFilter = Linear; };

texture ShinraAdvanced02L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler ShinraAdvanced02SL { Texture = ShinraAdvanced02L; MinFilter = Linear; MagFilter = Linear; };

texture ShinraAdvanced03L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
sampler ShinraAdvanced03SL { Texture = ShinraAdvanced03L; MinFilter = Linear; MagFilter = Linear; };

float3 plant (float3 tar, float r)
{
	const float t = max(max(tar.r,tar.g),tar.b) + 0.00001;
	return tar * r / t;
}

float4 PASS_SH0(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	const float x = ReShade::PixelSize.x * aarange;
	const float y = ReShade::PixelSize.y * aarange;
	const float2 dg1 = float2( x,y);
	const float2 dg2 = float2(-x,y);
	const float2 sd1 = dg1*0.5;
	const float2 sd2 = dg2*0.5;
	const float2 ddx = float2(x,0.0);
	const float2 ddy = float2(0.0,y);

	const float3 c11 = tex2D(ReShade::BackBuffer, uv).xyz;
	const float3 s00 = tex2D(ReShade::BackBuffer, uv - sd1).xyz;
	const float3 s20 = tex2D(ReShade::BackBuffer, uv - sd2).xyz;
	const float3 s22 = tex2D(ReShade::BackBuffer, uv + sd1).xyz;
	const float3 s02 = tex2D(ReShade::BackBuffer, uv + sd2).xyz;
	const float3 c00 = tex2D(ReShade::BackBuffer, uv - dg1).xyz;
	const float3 c22 = tex2D(ReShade::BackBuffer, uv + dg1).xyz;
	const float3 c20 = tex2D(ReShade::BackBuffer, uv - dg2).xyz;
	const float3 c02 = tex2D(ReShade::BackBuffer, uv + dg2).xyz;
	const float3 c10 = tex2D(ReShade::BackBuffer, uv - ddy).xyz;
	const float3 c21 = tex2D(ReShade::BackBuffer, uv + ddx).xyz;
	const float3 c12 = tex2D(ReShade::BackBuffer, uv + ddy).xyz;
	const float3 c01 = tex2D(ReShade::BackBuffer, uv - ddx).xyz;
	const float3 dt = float3(1.0,1.0,1.0);

	const float d1=dot(abs(c00-c22),dt)+0.0001;
	const float d2=dot(abs(c20-c02),dt)+0.0001;
	const float hl=dot(abs(c01-c21),dt)+0.0001;
	const float vl=dot(abs(c10-c12),dt)+0.0001;
	const float m1=dot(abs(s00-s22),dt)+0.0001;
	const float m2=dot(abs(s02-s20),dt)+0.0001;

	const float3 t1=(hl*(c10+c12)+vl*(c01+c21)+(hl+vl)*c11)/(3.0*(hl+vl));
	const float3 t2=(d1*(c20+c02)+d2*(c00+c22)+(d1+d2)*c11)/(3.0*(d1+d2));
	
	float3 color =.25*(t1+t2+(m2*(s00+s22)+m1*(s02+s20))/(m1+m2));

	const float3 scolor1 = plant(pow(max(color, 0.0), saturation.xxx), max(max(color.r,color.g),color.b));
	const float luma = dot(color, float3(0.299, 0.587, 0.114));
	const float3 scolor2 = lerp(luma.xxx, color, saturation);
	color = (saturation > 1.0) ? scolor1 : scolor2;

	return float4 (pow(max(color, 0.0), float3(1.0, 1.0, 1.0) * MaskGamma),1.0);
}


float4 PASS_SH1(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
		float4 color = tex2D(ShinraAdvanced01SL, uv) * 0.19744746769063704;
		color += tex2D(ShinraAdvanced01SL, uv + float2(1.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.1746973469158936;
		color += tex2D(ShinraAdvanced01SL, uv - float2(1.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.1746973469158936;
		color += tex2D(ShinraAdvanced01SL, uv + float2(2.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.12099884565428047;
		color += tex2D(ShinraAdvanced01SL, uv - float2(2.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.12099884565428047;
		color += tex2D(ShinraAdvanced01SL, uv + float2(3.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.06560233156931679;
		color += tex2D(ShinraAdvanced01SL, uv - float2(3.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.06560233156931679;
		color += tex2D(ShinraAdvanced01SL, uv + float2(4.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.027839605612666265;
		color += tex2D(ShinraAdvanced01SL, uv - float2(4.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.027839605612666265;
		color += tex2D(ShinraAdvanced01SL, uv + float2(5.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.009246250740395456;
		color += tex2D(ShinraAdvanced01SL, uv - float2(5.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.009246250740395456;
		color += tex2D(ShinraAdvanced01SL, uv + float2(6.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.002403157286908872;
		color += tex2D(ShinraAdvanced01SL, uv - float2(6.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.002403157286908872;
		color += tex2D(ShinraAdvanced01SL, uv + float2(7.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.00048872837522002;
		color += tex2D(ShinraAdvanced01SL, uv - float2(7.0*glow_size * ReShade::PixelSize.x, 0.0)) * 0.00048872837522002;
		
	return color;
}

float4 PASS_SH2(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
		float4 color = tex2D(ShinraAdvanced02SL, uv) * 0.19744746769063704;
		color += tex2D(ShinraAdvanced02SL, uv + float2(0.0, 1.0*glow_size * ReShade::PixelSize.y)) * 0.1746973469158936;
		color += tex2D(ShinraAdvanced02SL, uv - float2(0.0, 1.0*glow_size * ReShade::PixelSize.y)) * 0.1746973469158936;
		color += tex2D(ShinraAdvanced02SL, uv + float2(0.0, 2.0*glow_size * ReShade::PixelSize.y)) * 0.12099884565428047;
		color += tex2D(ShinraAdvanced02SL, uv - float2(0.0, 2.0*glow_size * ReShade::PixelSize.y)) * 0.12099884565428047;
		color += tex2D(ShinraAdvanced02SL, uv + float2(0.0, 3.0*glow_size * ReShade::PixelSize.y)) * 0.06560233156931679;
		color += tex2D(ShinraAdvanced02SL, uv - float2(0.0, 3.0*glow_size * ReShade::PixelSize.y)) * 0.06560233156931679;
		color += tex2D(ShinraAdvanced02SL, uv + float2(0.0, 4.0*glow_size * ReShade::PixelSize.y)) * 0.027839605612666265;
		color += tex2D(ShinraAdvanced02SL, uv - float2(0.0, 4.0*glow_size * ReShade::PixelSize.y)) * 0.027839605612666265;
		color += tex2D(ShinraAdvanced02SL, uv + float2(0.0, 5.0*glow_size * ReShade::PixelSize.y)) * 0.009246250740395456;
		color += tex2D(ShinraAdvanced02SL, uv - float2(0.0, 5.0*glow_size * ReShade::PixelSize.y)) * 0.009246250740395456;
		color += tex2D(ShinraAdvanced02SL, uv + float2(0.0, 6.0*glow_size * ReShade::PixelSize.y)) * 0.002403157286908872;
		color += tex2D(ShinraAdvanced02SL, uv - float2(0.0, 6.0*glow_size * ReShade::PixelSize.y)) * 0.002403157286908872;
		color += tex2D(ShinraAdvanced02SL, uv + float2(0.0, 7.0*glow_size * ReShade::PixelSize.y)) * 0.00048872837522002;
		color += tex2D(ShinraAdvanced02SL, uv - float2(0.0, 7.0*glow_size * ReShade::PixelSize.y)) * 0.00048872837522002;
		
	return color;
} 

float3 gc(float3 c)
{
	const float mc = max(max(c.r,c.g),c.b);
	const float mg = pow(max(mc, 0.0), 1.0/gamma_c);
	return c * mg/(mc + 1e-8);
} 
 
// Shadow mask (1-4 from PD CRT Lottes shader).

float3 Mask(float2 pos, float mx)
{
	float2 pos0 = pos;
	pos.y = floor(pos.y/masksize);

	float stagg_lvl = 1.0;
	if (frac(abs(mshift)) > 0.25 && abs(mshift) > 1.25)
		stagg_lvl = 2.0;
	const float next_line = float(frac((pos.y/stagg_lvl)*0.5) > 0.25);
	pos0.x = (mshift > -0.25) ? (pos0.x + next_line * floor(mshift)) : (pos0.x + floor(pos.y / stagg_lvl) * floor(abs(mshift)));
	pos = floor(pos0/masksize);

	float3 mask = float3(maskDark, maskDark, maskDark);
	const float3 one = float3(1.0.xxx);
	const float dark_compensate  = lerp(max( clamp( lerp (mcut, maskstr, mx),0.0, 1.0) - 0.5, 0.0) + 1.0, 1.0, mx);
	const float mc = 1.0 - max(maskstr, 0.0);
	
	// No mask
	if (shadowMask == -1.0)
	{
		mask = float3(1.0.xxx);
	}       
	
	// Phosphor.
	else if (shadowMask == 0.0)
	{
		pos.x = frac(pos.x*0.5);
		if (pos.x < 0.49)
		{
			mask.r = 1.0;
			mask.g = mc;
			mask.b = 1.0;
		}
		else
		{
			mask.r = mc;
			mask.g = 1.0;
			mask.b = mc;
		}
	}    
   
	// Very compressed TV style shadow mask.
	else if (shadowMask == 1.0)
	{
		float lline = maskLight;
		float odd  = 0.0;

		if (frac(pos.x/6.0) < 0.49)
			odd = 1.0;
		if (frac((pos.y + odd)/2.0) < 0.49)
			lline = maskDark;

		pos.x = frac(pos.x/3.0);
    
		if (pos.x < 0.3)
			mask.r = maskLight;
		else if (pos.x < 0.6)
			mask.g = maskLight;
		else
			mask.b = maskLight;
		
		mask *= lline;
	} 

	// Aperture-grille.
	else if (shadowMask == 2.0)
	{
		pos.x = frac(pos.x/3.0);

		if (pos.x < 0.3)
			mask.r = maskLight;
		else if (pos.x < 0.6)
			mask.g = maskLight;
		else
			mask.b = maskLight;
	} 

	// Stretched VGA style shadow mask (same as prior shaders).
	else if (shadowMask == 3.0)
	{
		pos.x += pos.y*3.0;
		pos.x  = frac(pos.x/6.0);

		if (pos.x < 0.3)
			mask.r = maskLight;
		else if (pos.x < 0.6)
			mask.g = maskLight;
		else
			mask.b = maskLight;
	}

	// VGA style shadow mask.
	else if (shadowMask == 4.0)
	{
		pos.xy = floor(pos.xy*float2(1.0, 0.5));
		pos.x += pos.y*3.0;
		pos.x  = frac(pos.x/6.0);

		if (pos.x < 0.3)
			mask.r = maskLight;
		else if (pos.x < 0.6)
			mask.g = maskLight;
		else
			mask.b = maskLight;
	}
	
	// Trinitron mask 5
	else if (shadowMask == 5.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x/2.0);
		if  (pos.x < 0.49)
		{	mask.r  = 1.0;
			mask.b  = 1.0;
		}
		else
		{
			mask.g = 1.0;
		}
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}    

	// Trinitron mask 6
	else if (shadowMask == 6.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x/3.0);
		if (pos.x < 0.3)
			mask.r = 1.0;
		else if (pos.x < 0.6)
			mask.g = 1.0;
		else
			mask.b = 1.0;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}
	
	// BW Trinitron mask 7
	else if (shadowMask == 7.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x/2.0);
		if  (pos.x < 0.49)
			mask  = 0.0.xxx;
		else
			mask = 1.0.xxx;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}    

	// BW Trinitron mask 8
	else if (shadowMask == 8.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x/3.0);
		if (pos.x < 0.3)
			mask = 0.0.xxx;
		else if (pos.x < 0.6)
			mask = 1.0.xxx;
		else
			mask = 1.0.xxx;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}    

	// Magenta - Green - Black mask
	else if (shadowMask == 9.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x/3.0);
		if (pos.x < 0.3)
			mask    = 0.0.xxx;
		else if (pos.x < 0.6)
			mask.rb = 1.0.xx;
		else
			mask.g  = 1.0;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}  
	
	// RGBX
	else if (shadowMask == 10.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x * 0.25);
		if (pos.x < 0.2)
			mask  = 0.0.xxx;
		else if (pos.x < 0.4)
			mask.r = 1.0;
		else if (pos.x < 0.7)
			mask.g = 1.0;
		else
			mask.b = 1.0;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}  

	// 4k mask
	else if (shadowMask == 11.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x * 0.25);
		if (pos.x < 0.2)
			mask.r  = 1.0;
		else if (pos.x < 0.4)
			mask.rg = 1.0.xx;
		else if (pos.x < 0.7)
			mask.gb = 1.0.xx;
		else
			mask.b  = 1.0;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}     
	else if (shadowMask == 12.0)
	{
		mask = float3(0.0.xxx);
		pos.x = frac(pos.x * 0.25);
		if (pos.x < 0.2)
			mask.r  = 1.0;
		else if (pos.x < 0.4)
			mask.rb = 1.0.xx;
		else if (pos.x < 0.7)
			mask.gb = 1.0.xx;
		else
			mask.g  = 1.0;
		mask = clamp(lerp( lerp(one, mask, mcut), lerp(one, mask, maskstr), mx), 0.0, 1.0) * dark_compensate;
	}     
 
	const float maskmin = min(min(mask.r,mask.g),mask.b);
	return (mask - maskmin) * maskboost + maskmin;
}


float SlotMask(float2 pos, float m)
{
	if ((slotmask + slotmask1) == 0.0)
	{
		return 1.0;
	}
	else
	{
		pos = floor(pos/smasksize);
		const float mlen = slotwidth*2.0;
		const float px = frac(pos.x/mlen);
		const float py = floor(frac(pos.y/(2.0*double_slot))*2.0*double_slot);
		const float slot_dark = lerp(1.0-slotmask1, 1.0-slotmask, m);
		float slot = 1.0;
		if (py == 0.0 && px <  0.5)
			slot = slot_dark;
		else if (py == double_slot && px >= 0.5)
			slot = slot_dark;

		return slot;
	}
}    

float3 declip(float3 c, float b)
{
	float m = max(max(c.r,c.g),c.b);
	if (m > b)
		c = c*b/m;
	return c;
} 

float2 Warp(float2 pos)
{
	pos  = pos*2.0-1.0;
	pos  = lerp(pos, float2(pos.x*rsqrt(1.0-c_shape*pos.y*pos.y), pos.y*rsqrt(1.0-c_shape*pos.x*pos.x)), float2(warpX, warpY)/c_shape);
	return pos*0.5 + 0.5;
}

float corner(float2 pos) {
	const float2 b = float2(bsize1, bsize1) *  float2(1.0, ReShade::PixelSize.x/ReShade::PixelSize.y) * 0.05;
	pos = clamp(pos, 0.0, 1.0);
	pos = abs(2.0*(pos - 0.5));
	float2 res = (bsize1 == 0.0) ? 1.0.xx : lerp(0.0.xx, 1.0.xx, smoothstep(1.0.xx, 1.0.xx-b, sqrt(pos)));
	res = pow(max(res, 0.0), sborder.xx);
	return sqrt(res.x*res.y);
} 


void fetch_pixel (inout float3 c, inout float3 b, float2 coord, float2 bcoord)
{
		const float stepx = ReShade::PixelSize.x;
		const float stepy = ReShade::PixelSize.y;
		
		const float ds = decons;
				
		const float2 dx = float2(stepx, 0.0);
		const float2 dy = float2(0.0, stepy);
		
		const float posx = 2.0*coord.x - 1.0;
		const float posy = 2.0*coord.y - 1.0;

		const float2 rc = deconrr * dx + deconrry*dy;
		const float2 gc = deconrg * dx + deconrgy*dy;
		const float2 bc = deconrb * dx + deconrby*dy;

		float r1 = tex2D(ShinraAdvanced01SL, coord + rc).r;
		float g1 = tex2D(ShinraAdvanced01SL, coord + gc).g;
		float b1 = tex2D(ShinraAdvanced01SL, coord + bc).b;

		float3 d = float3(r1, g1, b1);
		c = clamp(lerp(c, d, ds), 0.0, 1.0);
		
		r1 = tex2D(ShinraAdvanced03SL, bcoord + rc).r;
		g1 = tex2D(ShinraAdvanced03SL, bcoord + gc).g;
		b1 = tex2D(ShinraAdvanced03SL, bcoord + bc).b;

		d = float3(r1, g1, b1);
		b = clamp(lerp(b, d, ds), 0.0, 1.0);
}


float3 WMASK(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{	
	
	const float2 coord = Warp(uv);
	
	const float w3 = 1.0;
	const float2 dx = float2(0.001, 0.0);
	const float3 color0 = tex2D(ShinraAdvanced01SL, coord - dx).rgb;
	float3 color  = tex2D(ShinraAdvanced01SL, coord).rgb;
	const float3 color1 = tex2D(ShinraAdvanced01SL, coord + dx).rgb;
	float3 b11 = tex2D(ShinraAdvanced03SL, coord).rgb;

	fetch_pixel(color, b11, coord, coord);

	const float3 mcolor = max(max(color0,color),color1);
	float mx = max(max(mcolor.r, mcolor.g), mcolor.b);
	mx = pow(max(mx, 0.0), 1.4/MaskGamma);
	
	const float2 pos1 = floor(uv/ReShade::PixelSize);
	
	float3 cmask = Mask(pos1, mx);
	
	if (float(mask_layout) > 0.5)
		cmask = cmask.rbg;

	color = gc(color)*brightboost;
 	
	const float3 orig1 = color;
	const float3 one = float3(1.0,1.0,1.0);
	const float colmx = max(max(orig1.r,orig1.g),orig1.b)/w3;
	
	color*=cmask;
	
	color = min(color, 1.0);
	
	color*=SlotMask(pos1, mx);

	float3 Bloom1 = b11;
	Bloom1 = min(Bloom1*(orig1+color), max(0.5*(colmx + orig1 - color),0.001*Bloom1));
	Bloom1 = 0.5*(Bloom1 + lerp(Bloom1, lerp(colmx*orig1, Bloom1, 0.5), 1.0-color));

	Bloom1 = Bloom1 * lerp(1.0, 2.0-colmx, bdist);
	
	Bloom1 = bloom*Bloom1;
	
	color = color + Bloom1;
	color = color + glow*b11;
	
	color = min(color, 1.0);
	
	color = min(color, lerp(min(cmask,1.0),one,0.5));

	float maxb = max(max(b11.r,b11.g),b11.b);
	maxb = sqrt(maxb);
	float3 Bloom = b11;

	Bloom = lerp(0.5*(Bloom + Bloom*Bloom), Bloom*Bloom, colmx);
	color = color + (0.75+maxb)*Bloom*(0.75 + 0.70*pow(max(colmx, 0.0),0.33333))*lerp(1.0,w3,0.5*colmx)*lerp(one,cmask,0.35 + 0.4*maxb)*halation;

	color = pow(max(color, 0.0), float3(1.0,1.0,1.0)/MaskGamma);

	color = color*corner(coord);
	
	return color;
}

technique MaskGlowAdvanced
{
	
	pass bloom1
	{
		VertexShader = PostProcessVS;
		PixelShader = PASS_SH0;
		RenderTarget = ShinraAdvanced01L;
	}
	
	pass bloom2
	{
		VertexShader = PostProcessVS;
		PixelShader = PASS_SH1;
		RenderTarget = ShinraAdvanced02L;
	}

	pass bloom3
	{
		VertexShader = PostProcessVS;
		PixelShader = PASS_SH2;
		RenderTarget = ShinraAdvanced03L;
	}	 
	
	pass mask
	{
		VertexShader = PostProcessVS;
		PixelShader = WMASK;
	}
}
