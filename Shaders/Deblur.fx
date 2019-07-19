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
static const float3 dtt = float3(0.0001, 0.0001, 0.0001); 

uniform float OFFSET <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0;
	ui_label = "Kernel Width";
	ui_tooltip = "Kernel Width";
> = 1.0; 
 
uniform float DBL <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 5.0;
	ui_label = "Deblur";
	ui_tooltip = "Deblur strength";
> = 3.0; 

uniform float SMART <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Smart Deblur";
	ui_tooltip = "Smart Deblur";
> = 1.0;  
 
uniform float TH <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Smart Deblur Threshold";
	ui_tooltip = "Smart Deblur Threshold";
> = 0.25;  

uniform float PR <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 1.5;
	ui_label = "Smart Deblur Intensity";
	ui_tooltip = "Smart Deblur Intensity";
> = 1.0;  

float3 DEB(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	// Calculating texel coordinates
	const float2 inv_size = OFFSET * ReShade::PixelSize;	
	const float2 size     = 1.0/inv_size;

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
	const float3 c11 = tex2D(ReShade::BackBuffer,pC4     ).rgb;
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

	float3 dif1 = abs(c11-mn1) + dtt;
	float3 dif2 = abs(c11-mx1) + dtt;
   
	float DB1 = DBL; float dif;
   
	if (SMART > 0.5)
	{
		const float d1=dot(abs(c00-c22),dt)+0.0001;
		const float d2=dot(abs(c20-c02),dt)+0.0001;
		const float hl=dot(abs(c01-c21),dt)+0.0001;
		const float vl=dot(abs(c10-c12),dt)+0.0001;

		dif = PR*pow(max(d1+d2+hl+vl-TH,0.0)/(0.25*dot(c01+c10+c12+c21,dt)+0.33),0.75);
   
		dif = min(dif, 1.0);
		DB1 = max(lerp( 0.0, DBL, dif), 1.0);
	}
   
	dif1=float3(pow(dif1.x,DB1),pow(dif1.y,DB1),pow(dif1.z,DB1));
	dif2=float3(pow(dif2.x,DB1),pow(dif2.y,DB1),pow(dif2.z,DB1));

	d11 = float3((dif1.x*mx1.x + dif2.x*mn1.x)/(dif1.x + dif2.x),
				(dif1.y*mx1.y + dif2.y*mn1.y)/(dif1.y + dif2.y),
				(dif1.z*mx1.z + dif2.z*mn1.z)/(dif1.z + dif2.z));   

				
	float k10 = 1.0/(dot(abs(c10-d11),dt)+0.0001);
	float k01 = 1.0/(dot(abs(c01-d11),dt)+0.0001);
	float k11 = 1.0/(dot(abs(c11-d11),dt)+0.0001);  
	float k21 = 1.0/(dot(abs(c21-d11),dt)+0.0001);
	float k12 = 1.0/(dot(abs(c12-d11),dt)+0.0001);   
	float k00 = 1.0/(dot(abs(c00-d11),dt)+0.0001);
	float k02 = 1.0/(dot(abs(c02-d11),dt)+0.0001);  
	float k20 = 1.0/(dot(abs(c20-d11),dt)+0.0001);
	float k22 = 1.0/(dot(abs(c22-d11),dt)+0.0001);   
   
	const float avg = 0.03*(k10+k01+k11+k21+k12+k00+k02+k20+k22);
   
	k10 = max(k10-avg, 0.0);
	k01 = max(k01-avg, 0.0);
	k11 = max(k11-avg, 0.0);   
	k21 = max(k21-avg, 0.0);
	k12 = max(k12-avg, 0.0);
	k00 = max(k00-avg, 0.0);
	k02 = max(k02-avg, 0.0);   
	k20 = max(k20-avg, 0.0);
	k22 = max(k22-avg, 0.0);
   
	return (k10*c10 + k01*c01 + k11*c11 + k21*c21 + k12*c12 + k00*c00 + k02*c02 + k20*c20 + k22*c22 + 0.0001*c11)/(k10+k01+k11+k21+k12+k00+k02+k20+k22+0.0001);
}

technique DEBLUR
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DEB;
	}
}
