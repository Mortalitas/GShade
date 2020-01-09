/*
   Deblur shader
   
   Copyright (C) 2006 - 2019 guest(r) - guest.r@gmail.com

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

static const float3  dt = float3(1.0,1.0,1.0);

uniform float OFFSET <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0;
	ui_label = "Filter Width";
	ui_tooltip = "Filter Width";
> = 1.0; 
 
uniform float DBL <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 9.0;
	ui_label = "Deblur Strength";
	ui_tooltip = "Deblur Strength";
> = 6.0; 

uniform float SMART <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Smart Deblur";
	ui_tooltip = "Smart Deblur intensity";
> = 0.7; 

float3 DEB(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	// Calculating texel coordinates
	const float2 inv_size = OFFSET * BUFFER_PIXEL_SIZE;

	const float2 dx = float2(inv_size.x,0.0);
	const float2 dy = float2(0.0, inv_size.y);
	const float2 g1 = float2(inv_size.x,inv_size.y);
	const float2 g2 = float2(-inv_size.x,inv_size.y);
	
	const float2 pC4 = uv;
	
	// Reading the texels
	const float3 c00 = tex2D(ReShade::BackBuffer,pC4 - g1).rgb;
	const float3 c10 = tex2D(ReShade::BackBuffer,pC4 - dy).rgb;
	const float3 c20 = tex2D(ReShade::BackBuffer,pC4 - g2).rgb;
	const float3 c01 = tex2D(ReShade::BackBuffer,pC4 - dx).rgb;
	float3 c11 = tex2D(ReShade::BackBuffer,pC4     ).rgb;
	const float3 c21 = tex2D(ReShade::BackBuffer,pC4 + dx).rgb;
	const float3 c02 = tex2D(ReShade::BackBuffer,pC4 + g2).rgb;
	const float3 c12 = tex2D(ReShade::BackBuffer,pC4 + dy).rgb;
	const float3 c22 = tex2D(ReShade::BackBuffer,pC4 + g1).rgb;

	float3 d11 = c11;
	
	float3 mn1 = min (min (c00,c01),c02);
	const float3 mn2 = min (min (c10,c11),c12);
	const float3 mn3 = min (min (c20,c21),c22);
	float3 mx1 = max (max (c00,c01),c02);
	const float3 mx2 = max (max (c10,c11),c12);
	const float3 mx3 = max (max (c20,c21),c22);
   
	mn1 = min(min(mn1,mn2),mn3);
	mx1 = max(max(mx1,mx2),mx3);
	float3 contrast = mx1 - mn1;
	float m = max(max(contrast.r,contrast.g),contrast.b);
	
	float DB1 = DBL; float dif;

	float3 dif1 = abs(c11-mn1) + 0.0001; float3 df1 = pow(dif1,float3(DB1,DB1,DB1));
	float3 dif2 = abs(c11-mx1) + 0.0001; float3 df2 = pow(dif2,float3(DB1,DB1,DB1)); 

	dif1 *= dif1*dif1;
	dif2 *= dif2*dif2;
	
	const float3 df = df1/(df1 + df2);
	const float3 ratio = abs(dif1-dif2)/(dif1+dif2);
	d11 = lerp(c11, lerp(mn1,mx1,df), ratio);
	
	c11 = lerp(c11, d11, saturate(2.0*m-0.125));
	
	d11 = lerp(d11,c11,SMART);
	
	return d11;  
}

technique Deblur
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DEB;
	}
}
