////////////////////////////////////////////////////////
// Depth-Aware Mipmapped Ray Tracing
// Author: Zenteon
// License: GPLv3
// Repository: https://github.com/Zenteon/ZN_FX
////////////////////////////////////////////////////////

/*
ZN Depth Aware Mipmapped Ray Tracing (DAMP RT), by Zenteon (Daniel Oren-Ibarra)

Techniques used, papers inpiring, and information aquired:

Improved Normal Reconstruction from Depth:
	https://atyuwen.github.io/posts/normal-reconstruction/
Fitted modified ACES Tonemapping curve:
	https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
Bandwidth Efficient Graphics (Dual Kawase Blur):
	https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_marius_2D00_notes.pdf
Neighborhood Clamping:
	https://www.elopezr.com/temporal-aa-and-the-quest-for-the-holy-trail/	
TAA (Used for denoising)
	https://de45xmedrsdbp.cloudfront.net/Resources/files/TemporalAA_small-59732822.pdf
Variance Clamping:
	https://developer.download.nvidia.com/gameworks/events/GDC2016/msalvi_temporal_supersampling.pdf
Simple Hash:
	https://www.shadertoy.com/view/4djSRW
Reinhardt Jodie tonemapper https:
	//www.shadertoy.com/view/4dBcD1
Thanks to Matsilagi for the Sponza Test: //https://mega.nz/#!qVwGhYwT!rEwOWergoVOCAoCP3jbKKiuWlRLuHo9bf1mInc9dDGE
*/

#include "ReShade.fxh"

#ifndef DO_REFLECT
//============================================================================================
	#define DO_REFLECT 0 //Enables diffuse reflections
//============================================================================================
#endif

#ifndef ZNRY_SAMPLE_DIV
//============================================================================================
	#define ZNRY_SAMPLE_DIV 4 //Sample Texture Resolution Divider
//============================================================================================
#endif

#ifndef ZNRY_RENDER_SCL
//============================================================================================
	#define ZNRY_RENDER_SCL 0.5 //Sample Texture Resolution Divider
//============================================================================================
#endif


#ifndef ZNRY_MAX_LODS
//============================================================================================
	#define ZNRY_MAX_LODS 6 //How many Lods are checked during sampling, moderate impact
//============================================================================================
#endif

#ifndef HIDE_EXPERIMENTAL
//============================================================================================
	#define HIDE_EXPERIMENTAL 1 //Hides experimental or unfinished features
//============================================================================================
#endif

#ifndef HIDE_ADVANCED
//============================================================================================
	#define HIDE_ADVANCED 1 //Hides advanced settings that you probably shouldn't touch
//============================================================================================
#endif

#ifndef HIDE_INTERMEDIATE
//============================================================================================
	#define HIDE_INTERMEDIATE 1 //Hides experimental or unfinished features
//============================================================================================
#endif

#ifndef IMPORT_SAM
//============================================================================================
	#define IMPORT_SAM 0 //Hides experimental or unfinished features
//============================================================================================
#endif


#ifndef ZNRY_MV_TYPE
//============================================================================================
	#define ZNRY_MV_TYPE 0 //Vort, other, launchpad
//============================================================================================
#endif

#define RES float2(BUFFER_WIDTH, BUFFER_HEIGHT)
#define FARPLANE RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
#define ASPECT_RATIO RES.x/RES.y

uniform int FRAME_COUNT <
	source = "framecount";>;



static int2 TAA_SAM_DST[8] = {
		int2(1,-3), int2(-1,3), 
		int2(5,1), int2(-3,-5),
		int2(-5,5), int2(-7,-1),
		int2(3,7), int2(7,-7)};

uniform int ZN_DAMPRT <
	ui_label = " ";
	ui_text = "NOTE: Read the 'Preprocessor Info' and enable motion vectors before using\n\n"
			"Zentient DAMP RT (Depth Aware Mipmapped Ray Tracing) is a shader built around\n"
			"sampling miplevels in order to approximate cone tracing in 2D space\n"
			"before extrapolating into 3D \n"
			"While not directly taken from any papers, it was heavily inspired after seeing\n"
			"Alexander Sannikov's approach to calculating GI with radiance cascasdes.\n";
	ui_type = "radio";
	ui_category = "ZN DAMP RT";
> = 1;  

uniform float BUFFER_SCALE <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 5.0;
	ui_label = "Buffer Scale";
	ui_tooltip = "Adjusts the accuracy of the depth buffer for closer objects";
	ui_category = "Depth Buffer Settings";
	hidden = true;
> = 2.0;

uniform float NEAR_PLANE <
	ui_type = "slider";
	ui_min = -1.0;
	ui_max = 2.0;
	ui_label = "Near Plane";
	ui_tooltip = "Adjust min depth for depth buffer, increase slightly if dark lines or occlusion artifacts are visible";
	ui_category = "Depth Buffer Settings";
	ui_category_closed = true;
	hidden = HIDE_ADVANCED;
> = 0.0;

uniform float FOV <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 110.0;
	ui_label = "FOV";
	hidden = true;
	ui_tooltip = "Adjust to match ingame FOV";
	ui_category = "Depth Buffer Settings";
	ui_step = 1;
> = 70;

uniform bool SMOOTH_NORMALS <
	ui_label = "Smooth Normals";
	ui_tooltip = "Smooths normals to fake higher poly models || Moderate Performance Impact";
	ui_category = "Depth Buffer Settings";
	hidden = HIDE_EXPERIMENTAL;
> = 0;

uniform float INTENSITY <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 20.0;
	ui_label = "GI Intensity";
	ui_tooltip = "Intensity of the effect. It goes up to 40, I don't recommend keeping it there";
	ui_category = "Display";
	ui_category_closed = true;
> = 6.0;

uniform float SHADOW_INT <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Shadow Intesity";
	ui_tooltip = "Darkens shadows before adding GI to the image";
	ui_category = "Display";
> = 0.8;

uniform float SHADOW_GAMMA <
	ui_type = "slider";
	ui_min = 0.01;
	ui_max = 2.0;
	ui_label = "Shadow Gamma";
	ui_tooltip = "Gamma applied to shadow before blending";
	hidden = HIDE_INTERMEDIATE;
	ui_category = "Display";
> = 1.0;


uniform float3 SKY_COLOR <
	ui_type = "color";
	ui_label = "Ambient Color";
	ui_tooltip = "Adds ambient light to the scene";
	ui_category = "Display";
> = float3(0.45, 0.45, 0.5);

uniform float LIGHTMAP_SAT <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_label = "LightMap saturation";
	ui_tooltip = "Boosts lightmap saturation to compensate for downsampling";
	hidden = HIDE_INTERMEDIATE;
	ui_category = "Display";
	ui_category_closed = true;
> = 1.2;

uniform float HDR_RED <
	ui_type = "slider";
	ui_min = 1.01;
	ui_max = 1.6;
	ui_label = "HDR Reduction";
	ui_tooltip = "Reduces the maximum difference between light and dark areas";
	hidden = HIDE_INTERMEDIATE;
	ui_category = "Display";
	ui_category_closed = true;
> = 1.1;

uniform bool DO_BOUNCE <
	ui_label = "Bounce lighting";
	ui_tooltip = "Accumulates GI from previous frames to calculate extra GI steps || No Performance Impact";
	ui_category = "Display";
	hidden = HIDE_INTERMEDIATE;
> = 1;

uniform float TERT_INTENSITY <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Bounce intensity";
	ui_tooltip = "Intensity of accumulated bounce lighting, has a compounding effect on GI";
	ui_category = "Display";
	hidden = HIDE_INTERMEDIATE;
	ui_category_closed = true;
> = 0.5;

uniform float AMBIENT_NEG <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Exposure Reduction";
	ui_tooltip = "Reduces exposure before adding GI";
	ui_category = "Display";
> = 0.0;

uniform bool DO_AO <
	ui_label = "Ambient occlusion";
	ui_tooltip = "Lightweight ambient occlusion implementation || Low performance impact";
	ui_category = "Display";
> = 1;

uniform float DEPTH_MASK <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 10.0;
	ui_label = "Depth Mask";
	ui_tooltip = "Depth dropoff to allow compatibility with in game fog";
	ui_category = "Display";
> = 0.08;	

uniform float COLORMAP_BIAS <
	ui_type = "slider";
	ui_label = "Colormap Bias";
	ui_tooltip = "Normalizes the color buffer, recommended to keep very close to 1.0";
	ui_category = "Colors";
	ui_category_closed = true;
	hidden = HIDE_ADVANCED;
	ui_min = 0.9;
	ui_max = 1.0;
> = 0.997;

uniform float COLORMAP_OFFSET <
	ui_type = "slider";
	ui_label = "Colormap Offset";
	hidden = HIDE_ADVANCED;
	ui_tooltip = "Attempts to reduce artifacts in dark colors, but can wash them out in certain scenes";
	ui_category = "Colors";
	ui_min = 0.0;
	ui_max = 0.01;
> = 0.001;

uniform float3 DETINT_COLOR <
	ui_type = "color";
	ui_label = "Detint Color";
	ui_tooltip = "Can help remove certain boosted colors from the GI (ex. Purple shadows)";
	ui_category = "Colors";
> = float3(0.06, 0.45, 1.0);

uniform float DETINT_LEVEL <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Detint Strength";
	ui_tooltip = "The amount of Detinting applied";
	ui_category = "Colors";
> = 0.0;

uniform bool TAA_ERROR <
	ui_label = "Temporal Smoothing";
	ui_tooltip = "Reduces noise almost completely when paired with a motion vector shader, disable if not using one\n"
				"vort_motion or qUINT_MotionVectors recommended, although it should be compatible with most motion vectors";
	ui_category = "Denoising";
	ui_min = 0.0;
	ui_max = 1.0;
> = 1.0;

uniform bool DONT_SPATIAL <
	ui_label = "Disable Spatial Denoising";
	ui_tooltip = "Disables the spatial upscaler/denoiser before temporal denoising";
	ui_category = "Denoising";
	hidden = HIDE_ADVANCED;
> = 0;

uniform float TAA_SKIP <
	ui_type = "slider";
	ui_label = "Temporal Skipping";
	ui_tooltip = "Helps reduce flickering when no motion vectors are available\n"
					"Set to 2 if not using motion vectors";
	ui_category = "Denoising";
	ui_min = 1.0;
	ui_max = 2.0;
	ui_step = 1.0;
> = 1.0;

uniform float FRAME_PERSIST <
	ui_type = "slider";
	ui_label = "Frame Persistence";
	ui_tooltip = "Lower values will have less ghosting but more noise, higher values will have lower noise but more ghosting\n";
	ui_category = "Denoising";
	ui_min = 0.1;
	ui_max = 0.95;
> = 0.875;

uniform int UPSCALE_ITER <
	ui_type = "slider";
	ui_label = "Denoiser Samples";
	ui_tooltip = "Reduces noise and improves upscaling at the cost of detail and performance";
	ui_min = 2;
	ui_max = 64;
> = 8;	

uniform int SAMPLE_COUNT <
	ui_type = "slider";
	ui_label = "Ray count";
	ui_min = 3;
	ui_max = 24;
	ui_tooltip = "How many rays are cast per pixel. Massively diminishing returns over 6 || Large Performance Impact";
	ui_category = "Sampling";
	ui_category_closed = true;
> = 5;



uniform bool SHADOW <
	ui_label = "Shadows";
	ui_tooltip = "Rejects some samples to cast soft shadows, essentially a pretty nice AO || Almost No Performance Impact";
	ui_category = "Sampling";
	hidden = HIDE_INTERMEDIATE;
> = 1;

uniform bool ENABLE_Z_THK <
	ui_label = "Enable Z thickness";
	ui_tooltip = "Enables thickness for shadow occlusion to prevent shadow haloing || Low Performance Impact";
	ui_category = "Sampling";
	hidden = HIDE_INTERMEDIATE;
> = 1;

uniform float SHADOW_Z_THK <
	ui_type = "slider";
	ui_label = "Z Thickness";
	ui_tooltip = "Depth of cast shadows";
	ui_category = "Sampling";
	hidden = HIDE_INTERMEDIATE;
	ui_min = 0.001;
	ui_max = 1.0;
> = 0.01;

uniform float SHADOW_BIAS <
	ui_type = "slider";
	ui_label = "Shadow Bias";
	ui_tooltip = "Reduces artifacts and intensity of shadows";
	ui_category = "Sampling";
	hidden = HIDE_ADVANCED;
	ui_min = -0.01;
	ui_max = 0.01;
> = 0.001;

uniform bool BLOCK_SCATTER <
	ui_label = "Block Scattering";
	ui_tooltip = "Prevents surface scattering and brightening of already bright areas || Low-Medium Performance Impact";
	ui_category = "Sampling";
	hidden = HIDE_INTERMEDIATE;
> = 1;

uniform float RAY_LENGTH <
ui_type = "slider";
	ui_min = 0.5;
	ui_max = 10.0;
	ui_label = "Ray Step Length";
	ui_tooltip = "Changes the length of ray steps per Mip, reduces overall sample quality but increases ray range || Moderate Performance Impact"; 
	ui_category = "Sampling";
	hidden = HIDE_INTERMEDIATE;
> = 4.0;

uniform float DIST_BIAS <
ui_type = "slider";
	ui_min = 0.0;
	ui_max = 2.0;
	ui_label = "Distance Bias";
	ui_tooltip = "Gives distant samples a slightly higher weight to account for incomplete sampling || No Performance Impact"; 
	ui_category = "Sampling";
	hidden = HIDE_INTERMEDIATE;
> = 0.25;

uniform float DISTANCE_SCALE <
	ui_type = "slider";
	ui_min = 0.01;
	ui_max = 20.0;
	ui_label = "Distance Scale";
	ui_tooltip = "The scale at which brightness calculations are made\n"
				"Higher values cause light to disperse more quickly, lower values will cause light to propogate furtherm.\n"
					"Note that lower values aren't particularly 'better'"; 
	ui_category = "Sampling";
	hidden = HIDE_INTERMEDIATE;
> = 1.0;

uniform float DISTANCE_POW <
ui_type = "slider";
	ui_min = 0.5;
	ui_max = 3.0;
	ui_label = "Distance Power";
	ui_tooltip = "The inverse power light dissipates from, 2.0 is inverse square, 1.0 is linear";
	ui_category = "Sampling";
	hidden = HIDE_ADVANCED;
> = 2.0;

uniform int DEBUG <
	ui_type = "combo";
	ui_category = "Debug Settings";
	ui_items = "None\0Lighting\0GI * Color Map\0GI\0Shadows\0Color Map\0DeGhosting mask\0Normals\0Depth\0LightMap\0";
	hidden = HIDE_INTERMEDIATE;
> = 0;

uniform bool SHOW_MIPS <
	ui_label = "Display Mipmaps";
	ui_category = "Debug Settings";
	ui_tooltip = "Just for fun, for anyone wanting to visualize how it works\n"
		"recommended to use either the lighting or GI debug view";
	hidden = HIDE_INTERMEDIATE;
> = 0;

uniform bool STATIC_NOISE <
	ui_label = "Static Noise";
	ui_category = "Debug Settings";
	ui_tooltip = "Disables sample jittering";
	hidden = HIDE_ADVANCED;
> = 0;

uniform bool DONT_DENOISE <
	ui_category = "Debug Settings";
	ui_label = "Disable Temporal Denoising";
	hidden = HIDE_ADVANCED;
> = 0;


uniform float SPECULAR_POW <
	ui_type = "slider";
	ui_min = 0.5;
	ui_max = 10.0;
	ui_label = "Reflection power";
	ui_tooltip = "Diffuse reflection power, only works if experimental reflections are enabled";
	hidden = 1 - DO_REFLECT;
> = 2.0;

uniform int TONEMAPPER <
	ui_type = "combo";
	ui_items = "ZN Filmic\0Sony A7RIII\0ACES\0Modified Reinhard Jodie\0None\0"; //Contrast\0
	ui_label = "Tonemapper";
	ui_tooltip = "Tonemapper Selection, Reinhardt Jodie is the truest to original image, but other options are included";
	ui_category = "Experimental";
	hidden = HIDE_EXPERIMENTAL;
> = 3;

uniform bool DYNA_SAMPL <
	ui_category = "Experimental";
	ui_label = "Dynamic Sampling";
	ui_tooltip = "Applies sample amount dynamically to save performance";
	hidden = HIDE_EXPERIMENTAL;
> = 0;

uniform bool REMOVE_DIRECTL <
	ui_label = "Brightness Mask";
	ui_tooltip = "Prevents excessive illumination in already lit areas, but tends to reduce local contrast significantly || No Performance Impact";
	ui_category = "Experimental";
	hidden = true;
> = 0;


uniform int PREPRO_SETTINGS <
	ui_type = "radio";
	ui_category = "Preprocessor Info";
	ui_category_closed = true;
	ui_text = "Preprocessor Definition Guide:\n"
			"\n"
			"NOTE: ONLY CHANGE PREPROCESSORS IF YOU KNOW WHAT YOU ARE DOING, IF CHANGEING A SETTING CAUSES COMPILER FAILURE, MAKE A NEW PRESET OR CLEAR OUT THE DAMP PREPROCESSOR SETTINGS IN THE RESHADEPRESET.ini\n"
			"\n"
			"DO_REFLECT - Enables experimental diffuse reflections, unfinished, quite innacurate, and has a substantial performance impact\n"
			"\n"
			"HIDE INTERMEDIATE/ADVANCED/EXPERIMENTAL - Displays varying levels of advanced settings, experimental settings are unfinished and untested\n"
			"\n"
			"IMPORT_SAM - Toggles experimental importance sampling to cherry pick results, has a moderate performance impact, and generally provides worse results\n"
			"\n"
			"ZNRY_MAX_LODS - The maximum LOD sampled, has a direct performance impact, and an exponential impact on ray range. Max recommended is 7, max generally is 9 but may cause compiler failure at low resolution scales\n"
			"7 is usually enough for near fullscreen coverage\n"
			"\n"
			"ZNRY_MV_TYPE - Selects the motion vector shader to use: 0 for vort_Motion, 1 for launchpad, and 2 for most others (qUINT, Uber, etc)\n"
			"Note that motion vectors must be properly configured to prevent noise and ghosting\n"
			"\n"
			"ZNRY_RENDER_SCL - The resolution scale for GI (0.5 is 50%, 1.0 is 100%), changes may require reloading ReShade.\n"
			"\n"
			"ZNRY_SAMPLE_DIV - The miplevel of sampled textures (ex, 4 is 1/4 resolution, 2 is half resolution, 1 is full resolution)\n"
			"This has a moderate performance impact, with minimal quality improvements and negative effects on range, not recommended to set below 2";
> = 1;

uniform int CREDITS <
	ui_type = "radio";
	ui_category = "Credits";
	ui_text = "\nCredits and thanks:\n"
			"A big thanks to, Soop, Beta|Alea, Can, AlucardDH, BlueSkyDefender, Ceejay.dk and Dreamt for shader testing and feedback\n"
			"And a thank you to BlueSkyDefender, Vortigern, and LordofLunacy\n"
			"for being crazy enough to try and understand bits of the spaghetti code that is this shader\n"
			"And a big thank you to Crushius for providing me with a copy of 'Shadow Man Remastered' so I could test in something other than Skyrim\n"
			"If you did help with development and I forgot to mention you here, please reach out so I can amend the credits";
	ui_label = " ";
> = 0;

uniform int SHADER_VERSION <
	ui_type = "radio";
	ui_text = "\n" "Shader Version - Test Release A26-3-0 (v0.2.6.3.0)";
	ui_label = " ";
> = 0;



//============================================================================================
//Textures/Samplers
//=================================================================================
namespace A26{
	texture BlueNoiseTex < source = "ZNbluenoise512.png"; >
	{
		Width  = 512.0;
		Height = 512.0;
		Format = RGBA8;
	};
	sampler NoiseSam{Texture = BlueNoiseTex; MipFilter = Point;};
	
	texture NorTex{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 3;};
	sampler NorSam{Texture = NorTex;};
	
	texture NorDivTex{
		Width = BUFFER_WIDTH / ZNRY_SAMPLE_DIV;
		Height = BUFFER_HEIGHT / ZNRY_SAMPLE_DIV;
		Format = RGBA8;
		MipLevels = ZNRY_MAX_LODS;
	};
	sampler NorDivSam{
		Texture = NorDivTex;
		MinFilter = POINT;
		MagFilter = POINT;
		MipFilter = POINT;
	};
	
	texture NorInTex{
		Width = BUFFER_WIDTH;
		Height = BUFFER_HEIGHT;
		Format = RGBA8;
		MipLevels = ZNRY_MAX_LODS;
	};
	sampler NorInSam{Texture = NorInTex;};
	
	texture BufTex{
		Width = int(BUFFER_WIDTH * ZNRY_RENDER_SCL / ZNRY_SAMPLE_DIV);
		Height = int(BUFFER_HEIGHT * ZNRY_RENDER_SCL / ZNRY_SAMPLE_DIV);
		Format = R32F;
		MipLevels = ZNRY_MAX_LODS;
	};
	sampler DepSam{
		Texture = BufTex;
		MinFilter = POINT;
		MagFilter = POINT;
		MipFilter = POINT;
	};
	
	texture BilaTex{
		Width = int(BUFFER_WIDTH * ZNRY_RENDER_SCL);
		Height = int(BUFFER_HEIGHT * ZNRY_RENDER_SCL);
		Format = RGBA8;
		MipLevels = ZNRY_MAX_LODS;
	};
	sampler BilaSam{Texture = BilaTex;};
	texture LumTex{
		Width = int(BUFFER_WIDTH * ZNRY_RENDER_SCL / ZNRY_SAMPLE_DIV);
		Height = int(BUFFER_HEIGHT * ZNRY_RENDER_SCL / ZNRY_SAMPLE_DIV);
		Format = RGBA16F;
		MipLevels = ZNRY_MAX_LODS + 1;
	};
	sampler LumSam{Texture = LumTex;};
	
	texture GITex{
		Width = int(BUFFER_WIDTH * ZNRY_RENDER_SCL);
		Height = int(BUFFER_HEIGHT * ZNRY_RENDER_SCL);
		Format = RGBA16F;MipLevels = 3;
	};
	sampler GISam{
		Texture = GITex;
	};
	texture UpscaleTex{
		Width = BUFFER_WIDTH;
		Height = BUFFER_HEIGHT;
		Format = RGBA16F;MipLevels = 3;
	};
	sampler UpSam{
		Texture = UpscaleTex;
	};
	
	texture PreTex {
		Width = BUFFER_WIDTH;
		Height = BUFFER_HEIGHT;
		Format = RGBA8;
	};
	sampler PreFrm {Texture = PreTex;};
	
	texture PreLuminTex {
		Width = int(BUFFER_WIDTH * ZNRY_RENDER_SCL);
		Height = int(BUFFER_HEIGHT * ZNRY_RENDER_SCL);
		Format = R32F;
		MipLevels = 2;
	};
	sampler PreLumin {Texture = PreLuminTex;};
	
	texture CurTex {
		Width = BUFFER_WIDTH;
		Height = BUFFER_HEIGHT;
		Format = RGBA8;
		MipLevels = 3;
	};
	sampler CurFrm {Texture = CurTex;};
	
	texture DualTex {
		Width = BUFFER_WIDTH;
		Height = BUFFER_HEIGHT; 
		Format = RGBA8; MipLevels = 3;
	};
	sampler DualFrm {Texture = DualTex;};	
}



#define MV_TEX_PROPS {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F;};
#define POINT_SAM MagFilter = POINT; MinFilter = POINT; MipFilter = POINT;

#if(ZNRY_MV_TYPE == 2)
texture2D texMotionVectors MV_TEX_PROPS	
sampler motionSam {Texture = texMotionVectors; POINT_SAM};

#elif(ZNRY_MV_TYPE == 1)
namespace Deferred {
	texture2D MotionVectorsTex MV_TEX_PROPS
}	
sampler motionSam {Texture = Deferred::MotionVectorsTex; POINT_SAM};

#else
texture2D MotVectTexVort MV_TEX_PROPS	
sampler motionSam {Texture = MotVectTexVort; POINT_SAM};
#endif
//============================================================================================
//Tonemappers
//============================================================================================


float3 SONYA7RIII(float3 z) //This is a custom tonemapper modeled after the SONY A7RIII sensor
{							//It looks somewhat bad
    float a = 0.1;
    float b = 1.1;
    float c = 0.5;
    float3 d = float3(0.02, 0.01, 0.02);
    float e = 1.3;
    float f = 4.8;
    float g = 0.3;
    float h = 2.0;
    float i = 0.2;
    float j = 0.6;
    float k = 1.3;
    float l = 2.5;
    
    z *= 20.0;
    z = h*(c+pow(a*z,b)-d*(sin(e*z)-j)/((k*z-f)*(k*z-f)+g));
    z = i*l*log(z);
    
    return saturate(z);
}

float3 ReinhardtJ(float3 x) //Modified Reinhardt Jodie
{
	float  lum = dot(x, float3(0.2126, 0.7152, 0.0722));
	float3 tx  = x / (x + 1.0);
	return HDR_RED * lerp(x / (lum + 1.0), tx, pow(tx, 0.7));
}

float3 InvReinhardtJ(float3 x)
{
	float  lum = dot(x, float3(0.2126, 0.7152, 0.0722));
	float3 tx  = -x / (x - HDR_RED);
	return lerp(tx, -lum / ((0.5 * x + 0.5 * lum) - HDR_RED), pow(x, 0.7));
}

float3 ZNFilmic(float3 x)
{
	float a = 17.36;
	float b = 16.667;
	float c = 3.0;
	float d = 0.4;
	return saturate((a*x*x+d*x) / (b*x*x + c*x + 1.0));
}

float3 ACESFilm(float3 x)
{
	float a = 2.51f;
	float b = 0.03f;
	float c = 2.43f;
	float d = 0.59f;
	float e = 0.14f;
	return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

//============================================================================================
//Functions
//============================================================================================

float3 saturation(float3 c, float sat)
{
	float lum = c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722;
	c	 	= lerp(lum, c, sat);
	return saturate(c);
}

float3 eyePos(float2 xy, float z)//takes screen coords (0-1) and depth (0-1) and converts to eyespace position
{
	float  nd	 = z * FARPLANE;
	float3 eyp	= float3((2f * xy - 1f) * nd, nd);
	return eyp * float3(ASPECT_RATIO, 1.0, 1.0);
}

float3 NorEyePos(float2 xy)//takes screen coords (0-1) and depth (0-1) and converts to eyespace position
{
	float  nd	 = ReShade::GetLinearizedDepth(xy) * FARPLANE;
	float3 eyp	= float3((2f * xy - 1f) * nd, nd);
	return eyp * float3(ASPECT_RATIO, 1.0, 1.0);
}

float3 GetScreenPos(float3 xyz)//takes eyespace position and reprojects to screenspace
{
	xyz /= float3(ASPECT_RATIO, 1.0, 1.0);
	return float3(0.5 + 0.5 * (xyz.xy / xyz.z), xyz.z / FARPLANE);
}

int weighthash(float2 p, float w1, float w2) //For importance sampling
{
	float3 p3	= frac(float3(p.xyx) * .1031);
    	   p3	+= dot(p3, p3.yzx + 33.33);
    float  hsh   = frac((p3.x + p3.y) * p3.z);
    float  c	 = w1 / (w1 + w2);
    
    if(hsh < c) return 0;
    else return 1;
}

float2 hash(float2 p)
{
	float3 p3	= frac(p.xyx * float3(.1031, .1030, .0973));
    	   p3	+= dot(p3, p3.yzx+33.33);
    return frac((p3.xx+p3.yz)*p3.zy);
}

float hash12(float2 p)
{
	float3 p3  = frac(p.xyx * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

float3 hash3(float3 x)
{
	x		= frac(x * float3(.1031, .1030, .0973));
    x		+= dot(x, x.yxz+33.33);
    return   frac((x.xxy + x.yxx)*x.zyx);
}

float4 DAMPGI(float2 xy, float2 offset)//offset is noise value, output RGB is GI, A is shadows;
{
float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float  f	 = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	float  n	 = NEAR_PLANE;
	float2 PW	= 2.0 * tan(FOV * 0.00875) * (f - n); //Dimensions of FarPlane
		   PW.y *= res.x / res.y;

	int	LODS  = ZNRY_MAX_LODS;
    float  trueD = ReShade::GetLinearizedDepth(xy);
    	if(trueD == 1.0) {return float4(0.0, 0.0, 0.0, 1.0);}
    float3 surfN = 2.0 * tex2D(A26::NorSam, xy).rgb - 1.0;
    
    float  d	 = trueD;
    float3 rp	= float3(xy, d);
    float3 l;	//Light accumulation value
   
    float  occ;
    float3 trueC = pow(tex2D(A26::LumSam, xy).rgb, 1.0 / 2.2);

	int sampl = SAMPLE_COUNT;   
	if(DYNA_SAMPL) sampl = 1 + ceil((1.0 - 0.33 * (trueC.r + trueC.g + trueC.b)) * max(SAMPLE_COUNT - 1, 0));
	float3 actSam; //Active reseviour sample
	float  resW; //Reseviour weight
	float  iW;	//Sample weights
    for(int i = 0; i < sampl; i++){
    	
    	d =  trueD;
    	int iLOD = 0;
    		   rp	  = float3(xy, d);
    	float3 minD	= 1.0;//rp;//float3(rp.xy, 1.0);
    	float3 maxD	= 0.0;//float3(rp.xy, 0.0);
    	float2 vec	 = float2(sin((6.28 * offset.r) + (i+1) * 6.28 / sampl), cos((6.28 * offset.r) + (i+1) * 6.28 / sampl));
    	float3 pixP	= float3(xy, trueD);
    	
 	   for(int ii = 2; ii <= ZNRY_MAX_LODS; ii++)
    	{
    		//Max shadow vector calculation
    		float3 compVec0	= normalize(rp - pixP + 0.000001);
    		float3 compVec1	= normalize(minD - pixP + 0.000001);
    		float3 compVec2	= normalize(maxD - pixP + 0.000001);
			//float3 compVec2	= normalize(maxD - pixP + 0.000001);			
			if(compVec0.z <= compVec1.z) {minD = rp;} 
			if(compVec0.z >= compVec1.z) {maxD = float3(rp.xy, rp.z + SHADOW_Z_THK);} 
    		
			//Ray vector and depth calculations
			float2 rd = offset.xy * abs(SHOW_MIPS - 1.0);
			//	   rd += (0.5 * surfN.xy);//Biases sampling group
   
    		rp.xy += (RAY_LENGTH * (vec + rd) * pow(2, ii)) / res;
    		if(rp.x > 1.0 || rp.y > 1.0) {break;}
    		if(rp.x < 0 || rp.y < 0) {break;}
    		
			d = tex2Dlod(A26::DepSam, float4(rp.xy, 0, floor(0.75 * iLOD))).r;
    		rp.z = d;
    		
    		
    		//Occlusion calculations
   		 float sh;
   		 if(SHADOW == 0) {sh = 1.0;}
   		 float3 eyeXY	 = eyePos(rp.xy, rp.z);
			float3 texXY	 = eyePos(xy, trueD);
   		 float3 shvMin	= normalize(minD - pixP);
   		 float3 shvMax	= normalize(maxD - pixP);
   		 float  shd	   = distance(rp, float3(xy, trueD));
   		 float  sb		= SHADOW_BIAS;
   		 bool   zd;		//= d >= (trueD + shd * shvMax.z);
   		 
			if(ENABLE_Z_THK) zd = d > (trueD + shd * shvMax.z + SHADOW_Z_THK) - sb;		 
   		 if(d <= (trueD + shd * shvMin.z) + sb || zd) {sh = 1.0;}
			
			//Diffuse Lighting calculations
			float3 col = tex2Dlod(A26::LumSam, float4(rp.xy, 0, iLOD)).rgb;
			float  smb = 1.0;
			
			if(BLOCK_SCATTER)
			{
				float3 nor = 2.0 * tex2Dlod(A26::NorDivSam, float4(rp.xy, 0, iLOD)).rgb - 1.0;
				float3 lv2 = normalize(eyePos(pixP.xy, pixP.z) - eyePos(rp.xy, rp.z) );
				smb = 4.0 * max(dot(nor, lv2), 0.0);
			}
				
			float  ed	 = 1.0 + pow(abs((DISTANCE_SCALE * distance(texXY, 0.0))), DISTANCE_POW) / f;
			float  cd	 = 1.0 + pow(abs((DISTANCE_SCALE * distance(eyeXY, texXY))), DISTANCE_POW) / f;
			float3 lv	 = normalize(eyePos(rp.xy, rp.z) - eyePos(pixP.xy, pixP.z));
			float  amb	= max(dot(surfN, lv), 0.0);
				   //sh 	+= length(col) / LODS;
			float  rfs	= 1.0;
			#if DO_REFLECT
				float3 vVec = normalize(NorEyePos(xy));
				float3 rVec = reflect(vVec, surfN);
				rfs = pow(0.5 + 0.5 * dot(lv, rVec), SPECULAR_POW);
			#endif
			
			col *= ed;
			float3 lAcc = smb * amb * (col / (cd *ed));//(pow(4.0, iLOD) / (4.0 * cd)) * 
			l += rfs * sh * lAcc * pow(1.0 + DIST_BIAS, iLOD);
			occ += amb * sh * saturate(length(col) / ed);//1.0 / ((ii + 1.0) - pow(distance(eyePos(minD.xy, minD.z), texXY) * f, 2.0));
			
			iW += (lAcc.r + lAcc.g + lAcc.b); //Accumulation for weighted sampling
			iLOD++;	
    	}
    	#if IMPORT_SAM
    		if(weighthash(abs(vec), resW, iW) == 1) {actSam = l; resW += iW;}
    		l = 0.0; actSam *= 1.0; iW = 0.0;
    	#endif
    }
    #if IMPORT_SAM
		l = actSam;
	#endif    
    l /= sampl / 16.0;
	l = pow(l / LODS, 1.0 / 2.2);// / (2.0 * pow(2.0, LODS))
	occ = saturate(4.0 * length(l + 0.01) * length(tex2D(A26::LumSam, xy)));//saturate(0.1 + occ);////saturate(2.0 * occ / (sampl * LODS));
	
	float4 result = float4(l, pow(occ, SHADOW_GAMMA));
		   //result = result / (result + 1.0);
	return max(0.001, result);//Prevents negative values from entering the denoiser
}

float3 tonemap(float3 input)
{
	input = max(0.0, input);
	if(TONEMAPPER == 0) input = ZNFilmic(input);
	if(TONEMAPPER == 1) input = SONYA7RIII(input);
	if(TONEMAPPER == 2) input = ACESFilm(input);
	if(TONEMAPPER == 3) input = ReinhardtJ(input);
	if(TONEMAPPER == 4) {return pow(input, 1.0 / 2.2);}
	if(TONEMAPPER == 5) input = pow(input, 0.5 * input + 1.0);
	input = pow(input, 1.0 / 2.2);
	return saturate(input);
}

float SampleAO(float2 xy, float SampleLength, float Thickness)
{
	float3 NormalVector	= 2f * tex2Dlod(A26::NorSam, float4(xy, 0, 0)).xyz - 1f;
	float  PixelDepth	  = ReShade::GetLinearizedDepth(xy);
	float3 PixelPos		= NorEyePos(xy);//GetEyePos(xy, PixelDepth);
	
	float Accumulate;
	#define SMP 8
	[loop]
	for(int i; i < SMP; i++)
	{
		float3 rVec = normalize(2f * hash3(float3(xy * RES, i)) - 1f);
			   rVec = SampleLength * normalize(rVec + NormalVector);
		
		float3 nPos = GetScreenPos(PixelPos + rVec);
		float  nDep = ReShade::GetLinearizedDepth(nPos.xy);
		
		if(nPos.z > nDep && nPos.z < nDep + Thickness) Accumulate++;//= distance(nPos.z, nDep);
	}
	return 1.0 - Accumulate / SMP;
}

float3 BlendGI(float3 input, float4 GI, float depth, float2 xy)
{
	float dAccp = 1.0 - DEPTH_MASK;
	input	   = pow(input, 2.2);
	float3 ICol = saturate(input);
		   ICol = lerp(normalize(ICol + COLORMAP_OFFSET) / 0.577, input, 0.5 + 0.5 * COLORMAP_BIAS);
		   
	float  ILum = (input.r + input.g + input.b) / 3.0;
	float3 iGI;
	GI.rgb	  = pow(GI.rgb, 2.2);
	GI.rgb	  *= 1.0 + (1.0 - DETINT_COLOR) * pow(DETINT_LEVEL, 7.0);
	GI.rgb	  /= exp(pow(15.0 * depth * DEPTH_MASK, 2.0));
	GI.a		=  lerp(1.0, GI.a, 1.0 / exp(pow(15.0 * depth * DEPTH_MASK, 2.0)));
	float GILum = (GI.r + GI.g + GI.b) / 3.0;
	
	
	if(REMOVE_DIRECTL == 0) {ILum = 0.0;}
	
	
		 if(DEBUG == 2) {input = saturate(INTENSITY * GI.rgb) * ICol;}
	else if(DEBUG == 3) {input = saturate(GI.rgb);}
	else if(DEBUG == 4) {input = saturate(pow(GI.a, 2.2));}
	else if(DEBUG == 1)
	{
		input	= 0.33;//normalize(input) / 0.577 * pow((input.r + input.g + input.b) / 3.0, 1.0 + AMBIENT_NEG);//Exposure
		input	= input * GI.a;
		iGI	  = INTENSITY * (GI.rgb);
		//input = GI.a * pow(lerp(1.0, GI.rgb, GILum), 3.0);
	}
	else if(DEBUG == 5) {input = ICol;}
	else
	{
		if(depth == 1.0) return - input / (input - 1.1);
		input	= normalize(input) / 0.577 * pow((input.r + input.g + input.b) / 3.0, 1.0 + AMBIENT_NEG);//Exposure
		input	= lerp(input, GI.a * input, SHADOW_INT);
		iGI	  = (INTENSITY * (GI.rgb - (ILum)) * ICol);
	}
	
	return iGI - input / (input - 1.1);
}


//Modified variance clamping for TAA denoising
float4 NbrClamp(sampler frame, float2 xy, float4 col, float deG)
{
	float2 res	 = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float2 mVec	= tex2D(motionSam, xy).xy;
	
	float4 m;
	float4 m1;
	float gam = 1.0;
	for(int i = 0; i <= 1; i++) for(int ii = 0; ii <= 1; ii++)
	{
		float2 coord = xy + TAA_SKIP * float2(i - 0.5, ii - 0.5) / res;
		float4 c 	= tex2Dlod(frame, float4(coord, 0, 1));
		float4 cb	= tex2Dlod(A26::PreFrm, float4(coord + mVec, 0, 1));
		
		c  = lerp(c, cb, FRAME_PERSIST * TAA_ERROR * round(1.0 - deG));//(max(exp((deG / 2.0) -deG), 0.0) + 0.2)
		m  += c;
		m1 += c*c;
	}
	float4 mu	  = m / 4.0;
	float4 sig	 = sqrt(m1 / 4.0 - mu * mu);
	float4 minC	= mu - sig * gam;
	float4 maxC	= mu + sig * gam;
	return clamp(col, minC, maxC);
}

//============================================================================================
//Buffer Definitions
//============================================================================================

//Saves LightMap and LODS
float4 LightMap(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	float2 res	   = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp		= 0.5 / res;
    float  offset	= 4.0;
	
    float3 acc =  tex2D(ReShade::BackBuffer, xy).rgb * 4.0;
		   acc += tex2D(ReShade::BackBuffer, xy - hp * offset).rgb;
	       acc += tex2D(ReShade::BackBuffer, xy + hp * offset).rgb;
	       acc += tex2D(ReShade::BackBuffer, xy + float2(hp.x, -hp.y) * offset).rgb;
	       acc += tex2D(ReShade::BackBuffer, xy - float2(hp.x, -hp.y) * offset).rgb;
		   acc /= 8.0;
	
	float  p 	= 2.2;
	float3 te	= acc;
		   te	= pow(te, p);	   	   
	
	te = saturate(saturation(te, LIGHTMAP_SAT));
	te = InvReinhardtJ(te);//-te / (te - 1.1);
	if(DO_BOUNCE)
	{
		float2 mVec	 =  tex2D(motionSam, xy).xy;
		float3 GISec	=  tex2Dlod(A26::DualFrm, float4(mVec + xy, 0, 2)).rgb;
		te += ((te) * 5.0 * pow(SKY_COLOR, 2.2)) + lerp(normalize(te), te, 0.9) * GISec * TERT_INTENSITY;
		
	}
	
	
	
	return float4(max(0, te), 1.0);
}

//Generates Normal Buffer from depth, as described here: https://atyuwen.github.io/posts/normal-reconstruction/
float4 NormalBuffer(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 vc	  = NorEyePos(texcoord);
	
	float3 vx0	  = vc - NorEyePos(texcoord + float2(1, 0) / RES);
	float3 vy0 	 = vc - NorEyePos(texcoord + float2(0, 1) / RES);
	
	float3 vx1	  = -vc + NorEyePos(texcoord - float2(1, 0) / RES);
	float3 vy1 	 = -vc + NorEyePos(texcoord - float2(0, 1) / RES);
	
	float3 vx = abs(vx0.z) < abs(vx1.z) ? vx0 : vx1;
	float3 vy = abs(vy0.z) < abs(vy1.z) ? vy0 : vy1;
	
	float3 output = 0.5 + 0.5 * normalize(cross(vy, vx));
	
	return float4(output, 1.0);
}

float4 NormalSmooth(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	if(!SMOOTH_NORMALS) return float4(tex2D(A26::NorInSam, texcoord).xyz, 1.0);
	float3 cCol;// = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 cNor = tex2D(A26::NorInSam, texcoord).xyz;
	float  cDep = ReShade::GetLinearizedDepth(texcoord);
	float  ang  = hash12(texcoord * RES);
	float  tw;
	#define ITER  4
	for(int i; i <= ITER; i++)
	{
		float2 npos = 15.0 * float2(sin(ang), cos(ang)) * hash12((texcoord + 0.5) * RES * (i + 1.0)) / RES;
		float3 rNor = tex2D(A26::NorInSam, texcoord + npos).xyz;
		float3 rCol = tex2D(A26::NorInSam, texcoord + npos).xyz;
		float  rDep = ReShade::GetLinearizedDepth(texcoord + npos);//tex2D(A26::DepSam, texcoord + npos).x;
		ang  += 6.28 / ITER;
		float wn  = pow(2.0 * max(dot(2.0 * rNor - 1.0, 2.0 * cNor - 1.0) - 0.5, 0.0), 1.0);//exp(min(dot(rNor, cNor) + 1.0, 1.0) * 12.0);
		float wd  = exp(-distance(rDep, cDep) / 0.00003);
			  tw += wn*wd;
		
		cCol += rCol * wn*wd;
	}
	if(tw < 0.00001) return float4(tex2D(A26::NorInSam, texcoord).xyz, 1.0);
	return float4(cCol / tw, 1.0);
}

//Renders GI to a texture for resolution scaling and blending
float4 RawGI(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	
	float2 bxy		= float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float2 MSOff	  = 1.0 * TAA_SAM_DST[FRAME_COUNT % 8] / (16.0 * bxy);
	float2 tempOff	= 1.0 * (1-STATIC_NOISE) * hash((1.0 + FRAME_COUNT % 128) * bxy);
		   tempOff	= floor(tempOff * RES) / RES;
		   
	float2 offset	= frac(0.4 + tempOff + texcoord * (bxy / (512 / ZNRY_RENDER_SCL)));
	float3 noise	 = tex2D(A26::NoiseSam, offset).rgb;
	
	float4 GI		= float4(DAMPGI(MSOff + texcoord, 3.0 * (0.5 - noise.xy)));
		   GI		= saturate(GI + 0.125 * (noise.r - 0.5));
	float  AO		= 1;
	if(DO_AO) AO	 = SampleAO(texcoord, noise.r, 0.001);
	return AO * (GI / (GI + 1.0));
	
}

float4 NormalDiv(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	return tex2Dlod(A26::NorSam, float4(texcoord, 0, 0));	
}
//Bilateral Upscaler
float4 UpFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	if(DONT_SPATIAL) return tex2D(A26::GISam, texcoord);
	float4 cCol;// = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 cNor = 2.0 * tex2D(A26::NorSam, texcoord).xyz - 1.0;//ReShade::GetLinearizedDepth(texcoord);
	float  cDep = ReShade::GetLinearizedDepth(texcoord);
	float  ang  = 6.28 * hash12(texcoord * RES * (FRAME_COUNT % 128));
	float  tw;
	for(int i; i <= UPSCALE_ITER; i++)
	{
		float2 npos = float2(sin(ang), cos(ang)) ;//hash12((texcoord + 0.5) * RES * (i + 1.0)) / RES;
			   npos = (1.0 / ZNRY_RENDER_SCL) * npos * (1.0 + i) / RES;
		float3 rNor = 2.0 * tex2D(A26::BilaSam, texcoord + npos).xyz - 1.0;
		float  rDep = tex2D(A26::PreLumin, texcoord + npos).r;
		float4 rCol = tex2D(A26::GISam, texcoord + npos);
		ang  += 12.56 / UPSCALE_ITER;
		float nw  = pow(max(dot(rNor, cNor) - 0.5, 0), 4.0);
		float dw  = exp(-distance(eyePos(texcoord, rDep), eyePos(texcoord, cDep)) * 3.0);
			  tw += nw * dw;
		
		cCol += rCol * nw * dw;
	}
	if(tw < 0.0001) return tex2D(A26::GISam, texcoord);
	return cCol / tw;
}

//Temporal Denoisers
float4 CurrentFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 CF	  = tex2D(A26::UpSam, texcoord);
	float2 mVec	= tex2D(motionSam, texcoord).xy;
	float3 nor	 = tex2D(A26::NorSam, texcoord).rgb;
	float3 CC	  = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float  CD	  = ReShade::GetLinearizedDepth(texcoord);//saturate(CC.r * 0.2126 + CC.g * 0.7152 + CC.b * 0.0722);
	float4 PF	  = tex2D(A26::PreFrm, texcoord + mVec);
	float  PD	  = tex2D(A26::PreLumin, texcoord + mVec).r;
	
	float  DeGhostMask = 1.0 - saturate(pow(abs(PD / CD), 12.0) + 0.02);//pow(1.0 - saturate(distance(CD, PD)), 1.0);
	CF = lerp(PF.rgba, CF, (1.0 - FRAME_PERSIST));
	CF = NbrClamp(A26::UpSam, texcoord, CF, DeGhostMask);
	return float4(CF);
}

float4 DualFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 CF	  = tex2D(A26::CurFrm, texcoord);
	float2 mVec	= tex2D(motionSam, texcoord).xy;
	float3 nor	 = tex2D(A26::NorSam, texcoord).rgb;
	float3 CC	  = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float  CD	  = ReShade::GetLinearizedDepth(texcoord);//saturate(CC.r * 0.2126 + CC.g * 0.7152 + CC.b * 0.0722);
	float4 PF	  = tex2D(A26::PreFrm, texcoord + mVec);
	float  PD	  = tex2D(A26::PreLumin, texcoord + 1.0 * mVec).r;
	
	float  DeGhostMask = 1.0 - saturate(pow(abs(PD / CD), 12.0) + 0.02);//pow(1.0 - saturate(distance(CD, PD)), 1.0);
	if(DEBUG == 6) {return DeGhostMask;}
	CF = lerp(PF.rgba, CF, (1.0 - FRAME_PERSIST));
	CF = NbrClamp(A26::CurFrm, texcoord, CF, DeGhostMask);
	return float4(CF);
}

float DrawDepth(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	return ReShade::GetLinearizedDepth(texcoord);
}

float DrawLum(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 c   = tex2D(ReShade::BackBuffer, texcoord).rgb;
	return saturate(c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722);
}

float4 PreviousFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	
	return tex2D(A26::CurFrm, texcoord);
}



//============================================================================================
//Main
//============================================================================================



float3 DAMPRT(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;
		   input = saturate(input);
	float4 GI;
	if(DONT_DENOISE) GI	= saturate(tex2Dlod(A26::UpSam, float4(texcoord, 0, 0)));
	else 			GI	= tex2Dlod(A26::DualFrm, float4(texcoord, 0, 0));
	float			depth = ReShade::GetLinearizedDepth(texcoord);
	if(depth > 0.99) return input;
	GI = 1.1 * -GI / (GI - 1.1);
	
	input = BlendGI(input, GI, depth, texcoord);
	float3 AmbientFog = pow(SKY_COLOR, 2.2) / exp(pow(15.0 * depth * DEPTH_MASK, 2.0));
	input = tonemap(input * (1.0 + 5.0 * AmbientFog));
	
	if(DEBUG == 6) {input = GI.rgb;}
	else if(DEBUG == 7) {input = tex2D(A26::NorSam, texcoord).rgb;}
	else if(DEBUG == 8) {input = tex2D(A26::DepSam, texcoord).r;}
	else if(DEBUG == 9) {input = tex2D(A26::LumSam, texcoord).rgb;}
	return input;
}

technique ZN_DAMPRT_A26 <
    ui_label = "DAMP RT A26-3-0";
    ui_tooltip ="Zentient DAMP RT - by Zenteon\n" 
				"The sucessor to SDIL, a much more efficient and accurate GI approximation";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LightMap;
		RenderTarget = A26::LumTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DrawDepth;
		RenderTarget = A26::BufTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalBuffer;
		RenderTarget = A26::NorInTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalSmooth;
		RenderTarget = A26::NorTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalDiv;
		RenderTarget = A26::NorDivTex;
	}

	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalDiv;
		RenderTarget = A26::BilaTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = RawGI;
		RenderTarget = A26::GITex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = UpFrame;
		RenderTarget = A26::UpscaleTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CurrentFrame;
		RenderTarget = A26::CurTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DualFrame;
		RenderTarget = A26::DualTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DrawDepth;
		RenderTarget = A26::PreLuminTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DAMPRT;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PreviousFrame;
		RenderTarget = A26::PreTex;
	}
	
}
