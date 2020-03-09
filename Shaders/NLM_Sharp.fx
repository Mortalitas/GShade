 ////-------------//
 ///**NLM_Sharp**///
 //-------------////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Depth Based Unsharp Mask Non Local Means Contrast Adaptive Sharpening                                     																										
// For Reshade 3.0+																																					
// --------------------------																																			
// Have fun,																																								
// Jose Negrete AKA BlueSkyDefender																																		
// 																																											
// https://github.com/BlueSkyDefender/Depth3D																	
//  ---------------------------------
//	https://web.stanford.edu/class/cs448f/lectures/2.1/Sharpening.pdf
//																																	                                                                                                        																	
// 								Non-Local Means Made by panda1234lee ported over to Reshade by BSD													
//								Link for sorce info listed below																
// 								https://creativecommons.org/licenses/by-sa/4.0/ CC Thank You.
//
//								Non-Local Means sharpening figures out what
//								makes me different from other similar things
//								in the image, and exaggerates that
//                                                     
// LICENSE
// =======
// Copyright (c) 2017-2019 Advanced Micro Devices, Inc. All rights reserved.
// -------
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// -------
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// -------
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
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

// It is best to run Smart Sharp after tonemapping.

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
    ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "Scaled by adjusting this slider from Zero to One to increase sharpness of the image.\n"
				 "Zero = No Sharpening, to One = Full Sharpening, and Past One = Extra Crispy.\n"
				 "Number 0.625 is default.";
	ui_category = "Non-Local Means CAS";
> = 0.625;

uniform bool CAM_IOB <
	ui_label = "CAM Ignore Overbright";
	ui_tooltip = "Instead of of allowing Overbright in the mask this allows sharpening of this area.\n"
				 "I think it's more accurate to turn this on.";
	ui_category = "Non-Local Means CAS";
> = false;

uniform bool CA_Mask_Boost <
	ui_label = "CAM Boost";
	ui_tooltip = "This boosts the power of Contrast Adaptive Masking part of the shader.";
	ui_category = "Non-Local Means CAS";
> = false;

uniform bool CA_Removal <
	ui_label = "CAM Removal";
	ui_tooltip = "This removes Contrast Adaptive Masking part of the shader.\n"
				 "This is for people who like the Raw look of Non-Local Means Sharpen.";
	ui_category = "Non-Local Means CAS";
> = false;


uniform int NLM_Grounding <
	ui_type = "combo";
	ui_items = "Fine\0Medium\0Coarse\0";
	ui_label = "Grounding Type";
	ui_tooltip = "Like Coffee pick how rough do you want this shader to be.\n"
				 "Gives more control of Non-Local Means Sharpen.";
	ui_category = "Non-Local Means Filtering";
> = 0;

uniform bool Debug_View <
	ui_label = "View Mode";
	ui_tooltip = "This is used to select the normal view output or debug view.\n"
				 "Used to see what the shaderis changing in the image.\n"
				 "Normal gives you the normal out put of this shader.\n"
				 "Sharp is the full Debug for NLM Sharp.\n"
				 "Depth Cues is the Shaded output.\n"
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

float Min3(float x, float y, float z)
{
    return min(x, min(y, z));
}

float Max3(float x, float y, float z)
{
    return max(x, max(y, z));
}

float normaL2(float4 RGB) 
{ 
   return pow(RGB.r, 2) + pow(RGB.g, 2) + pow(RGB.b, 2) + pow(RGB.a, 2);
}

float4 BB(in float2 texcoord, float2 AD)
{
	return tex2Dlod(BackBuffer, float4(texcoord + AD,0,0));
}

float LI(float3 RGB)
{
	return dot(RGB,float3(0.2126, 0.7152, 0.0722));
}

float GT()
{
if (NLM_Grounding == 2)
	return 1.5;
else if(NLM_Grounding == 1)
	return 1.25;
else
	return 1.0;
}

#define search_radius 1 //Search window radius D = 1    2   3
#define block_radius 0.5 //Base Window Radius D = 0.5 0.75 1.0

#define search_window 2 * search_radius + 1 //Search window size
#define minus_search_window2_inv -rcp(search_window * search_window) //Refactor Search Window 

#define h 10 //Control the degree of attenuation of the Gaussian function
#define minus_h2_inv -rcp(h * h * 4) //The number of channels is four
#define noise_mult minus_h2_inv * 500 //Used for precision

float4 CAS(float2 texcoord)
{
	// fetch a Cross neighborhood around the pixel 'C',
	//         Up
	//
	//  Left(Center)Right
	//
	//        Down  
    const float Up = LI(BB(texcoord, float2( 0,-pix.y)).rgb);
    const float Left = LI(BB(texcoord, float2(-pix.x, 0)).rgb);
    const float Center = LI(BB(texcoord, 0).rgb);
    const float Right = LI(BB(texcoord, float2( pix.x, 0)).rgb);
    const float Down = LI(BB(texcoord, float2( 0, pix.y)).rgb);

    const float mnRGB = Min3( Min3(Left, Center, Right), Up, Down);
    const float mxRGB = Max3( Max3(Left, Center, Right), Up, Down);
       
    // Smooth minimum distance to signal limit divided by smooth max.
    const float rcpMRGB = rcp(mxRGB);
	float RGB_D = saturate(min(mnRGB, 1.0 - mxRGB) * rcpMRGB);

	if( CAM_IOB )
		RGB_D = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);
          
	//Non-Local Mean// - https://blog.csdn.net/panda1234lee/article/details/88016834      
   float sum2;
   const float2 RPC_WS = pix * GT();
   float4 sum1;
	//Traverse the search window
   for(float y = -search_radius; y <= search_radius; ++y)
   {
      for(float x = -search_radius; x <= search_radius; ++x)
      { //Count the sum of the L2 norms of the colors in a search window (the colors in all Base windows
          float dist = 0;
 
		  //Traversing the Base window
          for(float ty = -block_radius; ty <= block_radius; ++ty)
          { 
             for(float tx = -block_radius; tx <= block_radius; ++tx)
             {  //clamping to increase performance & Search window neighborhoods
                const float4 bv = saturate(  BB(texcoord, float2(x + tx, y + ty) * RPC_WS) );
                //Current pixel neighborhood
                const float4 av = saturate(  BB(texcoord, float2(tx, ty) * RPC_WS) );
                
                dist += normaL2(av - bv);
             }
          }
		  //Gaussian weights (calculated from the color distance and pixel distance of all base windows) under a search window
          float window = exp(dist * noise_mult + (pow(x, 2) + pow(y, 2)) * minus_search_window2_inv);
 
          sum1 +=  window * saturate( BB(texcoord, float2(x, y) * RPC_WS) ); //Gaussian weight * pixel value         
          sum2 += window; //Accumulate Gaussian weights for all search windows for normalization
      }
   }
   // Shaping amount of sharpening masked
	float CAS_Mask = RGB_D;

	if(CA_Mask_Boost)
		CAS_Mask = lerp(CAS_Mask,CAS_Mask * CAS_Mask,saturate(Sharpness * 0.5));
		
	if(CA_Removal)
		CAS_Mask = 1;
		
return saturate(float4(sum1.rgb / sum2,CAS_Mask));
}

float3 Sharpen_Out(float2 texcoord)                                                                          
{   const float3 Done = tex2D(BackBuffer,texcoord).rgb;	
	return lerp(Done,Done+(Done - CAS(texcoord).rgb)*(Sharpness*3.1), CAS(texcoord).w * saturate(Sharpness)); //Sharpen Out
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
		return lerp(Sharpen, BB, DB);
	else
	{
		const float3 Top_Left = lerp(float3(1.,1.,1.),CAS(float2(texcoord.x*2,texcoord.y*2)).www,1-DBTL);
		
		const float3 Top_Right =  Depth(float2(texcoord.x*2-1,texcoord.y*2)).rrr;		
		
		const float3 Bottom_Left = lerp(float3(1., 0., 1.),tex2D(BackBuffer,float2(texcoord.x*2,texcoord.y*2-1)).rgb,DBBL);	

		const float3 Bottom_Right = CAS(float2(texcoord.x*2-1,texcoord.y*2-1)).rgb;	

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
technique NLM_Sharp
< ui_tooltip = "Suggestion : You Can Enable 'Performance Mode Checkbox,' in the lower bottom right of the ReShade's Main UI.\n"
			   "             Do this once you set your Smart Sharp settings of course."; >
{		
			pass UnsharpMask
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}