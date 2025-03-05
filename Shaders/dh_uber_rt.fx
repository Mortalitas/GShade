////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_UBER_RT 0.20.6 (2025-03-04)
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

#ifndef USE_MARTY_LAUNCHPAD_MOTION
 #define USE_MARTY_LAUNCHPAD_MOTION 0
#endif
#ifndef USE_VORT_MOTION
 #define USE_VORT_MOTION 0
#endif


#define HUD_SIZE 256


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
#define RESV_SCALE 1

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

#define RT_HIT_LIGHT 2.0
#define RT_HIT 1.0
#define RT_HIT_BEHIND 0.5
#define RT_HIT_GUESS 0.25
#define RT_HIT_SKY -0.5
#define RT_MISSED -1.0
#define RT_MISSED_FAST -2.0

#define PI 3.14159265359
#define SQRT2 1.41421356237

#define BUFFER_SIZE int2(BUFFER_WIDTH,BUFFER_HEIGHT)
#define BUFFER_SIZE3 int3(BUFFER_WIDTH,BUFFER_HEIGHT,RESHADE_DEPTH_LINEARIZATION_FAR_PLANE)


// MACROS /////////////////////////////////////////////////////////////////
// Don't touch this
#define getColor(c) saturate(tex2Dlod(ReShade::BackBuffer,float4((c).xy,0,0))*(bBaseAlternative?fBaseColor:1))
#define getColorSamplerLod(s,c,l) tex2Dlod(s,float4((c).xy,0,l))
#define getColorSampler(s,c) tex2Dlod(s,float4((c).xy,0,0))
#define maxOf3(a) max(max(a.x,a.y),a.z)
#define minOf3(a) min(min(a.x,a.y),a.z)
#define avgOf3(a) (((a).x+(a).y+(a).z)/3.0)
#define CENTER float2(0.5,0.5)
#define S_PR MagFilter=POINT;MinFilter=POINT;MipFilter= POINT;AddressU=REPEAT;AddressV=REPEAT;AddressW=REPEAT;
#define S_PC MagFilter=POINT;MinFilter=POINT;MipFilter= POINT;AddressU=Clamp;AddressV=Clamp;AddressW=Clamp;
#if DX9_MODE
	#define safePow(a,b) pow(a,b)
#endif

//////////////////////////////////////////////////////////////////////////////

#if USE_MARTY_LAUNCHPAD_MOTION
namespace Deferred {
    texture MotionVectorsTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
    sampler sMotionVectorsTex { Texture = MotionVectorsTex;  };
}
#elif USE_VORT_MOTION
    texture2D MotVectTexVort {  Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
    sampler2D sMotVectTexVort { Texture = MotVectTexVort; S_PC  };
#else
    texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
    sampler sTexMotionVectorsSampler { Texture = texMotionVectors; S_PC };
#endif


namespace DH_UBER_RT_0206 {

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
#endif

    texture previousDepthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG32F; MipLevels = 6;  };
    sampler previousDepthSampler { Texture = previousDepthTex; MinLOD = 0.0f; MaxLOD = 5.0f; };
    
    texture motionMaskTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
    sampler motionMaskSampler { Texture = motionMaskTex; };

    texture depthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R32F; MipLevels = 6;  };
    sampler depthSampler { Texture = depthTex; MinLOD = 0.0f; MaxLOD = 5.0f; };

    // Roughness Thickness
    texture previousRTFTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler previousRTFSampler { Texture = previousRTFTex; };
    texture RTFTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler RTFSampler { Texture = RTFTex; S_PR};
 
    texture bestRayTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
    sampler bestRaySampler { Texture = bestRayTex; S_PC };
    
    texture bestRayFillTex { Width = BUFFER_WIDTH/RESV_SCALE; Height = BUFFER_HEIGHT/RESV_SCALE; Format = RGBA16F; };
    sampler bestRayFillSampler { Texture = bestRayFillTex; S_PC};
   
#if SHPERE
    texture previousSphereTex { Width = BUFFER_WIDTH/SPHERE_RATIO; Height = BUFFER_HEIGHT/SPHERE_RATIO; Format = RGBA8; };
    sampler previousSphereSampler { Texture = previousSphereTex;};
    
    texture sphereTex { Width = BUFFER_WIDTH/SPHERE_RATIO; Height = BUFFER_HEIGHT/SPHERE_RATIO; Format = RGBA8; };
    sampler sphereSampler { Texture = sphereTex;};
#endif

    texture normalTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
    sampler normalSampler { Texture = normalTex; S_PC};

    texture resultTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler resultSampler { Texture = resultTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    // RTGI textures
    texture rayColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler rayColorSampler { Texture = rayColorTex; };
    
    texture giPassTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler giPassSampler { Texture = giPassTex; S_PR};

    texture giPass2Tex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler giPass2Sampler { Texture = giPass2Tex; MinLOD = 0.0f; MaxLOD = 5.0f; S_PR};

    texture giSmoothPassTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler giSmoothPassSampler { Texture = giSmoothPassTex; MinLOD = 0.0f; MaxLOD = 5.0f; };
    
    texture giSmooth2PassTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler giSmooth2PassSampler { Texture = giSmooth2PassTex; MinLOD = 0.0f; MaxLOD = 5.0f; };
    
    texture giAccuTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};
    sampler giAccuSampler { Texture = giAccuTex;};
    
    texture giPreviousAccuTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;  MipLevels = 6;};
    sampler giPreviousAccuSampler { Texture = giPreviousAccuTex; MinLOD = 0.0f; MaxLOD = 5.0f;};//S_PR

    texture reinhardTex { Width = 1; Height = 1; Format = RGBA16F; };
    sampler reinhardSampler { Texture = reinhardTex; };   
   
    // SSR texture
    texture ssrPassTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;  MipLevels = 6;  };
    sampler ssrPassSampler { Texture = ssrPassTex; MinLOD = 0.0f; MaxLOD = 5.0f;};//S_PR
          
    texture ssrAccuTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;  MipLevels = 6; };
    sampler ssrAccuSampler { Texture = ssrAccuTex; MinLOD = 0.0f; MaxLOD = 5.0f; };
    
    texture ssrPreviousAccuTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler ssrPreviousAccuSampler { Texture = ssrPreviousAccuTex;};
   
    
// Structs
    struct RTOUT {
        float3 wp;
        float status;
        float4 drtf;
        float dist;
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
    uniform bool bTest2 <ui_category="Test";> = true;
    uniform bool bTest3 <ui_category="Test";> = false;
    uniform bool bTest4 <ui_category="Test";> = false;
    uniform bool bTest5 <ui_category="Test";> = false;
    uniform bool bTest6 <ui_category="Test";> = false;
    uniform bool bTest7 <ui_category="Test";> = false;
    uniform bool bTest8 <ui_category="Test";> = false;
    uniform bool bTest9 <ui_category="Test";> = false;
    uniform bool bTest10 <ui_category="Test";> = false;
    uniform bool bTest11 <ui_category="Test";> = false;
    uniform bool bTest12 <ui_category="Test";> = false;
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

    uniform bool bSkyAt0 <
        ui_category = "Game specific hacks";
        ui_label = "Sky at Depth=0 (SWTOR)";
    > = false;
    
    uniform bool bDepthMulti5 <
        ui_category = "Game specific hacks";
        ui_label = "Depth multiplier=5 (Skyrim SE, Other DX9>11 games)";
    > = false;
    

    uniform float fSkyDepth <
        ui_type = "slider";
        ui_category = "Common";
        ui_label = "Sky Depth";
        ui_min = 0.00; ui_max = 1.00;
        ui_step = 0.001;
        ui_tooltip = "Define where the sky starts to prevent if to be affected by the shader";
    > = 0.999;
    
    uniform float fWeaponDepth <
        ui_type = "slider";
        ui_category = "Common";
        ui_label = "Weapon Depth";
        ui_min = 0.00; ui_max = 1.00;
        ui_step = 0.001;
        ui_tooltip = "Define where the weapon ends to prevent it to affect the SSR";
    > = 0.001;

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
    
    uniform int iRTPrecision <
        ui_type = "slider";
        ui_category = "Common";
        ui_label = "RT Precision";
        ui_min = 1; ui_max = 3;
        ui_step = 1;
        ui_tooltip = "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 1;
    
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

    uniform float fRemoveAmbientAutoAntiFlicker <
        ui_type = "slider";
        ui_category = "Remove ambient light";
        ui_label = "Compromise flicker/reactvity";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.5;
    
// GI

    uniform float fGIRenderScale <
        ui_category="GI/AO: 1st Pass (New rays)";
        ui_label = "GI Render scale";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.333;
    
#if !DX9_MODE
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
    > = 2;
#else
	#define iRTMaxRays 1
#endif

    uniform float fGIAvoidThin <
        ui_type = "slider";
        ui_category = "GI/AO: 1st Pass (New rays)";
        ui_label = "Avoid thin objects: max thickness";
        ui_tooltip = "Reduce detection of grass or fences";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.750;


    uniform int iHudBorderProtectionRadius <
        ui_type = "slider";
        ui_category = "GI/AO: 1st Pass (New rays)";
        ui_label = "Avoid HUD: Radius";
        ui_tooltip = "Reduce chances of detecting large lights from the HUD. Disable if you're using REST or if HUD is hidden";
        ui_min = 1; ui_max = 256;
        ui_step = 1;
    > = 180;
    
    uniform float fHudBorderProtectionStrength <
        ui_type = "slider";
        ui_category = "GI/AO: 1st Pass (New rays)";
        ui_label = "Avoid HUD: Strength";
        ui_tooltip = "Reduce chances of detecting large lights from the HUD. Disable if you're using REST or if HUD is hidden";
        ui_min = 0.0; ui_max = 16.0;
        ui_step = 0.01;
    > = 16;

        
#if !DX9_MODE    
    uniform int iMemRadius <
        ui_type = "slider";
        ui_category = "GI/AO: 2nd Pass (Resample)";
        ui_label = "Memory radius";
        ui_min = 0; ui_max = 3;
        ui_step = 1;
    > = 2;
#else
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
#if DX9_MODE
    > = 12;
#else
    > = 5;
#endif
    
    uniform int iSmoothRadius <
        ui_type = "slider";
        ui_category = "GI/AO: 3rd pass (Denoising)";
        ui_label = "Spatial: Radius";
        ui_min = 0; ui_max = 16;
        ui_step = 1;
        ui_tooltip = "Define the max distance of smoothing.\n";
    > = 8;
    
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
#if DX9_MODE
    > = 32;
#else
    > = 16;
#endif
    
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
    > = 10;
    
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
    > = 0.350;
    
    
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
    > = 0.1;
    
    uniform float fGIDarkAmplify <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Dark color compensation";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Brighten dark colors, useful in dark corners";
    > = 0.1;
    
    uniform float fGIBounce <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Bounce intensity";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Define if GI bounces in following frames";
    > = 0.34;

    uniform float fGIHueBiais <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Hue Biais";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much base color can take GI hue.";
    > = 0.5;
    
    uniform float fGILightMerging <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "In Light intensity";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much bright areas are affected by GI.";
    > = 0.10;
    uniform float fGIDarkMerging <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "In Dark intensity";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much dark areas are affected by GI.";
    > = 0.5;
    
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
    > = 0.2;
    
    uniform bool bRreinhardFinalMerging <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Reinhard Tonemap";
        ui_tooltip = "Improve details in dark and bright areas.";
    > = true;
    
    uniform float fRreinhardStrength <
        ui_type = "slider";
        ui_category = "GI: 4th Pass (Merging)";
        ui_label = "Reinhard Tonemap strength";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Improve details in dark and bright areas.";
    > = 0.5;
    
// AO

    uniform float fAOBoostFromGI <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "Boost from GI";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.5;
    
    uniform float fAOMultiplier <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "Multiplier";
        ui_min = 0.0; ui_max = 5;
        ui_step = 0.01;
        ui_tooltip = "Define the intensity of AO";
    > = 0.9;
    
    uniform int iAODistance <
        ui_type = "slider";
        ui_category = "AO: 4th Pass (Merging)";
        ui_label = "Distance";
        ui_min = 0; ui_max = BUFFER_WIDTH;
        ui_step = 1;
    > = BUFFER_WIDTH/6;
    
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
    
    uniform float fSSRRenderScale <
        ui_category="SSR";
        ui_label = "SSR Render scale";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.5;
    
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
#if DX9_MODE
    > = 12;
#else
    > = 10;
#endif
    
    uniform int iSSRCorrectionMode <
        ui_type = "combo";
        ui_category = "SSR";
        ui_label = "Geometry correction mode";
        ui_items = "No correction\0FOV\0";
        ui_tooltip = "Try modifying this value is the relfection seems wrong";
    > = 1;
    
    uniform float fSSRCorrectionStrength <
        ui_type = "slider";
        ui_category = "SSR";
        ui_label = "Geometry correction strength";
        ui_min = -1; ui_max = 1;
        ui_step = 0.001;
        ui_tooltip = "Try modifying this value is the relfection seems wrong";
    > = 0;
    
    uniform float fSSRMergingRoughness <
        ui_type = "slider";
        ui_category = "SSR";
        ui_label = "Roughness reflexivity";
        ui_min = 0.000; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Define how much the roughness decrease reflection intensity";
    > = 0.5;
    
    uniform float fSSRMergingOrientation <
        ui_type = "slider";
        ui_category = "SSR";
        ui_label = "Orientation reflexivity";
        ui_min = 0.000; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Higher value make the wall less reflective than the floor";
    > = 0.5;

    uniform float fSSRMerging <
        ui_type = "slider";
        ui_category = "SSR";
        ui_label = "SSR Intensity";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Define this intensity of the Screan Space Reflection.";
    > = 0.5;
    
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
#if !DX9_MODE
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
#endif

    
// FUCNTIONS

    bool isScaledProcessed(float2 coords) {
        return coords.x>=0 && coords.y>0 && coords.x<=fGIRenderScale && coords.y<=fGIRenderScale;
    }
    
    float2 upCoords(float2 coords) {
    	float2 result = coords/fGIRenderScale;
#if!DX9_MODE
    	int steps = ceil(1.0/fGIRenderScale);
    	int count = steps*steps;
    	int index = random%count;
    	int2 delta = int2(index/steps,index%steps)-steps/2;
    	result += delta*ReShade::PixelSize;
#endif
    	return result;
    }
    
    float2 upCoordsSSR(float2 coords) {
    	float2 result = coords/fSSRRenderScale;
#if!DX9_MODE
    	int steps = ceil(1.0/fSSRRenderScale);
    	int count = steps*steps;
    	int index = random%count;
    	int2 delta = int2(index/steps,index%steps)-steps/2;
    	result += delta*ReShade::PixelSize;
#endif
    	return result;
    }

#if!DX9_MODE
    float safePow(float value, float power) {
        return pow(abs(value),power);
    }
    
    float3 safePow(float3 value, float power) {
        return pow(abs(value),power);
    }
#endif
    
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

    float3 RGBtoOKL(float3 rgb) {

        // Step 1: Linearize RGB
        float3 r = rgb <= 0.04045 ? rgb / 12.92 : pow((rgb + 0.055) / 1.055, 2.4);

        // Step 2: Linear RGB to LMS
        r = mul(float3x3(
            0.4122214708, 0.5363325363, 0.0514459929,
            0.2119034982, 0.6806995451, 0.1073969566,
            0.0883024619, 0.2817188376, 0.6299787005
        ), r);

        // Step 3: Non-linear transformation (cube root)
        r = pow(r, 1.0 / 3.0);

        // Step 4: LMS to OKLab
        r = mul(float3x3(
            0.2104542553, 0.7936177850, -0.0040720468,
            1.9779984951, -2.4285922050, 0.4505937099,
            0.0259040371, 0.7827717662, -0.8086757660
        ), r);

        return r;
    }

    float3 OKLtoRGB(float3 oklab) {
        // Step 1: OKLab to LMS
        float3 r = mul(float3x3(
            1.0, 0.3963377774, 0.2158037573,
            1.0, -0.1055613458, -0.0638541728,
            1.0, -0.0894841775, -1.2914855480
        ), oklab);

        // Step 2: Reverse Non-linear transformation (cube)
        r = r * r * r;

        // Step 3: LMS to linear RGB
        r = mul(float3x3(
            4.0767416621, -3.3077115913, 0.2309699292,
            -1.2684380046, 2.6097574011, -0.3413193965,
            -0.0041960863, -0.7034186147, 1.7076147010
        ), r);

        // Step 4: De-linearize RGB
        r = r <= 0.0031308 ? r * 12.92 : 1.055 * pow(r, 1.0 / 2.4) - 0.055;

        return r;
    }


// Screen

    float getDepthMultiplier() {
        return bDepthMulti5 ? 5 : 1;
    }

    float getSkyDepth() {
        return fSkyDepth*getDepthMultiplier();
    }

    float isSky(float depth) {
        return bSkyAt0 ? depth==0 : depth>getSkyDepth();
    }

    float3 getNormal(float2 coords) {
        float3 normal = -(tex2Dlod(normalSampler,float4(coords,0,0)).xyz-0.5)*2;
        return normalize(normal);
    }

    float2 getDepth(float2 coords) {
        float2 d = ReShade::GetLinearizedDepth(coords);
        
        if(d.x<fWeaponDepth)  {
            d *= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE*0.005*getDepthMultiplier();
            d.y = 1;
        } else {
            d *= getDepthMultiplier();
            d.y = 0;
        }
        return d;
    }
    
    
    float4 getRTF(float2 coords) {
        return getColorSampler(RTFSampler,coords);
    }
    
    float4 getDRTF(float2 coords) {
        
        float4 drtf = getDepth(coords).x;
        drtf.yzw = getRTF(coords).xyz;
        if(fNormalRoughness>0 && !isSky(drtf.x)) {
            drtf.x += drtf.x*drtf.y*fNormalRoughness*0.05;
        }
        drtf.z = (0.01+drtf.z)*drtf.x*320;
        drtf.z *= (0.25+drtf.x);
        
        return drtf;
    }
    
    bool inScreen(float3 coords) {
        return coords.x>=0.0 && coords.x<=1.0
            && coords.y>=0.0 && coords.y<=1.0
            && coords.z>=0.0 && coords.z<=getDepthMultiplier();
    }
    
    bool inScreen(float2 coords) {
        return coords.x>=0.0 && coords.x<=1.0
            && coords.y>=0.0 && coords.y<=1.0;
    }
    
    float3 fovCorrectedBufferSize() {
        float3 result = BUFFER_SIZE3;
        if(iSSRCorrectionMode==1) result.xy *= 1.0+fSSRCorrectionStrength;
        return result;
    }
    
    float3 getWorldPositionForNormal(float2 coords,bool ignoreRoughness) {
        float depth = getDepth(coords).x;
        if(!ignoreRoughness && fNormalRoughness>0 && !isSky(depth)) {
            float roughness = getRTF(coords).x;
            if(bSmoothNormals) roughness *= 1.5;
            depth /= getDepthMultiplier();
            depth += depth*roughness*fNormalRoughness*0.05;
            depth *= getDepthMultiplier();
        }
        
        float3 result = float3((coords-0.5)*depth,depth);
        result *= fovCorrectedBufferSize();
        return result;
    }
    
    float3 getWorldPosition(float2 coords,float depth) {
        float3 result = float3((coords-0.5)*depth,depth);

        result *= fovCorrectedBufferSize();
        return result;
    }

    float3 getScreenPosition(float3 wp) {
        float3 result = wp/fovCorrectedBufferSize();
        result.xy /= result.z;
        return float3(result.xy+0.5,result.z);
    }
    




// Vector operations
    
    float2 nextRand(float2 rand) {
        return  frac(abs(rand+PI)*PI);
    }
    float3 nextRand(float3 rand) {
        return frac(abs(rand+PI)*PI);
    }

#if !TEX_NOISE
    int getPixelIndex(float2 coords,int2 size) {
        int2 pxCoords = coords*size;
        return pxCoords.x+pxCoords.y*size.x+random;
    }

    float randomValue(inout uint seed) {
        seed = seed * 747796405 + 2891336453;
        uint result = ((seed>>((seed>>28)+4))^seed)*277803737;
        result = (result>>22)^result;
        return result/4294967295.0;
    }
#endif

    float2 randomCouple(float2 coords) {
#if TEX_NOISE
/*
        int2 offset = int2((framecount*random*SQRT2),(framecount*random*PI))%512;
        float2 noiseCoords = ((offset+coords*BUFFER_SIZE)%512)/512;
        return abs((getColorSampler(blueNoiseSampler,noiseCoords).rg-0.5)*2.0);
        */
        return getColorSampler(blueNoiseSampler,coords).rg;
#else
        uint seed = getPixelIndex(coords,BUFFER_SIZE);

		float2 v = 0;
        v.x = randomValue(seed);
        v.y = randomValue(seed);
        return v;
#endif
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
#if TEX_NOISE
/*
        int2 offset = int2((framecount*random*SQRT2),(framecount*random*PI))%512;
        float2 noiseCoords = ((offset+coords*BUFFER_SIZE)%512)/512;
        return getColorSampler(blueNoiseSampler,noiseCoords).rgb;
        */
        return getColorSampler(blueNoiseSampler,coords).rgb;
#else
        uint seed = getPixelIndex(coords,BUFFER_SIZE);
        return randomTriple(coords,seed);
#endif
    }
    
    float4 getRayColor(float2 coords) {
        return getColorSampler(rayColorSampler,coords);
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
    
        if(isSky(refDepth)) {
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
        
        float2 orientation = normalize(randomCouple(coords)-0.5);
        
        bool validPos = true;
        bool validNeg = true;
        sky = 1.0;
        
        [loop]
        for(int d=1;d<=iThicknessRadius;d++) {
            float2 step = orientation*ReShade::PixelSize*d;
            
            if(validPos) {
                currentCoords = coords+step;
                depth = getDepth(currentCoords).x;
                if(isSky(depth)) {
                    sky = min(sky,float(d)/iThicknessRadius);
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
                depth = getDepth(currentCoords).x;
                if(isSky(depth)) {
                    sky = min(sky,float(d)/iThicknessRadius);
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
    
    void PS_MotionMask  (float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outMask : SV_Target0) {
        float2 previousCoords = getPreviousCoords(coords);

        float2 depth = getDepth(coords);
        float2 previousDepth = getColorSampler(previousDepthSampler,previousCoords).xy;
        float2 previousDepth2 = getColorSampler(previousDepthSampler,coords).xy;
        
        float mask = 0;
        if(depth.x>previousDepth.x+0.1*depth.x) mask = 1;
        if(depth.x>previousDepth2.x+0.1*depth.x) mask = 1;
        outMask = float4(mask,0,0,1);
    } 
    
    void PS_RTFS(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outRTFS : SV_Target0) {
        float depth = getDepth(coords).x;
        
        float2 previousCoords = getPreviousCoords(coords);
        
        float4 RTFS;
        RTFS.x = roughnessPass(coords,depth);
        RTFS.y = thicknessPass(coords,depth,RTFS.a);
        
        float4 previousRTFS = getColorSampler(previousRTFSampler,previousCoords);
        RTFS.y = lerp(previousRTFS.y,RTFS.y,0.33);
        RTFS.a = min(RTFS.a,0.1+previousRTFS.a);
        
        RTFS.z = 1;
        
        outRTFS = RTFS;
    }

#if!DX9_MODE    
    void PS_SavePreviousAmbientPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outAmbient : SV_Target0) {
        outAmbient = getColorSampler(ambientSampler,CENTER);
    }
    
    
    
    void PS_AmbientPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outAmbient : SV_Target0) {

        float4 previous = getColorSampler(previousAmbientSampler,CENTER);
        bool first = false;
        if(previous.a<=2.0/255.0) {
            previous = 1;
            first = true;
        }
        //previous.rgb += 1.0/255.0;
        float b = maxOf3(previous.rgb);
        
        
        float3 result = 1.0;
        float bestB = maxOf3(previous.rgb);
        
        float2 currentCoords = 0;
        float2 bestCoords = CENTER;
        
        float2 size = BUFFER_SIZE;
        float stepSize = BUFFER_WIDTH/16.0;
        float2 numSteps = size/(stepSize+1);
        
        float avgBrightness = 0;
        int count = 0;
            
        float2 rand = randomCouple(coords);
        [loop]
        for(int it=0;it<=4 && stepSize>=1;it++) {
            float2 stepDim = stepSize/BUFFER_SIZE;
        	[loop]
            for(currentCoords.x=bestCoords.x-stepDim.x*(numSteps.x/2);currentCoords.x<=bestCoords.x+stepDim.x*(numSteps.x/2);currentCoords.x+=stepDim.x) {
    			[loop]            
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
        outAmbient = lerp(previous,float4(result,avgBrightness),max(fRemoveAmbientAutoAntiFlicker,0.1)*3.0/60.0);
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
            float3 colorHSV = RGBtoHSV(color);
            float3 removed = getRemovedAmbiantColor();
            float3 removedHSV = RGBtoHSV(removed);
            float3 removedTint = removed - minOf3(removed); 
            float3 sourceTint = color - minOf3(color);
            
            float hueDist = maxOf3(abs(removedTint-sourceTint));
            
            float removal = saturate(1.0-hueDist*saturate(colorHSV.y+colorHSV.z));
            color -= removed*(1.0-hueDist)*fSourceAmbientIntensity*0.333*(1.0-colorHSV.z);
            color = saturate(color);
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


    float4 computeNormal(float3 wpCenter,float3 wpNorth,float3 wpEast) {
        return float4(normalize(cross(wpCenter - wpNorth, wpCenter - wpEast)),1.0);
    }
    
    float4 computeNormal(float2 coords,float3 offset,bool ignoreRoughness,bool reverse) {
        float3 posCenter = getWorldPositionForNormal(coords,ignoreRoughness);
        float3 posNorth  = getWorldPositionForNormal(coords - (reverse?-1:1)*offset.zy,ignoreRoughness);
        float3 posEast   = getWorldPositionForNormal(coords + (reverse?-1:1)*offset.xz,ignoreRoughness);
        
        float4 r = computeNormal(posCenter,posNorth,posEast);
        float mD = max(abs(posCenter.z-posNorth.z),abs(posCenter.z-posEast.z));
        if(mD>16) r.a = 0;
        return r;
    }


    void PS_NormalPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outNormal : SV_Target0, out float4 outDepth : SV_Target1) {
        
        float3 offset = float3(ReShade::PixelSize, 0.0);
        
        float4 normal = computeNormal(coords,offset,false,false);
        if(normal.a==0) {
            normal = computeNormal(coords,offset,false,true);
        }
        
        if(bSmoothNormals) {
            float3 offset2 = offset * 7.5*(1.0-getDepth(coords).x);
            float4 normalTop = computeNormal(coords-offset2.zy,offset,true,false);
            float4 normalBottom = computeNormal(coords+offset2.zy,offset,true,false);
            float4 normalLeft = computeNormal(coords-offset2.xz,offset,true,false);
            float4 normalRight = computeNormal(coords+offset2.xz,offset,true,false);
            
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
        outDepth = getDepth(coords);
        
    }
    
    
    float3 rampColor(float3 color) {    
        float3 okl = RGBtoOKL(color);
        float b = okl.x;
        float originalB = b;
        
        if(iGIRayColorMode==1) { // smoothstep
            b *= smoothstep(fGIRayColorMinBrightness,1.0,b);
        } else if(iGIRayColorMode==2) { // linear
            b *= saturate(b-fGIRayColorMinBrightness)/(1.0-fGIRayColorMinBrightness);
        } else if(iGIRayColorMode==3) { // gamma
            b *= safePow(saturate(b-fGIRayColorMinBrightness)/(1.0-fGIRayColorMinBrightness),2.2);
        }
        
        okl.x = originalB>0 ? okl.x * b / originalB : 0;
        return OKLtoRGB(okl);
    }
    
    void PS_RayColorPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0) {

        
        
        float hueLimit = 0.1;
    
        float2 previousCoords = getPreviousCoords(coords);
    
        float3 refColor = getColor(coords).rgb;
        if(fGIBounce>0.0) {
            refColor = lerp(refColor,getColorSampler(resultSampler,previousCoords).rgb,fGIBounce);
        }
        
        float depth = getDepth(coords).x;
        if(isSky(depth)) {
            outColor = float4(refColor*fSkyColor,1);
            return;
        }
        
        float3 refHSV = RGBtoHSV(refColor);
        
        int lod = 1;
        float3 tempHSV = refHSV;
        while((1.0-tempHSV.y)*tempHSV.z>0.7 && lod<=5) {
            tempHSV = RGBtoHSV(getColorSamplerLod(resultSampler,previousCoords,lod).rgb);
            
            //refHSV.z = 0.9;
            //refColor = HSVtoRGB(refHSV);
            
            lod ++;
        }
        refHSV.x = tempHSV.x;
        refHSV.yz = max(refHSV.yz,tempHSV.yz);
        refColor = HSVtoRGB(refHSV);
        
        
        if(bRemoveAmbient) {  
            refColor = filterAmbiantLight(refColor);
            refHSV = RGBtoHSV(refColor);
        }
        
        if(fSaturationBoost>0 && refHSV.z*refHSV.y>0.1) {
            refHSV.y = lerp(refHSV.y,saturate(refHSV.y+fSaturationBoost),refHSV.y);
            refColor = HSVtoRGB(refHSV);
        }
        
        if(fGIBounce>0.0) {
            float3 previousColor = getColorSampler(giAccuSampler,previousCoords).rgb;
            float b = getBrightness(refColor);
            refColor = saturate(refColor+previousColor*fGIBounce*(1.0-b)*(0.5+b));
        }
        
        float3 result = rampColor(refColor);        
          
        if(fGIDarkAmplify>0) {
            float3 okl = RGBtoOKL(result);
            float avgB = getAverageBrightness();
            okl.x = saturate(okl.x+fGIDarkAmplify*(1.0-okl.x));
            result = OKLtoRGB(okl);
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
        [loop]
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
    
    bool hit(float3 currentWp, float3 screenWp, float4 drtf,float3 behindWp) {
        if(fGIAvoidThin>0 && drtf.z<drtf.x*100*fGIAvoidThin) return false;
        if(currentWp.z>=screenWp.z) {
            if(currentWp.z<=behindWp.z+distance(screenWp,behindWp)*2.0) return true;
            if(currentWp.z<=screenWp.z+2*abs(behindWp.z-screenWp.z)) return true;
            if(currentWp.z<=screenWp.z+drtf.z*saturate(drtf.x*2)) return true;
        }
        return false;
    }

#if !DX9_MODE
    float3 getDebugLightWp() {
        return getWorldPosition(fDebugLightPosition.xy,bDebugLightZAtDepth ? getDepth(fDebugLightPosition.xy).x*0.99 : fDebugLightPosition.z);
    }
#endif
    
    RTOUT traceGI(inout float2 rand, float3 refWp,float3 incrementVector) {
    
        RTOUT result;
        result.status = RT_MISSED;
        
        float3 currentWp = refWp;
        
        incrementVector = normalize(incrementVector)*(0.05+abs(rand.x)*0.05);
                
        currentWp += incrementVector;
        float3 screenCoords = getScreenPosition(currentWp);
        result.drtf = getDRTF(screenCoords.xy);
        float3 screenWp = getWorldPosition(screenCoords.xy,result.drtf.x);
        
        
        if(hit(currentWp, screenWp, result.drtf,0)) {
            result.wp = screenWp;
            result.status = RT_MISSED_FAST;              
            return result;
        }
        
        
        
        float3 refVector = normalize(incrementVector);
        incrementVector = refVector;
        
        int stepBehind = 0;
        bool behind = false;
        float3 behindWp = 0;
        float3 previousScreenWp = refWp;
 
        int step = -1;
        incrementVector *= 0.1;
        
        float maxDist = sqrt(BUFFER_WIDTH*BUFFER_WIDTH+BUFFER_HEIGHT*BUFFER_HEIGHT);
        int maxSteps = 16*(iRTPrecision>1?32:1);

        result.dist = 0;
        
        while(step<maxSteps*2 && result.dist<maxDist) {
            step++;
            if(step>maxSteps) incrementVector *= 1.05;

            result.dist += length(incrementVector);
            currentWp += incrementVector;
            screenCoords = getScreenPosition(currentWp);
            
            if(!inScreen(screenCoords)) break;
            
            result.drtf = getDRTF(screenCoords.xy);
            screenWp = getWorldPosition(screenCoords.xy,result.drtf.x);
            bool previousBehind = behind;
            behind = currentWp.z>screenWp.z;
            
            if(behind) {
                stepBehind++;
                if(stepBehind==1) {
                    behindWp = screenWp;
                }
            }
            
            if(isSky(result.drtf.x)) {
                result.status = RT_HIT_SKY;
                result.wp = currentWp;
            }
            
            bool isHit = hit(currentWp, screenWp, result.drtf,behindWp);
            
            if(isHit) {
                bool isHitBehind = stepBehind>1 || (currentWp.z>=screenWp.z+50 && result.drtf.z>=50);
        		result.status = isHitBehind ? RT_HIT_BEHIND :  RT_HIT;
                result.wp = result.status==RT_HIT_BEHIND ? behindWp : currentWp;
                return result;
            }
            
#if !DX9_MODE
            if(iRTPrecision==1) {
                rand = nextRand(rand);
                float l = 1.00+result.drtf.x+rand.y;
                incrementVector *= l;
            } else 
#endif
			if(step<=maxSteps) {
                float2 nextWp = float2(
                    refVector.x>0 ? ceil(currentWp.x+1) : floor(currentWp.x-1),
                    refVector.y>0 ? ceil(currentWp.y+1) : floor(currentWp.y-1)
                );
                
                float2 dist = abs(nextWp.xy-currentWp.xy);
                
                // On prend la plus petite distance positive
                float minDist = min(dist.x, dist.y);
                incrementVector = refVector*max(iRTPrecision<3?pow(float(step)/maxSteps,2)*1000:0,minDist*(1.0+result.drtf.x*2.5));
            }
            
            
            if(!behind) {
                stepBehind = 0;
            }

            previousScreenWp = screenWp;
            //dist = distance(refWp,currentWp);
        }
        
        return result;
    }
    
	RTOUT traceGItarget(inout float2 rand, float3 refWp,float3 incrementVector,float3 targetWp) {
    
        RTOUT result;
        result.status = RT_MISSED;
        
        float3 currentWp = refWp;
        
        incrementVector = normalize(incrementVector)*(0.05+abs(rand.x)*0.05);
                
        currentWp += incrementVector;
        float3 screenCoords = getScreenPosition(currentWp);
        result.drtf = getDRTF(screenCoords.xy);
        float3 screenWp = getWorldPosition(screenCoords.xy,result.drtf.x);
        
        
        if(hit(currentWp, screenWp, result.drtf,0)) {
            result.wp = screenWp;
            result.status = RT_MISSED_FAST;              
            return result;
        }
        
        
        
        float3 refVector = normalize(incrementVector);
        incrementVector = refVector;
        
        int stepBehind = 0;
        bool behind = false;
        float3 behindWp = 0;
        float3 previousScreenWp = refWp;
 
        int step = -1;
        incrementVector *= 0.1;
        
        float maxDist = distance(currentWp,targetWp);
        int maxSteps = 16*(iRTPrecision>1?32:1);

        result.dist = 0;
        
        while(step<maxSteps*2 && result.dist<maxDist) {
            step++;
            if(step>maxSteps) incrementVector *= 1.05;

            result.dist += length(incrementVector);
            currentWp += incrementVector;
            screenCoords = getScreenPosition(currentWp);
            
            if(!inScreen(screenCoords)) break;
            
            result.drtf = getDRTF(screenCoords.xy);
            screenWp = getWorldPosition(screenCoords.xy,result.drtf.x);
            bool previousBehind = behind;
            behind = currentWp.z>screenWp.z;
            
            if(behind) {
                stepBehind++;
                if(stepBehind==1) {
                    behindWp = screenWp;
                }
            }
            
            if(isSky(result.drtf.x)) {
                result.status = RT_HIT_SKY;
                result.wp = currentWp;
            }
            
            bool isHit = hit(currentWp, screenWp, result.drtf,behindWp);
            
            if(isHit) {
                bool isHitBehind = stepBehind>1 || (currentWp.z>=screenWp.z+50 && result.drtf.z>=50);
        		result.status = isHitBehind ? RT_HIT_BEHIND : (result.dist>=maxDist-2 ? RT_HIT_LIGHT : RT_HIT);
                result.wp = result.status==RT_HIT_BEHIND ? behindWp : currentWp;
                return result;
            }
            
#if !DX9_MODE
            if(iRTPrecision==1) {
                rand = nextRand(rand);
                float l = 1.00+result.drtf.x+rand.y;
                incrementVector *= l;
            } else 
#endif
			if(step<=maxSteps) {
                float2 nextWp = float2(
                    refVector.x>0 ? ceil(currentWp.x+1) : floor(currentWp.x-1),
                    refVector.y>0 ? ceil(currentWp.y+1) : floor(currentWp.y-1)
                );
                
                float2 dist = abs(nextWp.xy-currentWp.xy);
                
                // On prend la plus petite distance positive
                float minDist = min(dist.x, dist.y);
                incrementVector = refVector*max(iRTPrecision<3?pow(float(step)/maxSteps,2)*1000:0,minDist*(1.0+result.drtf.x*2.5));
            }
            
            
            if(!behind) {
                stepBehind = 0;
            }

            previousScreenWp = screenWp;
            //dist = distance(refWp,currentWp);
        }

        result.status = RT_HIT_LIGHT;
        result.wp = targetWp;
        
        return result;
    }

// GI

	float weightLight(float3 color) {
#if !DX9_MODE
		float3 hsv = RGBtoHSV(color);
		return (1+hsv.y)*hsv.z*0.5;
#else
		return maxOf3(color);
#endif
	}
    
    void handleHit(
        in bool doTargetLight, in float3 targetColor, in RTOUT hitPosition, 
        inout float3 sky, inout float4 bestRay, inout float sumAO, inout int hits, inout float3 mergedGiColor,
        inout float missRays
    ) {
    	if(hitPosition.status <= RT_MISSED) {
    		return;
    	}
    	
        float3 screenCoords = getScreenPosition(hitPosition.wp);
        
    	if(!inScreen(screenCoords.xy)) {
    		return;
    	}
        
        
        if(hitPosition.status==RT_HIT_SKY || isSky(screenCoords.z)) {
            float3 giColor = doTargetLight ? targetColor.rgb : getRayColor(screenCoords.xy).rgb;
            float b = getBrightness(giColor);
            sky = max(sky,giColor.rgb);
            
            hits++;
            sumAO+=1;
            
            return;
        }
        
        
        float4 DRTF = getDRTF(screenCoords.xy);  
        if((hitPosition.dist>0 || doTargetLight) && (fGIAvoidThin==0 || DRTF.z>DRTF.x*100*fGIAvoidThin)) {
            float ao = 2.0*hitPosition.dist/(iAODistance*screenCoords.z*getDepthMultiplier());
            sumAO += saturate(ao);
            hits+=1.0;
        }
        
        if(hitPosition.status==RT_HIT_BEHIND) {

            if(doTargetLight) {
                float3 giColor = getRayColor(screenCoords.xy).rgb;
                
                float hitB = getBrightness(giColor.rgb);
                float targetB = getBrightness(targetColor.rgb);
                if(hitB<targetB && targetB>0.3) {
                    missRays += targetB*2;
                }
                hitB = weightLight(giColor.rgb);
                if(hitB>bestRay.a) {
                    bestRay = float4(screenCoords,hitB);
                } 
                giColor = 0;
            }
            return;
            
        } 
        
        
        float3 giColor;
        if(doTargetLight) {
            if(hitPosition.status==RT_HIT_LIGHT) {
                giColor = targetColor.rgb;
                
            }
#if !DX9_MODE
			 else if(!bDebugLight || !bDebugLightOnly) {
#else
			 else {
#endif
                giColor = getRayColor(screenCoords.xy).rgb;
                
                float hitB = getBrightness(giColor.rgb);
                float targetB = getBrightness(targetColor.rgb);
                if(hitB<targetB && targetB>0.3) {
                    missRays += targetB*2;
                }
                hitB = weightLight(giColor.rgb);
	            if(hitB>bestRay.a) {
	                bestRay = float4(screenCoords,hitB);
	            } 
            }
        } else {
            giColor = getRayColor(screenCoords.xy).rgb;
        }
        float b = weightLight(giColor.rgb);
        if(b>=bestRay.a && !doTargetLight) {
            bestRay = float4(screenCoords,b);
        }
        
        
        if(doTargetLight) {
#if !DX9_MODE
            giColor.rgb = RGBtoOKL(giColor.rgb);
            giColor.x /= max(1.0,pow(fGIDistanceAttenuation,8.0)*30*hitPosition.dist);
            giColor.rgb = OKLtoRGB(giColor.rgb);
#else
            giColor.rgb /= max(1.0,pow(fGIDistanceAttenuation,8.0)*30*hitPosition.dist);
#endif
        }
        
        mergedGiColor.rgb = max(mergedGiColor.rgb,giColor.rgb);
    
    }

    void PS_GILightPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0, out float4 outBestRay : SV_Target1) {
        
        if(!isScaledProcessed(coords)) {
            outGI = float4(0,0,0,1);
            outBestRay = float4(0,0,0,1);
            return;            
        }
        
        coords = upCoords(coords);
        
        float depth = getDepth(coords).x;
        if(isSky(depth)) {
            outGI = float4(0,0,0,1);
            outBestRay = float4(coords,depth,fSkyColor);
            return;
        }
        
        
        float3 refWp = getWorldPosition(coords,depth);
        float3 refNormal = getNormal(coords);
        
        float4 bestRay = 0;

        float3 sky = 0.0;
        float3 mergedGiColor = 0.0;     
        
        float sumAO = 0;
        float hits = 0;
        float missRays = 0;
        
#if TEX_NOISE
        float3 rand = randomTriple(coords+0.05*framecount);
#else
        uint seed = getPixelIndex(coords,BUFFER_SIZE);
        float3 rand = randomTriple(coords,seed);
#endif

        
        
#if !DX9_MODE
        if(bDebugLight) {
            float3 targetWp = getDebugLightWp() + rand*iDebugLightSize*0.9;
            float3 lightVector = normalize(targetWp-refWp);
            float3 targetColor = fDebugLightColor;

            RTOUT hitPosition = traceGItarget(rand.xy,refWp,lightVector,targetWp);
            if(hitPosition.status!=RT_MISSED_FAST) {
	            handleHit(
	                true, targetColor,hitPosition, 
	                sky, bestRay, sumAO, hits, mergedGiColor,
	                missRays
	            );
            }
            
            if(bDebugLightOnly) {
            	outBestRay = bestRay;
        		outGI = float4(max(mergedGiColor,sky),hits>0 ? saturate(sumAO/hits) : 1.0);
        		return;
            }
        }
#endif
        
#if !DX9_MODE
        int maxRays = iRTMaxRays;
        
        [loop]
        for(int rays=0;rays<maxRays;rays++) {
#endif
            rand = nextRand(rand);
            rand = normalize(rand-0.5);

            float3 lightVector = rand;
            lightVector += cross(rand,refNormal);
            lightVector += refNormal;
			
            RTOUT hitPosition = traceGI(rand.xy,refWp,lightVector);
#if !DX9_MODE
            if(hitPosition.status==RT_MISSED_FAST) {
                continue;
            }
#endif
            
            handleHit(
                false, 0,hitPosition, 
                sky, bestRay, sumAO, hits, mergedGiColor,
                missRays
            );
#if !DX9_MODE
        }
#endif
        
        outBestRay = bestRay;
        outGI = float4(max(mergedGiColor,sky),hits>0 ? saturate(sumAO/hits) : 1.0);
    }
    
    
    float getBorderProximity(float2 coords) {
        float2 borderDists = min(coords,1.0-coords)*BUFFER_SIZE;
        float borderDist = min(borderDists.x,borderDists.y);
        return borderDist<=iHudBorderProtectionRadius ? float(iHudBorderProtectionRadius-borderDist)/iHudBorderProtectionRadius : 0;
    }
    
    
    void PS_GIFill(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outBestRay : SV_Target) {

        if(!isScaledProcessed(coords)) {
            outBestRay = float4(0,0,0,1);
            return;            
        }

        float2 pixelSize = ReShade::PixelSize;
        float4 bestRay = getColorSampler(bestRaySampler,coords);
        
#if TEX_NOISE
        float3 rand = randomTriple(coords+0.05*framecount);
#else
        uint seed = getPixelIndex(coords,BUFFER_SIZE);
        float3 rand = randomTriple(coords,seed);
#endif

        int2 delta;         
        int2 res = floor(BUFFER_SIZE/RESV_SCALE);
        int maxDist = 4;
        [loop]
        for(delta.x=-maxDist;delta.x<=maxDist;delta.x+=1) {
        	[loop]
            for(delta.y=-maxDist;delta.y<=maxDist;delta.y+=1) {
                float d = length(delta);
                if(d>maxDist) continue;
                
                float2 currentCoords = coords + delta*pixelSize*d;
                rand = nextRand(rand);
                currentCoords += (rand.xy-0.5)*0.1*fGIRenderScale*d;
                if(!isScaledProcessed(currentCoords)) continue;
                
                float4 ray = getColorSampler(bestRaySampler,currentCoords);                 
                if(ray.a>=bestRay.a) {
                    bestRay = ray;
                }
            }
        }

        outBestRay = bestRay;
        
    }
    
    void PS_GILightPass2(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0) {

        if(!isScaledProcessed(coords)) {
            outGI = float4(0,0,0,1);
            return;            
        }
        coords = upCoords(coords);

        float depth = getDepth(coords).x;
        if(isSky(depth)) {
            outGI = float4(0,0,0,1);
            return;
        }
        

                
        float3 refWp = getWorldPosition(coords,depth);
        float3 refNormal = getNormal(coords);
        
        float3 mergedGiColor = 0;
        
        float hits = 0;
        float sumAO = 0;
        
        float3 sky = 0.0;
        float4 bestRay;
        
        float missRays = 0;
                                  
        
#if TEX_NOISE
        float3 rand = randomTriple(coords+0.05*framecount);
#else
        uint seed = getPixelIndex(coords,BUFFER_SIZE);
        float3 rand = randomTriple(coords,seed);
#endif
        float2 pixelSize = ReShade::PixelSize;
        
#if !DX9_MODE
        if(!(bDebugLight && bDebugLightOnly)) {
#endif
	            
            bestRay = getColorSampler(bestRayFillSampler,coords*fGIRenderScale);
            bestRay.a = 0;
            
            float3 targetCoords = bestRay.xyz;
            
            targetCoords.xy +=  2*pixelSize*rand.yz;
            targetCoords.z = getDepth(targetCoords.xy).x;
            
            
            targetCoords.z = getDepth(targetCoords.xy).x;
            
            float3 targetWp = getWorldPosition(targetCoords.xy,targetCoords.z);
            targetWp += rand*8*fHudBorderProtectionStrength*getBorderProximity(targetCoords.xy);
            float3 lightVector = normalize(targetWp-refWp);
            
            float d = dot(refNormal,lightVector);
            if(d>0) {
                RTOUT hitPosition = traceGItarget(rand.xy,refWp,lightVector,targetWp);
	            if(hitPosition.status!=RT_MISSED_FAST) {
		            float3 targetColor = getRayColor(targetCoords.xy).rgb;
	            	handleHit(
		                true, targetColor, hitPosition, 
		                sky, bestRay, sumAO, hits, mergedGiColor,
		                missRays
		            );
	            }
            } else {
            	hits++;
            }
                
            
#if !DX9_MODE

            float2 step = 1.0/(1+iMemRadius);
            step.y *= float(BUFFER_WIDTH)/BUFFER_HEIGHT;
            
            float2 searchCoords = 0;
            
            float currentIndex = 0;
            
            [loop]
            for(searchCoords.y=step.y*0.5;searchCoords.y<=1.0-step.y*0.5;searchCoords.y+=step.y) {
    			[loop]            
				for(searchCoords.x=step.x*0.5;searchCoords.x<=1.0-step.x*0.5;searchCoords.x+=step.x) {

        			rand = nextRand(rand);

                    float2 currentCoords = searchCoords+step*rand.xy;
                    
                    if(!inScreen(currentCoords)) continue;
                    
                    currentCoords = getColorSampler(bestRayFillSampler,currentCoords*fGIRenderScale).xy;
    
                    float3 targetCoords = float3(currentCoords,getDepth(currentCoords).x);
                    
                    float3 targetWp = getWorldPosition(targetCoords.xy,targetCoords.z);
                    
                    float3 lightVector = normalize(targetWp-refWp);
                    
                    {
                        float d = dot(refNormal,lightVector);
                        if(d<0) {
                            hits++;
                            continue;
                        }
                        float3 targetNormal = getNormal(targetCoords.xy);
	                    if(!isSky(targetCoords.z) && length(targetNormal+lightVector)>1.4) {
	                        continue;
	                    }
                    }
                    
                    RTOUT hitPosition = traceGItarget(rand.xy,refWp,lightVector,targetWp);
                    if(hitPosition.status!=RT_MISSED_FAST) {
	                    float3 targetColor = getRayColor(targetCoords.xy).rgb;
	                    
	                    handleHit(
	                        true, targetColor, hitPosition, 
	                        sky, bestRay, sumAO, hits, mergedGiColor,
	                        missRays
	                    );
                    }
                    
                    
                    
                }
                
                
            }

        }
#endif
        
        
        float4 firstPassFrame = getColorSampler(giPassSampler,coords*fGIRenderScale);
        mergedGiColor.rgb = max(mergedGiColor.rgb,firstPassFrame.rgb);
        float firstAO = firstPassFrame.a;
                
        sumAO += firstAO*iRTMaxRays;
        hits += iRTMaxRays;
        float ao = hits>0 ? sumAO/hits : 1;
        
            
        if(missRays>0) {
            ao /= missRays;
        }
        
        mergedGiColor.rgb = max(mergedGiColor.rgb,sky);
        
        float3 fpOKL = RGBtoOKL(firstPassFrame.rgb);
        float r = 1.0-smoothstep(0,1,fpOKL.x);
        mergedGiColor.rgb = saturate(mergedGiColor.rgb*r+firstPassFrame.rgb);
        
        
        outGI = float4(mergedGiColor.rgb,ao);
        
        
    }

// SSR
    float3 computeSSR(float2 coords,float brightness) {
        float4 ssr = getColorSamplerLod(ssrAccuSampler,coords,1);
        
        float roughness = getRTF(coords).x;
        
        float rCoef = lerp(1.0,saturate(1.0-roughness*10),fSSRMergingRoughness);

        float coef = fSSRMerging*(1.0-brightness)*rCoef;

        if(fSSRMergingOrientation>0) {
            float3 normal = getNormal(coords);
            float3 preferedOrientation = normalize(float3(0,-1,-0.5));
            float oCoef = saturate(dot(normal,preferedOrientation));
            coef *= (1.0-fSSRMergingOrientation)+lerp(1,oCoef,fSSRMergingOrientation)*fSSRMergingOrientation;
        }

        return ssr.rgb*coef;
            
    }

	RTOUT traceSSR(inout float2 rand, float3 refWp,float3 incrementVector) {
    
        RTOUT result;
        result.status = RT_MISSED;
        
        float3 currentWp = refWp;
        
        incrementVector = normalize(incrementVector)*0.1;
                
        currentWp += incrementVector;
        float3 screenCoords = getScreenPosition(currentWp);
        
        result.drtf = getDRTF(screenCoords.xy);
        float3 screenWp = getWorldPosition(screenCoords.xy,result.drtf.x);
        
        bool isHit = hit(currentWp, screenWp, result.drtf,0);
        
        if(isHit) {
            float3 hitNormal = getNormal(screenCoords.xy);
            incrementVector = reflect(incrementVector,hitNormal);
            isHit = false;
        }        
        
        float3 refVector = normalize(incrementVector);
        incrementVector = refVector;
        
        int stepBehind = 0;
        bool behind = false;
        float3 behindWp = 0;
#if !DX9_MODE
        float3 beforeBehind = 0;
        float3 previousWp = refWp;
#endif
 
        int step = -1;
        incrementVector *= 0.1;
        
        float maxDist = sqrt(BUFFER_WIDTH*BUFFER_WIDTH+BUFFER_HEIGHT*BUFFER_HEIGHT);
        int maxSteps = 256;

        float dist = 0;
        
        while(step<maxSteps*2 && dist<maxDist) {
            step++;
            if(step>maxSteps) incrementVector *= 1.05;

            dist += length(incrementVector);
            currentWp += incrementVector;
            screenCoords = getScreenPosition(currentWp);
            
            if(!inScreen(screenCoords)) break;
            
            
            result.drtf = getDRTF(screenCoords.xy);
            screenWp = getWorldPosition(screenCoords.xy,result.drtf.x);
            behind = currentWp.z>screenWp.z;
            
            if(behind) {
                stepBehind++;
                if(stepBehind==1) {
                    behindWp = screenWp;
#if !DX9_MODE
                    beforeBehind = previousWp;
#endif
                }
            }
            
            if(isSky(result.drtf.x)) {
                result.status = RT_HIT_SKY;
                result.wp = currentWp;
            }
            
            isHit = hit(currentWp, screenWp, result.drtf,behindWp);
            bool isHitBehind = isHit && (stepBehind>1 || (currentWp.z>=screenWp.z+50 && result.drtf.z>=50));
        
            if(isHit) {
                result.status = isHitBehind ? RT_HIT_BEHIND : RT_HIT;
#if !DX9_MODE
                result.wp = result.status==RT_HIT_BEHIND ? beforeBehind : currentWp;
#else
				result.wp = result.status==RT_HIT_BEHIND ? behindWp : currentWp;
#endif
                if(result.drtf.y>=0.1) result.status = RT_HIT;
                return result;
            }
            
#if !DX9_MODE
            if(iRTPrecision==1) {
                rand = nextRand(rand);
                if(step<=maxSteps) {
                    incrementVector = refVector*(1.0+rand.x);
                }
            } else 
#endif
			if(step<=maxSteps) {
                float2 nextWp = float2(
                    refVector.x>0 ? ceil(currentWp.x+1) : floor(currentWp.x-1),
                    refVector.y>0 ? ceil(currentWp.y+1) : floor(currentWp.y-1)
                );
                
                float2 dist = abs(nextWp.xy-currentWp.xy);
                
                // On prend la plus petite distance positive
                float minDist = min(dist.x, dist.y);
                incrementVector = refVector*max(0.01,minDist*(1.0+result.drtf.x*2.5));
            }
            
            
            if(!behind) {
                stepBehind = 0;
            }
            
#if !DX9_MODE
            previousWp = currentWp;
#endif
        }

        if(incrementVector.z>0 && inScreen(getScreenPosition(currentWp).xy)) {
            result.status = RT_HIT;
            result.wp = currentWp;
        }
        
        return result;
    }

    void PS_SSRLightPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0) {
        if(!bSSR || fSSRMerging==0.0) {
            outColor = 0.0;
            return;
        }
        
        if(coords.x>fSSRRenderScale || coords.y>fSSRRenderScale) {
            outColor = float4(0,0,0,1);
            return;
        }
        
        
        coords = upCoordsSSR(coords);
        
        int subWidth = min(4,ceil(1.0/fSSRRenderScale));
        int subMax = subWidth*subWidth;
        int subCoordsIndex = framecount%subMax;
        int2 delta = 0;
            
        float2 depth = getDepth(coords);
        
        if(isSky(depth.x)) {
            outColor = 0.0;
        } else {
        
            float4 result = 0;
                
            float3 targetWp = getWorldPosition(coords,depth.x); 
            float3 targetNormal = getNormal(coords);
                           
            float3 lightVector = normalize(reflect(targetWp,targetNormal));
            
            float2 rand = (coords*PI)%1;
            RTOUT hitPosition = traceSSR(rand,targetWp,lightVector);
            
            float3 screenPosition = getScreenPosition(hitPosition.wp.xyz);
                
            if(hitPosition.status>RT_HIT_BEHIND) {
                float2 previousCoords = getPreviousCoords(screenPosition.xy);
                float3 hitNormal = getNormal(screenPosition.xy);
                if(distance(hitNormal,targetNormal)>=0.2) {
                	result = float4(getColorSampler(resultSampler,previousCoords).rgb,1);
                }
            }

            outColor = result;
        }
        
            
    }
    
/////////////////////////////////
    
    // Helper functions
    float gaussian(float x, float sigma) {
        return exp(-(x * x) / (2.0 * sigma * sigma));
    }
    
    float calculateDepthWeight(float centerDepth, float sampleDepth, float sigma) {
        float diff = abs(centerDepth - sampleDepth);
        return gaussian(diff, sigma);
    }
    
    
///////////////////////////////////

	void smoothWeight(
		float dist,
		float2 refDepth, float motionMask, float3 refNormal, float4 refColor, float avgB, 
		sampler sourceGISampler,float2 currentCoords,float2 currentScaledCoords,
		inout int maxSamples, inout float2 weightSum, inout float4 giAo, inout float3 previousResultGI,
		bool firstPass
	) {
        float2 depth = getDepth(currentScaledCoords);
        if(isSky(depth.x)) {
#if DX9_MODE
            return;
#else
            depth = getColorSampler(previousDepthSampler,currentScaledCoords).x;
            if(isSky(depth.x)) {
                return;
            }
#endif
        }
        
        if(depth.y != refDepth.y) {
            return;
        }
	
	
		float2 weight = 1.0;
            
        float nw = 0;

		float d;
        // Normal weight
        if(motionMask<1) {
            float3 normal = getNormal(currentScaledCoords);
			d = dot(normal,refNormal);
            nw = saturate(d);
            nw = pow(nw,3.0/fGIRenderScale);
            weight.x *= nw;
	        weight.y *= saturate(d);
        } else {
        	nw = 1;
        }
        
        // Depth weight
        if(motionMask<1) {
            float diffDepth = abs(depth.x - refDepth.x);
            weight *= max(0.001,1.0-100*diffDepth*saturate(1.0-refDepth*2.0));
        }
        
        
        if(weight.x>0) {
            float4 curGiAo = getColorSampler(sourceGISampler,currentCoords);
            
            {
            	float diffC = maxOf3(abs(curGiAo.rgb-refColor.rgb));
            	weight.x *= 1.01-diffC;
            }
            
            
            curGiAo.rgb = RGBtoOKL(curGiAo.rgb);
            
            
            weight.x *= avgB+pow(curGiAo.x*2,2);
            
            giAo.rgb += curGiAo.rgb*weight.x;
            giAo.a += curGiAo.a*weight.y;    
        }
        
        weightSum += weight;
        
        float3 result = giAo.rgb/weightSum.x;
        if(abs(result.x-previousResultGI.x)>0.05) {
            maxSamples = min(maxSamples+1,iSmoothSamples*2);
        }
        previousResultGI = result;
	
	}
	
	void smoothAccu(
		float motionMask, float2 refDepth, float3 refWp,
		inout float4 giAo, inout float2 weightSum,
		float2 previousCoords, float4 previousAccu,
		bool firstPass
	) {
		if(!firstPass && motionMask<1) {
            float2 depth = getColorSampler(previousDepthSampler,previousCoords).xy;            
            float4 curGiAo = previousAccu;
            curGiAo.rgb = RGBtoOKL(curGiAo.rgb);
            curGiAo.x *= 0.95;
                
            // Distance weight
            float2 weight = 1.0;
            
            {
                float diffDepth = abs(depth.x - refDepth.x);
                weight *= max(0.001,1.0-100*diffDepth*saturate(1.0-refDepth*2.0));
            }
            
            if(depth.y != refDepth.y) {
                weight = 0;
            }
                
            if(weight.x>0) {
                weight.x *= pow(curGiAo.x,0.25);
                weight.x *= iGIFrameAccu*0.5;
                
                

                float3 wp = getWorldPosition(previousCoords,depth.x);
                float d = distance(refWp,wp);
                if(d>iAODistance*0.5) weight.y = 0;
                


            	float diffL = abs(curGiAo.x-(giAo.rgb/ weightSum.x).x);
            	weight.x *= (1.0-diffL);
            
                
                giAo.rgb += curGiAo.rgb*weight.x;
                giAo.a += curGiAo.a*weight.y;
                
                
            }
            
            weightSum += weight;
            
            giAo.rgb /= weightSum.x;
            giAo.rgb = OKLtoRGB(giAo.rgb);
        
        } else if(weightSum.x>0) {
            giAo.rgb /= weightSum.x;            
            giAo.rgb = OKLtoRGB(giAo.rgb);
        } else {
        	giAo.rgb = 0;
        }
        
        if(weightSum.y>0) {
            giAo.a /= weightSum.y;
            giAo.a = lerp(giAo.a,previousAccu.a,0.5);
        } else {
            giAo.a = 1.0;
        }
	
	}
	
    void smoothPass1(
        sampler sourceGISampler,
        float2 coords, out float4 outGI
    ) {
    
		if(!isScaledProcessed(coords)) {
            outGI = float4(0,0,0,1);
            return;            
        }
        
        float2 scaledCoords = upCoords(coords);    
        
        float2 refDepth = getDepth(scaledCoords);
        //float2 previousPassDepth = getDepth(previousPassUpCoords);
        
        if(isSky(refDepth.x)) {
            outGI = float4(getColor(scaledCoords).rgb,1);
            return;
        }
        
        float2 previousCoords = getPreviousCoords(scaledCoords);
        float4 previousAccu = getColorSampler(giPreviousAccuSampler,previousCoords);

        float3 refNormal = getNormal(scaledCoords);  
        float3 refWp = getWorldPosition(scaledCoords,refDepth.x);        
        
        float2 weightSum;
        
        float4 giAo = 0.0;
        
        float2 currentCoords;
        float avgB = getAverageBrightness();
        
        //float roughness = getRTF(coords).x;
            
        float maxSamples = iSmoothSamples;
        float3 previousResultGI = previousAccu.rgb;
        
        float radius = 6;
                
#if TEX_NOISE
        float3 rand = randomTriple(coords+0.05*framecount);
#else
        uint seed = getPixelIndex(coords,BUFFER_SIZE);
        float3 rand = randomTriple(coords,seed);
#endif
        float motionMask = getColorSampler(motionMaskSampler,coords).x;
        
    	float2 delta;
    	[loop]
        for(delta.x=-2;delta.x<=2;delta.x+=1) {
        	[loop]
	        for(delta.y=-1;delta.y<=1;delta.y+=1) {
	        	
	        	float dist = length(delta);
	        	
		        currentCoords = coords+delta*ReShade::PixelSize.xy;
				
	            if(!isScaledProcessed(currentCoords)) continue;
	            
	            float2 currentScaledCoords = upCoords(currentCoords);
	            
				smoothWeight(
					dist,
					refDepth, motionMask, refNormal, previousAccu, avgB, 
					sourceGISampler,currentCoords,currentScaledCoords,
					maxSamples, weightSum, giAo, previousResultGI,
					true
				);
	        }
        }


        
		float angle = rand.x*2*PI;
        
        [loop]
        for(float s=15;s<maxSamples;s+=1.0) {
        	angle += PI/4.0;
        	
        	float dist = 1+5*(s/maxSamples);
	        currentCoords = coords+float2(cos(angle),sin(angle))*ReShade::PixelSize.xy*dist;
			
            if(!isScaledProcessed(currentCoords)) continue;
            
            float2 currentScaledCoords = upCoords(currentCoords);
            
			smoothWeight(
				dist,
				refDepth, motionMask, refNormal, previousAccu, avgB, 
				sourceGISampler,currentCoords,currentScaledCoords,
				maxSamples, weightSum, giAo, previousResultGI,
				true
			);
        
        }
        
		smoothAccu(
			motionMask, refDepth, refWp,
			giAo, weightSum,
			previousCoords, previousAccu,
			true
		);
        
        outGI = saturate(giAo);
    }
    
    void smoothPass2(
        sampler sourceGISampler,
        float2 coords, out float4 outGI
    ) {
        
        float2 refDepth = getDepth(coords);
        
        if(isSky(refDepth.x)) {
            outGI = float4(getColor(coords).rgb,1);
            return;
        }
        
        
        float2 downscaledCoords = coords*fGIRenderScale;
        float2 previousCoords = getPreviousCoords(coords);
        float4 previousAccu = getColorSampler(giPreviousAccuSampler,previousCoords);
        
        float3 refNormal = getNormal(coords);  
        float3 refWp = getWorldPosition(coords,refDepth.x);        
        
        float2 weightSum;
        
        float4 giAo = 0.0;
        
        float2 currentCoords;
        float avgB = getAverageBrightness();
        
        //float roughness = getRTF(coords).x;
            
        float maxSamples = iSmoothSamples;
        float3 previousResultGI = previousAccu.rgb;
        
        float radius = iSmoothRadius;
        float4 bestRay = getColorSampler(bestRaySampler,downscaledCoords);
        float3 bestRayWp = getWorldPosition(bestRay.xy,bestRay.z);
        float dist = distance(refWp,bestRayWp);
        radius += (dist*0.35);
                
#if TEX_NOISE
        float3 rand = randomTriple(coords+0.05*framecount);
#else
        uint seed = getPixelIndex(coords,BUFFER_SIZE);
        float3 rand = randomTriple(coords,seed);
#endif
        float angle = rand.x*2*PI;
        float motionMask = getColorSampler(motionMaskSampler,coords).x;
		
		
        
        [loop]
        for(float s=0;s<maxSamples;s+=1.0) {
        	if(s>0) {
        		angle += PI/4.0+rand.x;
        	}
        	
			float dist = (radius)*pow(s/maxSamples,2);
	        currentCoords = downscaledCoords+float2(cos(angle),sin(angle))*ReShade::PixelSize.xy*dist;
			
            if(!isScaledProcessed(currentCoords)) continue;
            
            float2 currentScaledCoords = upCoords(currentCoords);        
            
			smoothWeight(
				dist,
				refDepth, motionMask, refNormal, previousAccu, avgB, 
				sourceGISampler,currentCoords,currentScaledCoords,
				maxSamples, weightSum, giAo, previousResultGI,
				false
			);
        
        }
        
		smoothAccu(
			motionMask, refDepth, refWp,
			giAo, weightSum,
			previousCoords, previousAccu,
			false
		);
        
        outGI = saturate(giAo);
    }
    
    void PS_SmoothPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0) {
        smoothPass1(giPass2Sampler,coords,outGI);
    }
    
    void PS_Smooth2Pass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0) {
        smoothPass2(giSmoothPassSampler,coords,outGI);
    }
    
    float3 oklLerp(float3 a,float3 b, float3 r) {
        return OKLtoRGB(lerp(RGBtoOKL(saturate(a)),RGBtoOKL(saturate(b)),r));
    }
    
    
    void PS_AccuPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0, out float4 outSSR : SV_Target1) {
    
        float4 giAO = getColorSampler(giSmooth2PassSampler,coords);
        if(maxOf3(giAO.rgb)<0.1) {
        	giAO = getColorSamplerLod(giSmooth2PassSampler,coords,2.0);
        }
        
        

        float motionMask = getColorSampler(motionMaskSampler,coords).x;
        if(motionMask>0) {
            giAO = getColorSamplerLod(giSmooth2PassSampler,coords,3);
            outGI = giAO;
            outSSR = bSSR ? getColorSampler(ssrPassSampler,coords*fSSRRenderScale) : 0;
            return;
        }
        
        float2 previousCoords = getPreviousCoords(coords);    
        float motionDist = 1+distance(coords*BUFFER_SIZE,previousCoords*BUFFER_SIZE);
        float centerDist = distance(0.5*BUFFER_SIZE,previousCoords*BUFFER_SIZE);
        motionDist *= (1+centerDist*50.0/BUFFER_WIDTH);
        
        float2 op = 1.0/float2(iGIFrameAccu,iAOFrameAccu);
        op = lerp(op,1,saturate(motionDist/256));
        op = saturate(op);
        
        float4 previousColorMoved = getColorSampler(giPreviousAccuSampler,previousCoords);

		float diff = maxOf3(abs(previousColorMoved.rgb-giAO.rgb));
		if(diff>0.2) op.x = saturate(op.x*(2+(diff-0.2)/0.8));
        giAO.rgb = oklLerp(previousColorMoved.rgb,giAO.rgb,op.x);
        giAO.a = lerp(previousColorMoved.a,giAO.a,op.y);
        

        outGI = giAO;
        
        if(bSSR) {
            
            float4 ssr = getColorSampler(ssrPassSampler,coords*fSSRRenderScale);
            float b = getBrightness(ssr.rgb);
            if(b<0.1) {
                ssr = getColorSamplerLod(ssrPassSampler,coords*fSSRRenderScale,2+3*b/0.1);
            }
        
            float4 previousSSRm = getColorSampler(ssrPreviousAccuSampler,previousCoords);
            float4 previousSSR = getColorSampler(ssrPreviousAccuSampler,coords);
            previousSSRm = lerp(previousSSRm,previousSSR,0.5);
            
            float op = ssr.a/iSSRFrameAccu;
	        float2 refDepth = getDepth(coords);
            op = max(0.33/iSSRFrameAccu,op*saturate(1.0-refDepth.x*3));
            
            op = lerp(op,1,saturate(motionDist/256));           
            op = saturate(op);
            if(maxOf3(previousSSRm)<0.01) op = 1;
            
            ssr.rgb = oklLerp(
                    previousSSRm.rgb,
                    ssr.rgb,
                    op
                );
                
            
            outSSR = ssr;
        } else {
            outSSR = 0;
        }
        
    }
    
    
    float smoothPow(float x,float p) {
        return smoothstep(0,1,pow(x,p));
    }
    
    
    float computeAo(float ao,float colorBrightness, float giBrightness, float avgB) {
        
        //ao = fAOMultiplier-(1.0-ao)*fAOMultiplier;
        if(fAOBoostFromGI>0) {
            //ao *= pow(giBrightness,fAOBoostFromGI*4);
            ao -= fAOBoostFromGI*pow(1.0-giBrightness,2);
        }
        ao = 1.0-saturate((1.0-ao)*fAOMultiplier);
        
        ao = (safePow(ao,fAOPow));
        
        //ao += giBrightness*fAoProtectGi*4.0;
        
        float inDark = max(0.1,pow(avgB,0.25));
        ao += (1.0-colorBrightness)*(1.0-colorBrightness)*fAODarkProtect;
        ao += pow(colorBrightness,2)*fAOLightProtect;
        
        ao = saturate(ao);
        ao = 1.0-saturate((1.0-ao)*fAOMultiplier);
        //ao += pow(giBrightness,2.0)*(1.0-fAoProtectGi)*4.0;
        ao += pow(giBrightness,2.0)*fAoProtectGi*4.0;
        
        ao += saturate((1.0-colorBrightness)*fAODarkProtect/inDark);
        
        return saturate(ao);
    }
    


    float3 compureResult(
            in float2 coords,
            in float depth,
            in float3 refColor,
            in float4 giAo,
            in bool reinhardFirstPass
        ) {

        float3 color = refColor;
         
        float originalColorBrightness = maxOf3(color);

        if(bRemoveAmbient) {
            color = filterAmbiantLight(color);
        }
        
        
        float3 gi = giAo.rgb;
        
        float3 giHSV = RGBtoHSV(gi);
        float3 colorHSV = RGBtoHSV(color);
       
        float colorBrightness = getBrightness(color);
            
        // Base color
        float3 result = color*(bBaseAlternative?1.0:fBaseColor);
        
        
        
        // GI
        float avgB = getAverageBrightness();

        result += originalColorBrightness*gi*fGIDarkMerging*(1.0-pow(originalColorBrightness,0.2));
         

		if(fGIHueBiais>0) {
        	float3 resultHSV = RGBtoHSV(saturate(result));
            float3 biaised = resultHSV;
            biaised.x = giHSV.x;
            biaised = HSVtoRGB(biaised);
            float r = giHSV.y*giHSV.z*(1.0-resultHSV.y)*max(pow((resultHSV.z-0.75)*2,4),pow((resultHSV.z-0.25)*2,4))*fGIHueBiais;
            
            result = lerp(result,biaised,saturate(r));
        }
        
        result += pow(result,0.25)*gi*saturate(1.0-avgB)*fGIDarkMerging*(1.0-originalColorBrightness);
        result = lerp(result,(1.0-fGILightMerging)*result + fGILightMerging*gi*result,saturate(originalColorBrightness*giHSV.z*4*fGILightMerging));
	        
        
        // Overbright
        if(!reinhardFirstPass && fGIOverbrightToWhite>0) {
            float b = maxOf3(result);
            if(b>1) {
                result += (b-1)*fGIOverbrightToWhite;
            }
        }
        
        
        if(bRreinhardFinalMerging && !reinhardFirstPass) {
            float2 mMW = getColorSampler(reinhardSampler,CENTER).xy;
            float3 rResult = result*(1+result/(mMW.y*mMW.y))/(1+result);
            result = oklLerp(result,rResult,fRreinhardStrength);
        }
        
        return reinhardFirstPass ? result : oklLerp(refColor,saturate(result),getRTF(coords).a);

    }
    

    void PS_ReinhardPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outReinhard : SV_Target0) {
        if(!bRreinhardFinalMerging) discard;
        float2 minMaxW = 0;
        
        float2 currentCoords = 0;
        
        float2 pixelSize = ReShade::PixelSize;
        float2 stepSize = (BUFFER_SIZE/8.0)*pixelSize;
        
        float2 rand = randomCouple(coords);
        [loop]
        for(currentCoords.x=stepSize.x*0.5;currentCoords.x<=1.0-stepSize.x*0.5;currentCoords.x+=stepSize.x) {
    		[loop]         
			for(currentCoords.y=stepSize.y*0.5;currentCoords.y<=1.0-stepSize.y*0.5;currentCoords.y+=stepSize.y) {
                rand = nextRand(rand);
                float2 c = currentCoords+(rand-0.5)*stepSize;
               
                float depth = getDepth(c).x;
                float3 refColor = getColor(c).rgb;
                
                float4 giAo = getColorSampler(giAccuSampler,c);
               
                float3 result = compureResult(c,depth,refColor,giAo,true);
                float b = getBrightness(result);
                minMaxW.x = min(minMaxW.x,b);
                minMaxW.y = max(minMaxW.y,b);
            }
        }
        
        outReinhard = float4(minMaxW,1.0,1.0/64.0);
    }

    void PS_UpdateResult(in float4 position : SV_Position, in float2 coords : TEXCOORD, 
            out float4 outResult : SV_Target,
            out float4 outGiAccu : SV_Target1,
            out float4 outSsrAccu : SV_Target2
#if !DX9_MODE
            ,out float4 outDepth : SV_Target3
#endif
    ) {
        float2 depth = getDepth(coords);
        float3 refColor = getColor(coords).rgb;

        float4 giAo = getColorSampler(giAccuSampler,coords);

        outGiAccu = giAo;
        outSsrAccu = bSSR ? getColorSampler(ssrAccuSampler,coords) : 0;
#if !DX9_MODE
        outDepth = depth;
#endif

        outResult = float4(compureResult(coords,depth.x,refColor,giAo,false),1.0);
    }
    

    
    void PS_DisplayResult(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outPixel : SV_Target0)
    {        
        float3 result = 0;
        
#if !DX9_MODE
        if(bDebugLight) {
            if(distance(coords,fDebugLightPosition.xy)<2*ReShade::PixelSize.x) {
                float colorBrightness = getBrightness(result);
                outPixel = float4(fDebugLightColor,1);
                return;
            }
        }
#endif
        
        
        if(iDebug==DEBUG_OFF) {
            result = getColorSampler(resultSampler,coords).rgb;
            
            // AO
            float avgB = getAverageBrightness();
            float resultB = getBrightness(result);
            float4 giAo = getColorSampler(giAccuSampler,coords);
            float giBrightness = getBrightness(giAo.rgb);
            float ao = giAo.a;
            ao = computeAo(ao,resultB,giBrightness,avgB);
            result *= ao;
               
            // SSR
            if(bSSR && fSSRMerging>0.0) {
                float colorBrightness = getBrightness(result);
                float3 ssr = computeSSR(coords,colorBrightness);
                result += ssr;
            }
            
            // Levels
            result = (result-iBlackLevel/255.0)/((iWhiteLevel-iBlackLevel)/255.0);
            
            // Distance fading
            float depth = getDepth(coords).x;
            if(fDistanceFading<1.0 && depth>fDistanceFading*getDepthMultiplier()) {
                float3 color = getColor(coords).rgb;
                
                float diff = depth/getDepthMultiplier()-fDistanceFading;
                float max = 1.0-fDistanceFading;
                float ratio = diff/max;
                result = result*(1.0-ratio)+color*ratio;
            }
            
            result = saturate(result);
            
        } else if(iDebug==DEBUG_GI) {
            float4 passColor;
            if(false) {
	            if(iDebugPass==0) passColor =  getColorSampler(giPass2Sampler,coords*fGIRenderScale);
	            if(iDebugPass==1) passColor =  getColorSampler(giSmoothPassSampler,coords*fGIRenderScale);
	            
            } else {
	            if(iDebugPass==0) passColor =  getColorSampler(giPassSampler,coords*fGIRenderScale);
	            if(iDebugPass==1) passColor =  getColorSampler(giPass2Sampler,coords*fGIRenderScale);
            }
            if(iDebugPass==2) passColor =  getColorSampler(giSmooth2PassSampler,coords);
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
                
                float3 addedGi = gi*color*
                    saturate(
                    (pow(1.0-colorBrightness,2)-pow(1.0-colorBrightness,4))*2*fGIDarkMerging
                    -(pow(colorBrightness,2)-pow(colorBrightness,4))*(1.0-fGILightMerging)
                    )*fGIFinalMerging;
                    
                result += addedGi;
                
                result = saturate(0.5+result-color);
            }

            
        } else if(iDebug==DEBUG_AO) {

            float4 passColor;
            if(iDebugPass==0) passColor =  getColorSampler(giPassSampler,coords*fGIRenderScale);
            if(iDebugPass==0) passColor =  getColorSampler(giPass2Sampler,coords*fGIRenderScale);
            if(iDebugPass==1) passColor =  getColorSampler(giPass2Sampler,coords*fGIRenderScale);
            if(iDebugPass==1) passColor =  getColorSampler(giSmoothPassSampler,coords*fGIRenderScale);
            if(iDebugPass==2) passColor =  getColorSampler(giSmooth2PassSampler,coords);
            if(iDebugPass>=3) passColor =  getColorSampler(giAccuSampler,coords);

            float ao = passColor.a;
            
            
            if(iDebugPass==3) {
                float giBrightness = getBrightness(passColor.rgb);
                if(fAOBoostFromGI>0) {
                    //ao *= pow(giBrightness,(fAOBoostFromGI)*4);
                    ao -= fAOBoostFromGI*pow(1.0-giBrightness,2);
                }
                ao = 1.0-saturate((1.0-ao)*fAOMultiplier);
                ao += pow(giBrightness,2.0)*fAoProtectGi*4.0;
                
            } else if(iDebugPass==4) {
                float giBrightness = getBrightness(passColor.rgb);

                float3 color = getColor(coords).rgb;
                if(bRemoveAmbient) {
                    color = filterAmbiantLight(color);
                }
                float colorBrightness = getBrightness(color);
            
                float avgB = getAverageBrightness();
                ao = computeAo(ao,colorBrightness,giBrightness,avgB);
            }
            result = ao;
            
        } else if(iDebug==DEBUG_SSR) {
            float4 passColor;
            if(iDebugPass==0) passColor =  getColorSampler(ssrPassSampler,coords*fSSRRenderScale);
            if(iDebugPass==1) passColor =  getColorSampler(ssrPassSampler,coords*fSSRRenderScale);
            if(iDebugPass==2) passColor =  getColorSampler(ssrPassSampler,coords*fSSRRenderScale);
            if(iDebugPass>=3) passColor =  getColorSamplerLod(ssrAccuSampler,coords,1);
            
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
            float depth = getDepth(coords).x;
            result = depth;
            if(depth<fWeaponDepth*getDepthMultiplier()) {
                result = float3(1,0,0);
            }
            else if(depth==1) {
                result = float3(0,1,0);
            }
            
        } else if(iDebug==DEBUG_NORMAL) {
            result = getColorSampler(normalSampler,coords).rgb;
            
        } else if(iDebug==DEBUG_SKY) {
            float depth = getDepth(coords).x;
            result = isSky(depth)?1.0:0.0;
            //result = getColor(getColorSampler(bestRaySampler,coords).xy).rbg;
            //result = getColorSampler(bestRayFillSampler,coords).xyz;
      
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
            float4 rtfs = getColorSampler(RTFSampler,coords);
            if(iDebugPass==0) result =  rtfs.x;
            if(iDebugPass==1) result =  rtfs.y;
            if(iDebugPass==2) result =  rtfs.z;
            if(iDebugPass>=3) result =  rtfs.a;
            if(iDebugPass==4) result = drtf.z*0.004;
            
            result = drtf.z*0.004;
            
            float4 brs = getColorSampler(bestRayFillSampler,coords*fGIRenderScale);
            result = brs.a>0 ? getRayColor(brs.xy).rgb : 0;
            
        }
        
        outPixel = float4(result,1.0);
    }


// TEHCNIQUES 
    
    technique DH_UBER_RT <
        ui_label = "DH_UBER_RT 0.20.6";
        ui_tooltip = 
            "_____________ DH_UBER_RT _____________\n"
            "\n"
            " ver 0.20.6 (2025-03-04)  by AlucardDH\n"
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
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_MotionMask;
            RenderTarget = motionMaskTex;
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
            RenderTarget1 = depthTex;
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
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_Smooth2Pass;
            RenderTarget = giSmooth2PassTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_AccuPass;
            RenderTarget = giAccuTex;
            RenderTarget1 = ssrAccuTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_ReinhardPass;
            RenderTarget = reinhardTex;
            
            ClearRenderTargets = false;
                        
            BlendEnable = true;
            BlendOp = ADD;
            SrcBlend = SRCALPHA;
            SrcBlendAlpha = ONE;
            DestBlend = INVSRCALPHA;
            DestBlendAlpha = ONE;
        }
        
        
        // Merging
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_UpdateResult;
            RenderTarget = resultTex;
            RenderTarget1 = giPreviousAccuTex;
            RenderTarget2 = ssrPreviousAccuTex;
#if !DX9_MODE
            RenderTarget3 = previousDepthTex;
#endif            
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_DisplayResult;
        }
    }
}