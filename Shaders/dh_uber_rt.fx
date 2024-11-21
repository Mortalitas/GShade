////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_UBER_RT 0.19.1 (2024-11-14)
//
// This shader is free, if you paid for it, you have been ripped and should ask for a refund.
//
// This shader is developed by AlucardDH (Damien Hembert)
//
// Get more here : https://alucarddh.github.io
// Join my Discord server for news, request, bug reports or help : https://discord.gg/V9HgyBRgMW
//
// License: GNU GPL-2.0
//
////////////////////////////////////////////////////////////////////////////////////////////////
#include "Reshade.fxh"

// VISIBLE PERFORMANCE SETTINGS /////////////////////////////////////////////////////////////////

// Define the working resolution of the intermediate steps of the shader
// Default is 0.5. 1.0 for full-res, 0.5 for quarter-res
// It can go lower for a performance boost like 0.25 but the image will be more blurry and noisy
// It can go higher (lile 2.0) if you have GPU to spare
#ifndef DH_RENDER_SCALE
 #define DH_RENDER_SCALE 0.333
#endif

#ifndef USE_MARTY_LAUNCHPAD_MOTION
 #define USE_MARTY_LAUNCHPAD_MOTION 0
#endif
#ifndef USE_VORT_MOTION
 #define USE_VORT_MOTION 0
#endif


#define HUD_SIZE 128


#define SPHERE 0

#if SPHERE
	#ifndef SPHERE_RATIO
	 #define SPHERE_RATIO 8
	#endif
#endif


// HIDDEN PERFORMANCE SETTINGS /////////////////////////////////////////////////////////////////
// Should not be modified but can help if you really want to squeeze some FPS at the cost of lower fidelity

#define DX9_MODE (__RENDERER__==0x9000)

// Enable ambient light functionality
#define TEX_NOISE DX9_MODE
#define OPTIMIZATION_ONE_LOOP_RT DX9_MODE
#define RESV_SCALE 2

// CONSTANTS /////////////////////////////////////////////////////////////////
// Don't touch this

#define DEBUG_OFF 0
#define DEBUG_GI 1
#define DEBUG_AO 2
#define DEBUG_SSR 3
#define DEBUG_ROUGHNESS 4
#define DEBUG_DEPTH 5
#define DEBUG_NORMAL 6
#define DEBUG_SKY 7
#define DEBUG_MOTION 8
#define DEBUG_AMBIENT 9
#define DEBUG_THICKNESS 10

#define RT_HIT_DEBUG_LIGHT 2.0
#define RT_HIT 1.0
#define RT_HIT_BEHIND 0.5
#define RT_HIT_GUESS 0.25
#define RT_HIT_SKY -0.5
#define RT_MISSED -1.0
#define RT_MISSED_FAST -2.0

#define PI 3.14159265359
#define SQRT2 1.41421356237

// Can be used to fix wrong screen resolution
#define INPUT_WIDTH BUFFER_WIDTH
#define INPUT_HEIGHT BUFFER_HEIGHT

#define RENDER_WIDTH INPUT_WIDTH*DH_RENDER_SCALE
#define RENDER_HEIGHT INPUT_HEIGHT*DH_RENDER_SCALE

#define RENDER_SIZE int2(RENDER_WIDTH,RENDER_HEIGHT)

#define BUFFER_SIZE int2(INPUT_WIDTH,INPUT_HEIGHT)
#define BUFFER_SIZE3 int3(INPUT_WIDTH,INPUT_HEIGHT,RESHADE_DEPTH_LINEARIZATION_FAR_PLANE)


// MACROS /////////////////////////////////////////////////////////////////
// Don't touch this
#define getColor(c) saturate(tex2Dlod(ReShade::BackBuffer,float4((c).xy,0,0))*(bBaseAlternative?fBaseColor:1))
#define getColorSamplerLod(s,c,l) tex2Dlod(s,float4((c).xy,0,l))
#define getColorSampler(s,c) tex2Dlod(s,float4((c).xy,0,0))
#define maxOf3(a) max(max(a.x,a.y),a.z)
#define minOf3(a) min(min(a.x,a.y),a.z)
#define avgOf3(a) (((a).x+(a).y+(a).z)/3.0)
#define CENTER float2(0.5,0.5)
//////////////////////////////////////////////////////////////////////////////

#if USE_MARTY_LAUNCHPAD_MOTION
namespace Deferred {
	texture MotionVectorsTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
	sampler sMotionVectorsTex { Texture = MotionVectorsTex; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };
}
#elif USE_VORT_MOTION
	texture2D MotVectTexVort {  Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
	sampler2D sMotVectTexVort { Texture = MotVectTexVort; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point;  };
#else
	texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
	sampler sTexMotionVectorsSampler { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };
#endif

#define S_PR MagFilter=POINT;MinFilter=POINT;MipFilter= POINT;AddressU=REPEAT;AddressV=REPEAT;AddressW=REPEAT;

namespace DH_UBER_RT_0191 {

    // Textures

#if TEX_NOISE
    texture blueNoiseTex < source ="dh_rt_noise.png" ; > { Width = 512; Height = 512; MipLevels = 1; Format = RGBA8; };
    sampler blueNoiseSampler { Texture = blueNoiseTex; S_PR};
#endif

#if !DX9_MODE
    texture ambientTex { Width = 1; Height = 1; Format = RGBA16F; };
    sampler ambientSampler { Texture = ambientTex; };   

    texture previousAmbientTex { Width = 1; Height = 1; Format = RGBA16F; };
    sampler previousAmbientSampler { Texture = previousAmbientTex; }; 
    
    texture previousColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler previousColorSampler { Texture = previousColorTex; };
    
    texture previousDepthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; };
    sampler previousDepthSampler { Texture = previousDepthTex; };
#endif

    // Roughness Thickness
    texture previousRTFTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler previousRTFSampler { Texture = previousRTFTex; };
    texture RTFTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler RTFSampler { Texture = RTFTex; S_PR};
 
    texture bestRayTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA16F; };
    sampler bestRaySampler { Texture = bestRayTex; S_PR};
	
    texture bestRayFillTex { Width = RENDER_WIDTH/RESV_SCALE; Height = RENDER_HEIGHT/RESV_SCALE; Format = RGBA16F; };
    sampler bestRayFillSampler { Texture = bestRayFillTex; S_PR};
    texture previousBestRayTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA16F; };
    sampler previousBestRaySampler { Texture = previousBestRayTex; S_PR};
   
#if SHPERE
    texture previousSphereTex { Width = RENDER_WIDTH/SPHERE_RATIO; Height = RENDER_HEIGHT/SPHERE_RATIO; Format = RGBA8; };
    sampler previousSphereSampler { Texture = previousSphereTex;};
    
    texture sphereTex { Width = RENDER_WIDTH/SPHERE_RATIO; Height = RENDER_HEIGHT/SPHERE_RATIO; Format = RGBA8; };
    sampler sphereSampler { Texture = sphereTex;};
#endif

    texture normalTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA16F; };
    sampler normalSampler { Texture = normalTex; };
    
    texture resultTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler resultSampler { Texture = resultTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    // RTGI textures
    texture rayColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler rayColorSampler { Texture = rayColorTex; };
    
    texture giPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; };
    sampler giPassSampler { Texture = giPassTex; };

    texture giPass2Tex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; };
    sampler giPass2Sampler { Texture = giPass2Tex;};

    texture giSmoothPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; };
    sampler giSmoothPassSampler { Texture = giSmoothPassTex;};
    
    texture giPreviousAccuTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA8; };
    sampler giPreviousAccuSampler { Texture = giPreviousAccuTex;};
   
    texture giAccuTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA8;};
    sampler giAccuSampler { Texture = giAccuTex;};

    // SSR texture
    texture ssrPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; };
    sampler ssrPassSampler { Texture = ssrPassTex; };

    texture ssrSmoothPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; };
    sampler ssrSmoothPassSampler { Texture = ssrSmoothPassTex; };
    
    texture ssrAccuTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA8; };
    sampler ssrAccuSampler { Texture = ssrAccuTex; };
    
    texture ssrPreviousAccuTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA8; };
    sampler ssrPreviousAccuSampler { Texture = ssrPreviousAccuTex;};
   
    
// Structs
    struct RTOUT {
        float3 wp;
        float status;
    };
    

// Internal Uniforms
    uniform int framecount < source = "framecount"; >;
    uniform int random < source = "random"; min = 0; max = 512; >;

// Parameters

/*
    uniform float fTest <
		ui_category="Test";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.01;
    uniform float fTest2 <
		ui_category="Test";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 25.0;
        ui_step = 0.001;
    > = 8;
    uniform float fTest3 <
		ui_category="Test";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.25;
    uniform float fTest4 <
		ui_category="Test";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.6;
    uniform int iTest <
		ui_category="Test";
        ui_type = "slider";
        ui_min = 0; ui_max = 4;
        ui_step = 1;
    > = 2;
    uniform int iTest2 <
		ui_category="Test";
        ui_type = "slider";
        ui_min = 0; ui_max = 64;
        ui_step = 1;
    > = 12;
    uniform bool bTest <ui_category="Test";> = true;
    uniform bool bTest2 <ui_category="Test";> = false;
    uniform bool bTest3 <ui_category="Test";> = false;
    uniform bool bTest4 <ui_category="Test";> = false;
    uniform bool bTest5 <ui_category="Test";> = false;
    uniform bool bTest6 <ui_category="Test";> = false;
    uniform bool bTest7 <ui_category="Test";> = true;
    uniform bool bTest8 <ui_category="Test";> = false;
    uniform bool bTest9 <ui_category="Test";> = false;
    uniform bool bTest10 <ui_category="Test";> = true;
*/
  
// DEBUG 

    uniform int iDebug <
        ui_category = "Debug";
        ui_type = "combo";
        ui_label = "Display";
        ui_items = "Output\0GI\0AO\0SSR\0Roughness\0Depth\0Normal\0Sky\0Motion\0Ambient light\0Thickness\0";
        ui_tooltip = "Debug the different components of the shader";
    > = 0;
    uniform int iDebugPass <
		ui_category= "Debug";
        ui_type = "combo";
        ui_label = "GI/AO/SSR pass";
        ui_items = "New rays\0Resample\0Spatial denoising\0Temporal denoising\0Merging\0";
        ui_tooltip = "GI/AO/SSR only: Debug the intermediate steps of the shader";
    > = 3;
    
// DEPTH

	uniform float fDepthMultiplier <
        ui_type = "slider";
        ui_category = "Common";
        ui_label = "Depth multiplier";
        ui_min = 0.001; ui_max = 10.00;
        ui_step = 0.001;
    > = 1;


    uniform float fSkyDepth <
        ui_type = "slider";
        ui_category = "Common";
        ui_label = "Sky Depth";
        ui_min = 0.00; ui_max = 1.00;
        ui_step = 0.01;
        ui_tooltip = "Define where the sky starts to prevent if to be affected by the shader";
    > = 0.99;

    uniform float fNormalRoughness <
        ui_type = "slider";
        ui_category = "Common";
        ui_label = "Normal roughness";
        ui_min = 0.000; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "";
    > = 0.1;
    

    uniform int iRoughnessRadius <
        ui_type = "slider";
        ui_category = "Common";
        ui_label = "Roughness Radius";
        ui_min = 1; ui_max = 4;
        ui_step = 2;
        ui_tooltip = "Define the max distance of roughness computation.\n"
                    "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 2;
    
	uniform bool bSmoothNormals <
        ui_category = "Common";
        ui_label = "Smooth Normals";
    > = false;



// AMBIENT LIGHT 
    uniform bool bRemoveAmbient <
        ui_category = "Ambient light";
        ui_label = "Remove Source Ambient light";
    > = true;
    
    uniform float fSourceAmbientIntensity <
        ui_type = "slider";
        ui_category = "Ambient light";
        ui_label = "Strength";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.75;

    
// GI
    
#if DX9_MODE
	#define iCheckerboardRT 0
#else
    uniform int iCheckerboardRT <
        ui_category = "GI/AO: 1st Pass (New rays)";
        ui_type = "combo";
        ui_label = "Checkerboard ray tracing";
        ui_items = "Disabled\0Half per frame\0Quarter per frame\0";
        ui_tooltip = "One ray per pixel, 1 ray per 2-pixels or 1 ray per 4-pixels\n"
                    "Lower=less ghosting, less performance\n"
                    "Higher=more ghosting, less noise, better performance\n"
                    "POSITIVE INPACT ON PERFORMANCES";
    > = 1;
#endif

#if !OPTIMIZATION_ONE_LOOP_RT
    uniform int iRTMaxRays <
        ui_type = "slider";
        ui_category = "GI/AO: 1st Pass (New rays)";
        ui_label = "Max rays...";
        ui_min = 1; ui_max = 6;
        ui_step = 1;
        ui_tooltip = "Maximum number of rays from 1 pixel if the first miss\n"
                    "Lower=Darker image, better performance\n"
                    "Higher=Less noise, brighter image\n"
                    "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 1;
    
    uniform int iRTMaxRaysMode <
        ui_type = "combo";
        ui_category = "GI/AO: 1st Pass (New rays)";
        ui_label = "... per pixel of";
        ui_items = "Render size\0Target size\0";
    > = 0;
#else
	#define iRTMaxRays 0
	#define iRTMaxRaysMode 0
#endif

    uniform float fGIAvoidThin <
        ui_type = "slider";
        ui_category = "GI/AO: 1st Pass (New rays)";
        ui_label = "Avoid thin objects: max thickness";
        ui_tooltip = "Reduce detection of grass or fences";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.25;

    uniform bool bHudBorderProtection <
        ui_type = "slider";
        ui_category = "GI/AO: 1st Pass (New rays)";
        ui_label = "Avoid HUD";
        ui_tooltip = "Reduce chances of detecting large lights from the HUD. Disable if you're using REST or if HUD is hidden";
    > = true;
    
#if !DX9_MODE
    uniform int iMemLevel <
        ui_type = "slider";
        ui_category = "GI/AO: 2nd Pass (Resample)";
        ui_label = "Memory level";
    	ui_min = 0; ui_max = 4;
        ui_step = 1;
    > = 4;
    uniform int iMemRadius <
        ui_type = "slider";
		ui_category = "GI/AO: 2nd Pass (Resample)";
        ui_label = "Memory radius";
        ui_min = 1; ui_max = 3;
        ui_step = 1;
    > = 2;
#else
    uniform int iMemLevel <
        ui_type = "slider";
        ui_category = "GI/AO: 2nd Pass (Resample)";
        ui_label = "Memory level";
    	ui_min = 0; ui_max = 1;
        ui_step = 1;
    > = 1;
    #define iMemRadius 1
#endif 

	// Denoising
    uniform int iSmoothSamples <
        ui_type = "slider";
        ui_category = "GI/AO: 3rd pass (Denoising)";
        ui_label = "Spatial: Samples";
        ui_min = 1; ui_max = 64;
        ui_step = 1;
        ui_tooltip = "Define the number of denoising samples.\n"
                    "Higher:less noise, less performances\n"
                    "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 20;
    
    uniform int iSmoothRadius <
        ui_type = "slider";
        ui_category = "GI/AO: 3rd pass (Denoising)";
        ui_label = "Spatial: Radius";
        ui_min = 0; ui_max = 16;
        ui_step = 1;
        ui_tooltip = "Define the max distance of smoothing.\n";
    > = 16;
    
    uniform int iGIFrameAccu <
        ui_type = "slider";
        ui_category = "GI/AO: 3rd pass (Denoising)";
        ui_label = "GI Temporal accumulation";
        ui_min = 1; ui_max = 32;
        ui_step = 1;
        ui_tooltip = "Define the number of accumulated frames over time.\n"
                    "Lower=less ghosting in motion, more noise\n"
                    "Higher=more ghosting in motion, less noise\n"
                    "/!\\ If motion detection is disable, decrease this to 3 except if you have a very high fps";
    > = 16;
    
    uniform int iAOFrameAccu <
        ui_type = "slider";
        ui_category = "GI/AO: 3rd pass (Denoising)";
        ui_label = "AO Temporal accumulation";
        ui_min = 1; ui_max = 16;
        ui_step = 1;
        ui_tooltip = "Define the number of accumulated frames over time.\n"
                    "Lower=less ghosting in motion, more noise\n"
                    "Higher=more ghosting in motion, less noise\n"
                    "/!\\ If motion detection is disable, decrease this to 3 except if you have a very high fps";
    > = 8;
    
	uniform float fGIRayColorMinBrightness <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "GI Ray min brightness";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.0;
    
    uniform int iGIRayColorMode <
        ui_type = "combo";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "GI Ray brightness mode";
        ui_items = "Crop\0Smoothstep\0Linear\0Gamma\0";
#if DX9_MODE
    > = 0;
#else
    > = 1;
#endif    

    uniform float fGIDistanceAttenuation <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Distance attenuation";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.50;
    
    
    uniform float fSkyColor <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Sky color";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much the sky can brighten the scene";
    > = 0.4;
    
    uniform float fSaturationBoost <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Saturation boost";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.01;
    > = 0.0;
    
    uniform float fGIDarkAmplify <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Dark color compensation";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Brighten dark colors, useful in dark corners";
    > = 0.0;
    
    uniform float fGIBounce <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Bounce intensity";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Define if GI bounces in following frames";
    > = 0.5;

    uniform float fGIHueBiais <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Hue Biais";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much base color can take GI hue.";
    > = 0.25;
    
    uniform float fGILightMerging <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "In Light intensity";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much bright areas are affected by GI.";
    > = 0.50;
    uniform float fGIDarkMerging <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "In Dark intensity";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much dark areas are affected by GI.";
    > = 1.0;
    
    uniform float fGIFinalMerging <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "General intensity";
        ui_min = 0; ui_max = 2.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much the whole image is affected by GI.";
    > = 1.0;
    
    uniform float fGIOverbrightToWhite <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Overbright to white";
        ui_min = 0.0; ui_max = 5.0;
        ui_step = 0.001;
    > = 0.1;
    
// AO

    uniform float fAOBoostFromGI <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "Boost from GI";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.75;
    
    uniform float fAOMultiplier <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "Multiplier";
        ui_min = 0.0; ui_max = 5;
        ui_step = 0.01;
        ui_tooltip = "Define the intensity of AO";
    > = 1.0;
    
    uniform int iAODistance <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "Distance";
        ui_min = 0; ui_max = BUFFER_WIDTH;
        ui_step = 1;
    > = BUFFER_WIDTH/8;
    
    uniform float fAOPow <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "Pow";
        ui_min = 0.001; ui_max = 2.0;
        ui_step = 0.001;
        ui_tooltip = "Define the intensity of the gradient of AO";
    > = 1.0;
    
    uniform float fAOLightProtect <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "Light protection";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Protection of bright areas to avoid washed out highlights";
    > = 0.5;  
    
    uniform float fAODarkProtect <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "Dark protection";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Protection of dark areas to avoid totally black and unplayable parts";
    > = 0.15;

    uniform float fAoProtectGi <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "GI protection";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.05;
    


// SSR
    uniform bool bSSR <
        ui_category = "SSR";
        ui_label = "Enable SSR";
        ui_tooltip = "Toggle SSR";
    > = false;
    
    uniform bool bSSRHQSubPixel <
        ui_category = "SSR";
        ui_label = "High precision sub-pixels";
    > = false;
    
    uniform bool bSSRRinR <
        ui_category = "SSR";
        ui_label = "Reflections in reflection";
    > = false;
    
    uniform int iSSRFrameAccu <
        ui_type = "slider";
        ui_category = "SSR";
        ui_label = "SSR Temporal accumulation";
        ui_min = 1; ui_max = 16;
        ui_step = 1;
        ui_tooltip = "Define the number of accumulated frames over time.\n"
                    "Lower=less ghosting in motion, more noise\n"
                    "Higher=more ghosting in motion, less noise\n"
                    "/!\\ If motion detection is disable, decrease this to 3 except if you have a very high fps";
    > = 4;
    
    uniform float fMergingRoughness <
        ui_type = "slider";
        ui_category = "SSR";
        ui_label = "Roughness reflexivity";
        ui_min = 0.001; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Define how much the roughness decrease reflection intensity";
    > = 0.5;

    uniform float fMergingSSR <
        ui_type = "slider";
        ui_category = "SSR";
        ui_label = "SSR Intensity";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Define this intensity of the Screan Space Reflection.";
    > = 0.3;
    
// Merging
        
    uniform float fDistanceFading <
        ui_type = "slider";
        ui_category = "Fianl Merging";
        ui_label = "Distance fading";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Distance from where the effect is less applied.";
    > = 0.9;
    
    
    uniform float fBaseColor <
        ui_type = "slider";
        ui_category = "Fianl Merging";
        ui_label = "Base color";
        ui_min = 0.0; ui_max = 2.0;
        ui_step = 0.01;
        ui_tooltip = "Simple multiplier for the base image.";
    > = 1.0;
    
    uniform bool bBaseAlternative <
        ui_category = "Fianl Merging";
        ui_label = "Base color alternative method";
    > = false;

    uniform int iBlackLevel <
        ui_type = "slider";
        ui_category = "Fianl Merging";
        ui_label = "Black level ";
        ui_min = 0; ui_max = 255;
        ui_step = 1;
    > = 0;
    
    uniform int iWhiteLevel <
        ui_type = "slider";
        ui_category = "Fianl Merging";
        ui_label = "White level";
        ui_min = 0; ui_max = 255;
        ui_step = 1;
    > = 255;
    
// Debug light
    uniform bool bDebugLight <
        ui_type = "color";
        ui_category = "Debug Light";
        ui_label = "Enable";
    > = false;
    
    uniform bool bDebugLightOnly <
        ui_type = "color";
        ui_category = "Debug Light";
        ui_label = "No scene light";
    > = true;
    
    uniform float3 fDebugLightColor <
        ui_type = "color";
        ui_category = "Debug Light";
        ui_label = "Color";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = float3(1.0,0,0);
    
    uniform float3 fDebugLightPosition <
        ui_type = "slider";
        ui_category = "Debug Light";
        ui_label = "XYZ Position";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = float3(0.5,0.5,0.05);
    
    uniform int iDebugLightSize <
        ui_type = "slider";
        ui_category = "Debug Light";
        ui_label = "Source Size";
        ui_min = 1; ui_max = 100;
        ui_step = 1;
    > = 2;
    
    uniform bool bDebugLightZAtDepth <
        ui_type = "color";
        ui_category = "Debug Light";
        ui_label = "Z at screen depth";
    > = true;
    
// FUCNTIONS

    int halfIndex(float2 coords) {
        int2 coordsInt = (coords * RENDER_SIZE)%2;
        return coordsInt.x==coordsInt.y?0:1;
    }
    
    int quadIndex(float2 coords) {
        int2 coordsInt = (coords * RENDER_SIZE)%2;
        return coordsInt.x+coordsInt.y*2;
    }

    float safePow(float value, float power) {
        return pow(abs(value),power);
    }
    
    float3 safePow(float3 value, float power) {
        return pow(abs(value),power);
    }
    
// Colors
    float3 RGBtoHSV(float3 c) {
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    
        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }
    
    float3 HSVtoRGB(float3 c) {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }
    
    float hueDistance(float a,float b) {
    	return min(abs(a-b),1.0-abs(a-b));
    }
    
    float getPureness(float3 rgb) {
        return maxOf3(rgb)-minOf3(rgb);
    }
    
    float getBrightness(float3 rgb) {
    	return maxOf3(rgb);
    }

// Screen

	float getSkyDepth() {
		return fSkyDepth*fDepthMultiplier;
	}

	float3 getNormal(float2 coords) {
		float3 normal = (tex2Dlod(normalSampler,float4(coords,0,0)).xyz-0.5)*2;
		return normal;
	}

    float getDepth(float2 coords) {
    	return ReShade::GetLinearizedDepth(coords)*fDepthMultiplier;
    }
    
    
    float4 getRTF(float2 coords) {
        return getColorSampler(RTFSampler,coords);
    }
    
    float4 getDRTF(float2 coords) {
    	
        float4 drtf = getDepth(coords);
        drtf.yzw = getRTF(coords).xyz;
        if(fNormalRoughness>0 && drtf.x<=getSkyDepth()) {
            float roughness = drtf.y;
        	drtf.x += drtf.x*roughness*fNormalRoughness*0.1*fDepthMultiplier;
        }
        drtf.z = (0.01+drtf.z)*drtf.x*320;
        drtf.z *= (0.25+drtf.x);
        
        return drtf;
    }
    
    bool inScreen(float3 coords) {
        return coords.x>=0.0 && coords.x<=1.0
            && coords.y>=0.0 && coords.y<=1.0
            && coords.z>=0.0 && coords.z<=fDepthMultiplier;
    }
    
    bool inScreen(float2 coords) {
        return coords.x>=0.0 && coords.x<=1.0
            && coords.y>=0.0 && coords.y<=1.0;
    }
    

    
    float3 getWorldPositionForNormal(float2 coords,bool ignoreRoughness) {
        float depth = getDepth(coords);
        if(!ignoreRoughness && fNormalRoughness>0 && depth<=getSkyDepth()) {
            float roughness = getRTF(coords).x;
            if(bSmoothNormals) roughness *= 1.5;
        	depth += depth*roughness*fNormalRoughness*0.1;
        }
        
        float3 result = float3((coords-0.5)*depth,depth);
        result *= BUFFER_SIZE3;
        return result;
    }
    
    float3 getWorldPosition(float2 coords,float depth) {
        float3 result = float3((coords-0.5)*depth,depth);
        result *= BUFFER_SIZE3;
        return result;
    }

    float3 getScreenPosition(float3 wp) {
        float3 result = wp/BUFFER_SIZE3;
        result.xy /= result.z;
        return float3(result.xy+0.5,result.z);
    }

    float4 computeNormal(float3 wpCenter,float3 wpNorth,float3 wpEast) {
        return float4(normalize(cross(wpCenter - wpNorth, wpCenter - wpEast)),1.0);
    }
    
    float4 computeNormal(float2 coords,float3 offset,bool ignoreRoughness) {
        float3 posCenter = getWorldPositionForNormal(coords,ignoreRoughness);
        float3 posNorth  = getWorldPositionForNormal(coords - offset.zy,ignoreRoughness);
        float3 posEast   = getWorldPositionForNormal(coords + offset.xz,ignoreRoughness);
        
        return computeNormal(posCenter,posNorth,posEast);
    }
    




// Vector operations
    int getPixelIndex(float2 coords,int2 size) {
        int2 pxCoords = coords*size;
        return pxCoords.x+pxCoords.y*size.x+random;
    }

#if !TEX_NOISE
    float randomValue(inout uint seed) {
    	seed = seed * 747796405 + 2891336453;
        uint result = ((seed>>((seed>>28)+4))^seed)*277803737;
        result = (result>>22)^result;
        return result/4294967295.0;
    }
#endif

    float2 randomCouple(float2 coords) {
        float2 v = 0;
#if TEX_NOISE
        int2 offset = int2((framecount*random*SQRT2),(framecount*random*PI))%512;
        float2 noiseCoords = ((offset+coords*BUFFER_SIZE)%512)/512;
        v = abs((getColorSampler(blueNoiseSampler,noiseCoords).rg-0.5)*2.0);
#else
        uint seed = getPixelIndex(coords,RENDER_SIZE);

        v.x = randomValue(seed);
        v.y = randomValue(seed);
#endif
        return v;
    }
    
#if TEX_NOISE
#else
	float3 randomTriple(float2 coords,in out uint seed) {
        float3 v = 0;
        v.x = randomValue(seed);
        v.y = randomValue(seed);
        v.z = randomValue(seed);
        return v;
    }
#endif

    float3 randomTriple(float2 coords) {
        float3 v = 0;
#if TEX_NOISE
        int2 offset = int2((framecount*random*SQRT2),(framecount*random*PI))%512;
        float2 noiseCoords = ((offset+coords*BUFFER_SIZE)%512)/512;
        v = getColorSampler(blueNoiseSampler,noiseCoords).rgb;
#else
        uint seed = getPixelIndex(coords,RENDER_SIZE)+random+framecount;
		v = randomTriple(coords,seed);
#endif
        return v;
    }
    
    float3 getRayColor(float2 coords) {
        return getColorSampler(rayColorSampler,coords).rgb;
    }
    
    bool isEmpty(float3 v) {
        return maxOf3(v)==0;
    }

// PS
	
    float2 getPreviousCoords(float2 coords) {
#if USE_MARTY_LAUNCHPAD_MOTION
		float2 mv = getColorSampler(Deferred::sMotionVectorsTex,coords).xy;
        return coords+mv;
#elif USE_VORT_MOTION
		float2 mv = getColorSampler(sMotVectTexVort,coords).xy;
        return coords+mv;
#else
		float2 mv = getColorSampler(sTexMotionVectorsSampler,coords).xy;
        return coords+mv;
#endif
    } 

    float roughnessPass(float2 coords,float refDepth) {
     
        float3 refColor = getColor(coords).rgb;
        
        float roughness = 0.0;
        float ws = 0;
            
        float3 previousX = refColor;
        float3 previousY = refColor;
        
        [loop]
        for(int d = 1;d<=iRoughnessRadius;d++) {
            float w = 1.0/safePow(d,0.5);
            
            float3 color = getColor(float2(coords.x+ReShade::PixelSize.x*d,coords.y)).rgb;
            float3 diff = abs(previousX-color);
            roughness += maxOf3(diff)*w;
            ws += w;
            previousX = color;
            
            color = getColor(float2(coords.x,coords.y+ReShade::PixelSize.y*d)).rgb;
            diff = abs(previousY-color);
            roughness += maxOf3(diff)*w;
            ws += w;
            previousY = color;
        }
        
        previousX = refColor;
        previousY = refColor;
        
        [loop]
        for(int d = 1;d<=iRoughnessRadius;d++) {
            float w = 1.0/safePow(d,0.5);
            
            float3 color = getColor(float2(coords.x-ReShade::PixelSize.x*d,coords.y)).rgb;
            float3 diff = abs(previousX-color);
            roughness += maxOf3(diff)*w;
            ws += w;
            previousX = color;
            
            color = getColor(float2(coords.x,coords.y-ReShade::PixelSize.y*d)).rgb;
            diff = abs(previousY-color);
            roughness += maxOf3(diff)*w;
            ws += w;
            previousY = color;
        }
        
        
        roughness *= 4.0/iRoughnessRadius;
  
        float refB = getBrightness(refColor);      
        roughness *= safePow(refB,0.5);
        roughness *= safePow(1.0-refB,2.0);
        
        roughness *= 0.5+refDepth*2;
        
        return roughness;
    }

    float thicknessPass(float2 coords, float refDepth,out float sky) {
    
    	if(refDepth>getSkyDepth()) {
    		sky = 0;
    		return 1000;
    	}

        int iThicknessRadius = 4;
        
        float2 thickness = 0;
        float previousXdepth = refDepth;
        float previousYdepth = refDepth;
        float depthLimit = refDepth*0.015;
        float depth;
        float2 currentCoords;
        
        float2 orientation = normalize(randomCouple(coords*PI)-0.5);
        
        bool validPos = true;
        bool validNeg = true;
        sky = 1.0;
        
        [loop]
        for(int d=1;d<=iThicknessRadius;d++) {
            float2 step = orientation*ReShade::PixelSize*d/DH_RENDER_SCALE;
            
            if(validPos) {
                currentCoords = coords+step;
                depth = getDepth(currentCoords);
                if(depth>getSkyDepth() && sky==1) {
                	sky = 1.0-float(d)/iThicknessRadius;
				}
                if(depth-previousXdepth<=depthLimit) {
                    thickness.x = d;
                    previousXdepth = depth;
                } else {
                    validPos = false;
                }
            }
        
            if(validNeg) {
                currentCoords = coords-step;
                depth = getDepth(currentCoords);
                if(depth>getSkyDepth() && sky==1) {
                	sky = 1.0-float(d)/iThicknessRadius;
				} 
                if(depth-previousYdepth<=depthLimit) {
                    thickness.y = d;
                    previousYdepth = depth;
                } else {
                    validNeg = false;
                }
            }
        }        
        
        thickness /= iThicknessRadius;
        
        
        return (thickness.x+thickness.y)*0.5;
    }
    
    float distanceHue(float refHue, float hue) {
    	if(refHue<hue) {
    		return min(hue-refHue,refHue+1.0-hue);
    	} else {
    		return min(refHue-hue,hue+1.0-refHue);
    	}
    }
    
    float scoreLight(float3 rgb,float3 hsv) {
    	return hsv.y * hsv.z;
    }
    
    void PS_RTFS_save(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outRTFS : SV_Target0) {
        outRTFS = getColorSampler(RTFSampler,coords);
    }    
    
    void PS_RTFS(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outRTFS : SV_Target0) {
        float depth = getDepth(coords);
        
        float2 previousCoords = getPreviousCoords(coords);
        
        float4 RTFS;
        RTFS.x = roughnessPass(coords,depth);
        RTFS.y = thicknessPass(coords,depth,RTFS.a);
        
        float4 previousRTFS = getColorSampler(previousRTFSampler,previousCoords);
        RTFS.y = lerp(previousRTFS.y,RTFS.y,0.33);
        RTFS.a = min(RTFS.a,0.25+previousRTFS.a);

        
		RTFS.z = 1;
        
        outRTFS = RTFS;
    }

#if!DX9_MODE    
	void PS_SavePreviousAmbientPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outAmbient : SV_Target0) {
        outAmbient = getColorSampler(ambientSampler,CENTER);
    }
    
    
    
    void PS_AmbientPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outAmbient : SV_Target0) {

        float4 previous = getColorSampler(previousAmbientSampler,CENTER);
        float b = maxOf3(previous.rgb);
        bool first = false;
        if(b<1.0/255.0) {
			previous = 1;
			first = true;
        }
        else previous.rgb += 1.0/255.0;
        
        float3 result = 1.0;
        float bestB = maxOf3(previous.rgb);
        
        float2 currentCoords = 0;
        float2 bestCoords = CENTER;
        float2 rand = randomCouple(coords);
        
        float2 size = BUFFER_SIZE;
        float stepSize = BUFFER_WIDTH/16.0;
        float2 numSteps = size/(stepSize+1);
        
        float avgBrightness = 0;
        int count = 0;
            
        //float2 rand = randomCouple(currentCoords);
        for(int it=0;it<=4 && stepSize>=1;it++) {
            float2 stepDim = stepSize/BUFFER_SIZE;
        
            for(currentCoords.x=bestCoords.x-stepDim.x*(numSteps.x/2);currentCoords.x<=bestCoords.x+stepDim.x*(numSteps.x/2);currentCoords.x+=stepDim.x) {
                for(currentCoords.y=bestCoords.y-stepDim.y*(numSteps.y/2);currentCoords.y<=bestCoords.y+stepDim.y*(numSteps.y/2);currentCoords.y+=stepDim.y) {
                   float2 c = currentCoords+rand*stepDim;
                    float3 color = getColor(c).rgb;
                    b = maxOf3(color);
                    avgBrightness += b;
                    if(b>0.1 && b<bestB) {
                    
                        bestCoords = c;
                        result = min(result,color);
                        bestB = b;
                    }
                    count += 1;
                }
            }
            size = stepSize;
            numSteps = 8;
            stepSize = size.x/numSteps.x;
        }
        
        result = first ? result : min(previous.rgb,result);
        avgBrightness /= count;
        outAmbient = lerp(previous,float4(result,avgBrightness),3.0/60.0);
    }
    
    float3 getRemovedAmbiantColor() {
        if(bRemoveAmbient) {
            float3 color = getColorSampler(ambientSampler,CENTER).rgb;
            color += color.x;
            return color;
        } else {
            return 0;
        }
    }
    
    float getAverageBrightness() {
    	return getColorSampler(ambientSampler,CENTER).a;
    }
    
    float3 filterAmbiantLight(float3 sourceColor) {
        float3 color = sourceColor;
        if(bRemoveAmbient) {
            float3 ral = getRemovedAmbiantColor();
            float3 removedTint = ral - minOf3(ral); 

            color -= removedTint;
            color = saturate(color);
            
            color = lerp(sourceColor,color,fSourceAmbientIntensity);
        }
        return color;
    }
#else
    float3 getRemovedAmbiantColor() {
        if(bRemoveAmbient) {
            return 2.0/255.0;
        } else {
            return 0;
        }
    }

    float3 filterAmbiantLight(float3 sourceColor) {
        return bRemoveAmbient ? sourceColor - 2.0/255.0 : sourceColor;
    }
    
    float getAverageBrightness() {
    	return 0.5;
    }    
#endif

	float4 mulByA(float4 v) {
		v.rgb *= v.a;
		return v;
	}

    void PS_NormalPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outNormal : SV_Target0) {
        
        float3 offset = float3(ReShade::PixelSize, 0.0);
        
        float4 normal = computeNormal(coords,offset,false);
        
		if(bSmoothNormals) {
        	float3 offset2 = offset * 7.5*(1.0-getDepth(coords));
            float4 normalTop = computeNormal(coords-offset2.zy,offset,true);
            float4 normalBottom = computeNormal(coords+offset2.zy,offset,true);
            float4 normalLeft = computeNormal(coords-offset2.xz,offset,true);
            float4 normalRight = computeNormal(coords+offset2.xz,offset,true);
            
            normalTop.a *= smoothstep(1,0,distance(normal.xyz,normalTop.xyz)*1.5)*2;
        	normalBottom.a *= smoothstep(1,0,distance(normal.xyz,normalBottom.xyz)*1.5)*2;
        	normalLeft.a *= smoothstep(1,0,distance(normal.xyz,normalLeft.xyz)*1.5)*2;
        	normalRight.a *= smoothstep(1,0,distance(normal.xyz,normalRight.xyz)*1.5)*2;
        	
            float4 normal2 = 
				mulByA(normal)
				+mulByA(normalTop)
				+mulByA(normalBottom)
				+mulByA(normalLeft)
				+mulByA(normalRight)
			;
            if(normal2.a>0) {
            	normal2.xyz /= normal2.a;
            	normal.xyz = normalize(normal2.xyz);
            }
            
        }
        
        outNormal = float4(normal.xyz/2.0+0.5,1.0);
        
    }
    
    float3 rampColor(float3 color) {
    	float b = getBrightness(color);
        float originalB = b;
        
        if(iGIRayColorMode==1) { // smoothstep
            b *= smoothstep(fGIRayColorMinBrightness,1.0,b);
        } else if(iGIRayColorMode==2) { // linear
            b *= saturate(b-fGIRayColorMinBrightness)/(1.0-fGIRayColorMinBrightness);
        } else if(iGIRayColorMode==3) { // gamma
            b *= safePow(saturate(b-fGIRayColorMinBrightness)/(1.0-fGIRayColorMinBrightness),2.2);
        }
        
        
        return originalB>0 ? color * b / originalB : 0;
    }
    
    void PS_RayColorPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0) {

        float3 color = getColor(coords).rgb;
 

        if(bRemoveAmbient) {  
            color = filterAmbiantLight(color);
        }
		
		float2 previousCoords = getPreviousCoords(coords);
		float3 colorHSV = RGBtoHSV(color);
		int lod = 1;
		while((1.0-colorHSV.y)*colorHSV.z>0.7 && lod<=5) {
			color = getColorSamplerLod(resultSampler,previousCoords,lod).rgb;
			colorHSV = RGBtoHSV(color);
			
			colorHSV.z = 0.9;
			color = HSVtoRGB(colorHSV);
			
			lod ++;
		}
		
		if(fSaturationBoost>0 && colorHSV.z*colorHSV.y>0.1) {
			colorHSV.y = saturate(colorHSV.y+fSaturationBoost);
			color = HSVtoRGB(colorHSV);
		}
		
		if(fGIBounce>0.0) {
			float3 previousColor = getColorSampler(giAccuSampler,previousCoords).rgb;
			float b = getBrightness(color);
			color = saturate(color+previousColor*fGIBounce*(1.0-b)*(0.5+b));
			
		}
        
        
        
        
		float3 result = rampColor(color);        
          
        if(fGIDarkAmplify>0) {
        	float3 colorHSV = RGBtoHSV(result);
        	float avgB = getAverageBrightness();
        	colorHSV.z = saturate(colorHSV.z+fGIDarkAmplify*(1.0-avgB)*colorHSV.z*(1.0-colorHSV.z)*10);
        	result = HSVtoRGB(colorHSV);
        }
        
        if(getBrightness(result)<fGIRayColorMinBrightness) {
            result = 0; 
        }
        
        outColor = float4(result,1.0);
        
    }
    
    bool isSaturated(float2 coords) {
    	return coords.x>=0 && coords.x<=1 && coords.y>=0 && coords.y<=1;
    }
    
#if SHPERE
    int2 sphereSize() {
    	return BUFFER_SIZE/SPHERE_RATIO;
    }
    
    
    void PS_Sphere_save(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0) {
    	outColor = getColorSampler(sphereSampler,coords);
    }
    
    void PS_SpherePass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0) {
    	float2 screencoords = (coords-0.5)*3;
    	float2 currentCoords = screencoords+0.5;
    	float2 mv = 0;
    	
    	int count = 0;
    	float2 v = normalize(coords - 0.5)/iTest;
    	for(int i=1;i<=iTest;i++) {
    		float2 c = 0.5+v*i;
    		if(!isSaturated(c)) {
    			break;
    		}
    		float2 p = getPreviousCoords(c);
    		mv += (p-c);
    		count += 1;
    	}
    	mv /= count;
    	
    	if(isSaturated(currentCoords)) {
    		outColor = getColorSampler(rayColorSampler,currentCoords);
    	} else {    	
    		float2 p = coords + mv;

    		if(isSaturated(p)) {
    			float3 previousColor= getColorSampler(previousSphereSampler,p).rgb;
    			outColor = float4(previousColor,saturate(0.5+getBrightness(previousColor)));
    		} else {
    			outColor = float4(0,0,0,0);
    		}
    	}
	}
#endif
 
    int crossing(float deltaZbefore, float deltaZ) {      
        if(deltaZ<=0 && deltaZbefore>0) return -1;
        if(deltaZ>=0 && deltaZbefore<0) return 1;
        return  0;
    }
    
    bool hit(float3 currentWp, float3 screenWp, float depth, float thickness,float3 behindWp) {
    	if(fGIAvoidThin>0 && thickness<depth*100*fGIAvoidThin) return false;
    	if(currentWp.z>=screenWp.z) {
    		if(currentWp.z<=behindWp.z+distance(screenWp,behindWp)*2.0) return true;
    		if(currentWp.z<=screenWp.z+2*abs(behindWp.z-screenWp.z)) return true;
    		if(currentWp.z<=screenWp.z+thickness*saturate(depth*2)) return true;
    	}
    	return false;
    }
    
    float3 getDebugLightWp() {
    	return getWorldPosition(fDebugLightPosition.xy,bDebugLightZAtDepth ? getDepth(fDebugLightPosition.xy)*0.99 : fDebugLightPosition.z);
    }     	

    bool hitLight(float3 refWp, float3 currentWp,float3 targetWp) {
    	float sourceDist = distance(refWp,currentWp);
    	float targetDist = distance(refWp,targetWp);
        return sourceDist>=targetDist-iDebugLightSize*2;
    }
    
    bool isBehind(float3 refWp,float3 refNormal, float3 hitWp) {
		return distance(refWp-refNormal*0.5,hitWp)>distance(refWp,hitWp);
	}
	
    RTOUT trace(float3 refWp,float3 incrementVector,float startDepth,bool ssr,bool lightTarget,float3 targetWp) {
    
        RTOUT result;
        result.status = RT_MISSED;
        
        float3 currentWp = refWp;
        float3 refNormal = getNormal(getScreenPosition(currentWp).xy);
        
		incrementVector = normalize(incrementVector);		
		incrementVector *= 0.1;
		
				
		currentWp += incrementVector;//*(1.0-screenCoords.z);
		float3 screenCoords = getScreenPosition(currentWp);
		float3 screenWp = getWorldPositionForNormal(screenCoords.xy,true);
        
		float4 DRTF = getDRTF(screenCoords.xy);
        bool isHit = hit(currentWp, screenWp, DRTF.x,DRTF.z,0);
        if(isHit) {
        	result.wp = currentWp;
			result.status = RT_MISSED_FAST;
		    return result;
        }
        
        float3 refVector = normalize(incrementVector);
		incrementVector = refVector;
        
        float3 startBehindWp = 0;
        
		
		float maxDist = lightTarget ? distance(currentWp,targetWp) : sqrt(BUFFER_WIDTH*BUFFER_WIDTH+BUFFER_HEIGHT*BUFFER_HEIGHT);
		
        float deltaZ = 0.0;
        int stepBehind = 0;
        float3 behindWp = 0;
        bool behind = false;
        
        int step = -1;
        incrementVector *= 0.1;
        int maxSteps = ssr?128:16;
        float forcedLength = max(8,maxDist/maxSteps);
		
		while(step<maxSteps && distance(refWp,currentWp)<maxDist) {
			step++;
			if(length(incrementVector)>forcedLength) {
				incrementVector = refVector*forcedLength;
			}
            currentWp += incrementVector;
            
            float3 screenCoords = getScreenPosition(currentWp);
            
            bool outScreen = !inScreen(screenCoords);
            if(outScreen) {
                break;
            }
            
            
            DRTF = getDRTF(screenCoords.xy);
            
            float3 screenWp = getWorldPosition(screenCoords.xy,DRTF.x);
            behind = currentWp.z>screenWp.z;
            
            if(behind) {
            	stepBehind++;
            	if(stepBehind==1) {
            		behindWp = screenWp;
            	}
            }
            
            if(DRTF.x>getSkyDepth() && result.status<=RT_HIT_SKY) {
                result.status = RT_HIT_SKY;
                result.wp = currentWp;
            }
            
            isHit = lightTarget && hitLight(refWp, currentWp,targetWp);
            if(!isHit) isHit = hit(currentWp, screenWp, DRTF.x,DRTF.z,behindWp);

			if(isHit) {
            	result.status = stepBehind>1 || (currentWp.z>=screenWp.z+50 && DRTF.z>=50) ? RT_HIT_BEHIND : RT_HIT;            	
        		result.wp = result.status==RT_HIT_BEHIND ? behindWp : currentWp;
                    
        		return result;
            }
            
            float2 r = randomCouple(screenCoords.xy);

            if(ssr) {
            	deltaZ = screenWp.z-currentWp.z;
        		float l = max(0.5,abs(deltaZ)*0.1);
        		l += r.y;
        		incrementVector = refVector*l;
        	} else  {
        		float l = 1.00+DRTF.x+r.y;
				incrementVector *= l;
            }
            
			if(!behind) {
            	stepBehind = 0;
            }          
        }
        
        
        if(lightTarget) {
            result.status = behind ? RT_HIT_BEHIND : RT_HIT;
        	if(result.status==RT_HIT_BEHIND && DRTF.z<50) {
        		result.status = RT_HIT;
        	}
            result.wp = targetWp;
                        
            return result;
        } else if(maxOf3(abs(behindWp))>0) {
        	result.status = RT_HIT;            	
        	result.wp = behindWp;
        }
        
        return result;
    }

// GI
	

	
	int getIndexRGB(float2 coords,float2 size) {
		int2 px = floor(coords*size);
		if(px.x%2==0) {
			if(px.y%2==0) {
				return 0;
			} else {
				return 1;
			}
		} else {
			if(px.y%2==0) {
				return 2;
			} else {
				return 3;
			}
		}
	}
	
	float getBrightnessRGB(int pixelIndex, float3 color) {
		float b=0;
		
		float p = saturate(getPureness(color)*3);
		if(pixelIndex==0) b = color.r*p;
    	if(pixelIndex==1) b = color.g*p;
    	if(pixelIndex==2) b = color.b*p;
    	if(pixelIndex==3) b = getBrightness(color)*(1.0-p);
		
		return b;
	}
	
	void handleHit(
		in float3 refWp, in float3 refNormal, in float3 lightVector, in bool doTargetLight, in float3 targetColor, in float3 targetWp , in RTOUT hitPosition, 
		inout float3 sky, inout float4 bestRay, inout float sumAO, inout int hits, inout float4 mergedGiColor,
		in bool skipPixel, in float3 refColor, in float3 rand, in out float missRays,in out float3 missedColor
	) {
		
		float3 coords = getScreenPosition(refWp);
        float2 pixelSize = ReShade::PixelSize/DH_RENDER_SCALE;
		float3 screenCoords = getScreenPosition(hitPosition.wp);
        
        float pixelIndex = getIndexRGB(coords.xy,RENDER_SIZE);
        
        float4 giColor = 0.0;
        
        if(!inScreen(screenCoords.xy) || (hitPosition.status == RT_MISSED_FAST && !doTargetLight)) {
        } else if(hitPosition.status <= RT_MISSED) {
			if(doTargetLight) {
				giColor = getRayColor(screenCoords.xy);
				
				float hitB = getBrightness(giColor.rgb);
				float targetB = getBrightness(targetColor);
				if(hitB<targetB && targetB>0.3) missRays += targetB;
				missedColor += targetColor;
				giColor = 0;
			}
			
		} else if(hitPosition.status==RT_HIT_SKY) {
            giColor = getColor(screenCoords.xy);
            float b = getBrightness(giColor.rgb);
			if(b>0) giColor *= fSkyColor/b;
			sky = max(sky,giColor.rgb);
			b = getBrightnessRGB(pixelIndex,giColor.rgb);
			if(b>=bestRay.a+(0.5-rand.x)*0.5) {
				bestRay = float4(screenCoords,b);
			}
			hits++;
			sumAO+=1;
            
        } else if(hitPosition.status>=0 ) {
        
        	float mul = 1;
        	float b = 1;
        
        	float dist = distance(hitPosition.wp,refWp);
        	bool behind = hitPosition.status==RT_HIT_BEHIND;
            	
        	if(behind) {

				//giColor = float3(0,0,1);
				if(doTargetLight) {
					giColor = getRayColor(screenCoords.xy);
					
					float hitB = getBrightness(giColor.rgb);
					float targetB = getBrightness(targetColor);
					if(hitB<targetB && targetB>0.3) missRays += targetB*2;
					missedColor += targetColor;
					giColor = 0;
				}
        		
    		} else {
    			if(doTargetLight) {
					if(hitLight(refWp, hitPosition.wp,targetWp)) {
						giColor = targetColor;
					} else if(!bDebugLight || !bDebugLightOnly) {
						giColor = getRayColor(screenCoords.xy);
						
						float hitB = getBrightness(giColor.rgb);
    					float targetB = getBrightness(targetColor);
    					if(hitB<targetB && targetB>0.3) missRays += targetB*2;
						missedColor += targetColor;
						// hit something before
					}
    			} else {
	    			giColor = getRayColor(screenCoords.xy);
    			}
    			
    			b = getBrightness(giColor.rgb);
    			
    			mul = lerp(0,mul,1.0-saturate(fGIDistanceAttenuation*dist*dist*0.00002));
				
    			{
    				float d = dot(normalize(lightVector),normalize(refNormal));
    				mul *= lerp(1,saturate(abs(d)+0.2),saturate(6*dist/RESHADE_DEPTH_LINEARIZATION_FAR_PLANE));
    			}
    			
    			
    			
    			
    			giColor.rgb *= mul;
				b = getBrightnessRGB(pixelIndex,giColor.rgb);
				if(b>=bestRay.a) {
					bestRay = float4(screenCoords,b);
				}
    			
			}

			float ao = 2.0*dist/(iAODistance*screenCoords.z);
			if(doTargetLight) {
				float maxDist = distance(targetWp,refWp);
				ao = min(ao,lerp(1,safePow(dist/maxDist,10),b));
			}
            sumAO += saturate(ao);
            hits+=1.0;
            
            mergedGiColor.rgb = max(mergedGiColor.rgb,giColor.rgb);
    		mergedGiColor.a = getBrightness(mergedGiColor.rgb);
        }
	}
	
	float2 nextRand2(float2 rand) {
		return  normalize(frac(abs(rand)*PI)-0.5)*2;
	}
	float3 nextRand3(float3 rand) {
		return  normalize(frac(abs(rand)*PI)-0.5)*2;
	}

    void PS_GILightPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0, out float4 outBestRay : SV_Target1) {
        
		int subWidth = 1.0/DH_RENDER_SCALE;
		int subMax = subWidth*subWidth;
		int subCoordsIndex = framecount%subMax;
        
        float depth = getDepth(coords);
        if(depth>getSkyDepth()) {
            outGI = float4(0,0,0,1);
            outBestRay = 0.0;
            return;
        }
        
        
        float3 refWp = getWorldPosition(coords,depth);
        float3 refNormal = getNormal(coords);
        float3 refColor = getColor(coords).rgb;
        
        float3 screenCoords;
        
        float4 bestRay = getColorSampler(previousBestRaySampler,coords);
			
        if((iCheckerboardRT==1 && halfIndex(coords)!=framecount%2)
        	|| (iCheckerboardRT==2 && quadIndex(coords)!=framecount%4)
		) {
        	float2 previousCoords = getPreviousCoords(coords);
            outGI = float4(0,0,0,1);
        	outBestRay = bestRay;
        	return;
        }
        

        float3 sky = 0.0;
        float4 mergedGiColor = 0.0;
		bestRay.a *= 0.1;
		
        
        float sumAO = 0;
        float hits = 0;
        float missRays = 0;
        float3 missedColor = 0;
        int rays = 0;
        
        float2 subCoords = coords;
        
#if TEX_NOISE
        float3 rand = randomTriple(subCoords+0.05*framecount);
#else
        uint seed = getPixelIndex(subCoords,RENDER_SIZE);
        float3 rand = randomTriple(subCoords,seed);
#endif
        
    #if !OPTIMIZATION_ONE_LOOP_RT
    
    	int maxRays = iRTMaxRays*(iRTMaxRaysMode?subMax:1);
        
        [loop]
        for(rays=0;
			rays<maxRays 
			&& !(mergedGiColor.a>0);
			rays++
		) {
        
        	if(bDebugLight && bDebugLightOnly && rays>0) {
    			break;
    		}
    #else
        int maxRays = 1;
    #endif
    		
    		
    		if(DH_RENDER_SCALE<1.0) {
	    		subCoordsIndex = (subCoordsIndex+1)%subMax;
	    		int2 delta = 0;
	    		delta.x = subCoordsIndex%subWidth;
	    		delta.y = subCoordsIndex/subWidth;
		        subCoords = coords+ReShade::PixelSize*(delta-subWidth*0.5);
		        depth = getDepth(subCoords);
		        refWp = getWorldPosition(subCoords,depth);
                refNormal = getNormal(subCoords);
	        }
	        
	        rand = nextRand3(rand);
			rand = normalize(rand-0.5);
            	
			bool doTargetLight = rays==0 && bDebugLight;
			float3 targetWp;
			float3 targetColor;
			float3 lightVector;
			float3 shadowColor;
			if(doTargetLight) {
				targetWp = getDebugLightWp();           
            	targetWp += rand*iDebugLightSize*0.9;
            	lightVector = normalize(targetWp-refWp);
            	targetColor = fDebugLightColor;
			} else {
            	lightVector = rand;
			}

            RTOUT hitPosition = trace(refWp,lightVector,depth,false,doTargetLight,targetWp);
            
            handleHit(
				refWp, refNormal, lightVector, doTargetLight, targetColor,targetWp, hitPosition, 
				sky, bestRay, sumAO, hits, mergedGiColor,
				true,refColor,rand,missRays,missedColor
			);
            
			
                
    #if !OPTIMIZATION_ONE_LOOP_RT
        }
    #endif

    	mergedGiColor.rgb = max(mergedGiColor.rgb,sky);
    	float ao = hits>0 ? saturate(sumAO/hits) : 1.0;
    	
        outBestRay = bestRay;
        outGI = float4(mergedGiColor.rgb,ao);
    }

	void PS_GIFill(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outBestRay : SV_Target) {

		float2 pixelSize = ReShade::PixelSize/DH_RENDER_SCALE;
		

		if(iMemLevel<1)  { 
			outBestRay = getColorSampler(bestRaySampler,coords);
			return;
    	} else {
    		float4 bestRay = 0;
			int2 delta;
			
			
			int2 res = floor(RENDER_SIZE/RESV_SCALE);
			int refIndex = getIndexRGB(coords,res);
			for(delta.x=-8;delta.x<=8;delta.x+=1) {
				for(delta.y=-8;delta.y<=8;delta.y+=1) {
					float d = length(delta);
					if(d>8) continue;
					float2 currentCoords = coords + delta*pixelSize*d;
					int index = getIndexRGB(currentCoords,res);
					if(index != refIndex) {
						float2 step = 0;
						if(index%2!=refIndex%2) {
							step.x = pixelSize.x;
						}
						if((index<2 && refIndex>=2) || (index>=2 && refIndex<2)) {
							step.y = pixelSize.y;
						}
						currentCoords += step;
					}
					if(!inScreen(currentCoords)) continue;
        
					
					float4 ray = getColorSampler(bestRaySampler,currentCoords);
					if(ray.a>bestRay.a) {
						bestRay = ray;
					}
				}
			}
			
			
			outBestRay = bestRay;
			return;
    	}
		
	}
	
	float getBorderDist(float3 wp) {
		float2 coords = wp.xy/BUFFER_SIZE;
		float2 borderDists = min(coords,1.0-coords)*BUFFER_SIZE;
        float borderDist = min(borderDists.x,borderDists.y);
        return borderDist<=HUD_SIZE ? 1+HUD_SIZE-borderDist : 0;
	}
	
    void PS_GILightPass2(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0, out float4 outBestRay : SV_Target1) {
        
        float depth = getDepth(coords);
        if(depth>getSkyDepth()) {
            outGI = float4(0,0,0,1);
            outBestRay = 0.0;
            return;
        }
        
        int subWidth = 1.0/DH_RENDER_SCALE;
        int subMax = subWidth*subWidth;
        int subCoordsIndex = framecount%subMax;
        
        bool skipPixel = 
            (iCheckerboardRT==1 && halfIndex(coords)!=framecount%2)
            || (iCheckerboardRT==2 && quadIndex(coords)!=framecount%4);   
     
        float2 previousCoords = getPreviousCoords(coords);
        
        float4 firstPassFrame = skipPixel
			? getColorSampler(giPreviousAccuSampler,previousCoords)
			: getColorSampler(giPassSampler,coords);
			
		if(iMemLevel==0) {
            outGI = firstPassFrame;
            outBestRay = 0.0;
            return;
        }
                
        float3 refWp = getWorldPosition(coords,depth);
        float3 refNormal = getNormal(coords);
        float3 refColor = getColor(coords).rgb;
        
        float3 screenCoords;
        
        float firstAO = firstPassFrame.a;
        float4 mergedGiColor = firstPassFrame;
        
        mergedGiColor.a = getBrightness(mergedGiColor.rgb);
        
        float hits = 0;
        float sumAO = 0;
        
        float3 sky = 0.0;
        float4 bestRay = getColorSampler(bestRayFillSampler,previousCoords);
		bestRay.a = 0;
        
        
        int rays = 0;
        float missRays = 0;
        float3 missedColor = 0;
        
        float2 subCoords = coords;
        int refIndex = getIndexRGB(coords,RENDER_SIZE);
                                  
        
#if TEX_NOISE
        float3 rand = randomTriple(subCoords+0.05*framecount);
#else
        uint seed = getPixelIndex(subCoords,RENDER_SIZE);
        float3 rand = randomTriple(subCoords,seed);
#endif
        float2 pixelSize = ReShade::PixelSize/DH_RENDER_SCALE;
        
        if(!skipPixel && iMemLevel>0 && !(bDebugLight && bDebugLightOnly)) {
            
            float4 previousBestRay = 0;
                
            {
                        
                float3 targetCoords = bestRay.xyz;
                targetCoords.xy = getPreviousCoords(targetCoords.xy);
                targetCoords.z = getDepth(targetCoords.xy);
                bool doTargetLight = targetCoords.z<=fSkyDepth;
                
                float3 targetWp = getWorldPosition(targetCoords.xy,targetCoords.z);
                targetWp += (rand-0.5)*(8+(bHudBorderProtection ? 8*getBorderDist(targetWp)/HUD_SIZE:0));
                
                float3 lightVector = normalize(targetWp-refWp);
                float3 targetColor = getRayColor(targetCoords.xy).rgb;
                
                RTOUT hitPosition = trace(refWp,lightVector,depth,false,doTargetLight,targetWp);
                handleHit(
                    refWp, refNormal, lightVector, doTargetLight, targetColor, targetWp, hitPosition, 
                    sky, bestRay, sumAO, hits, mergedGiColor,
                    skipPixel,refColor,rand,missRays,missedColor
                );
				rays++;
                
            }
            
#if !DX9_MODE
	if(iMemLevel==2) {
	#if TEX_NOISE
				rand = normalize(randomCouple(subCoords+(0.05*(rays+framecount)))-0.5);
	#else
				rand = normalize(randomTriple(subCoords,seed).xy-0.5);
	#endif
                int2 delta;
                int r = iMemRadius;
                previousBestRay.a = 0;
                for(delta.x=-r;delta.x<=r;delta.x+=1) {
                    for(delta.y=-r;delta.y<=r;delta.y+=1) {
                    
						float2 currentCoords = coords+delta*pixelSize*RESV_SCALE;
                        
                        if(!inScreen(currentCoords)) continue;

                   	 int index = getIndexRGB(currentCoords,RENDER_SIZE/RESV_SCALE);
                   	 if(index != refIndex) {
							float2 step = 0;
							if(index%2!=refIndex%2) {
								step.x = pixelSize.x;
							}
							if((index<2 && refIndex>=2) || (index>=2 && refIndex<2)) {
								step.y = pixelSize.y;
							}
							currentCoords += step;
						}
                        
                        float4 ray = getColorSampler(bestRayFillSampler,currentCoords);
                        if(ray.a>=previousBestRay.a+(0.5-rand.x) && ray.z<=fSkyDepth) {
                            previousBestRay = ray;
                        }
                    }
                }
                

                        
                float3 targetCoords = previousBestRay.xyz;
                targetCoords.xy = getPreviousCoords(targetCoords.xy);
                targetCoords.z = getDepth(targetCoords.xy);
                bool doTargetLight = targetCoords.z<=fSkyDepth;
                
                        
                float3 targetWp = getWorldPosition(targetCoords.xy,targetCoords.z);
                targetWp += (rand-0.5)*(8+(bHudBorderProtection ? 8*getBorderDist(targetWp)/HUD_SIZE:0));
                
                float3 lightVector = normalize(targetWp-refWp);
                float3 targetColor = getRayColor(targetCoords.xy).rgb;
                
                RTOUT hitPosition = trace(refWp,lightVector,depth,false,doTargetLight,targetWp);
                handleHit(
                    refWp, refNormal, lightVector, doTargetLight, targetColor, targetWp, hitPosition, 
                    sky, bestRay, sumAO, hits, mergedGiColor,
                    skipPixel,refColor,rand,missRays,missedColor
                );
				if(distance(hitPosition.wp,targetWp)>16) {
					missRays += getBrightness(targetColor);
					//sumAO += 1;
				}
				rays++;
                
            } else if(iMemLevel==3) {
                
                float2 delta;
                int s = 1;
                int r = iMemRadius*s;
                
                for(delta.x=-r;delta.x<=r;delta.x+=s) {
                    for(delta.y=-r+abs(delta.x);delta.y<=r-+abs(delta.x);delta.y+=s) {
			#if TEX_NOISE
						rand = (randomCouple(subCoords+(0.05*(rays+framecount)))-0.5);
			#else
						rand = (randomTriple(subCoords,seed).xy-0.5);
			#endif
						
						float2 currentCoords = coords+delta*pixelSize*64*rand.xy;
                        
                        if(!inScreen(currentCoords)) continue;
                        
                   	 int index = getIndexRGB(currentCoords,RENDER_SIZE/RESV_SCALE);
                   	 if(index != refIndex) {
							float2 step = 0;
							if(index%2!=refIndex%2) {
								step.x = pixelSize.x;
							}
							if((index<2 && refIndex>=2) || (index>=2 && refIndex<2)) {
								step.y = pixelSize.y;
							}
							currentCoords += step;
						}
                        
                        float4 ray = getColorSampler(bestRayFillSampler,currentCoords);
						
	                    //ray.xy += (0.1+abs(delta))*(bHudBorderProtection?0.5+dist:1)*(rand.xy)*0.03/BUFFER_HEIGHT;                        
						
		
                        float3 targetCoords = ray.xyz;
                    	targetCoords.z = getDepth(targetCoords.xy);
                        bool doTargetLight = targetCoords.z<=fSkyDepth;
                        
                        float3 targetWp = getWorldPosition(targetCoords.xy,targetCoords.z);                        
                		targetWp += (rand-0.5)*(8+(bHudBorderProtection ? 8*getBorderDist(targetWp)/HUD_SIZE:0));
                        
                        float3 lightVector = normalize(targetWp-refWp);
                        float3 targetColor = getRayColor(targetCoords.xy).rgb;
                    
                        RTOUT hitPosition = trace(refWp,lightVector,depth,false,doTargetLight,targetWp);
                        
                        handleHit(
                            refWp, refNormal, lightVector, doTargetLight, targetColor, targetWp, hitPosition, 
                            sky, bestRay, sumAO, hits, mergedGiColor,
                            skipPixel,refColor,rand,missRays,missedColor
                        );
                        
                        rays++;
                        
                    }
                }
			} else if(iMemLevel==4) {
			
				float step = 1.0/(iMemRadius+2);
				float2 searchCoords = 0;
				float dist = 0;
				
				for(searchCoords.y=step*0.5+rand.y*0.1;searchCoords.y<=1.0-step;dist=distance(searchCoords,coords)/max(1,iMemRadius),searchCoords.y+=0.1*step+dist*(1+rand.x)) {
					for(searchCoords.x=step*0.5+rand.x*0.1;searchCoords.x<=1.0-step;dist=distance(searchCoords,coords)/max(1,iMemRadius),searchCoords.x+=0.1*step+dist*(1+rand.y)) {
            
			#if TEX_NOISE
						rand = (randomCouple(subCoords+(0.05*(rays+framecount)))-0.5);
			#else
						rand = (randomTriple(subCoords,seed).xy-0.5);
			#endif
						float2 currentCoords = searchCoords+pixelSize*(0.1+step*dist)*BUFFER_SIZE*rand.xy;
						
                        if(!inScreen(currentCoords)) continue;

                   	 int index = getIndexRGB(currentCoords,RENDER_SIZE/RESV_SCALE);
                   	 if(index!=refIndex) continue;
                        
                        
                        float4 ray = getColorSampler(bestRayFillSampler,currentCoords);                       
						
		
                        float3 targetCoords = ray.xyz;
                    	targetCoords.z = getDepth(targetCoords.xy);
                        bool doTargetLight = targetCoords.z<=fSkyDepth;
                        
                        float3 targetWp = getWorldPosition(targetCoords.xy,targetCoords.z);
                        targetWp += rand*(8+(bHudBorderProtection ? 8*getBorderDist(targetWp)/HUD_SIZE:0));
                        
                        float3 lightVector = normalize(targetWp-refWp);
                        float3 targetColor = getRayColor(targetCoords.xy).rgb;
                    
                        RTOUT hitPosition = trace(refWp,lightVector,depth,false,doTargetLight,targetWp);
                        
                        handleHit(
                            refWp, refNormal, lightVector, doTargetLight, targetColor, targetWp, hitPosition, 
                            sky, bestRay, sumAO, hits, mergedGiColor,
                            skipPixel,refColor,rand,missRays,missedColor
                        );
                        
                        rays++;
                        
                    }
                }
                
            }
            
#endif
        }
    	
        float ao;
        	
        sumAO *= 5-iMemRadius;
        hits *= 5-iMemRadius;
        
        sumAO += firstAO*iRTMaxRays;
        hits += iRTMaxRays;
        ao = hits>0 ? sumAO/hits : 1;
    		
    	if(missRays>=0.5) {
			mergedGiColor.rgb -= (missedColor/missRays)*0.5;
			mergedGiColor.rgb = saturate(mergedGiColor.rgb);
			ao /= missRays/rays+1;
    		
   	 }
        
        mergedGiColor.rgb = max(mergedGiColor.rgb,sky);
        outBestRay = bestRay;
        outGI = float4(mergedGiColor.rgb,ao);
    }

// SSR
    void PS_SSRLightPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0) {
        if(!bSSR || fMergingSSR==0.0) {
            outColor = 0.0;
            return;
        }
        
        int subWidth = 1.0/DH_RENDER_SCALE;
		int subMax = subWidth*subWidth;
		int subCoordsIndex = framecount%subMax;
		int2 delta = 0;
        
        float2 subCoords = coords;
        
        if(!bSSRHQSubPixel && DH_RENDER_SCALE<1.0) {
        	delta.x = subCoordsIndex%subWidth;
    		delta.y = subCoordsIndex/subWidth;
	        subCoords = coords+ReShade::PixelSize*(delta-subWidth*0.5);
        }
            
        float depth = getDepth(subCoords);
        
        if(depth>getSkyDepth()) {
            outColor = 0.0;
        } else {
        
            float3 result = 0;
            float weightSum = 0;
            
            [loop]
            for(int rays=0;rays<(bSSRHQSubPixel && DH_RENDER_SCALE<1.0 ?subMax:1);rays++) {
        		
        		if(bSSRHQSubPixel && DH_RENDER_SCALE<1.0) {
    	    		subCoordsIndex = (framecount+rays)%subMax;
    	    		delta.x = subCoordsIndex%subWidth;
    	    		delta.y = subCoordsIndex/subWidth;
    		        subCoords = coords+ReShade::PixelSize*(delta-subWidth*0.5);
    		        depth = getDepth(subCoords);
    	        }
                
                float3 targetWp = getWorldPosition(subCoords,depth); 
                float3 targetNormal = getNormal(subCoords);
                
        
                float3 lightVector = reflect(targetWp,targetNormal);
                
                RTOUT hitPosition = trace(targetWp,lightVector,depth,true,false,0);
				float3 screenPosition = getScreenPosition(hitPosition.wp.xyz);
                    
                if(hitPosition.status<RT_HIT_SKY) {
                } else {
                    //float3 screenPosition = getScreenPosition(hitPosition.wp.xyz);
                    float2 previousCoords = getPreviousCoords(screenPosition.xy);
                    float depth = getDepth(screenPosition.xy);
                    float3 c = getColorSampler(resultSampler,previousCoords).rgb;
                    
					float3 hitNormal = getNormal(screenPosition.xy);
                    if(distance(hitNormal,targetNormal)<0.2) continue;
                    
                    if(bSSRRinR && hitPosition.status!=RT_HIT_BEHIND) { 
						c = max(c,getColorSampler(ssrAccuSampler,previousCoords).rgb*0.8);
					}
                    float w = getBrightness(c)*100.0+1.0;
                    
                    
                    result += c*w;
                    weightSum += w;
                
                }
            }

            if(weightSum>0) {
                outColor = float4(result/weightSum,(bSSRHQSubPixel?1:subMax)*weightSum/32.0);
            } else {
            	outColor= float4(0,0,0,0);
            }
        }
        
            
    }
    
    void smooth(
        sampler sourceGISampler,
        sampler sourceSSRSampler,
        float2 coords, out float4 outGI, out float4 outSSR,bool firstPass
    ) {
        float2 pixelSize = 1.0/tex2Dsize(sourceGISampler);
        
#if TEX_NOISE
        float3 rand = randomTriple(coords+0.05*framecount);
#else
        uint seed = getPixelIndex(coords,RENDER_SIZE);
        float3 rand = randomTriple(coords,seed);
#endif
        
        
        if(firstPass  && DH_RENDER_SCALE<1.0) {
	        int subWidth = 1.0/DH_RENDER_SCALE;
			int subMax = subWidth*subWidth;
			
    	    coords += (floor(rand.xy*subWidth)-0.5*subWidth)*ReShade::PixelSize;
        }
        
        float refDepth = getDepth(coords);
        if(refDepth>getSkyDepth()) {
            outGI = float4(0,0,0,1);
			outSSR = float4(0,0,0,1);
            return;
        }
        
        float3 refNormal = getNormal(coords);  
 
        float3 gi = 0.0;
        float sumAO = 0;
        
        float4 ssr = 0.0;
        
        
        float3 weightSum; // gi, ao, ssr
        
        float3 giR;
        float3 giG;
        float3 giB;
        float3 giW;
        float4 giRGBWws;
        
        
        float2 previousCoords = getPreviousCoords(coords);            
        
        		
        float4 refSSR = getColorSampler(sourceSSRSampler,coords);
        
        float2 currentCoords;
        
        int sSamples = ceil(iSmoothSamples*0.25);
                        
        int2 delta;
        
        int extra = 0;
        float hitSky = 0;
        float count = 0;
        
    	float roughness = getRTF(coords).x;
        
    	for(float s=0;s<sSamples;s+=1) {
#if TEX_NOISE
			rand = normalize(randomCouple(coords+(0.05*(s+1+framecount)))-0.5);
#else
			rand = normalize(randomTriple(coords,seed).xy-0.5);
#endif
		
			if(s==0) rand = 0;
			count += 1;
			
			for(int i=0;i<4;i++) {
			
				currentCoords = coords+float2(cos(rand.x*PI*2),sin(rand.x*PI*2))*pixelSize.xy*iSmoothRadius*s/sSamples;
				if(i==1 || i==3) {
					currentCoords.x += pixelSize.x;
				}
				if(i==2 || i==3) {
					currentCoords.y += pixelSize.y;
				}
			
	            float depth = getDepth(currentCoords);
				if(depth>getSkyDepth()) {
					hitSky += 1.0;
					continue;
				}
				
	            // Distance weight | gi,ao,ssr 
	            float dist = distance(coords*BUFFER_SIZE,currentCoords*BUFFER_SIZE)/(1+iSmoothRadius);
	            float3 weight = sqrt(1.0/(1.0+sqrt(dist)));
	            //weight /= (s+1);
	
				bool skipPixel = 
		            (iCheckerboardRT==1 && halfIndex(currentCoords)!=framecount%2)
		            || (iCheckerboardRT==2 && quadIndex(currentCoords)!=framecount%4);
	
				if(skipPixel) weight.xy *= 0.15;			
	            
	            // Normal weight
	            
	            if(roughness<=0.125) {
	                float3 normal = getNormal(currentCoords);
	            	float d = dot(normal,refNormal);
	            	float nw = saturate(d);
	            	weight.xyz *= nw*nw*nw;	
	            	if(!firstPass && nw<0.995) {
						continue;
					}
	            }
	            
	            { // Depth weight
	                float dw = saturate(1.0-abs(refDepth-depth)*50);
	                weight *= dw*dw;
	            }
	            
				if(weight.x>0) {
	                float4 curGiAo = getColorSampler(sourceGISampler,currentCoords);
	            
	                gi += curGiAo.rgb*weight.x;
	                sumAO += curGiAo.a*weight.y;
	                
	                int index = getIndexRGB(currentCoords,RENDER_SIZE);
	
	                if(index==0) {
						giR += curGiAo.rgb*weight.x;
	            		giRGBWws.r += weight.x;
	                } else if(index==1) {
						giG += curGiAo.rgb*weight.x;
	                	giRGBWws.g += weight.x;
	                } else if(index==2) {
						giB += curGiAo.rgb*weight.x;
	                	giRGBWws.b += weight.x;
	                } else {
	                	giW += curGiAo.rgb*weight.x;
	            		giRGBWws.a += weight.x;
	                }
	            }
	            
	            weightSum += weight;
	            
            }
            
    	}
        
        
        
        
        if(weightSum.x>0) {
        	gi /= weightSum.x;
        } else {
        	gi = 0;
        }
        
        if(firstPass) {
        	giR /= giRGBWws.r;
        	giG /= giRGBWws.g;
        	giB /= giRGBWws.b;
        	giW /= giRGBWws.a;
        	gi = max(max(giR,giG),max(giB,giW));
        }
        
    	
        if(sumAO>0 && weightSum.y>0) {
        	sumAO /= weightSum.y;
        } else {
        	sumAO = 1.0;
        }
      
        if(bSSR) {
        	ssr = getColorSampler(sourceSSRSampler,coords);
        } else {
        	ssr = 0;
        }
		
        if(!firstPass) {
        	
			float2 op = 1.0/float2(iGIFrameAccu,iAOFrameAccu);
				
			float3 color = getColor(coords).rgb;
			float motionDist = 1+distance(coords*BUFFER_SIZE,previousCoords*BUFFER_SIZE);
			float3 dist = 0;
			
#if !DX9_MODE
			float3 prevColor = getColorSampler(previousColorSampler,previousCoords).rgb;
			dist = abs(color-prevColor);
			if(minOf3(dist)>3.0/255.0) {
				op = saturate(op*iGIFrameAccu*0.5);
			}
#endif			
			
			op = lerp(op,1,saturate(motionDist/256));			
			op = saturate(op);
			
			
			
			float3 savedGi = gi;
			
			float4 previousColorMoved = getColorSampler(giPreviousAccuSampler,previousCoords); 
			
			float3 giSky = max(gi,previousColorMoved.rgb*(1.0-op.x));
			float3 giNotSky = lerp(previousColorMoved.rgb,gi,op.x);
			gi = lerp(giNotSky.rgb,giSky,saturate(2*hitSky/count));
			
			float aoSky = max(sumAO,previousColorMoved.a*(1.0-op.y));
			float ao = lerp(previousColorMoved.a,sumAO,op.y);
			sumAO = lerp(ao,aoSky,saturate(2*hitSky/count));
    	
	    	
	    	if(bSSR) {
				float4 previousSSRm = getColorSampler(ssrPreviousAccuSampler,previousCoords);
				
        		float op = 1.0/iSSRFrameAccu;
            	op = max(op/3,op*saturate(1.0-refDepth*3));
            	
				if(maxOf3(dist)>3.0/255.0) {
					op = saturate(op*iSSRFrameAccu*0.5);
				}
				
				op = lerp(op,1,saturate(motionDist/256));			
				op = saturate(op);
				
				ssr.rgb = lerp(
                        previousSSRm.rgb,
                        ssr.rgb,
                        op
					);
	        }
        }
        
    	
        outGI = float4(gi,sumAO);
        outSSR = ssr;        
        
    }
    
    void PS_SmoothPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0, out float4 outSSR : SV_Target1) {
        smooth(giPass2Sampler,ssrPassSampler,coords,outGI,outSSR, true);
    }
    
    void PS_AccuPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0, out float4 outSSR : SV_Target1) {
        smooth(giSmoothPassSampler,ssrSmoothPassSampler,coords,outGI,outSSR, false);
    }
    
    float computeAo(float ao,float colorBrightness, float giBrightness) {
    	
    	//ao = fAOMultiplier-(1.0-ao)*fAOMultiplier;
        ao = 1.0-saturate((1.0-ao)*fAOMultiplier);
		if(fAOBoostFromGI>0) {
			float boosted = 1.0-max(1.0-ao,(1.0-giBrightness)*(1.0-giBrightness));
			ao = lerp(ao,boosted,fAOBoostFromGI);
		}
        ao = (safePow(ao,fAOPow));
        
        ao += giBrightness*fAoProtectGi*4.0;
        
		ao += (1.0-colorBrightness)*(1.0-colorBrightness)*fAODarkProtect;
        ao += colorBrightness*fAOLightProtect;
		
        
		ao = saturate(ao);
        ao = 1.0-saturate((1.0-ao)*fAOMultiplier);
    	
    	
        
        return ao;
    }
    
    float3 computeSSR(float2 coords,float brightness) {
        float4 ssr = getColorSampler(ssrAccuSampler,coords);
        if(ssr.a==0) return 0;
        
        float3 ssrHSV = RGBtoHSV(ssr.rgb);
        
        float ssrBrightness = getBrightness(ssr.rgb);
        float ssrChroma = ssrHSV.y;
        
        float colorPreservation = lerp(1,safePow(brightness,2),1.0-safePow(1.0-brightness,10));
        
        ssr = lerp(ssr,ssr*0.5,saturate(ssrBrightness-ssrChroma));
        
        float roughness = getRTF(coords).x;
        
        float rCoef = lerp(1.0,saturate(1.0-roughness*10),fMergingRoughness);
        float coef = fMergingSSR*(1.0-brightness)*rCoef;
        
        return ssr.rgb*coef;
            
    }

    void PS_UpdateResult(in float4 position : SV_Position, in float2 coords : TEXCOORD, 
			out float4 outResult : SV_Target,
			out float4 outGiAccu : SV_Target1,
			out float4 outSsrAccu : SV_Target2
#if !DX9_MODE
			,out float4 outColor : SV_Target3,
			out float4 outDepth : SV_Target4
#endif
	) {
        float depth = getDepth(coords);
        float3 refColor = getColor(coords).rgb;
        
#if !DX9_MODE
        outDepth = depth;
        outColor = float4(refColor,1);
#endif

        //float refB = getBrightness(refColor);
        float3 color = refColor;
        float3 colorHSV = RGBtoHSV(color);
        
        if(depth>getSkyDepth()) {
            outResult = float4(color,1.0);
            outGiAccu = 0;
            outSsrAccu = 0;
        } else {   
            float originalColorBrightness = maxOf3(color);

            if(bRemoveAmbient) {
                color = filterAmbiantLight(color);
            }
            
            float4 passColor = getColorSampler(giAccuSampler,coords);
            
            float3 gi = passColor.rgb;
            float3 giHSV = RGBtoHSV(gi);
            float giBrightness =  getBrightness(gi);            
            colorHSV = RGBtoHSV(color);
           
            float colorBrightness = getBrightness(color);
            	
            // Base color
            float3 result = color*(bBaseAlternative?1.0:fBaseColor);
           // float p = getPureness(result);
            
            	
            // GI
            float avgB = getAverageBrightness();
            if(fGIHueBiais>0 && giHSV.y>0 && giHSV.z>0) {
            	float3 c = gi;
            	c *= colorBrightness/giHSV.z;
				result = lerp(result,c,saturate(fGIHueBiais*4*giHSV.y*(1.0-giHSV.z)*(1.0-colorHSV.y)));				
			}
        	result += 
            	(
					safePow(saturate(avgB+0.3),2)*fGILightMerging*2*(0.5+originalColorBrightness*0.5)
					+safePow(1.0-saturate(avgB+0.3),2)*(0.2+smoothstep(1,0,safePow(colorBrightness,0.3))*0.8)*(fGIDarkMerging+smoothstep(1,0,colorBrightness)*fGIDarkMerging*2)*8
					
				)
				*safePow(result+safePow(originalColorBrightness,0.2)*(1.0-originalColorBrightness)*0.25,2.0)
				*(1.0-originalColorBrightness*originalColorBrightness)
				*fGIFinalMerging
				*gi
				*(1+giHSV.y*0.25);
				
            
        	// Overbright
        	if(fGIOverbrightToWhite>0) {
        		float b = maxOf3(result);
	        	if(b>1) {
	        		result += (b-1)*fGIOverbrightToWhite;
	        	}
        	}
            
            // Mixing
            //result = lerp(color,result,fGIFinalMerging);
            
            // Apply AO after GI
            {
                float resultB = getBrightness(result);
                float ao = passColor.a;
                ao = computeAo(ao,resultB,giBrightness);
                result *= ao;
            }
            
            outResult = float4(saturate(result),1.0);
            outGiAccu = passColor;
            outSsrAccu = getColorSampler(ssrAccuSampler,coords);
            
        }
    }
    

    
    void PS_DisplayResult(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outPixel : SV_Target0)
    {        
        float3 result = 0;
        if(bDebugLight) {
        	if(distance(coords,fDebugLightPosition.xy)<2*ReShade::PixelSize.x) {
	            float colorBrightness = getBrightness(result);
		            float3 ssr = computeSSR(coords,colorBrightness);
	            outPixel = float4(fDebugLightColor,1);
	            return;
			}
        }
        
        
        if(iDebug==DEBUG_OFF) {
            result = getColorSampler(resultSampler,coords).rgb;
            
            float3 resultHSV = RGBtoHSV(result);
            float depth = getDepth(coords);
            float3 color = getColor(coords).rgb;
                
            // SSR
            if(bSSR && fMergingSSR>0.0) {
                float colorBrightness = getBrightness(result);
                float3 ssr = computeSSR(coords,colorBrightness);
                result += ssr;
            }
            
            // Levels
            result = (result-iBlackLevel/255.0)/((iWhiteLevel-iBlackLevel)/255.0);
            
            // Distance fading
            if(fDistanceFading<1.0 && depth>fDistanceFading*fDepthMultiplier) {
                float diff = depth/fDepthMultiplier-fDistanceFading;
                float max = 1.0-fDistanceFading;
                float ratio = diff/max;
                result = result*(1.0-ratio)+color*ratio;
            }
            
            result = saturate(result);
            
        } else if(iDebug==DEBUG_GI) {
            float4 passColor;
            if(iDebugPass==0) passColor =  getColorSampler(giPassSampler,coords);
            if(iDebugPass==1) passColor =  getColorSampler(giPass2Sampler,coords);
            if(iDebugPass==2) passColor =  getColorSampler(giSmoothPassSampler,coords);
            if(iDebugPass>=3) passColor =  getColorSampler(giAccuSampler,coords);

			result = passColor.rgb;
            if(iDebugPass==4) {
            	float3 gi = result;
            	float3 refColor = getColor(coords).rgb;
		        float3 color = refColor; 

	            if(bRemoveAmbient) {
	                color = filterAmbiantLight(color);
	            }

				float colorBrightness = getBrightness(color);
				float3 colorHSV = RGBtoHSV(color);
				
				float3 giHSV = RGBtoHSV(gi);
            	float giBrightness =  getBrightness(gi);            
            
	            float3 tintedColor = colorHSV;
	            tintedColor.xy = gi.xy;
	            tintedColor = HSVtoRGB(tintedColor);
	            //hb += saturate(1.0-colorHSV.y-0.6)*(max(1.0-colorHSV.z,colorHSV.z))*2;
	            float avgB = getAverageBrightness();
	            
	            result = color;
	            
	            if(fGIHueBiais>0 && giHSV.y>0 && giHSV.z>0) {
	            	float3 c = gi;
	            	c *= colorBrightness/giHSV.z;
					result = lerp(result,c,saturate(fGIHueBiais*4*giHSV.y*(1.0-giHSV.z)));
				}
				
	        	result += 
	            	(
						safePow(saturate(avgB+0.3),2)*fGILightMerging*2*(0.5+colorBrightness*0.5)
						+safePow(1.0-saturate(avgB+0.3),2)*(0.2+smoothstep(1,0,safePow(colorBrightness,0.3))*0.8)*(fGIDarkMerging+smoothstep(1,0,colorBrightness)*fGIDarkMerging*2)*8
					)
					*safePow(result+safePow(colorBrightness,0.2)*(1.0-colorBrightness)*0.25,2.0)
					*(1.0-colorBrightness*colorBrightness)
					*fGIFinalMerging
					*gi
					*(1+giHSV.y*0.25);
				
				result = saturate(0.5+result-color);
            }

            
        } else if(iDebug==DEBUG_AO) {

			float4 passColor;
            if(iDebugPass==0) passColor =  getColorSampler(giPassSampler,coords);
            if(iDebugPass==1) passColor =  getColorSampler(giPass2Sampler,coords);
            if(iDebugPass==2) passColor =  getColorSampler(giSmoothPassSampler,coords);
            if(iDebugPass>=3) passColor =  getColorSampler(giAccuSampler,coords);

			float ao = passColor.a;
            
            
	            
            
            if(iDebugPass==4) {
            	float giBrightness = getBrightness(passColor.rgb);
            	
				float3 color = getColor(coords).rgb;
	            if(bRemoveAmbient) {
	                color = filterAmbiantLight(color);
	            }
	        	float colorBrightness = getBrightness(color);
	        
				ao = computeAo(ao,colorBrightness,giBrightness);
            }
        	result = ao;
			
        } else if(iDebug==DEBUG_SSR) {
        	float4 passColor;
            if(iDebugPass==0) passColor =  getColorSampler(ssrPassSampler,coords);
            if(iDebugPass==1) passColor =  getColorSampler(ssrPassSampler,coords);
            if(iDebugPass==2) passColor =  getColorSampler(ssrSmoothPassSampler,coords);
            if(iDebugPass>=3) passColor =  getColorSampler(ssrAccuSampler,coords);
        	
        	if(iDebugPass==4) {
        		float3 color = getColorSampler(resultSampler,coords).rgb;
        		float colorBrightness = getBrightness(color);
				passColor = computeSSR(coords,colorBrightness);
        	}
        	result = passColor.rgb;
            
        } else if(iDebug==DEBUG_ROUGHNESS) {
            float3 RTF = getColorSampler(RTFSampler,coords).xyz;
            
            result = RTF.x;
            //result = RTF.z;
        } else if(iDebug==DEBUG_DEPTH) {
            float depth = getDepth(coords);
            result = depth;
            
        } else if(iDebug==DEBUG_NORMAL) {
            result = getColorSampler(normalSampler,coords).rgb;
            
        } else if(iDebug==DEBUG_SKY) {
            float depth = getDepth(coords);
            result = depth>getSkyDepth()?1.0:0.0;
      
        } else if(iDebug==DEBUG_MOTION) {
            float2  motion = getPreviousCoords(coords);
            motion = 0.5+(motion-coords)*25;
            result = float3(motion,0.5);
            
        } else if(iDebug==DEBUG_AMBIENT) {

			if(coords.y>0.95) {
				if(coords.x<0.5) {
					result = getRemovedAmbiantColor();
				} else {
					result = getAverageBrightness();
				}
			} else {
				result = getColor(coords).rgb;
			}			
			
        } else if(iDebug==DEBUG_THICKNESS) {
            float4 drtf = getDRTF(coords);
            
            result = drtf.z*0.004;
      
        }
        
        outPixel = float4(result,1.0);
    }


// TEHCNIQUES 
    
    technique DH_UBER_RT <
        ui_label = "DH_UBER_RT 0.19.1";
        ui_tooltip = 
            "_____________ DH_UBER_RT _____________\n"
            "\n"
            " ver 0.19.1 (2024-11-14)  by AlucardDH\n"
#if DX9_MODE
            "         DX9 limited edition\n"
#endif
            "\n"
            "______________________________________";
    > {
#if!DX9_MODE
		pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_SavePreviousAmbientPass;
            RenderTarget = previousAmbientTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_AmbientPass;
            RenderTarget = ambientTex;
        }
#endif
      
        // Normal Roughness
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_RTFS_save;
            RenderTarget = previousRTFTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_RTFS;
            RenderTarget = RTFTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_NormalPass;
            RenderTarget = normalTex;
        }

        // GI
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_RayColorPass;
            RenderTarget = rayColorTex;
        }
#if SHPERE
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_Sphere_save;
            RenderTarget = previousSphereTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_SpherePass;
            RenderTarget = sphereTex;
            
            ClearRenderTargets = false;
                        
            BlendEnable = true;
            BlendOp = ADD;
            SrcBlend = SRCALPHA;
            SrcBlendAlpha = ONE;
            DestBlend = INVSRCALPHA;
            DestBlendAlpha = ONE;
        }
#endif
        
        
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_GILightPass;
            RenderTarget = giPassTex;
            RenderTarget1 = bestRayTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_GIFill;
            RenderTarget = bestRayFillTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_GILightPass2;
            RenderTarget = giPass2Tex;
            RenderTarget1 = previousBestRayTex;
        }
        
        // SSR
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_SSRLightPass;
            RenderTarget = ssrPassTex;
        }
        
        // Denoising
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_SmoothPass;
            RenderTarget = giSmoothPassTex;
            RenderTarget1 = ssrSmoothPassTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_AccuPass;
            RenderTarget = giAccuTex;
            RenderTarget1 = ssrAccuTex;
        }
        
        // Merging
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_UpdateResult;
            RenderTarget = resultTex;
            RenderTarget1 = giPreviousAccuTex;
            RenderTarget2 = ssrPreviousAccuTex;
#if !DX9_MODE
            RenderTarget3 = previousColorTex;
            RenderTarget4 = previousDepthTex;
#endif            
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_DisplayResult;
        }
    }
}