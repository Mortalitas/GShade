////////////////////////////////////////////////////////
// Depth-Aware Mipmapped Ray Tracing
// Author: Zenteon
// License: GPLv3
// Repository: https://github.com/Zenteon/ZN_FX
////////////////////////////////////////////////////////

/*
ZN Depth Aware Mipmapped Ray Tracing (DAMP RT), by Zenteon 

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
Lord of Lunacy - https://github.com/LordOfLunacy
BlueSkyDefender - https://blueskydefender.github.io/AstrayFX/
*/
#include "ReShade.fxh"

#ifndef ZNRY_SAMPLE_DIV
//============================================================================================
	#define ZNRY_SAMPLE_DIV 4 //Sample Texture Resolution Divider
//============================================================================================
#endif

#ifndef ZNRY_RENDER_SCL
//============================================================================================
	#if(BUFFER_HEIGHT <= 720)
		#define ZNRY_RENDER_SCL 100 //Render Scale (percent)
	#elif(BUFFER_HEIGHT <= 960)
		#define ZNRY_RENDER_SCL 89
	#elif(BUFFER_HEIGHT <= 1080)
		#define ZNRY_RENDER_SCL 80
	#elif(BUFFER_HEIGHT <= 1440)
		#define ZNRY_RENDER_SCL 67
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

uniform int ZN_DAMPRT <
	ui_label = " ";
	ui_text = "Zentient DAMP RT (Depth Aware Mipmapped Ray Tracing) is a shader built around\n"
			"sampling miplevels in order to approximate cone tracing in 2D space before\n"
			"extrapolating the data into 3D based on depth information. \n"
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
	ui_tooltip = "Adjust the accuracy of the depth buffer for closer objects";
	ui_category = "Depth Buffer Settings";
	ui_category_closed = true;
> = 2.0;

uniform float NEAR_PLANE <
	ui_type = "slider";
	ui_min = -1.0;
	ui_max = 2.0;
	ui_label = "Near Plane";
	ui_tooltip = "Adjust min depth for depth buffer, increase slightly if dark lines or occlusion artifacts are visible";
	ui_category = "Depth Buffer Settings";
> = 0.0;

uniform float FOV <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 110.0;
	ui_label = "FOV";
	ui_tooltip = "Adjust to match ingame FOV";
	ui_category = "Depth Buffer Settings";
	ui_step = 1;
> = 70;

uniform bool APPROX_NORMALS <
	ui_label = "Approximate Normals";
	ui_tooltip = "Uses less accurate normal approximations to speed up performance slightly";
	ui_category = "Depth Buffer Settings";
> = 1;

uniform float INTENSITY <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "GI Intensity";
	ui_tooltip = "Intensity of the effect";
	ui_category = "Display";
	ui_category_closed = true;
> = 0.35;


uniform int TONEMAPPER <
	ui_type = "combo";
	ui_items = "ZN Filmic\0Sony A7RIII\0ACES\0Reinhardt\0None\0Contrast\0";
	ui_label = "Tonemapper";
	ui_tooltip = "Tonemapper Selection, Select 'None' if image becomes too dark or saturated";
	ui_category = "Display";
> = 4;

uniform float AMBIENT_NEG <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Ambient Reduction";
	ui_tooltip = "Removes ambient light before adding GI to the image";
	ui_category = "Display";
> = 0.4;

uniform float DEPTH_MASK <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Depth Mask";
	ui_tooltip = "Depth dropoff to allow compatibility with in game fog";
	ui_category = "Display";
> = 0.0;	

uniform float COLORMAP_BIAS <
	ui_type = "slider";
	ui_label = "Colormap Bias";
	ui_tooltip = "Attempts to reduce artifacts in dark colors at the cost of lighting quality";
	ui_category = "Colors";
	ui_category_closed = true;
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.5;

uniform float COLORMAP_OFFSET <
	ui_type = "slider";
	ui_label = "Colormap Offset";
	ui_tooltip = "Attempts to reduce artifacts in dark colors, but can wash them out in certain scenes";
	ui_category = "Colors";
	ui_min = 0.0;
	ui_max = 0.01;
> = 0.001;

uniform float3 DETINT_COLOR <
	ui_type = "color";
	ui_label = "Detint Color";
	ui_tooltip = "Can help remove certain boosted colors from the Colormap";
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

uniform int SAMPLE_COUNT <
	ui_type = "combo";
	ui_items = "High - 8 samples per mip\0Medium - 6 samples per mip\0Low - 4 samples per mip\0Ultra - 16 samples per mip\0";
	ui_label = "Sample Quality";
	ui_tooltip = "Higher settings reduce noise but are slower to run. Note that increasing the render scale is often more effective.";
	ui_category = "Sampling";
	ui_category_closed = true;
> = 1;

uniform bool SHADOW <
	ui_label = "Shadows";
	ui_tooltip = "Rejects some samples to cast soft shadows || No Performance Impact";
	ui_category = "Sampling";
> = 1;

uniform float SHADOW_BIAS <
	ui_type = "slider";
	ui_label = "Shadow Bias";
	ui_tooltip = "Reduces artifacts and intensity of shadows";
	ui_category = "Sampling";
	ui_min = -0.01;
	ui_max = 0.01;
> = 0.001;

uniform float TAA_ERROR <
	ui_type = "slider";
	ui_label = "TAA Error";
	ui_tooltip = "Reduces noise almost completely, introduces ghosting, good for screenshots";
	ui_category = "Sampling";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.0;


uniform bool REMOVE_DIRECTL <
	ui_label = "Brightness Mask";
	ui_tooltip = "Prevents excessive illumination in already lit areas || No Performance Impact";
	ui_category = "Sampling";
> = 0;

uniform bool BLOCK_SCATTER <
	ui_label = "Block Scattering";
	//hidden = true;
	ui_tooltip = "Prevents surface scattering and brightening of already bright areas || Medium Performance Impact";
	ui_category = "Sampling";
> = 1;

uniform float RAY_LENGTH <
ui_type = "slider";
	ui_min = 0.5;
	ui_max = 5.0;
	ui_label = "Ray Step Length";
	ui_tooltip = "Changes the length of ray steps per Mip, reduces overall sample quality but increases ray range || Low Performance Impact"; 
	ui_category = "Sampling";
> = 2.5;

uniform float DISTANCE_SCALE <
ui_type = "slider";
	ui_min = 0.01;
	ui_max = 20.0;
	ui_label = "Distance Scale";
	ui_tooltip = "The scale at which brightness calculations are made"; 
	ui_category = "Sampling";
> = 5.0;

uniform int FRAME_COUNT <
	source = "framecount";>;

uniform int DEBUG <
	ui_type = "combo";
	ui_category = "Debug Settings";
	ui_items = "None\0GI * Color Map\0GI\0Shadows\0Lighting\0Color Map\0DeGhosting mask\0Normals\0Depth\0LightMap\0";
> = 0;

uniform bool SHOW_MIPS <
	ui_label = "Display Mipmaps";
	ui_category = "Debug Settings";
	ui_tooltip = "Just for fun, for anyone wanting to visualize how it works\n"
		"recommended to use either the lighting or GI debug view";
> = 0;

uniform bool STATIC_NOISE <
	ui_label = "Static Noise";
	ui_category = "Debug Settings";
	ui_tooltip = "Disables sample jittering";
> = 0;

uniform bool DONT_DENOISE <
	ui_category = "Debug Settings";
	ui_label = "Disable Denoising";
> = 0;

uniform int PREPRO_SETTINGS <
	ui_type = "radio";
	ui_text = "Preprocessor Definition Guide:\n"
			"\n"
			"ZNRY_MAX_LODS - The maximum LOD sampled, has a direct performance impact, and an exponential impact on ray range. Max is 9\n"
			"7 is usually enough for near fullscreen coverage\n"
			"\n"
			"ZNRY_RENDER_SCL - The resolution scale for GI, default is automatically selected based on resolution, changes may require reloading ReShade.\n"
			"\n"
			"ZNRY_SAMPLE_DIV - The resolution divider for sampled textures. (ex, 4 is 1/4 resolution, 2 is half resolution, 1 is full resolution\n"
			"This has a massive performance impact, with minimal quality drops, not recommended to increase past half resolution";
> = 1;

uniform int SHADER_VERSION <
	ui_type = "radio";
	ui_text = "\n" "Shader Version - A22 (v0.2.2)";
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

texture RYNorTex{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 3;};
texture RYNorDivTex{Width = BUFFER_WIDTH / ZNRY_SAMPLE_DIV; Height = BUFFER_HEIGHT / ZNRY_SAMPLE_DIV; Format = RGBA8; MipLevels = ZNRY_MAX_LODS;};
texture RYBufTex{Width = BUFFER_WIDTH / ZNRY_SAMPLE_DIV; Height = BUFFER_HEIGHT / ZNRY_SAMPLE_DIV; Format = R16; MipLevels = ZNRY_MAX_LODS;};
texture RYLumDownTex{Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = RGBA8;};
texture RYLumTex{Width = BUFFER_WIDTH / ZNRY_SAMPLE_DIV; Height = BUFFER_HEIGHT / ZNRY_SAMPLE_DIV; Format = RGBA8; MipLevels = ZNRY_MAX_LODS;};
texture RYGITex{Width = BUFFER_WIDTH * (ZNRY_RENDER_SCL / 100.0); Height = BUFFER_HEIGHT * (ZNRY_RENDER_SCL / 100.0); Format = RGBA8;MipLevels = 3;};
texture RY_PreFrm {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};
texture RY_PreDep {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16; MipLevels = 5;};
texture RY_CurFrm {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 5;};
texture RY_DualFrm {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 5;};

sampler NoiseSam{Texture = RYBlueNoiseTex; MipFilter = Point;};
sampler NorSam{Texture = RYNorTex;};
sampler NorDivSam{Texture = RYNorDivTex;};
sampler DepSam{Texture = RYBufTex;};
sampler LumDown{Texture = RYLumDownTex;};
sampler LumSam{Texture = RYLumTex;};
sampler GISam{
	Texture = RYGITex;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
};
sampler PreFrm {Texture = RY_PreFrm;};
sampler PreDep {Texture = RY_PreDep;};
sampler CurFrm {Texture = RY_CurFrm;};
sampler DualFrm {Texture = RY_DualFrm;};

//============================================================================================
//Tonemappers
//============================================================================================


float3 SONYA7RIII(float3 z) //This is a custom tonemapper, it doesn't look great, which is funny
{
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

float3 eyePos(float2 xy, float z, float2 pw)//takes screen coords (0-1) and depth (0-1) and converts to eyespace position
{
	float fn = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE - 1.0;
	float2 nxy = 2.0 * xy - 1.0;
	float3 vv = normalize(float3(nxy, 1.0));
	float3 eyp = float3(vv * (fn * z));
	return eyp;
}


float4 DAMPGI(float2 xy, float2 offset)//offset is noise value, output RGB is GI, A is shadows;
{
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float f = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	float n = NEAR_PLANE;
	float2 PW = 2.0 * tan(FOV * 0.00875) * (f - n); //Dimensions of FarPlane
	PW.y *= res.x / res.y;
	
	
	int LODS = ZNRY_MAX_LODS;
	
	//Different sample densities for adaptive sampling
	float2 dir0[8] = {
		float2(0.0, 1.0), float2(0.7071, 0.7071),
		float2(1.0, 0.0), float2(0.7071, -0.7071),
		float2(0.0, -1.0), float2(-0.7071, -0.7071),
		float2(-1.0, 0.0), float2(-0.7071, 0.7071)};
    
    float2 dir1[6] = {
	    float2(0.866, 0.5), float2(0.866, -0.5),
	    float2(0.0, -1.0), float2(-0.86, -0.5),
		float2(-0.85, 0.5), float2(0.0, 1.0)};
	
	float2 dir2[4] = {
		float2(0.0, 1.0), float2(1.0, 0.0),
		float2(0.0, -1.0), float2(-1.0, 0.0)};
	
	float2 dir3[16] = {
		float2(0.382, 0.92), float2(0.7071, 0.7071),
		float2(0.92, 0.382), float2(1.0, 0.0),
		float2(0.92, -0.382), float2(0.7071, -0.7071),
		float2(0.382, -0.92), float2(0.0, -1.0),
		float2(-0.382, -0.92), float2(-0.7071, -0.7071),
		float2(-0.92, -0.382), float2(-1.0, 0.0),
		float2(-0.92, 0.382), float2(-0.7071, 0.7071),
		float2(-0.382, 0.92), float2(0.0, 1.0)};
			
	
	int sampCt = SAMPLE_COUNT;
	int RAD;
	int DIRL;
	
	if(sampCt == 1) {RAD = 6; DIRL = 1;}
	else if(sampCt == 2) {RAD = 4; DIRL = 2;}
	else if(sampCt == 3) {RAD = 16; DIRL = 3;}
	else {RAD = 8; DIRL = 0;}
    
    float trueD = ReShade::GetLinearizedDepth(xy);
    float3 surfN = normalize(2.0 * tex2D(NorSam, xy).rgb - 1.0);
    
    float d = trueD;
    float3 rp = float3(xy, d);
    float3 l;
    float occ;
    
    for(int i = 0; i < RAD; i++){
    	
    	d =  trueD;
    	int iLOD = 0;
    	rp = float3(xy, d);
    	float3 minD  = float3(rp.xy, 1.0);
    	
    	//Array selection for adaptive sampling
    	float2 vec;
    	if(DIRL == 0) {vec = dir0[i];}//High
    	if(DIRL == 1) {vec = dir1[i];}//Medium
    	if(DIRL == 2) {vec = dir2[i];}//Low
    	if(DIRL == 3) {vec = dir3[i];}//Ultra
    	
 	   for(int ii = 2; ii <= LODS; ii++)
    	{
    		//Max shadow vector calculation
    		float3 compVec0 = normalize(0.000000001 + rp - float3(xy, trueD));
    		float3 compVec1 = normalize(0.000000001 + minD - float3(xy, trueD));		
			if(compVec0.z <= compVec1.z) {minD = rp;}//d <= trueD && 
    		
			//Ray vector and depth calculations
			float2 rd = offset.xy * abs(SHOW_MIPS - 1.0);
			rd += (0.5 * surfN.xy);//Biases sampling group
   
    		rp.xy += (RAY_LENGTH * (vec + rd) * pow(2, ii)) / res;
    		if(rp.x > 1.0 || rp.y > 1.0) {break;}
    		if(rp.x < 0 || rp.y < 0) {break;}
    		
			d = pow(tex2Dlod(DepSam, float4(rp.xy, 0, iLOD)).r, BUFFER_SCALE);
    		rp.z = d;
    		
    		
    		//Occlusion calculations
   		 int sh;
   		 if(SHADOW == 0) {sh = 1;}
   		 float3 eyeXY = eyePos(rp.xy, rp.z, PW);
			float3 texXY = eyePos(xy, trueD, PW);
   		 float3 shvMin = normalize(minD - float3(xy, trueD));
   		 float shd = distance(rp, float3(xy, trueD));
   		 if(d <= (trueD + shd * shvMin.z) + SHADOW_BIAS) {sh = 1;}
			
			//Diffuse Lighting calculations
			float3 col = tex2Dlod(LumSam, float4(rp.xy, 0, iLOD)).rgb;
			float smb = 1.0;
			if(BLOCK_SCATTER == 1)
			{
				float3 nor = 2.0 * tex2Dlod(NorDivSam, float4(rp.xy, 0, iLOD)).rgb - 1.0;
				smb = 2.01 + 1.99 * dot(-surfN, nor);
			}
				
			float ed = 1.0 + pow(DISTANCE_SCALE * distance(texXY, 0.0), 2.0) / f;
			float cd = 1.0 + (pow(DISTANCE_SCALE * distance(eyeXY, texXY), 2.0)) / f;
			float amb = 0.5 + 0.5 * dot(surfN, normalize(rp - float3(xy, trueD)));
			
			col *= ed;
			l += sh * (pow(4.0, iLOD) / (4.0 * cd)) * smb * amb * (col / ed);
			occ += sh * (col.r + col.g + col.b) / ed;
			
			iLOD++;	
    	}}
    
    l *= (1.0 + pow(RAY_LENGTH, 2.0)) * (6.0 / RAD);
	l = pow(l / (2.0 * pow(2.0, LODS)), 1.0 / 2.2);
	occ = saturate(8.0 * occ / (RAD * LODS));
	return float4(l, pow(occ, 1.0 / 2.2));
}

float3 tonemap(float3 input)
{
	if(TONEMAPPER == 4) {return input;}
	input = pow(saturate(input), 2.2);
	input = clamp(-input / (input - 1.1), 0.0, 1.0);
	if(TONEMAPPER == 0) {input = ZNFilmic(input);}
	if(TONEMAPPER == 1){input = SONYA7RIII(input);}
	if(TONEMAPPER == 2){input = ACESFilm(input);}
	if(TONEMAPPER == 3){input = input / (input + 0.5);}
	if(TONEMAPPER == 5){input = pow(input, 0.5 * input + 1.0);}
	input = saturate(input * 1.1);
	return pow(input, 1.0 / 2.2);
}

float3 BlendGI(float3 input, float4 GI, float depth, float2 xy)
{
	GI *= 1.0 - pow(depth, 1.0 - DEPTH_MASK * 0.5) * DEPTH_MASK;
	float3 ICol = COLORMAP_OFFSET + pow(input, 2.2);
	ICol += (1.0 - DETINT_COLOR) * pow(DETINT_LEVEL, 7.0);
	ICol = lerp(normalize(ICol), input, 0.5 + 0.5 * COLORMAP_BIAS) / 0.577;
	float ILum = (input.r + input.g + input.b) / 3.0;
	float GILum = (GI.r + GI.g + GI.b) / 3.0;
	
	if(REMOVE_DIRECTL == 0) {ILum = 0.0;}
	if(DEBUG == 1) {input = (GI.rgb) * ICol;}
	else if(DEBUG == 2) {input = GI.rgb;}
	else if(DEBUG == 3) {input = GI.a;}
	else if(DEBUG == 4) {input = GI.a * pow(lerp(1.0, GI.rgb, GILum), 3.0);}
	else if(DEBUG == 5) {input = ICol;}
	else if(DEBUG == 6) {input = GI.rgb;}
	else if(DEBUG == 7) {input = tex2D(NorSam, xy).rgb;}
	else if(DEBUG == 8) {input = tex2D(DepSam, xy).r;}
	else if(DEBUG == 9) {input = tex2D(LumSam, xy).rgb;}
	else{input = lerp(input, GI.a * input, AMBIENT_NEG) + (INTENSITY * (GI.rgb - ILum) * ICol);}
	
	return input;
}


float eyeDis(float2 xy, float2 pw)
{
	return eyePos(xy, ReShade::GetLinearizedDepth(xy), pw).z;
}

//Modified variance clamping for TAA denoising
float4 NbrClamp(float2 xy, float4 col, float deG)
{
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float4 m;
	float4 m1;
	float gam = 1.0;
	for(int i = 0; i <= 1; i++) for(int ii = 0; ii <= 1; ii++)
	{
		float2 coord = xy + 2.0 * float2(i - 0.5, ii - 0.5) / res;
		float4 c = tex2Dlod(GISam, float4(coord, 0, 0));
		float4 cb = tex2Dlod(PreFrm, float4(coord, 0, 0));
		c = lerp(c, cb, TAA_ERROR * (0.95 - deG));
		m += c;
		m1 += c*c;
		
		
	}
	float4 mu = m / 4.0;
	float4 sig = sqrt(m1 / 4.0 - mu * mu);
	float4 minC = mu - sig * gam;
	float4 maxC = mu + sig * gam;
	return clamp(col, minC, maxC);
}

float4 DualNbrClamp(float2 xy, float4 col, float deG)
{
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float4 m;
	float4 m1;
	float gam = 1.0;
	for(int i = 0; i <= 1; i++) for(int ii = 0; ii <= 1; ii++)
	{
		float2 coord = xy + 2.0 * float2(i - 0.5, ii - 0.5) / res;
		float4 c = tex2Dlod(CurFrm, float4(coord, 0, 0));
		float4 cb = tex2Dlod(PreFrm, float4(coord, 0, 0));
		c = lerp(c, cb, TAA_ERROR * (0.95 - deG));
		m += c;
		m1 += c*c;
		
		
	}
	float4 mu = m / 4.0;
	float4 sig = sqrt(m1 / 4.0 - mu * mu);
	float4 minC = mu - sig * gam;
	float4 maxC = mu + sig * gam;
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
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = 2.0;

    float3 acc = tex2D(LumDown, xy).rgb * 4.0;
    
	acc += tex2D(LumDown, xy - hp * offset).rgb;
    acc += tex2D(LumDown, xy + hp * offset).rgb;
    acc += tex2D(LumDown, xy + float2(hp.x, -hp.y) * offset).rgb;
    acc += tex2D(LumDown, xy - float2(hp.x, -hp.y) * offset).rgb;
	acc /= 8.0;
	
	float p = 2.2;
	float3 te = acc;
	te = pow(te, p);
	
	float3 ten = normalize(te);
	te = -te / (te - 1.4);
	float teb = (te.r + te.g + te.b) / 3.0;
	//te = lerp(te, ten / 0.577, 0.0);
	return saturate(float4(te, 1.0));
}

//Saves DepthBuffer and LODS
float LinearBuffer(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float f = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	float n = NEAR_PLANE;
	float depth = ReShade::GetLinearizedDepth(texcoord);
	depth = lerp(n, f, depth);
	return pow(depth / (f - n), 1.0 / BUFFER_SCALE);
}


//Generates Normal Buffer from depth, as described here: https://atyuwen.github.io/posts/normal-reconstruction/
float4 NormalBuffer(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 output;
	
	float FarPlane = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	float2 aspectPos= float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float2 PW = 0;//2.0 * tan(70.0 * 0.00875) * (FarPlane - 1); //Dimensions of FarPlane
	PW.y *= aspectPos.x / aspectPos.y;
	float2 uvd = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float vc = eyeDis(texcoord, PW);
	
	if(APPROX_NORMALS)
	{
		float vx = vc - eyeDis(texcoord + float2(1, 0) / uvd, PW);
		float vy = vc - eyeDis(texcoord + float2(0, 1) / uvd, PW);
		output = 0.5 + 0.5 * normalize(float3(-vx, -vy, vc / FarPlane));
	}
	else
	{		 
		float vx;
		float vxl = vc - eyeDis(texcoord + float2(-1, 0) / uvd, PW);	
		float vxl2 = vc - eyeDis(texcoord + float2(-2, 0) / uvd, PW);
		float exlC = lerp(vxl2, vxl, 2.0);
		
		float vxr = vc - eyeDis(texcoord + float2(1, 0) / uvd, PW);
		float vxr2 = vc - eyeDis(texcoord + float2(2, 0) / uvd, PW);
		float exrC = lerp(vxr2, vxr, 2.0);
		
		if(abs(exlC - vc) > abs(exrC - vc)) {vx = -vxl;}
		else {vx = vxr;}
		
		float vy;
		float vyl = vc - eyeDis(texcoord + float2(0, -1) / uvd, PW);
		float vyl2 = vc - eyeDis(texcoord + float2(0, -2) / uvd, PW);
		float eylC = lerp(vyl2, vyl, 2.0);
		
		float vyr = vc - eyeDis(texcoord + float2(0, 1) / uvd, PW);
		float vyr2 = vc - eyeDis(texcoord + float2(0, 2) / uvd, PW);
		float eyrC = lerp(vyr2, vyr, 2.0);
		
		if(abs(eylC - vc) > abs(eyrC - vc)) {vy = -vyl;}
		else {vy = vyr;}
		
		output = float3(0.5 + 0.5 * normalize(float3(-vx, -vy, vc / FarPlane)));
	}
	return float4(output, 1.0);
}
//Renders GI to a texture for resolution scaling and blending
float4 RawGI(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 TAA_SAM_DST[8] = {
		float2(1,-3), float2(-1,3), 
		float2(5,1), float2(-3,-5),
		float2(-5,5), float2(-7,-1),
		float2(3,7), float2(7,-7)};
	float2 bxy = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float2 MSOff = (100 / ZNRY_RENDER_SCL) * TAA_SAM_DST[FRAME_COUNT % 8] / (16.0 * bxy);
	
	float2 tempOff = 10.0 * (1-STATIC_NOISE) * float2(sin(0.01 * FRAME_COUNT), cos(0.01 * FRAME_COUNT));
	tempOff = round(tempOff * bxy) / bxy;
	float2 offset = frac(0.4 + tempOff + texcoord * (bxy / (512 / (ZNRY_RENDER_SCL / 100.0))));
	float3 noise = tex2D(NoiseSam, offset).rgb;
	return float4(DAMPGI(MSOff + texcoord, 1.0 - 2.0 * noise.xy));
	
}

float4 NormalDiv(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 nor = tex2D(NorSam, texcoord).rgb;
	return float4(nor, 1.0);
}

//Temporal Denoisers
float4 DualFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 CF = tex2D(CurFrm, texcoord);
	float3 nor = tex2D(NorSam, texcoord).rgb;
	float CD = ReShade::GetLinearizedDepth(texcoord);//(nor.x + nor.y + nor.z) / 3.0;
	float4 PF = tex2D(PreFrm, texcoord);
	float PD = tex2D(PreDep, texcoord).r;
	float DeGhostMask = 0.9 * saturate(60.0 * distance(CD, PD));
	if(DEBUG == 6) {return DeGhostMask;}
	CF = lerp(PF.rgba, CF, 0.1 + DeGhostMask);
	//CF.a = NbrClamp(texcoord, CF.a).r;
	CF = DualNbrClamp(texcoord, CF, DeGhostMask);
	return float4(CF);//DeGhostMask;
}

float4 CurrentFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 CF = tex2Dlod(GISam, float4(texcoord, 0, 0));
	float3 nor = tex2D(NorSam, texcoord).rgb;
	float CD = ReShade::GetLinearizedDepth(texcoord);//(nor.x + nor.y + nor.z) / 3.0;
	float4 PF = tex2D(PreFrm, texcoord);
	float PD = tex2D(PreDep, texcoord).r;
	float DeGhostMask = 0.9 * saturate(60.0 * distance(CD, PD));
	if(DEBUG == 6) {return DeGhostMask;}
	CF = lerp(PF.rgba, CF, 0.1 + DeGhostMask);
	//CF.a = NbrClamp(texcoord, CF.a).r;
	CF = NbrClamp(texcoord, CF, DeGhostMask);
	return float4(CF);//DeGhostMask;
}

float PreviousDepth(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 nor = tex2D(NorSam, texcoord).rgb;
	return ReShade::GetLinearizedDepth(texcoord);//(nor.x + nor.y + nor.z) / 3.0;
}

float4 PreviousFrame(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 PF = tex2D(CurFrm, texcoord);
	return float4(PF);
}



//============================================================================================
//Main
//============================================================================================



float3 DAMPRT(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float4 GI;
	if(DONT_DENOISE) {GI = tex2Dlod(GISam, float4(texcoord, 0, 1));}
	else {GI = tex2Dlod(DualFrm, float4(texcoord, 0, 1));}
	float depth = ReShade::GetLinearizedDepth(texcoord);
	
	input = BlendGI(input, GI, depth, texcoord);
	input = tonemap(input);
	
	return input;
}

technique ZN_DAMPRT <
    ui_label = "DAMP RT";
    ui_tooltip ="Zentient DAMP RT - by Zenteon\n" 
				"The sucessor to SDIL, a slightly more expensive, but much stronger base";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LightDown;
		RenderTarget = RYLumDownTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LightMap;
		RenderTarget = RYLumTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LinearBuffer;
		RenderTarget = RYBufTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalBuffer;
		RenderTarget = RYNorTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalDiv;
		RenderTarget = RYNorDivTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = RawGI;
		RenderTarget = RYGITex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CurrentFrame;
		RenderTarget = RY_CurFrm;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DualFrame;
		RenderTarget = RY_DualFrm;
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
		RenderTarget = RY_PreFrm;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PreviousDepth;
		RenderTarget = RY_PreDep;
	}
}
