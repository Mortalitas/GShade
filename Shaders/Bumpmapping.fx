/*
   Bumpmapping shader
   
   Copyright (C) 2019 guest(r) - guest.r@gmail.com

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

uniform float buGlow <
    ui_type = "slider";
    ui_label = "Glow";
    ui_tooltip = "Max brightness on borders.";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.25;

uniform float buShade <
    ui_type = "slider";
    ui_label = "Shade";
    ui_tooltip = "Max darkening.";
    ui_min = 0.0;
    ui_max = 5.0;
    ui_step = 0.001;
> = 0.75;

uniform float buBump <
    ui_type = "slider";
    ui_label = "Strength";
    ui_tooltip = "Effect strength. Lower values bring more effect.";
    ui_min = 0.75;
    ui_max = 3.0;
    ui_step = 0.001;
> = 2.25;

sampler Texture00S
{
	Texture = ReShade::BackBufferTex;
	MinFilter = Point; MagFilter = Point;
};

texture Texture01 { Width = 2.0 * BUFFER_WIDTH; Height = 2.0 * BUFFER_HEIGHT; Format = RGBA8; };
sampler Texture01S { Texture = Texture01; };


float3 TWODS0(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	// Calculating texel coordinates
	const float2 ps = 0.5 * ReShade::PixelSize;	

	const float x = ps.x;
	const float y = ps.y;
	const float2 dg1 = float2( x,y);  float2 dg2 = float2(-x,y);
	const float2 sd1 = dg1*0.5;     float2 sd2 = dg2*0.5;
	const float2 ddx = float2(x,0.0); float2 ddy = float2(0.0,y);

	const float3 c11 = tex2D(Texture00S, uv.xy).xyz;
	const float3 s00 = tex2D(Texture00S, uv.xy - sd1).xyz; 
	const float3 s20 = tex2D(Texture00S, uv.xy - sd2).xyz; 
	const float3 s22 = tex2D(Texture00S, uv.xy + sd1).xyz; 
	const float3 s02 = tex2D(Texture00S, uv.xy + sd2).xyz; 
	const float3 c00 = tex2D(Texture00S, uv.xy - dg1).xyz; 
	const float3 c22 = tex2D(Texture00S, uv.xy + dg1).xyz; 
	const float3 c20 = tex2D(Texture00S, uv.xy - dg2).xyz;
	const float3 c02 = tex2D(Texture00S, uv.xy + dg2).xyz;
	const float3 c10 = tex2D(Texture00S, uv.xy - ddy).xyz; 
	const float3 c21 = tex2D(Texture00S, uv.xy + ddx).xyz; 
	const float3 c12 = tex2D(Texture00S, uv.xy + ddy).xyz; 
	const float3 c01 = tex2D(Texture00S, uv.xy - ddx).xyz;     
	const float3 dt = float3(1.0,1.0,1.0);

	const float d1=dot(abs(c00-c22),dt)+0.0001;
	const float d2=dot(abs(c20-c02),dt)+0.0001;
	const float hl=dot(abs(c01-c21),dt)+0.0001;
	const float vl=dot(abs(c10-c12),dt)+0.0001;
	const float m1=dot(abs(s00-s22),dt)+0.0001;
	const float m2=dot(abs(s02-s20),dt)+0.0001;

	const float3 t1=(hl*(c10+c12)+vl*(c01+c21)+(hl+vl)*c11)/(3.0*(hl+vl));
	const float3 t2=(d1*(c20+c02)+d2*(c00+c22)+(d1+d2)*c11)/(3.0*(d1+d2));
	
	return .25*(t1+t2+(m2*(s00+s22)+m1*(s02+s20))/(m1+m2));
} 


float3 BUMP(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	const float3 dt = float3(1.0,1.0,1.0);

	// Calculating texel coordinates
	const float2 inv_size = 0.8 * ReShade::PixelSize;	

	const float2 dx = float2(inv_size.x,0.0);
	const float2 dy = float2(0.0, inv_size.y);
	const float2 g1 = float2(inv_size.x,inv_size.y);	
	
	// Reading the texels
	const float3 c00 = tex2D(Texture01S,uv - g1).rgb; 
	const float3 c10 = tex2D(Texture01S,uv - dy).rgb;
	const float3 c01 = tex2D(Texture01S,uv - dx).rgb;
	float3 c11 = tex2D(Texture01S,uv     ).rgb;
	const float3 c21 = tex2D(Texture01S,uv + dx).rgb;
	const float3 c12 = tex2D(Texture01S,uv + dy).rgb;
	const float3 c22 = tex2D(Texture01S,uv + g1).rgb;
	
	const float3 d11 = c11;

	c11 = (-c00+c22-c01+c21-c10+c12+buBump*d11)/buBump;
	c11 = min(c11,buGlow*d11);

	return max(c11,buShade*d11);
}

technique BUMPMAPPING
{
	pass bump1
	{
		VertexShader = PostProcessVS;
		PixelShader = TWODS0;
		RenderTarget = Texture01; 		
	}
	pass bump2
	{
		VertexShader = PostProcessVS;
		PixelShader = BUMP;
	}
}
