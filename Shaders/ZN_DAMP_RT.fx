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

Sponza Test: //https://mega.nz/#!qVwGhYwT!rEwOWergoVOCAoCP3jbKKiuWlRLuHo9bf1mInc9dDGE
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
	#if(BUFFER_HEIGHT <= 720)
		#define ZNRY_RENDER_SCL 90 //Render Scale (percent)
	#elif(BUFFER_HEIGHT <= 960)
		#define ZNRY_RENDER_SCL 80
	#elif(BUFFER_HEIGHT <= 1080)
		#define ZNRY_RENDER_SCL 67
	#elif(BUFFER_HEIGHT <= 1440)
		#define ZNRY_RENDER_SCL 60
	#elif(BUFFER_HEIGHT <= 2160)
		#define ZNRY_RENDER_SCL 50
	#else
		#define ZNRY_RENDER_SCL 40 
	#endif
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

uniform int FRAME_COUNT <
	source = "framecount";>;

static int2 TAA_SAM_DST[8] = {
		int2(1,-3), int2(-1,3), 
		int2(5,1), int2(-3,-5),
		int2(-5,5), int2(-7,-1),
		int2(3,7), int2(7,-7)};

uniform int ZN_DAMPRT <
	ui_label = " ";
	ui_text = "Zentient DAMP RT (Depth Aware Mipmapped Ray Tracing) is a shader built around"
			"sampling miplevels in order to approximate cone tracing in 2D space\n"
			"The data is then extrapolated into 3D based on depth information. \n"
			"While not directly taken from any papers, it was heavily inspired after seeing\n"
			"Alexander Sannikov's approach to calculating GI with radiance cascasdes.\n";
	ui_type = "radio";
	ui_category = "ZN DAMP RT";
	ui_category_closed = true;
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

uniform bool APPROX_NORMALS <
	ui_label = "Approximate Normals";
	ui_tooltip = "Uses less accurate normal approximations to speed up performance slightly";
	ui_category = "Depth Buffer Settings";
	hidden = HIDE_INTERMEDIATE;
> = 1;

uniform float INTENSITY <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 10.0;
	ui_label = "GI Intensity";
	ui_tooltip = "Intensity of the effect.";
	ui_category = "Display";
	ui_category_closed = true;
> = 3.0;

uniform float SHADOW_INT <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Shadow Intesity";
	ui_tooltip = "Darkens shadows before adding GI to the image";
	ui_category = "Display";
> = 0.7;

uniform float SKY_BRIGHT <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.5;
	ui_label = "Sky Brightness";
	ui_tooltip = "Intensity of skylight, may introduce noise and cause over brightening of distant objects";
	ui_category = "Display";
	ui_category_closed = true;
> = 0.0;

uniform float LIGHTMAP_SAT <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 3.0;
	ui_label = "LightMap saturation";
	ui_tooltip = "Boosts lightmap saturation to compensate for downsampling";
	hidden = HIDE_INTERMEDIATE;
	ui_category = "Display";
	ui_category_closed = true;
> = 1.0;

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
> = 0.35;

uniform float AMBIENT_NEG <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Exposure Reduction";
	ui_tooltip = "Reduces exposure before adding GI";
	ui_category = "Display";
> = 0.0;

uniform float DEPTH_MASK <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 0.95;
	ui_label = "Depth Mask";
	ui_tooltip = "Depth dropoff to allow compatibility with in game fog";
	ui_category = "Display";
> = 0.0;	

uniform float COLORMAP_BIAS <
	ui_type = "slider";
	ui_label = "Colormap Bias";
	ui_tooltip = "Normalizes the color buffer, recommended to keep very close to 1.0";
	ui_category = "Colors";
	ui_category_closed = true;
	hidden = HIDE_ADVANCED;
	ui_min = 0.9;
	ui_max = 1.0;
> = 0.995;

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
				"vort_motion or qUINT_MotionVectors recommended, although it should be compatible with most motion vectors (excluding launchpad)";
	ui_category = "Denoising";
	ui_min = 0.0;
	ui_max = 1.0;
> = 1.0;

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
> = 0.85;

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
	ui_tooltip = "Enables thickness for shadow occlusion to prevent shadow haloing|| Low Performance Impact";
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
> = 0.015;

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
	ui_max = 5.0;
	ui_label = "Ray Step Length";
	ui_tooltip = "Changes the length of ray steps per Mip, reduces overall sample quality but increases ray range || Moderate Performance Impact"; 
	ui_category = "Sampling";
	hidden = HIDE_INTERMEDIATE;
> = 2.5;

uniform float DISTANCE_SCALE <
ui_type = "slider";
	ui_min = 0.01;
	ui_max = 20.0;
	ui_label = "Distance Scale";
	ui_tooltip = "The scale at which brightness calculations are made\n"
				"Higher values cause light to disperse much more quickly, lower values will cause light to propogate further\n"
					"Note that lower values aren't particularly 'better' and 1-5 is generally the most 'realistic'"; 
	ui_category = "Sampling";
	hidden = HIDE_INTERMEDIATE;
> = 2.0;

uniform int DEBUG <
	ui_type = "combo";
	ui_category = "Debug Settings";
	ui_items = "None\0GI * Color Map\0GI\0Shadows\0Lighting\0Color Map\0DeGhosting mask\0Normals\0Depth\0LightMap\0";
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
	ui_items = "ZN Filmic\0Sony A7RIII\0ACES\0Reinhardt\0None\0"; //Contrast\0
	ui_label = "Tonemapper";
	ui_tooltip = "Tonemapper Selection, Reinhardt is the truest to original image, but other options are included";
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
			"DO_REFLECT - Enables experimental diffuse reflections, unfinished, quite innacurate, and has a substantial performance impact\n"
			"\n"
			"HIDE INTERMEDIATE/ADVANCED/EXPERIMENTAL - Displays varying levels of advanced settings, experimental settings are unfinished and untested\n"
			"\n"
			"IMPORT_SAM - Toggles experimental importance sampling to cherry pick results, has a moderate performance impact, and generally provides worse results\n"
			"\n"
			"ZNRY_MAX_LODS - The maximum LOD sampled, has a direct performance impact, and an exponential impact on ray range. Max is 9\n"
			"7 is usually enough for near fullscreen coverage, higher values will make color bleed less dramatic\n"
			"\n"
			"ZNRY_RENDER_SCL - The resolution scale for GI, default is automatically selected based on resolution, changes may require reloading ReShade.\n"
			"\n"
			"ZNRY_SAMPLE_DIV - The miplevel of sampled textures (ex, 4 is 1/4 resolution, 2 is half resolution, 1 is full resolution)\n"
			"This has a moderate performance impact, with minimal quality improvements and negative effects on range, not recommended to set below 2";
> = 1;

uniform int CREDITS <
	ui_type = "radio";
	ui_category = "Credits";
	ui_text = "\nCredits and thanks:\n"
			"A big thanks to, Soop, Beta|Alea, Can, AlucardDH, BlueSkyDefender, Ceejay.dk and Dreamt for shader testing and feedback on the UI\n"
			"And a thank you to Vortigern, and LordofLunacy\n"
			"for being crazy enough to try and understand bits of the spaghetti code that is this shader\n"
			"And a big thank you to Crushius for providing me with a copy of 'Shadow Man Remastered' so I could test in something other than Skyrim\n"
			"If you did help with development and I forgot to mention you here, please reach out so I can amend the credits";
	ui_label = " ";
> = 0;

uniform int SHADER_VERSION <
	ui_type = "radio";
	ui_text = "\n" "Shader Version - A25 (v0.2.5)";
	ui_label = " ";
> = 0;



//============================================================================================
//Textures/Samplers
//=================================================================================

texture RYBlueNoiseTex < source = "ZNbluenoise512.png"; >
{
	Width  = 512.0;
	Height = 512.0;
	Format = RGBA8;
};
sampler NoiseSam{Texture = RYBlueNoiseTex; MipFilter = Point;};

texture A246RYNorTex{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 3;};
sampler NorSam{Texture = A246RYNorTex;};

texture A25RYNorDivTex{
	Width = BUFFER_WIDTH / ZNRY_SAMPLE_DIV;
	Height = BUFFER_HEIGHT / ZNRY_SAMPLE_DIV;
	Format = RGBA8;
	MipLevels = ZNRY_MAX_LODS;
};
sampler NorDivSam{Texture = A25RYNorDivTex;};

texture A25RYBufTex{
	Width = BUFFER_WIDTH * (ZNRY_RENDER_SCL / 100.0) / ZNRY_SAMPLE_DIV;
	Height = BUFFER_HEIGHT * (ZNRY_RENDER_SCL / 100.0) / ZNRY_SAMPLE_DIV;
	Format = R32F;
	MipLevels = ZNRY_MAX_LODS;
};
sampler DepSam{Texture = A25RYBufTex;};

texture A25RYLumDownTex{
	Width = BUFFER_WIDTH * (ZNRY_RENDER_SCL / 100.0) / (0.5 * ZNRY_SAMPLE_DIV);
	Height = BUFFER_HEIGHT * (ZNRY_RENDER_SCL / 100.0) / (0.5 * ZNRY_SAMPLE_DIV);
	Format = RGBA16;
};
sampler LumDown{Texture = A25RYLumDownTex;};

texture A25RYLumTex{
	Width = BUFFER_WIDTH * (ZNRY_RENDER_SCL / 100.0) / ZNRY_SAMPLE_DIV;
	Height = BUFFER_HEIGHT * (ZNRY_RENDER_SCL / 100.0) / ZNRY_SAMPLE_DIV;
	Format = RGBA16F;
	MipLevels = ZNRY_MAX_LODS + 1;
};
sampler LumSam{Texture = A25RYLumTex;};

texture A25RYGITex{
	Width = BUFFER_WIDTH * (ZNRY_RENDER_SCL / 100.0);
	Height = BUFFER_HEIGHT * (ZNRY_RENDER_SCL / 100.0);
	Format = RGBA16F;MipLevels = 3;
};
sampler GISam{
	Texture = A25RYGITex;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	MipFilter = LINEAR;
};

texture A25RY_PreFrm {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};
sampler PreFrm {Texture = A25RY_PreFrm;};

texture A25RY_PreDep {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = R32F;
	MipLevels = 3;
};
sampler PreDep {Texture = A25RY_PreDep;};

texture A25RY_CurFrm {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
	MipLevels = 3;
};
sampler CurFrm {Texture = A25RY_CurFrm;};

texture A25RY_DualFrm {
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT; 
	Format = RGBA8; MipLevels = 3;
};
sampler DualFrm {Texture = A25RY_DualFrm;};

texture texMotionVectors;	
sampler motionSam {Texture = texMotionVectors;};

texture MotVectTexVort;	
sampler motionSam1 {Texture = MotVectTexVort;};


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


float3 ZNFilmic(float3 x)
{
	float a = 17.36;
	float b = 16.667;
	float c = 6.0;
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
	float  fn	 = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - 1.0;
	float2 nxy	= 2.0 * xy - 1.0;
	float3 vv	 = normalize(float3(nxy, 1.0));
	float3 eyp	= float3(vv * (fn * z));
	return eyp;
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
    float3 surfN = normalize(2.0 * tex2D(NorSam, xy).rgb - 1.0);
    
    float  d	 = trueD;
    float3 rp	= float3(xy, d);
    float3 l;	//Light accumulation value
   
    float  occ;
    float3 trueC = pow(tex2D(LumSam, xy).rgb, 1.0 / 2.2);

	int sampl = SAMPLE_COUNT;   
	if(DYNA_SAMPL) sampl = 1 + ceil((1.0 - 0.33 * (trueC.r + trueC.g + trueC.b)) * max(SAMPLE_COUNT - 1, 0));
	float3 actSam; //Active reseviour sample
	float  resW; //Reseviour weight
	float  iW;	//Sample weights
    for(int i = 0; i < sampl; i++){
    	
    	d =  trueD;
    	int iLOD = 0;
    		   rp	  = float3(xy, d);
    	float3 minD	= float3(rp.xy, 1.0);
    	float3 maxD	= minD;
    	float2 vec	 = float2(sin((i+1) * 6.28 / sampl), cos((i+1) * 6.28 / sampl));
    	float3 pixP	= float3(xy, trueD);
    	
 	   for(int ii = 2; ii <= ZNRY_MAX_LODS; ii++)
    	{
    		//Max shadow vector calculation
    		float3 compVec0	= normalize(rp - pixP + 0.000001);
    		float3 compVec1	= normalize(minD - pixP + 0.000001);		
			if(compVec0.z <= compVec1.z) {minD = rp;} 
			if(compVec0.z >= compVec1.z) {maxD = float3(rp.xy, rp.z + SHADOW_Z_THK);} 
    		
			//Ray vector and depth calculations
			float2 rd = offset.xy * abs(SHOW_MIPS - 1.0);
				   rd += (0.5 * surfN.xy);//Biases sampling group
   
    		rp.xy += (RAY_LENGTH * (vec + rd) * pow(2, ii)) / res;
    		if(rp.x > 1.0 || rp.y > 1.0) {break;}
    		if(rp.x < 0 || rp.y < 0) {break;}
    		
			d = pow(tex2Dlod(DepSam, float4(rp.xy, 0, iLOD)).r, BUFFER_SCALE);
    		rp.z = d;
    		
    		
    		//Occlusion calculations
   		 bool sh;
   		 if(SHADOW == 0) {sh = 1;}
   		 float3 eyeXY	 = eyePos(rp.xy, rp.z);
			float3 texXY	 = eyePos(xy, trueD);
   		 float3 shvMin	= normalize(minD - pixP);
   		 float3 shvMax	= normalize(maxD - pixP);
   		 float  shd	   = distance(rp, float3(xy, trueD));
   		 float  sb		= SHADOW_BIAS;
   		 bool   zd		= 0;
   		 
			if(ENABLE_Z_THK) zd = d > (trueD + shd * shvMax.z) + sb;		 
   		 if(d <= (trueD + shd * shvMin.z) + sb || zd) {sh = 1;}
			
			//Diffuse Lighting calculations
			float3 col = tex2Dlod(LumSam, float4(rp.xy, 0, iLOD)).rgb;
			float  smb = 1.0;
			
			if(BLOCK_SCATTER)
			{
				float3 nor = 2.0 * tex2Dlod(NorDivSam, float4(rp.xy, 0, iLOD)).rgb - 1.0;
				smb = 2.01 + 1.99 * dot(-surfN, nor);
			}
				
			float  ed	 = 1.0 + pow(abs(DISTANCE_SCALE * distance(texXY, 0.0)), 2.0) / f;
			float  cd	 = 1.0 + (pow(abs(DISTANCE_SCALE * distance(eyeXY, texXY)), 2.0)) / f;
			float3 lv	 = normalize(rp - pixP);
			float  amb	= 0.5 + 0.5 * dot(surfN, lv);
			float  rfs	= 1.0;
			if(DO_REFLECT == 1)
			{
				rfs = 0.5 + 0.5 * dot(reflect(normalize(float3(0.0, 0.0, 1.0)),
					float3(surfN.x, -surfN.y, surfN.z)), normalize(pixP - rp));
				rfs = pow(rfs, SPECULAR_POW);
			}
			
			col *= ed;
			float3 lAcc = (pow(4.0, iLOD) / (4.0 * cd)) * smb * amb * (col / ed);
			l += rfs * sh * lAcc;
			if(d == 1.0) {l += col * SKY_BRIGHT;}
			occ += 2.0 * sh * (col.r + col.g + col.b) / ed;
			
			iW += (lAcc.r + lAcc.g + lAcc.b); //Accumulation for weighted sampling
			iLOD++;	
    	}
    	if(IMPORT_SAM){
    		if(weighthash(abs(vec), resW, iW) == 1) {actSam = l; resW += iW;}
    		l = 0.0; actSam *= 1.0; iW = 0.0;
    	}
    }
    if(IMPORT_SAM){l = actSam;}    
    l *= (1.0 + pow(RAY_LENGTH, 2.0)) * (6.0 / sampl);
	l = pow(l / (2.0 * pow(2.0, LODS)), 1.0 / 2.2);
	occ = saturate(8.0 * occ / (sampl * LODS));
	return float4(0.5 * max(0.001, l), pow(occ, 1.0 / 2.2));
}

float3 tonemap(float3 input)
{
	input = max(0.0, input);
	if(TONEMAPPER == 0) input = ZNFilmic(input);
	if(TONEMAPPER == 1) input = SONYA7RIII(input);
	if(TONEMAPPER == 2) input = ACESFilm(input);
	if(TONEMAPPER == 3) input = input / (input + 1.0);
	if(TONEMAPPER == 4) {return pow(input, 1.0 / 2.2);}
	if(TONEMAPPER == 5) input = pow(input, 0.5 * input + 1.0);
	input = pow(input, 1.0 / 2.2);
	return saturate(input);
}

float3 BlendGI(float3 input, float4 GI, float depth, float2 xy)
{
	float dAccp = 1.0 - DEPTH_MASK;
	input	   = pow(input, 2.2);
	float3 ICol = saturate(COLORMAP_OFFSET + input);
		   ICol = lerp(normalize(ICol) / 0.577, input, 0.5 + 0.5 * COLORMAP_BIAS);
		   
	float  ILum = (input.r + input.g + input.b) / 3.0;
	float3 iGI;
	GI.rgb	  = pow(GI.rgb, 2.2);
	GI.rgb	  *= 1.0 + (1.0 - DETINT_COLOR) * pow(DETINT_LEVEL, 7.0);
	GI.rgb	  *= 1.0 - pow(depth, 1.0 - DEPTH_MASK);
	GI.a		= lerp(GI.a, 1.0, pow(depth, 1.0 - DEPTH_MASK));
	float GILum = (GI.r + GI.g + GI.b) / 3.0;
	
	
	if(REMOVE_DIRECTL == 0) {ILum = 0.0;}
	
		 if(DEBUG == 1) {input = (GI.rgb) * ICol;}
	else if(DEBUG == 2) {input = GI.rgb;}
	else if(DEBUG == 3) {input = GI.a;}
	else if(DEBUG == 4) {input = GI.a * pow(lerp(1.0, GI.rgb, GILum), 3.0);}
	else if(DEBUG == 5) {input = ICol;}
	else
	{
		if(depth == 1.0) return - input / (input - 1.1);
		input	= normalize(input) / 0.577 * pow((input.r + input.g + input.b) / 3.0, 1.0 + AMBIENT_NEG);//Exposure
		input	= lerp(input, GI.a * input, SHADOW_INT);
		iGI	  = (INTENSITY * (GI.rgb - (ILum)) * ICol);
	}
	
	return 2.0 * iGI - input / (input - 1.1);
}


//Modified variance clamping for TAA denoising
float4 NbrClamp(sampler frame, float2 xy, float4 col, float deG)
{
	float2 res	 = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float2 mVec	= tex2D(motionSam, xy).xy;
		   mVec	+= tex2D(motionSam1, xy).xy;
	/*
	//Can't calculate dissoclusion with this method due to generated motion vector limitations
	float dep1 = ReShade::GetLinearizedDepth(xy);	
	float dep2 = tex2D(PreDep, mVec + xy).r; 
	float dcomp = normalize(float2(distance(dep1, dep2), dep1)).x;
	if(dcomp > 0.05) return tex2Dlod(frame, float4(xy, 0, 0));
	*/
	
	float4 m;
	float4 m1;
	float gam = 1.0;
	for(int i = 0; i <= 1; i++) for(int ii = 0; ii <= 1; ii++)
	{
		float2 coord = xy + TAA_SKIP * float2(i - 0.5, ii - 0.5) / res;
		float4 c 	= tex2Dlod(frame, float4(coord, 0, 0));
		float4 cb	= tex2Dlod(PreFrm, float4(coord + mVec, 0, 0));
		
		c  = lerp(c, cb, TAA_ERROR * (0.95 - deG));
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

float4 LightDown(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = 2.0;

    float3 acc = tex2D(ReShade::BackBuffer, xy).rgb * 4.0;
    acc += tex2D(ReShade::BackBuffer, xy - hp * offset).rgb;
    acc += tex2D(ReShade::BackBuffer, xy + hp * offset).rgb;
    acc += tex2D(ReShade::BackBuffer, xy + float2(hp.x, -hp.y) * offset).rgb;
    acc += tex2D(ReShade::BackBuffer, xy - float2(hp.x, -hp.y) * offset).rgb;

    return float4(acc / 8.0, 1.0);
}


//Saves LightMap and LODS
float4 LightMap(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	float2 res	   = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp		= 0.5 / res;
    float  offset	= 2.0;
	
    float3 acc = tex2D(LumDown, xy).rgb * 4.0;
		acc += tex2D(LumDown, xy - hp * offset).rgb;
	    acc += tex2D(LumDown, xy + hp * offset).rgb;
	    acc += tex2D(LumDown, xy + float2(hp.x, -hp.y) * offset).rgb;
	    acc += tex2D(LumDown, xy - float2(hp.x, -hp.y) * offset).rgb;
		acc /= 8.0;
	
	float  p 	= 2.2;
	float3 te	= acc;
		   te	= pow(te, p);	   
	
	if(DO_BOUNCE)
	{
		float2 mVec	 =  tex2D(motionSam, xy).xy;
			   mVec	 += tex2D(motionSam1, xy).xy;
		float3 GISec	=  tex2Dlod(DualFrm, float4(mVec + xy, 0, 2)).rgb;
		te += lerp(normalize(te), te, 0.9 * COLORMAP_BIAS) * GISec * TERT_INTENSITY;
	}
	te = saturate(saturation(te, LIGHTMAP_SAT));
	te = -te / (te - 1.1);
	return float4(max(0, te), 1.0);
}

//Saves DepthBuffer and LODS
float LinearBuffer(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float f	= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	float n	= NEAR_PLANE;
	float d	= ReShade::GetLinearizedDepth(texcoord);
		  d	= lerp(n, f, d);
		  
	return pow(d / (f - n), 1.0 / BUFFER_SCALE);
}


//Generates Normal Buffer from depth, as described here: https://atyuwen.github.io/posts/normal-reconstruction/
float4 NormalBuffer(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 output;
	
	float FarPlane	= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	float2 uvd		= float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float vc 		 = ReShade::GetLinearizedDepth(texcoord);
	
	if(APPROX_NORMALS)
	{
		float vx	= vc - ReShade::GetLinearizedDepth(texcoord + float2(1, 0) / uvd);
		float vy	= vc - ReShade::GetLinearizedDepth(texcoord + float2(0, 1) / uvd);
		output	  = 0.5 + 0.5 * normalize(float3(-vx, -vy, -vc / FarPlane));
	}
	else
	{
		 
		float vx;
		float vxl	 = vc - ReShade::GetLinearizedDepth(texcoord + float2(-1, 0) / uvd);	
		float vxl2	= vc - ReShade::GetLinearizedDepth(texcoord + float2(-2, 0) / uvd);
		float exlC	= lerp(vxl2, vxl, 2.0);
		
		float vxr 	= vc - ReShade::GetLinearizedDepth(texcoord + float2(1, 0) / uvd);
		float vxr2	= vc - ReShade::GetLinearizedDepth(texcoord + float2(2, 0) / uvd);
		float exrC	= lerp(vxr2, vxr, 2.0);
		
		if(distance(exlC, vc) > distance(exrC, vc)) vx = -vxl;
		else vx = vxr;
		
		float vy;
		float vyl 	= vc - ReShade::GetLinearizedDepth(texcoord + float2(0, -1) / uvd);
		float vyl2	= vc - ReShade::GetLinearizedDepth(texcoord + float2(0, -2) / uvd);
		float eylC	= lerp(vyl2, vyl, 2.0);
		
		float vyr 	= vc - ReShade::GetLinearizedDepth(texcoord + float2(0, 1) / uvd);
		float vyr2	= vc - ReShade::GetLinearizedDepth(texcoord + float2(0, 2) / uvd);
		float eyrC	= lerp(vyr2, vyr, 2.0);
		
		if(distance(eylC, vc) > distance(eyrC, vc)) vy = -vyl;
		else vy = vyr;
	
		output = float3(0.5 + 0.5 * normalize(float3(-vx, -vy, -vc / FarPlane)));
	}
	return float4(output, 1.0);	
}


//Renders GI to a texture for resolution scaling and blending
float4 RawGI(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	
	float2 bxy		= float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float2 MSOff	  = (100 / ZNRY_RENDER_SCL) * TAA_SAM_DST[FRAME_COUNT % 8] / (16.0 * bxy);
	float2 tempOff	= 1.0 * (1-STATIC_NOISE) * hash((1.0 + FRAME_COUNT % 128) * bxy);
		   tempOff	= floor(tempOff * bxy) / bxy;
		   
	float2 offset	= frac(0.4 + tempOff + texcoord * (bxy / (512 / (ZNRY_RENDER_SCL / 100.0))));
	float3 noise	 = tex2D(NoiseSam, offset).rgb;
	
	float4 GI		= float4(DAMPGI(MSOff + texcoord, 2.0 * (0.5 - noise.xy)));
	
	return GI;
	
}

float4 NormalDiv(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	return tex2Dlod(NorSam, float4(texcoord, 0, 2));	
}

//Temporal Denoisers
float4 DualFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 CF	  = tex2D(CurFrm, texcoord);
	float2 mVec	= tex2D(motionSam, texcoord).xy;
		   mVec	+= tex2D(motionSam1, texcoord).xy;
	float3 nor	 = tex2D(NorSam, texcoord).rgb;
	float  CD	  = ReShade::GetLinearizedDepth(texcoord);
	float4 PF	  = tex2D(PreFrm, texcoord + mVec);
	float  PD	  = tex2D(PreDep, texcoord + mVec).r;
	
	float  DeGhostMask = FRAME_PERSIST * saturate(60.0 * distance(CD, PD));
	if(DEBUG == 6) {return DeGhostMask;}
	CF = lerp(PF.rgba, CF, (1.0 - FRAME_PERSIST) + DeGhostMask);
	CF = NbrClamp(CurFrm, texcoord, CF, DeGhostMask);
	return float4(CF);
}

float4 CurrentFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 CF	  = tex2D(GISam, texcoord);
	float2 mVec	= tex2D(motionSam, texcoord).xy;
		   mVec	+= tex2D(motionSam1, texcoord).xy;
	float3 nor	 = tex2D(NorSam, texcoord).rgb;
	float  CD	  = ReShade::GetLinearizedDepth(texcoord);
	float4 PF	  = tex2D(PreFrm, texcoord + mVec);
	float  PD	  = tex2D(PreDep, texcoord + mVec).r;
	
	float  DeGhostMask = FRAME_PERSIST * saturate(60.0 * distance(CD, PD));
	if(DEBUG == 6) {return DeGhostMask;}
	CF = lerp(PF.rgba, CF, (1.0 - FRAME_PERSIST) + DeGhostMask);
	CF = NbrClamp(GISam, texcoord, CF, DeGhostMask);
	return float4(CF);
}

float PreviousDepth(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	return ReShade::GetLinearizedDepth(texcoord);
}

float4 PreviousFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	return tex2D(CurFrm, texcoord);
}



//============================================================================================
//Main
//============================================================================================



float3 DAMPRT(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;
		   input = saturate(input);
	float4 GI;
	if(DONT_DENOISE) GI	= tex2Dlod(GISam, float4(texcoord, 0, 1));
	else 			GI	= tex2Dlod(DualFrm, float4(texcoord, 0, 1));
	float			depth = ReShade::GetLinearizedDepth(texcoord);
	
	input = BlendGI(input, GI, depth, texcoord);
	input = tonemap(input);
	
	if(DEBUG == 6) {input = GI.rgb;}
	else if(DEBUG == 7) {input = tex2D(NorSam, texcoord).rgb;}
	else if(DEBUG == 8) {input = tex2D(DepSam, texcoord).r;}
	else if(DEBUG == 9) {input = tex2D(LumSam, texcoord).rgb;}
	return input;
}

technique ZN_DAMPRT_A24_6 <
    ui_label = "DAMP RT A25";
    ui_tooltip ="Zentient DAMP RT - by Zenteon\n" 
				"The sucessor to SDIL, a much more efficient and accurate GI approximation";
>
{

	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LightDown;
		RenderTarget = A25RYLumDownTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LightMap;
		RenderTarget = A25RYLumTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LinearBuffer;
		RenderTarget = A25RYBufTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalBuffer;
		RenderTarget = A246RYNorTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalDiv;
		RenderTarget = A25RYNorDivTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = RawGI;
		RenderTarget = A25RYGITex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CurrentFrame;
		RenderTarget = A25RY_CurFrm;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DualFrame;
		RenderTarget = A25RY_DualFrm;
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
		RenderTarget = A25RY_PreFrm;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PreviousDepth;
		RenderTarget = A25RY_PreDep;
	}
}
