 ////-------------//
 ///**NFAA Fast**///
 //-------------////

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Normal Filter Anti Aliasing.                                     																										        *//
 //* For Reshade 3.0																																								*//
 //* --------------------------																																						*//
 //* This work is licensed under a Creative Commons Attribution 3.0 Unported License.																								*//
 //* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.																				*//
 //* I would also love to hear about a project you are using it with.																												*//
 //* https://creativecommons.org/licenses/by/3.0/us/																																*//
 //*																																												*//
 //* Have fun,																																										*//
 //* Jose Negrete AKA BlueSkyDefender																																				*//
 //* Based on port by b34r                       																																	*//
 //* https://www.gamedev.net/forums/topic/580517-nfaa---a-post-process-anti-aliasing-filter-results-implementation-details/?page=2													*//	
 //* ---------------------------------																																				*//
 //*                                                                            																									*//
 //* 																																												*//
 //* Lightly optimized by Marot Satil for the GShade project.
 //*
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

uniform float Mask_Adjust <
	ui_type = "slider";
	ui_min = 0.125; ui_max = 0.625;
	ui_label = "Mask Adjustment";
	ui_tooltip = "Use this to adjust the Mask.\n"
				 "Default is 0.375";
	ui_category = "NFAA";
> = 0.375;

uniform int View_Mode <
	ui_type = "combo";
	ui_items = "NFAA\0NFAA Masked\0Mask View A\0Mask View B\0";
	ui_label = "View Mode";
	ui_tooltip = "This is used to select the normal view output or debug view.\n"
				 "Mask View A & B gives view of the edge detection.\n"
				 "NFAA Masked gives you a sharper image.\n"
				 "NFAA is the full fat NFAA experiance.\n"
				 "Default is NFAA Masked.";
	ui_category = "NFAA";
> = 1;

/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

texture BackBufferTex : COLOR;

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Luminosity Intensity
float LI(in float3 value)
{	
	return dot(value.rgb,float3(0.333, 0.333, 0.333));
}

float4 GetBB(float2 texcoord : TEXCOORD)
{
	return tex2D(BackBuffer, texcoord);
}

float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 NFAA;
    float2 UV = texcoord.xy, SW = pix, n;	
	float t, l, r, d;
		
	t = LI(GetBB( float2( UV.x , UV.y - SW.y ) ).rgb);
	d = LI(GetBB( float2( UV.x , UV.y + SW.y ) ).rgb);
	l = LI(GetBB( float2( UV.x - SW.x , UV.y ) ).rgb);
	r = LI(GetBB( float2( UV.x + SW.x , UV.y ) ).rgb);
	n = float2(t - d,r - l);
		
    const float   nl = length(n);
 
    if (nl < (1.0 / 16))
    {
		NFAA = GetBB(UV);
	}
    else
    {
	n *= pix / (nl * 0.5f);
 
	const float4   o = GetBB( UV ),
			t0 = GetBB( UV + n * 0.5f) * 0.9f,
			t1 = GetBB( UV - n * 0.5f) * 0.9f,
			t2 = GetBB( UV + n * 0.9f) * 0.75f,
			t3 = GetBB( UV - n * 0.9f) * 0.75f;
 
		NFAA = (o + t0 + t1 + t2 + t3) / 4.3;
	}
	
	float Mask = nl * Mask_Adjust;
	
	if (Mask > 0.025)
	Mask = 1-Mask;
	else
	Mask = 1;
	
	Mask = saturate(lerp(Mask,1,-6.25f));
	
	// Final color
	if(View_Mode == 1)
	{
		NFAA = lerp(NFAA,GetBB( texcoord.xy ), Mask );
	}
	if(View_Mode == 2)
	{
		NFAA = lerp(float4(2.5,0,0,1),GetBB( texcoord.xy ), Mask );
	}
	else if (View_Mode == 3)
	{
		NFAA = Mask.xxxx;
	}	
	return NFAA;
}

///////////////////////////////////////////////////////////ReShade.fxh/////////////////////////////////////////////////////////////

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

//*Rendering passes*//
technique Normal_Filter_Anti_Aliasing
{
			pass NFAA_Fast
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}
