 ////----------------//
 ///**Blooming HDR**///
 //----------------////

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* HDR Bloom AKA FakeHDR + Bloom                                               																									*//
 //* For Reshade 3.0																																								*//
 //* --------------------------																																						*//
 //* This work is licensed under a Creative Commons Attribution 3.0 Unported License.																								*//
 //* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.																				*//
 //* I would also love to hear about a project you are using it with.																												*//
 //* https://creativecommons.org/licenses/by/3.0/us/																																*//
 //*																																												*//
 //* Have fun,																																										*//
 //* Jose Negrete AKA BlueSkyDefender																																				*//
 //*																																												*//
 //* http://reshade.me/forum/shader-presentation/2128-sidebyside-3d-depth-map-based-stereoscopic-shader																				*//	
 //* ---------------------------------																																				*//
 //*                                                                            																									*//
 //* 																																												*//
 //* Lightly optimized by Marot Satil for the GShade project.
 //*
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float CBT_Adjust <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Extracting Bright Colors";
	ui_tooltip = "Use this to set the color based brightness threshold for what is and what isn't allowed.\n"
				"This is the most important setting, use Debug View to adjust this.\n"
				"Number 0.5 is default.";
	ui_category = "HDR Adjustments";
> = 0.5;

uniform float HDR_Adjust <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0;
	ui_label = "HDR Adjust";
	ui_tooltip = "Use this to adjust HDR levels for your content.\n"
				"Number 1.125 is default.";
	ui_category = "HDR Adjustments";
> = 1.125;

uniform bool Auto_Exposure <
	ui_label = "Auto Exposure";
	ui_tooltip = "This will enable the shader to adjust exposure automaticly.\n"
				"You will still need to adjust exposure below.";
	ui_category = "HDR Adjustments";
> = false;

uniform float Exposure<
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Exposure";
	ui_tooltip = "Use this to set HDR exposure for your content.\n"
				"Number 0.100 is default.";
	ui_category = "HDR Adjustments";
> = 0.100;

uniform float Saturation <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.5;
	ui_label = "Bloom Saturation";
	ui_tooltip = "Adjustment The amount to adjust the saturation of the color.\n"
				"Number 1.0 is default.";
	ui_category = "HDR Adjustments";
> = 1.0;

uniform float Spread <
	ui_type = "slider";
	ui_min = 25.0; ui_max = 50.0; ui_step = 0.5;
	ui_label = "Bloom Spread";
	ui_tooltip = "Adjust This to have the Bloom effect to fill in areas.\n"
				 "This is used for Bloom gap filling.\n"
				 "Number 37.5 is default.";
	ui_category = "HDR Adjustments";
> = 37.5;

uniform int Luma_Coefficient <
	ui_type = "combo";
	ui_label = "Luma";
	ui_tooltip = "Changes how color get used for the other effects.\n";
	ui_items = "SD video\0HD video\0HDR video\0Intensity\0";
	ui_category = "HDR Adjustments";
> = 0;

uniform bool Debug_View <
	ui_label = "Debug View";
	ui_tooltip = "To view Shade & Blur effect on the game, movie piture & ect.";
	ui_category = "Debugging";
> = false;

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
texture texBC { Width = BUFFER_WIDTH * 0.5; Height = BUFFER_HEIGHT * 0.5; Format = RGBA8; MipLevels = 4;};

sampler SamplerBC
	{
		Texture = texBC;
		MipLODBias = 2.0f;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
					
texture texBlur { Width = BUFFER_WIDTH * 0.5; Height = BUFFER_HEIGHT * 0.5; Format = RGBA8; MipLevels = 3;};

sampler SamplerBlur
	{
		Texture = texBlur;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
	};
	
texture PastSingle_BackBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};

sampler PSBackBuffer
	{
		Texture = PastSingle_BackBuffer;
	};
		
//Total amount of frames since the game started.
uniform uint framecount < source = "framecount"; >;	
uniform float frametime < source = "frametime";>;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define Alternate framecount % 2 == 0  
#define MipLevelAdjust 2 //This is used for removing banding in the Bloom.

float3 Luma()
{
	float3 Luma;
	
	if (Luma_Coefficient == 0)
	{
		Luma = float3(0.299, 0.587, 0.114); // (SD video)
	}
	else if (Luma_Coefficient == 1)
	{
		Luma = float3(0.2126, 0.7152, 0.0722); // (HD video) https://en.wikipedia.org/wiki/Luma_(video)
	}
	else if (Luma_Coefficient == 2)
	{
		Luma = float3(0.2627, 0.6780, 0.0593); // (HDR video) https://en.wikipedia.org/wiki/Rec._2100
	}
	else
	{
		Luma = float3(0.3333, 0.3333, 0.3333); // Intensity
	}
	return Luma;
}

/////////////////////////////////////////////////////////////////////////////////Adapted Luminance/////////////////////////////////////////////////////////////////////////////////
//Something seems off in the new reshade.
texture texLumAvg {Width = 256; Height = 256; Format = RGBA8; MipLevels = 9;}; //Sample at 256x256 map only has nine mip levels; 0-1-2-3-4-5-6-7-8 : 256,128,64,32,16,8,4,2, and 1 (1x1).
																				
sampler SamplerLum																
	{
		Texture = texLumAvg;
		MipLODBias = 11; //Luminance adapted luminance value from 1x1 So you would only have to adjust the boxes from Image to 8.
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		AddressU = Clamp; 
		AddressV = Clamp;
	};
	
texture PStexLumAvg {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
																				
sampler SamplerPSLum																
	{
		Texture = PStexLumAvg;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		AddressU = Clamp; 
		AddressV = Clamp;
	};
	
float Luminance(float4 pos : SV_Position, float2 texcoords : TEXCOORD) : SV_Target
{   
	float GSBB = dot(tex2D(BackBuffer,texcoords).rgb, Luma());
	return GSBB;
}

float Average_Luminance(float2 texcoords : TEXCOORD)
{
	const float2 tex_offset = 50 * pix; // gets texel offset
    const float L = tex2D(SamplerLum, texcoords).x, PL = tex2D(PSBackBuffer, texcoords).w;
		  //L += tex2D(SamplerLum, texcoords + float2( 1, 0) * tex_offset ).x;
		  //L += tex2D(SamplerLum, texcoords + float2(-1, 0) * tex_offset ).x;
		  //L += tex2D(SamplerLum, texcoords + float2( 0, 1) * tex_offset ).x;
		  //L += tex2D(SamplerLum, texcoords + float2( 0,-1) * tex_offset ).x;
		  //PL += tex2D(PSBackBuffer, texcoords + float2( 1, 0) * tex_offset ).w;
		  //PL += tex2D(PSBackBuffer, texcoords + float2(-1, 0) * tex_offset ).w;
		  //PL += tex2D(PSBackBuffer, texcoords + float2( 0, 1) * tex_offset ).w;
		  //PL += tex2D(PSBackBuffer, texcoords + float2( 0,-1) * tex_offset ).w;
	const float lum = L;
	const float lumlast = PL;
	//Temporal adaptation https://knarkowicz.wordpress.com/2016/01/09/automatic-exposure/
   return lumlast + (lum - lumlast) * (1.0 - exp2(-frametime));
}
   
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
float4 BrightColors(float4 position : SV_Position, float2 texcoords : TEXCOORD) : SV_Target //bright-pass filter is applied to dim-down the darkest areas of the scene.
{   
	float4 BC, Color = tex2D(BackBuffer, texcoords);
	// check whether fragment output is higher than threshold, if so output as brightness color.
    const float brightness = dot(Color.rgb, Luma());

    if(brightness > CBT_Adjust)
        BC.rgb = Color.rgb;
    else
        BC.rgb = float3(0.0, 0.0, 0.0);
	
	const float3 intensity = dot(BC.rgb,Luma());
    BC.rgb = lerp(intensity,BC.rgb,Saturation);  
   // The result of the bright-pass filter is then downscaled.
   return float4(BC.rgb,1.0);
}

float4 Blur(float4 position : SV_Position, float2 texcoords : TEXCOORD) : SV_Target//Then blurred.                                                                        
{    
    float2 tex_offset = (Spread * 0.5f) * pix; // Gets texel offset
    float4 result = tex2D(SamplerBC,texcoords); // Current fragment's contribution
	if (Alternate)
	{
		result += tex2D(SamplerBC,texcoords + float2( 1, 0) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2(-1, 0) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2( 0, 1) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2( 0,-1) * tex_offset );
		tex_offset *= 0.75;
		result += tex2D(SamplerBC,texcoords + float2( 1, 1) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2(-1,-1) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2( 1,-1) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2(-1, 1) * tex_offset );
    }
    else
    {
		tex_offset *= 0.5;
		result += tex2D(SamplerBC,texcoords + float2( 1, 0) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2(-1, 0) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2( 0, 1) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2( 0,-1) * tex_offset );
		tex_offset *= 0.75;
		result += tex2D(SamplerBC,texcoords + float2( 1, 1) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2(-1,-1) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2( 1,-1) * tex_offset );
		result += tex2D(SamplerBC,texcoords + float2(-1, 1) * tex_offset );
	}
	    
   return result / 9;
}

float3 LastBlur(float2 texcoord : TEXCOORD0)
{
	float2 tex_offset = (Spread * 0.25f) * pix; // Gets texel offset
	float3 result =  tex2Dlod(SamplerBlur, float4(texcoord, 0,MipLevelAdjust)).rgb;
		   result += tex2Dlod(SamplerBlur, float4(texcoord + float2( 1, 0) * tex_offset, 0, MipLevelAdjust)).rgb;
		   result += tex2Dlod(SamplerBlur, float4(texcoord + float2(-1, 0) * tex_offset, 0, MipLevelAdjust)).rgb;
		   result += tex2Dlod(SamplerBlur, float4(texcoord + float2( 0, 1) * tex_offset, 0, MipLevelAdjust)).rgb;
		   result += tex2Dlod(SamplerBlur, float4(texcoord + float2( 0,-1) * tex_offset, 0, MipLevelAdjust)).rgb;
		   tex_offset *= 0.75;		   
		   result += tex2Dlod(SamplerBlur, float4(texcoord + float2( 1, 1) * tex_offset, 0, MipLevelAdjust)).rgb;
		   result += tex2Dlod(SamplerBlur, float4(texcoord + float2(-1,-1) * tex_offset, 0, MipLevelAdjust)).rgb;
		   result += tex2Dlod(SamplerBlur, float4(texcoord + float2( 1,-1) * tex_offset, 0, MipLevelAdjust)).rgb;
		   result += tex2Dlod(SamplerBlur, float4(texcoord + float2(-1, 1) * tex_offset, 0, MipLevelAdjust)).rgb;
   return result / 9;
}

void Past_BackSingleBuffer(float4 position : SV_Position, float2 texcoords : TEXCOORD, out float4 PastSingle : SV_Target)
{	
	PastSingle = float4(LastBlur(texcoords),Average_Luminance(texcoords).x);
}

float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float AL = Average_Luminance(texcoord).x, Ex = Exposure;

	if(Auto_Exposure)
	Ex = Ex * AL;

	float4 Out;
    float3 TM, Color = tex2D(BackBuffer, texcoord).rgb, HDR = tex2D(BackBuffer, texcoord).rgb;      
    float3 bloomColor = LastBlur(texcoord) + tex2D(PSBackBuffer, texcoord).rgb; // Merge Current and past frame.
    //Tone Mapping done here.
	TM = 1.0 - exp(-bloomColor * Ex );
	//HDR
	HDR += TM;
	Color = pow(abs(HDR),HDR_Adjust); 

	if (!Debug_View)
	{
		Out = float4(Color, 1.0);
	}
	else
	{	
		Out = float4(bloomColor, 1.0);
	}

#if GSHADE_DITHER
	return float4(Out.rgb + TriDither(Out.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), Out.a);
#else
	return Out;
#endif
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
technique Blooming_HDR
{	
		pass Bright_Filter
	{
		VertexShader = PostProcessVS;
		PixelShader = BrightColors;
		RenderTarget = texBC;
	}
		pass Blur_Filter
	{
		VertexShader = PostProcessVS;
		PixelShader = Blur;
		RenderTarget = texBlur;
	}
		pass Avg_Lum
    {
        VertexShader = PostProcessVS;
        PixelShader = Luminance;
        RenderTarget = texLumAvg;
    }
		pass HDROut
	{
		VertexShader = PostProcessVS;
		PixelShader = Out;	
	}
		pass PSB
	{
		VertexShader = PostProcessVS;
		PixelShader = Past_BackSingleBuffer;
		RenderTarget = PastSingle_BackBuffer;	
	}
}
