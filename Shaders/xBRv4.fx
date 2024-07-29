/*
   xBR and dilation ported by Bapho - https://github.com/Bapho https://www.shadertoy.com/user/Bapho

   Hyllian's xBR v4.0 (LEVEL 2) Shader
   
   Copyright (C) 2011/2014 Hyllian/Jararaca - sergiogdb@gmail.com
  
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

   Incorporates some of the ideas from SABR shader. Thanks to Joshua Street.

Shader notes:

	Shader level 1: a cornering

	Shader level 2: b cornering

	Shader level 3: c cornering

	Shader level 4: d cornering

*/
#include "ReShade.fxh"

uniform float dilationAmount <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Dilation amount";
	ui_tooltip = "Stretches the image itself";
> = 0.25;

uniform int xBRtype <
	ui_type = "combo";
    ui_label = "xBR type";
	ui_items = "type A - round\0type B: semi-round\0type C: semi-square\0type D: square\0";
	ui_tooltip = "Changes the edge type.";
> = 2;

#define TEX(dx,dy,dz) tex2D(ReShade::BackBuffer, tex + float2(dx, dy) * dz)

static const precise float XBR_SCALE = 4096.0;
static const float coef = 2.0;
static const float4 eq_threshold = float4(15.0, 15.0, 15.0, 15.0);
static const float3 rgbw = float3(14.352, 28.176, 5.472);
static const float3 dt = float3(1.0,1.0,1.0);

bool4 greaterThanEqual(float4 A, float4 B){
	return bool4(A.x >= B.x, A.y >= B.y, A.z >= B.z, A.w >= B.w);
}

bool4 notEqual(float4 A, float4 B){
	return bool4(A.x != B.x, A.y != B.y, A.z != B.z, A.w != B.w);
}

bool4 lessThanEqual(float4 A, float4 B){
	return bool4(A.x <= B.x, A.y <= B.y, A.z <= B.z, A.w <= B.w);
}

bool4 lessThan(float4 A, float4 B){
	return bool4(A.x < B.x, A.y < B.y, A.z < B.z, A.w < B.w);
}

float4 noteq(float4 A, float4 B)
{
	return float4(notEqual(A, B));
}

float4 not(float4 A)
{
	return float4(1.0, 1.0, 1.0, 1.0)-A;
}

float4 df(float4 A, float4 B)
{
    return abs(A-B);
}

float4 eq(float4 A, float4 B)
{
	return float4(lessThan(df(A, B),eq_threshold));
}

float4 weighted_distance(float4 a, float4 b, float4 c, float4 d, float4 e, float4 f, float4 g, float4 h)
{
    return (df(a,b) + df(a,c) + df(d,e) + df(d,f) + 4.0*df(g,h));
}

float3 xBRv4(float4 position : SV_Position, float2 tex : TEXCOORD0) : SV_Target
{	
	const float2 OGLSize = float2(ReShade::ScreenSize.x * 0.25, ReShade::ScreenSize.y * 0.25);
	const float2 OGLInvSize = float2(1.0/OGLSize.x, 1.0/OGLSize.y);
	
	const float2 dx         = float2( OGLInvSize.x, 0.0);
	const float2 dy         = float2( 0.0, OGLInvSize.y );
	
	const float2 fp  = frac(tex*OGLSize);
	const float2 TexCoord_0 = tex-fp*OGLInvSize + 0.5*OGLInvSize;
	
	float4 edr, edr_left, edr_up;                     // px = pixel, edr = edge detection rule
	float4 interp_restriction_lv1, interp_restriction_lv2_left, interp_restriction_lv2_up;
	float4 nc30, nc60, nc45;                          // new_color
	float4 fx, fx_left, fx_up, final_fx;              // inequations of straight lines.
	float3 res1, res2, pix1, pix2;
	bool4 nc, px;
	float blend1, blend2; 
	
	const float OGLInvSizeY2 = OGLInvSize.y * 2;
	const float2 x2         = float2( OGLInvSize.y, 0.0);
	const float2 y2         = float2( 0.0 , OGLInvSizeY2 );
	const float4 xy         = float4( OGLInvSize.x, OGLInvSize.y, -OGLInvSize.x, -OGLInvSize.y );
	const float4 zw         = float4( OGLInvSize.y, OGLInvSize.y, -OGLInvSize.y, -OGLInvSizeY2 );
	const float4 wz         = float4( OGLInvSize.x, OGLInvSizeY2, -OGLInvSize.x, -OGLInvSizeY2 );

	const float4 delta  = float4(1.0/XBR_SCALE, 1.0/XBR_SCALE, 1.0/XBR_SCALE, 1.0/XBR_SCALE);
	const float4 deltaL = float4(0.5/XBR_SCALE, 1.0/XBR_SCALE, 0.5/XBR_SCALE, 1.0/XBR_SCALE);
	const float4 deltaU = deltaL.yxwz;

	const float3 A  = tex2D(ReShade::BackBuffer, TexCoord_0 + xy.zw ).xyz;
	const float3 B  = tex2D(ReShade::BackBuffer, TexCoord_0     -dy ).xyz;
	const float3 C  = tex2D(ReShade::BackBuffer, TexCoord_0 + xy.xw ).xyz;
	const float3 D  = tex2D(ReShade::BackBuffer, TexCoord_0 - dx    ).xyz;
	const float3 E  = tex2D(ReShade::BackBuffer, TexCoord_0         ).xyz;
	const float3 F  = tex2D(ReShade::BackBuffer, TexCoord_0 + dx    ).xyz;
	const float3 G  = tex2D(ReShade::BackBuffer, TexCoord_0 + xy.zy ).xyz;
	const float3 H  = tex2D(ReShade::BackBuffer, TexCoord_0     +dy ).xyz;
	const float3 I  = tex2D(ReShade::BackBuffer, TexCoord_0 + xy.xy ).xyz;
	const float3 A1 = tex2D(ReShade::BackBuffer, TexCoord_0 + wz.zw ).xyz;
	const float3 C1 = tex2D(ReShade::BackBuffer, TexCoord_0 + wz.xw ).xyz;
	const float3 A0 = tex2D(ReShade::BackBuffer, TexCoord_0 + zw.zw ).xyz;
	const float3 G0 = tex2D(ReShade::BackBuffer, TexCoord_0 + zw.zy ).xyz;
	const float3 C4 = tex2D(ReShade::BackBuffer, TexCoord_0 + zw.xw ).xyz;
	const float3 I4 = tex2D(ReShade::BackBuffer, TexCoord_0 + zw.xy ).xyz;
	const float3 G5 = tex2D(ReShade::BackBuffer, TexCoord_0 + wz.zy ).xyz;
	const float3 I5 = tex2D(ReShade::BackBuffer, TexCoord_0 + wz.xy ).xyz;
	const float3 B1 = tex2D(ReShade::BackBuffer, TexCoord_0 - y2    ).xyz;
	const float3 D0 = tex2D(ReShade::BackBuffer, TexCoord_0 - x2    ).xyz;
	const float3 H5 = tex2D(ReShade::BackBuffer, TexCoord_0 + y2    ).xyz;
	const float3 F4 = tex2D(ReShade::BackBuffer, TexCoord_0 + x2    ).xyz;

	const float4 b  = float4(dot(B ,rgbw), dot(D ,rgbw), dot(H ,rgbw), dot(F ,rgbw));
	const float4 c  = float4(dot(C ,rgbw), dot(A ,rgbw), dot(G ,rgbw), dot(I ,rgbw));
	const float4 d  = b.yzwx;
	const float  eV = dot(E,rgbw);
	const float4 e  = float4(eV, eV, eV, eV);
	const float4 f  = b.wxyz;
	const float4 g  = c.zwxy;
	const float4 h  = b.zwxy;
	const float4 i  = c.wxyz;
	const float4 i4 = float4(dot(I4,rgbw), dot(C1,rgbw), dot(A0,rgbw), dot(G5,rgbw));
	const float4 i5 = float4(dot(I5,rgbw), dot(C4,rgbw), dot(A1,rgbw), dot(G0,rgbw));
	const float4 h5 = float4(dot(H5,rgbw), dot(F4,rgbw), dot(B1,rgbw), dot(D0,rgbw));
	const float4 f4 = h5.yzwx;
	const float4 c1 = i4.yzwx;
	const float4 g0 = i5.wxyz;
	
	const float4 Ao = float4( 1.0, -1.0, -1.0, 1.0 );
	const float4 Bo = float4( 1.0,  1.0, -1.0,-1.0 );
	const float4 Co = float4( 1.5,  0.5, -0.5, 0.5 );
	const float4 Ax = float4( 1.0, -1.0, -1.0, 1.0 );
	const float4 Bx = float4( 0.5,  2.0, -0.5,-2.0 );
	const float4 Cx = float4( 1.0,  1.0, -0.5, 0.0 );
	const float4 Ay = float4( 1.0, -1.0, -1.0, 1.0 );
	const float4 By = float4( 2.0,  0.5, -2.0,-0.5 );
	const float4 Cy = float4( 2.0,  0.0, -1.0, 0.5 );
	
    // These inequations define the line below which interpolation occurs.
	
	fx      = (Ao*fp.y+Bo*fp.x); 
	
	fx_left = (Ax*fp.y+Bx*fp.x);
	
	fx_up   = (Ay*fp.y+By*fp.x);

	if (xBRtype <= 0){
		interp_restriction_lv1 = sign(noteq(e,f) * noteq(e,h));
	} else if (xBRtype <= 1){
		interp_restriction_lv1 = sign(noteq(e,f) * noteq(e,h) * ( not(eq(f,b)) * not(eq(h,d)) + eq(e,i) * not(eq(f,i4)) * not(eq(h,i5)) + eq(e,g) + eq(e,c)));
	} else if (xBRtype <= 2){
		interp_restriction_lv1 = sign(noteq(e,f)*noteq(e,h)*(not(eq(f,b))* not(eq(h,d)) + eq(e,i) * not(eq(f,i4)) * not(eq(h,i5)) + eq(e,g) + eq(e,c) )  * (noteq(f,f4)* noteq(f,i) + noteq(h,h5) * noteq(h,i) + noteq(h,g) + noteq(f,c) + eq(b,c1) * eq(d,g0)));
	} else {
		interp_restriction_lv1 = sign(noteq(e,f) * noteq(e,h) * ( not(eq(f,b)) * not(eq(f,c)) + not(eq(h,d)) * not(eq(h,g)) + eq(e,i) * (not(eq(f,f4)) * not(eq(f,i4)) + not(eq(h,h5)) * not(eq(h,i5))) + eq(e,g) + eq(e,c)) );
	}

	interp_restriction_lv2_left = float4(notEqual(e,g))*float4(notEqual(d,g));
	interp_restriction_lv2_up   = float4(notEqual(e,c))*float4(notEqual(b,c));

	float4 fx45 = clamp((fx + delta -Co)/(2*delta ),0.0,1.0);
	float4 fx30 = clamp((fx_left + deltaL -Cx)/(2*deltaL),0.0,1.0);
	float4 fx60 = clamp((fx_up + deltaU -Cy)/(2*deltaU),0.0,1.0);
	
	edr      = float4(lessThan(weighted_distance( e, c, g, i, h5, f4, h, f), weighted_distance( h, d, i5, f, i4, b, e, i)))*interp_restriction_lv1;
	edr_left = float4(lessThanEqual(coef*df(f,g),df(h,c)))*interp_restriction_lv2_left*edr; 
	edr_up   = float4(greaterThanEqual(df(f,g),coef*df(h,c)))*interp_restriction_lv2_up*edr;

	fx45 = edr*fx45;
	fx30 = edr_left*fx30;
	fx60 = edr_up*fx60;

	px = lessThanEqual(df(e,f),df(e,h));
	const float4 maximo = max(max(fx30, fx60), fx45);    
	
	const float3 zero  = lerp(E, lerp(H, F, float(px.x)), maximo.x).rgb;
	const float3 one   = lerp(E, lerp(F, B, float(px.y)), maximo.y).rgb;
	const float3 two   = lerp(E, lerp(B, D, float(px.z)), maximo.z).rgb;
	const float3 three = lerp(E, lerp(D, H, float(px.w)), maximo.w).rgb;

	const float4 pixel = float4(dot(zero,rgbw),dot(one,rgbw),dot(two,rgbw),dot(three,rgbw));

	const float4 diff = df(pixel,e);

	float3 res = zero;
	float mx = diff.x;

	if (diff.y > mx) {res = one; mx = diff.y;}
	if (diff.z > mx) {res = two; mx = diff.z;}
	if (diff.w > mx) {res = three;}
	
	return res;
}

float3 dilation(float4 position : SV_Position, float2 tex : TEXCOORD0) : SV_Target
{
	const float2 dz = float2( 1.0 / ReShade::ScreenSize.x * dilationAmount, 
						1.0 / ReShade::ScreenSize.y * dilationAmount);
						
	const float x = ReShade::PixelSize.x;
	const float y = ReShade::PixelSize.y;
	
	const float3 B  = TEX( 0,-1, dz).rgb;
	const float3 D  = TEX(-1, 0, dz).rgb;
	const float3 E  = TEX( 0, 0, dz).rgb;
	const float3 F  = TEX( 1, 0, dz).rgb;
	const float3 H  = TEX( 0, 1, dz).rgb;
	
	return max(E, max(max(F, D), max(B, H)));
}

technique xBRv4
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader  = dilation;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader  = dilation;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader  = xBRv4;
	}
}
