 ////--------------------//
 ///**3x3 Median Sharp**///
 //--------------------////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Depth Based Unsharp Mask Median Contrast Adaptive Sharpening                                     																										
// For Reshade 3.0+																																					
// --------------------------																																			
// Have fun,																																								
// Jose Negrete AKA BlueSkyDefender																																		
// 																																											
// https://github.com/BlueSkyDefender/Depth3D																	
//  ---------------------------------																																	                                                                                                        																	
// 								3x3 Median Filter Made by Morgan McGuire and Kyle Whitson ported over to Reshade by BSD													
//								 Link for sorce info https://casual-effects.com/research/McGuire2008Median/index.html																
// 								Shadertoy Link http://graphics.cs.williams.edu  Thank You.
//                                                       
// LICENSE
// =======
// Copyright (c) Morgan McGuire and Williams College, 2006
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// This is the practical limit for the algorithm's scaling ability. Example resolutions;
//  1280x720  -> 1080p = 2.25x area
//  1536x864  -> 1080p = 1.56x area
//  1792x1008 -> 1440p = 2.04x area
//  1920x1080 -> 1440p = 1.78x area
//  1920x1080 ->    4K =  4.0x area
//  2048x1152 -> 1440p = 1.56x area
//  2560x1440 ->    4K = 2.25x area
//  3072x1728 ->    4K = 1.56x area

// It is best to run Median Sharp after tonemapping.

uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "Normal\0Reverse\0";
	ui_label = "Custom Depth Map";
	ui_tooltip = "Pick your Depth Map.";
	ui_category = "Depth Buffer";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 1000.0; ui_step = 0.125;
	ui_label = "Depth Map Adjustment";
	ui_tooltip = "Adjust the depth map and sharpness distance.";
	ui_category = "Depth Buffer";
> = 250.0;

uniform bool Depth_Map_Flip <
	ui_label = "Depth Map Flip";
	ui_tooltip = "Flip the depth map if it is upside down.";
	ui_category = "Depth Buffer";
> = false;

uniform bool No_Depth_Map <
	ui_label = "No Depth Map";
	ui_tooltip = "If you have No Depth Buffer turn this On.";
	ui_category = "Depth Buffer";
> = false;

uniform float Sharpness <
	ui_type = "slider";
    ui_label = "Sharpening Strength";
    ui_min = 0.0; ui_max = 1.25;
    ui_tooltip = "Scaled by adjusting this slider from Zero to One to increase sharpness of the image.\n"
				 "Zero = No Sharpening, to One = Full Sharpening, and Past One = Extra Crispy.\n"
				 "Number 0.625 is default.";
	ui_category = "Median CAS";
> = 0.625;

uniform bool CA_Mask_Boost <
	ui_label = "CAM Boost";
	ui_tooltip = "This boosts the power of Contrast Adaptive Masking part of the shader.";
	ui_category = "Median CAS";
> = false;

uniform int Debug_View <
	ui_type = "combo";
	ui_items = "Normal View\0Sharp Debug\0Z-Buffer Debug\0";
	ui_label = "View Mode";
	ui_tooltip = "This is used to select the normal view output or debug view.\n"
				 "Used to see what the shaderis changing in the image.\n"
				 "Normal gives you the normal out put of this shader.\n"
				 "Sharp is the full Debug for Smart sharp.\n"
				 "Depth Cues is the Shaded output.\n"
				 "Z-Buffer id Depth Buffer only.\n"
				 "Default is Normal View.";
	ui_category = "Debug";
> = 0;

/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

texture DepthBufferTex : DEPTH;

sampler DepthBuffer 
	{ 	
		Texture = DepthBufferTex; 
	};
	
texture BackBufferTex : COLOR;	

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};
				
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float Depth(in float2 texcoord : TEXCOORD0)
{
	if (Depth_Map_Flip)
		texcoord.y =  1 - texcoord.y;
		
	float zBuffer = tex2D(DepthBuffer, texcoord).x; //Depth Buffer
	
	//Conversions to linear space.....
	//Near & Far Adjustment
	const float Far = 1.0, Near = 0.125/Depth_Map_Adjust; //Division Depth Map Adjust - Near
	
	const float2 Z = float2( zBuffer, 1-zBuffer );
	
	if (Depth_Map == 0)//DM0. Normal
		zBuffer = Far * Near / (Far + Z.x * (Near - Far));		
	else if (Depth_Map == 1)//DM1. Reverse
		zBuffer = Far * Near / (Far + Z.y * (Near - Far));	
		 
	return saturate(zBuffer);	
}	

float3 BB(in float2 texcoord, float2 AD)
{
	return tex2Dlod(BackBuffer, float4(texcoord + AD,0,0)).rgb;
}

#define s2(a, b)				temp = a; a = min(a, b); b = max(temp, b);
#define mn3(a, b, c)			s2(a, b); s2(a, c);
#define mx3(a, b, c)			s2(b, c); s2(a, c);

#define mnmx3(a, b, c)			mx3(a, b, c); s2(a, b);                                   // 3 exchanges
#define mnmx4(a, b, c, d)		s2(a, b); s2(c, d); s2(a, c); s2(b, d);                   // 4 exchanges
#define mnmx5(a, b, c, d, e)	s2(a, b); s2(c, d); mn3(a, c, e); mx3(b, d, e);           // 6 exchanges
#define mnmx6(a, b, c, d, e, f) s2(a, d); s2(b, e); s2(c, f); mn3(a, b, c); mx3(d, e, f); // 7 exchanges	

float4 MCAS(float2 texcoord)
{   
	const float2 ScreenCal = pix;

	
	const float2 FinCal = ScreenCal*0.6;

	float3 v[9];
	
	[unroll]
	for(int i = -1; i <= 1; ++i) 
	{
		[unroll]
		for(int j = -1; j <= 1; ++j)
		{		
		  const float2 offset = float2(i, j);

		  v[(i + 1) * 3 + (j + 1)] = BB( texcoord , offset * FinCal);
		}
	}

	float3 temp;

	mnmx6(v[0], v[1], v[2], v[3], v[4], v[5]);
	mnmx5(v[1], v[2], v[3], v[4], v[6]);
	mnmx4(v[2], v[3], v[4], v[7]);
	mnmx3(v[3], v[4], v[8]);

	const float3 rcpMRGB = abs(v[0] - BB( texcoord ,0));
	float3 ampRGB = saturate(rcpMRGB);
    
    // Shaping amount of sharpening.
    ampRGB = sqrt(ampRGB);
    
	float CAS_Mask = 1-length(ampRGB);

	if(CA_Mask_Boost)
		CAS_Mask = lerp(CAS_Mask,CAS_Mask * CAS_Mask,saturate(Sharpness * 0.5));
		
return saturate(float4(v[4],CAS_Mask));
}

float3 Sharpen_Out(float2 texcoord)                                                                          
{   const float3 Done = BB(texcoord ,0);	
	return lerp(Done,Done+(Done - MCAS(texcoord).rgb)*(Sharpness*3.), MCAS(texcoord).w * saturate(Sharpness)); //Sharpen Out
}


float3 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float3 Sharpen = Sharpen_Out(texcoord).rgb,BB = tex2D(BackBuffer,texcoord).rgb;
	float DB = Depth(texcoord).r, DBBL = Depth(float2(texcoord.x*2,texcoord.y*2-1)).r;
	const float DBTL = Depth(float2(texcoord.x*2,texcoord.y*2)).r;
	
	if(No_Depth_Map)
	{
		DB = 0.0;
		DBBL = 0.0;
	}
	
	if (Debug_View == 0)
	{			
		return lerp(Sharpen, BB, DB);
	}
	else if (Debug_View == 1)
	{
		const float3 Top_Left = lerp(float3(1.,1.,1.),MCAS(float2(texcoord.x*2,texcoord.y*2)).www,1-DBTL);
		
		const float3 Top_Right =  Depth(float2(texcoord.x*2-1,texcoord.y*2)).rrr;		
		
		const float3 Bottom_Left = lerp(float3(1., 0., 1.),tex2D(BackBuffer,float2(texcoord.x*2,texcoord.y*2-1)).rgb,DBBL);	

		const float3 Bottom_Right = MCAS(float2(texcoord.x*2-1,texcoord.y*2-1)).rgb;	
		
		float3 VA_Top;
		if (texcoord.x < 0.5)
			VA_Top = Top_Left;
		else
			VA_Top = Top_Right;

		float3 VA_Bottom;
		if (texcoord.x < 0.5)
			VA_Bottom = Bottom_Left;
		else
			VA_Bottom = Bottom_Right;
		
		if (texcoord.y < 0.5)
			return VA_Top;
		else
			return VA_Bottom;
	}
	else
		return Depth(texcoord);
}

///////////////////////////////////////////////////////////ReShade.fxh/////////////////////////////////////////////////////////////

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	if (id == 2)
		texcoord.x = 2.0;
	else
		texcoord.x = 0.0;

	if (id == 1)
		texcoord.y = 2.0;
	else
		texcoord.y = 0.0;

	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

//*Rendering passes*//
technique Median_Sharp
{		
			pass UnsharpMask
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}