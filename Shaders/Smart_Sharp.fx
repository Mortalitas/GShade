 ////---------------//
 ///**Smart Sharp**///
 //---------------////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Depth Based Unsharp Mask Bilateral Contrast Adaptive Sharpening                                     																										
// For Reshade 3.0+																																					
// --------------------------																																			
// Have fun,																																								
// Jose Negrete AKA BlueSkyDefender																																		
// 																																											
// https://github.com/BlueSkyDefender/Depth3D																	
//  ---------------------------------
//	https://web.stanford.edu/class/cs448f/lectures/2.1/Sharpening.pdf
//																																                                                                                                        																	
// 								Bilateral Filter Made by mrharicot ported over to Reshade by BSD													
//								GitHub Link for sorce info github.com/SableRaf/Filters4Processin																
// 								Shadertoy Link https://www.shadertoy.com/view/4dfGDH  Thank You.
//
//                                     Everyone wants to best the bilateral filter.....                        
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
// Lightly optimized by Marot Satil for the GShade project.

// This is the practical limit for the algorithm's scaling ability. Example resolutions;
//  1280x720  -> 1080p = 2.25x area
//  1536x864  -> 1080p = 1.56x area
//  1792x1008 -> 1440p = 2.04x area
//  1920x1080 -> 1440p = 1.78x area
//  1920x1080 ->    4K =  4.0x area
//  2048x1152 -> 1440p = 1.56x area
//  2560x1440 ->    4K = 2.25x area
//  3072x1728 ->    4K = 1.56x area

// Determines the power of the Bilateral Filter and sharpening quality. Lower the setting the more performance you would get along with lower quality.
// 0 = Off
// 1 = Low
// 2 = Default 
// 3 = Medium
// 4 = High 
// Default is off.
#define M_Quality 0 //Manual Quality Shader Defaults to 2 when set to off.

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
	#if Compatibility
	ui_type = "drag";
	#else
	ui_type = "slider";
	#endif
    ui_label = "Sharpening Strength";
    ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "Scaled by adjusting this slider from Zero to One to increase sharpness of the image.\n"
				 "Zero = No Sharpening, to One = Full Sharpening, and Past One = Extra Crispy.\n"
				 "Number 0.625 is default.";
	ui_category = "Bilateral CAS";
> = 0.625;

uniform bool CAM_IOB <
	ui_label = "CAM Ignore Overbright";
	ui_tooltip = "Instead of of allowing Overbright in the mask this allows sharpening of this area.\n"
				 "I think it's more accurate to turn this on.";
	ui_category = "Bilateral CAS";
> = false;

uniform bool CA_Mask_Boost <
	ui_label = "CAM Boost";
	ui_tooltip = "This boosts the power of Contrast Adaptive Masking part of the shader.";
	ui_category = "Bilateral CAS";
> = false;

uniform bool CA_Removal <
	ui_label = "CAM Removal";
	ui_tooltip = "This removes Contrast Adaptive Masking part of the shader.\n"
				 "This is for people who like the Raw look of Bilateral Sharpen.";
	ui_category = "Bilateral CAS";
> = false;

uniform int B_Grounding <
	ui_type = "combo";
	ui_items = "Fine\0Medium\0Coarse\0";
	ui_label = "Grounding Type";
	ui_tooltip = "Like Coffee pick how rough do you want this shader to be.\n"
				 "Gives more control of Bilateral Filtering.";
	ui_category = "Bilateral Filtering";
> = 0;

uniform bool Slow_Mode <
	ui_label = "CAS Slow Mode";
	ui_tooltip = "This enables release Quality of Bilateral Sharpen that is 2X the amount of image bluring at the cost of in game FPS.\n"
				 "If you want this to be usable at higher resolutions go in shader and change the preprocessor M_Quality, to low.\n"
				 "This toggle only for accuracy.";
	ui_category = "Bilateral Filtering";
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

#define Quality 2

#if M_Quality > 0
	#undef Quality
    #define Quality M_Quality
#endif
/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

#define SIGMA 10
#define BSIGMA 0.25

#if Quality == 1
	#define MSIZE 3
#endif
#if Quality == 2
	#define MSIZE 5
#endif
#if Quality == 3
	#define MSIZE 7
#endif
#if Quality == 4
	#define MSIZE 9
#endif

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
		
	const float zBuffer = tex2D(DepthBuffer, texcoord).x; //Depth Buffer
	
	//Conversions to linear space.....
	//Near & Far Adjustment
	const float Far = 1.0, Near = 0.125/Depth_Map_Adjust; //Division Depth Map Adjust - Near
	
	const float2 Z = float2( zBuffer, 1-zBuffer );
	
	if (Depth_Map == 0) //DM0. Normal
		return saturate(Far * Near / (Far + Z.x * (Near - Far)));		
	else //DM1. Reverse
		return saturate(Far * Near / (Far + Z.y * (Near - Far)));
}	

float Min3(float x, float y, float z)
{
    return min(x, min(y, z));
}

float Max3(float x, float y, float z)
{
    return max(x, max(y, z));
}

float normpdf3(in float3 v, in float sigma)
{
	return 0.39894*exp(-0.5*dot(v,v)/(sigma*sigma))/sigma;
}

float3 BB(in float2 texcoord, float2 AD)
{
	return tex2Dlod(BackBuffer, float4(texcoord + AD,0,0)).rgb;
}

float LI(float3 RGB)
{
	return dot(RGB,float3(0.2126, 0.7152, 0.0722));
}

float GT()
{
if (B_Grounding == 2)
	return 1.5;
else if(B_Grounding == 1)
	return 1.25;
else
	return 1.0;
}

float4 CAS(float2 texcoord)
{
	// fetch a Cross neighborhood around the pixel 'C',
	//         Up
	//
	//  Left(Center)Right
	//
	//        Down  
    const float Up = LI(BB(texcoord, float2( 0,-pix.y)));
    const float Left = LI(BB(texcoord, float2(-pix.x, 0)));
    const float Center = LI(BB(texcoord, 0));
    const float Right = LI(BB(texcoord, float2( pix.x, 0)));
    const float Down = LI(BB(texcoord, float2( 0, pix.y)));

    const float mnRGB = Min3( Min3(Left, Center, Right), Up, Down);
    const float mxRGB = Max3( Max3(Left, Center, Right), Up, Down);
       
    // Smooth minimum distance to signal limit divided by smooth max.
    const float rcpMRGB = rcp(mxRGB);
	float RGB_D = saturate(min(mnRGB, 1.0 - mxRGB) * rcpMRGB);

	if( CAM_IOB )
		RGB_D = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);
          
	//Bilateral Filter//                                                Q1         Q2       Q3        Q4                                                                                          
	const int kSize = MSIZE * 0.5; // Default M-size is Quality 2 so [MSIZE 3] [MSIZE 5] [MSIZE 7] [MSIZE 9] / 2.
														
//													1			2			3			4				5			6			7			8				7			6			5				4			3			2			1
//Full Kernal Size would be 15 as shown here (0.031225216, 0.03332227	1, 0.035206333, 0.036826804, 0.038138565, 0.039104044, 0.039695028, 0.039894000, 0.039695028, 0.039104044, 0.038138565, 0.036826804, 0.035206333, 0.033322271, 0.031225216)
/*#if Quality == 1
	const float weight[MSIZE] = {0.031225216, 0.039894000, 0.031225216}; // by 3
#endif
#if Quality == 2
	const float weight[MSIZE] = {0.031225216, 0.036826804, 0.039894000, 0.036826804, 0.031225216};  // by 5
#endif	
#if Quality == 3
	const float weight[MSIZE] = {0.031225216, 0.035206333, 0.039104044, 0.039894000, 0.039104044, 0.035206333, 0.031225216};   // by 7
#endif
#if Quality == 4
	const float weight[MSIZE] = {0.031225216, 0.035206333, 0.038138565, 0.039695028, 0.039894000, 0.039695028, 0.038138565, 0.035206333, 0.031225216};  // by 9
#endif*/
	
	float3 final_colour, c = BB(texcoord.xy,0), cc;
	const float2 RPC_WS = pix * GT();
	float Z, factor;
	
	[loop]
	for (int i=-kSize; i <= kSize; ++i)
	{	
	if(Slow_Mode)
		{
			for (int j=-kSize; j <= kSize; ++j)
			{
				cc = BB(texcoord.xy, float2(i,j) * RPC_WS * rcp(kSize) );
				factor = normpdf3(cc-c, BSIGMA);
				Z += factor;
				final_colour += factor * cc;
			}
		}
		else
		{		
			cc = BB(texcoord.xy, float2( i, 1 - (i * i) * 0.5 ) * RPC_WS * rcp(kSize) );
			factor = normpdf3(cc-c, BSIGMA);
			Z += factor;
			final_colour += factor * cc;
		}
	}
	
	//// Shaping amount of sharpening masked	
	float CAS_Mask = RGB_D;

	if(CA_Mask_Boost)
		CAS_Mask = lerp(CAS_Mask,CAS_Mask * CAS_Mask,saturate(Sharpness * 0.5));
		
	if(CA_Removal)
		CAS_Mask = 1;
		
return saturate(float4(final_colour/Z,CAS_Mask));
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
	{			
		return lerp(Sharpen, BB, DB);
	}
	else if (Debug_View == 1)
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
technique Smart_Sharp
< ui_tooltip = "Suggestion : You Can Enable 'Performance Mode Checkbox,' in the lower bottom right of the ReShade's Main UI.\n"
			   "             Do this once you set your Smart Sharp settings of course."; >
{		
			pass UnsharpMask
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}