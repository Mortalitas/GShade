/*

	CRT - Guest - Dr. Venom

	Copyright (C) 2018-2020 guest(r) - guest.r@gmail.com
	Incorporates many good ideas and suggestions from Dr. Venom.

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

	Ported to ReShade by DevilSingh (with help from guest(r))
	
	Optimized for the GShade project by Marot Satil.

*/

uniform int ResolutionX <
	ui_type = "input";
	ui_label = "Resolution X";
	ui_bind = "ResolutionXGCRT";
> = 320;

#ifndef ResolutionXGCRT
#define ResolutionXGCRT 320
#endif

uniform int ResolutionY <
	ui_type = "input";
	ui_label = "Resolution Y";
	ui_bind = "ResolutionYGCRT";
> = 240;

#ifndef ResolutionYGCRT
#define ResolutionYGCRT 240
#endif

uniform float TATE <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 1.0;
	ui_label = "TATE Mode";
> = 0.0;

uniform float IOS <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_step = 1.0;
	ui_label = "Smart Integer Scaling: 1.0:Y, 2.0:'X'+Y";
> = 0.0;

uniform float OS <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_step = 1.0;
	ui_label = "Raster Bloom Overscan Mode";
> = 1.0;

uniform float blm1 <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 20.0;
	ui_step = 1.0;
	ui_label = "Raster Bloom %";
> = 0.0;

uniform float brightboost1 <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 4.0;
	ui_step = 0.05;
	ui_label = "Bright Boost Dark Pixels";
> = 1.4;

uniform float brightboost2 <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 3.0;
	ui_step = 0.05;
	ui_label = "Bright Boost Bright Pixels";
> = 1.1;

uniform float gsl <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_step = 1.0;
	ui_label = "Scanline Type";
> = 0.0;

uniform float scanline1 <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 15.0;
	ui_step = 1.0;
	ui_label = "Scanline Beam Shape Low";
> = 6.0;

uniform float scanline2 <
	ui_type = "slider";
	ui_min = 5.0;
	ui_max = 23.0;
	ui_step = 1.0;
	ui_label = "Scanline Beam Shape High";
> = 8.0;

uniform float beam_min <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 2.5;
	ui_step = 0.05;
	ui_label = "Scanline Dark";
> = 1.35;

uniform float beam_max <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 2.0;
	ui_step = 0.05;
	ui_label = "Scanline Bright";
> = 1.05;

uniform float beam_size <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.05;
	ui_label = "Increased Bright Scanline Beam";
> = 0.7;

uniform float spike <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_step = 0.1;
	ui_label = "Scanline Spike Removal";
> = 1.1;

uniform float h_sharp <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 15.0;
	ui_step = 0.25;
	ui_label = "Horizontal Sharpness";
> = 5.25;

uniform float s_sharp <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.1;
	ui_label = "Substractive Sharpness";
> = 0.4;

uniform float csize <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.07;
	ui_step = 0.01;
	ui_label = "Corner Size";
> = 0.0;

uniform float bsize <
	ui_type = "slider";
	ui_min = 100.0;
	ui_max = 600.0;
	ui_step = 25.0;
	ui_label = "Border Smoothness";
> = 600.0;

uniform float warpX <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.125;
	ui_step = 0.01;
	ui_label = "Curvature X (Default 0.03)";
> = 0.0;

uniform float warpY <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.125;
	ui_step = 0.01;
	ui_label = "Curvature Y (Default 0.04)";
> = 0.0;

uniform float glow <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.5;
	ui_step = 0.01;
	ui_label = "Glow Strength";
> = 0.02;

uniform uint shadowMask <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 7;
	ui_step = 1;
	ui_label = "CRT Mask: 1:CGWG, 2-5:Lottes, 6-7:'Trinitron'";
	ui_bind = "ShadowMaskGCRT";
> = 1;

#ifndef ShadowMaskGCRT
#define ShadowMaskGCRT 1
#endif

uniform float masksize <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 2.0;
	ui_step = 1.0;
	ui_label = "CRT Mask Size (2.0 is nice in 4K)";
> = 1.0;

uniform float vertmask <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.25;
	ui_step = 0.01;
	ui_label = "PVM Like Colors";
> = 0.0;

uniform float slotmask <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.05;
	ui_label = "Slot Mask Strength";
> = 0.0;

uniform float slotwidth <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 6.0;
	ui_step = 0.5;
	ui_label = "Slot Mask Width";
> = 2.0;

uniform float double_slot <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 2.0;
	ui_step = 1.0;
	ui_label = "Slot Mask Height: 2x1 or 4x1";
> = 1.0;

uniform float slotms <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 2.0;
	ui_step = 1.0;
	ui_label = "Slot Mask Size";
> = 1.0;

uniform float mcut <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.5;
	ui_step = 0.05;
	ui_label = "Mask 5-7 Cutoff";
> = 0.2;

uniform float maskDark <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_step = 0.05;
	ui_label = "Lottes&Trinitron Mask Dark";
> = 0.5;

uniform float maskLight <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_step = 0.05;
	ui_label = "Lottes & Trinitron Mask Bright";
> = 1.5;

uniform float CGWG <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.05;
	ui_label = "Mask 0 & 7 Strength";
> = 0.3;

uniform float gamma_in <
	ui_type = "slider";
	ui_min = 0.1;
	ui_max = 5.0;
	ui_step = 0.05;
	ui_label = "Gamma Input";
> = 2.4;

uniform float gamma_out <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 3.5;
	ui_step = 0.05;
	ui_label = "Gamma Output";
> = 2.4;

uniform float inter <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 800.0;
	ui_step = 25.0;
	ui_label = "Interlace Trigger Resolution";
> = 400.0;

uniform float interm <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_step = 1.0;
	ui_label = "Interlace Mode (0.0 = OFF)";
> = 2.0;

uniform float blm2 <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_step = 0.1;
	ui_label = "Bloom Strength";
> = 0.0;

uniform float scans <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.1;
	ui_label = "Scanline 1 & 2 Saturation";
> = 0.5;

#include "ReShade.fxh"

#define TextureSizeGCRT float2(ResolutionXGCRT, ResolutionYGCRT)
#define InputSizeGCRT float2(ResolutionXGCRT, ResolutionYGCRT)
#define OutputSizeGCRT float4(BUFFER_SCREEN_SIZE, 1.0 / BUFFER_SCREEN_SIZE)
#define SourceSizeGCRT float4(TextureSizeGCRT, 1.0 / TextureSizeGCRT)
#define fmodGCRT(x, y)(x - y * trunc(x / y))

texture Texture1GCRT{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;};
sampler Sampler1GCRT{Texture = Texture1GCRT; MinFilter = Linear; MagFilter = Linear;};

texture Texture2GCRT{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;};
sampler Sampler2GCRT{Texture = Texture2GCRT; MinFilter = Linear; MagFilter = Linear;};

sampler Sampler3GCRT{Texture = ReShade::BackBufferTex;};

uniform int framecount<source = "framecount";>;

float st(float x)
{
	return exp2(-10.0 * x * x);
}

float3 sw0(float3 x, float3 color, float scanline)
{
	const float3 ex = x * lerp(beam_min, beam_max, color);

	return exp2(-scanline * ex * ex);
}

float3 sw1(float3 x, float3 color, float scanline)
{
	const float mx = max(max(color.r, color.g), color.b);
	x = lerp(x, beam_min * x, max(x - 0.4 * mx, 0.0));
	const float3 ex = x * lerp(1.2*beam_min,beam_max,color);
	const float br = clamp(0.8 * beam_min - 1.0, 0.2, 0.45);
	const float3 res = exp2(-scanline * ex * ex) / (1.0 - br + br * mx);
	float scans1 = scans;
	if(abs(vertmask) > 0.01)
		scans1 = 1.0;

	return lerp(max(max(res.r, res.g), res.b), res, scans1);
}

float3 sw2(float3 x, float3 color, float scanline)
{
	const float3 ex = x * lerp(beam_max, lerp(2.5 * beam_min, beam_max, color), pow(abs(x), color + 0.3));
	const float3 res = exp2(-scanline * ex * ex) / (0.6 + 0.4 * max(max(color.r, color.g), color.b));
	float scans1 = scans;
	if(abs(vertmask) > 0.01)
		scans1 = 0.85;

	return lerp(max(max(res.r, res.g), res.b), res, scans1);
}

float3 mask1(float2 pos, float3 c)
{
	pos = floor(pos / masksize);
	float3 mask = maskDark;

#if ShadowMaskGCRT == 0
	mask = 1.0;
#elif ShadowMaskGCRT == 1
	pos.x = frac(pos.x * 0.5);
	const float mc = 1.0 - CGWG;
	if(pos.x < 0.5)
	{
		mask.r = 1.1;
		mask.g = mc;
		mask.b = 1.1;
	}
	else
	{
		mask.r = mc;
		mask.g = 1.1;
		mask.b = mc;
	}
#elif ShadowMaskGCRT == 2
	if(frac(pos.x / 6.0) < 0.5 && frac((pos.y + 1.0) / 2.0) < 0.5)
		pos.x = frac(pos.x / 3.0);
	if(pos.x < 0.333)
		mask.r = maskLight;
	else if(pos.x < 0.666)
		mask.g = maskLight;
	else
		mask.b = maskLight;
	mask *= maskDark;
#elif ShadowMaskGCRT == 3
	pos.x = frac(pos.x / 3.0);
	if(pos.x < 0.333)
		mask.r = maskLight;
	else if(pos.x < 0.666)
		mask.g = maskLight;
	else
		mask.b = maskLight;
#elif ShadowMaskGCRT == 4
	pos.x += pos.y * 3.0;
	pos.x = frac(pos.x / 6.0);
	if(pos.x < 0.333)
		mask.r = maskLight;
	else if(pos.x < 0.666)
		mask.g = maskLight;
	else
		mask.b = maskLight;
#elif ShadowMaskGCRT == 5
	pos.xy = floor(pos.xy * float2(1.0, 0.5));
	pos.x += pos.y * 3.0;
	pos.x = frac(pos.x / 6.0);
	if(pos.x < 0.333)
		mask.r = maskLight;
	else if(pos.x < 0.666)
		mask.g = maskLight;
	else
		mask.b = maskLight;
#elif ShadowMaskGCRT == 6
	const float mx = max(max(c.r, c.g), c.b);
	const float adj = 0.80 * maskLight - 0.5 * (0.80 * maskLight - 1.0) * mx + 0.75 * (1.0 - mx);
	mask = min(1.25 * max(mx - mcut, 0.0) / (1.0 - mcut), maskDark + 0.2 * (1.0 - maskDark) * mx);
	pos.x = frac(pos.x / 2.0);
	if(pos.x < 0.5)
	{
		mask.r = adj;
		mask.b = adj;
	}
	else
		mask.g = adj;
#elif ShadowMaskGCRT == 7
	const float mx = max(max(c.r, c.g), c.b);
	const float adj = 0.80 * maskLight - 0.5 * (0.80 * maskLight - 1.0) * mx + 0.75 * (1.0 - mx);
	mask = min(1.33 * max(mx - mcut, 0.0) / (1.0 - mcut), maskDark + 0.225 * (1.0 - maskDark) * mx);
	pos.x = frac(pos.x / 3.0);
	if(pos.x < 0.333)
		mask.r = adj;
	else if(pos.x < 0.666)
		mask.g = adj;
	else
		mask.b = adj;
#elif ShadowMaskGCRT == 8
	const float mx = max(max(c.r, c.g), c.b);
	const float maskTmp = min(1.6 * max(mx - mcut, 0.0) / (1.0 - mcut), 1.0 - CGWG);
	mask = float3(maskTmp, maskTmp, maskTmp);
	pos.x = frac(pos.x / 2.0);
	if(pos.x < 0.5)
		mask = 1.0 + 0.6 * (1.0 - mx);
#endif

	return mask;
}

float mask2(float2 pos, float3 c)
{
	if(slotmask == 0.0)
		return 1.0;
	pos = floor(pos / slotms);
	const float mx = pow(max(max(c.r, c.g), c.b), 1.33);
	const float px = frac(pos.x / (slotwidth * 2.0));
	const float py = floor(frac(pos.y / (2.0 * double_slot)) * 2.0 * double_slot);
	const float slot_dark = lerp(1.0 - slotmask, 1.0 - 0.80 * slotmask, mx);
	if(py == 0.0 && px < 0.5)
		return slot_dark;
	else if(py == double_slot && px >= 0.5)
		return slot_dark;

	return 1.0 + 0.7 * slotmask * (1.0 - mx);
}

float2 warp(float2 pos)
{
	pos = pos * 2.0 - 1.0;
	pos *= float2(1.0 + (pos.y * pos.y) * warpX, 1.0 + (pos.x * pos.x) * warpY);

	return pos * 0.5 + 0.5;
}

float2 overscan(float2 pos, float dx, float dy)
{
	pos = pos * 2.0 - 1.0;
	pos *= float2(dx, dy);

	return pos * 0.5 + 0.5;
}

float corner(float2 coord)
{
	coord *= SourceSizeGCRT.xy / InputSizeGCRT.xy;
	coord = (coord - 0.5) * 1.0 + 0.5;
	coord = min(coord, 1.0 - coord) * float2(1.0, OutputSizeGCRT.y / OutputSizeGCRT.x);
	const float2 cdist = max(csize, max((1.0 - smoothstep(100.0, 600.0, bsize)) * 0.01, 0.002));
	coord = (cdist - min(coord, cdist));

	return clamp((cdist.x - sqrt(dot(coord, coord))) * bsize, 0.0, 1.0);
}

float3 declip(float3 c, float b)
{
	const float m = max(max(c.r, c.g), c.b);
	if(m > b)
		return c * b / m;

	return c;
}

float4 LinearizePS(float4 position:SV_Position, float2 texcoord:TEXCOORD):SV_Target
{
	return float4(pow(abs(tex2D(Sampler3GCRT, texcoord)), gamma_in));
}

float4 ScanlinesPS(float4 position:SV_Position, float2 texcoord:TEXCOORD):SV_Target
{
	return float4(pow(tex2D(Sampler3GCRT, texcoord).rgb, 10.0), 1.0);
}

float4 GuestPS(float4 position:SV_Position, float2 texcoord:TEXCOORD):SV_Target
{
	if(IOS > 0.0)
	{
		const float2 ofactor = OutputSizeGCRT.xy / InputSizeGCRT.xy;
		const float2 diff = ofactor / round(ofactor);
		const float scan = lerp(diff.y, diff.x, TATE);
		texcoord = overscan(texcoord * (SourceSizeGCRT.xy / InputSizeGCRT.xy), scan, scan) * (InputSizeGCRT.xy / SourceSizeGCRT.xy);
		if(IOS == 1.0)
			texcoord = lerp(float2(texcoord.x, texcoord.y), float2(texcoord.x, texcoord.y), TATE);
	}

	const float factor = 1.00 + (1.0 - 0.5 * OS) * blm1 / 100.0 - tex2D(Sampler3GCRT, 0.05).a * blm1 / 100.0;
	texcoord = overscan(texcoord * (SourceSizeGCRT.xy / InputSizeGCRT.xy), factor, factor) * (InputSizeGCRT.xy / SourceSizeGCRT.xy);
	const float2 pos = warp(texcoord * (TextureSizeGCRT.xy / InputSizeGCRT.xy)) * (InputSizeGCRT.xy / TextureSizeGCRT.xy);

	float2 coffset = 0.5;
	if((interm == 1.0 || interm == 2.0) && inter <= lerp(InputSizeGCRT.y, InputSizeGCRT.x, TATE))
	{
		if (TATE < 0.5)
			coffset = float2(0.5, 0.0);
		else
			coffset = float2(0.0, 0.5);
	}

	const float2 ps = SourceSizeGCRT.zw;
	const float2 ogl2pos = pos * SourceSizeGCRT.xy - coffset;
	const float2 fp = frac(ogl2pos);
	const float2 dx = float2(ps.x, 0.0);
	const float2 dy = float2(0.0, ps.y);

	float2 offx = dx;
	float2 off2 = 2.0 * dx;
	float2 offy = dy;
	float fpx = fp.x;

	if(TATE > 0.5)
	{
		offx = dy;
		off2 = 2.0 * dy;
		offy = dx;
		fpx = fp.y;
	}

	const float f = (TATE < 0.5)?fp.y:fp.x;

	float2 pc4 = floor(ogl2pos) * ps + 0.5 * ps;

	const float sharp1 = s_sharp * exp2(-h_sharp);

	float wl3 = 2.0 + fpx;
	float wl2 = 1.0 + fpx;
	float wl1 = fpx;
	float wr1 = 1.0 - fpx;
	float wr2 = 2.0 - fpx;
	float wr3 = 3.0 - fpx;

	wl3 *= wl3;
	wl3 = exp2(-h_sharp * wl3);
	
	wl2 *= wl2;
	wl2 = exp2(-h_sharp * wl2);
	
	wl1 *= wl1;
	wl1 = exp2(-h_sharp * wl1);
	
	wr1 *= wr1;
	wr1 = exp2(-h_sharp * wr1);
	
	wr2 *= wr2;
	wr2 = exp2(-h_sharp * wr2);
	
	wr3 *= wr3;
	wr3 = exp2(-h_sharp * wr3);

	const float twl3 = max(wl3 - sharp1, 0.0);
	const float twl2 = max(wl2 - sharp1, lerp(0.0, lerp(-0.17, -0.025, fp.x), float(s_sharp > 0.05)));
	const float twl1 = max(wl1 - sharp1, 0.0);
	const float twr1 = max(wr1 - sharp1, 0.0);
	const float twr2 = max(wr2 - sharp1, lerp(0.0, lerp(-0.17, -0.025, 1.0 - fp.x), float(s_sharp > 0.05)));
	const float twr3 = max(wr3 - sharp1, 0.0);

	const float wtt = 1.0 / (twl3 + twl2 + twl1 + twr1 + twr2 + twr3);
	const float wt = 1.0 / (wl2 + wl1 + wr1 + wr2);
	const bool sharp = (s_sharp > 0.05);

	float3 l3 = tex2D(Sampler1GCRT, pc4 - off2).xyz;
	float3 l2 = tex2D(Sampler1GCRT, pc4 - offx).xyz;
	float3 l1 = tex2D(Sampler1GCRT, pc4).xyz;
	float3 r1 = tex2D(Sampler1GCRT, pc4 + offx).xyz;
	float3 r2 = tex2D(Sampler1GCRT, pc4 + off2).xyz;
	float3 r3 = tex2D(Sampler1GCRT, pc4 + offx + off2).xyz;

	float3 sl2 = tex2D(Sampler2GCRT, pc4 - offx).xyz;
	float3 sl1 = tex2D(Sampler2GCRT, pc4).xyz;
	float3 sr1 = tex2D(Sampler2GCRT, pc4 + offx).xyz;
	float3 sr2 = tex2D(Sampler2GCRT, pc4 + off2).xyz;

	float3 color1 = (l3 * twl3 + l2 * twl2 + l1 * twl1 + r1 * twr1 + r2 * twr2 + r3 * twr3) * wtt;

	float3 colmin = min(min(l1, r1), min(l2, r2));
	float3 colmax = max(max(l1, r1), max(l2, r2));

	if(sharp)
		color1 = clamp(color1, colmin, colmax);

	const float3 gtmp = gamma_out * 0.1;
	float3 scolor1 = color1;

	scolor1 = (sl2 * wl2 + sl1 * wl1 + sr1 * wr1 + sr2 * wr2) * wt;
	scolor1 = pow(abs(scolor1), gtmp);
	const float3 mcolor1 = scolor1;
	scolor1 = lerp(color1, scolor1, spike);

	pc4 += offy;

	l3 = tex2D(Sampler1GCRT, pc4 - off2).xyz;
	l2 = tex2D(Sampler1GCRT, pc4 - offx).xyz;
	l1 = tex2D(Sampler1GCRT, pc4).xyz;
	r1 = tex2D(Sampler1GCRT, pc4 + offx).xyz;
	r2 = tex2D(Sampler1GCRT, pc4 + off2).xyz;
	r3 = tex2D(Sampler1GCRT, pc4 + offx + off2).xyz;

	sl2 = tex2D(Sampler2GCRT, pc4 - offx).xyz;
	sl1 = tex2D(Sampler2GCRT, pc4).xyz;
	sr1 = tex2D(Sampler2GCRT, pc4 + offx).xyz;
	sr2 = tex2D(Sampler2GCRT, pc4 + off2).xyz;

	float3 color2 = (l3 * twl3 + l2 * twl2 + l1 * twl1 + r1 * twr1 + r2 * twr2 + r3 * twr3) * wtt;

	colmin = min(min(l1, r1), min(l2, r2));
	colmax = max(max(l1, r1), max(l2, r2));

	if(sharp)
		color2 = clamp(color2, colmin, colmax);

	float3 scolor2 = color2;

	scolor2 = (sl2 * wl2 + sl1 * wl1 + sr1 * wr1 + sr2 * wr2) * wt;
	scolor2 = pow(abs(scolor2), gtmp);float3 mcolor2 = scolor2;
	scolor2 = lerp(color2, scolor2, spike);

	float3 color0 = color1;

	if((interm == 1.0 || interm == 2.0) && inter <= lerp(InputSizeGCRT.y, InputSizeGCRT.x, TATE))
	{
		pc4 -= 2.0 * offy;

		l3 = tex2D(Sampler1GCRT, pc4 - off2).xyz;
		l2 = tex2D(Sampler1GCRT, pc4 - offx).xyz;
		l1 = tex2D(Sampler1GCRT, pc4).xyz;
		r1 = tex2D(Sampler1GCRT, pc4 + offx).xyz;
		r2 = tex2D(Sampler1GCRT, pc4 + off2).xyz;
		r3 = tex2D(Sampler1GCRT, pc4 + offx + off2).xyz;

		color0 = (l3 * twl3 + l2 * twl2 + l1 * twl1 + r1 * twr1 + r2 * twr2 + r3 * twr3) * wtt;

		colmin = min(min(l1, r1), min(l2, r2));
		colmax = max(max(l1, r1), max(l2, r2));

		if(sharp)
			color0 = clamp(color0, colmin, colmax);
	}

	const float shape1 = lerp(scanline1, scanline2, f);
	const float shape2 = lerp(scanline1, scanline2, 1.0 - f);

	const float wt1 = st(f);
	const float wt2 = st(1.0 - f);

	float3 mcolor = (mcolor1 * wt1 + mcolor2 * wt2) / (wt1 + wt2);

	float3 ctmp = (color1 * wt1 + color2 * wt2) / (wt1 + wt2);
	const float3 sctmp = (scolor1 * wt1 + scolor2 * wt2) / (wt1 + wt2);

	const float3 tmp = pow(abs(ctmp), 1.0 / gamma_out);
	mcolor = clamp(lerp(ctmp, mcolor, 1.5), 0.0, 1.0);
	mcolor = pow(mcolor, 1.4 / gamma_out);

	float3 w1, w2 = 0.0;

	const float3 cref1 = lerp(sctmp, scolor1, beam_size);
	const float3 cref2 = lerp(sctmp, scolor2, beam_size);

	const float3 shift = float3(-vertmask, vertmask, -vertmask);

	const float3 f1 = clamp(f + shift * 0.5 * (1.0 + f), 0.0, 1.0);
	const float3 f2 = clamp((1.0 - f) - shift * 0.5 * (2.0 - f), 0.0, 1.0);

	if(gsl == 0.0){
		w1 = sw0(f1, cref1, shape1);
		w2 = sw0(f2, cref2, shape2);
	}
	else if(gsl == 1.0)
	{
		w1 = sw1(f1, cref1, shape1);
		w2 = sw1(f2, cref2, shape2);
	}
	else if(gsl == 2.0)
	{
		w1 = sw2(f1, cref1, shape1);
		w2 = sw2(f2, cref2, shape2);
	}

	float3 color = color1 * w1 + color2 * w2;
	color = min(color, 1.0);

	if(interm > 0.5 && inter <= lerp(InputSizeGCRT.y, InputSizeGCRT.x, TATE))
	{
		if(interm < 3.0)
		{
			float ii = 0.5;
			if(interm < 1.5)
				ii = abs(floor(fmodGCRT(lerp(ogl2pos.y, ogl2pos.x, TATE), 2.0)) - floor(fmodGCRT(float(framecount), 2.0)));

			color = lerp(lerp(color1, color0, ii), lerp(color1, color2, ii), f);
		}
		else
			color = lerp(color1, color2, f);

		mcolor = sqrt(color);
	}

	ctmp = 0.5 * (ctmp + tmp);
	color *= lerp(brightboost1, brightboost2, max(max(ctmp.r, ctmp.g), ctmp.b));

	const float3 orig1 = color;
	w1 = w1 + w2;
	float3 cmask = 1.0;
	float3 cmask1 = 1.0;

	if (TATE < 0.5)
	{
		cmask *= mask1(position.xy * 1.000001, mcolor);
		cmask1 *= mask2(position.xy * 1.000001, tmp);
	}
	else
	{
		cmask *= mask1(position.yx * 1.000001, mcolor);
		cmask1 *= mask2(position.yx * 1.000001, tmp);
	}

	color = min(color * cmask, 1.0) * cmask1;
	cmask = min(cmask * cmask1, 1.0);

	const float3 Bloom1 = tex2D(Sampler3GCRT, pos).xyz;

	float3 Bloom2 = min(2.0 * Bloom1 * Bloom1, 0.80);
	const float pmax = lerp(0.825, 0.725, max(max(ctmp.r, ctmp.g), ctmp.b));
	Bloom2 = min(Bloom2, pmax * max(max(Bloom2.r, Bloom2.g), Bloom2.b)) / pmax;

	Bloom2 = blm2 * lerp(min(Bloom2, color), Bloom2, 0.5 * (orig1 + color));

	color = min(color + Bloom2, 1.0);
	if(interm < 0.5 || inter > lerp(InputSizeGCRT.y, InputSizeGCRT.x, TATE))
		color = declip(color, pow(max(max(w1.r, w1.g), w1.b), 0.5));

	return float4(pow(abs(min(color, lerp(cmask, 1.0, 0.5)) + glow * Bloom1), 1.0 / gamma_out) * corner(pos), 1.0);
}

technique GuestCRT
{
	pass Linearize_Gamma
	{
		VertexShader = PostProcessVS;
		PixelShader = LinearizePS;
		RenderTarget = Texture1GCRT;
	}

	pass Linearize_Scanlines
	{
		VertexShader = PostProcessVS;
		PixelShader = ScanlinesPS;
		RenderTarget = Texture2GCRT;
	}

	pass Guest_Dr_Venom
	{
		VertexShader = PostProcessVS;
		PixelShader = GuestPS;
	}
}