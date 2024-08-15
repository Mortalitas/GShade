/*
   Fast Sharpen shader
   
   Copyright (C) 2019 guest(r)

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

uniform float SHARPEN <
	ui_min = 0.0; ui_max = 2.0;
	ui_type = "slider";
	ui_label = "Sharpen";
	ui_tooltip = "Sharpen intensity";
	ui_step = 0.001;
> = 0.9;

uniform float CONTRAST <
	ui_min = 0.0; ui_max = 0.20;
	ui_type = "slider";
	ui_label = "Contrast";
	ui_tooltip = "Ammount of haloing etc.";
	ui_step = 0.001;
> = 0.06;

uniform float DETAILS <
	ui_min = 0.0; ui_max = 1.0;
	ui_type = "slider";
	ui_label = "Details";
	ui_tooltip = "Ammount of Details.";
	ui_step = 0.001;
> = 0.50; 
 

static const float2 g10 = float2( 0.3333,-1.0)*BUFFER_PIXEL_SIZE;
static const float2 g01 = float2(-1.0,-0.3333)*BUFFER_PIXEL_SIZE;
static const float2 g12 = float2(-0.3333, 1.0)*BUFFER_PIXEL_SIZE;
static const float2 g21 = float2( 1.0, 0.3333)*BUFFER_PIXEL_SIZE; 
 
float3 SHARP(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	// Reading the texels

	const float3 c10 = tex2D(ReShade::BackBuffer, uv + g10).rgb;
	const float3 c01 = tex2D(ReShade::BackBuffer, uv + g01).rgb;
	const float3 c21 = tex2D(ReShade::BackBuffer, uv + g21).rgb;
	const float3 c12 = tex2D(ReShade::BackBuffer, uv + g12).rgb;
	const float3 c11 = tex2D(ReShade::BackBuffer, uv      ).rgb;	
	const float3 b11 = (c10+c01+c12+c21)*0.25; 
	
	float contrast = max(max(c11.r,c11.g),c11.b);
	contrast = lerp(2.0*CONTRAST, CONTRAST, contrast);
	
	float3 mn1 = min(min(c10,c01),min(c12,c21)); mn1 = min(mn1,c11*(1.0-contrast));
	float3 mx1 = max(max(c10,c01),max(c12,c21)); mx1 = max(mx1,c11*(1.0+contrast));
	
	const float3 dif = pow(abs(mx1-mn1), float3(0.75,0.75,0.75));
	const float3 sharpen = lerp(SHARPEN*DETAILS, SHARPEN, dif);
	
	return clamp(lerp(c11,b11,-sharpen), mn1,mx1);
}

technique FastSharpen
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = SHARP;
	}
}
