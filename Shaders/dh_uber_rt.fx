////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_UBER_RT 0.18.1-dev (2024-04-14)
//
// This shader is free, if you paid for it, you have been ripped and should ask for a refund.
//
// This shader is developed by AlucardDH (Damien Hembert)
//
// Get more here : https://alucarddh.github.io
// Join my Discord server for news, request, bug reports or help : https://discord.gg/V9HgyBRgMW
//
////////////////////////////////////////////////////////////////////////////////////////////////
#include "ReShade.fxh"

// VISIBLE PERFORMANCE SETTINGS /////////////////////////////////////////////////////////////////

// Define the working resolution of the intermediate steps of the shader
// Default is 0.5. 1.0 for full-res, 0.5 for quarter-res
// It can go lower for a performance boost like 0.25 but the image will be more blurry and noisy
// It can go higher (lile 2.0) if you have GPU to spare
#ifndef DH_RENDER_SCALE
 #define DH_RENDER_SCALE 0.25
#endif

#ifndef USE_MARTY_LAUNCHPAD
 #define USE_MARTY_LAUNCHPAD 0
#endif

/*
#ifndef SPHERE_RATIO
 #define SPHERE_RATIO 8
#endif
*/

// HIDDEN PERFORMANCE SETTINGS /////////////////////////////////////////////////////////////////
// Should not be modified but can help if you really want to squeeze some FPS at the cost of lower fidelity

// Define the maximum distance a ray can travel
// Default is 1.0 : the full screen/depth, less (0.5) can be enough depending on the game

#define OPTIMIZATION_MAX_RETRIES_FAST_MISS_RATIO 1.5

// Define is a light smoothing filter on Normal
// Default is 1 (activated)
#define NORMAL_FILTER 0



#define DX9_MODE (__RENDERER__==0x9000)

// Enable ambient light functionality
#define AMBIENT_ON !DX9_MODE
#define TEX_NOISE DX9_MODE
#define OPTIMIZATION_ONE_LOOP_RT DX9_MODE


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

#define RT_HIT 1.0
#define RT_HIT_BEHIND 0.5
#define RT_HIT_GUESS 0.25
#define RT_HIT_SKY -0.5
#define RT_MISSED -1.0
#define RT_MISSED_FAST -2.0

#define PI 3.14159265359
#define SQRT2 1.41421356237

#define fGIDistancePower 2.0

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
#define getNormal(c) (tex2Dlod(normalSampler,float4((c).xy,0,0)).xyz-0.5)*2
#define getColor(c) tex2Dlod(ReShade::BackBuffer,float4((c).xy,0,0))
#define getColorSamplerLod(s,c,l) tex2Dlod(s,float4((c).xy,0,l))
#define getColorSampler(s,c) tex2Dlod(s,float4((c).xy,0,0))
#define maxOf3(a) max(max(a.x,a.y),a.z)
#define minOf3(a) min(min(a.x,a.y),a.z)
#define avgOf3(a) (((a).x+(a).y+(a).z)/3.0)
#define CENTER float2(0.5,0.5)
//////////////////////////////////////////////////////////////////////////////

#if USE_MARTY_LAUNCHPAD
namespace Deferred {
	texture MotionVectorsTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
	sampler sMotionVectorsTex { Texture = MotionVectorsTex; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };
}
#else

texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler sTexMotionVectorsSampler { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

#endif
namespace DH_UBER_RT_0181 {

// Textures

    // Common textures

#if TEX_NOISE
    texture blueNoiseTex < source ="dh_rt_noise.png" ; > { Width = 512; Height = 512; MipLevels = 1; Format = RGBA8; };
    sampler blueNoiseSampler { Texture = blueNoiseTex;  AddressU = REPEAT;  AddressV = REPEAT;  AddressW = REPEAT;};
#endif
#if AMBIENT_ON
    texture ambientTex { Width = 1; Height = 1; Format = RGBA16F; };
    sampler ambientSampler { Texture = ambientTex; };   

    texture previousAmbientTex { Width = 1; Height = 1; Format = RGBA16F; };
    sampler previousAmbientSampler { Texture = previousAmbientTex; }; 
#endif
    // Roughness Thickness
    texture previousRTTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler previousRTSampler { Texture = previousRTTex; };
    texture RTTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
    sampler RTSampler { Texture = RTTex; };
    
/*    
    texture previousSphereTex { Width = RENDER_WIDTH/SPHERE_RATIO; Height = RENDER_HEIGHT/SPHERE_RATIO; Format = RGBA8; };
    sampler previousSphereSampler { Texture = previousSphereTex;};
    
    texture sphereTex { Width = RENDER_WIDTH/SPHERE_RATIO; Height = RENDER_HEIGHT/SPHERE_RATIO; Format = RGBA8; };
    sampler sphereSampler { Texture = sphereTex;};
*/    

    texture normalTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA16F; };
    sampler normalSampler { Texture = normalTex; };
    
    texture resultTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler resultSampler { Texture = resultTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    // RTGI textures
    texture rayColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6; };
    sampler rayColorSampler { Texture = rayColorTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    texture giPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; MipLevels = 6; };
    sampler giPassSampler { Texture = giPassTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    texture giSmoothPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; MipLevels = 6; };
    sampler giSmoothPassSampler { Texture = giSmoothPassTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    texture giAccuTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA16F; MipLevels = 6; };
    sampler giAccuSampler { Texture = giAccuTex; MinLOD = 0.0f; MaxLOD = 5.0f;};

    // SSR texture
    texture ssrPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; };
    sampler ssrPassSampler { Texture = ssrPassTex; };

    texture ssrSmoothPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; };
    sampler ssrSmoothPassSampler { Texture = ssrSmoothPassTex; };
    
    texture ssrAccuTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA8; };
    sampler ssrAccuSampler { Texture = ssrAccuTex; };
    
// Structs
    struct RTOUT {
        float3 wp;
        float3 DRT;
        float deltaZ;
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
    > = 0.0;
    uniform float fTest2 <
		ui_category="Test";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 25.0;
        ui_step = 0.001;
    > = 0.0;
    uniform float fTest3 <
		ui_category="Test";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0;
    uniform int iTest <
		ui_category="Test";
        ui_type = "slider";
        ui_min = 0; ui_max = 64;
        ui_step = 1;
    > = 1;
    uniform bool bTest <ui_category="Test";> = false;
    uniform bool bTest2 <ui_category="Test";> = false;
    uniform bool bTest3 <ui_category="Test";> = false;
    uniform bool bTest4 <ui_category="Test";> = false;
    uniform bool bTest5 <ui_category="Test";> = false;
*/
    
// DEBUG 

    uniform int iDebug <
        ui_category = "Debug";
        ui_type = "combo";
        ui_label = "Display";
        ui_items = "Output\0GI\0AO\0SSR\0Roughness\0Depth\0Normal\0Sky\0Motion\0Ambient light\0Thickness\0";
        ui_tooltip = "Debug the intermediate steps of the shader";
    > = 0;
    
    uniform bool bDebugShowIntensity <
        ui_category = "Debug";
        ui_label = "Show intensity";
    > = false;  

	uniform float fTempoGS <
        ui_type = "slider";
        ui_category = "Experimental";
        ui_label = "GI Trade-off Ghosting/shimmering";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
    > = 0.25; 
    
    uniform float fGIDistanceAttenuation <
        ui_type = "slider";
        ui_category = "Experimental";
        ui_label = "GI Distance attenuation";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
    > = 0.15; 
    
    uniform bool bGIOpti <
        ui_category = "Experimental";
        ui_label = "GI Fast";
    > = true; 
    
    uniform bool bRTHQSubPixel <
        ui_category = "Experimental";
        ui_label = "GI High precision sub-pixels";
    > = false; 
    
    uniform bool bSSRHQSubPixel <
        ui_category = "Experimental";
        ui_label = "SSR High precision sub-pixels";
    > = true;
    
// DEPTH

    uniform float fSkyDepth <
        ui_type = "slider";
        ui_category = "Common Depth";
        ui_label = "Sky Depth";
        ui_min = 0.00; ui_max = 1.00;
        ui_step = 0.01;
        ui_tooltip = "Define where the sky starts to prevent if to be affected by the shader";
    > = 0.99;
    
    uniform float fWeaponDepth <
        ui_type = "slider";
        ui_category = "Common Depth";
        ui_label = "Weapon Depth ";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Define where the first person weapon ends";
    > = 0.001;
    
// COMMMON RT
    
#if DX9_MODE
#else
    uniform int iCheckerboardRT <
        ui_category = "Common RT";
        ui_type = "combo";
        ui_label = "Checkerboard ray tracing";
        ui_items = "Disabled\0Half per frame\0Quarter per frame\0";
        ui_tooltip = "One ray per pixel, 1 ray per 2-pixels or 1 ray per 4-pixels\n"
                    "Lower=less ghosting, less performance\n"
                    "Higher=more ghosting, less noise, better performance\n"
                    "POSITIVE INPACT ON PERFORMANCES";
    > = 0;
#endif

    uniform int iFrameAccu <
        ui_type = "slider";
        ui_category = "Common RT";
        ui_label = "Temporal accumulation";
        ui_min = 1; ui_max = 16;
        ui_step = 1;
        ui_tooltip = "Define the number of accumulated frames over time.\n"
                    "Lower=less ghosting in motion, more noise\n"
                    "Higher=more ghosting in motion, less noise\n"
                    "/!\\ If motion detection is disable, decrease this to 3 except if you have a very high fps";
    > = 12;

#if !OPTIMIZATION_ONE_LOOP_RT
    uniform int iRTMaxRays <
        ui_type = "slider";
        ui_category = "Common RT";
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
        ui_category = "Common RT";
        ui_label = "... per pixel of";
        ui_items = "Render size\0Target size\0";
    > = 1;
    
    uniform int iRTMaxRaysMode <
        ui_type = "combo";
        ui_category = "Common RT";
        ui_label = "... per pixel of";
        ui_items = "Render size\0Target size\0";
    > = 1;
    
    uniform float fRTMinRayBrightness <
        ui_type = "slider";
        ui_category = "Common RT";
        ui_label = "Min ray brightness";
        ui_min = 0.01; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define the minimum brightness of a ray to not retry.\n"
                    "Lower=Darker image, better performance\n"
                    "Higher=Less noise, brighter image\n"
                    "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 0.1;
#endif

    uniform float fNormalRoughness <
        ui_type = "slider";
        ui_category = "Common RT";
        ui_label = "Normal roughness";
        ui_min = 0.000; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "";
    > = 0.1;

// AMBIENT LIGHT 
#if AMBIENT_ON
    uniform bool bRemoveAmbient <
        ui_category = "Ambient light";
        ui_label = "Remove Source Ambient light";
    > = true;
    
    uniform bool bRemoveAmbientAuto <
        ui_category = "Ambient light";
        ui_label = "Auto ambient color";
    > = true;

    uniform float3 cSourceAmbientLightColor <
        ui_type = "color";
        ui_category = "Ambient light";
        ui_label = "Source Ambient light color";
    > = float3(31.0,44.0,42.0)/255.0;
    
    uniform float fSourceAmbientIntensity <
        ui_type = "slider";
        ui_category = "Ambient light";
        ui_label = "Strength";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.75;
    
    uniform int iRemoveAmbientMode <
        ui_category = "Ambient light";
        ui_label = "Mode";
        ui_type = "combo";
        ui_items = "As external\0Only GI\0Only base image\0";
    > = 0;
    
/// ADD
    uniform bool bAddAmbient <
        ui_category = "Ambient light";
        ui_label = "Add Ambient light";
    > = false;

    uniform float3 cTargetAmbientLightColor <
        ui_type = "color";
        ui_category = "Add ambient light";
        ui_label = "Target Ambient light color";
    > = float3(13.0,13.0,13.0)/255.0;
#endif
    
// GI    
    
    uniform bool bGIAvoidThin <
        ui_category = "GI";
        ui_label = "Avoid thin objects";
        ui_tooltip = "Reduce detection of grass or fences";
    > = true;
    
	uniform float fGIRayColorMinBrightness <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "GI Ray min brightness";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.0;
    
    uniform int iGIRayColorMode <
        ui_type = "combo";
        ui_category = "GI";
        ui_label = "GI Ray brightness mode";
        ui_items = "Crop\0Smoothstep\0Linear\0Gamma\0";
#if DX9_MODE
    > = 0;
#else
    > = 1;
#endif
    
    
    uniform float fSkyColor <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "Sky color";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much the sky can brighten the scene";
    > = 0.2;
    
    uniform float fSaturationBoost <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "Saturation boost";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.01;
    > = 0.0;
    
    uniform float fGIDarkAmplify <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "Dark color compensation";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Brighten dark colors, useful in dark corners";
    > = 0.15;
    
    uniform float fGIBounce <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "Bounce intensity";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Define if GI bounces in following frames";
    > = 0.5;

    uniform float fGIHueBiais <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "Hue Biais";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much base color can take GI hue.";
    > = 0.1;
    
    uniform float fGILightMerging <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "In Light intensity";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much bright areas are affected by GI.";
    > = 0.15;
    uniform float fGIDarkMerging <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "In Dark intensity";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much dark areas are affected by GI.";
    > = 0.35;
	uniform float fGIDarkPower <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "Dark power";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.5;
    
    uniform float fGIFinalMerging <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "General intensity";
        ui_min = 0; ui_max = 2.0;
        ui_step = 0.01;
        ui_tooltip = "Define how much the whole image is affected by GI.";
    > = 1.0;
    
    uniform float fGIOverbrightToWhite <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "Overbright to white";
        ui_min = 0.0; ui_max = 5.0;
        ui_step = 0.001;
    > = 0.25;
    
// AO
    uniform float fAOBoostFromGI <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Boost from GI";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.5;
    
    uniform float fAOMultiplier <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Multiplier";
        ui_min = 0.0; ui_max = 5;
        ui_step = 0.01;
        ui_tooltip = "Define the intensity of AO";
    > = 1.1;
    
    uniform int iAODistance <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Distance";
        ui_min = 0; ui_max = BUFFER_WIDTH;
        ui_step = 1;
    > = BUFFER_WIDTH/4;
    
    uniform float fAOPow <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Pow";
        ui_min = 0.001; ui_max = 2.0;
        ui_step = 0.001;
        ui_tooltip = "Define the intensity of the gradient of AO";
    > = 0.6;
    
    uniform float fAOLightProtect <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Light protection";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Protection of bright areas to avoid washed out highlights";
    > = 0.50;
    
	uniform float fAOLightPower <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Light power";
        ui_min = 0.0; ui_max = 4.0;
        ui_step = 0.001;
    > = 4.0;    
    
    uniform float fAODarkProtect <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Dark protection";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Protection of dark areas to avoid totally black and unplayable parts";
    > = 0.25;

    uniform float fAoProtectGi <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "GI protection";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.5;
    


    // SSR
    uniform bool bSSR <
        ui_category = "SSR";
        ui_label = "Enable SSR";
        ui_tooltip = "Toggle SSR";
    > = false;
    

    uniform int iRoughnessRadius <
        ui_type = "slider";
        ui_category = "SSR";
        ui_label = "Roughness Radius";
        ui_min = 1; ui_max = 4;
        ui_step = 2;
        ui_tooltip = "Define the max distance of roughness computation.\n"
                    "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 1;
    
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
    > = 0.350;

// Denoising
    uniform int iSmoothRadius <
        ui_type = "slider";
        ui_category = "Denoising";
        ui_label = "Radius";
        ui_min = 0; ui_max = 8;
        ui_step = 1;
        ui_tooltip = "Define the max distance of smoothing.\n"
                    "Higher:less noise, less performances\n"
                    "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 1;
    
    uniform bool bSSRFilter <
        ui_category = "Denoising";
        ui_label = "Filter SSR";
    > = false;
    
    
    /*
    uniform int iSmoothStep <
        ui_type = "slider";
        ui_category = "Denoising";
        ui_label = "Step";
        ui_min = 1; ui_max = 8;
        ui_step = 1;
        ui_tooltip = "Compromise smoothing by skipping pixels in the smoothing and using lower quality LOD.\n"
                    "Higher:less noise, can smooth surfaces that should not be mixed\n"
                    "This has no impact on performances :)";
    > = 4;
    */
    
    // Merging
        
    uniform float fDistanceFading <
        ui_type = "slider";
        ui_category = "Merging";
        ui_label = "Distance fading";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Distance from where the effect is less applied.";
    > = 0.9;
    
    uniform float fBaseColor <
        ui_type = "slider";
        ui_category = "Merging";
        ui_label = "Base color brightness";
        ui_min = 0.0; ui_max = 2.0;
        ui_step = 0.01;
        ui_tooltip = "Simple multiplier for the base image.";
    > = 1.0;

    uniform int iBlackLevel <
        ui_type = "slider";
        ui_category = "Merging";
        ui_label = "Black level ";
        ui_min = 0; ui_max = 255;
        ui_step = 1;
    > = 0;
    
    uniform int iWhiteLevel <
        ui_type = "slider";
        ui_category = "Merging";
        ui_label = "White level";
        ui_min = 0; ui_max = 255;
        ui_step = 1;
    > = 255;

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
    
    float getPureness(float3 rgb) {
        return maxOf3(rgb)-minOf3(rgb);
    }
    
    float getBrightness(float3 rgb) {
    	return maxOf3(rgb);
    }

// Screen

    float getDepth(float2 coords) {
        return ReShade::GetLinearizedDepth(coords);
    }
    
    
    float2 getRT(float2 coords) {
        return getColorSampler(RTSampler,coords).xy;
    }
    
    float3 getDRT(float2 coords) {
        float3 drt = getDepth(coords);
        drt.yz = getRT(coords);
        drt.z = (0.01+drt.z)*drt.x*320;
        drt.z *= (0.25+drt.x);
        
        return drt;
    }
    
    bool inScreen(float3 coords) {
        return coords.x>=0.0 && coords.x<=1.0
            && coords.y>=0.0 && coords.y<=1.0
            && coords.z>=0.0 && coords.z<=1.0;
    }
    

    
    float3 getWorldPositionForNormal(float2 coords) {
        float depth = getDepth(coords);
        if(fNormalRoughness>0) {
            float roughness = getRT(coords).x;
        	depth += depth*roughness*fNormalRoughness*0.1;
        }
        
        float3 result = float3((coords-0.5)*depth,depth);
        if(depth<fWeaponDepth) {
            result.z /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
        }
        result *= BUFFER_SIZE3;
        return result;
    }
    
    float3 getWorldPosition(float2 coords,float depth) {
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

    float3 computeNormal(float2 coords,float3 offset) {
        float3 posCenter = getWorldPositionForNormal(coords);
        float3 posNorth  = getWorldPositionForNormal(coords - offset.zy);
        float3 posEast   = getWorldPositionForNormal(coords + offset.xz);
        return  normalize(cross(posCenter - posNorth, posCenter - posEast));
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
        v = abs((getColorSamplerLod(blueNoiseSampler,noiseCoords,0).rg-0.5)*2.0);
#else
        uint seed = getPixelIndex(coords,RENDER_SIZE);

        v.x = randomValue(seed);
        v.y = randomValue(seed);
#endif
        return v;
    }
    
    float3 randomTriple(float2 coords) {
        float3 v = 0;
#if TEX_NOISE
        int2 offset = int2((framecount*random*SQRT2),(framecount*random*PI))%512;
        float2 noiseCoords = ((offset+coords*BUFFER_SIZE)%512)/512;
        v = abs((getColorSamplerLod(blueNoiseSampler,noiseCoords,0).rgb-0.5)*2.0);
#else
        uint seed = getPixelIndex(coords,RENDER_SIZE)+random+framecount;

        v.x = randomValue(seed);
        v.y = randomValue(seed);
        v.z = randomValue(seed);
#endif
        return v;
    }
    
    float3 randomTriple(float2 coords,in out uint seed) {
        float3 v = 0;
#if TEX_NOISE
        int2 offset = int2((framecount*random*SQRT2),(framecount*random*PI))%512;
        float2 noiseCoords = ((offset+coords*BUFFER_SIZE)%512)/512;
        v = abs((getColorSamplerLod(blueNoiseSampler,noiseCoords,0).rgb-0.5)*2.0);
#else
        v.x = randomValue(seed);
        v.y = randomValue(seed);
        v.z = randomValue(seed);
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
#if USE_MARTY_LAUNCHPAD
		float2 mv = getColorSampler(Deferred::sMotionVectorsTex,coords).xy;
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

    float thicknessPass(float2 coords, float refDepth) {

        int iThicknessRadius = 4;//max(1,min(iTest,8));
        
        float2 thickness = 0;
        float previousXdepth = refDepth;
        float previousYdepth = refDepth;
        float depthLimit = refDepth*0.015;
        float depth;
        float2 currentCoords;
        
        float2 orientation = normalize(randomCouple(coords*PI)-0.5);
        
        bool validPos = true;
        bool validNeg = true;
        
        [loop]
        for(int d=1;d<=iThicknessRadius;d++) {
            float2 step = orientation*ReShade::PixelSize*d/DH_RENDER_SCALE;
            
            if(validPos) {
                currentCoords = coords+step;
                depth = getDepth(currentCoords);
                if(depth-previousXdepth<=depthLimit) {
                    thickness.x += 1;
                    previousXdepth = depth;
                } else {
                    validPos = false;
                }
            }
        
            if(validNeg) {
                currentCoords = coords-step;
                depth = getDepth(currentCoords);
                if(depth-previousYdepth<=depthLimit) {
                    thickness.y += 1;
                    previousYdepth = depth;
                } else {
                    validNeg = false;
                }
            }
        }        
        
        thickness /= iThicknessRadius;
        
        
        return (thickness.x+thickness.y)/2;
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
    
    void PS_RT_save(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outRT : SV_Target0) {
        outRT = getColorSampler(RTSampler,coords);
    }    
    
    void PS_DRT(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outRT : SV_Target0) {
        float2 RT;
        float depth = getDepth(coords);
        
        float2 previousCoords = getPreviousCoords(coords);
        float2 diff = (previousCoords-coords);
        
        RT.x = roughnessPass(coords,depth);
        RT.y = thicknessPass(coords,depth);
        
        float3 previousRT = getColorSampler(previousRTSampler,previousCoords).xyz;
        RT.y = lerp(previousRT.y,RT.y,0.33);
        
        outRT = float4(RT,0,1);
    }
    

#if AMBIENT_ON
    void PS_SavePreviousAmbientPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outAmbient : SV_Target0) {
        outAmbient = getColorSampler(ambientSampler,CENTER);
    }
    
    void PS_AmbientPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outAmbient : SV_Target0) {
        if(!bRemoveAmbient || !bRemoveAmbientAuto) discard;

        float4 previous = getColorSampler(previousAmbientSampler,CENTER);
        float3 result = previous.rgb;
        float b = maxOf3(result);
        
        bool first = framecount%60==0;
        if(b<0.1) {
            first = true;
            result = 1;
            b = 1;
        }
        
        float bestB = b;
        
        float2 currentCoords = 0;
        float2 bestCoords = CENTER;
        float2 rand = randomCouple(coords);
        
        float2 size = BUFFER_SIZE;
        float stepSize = BUFFER_WIDTH/16.0;
        float2 numSteps = size/(stepSize+1);
        
            
        //float2 rand = randomCouple(currentCoords);
        for(int it=0;it<=4 && stepSize>=1;it++) {
            float2 stepDim = stepSize/BUFFER_SIZE;
        
            for(currentCoords.x=bestCoords.x-stepDim.x*(numSteps.x/2);currentCoords.x<=bestCoords.x+stepDim.x*(numSteps.x/2);currentCoords.x+=stepDim.x) {
                for(currentCoords.y=bestCoords.y-stepDim.y*(numSteps.y/2);currentCoords.y<=bestCoords.y+stepDim.y*(numSteps.y/2);currentCoords.y+=stepDim.y) {
                   float2 c = currentCoords+rand*stepDim;
                    float3 color = getColor(c).rgb;
                    b = maxOf3(color);
                    if(b>0.1 && b<bestB) {
                    
                        bestCoords = c;
                        result = min(result,color);
                        bestB = b;
                    }
                }
            }
            size = stepSize;
            numSteps = 8;
            stepSize = size.x/numSteps.x;
        }
        
        float opacity = first && bestB<0.5 ? 0.5 : saturate(1.0-bestB*5)*0.1;
        result = min(previous.rgb+0.01,result);
        outAmbient = float4(result, first ? 0.1 : 0.01);
    }
    
    float3 getRemovedAmbiantColor() {
        if(bRemoveAmbientAuto) {
            float3 color = getColorSampler(ambientSampler,float2(0.5,0.5)).rgb;
            color += color.x;
            return color;
        } else {
            return cSourceAmbientLightColor;
        }
    }
    
    float3 filterAmbiantLight(float3 sourceColor) {
        float3 color = sourceColor;
        if(bRemoveAmbient) {
            float3 ral = getRemovedAmbiantColor();
            float3 removedTint = ral - minOf3(ral); 

            color -= removedTint;
            color = saturate(color);
            
            color = lerp(sourceColor,color,fSourceAmbientIntensity);
            
            if(bAddAmbient) {
                float b = getBrightness(color);
                color = saturate(color+pow(1.0-b,4.0)*cTargetAmbientLightColor);
            }
        }
        return color;
    }
#endif

    void PS_NormalPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outNormal : SV_Target0) {
        
        float3 offset = float3(ReShade::PixelSize, 0.0);
        
        float3 normal = computeNormal(coords,offset);

        #if NORMAL_FILTER            
            float3 normalTop = computeNormal(coords-offset.zy,offset);
            float3 normalBottom = computeNormal(coords+offset.zy,offset);
            float3 normalLeft = computeNormal(coords-offset.xz,offset);
            float3 normalRight = computeNormal(coords+offset.xz,offset);
            normal += normalTop+normalBottom+normalLeft+normalRight;
            normal/=5.0;
        #endif
        
        outNormal = float4(normal/2.0+0.5,1.0);
        
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
 
#if AMBIENT_ON
        if(iRemoveAmbientMode<2) {  
            color = filterAmbiantLight(color);
        }
#endif

		float3 colorHSV = RGBtoHSV(color);
		if(fSaturationBoost>0 && colorHSV.z*colorHSV.y>0.1) {
			colorHSV.y = saturate(colorHSV.y+fSaturationBoost);
			color = HSVtoRGB(colorHSV);
		}
        
        
        
		float3 result = rampColor(color);
		if(fGIBounce>0.0) {
			float2 previousCoords = getPreviousCoords(coords);
			float3 previousColor = getColorSampler(resultSampler,previousCoords).rgb;
        	result = saturate(result+rampColor(previousColor*fGIBounce));
		}
        
        if(fGIDarkAmplify>0) {
        	float3 colorHSV = RGBtoHSV(result);
            result *= 1.0+fGIDarkAmplify*(1.0-maxOf3(result))*4.0*(0.4+colorHSV.y*0.6);
        }
        
        
		
        
        if(getBrightness(result)<fGIRayColorMinBrightness) {
            result = 0; 
        }
        
        outColor = float4(result,1.0);
        
    }
    
    /*
    int2 sphereSize() {
    	return BUFFER_SIZE/SPHERE_RATIO;
    }
    
    bool isSaturated(float2 coords) {
    	return coords.x>=0 && coords.x<=1 && coords.y>=0 && coords.y<=1;
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
    		float2 p = coords + mv*fTest;

    		if(isSaturated(p)) {
    			float3 previousColor= getColorSampler(previousSphereSampler,p).rgb;
    			outColor = float4(previousColor,saturate(0.5+getBrightness(previousColor)));
    		} else {
    			outColor = float4(0,0,0,0);
    		}
    	}
	}
	*/
    
    
    int crossing(float deltaZbefore, float deltaZ) {      
        if(deltaZ<=0 && deltaZbefore>0) return -1;
        if(deltaZ>=0 && deltaZbefore<0) return 1;
        return  0;
    }
    
    bool hit(float3 currentWp, float3 screenWp, float depth, float thickness) {
    	if(bGIAvoidThin && thickness<depth*100) return false;
    	return currentWp.z>=screenWp.z && currentWp.z<=screenWp.z+thickness;
    }

    float3 getGIColor(float3 screenCoords, float3 hitWp, float3 refWp, float3 DRT) {

        float3 giColor;

        float dist = distance(hitWp,refWp);
        
        giColor = getRayColor(screenCoords.xy);
        
#if !DX9_MODE
        giColor *= saturate(safePow(DRT.z,0.25)*0.4);
        
        
        // Distance atenuation
        giColor *= 1.0-fGIDistanceAttenuation+fGIDistanceAttenuation/(1.0+dist*0.01);

        // Light hit orientation
        //  float orientationSource = saturate(0.25+dot(lightVector,-refNormal));
        //  giColor *= orientationSource; 
                
#endif
        return giColor;

    }
    
    RTOUT trace(float3 refWp,float3 incrementVector,float startDepth,bool ssr, float rayNum) {
    
        RTOUT result;
        
        float3 currentWp = refWp;
        float3 refNormal = getNormal(getScreenPosition(currentWp).xy);
        
		incrementVector = normalize(incrementVector);
        incrementVector /= max(abs(incrementVector.x),abs(incrementVector.y))*8.0;        
        
        float deltaZ = 0.0;      
        
        bool startWeapon = startDepth<fWeaponDepth;
        float weaponLimit = fWeaponDepth*BUFFER_SIZE3.z;
        
        currentWp += incrementVector;
        
        float3 screenCoords = getScreenPosition(currentWp);
        
        bool outScreen = !inScreen(screenCoords) && (!startWeapon || currentWp.z<weaponLimit);
        if(outScreen) {
        	result.status = RT_MISSED_FAST;
            return result;                
        }
        
        float3 DRT = getDRT(screenCoords.xy);
        if(DRT.x>fSkyDepth) {
            result.status = RT_HIT_SKY;
            result.wp = currentWp;
        }  
        
        float3 screenWp = getWorldPosition(screenCoords.xy,DRT.x);
        
        bool outSource = !hit(currentWp,screenWp,DRT.x,DRT.z);
        
        if(!outSource) {
        	if(result.status != RT_HIT_SKY) {
        		result.status = RT_MISSED_FAST;
        	}
            return result;                
        }
                
        result.status = RT_MISSED;
        
        
        bool behindBefore = false;
        float thickness = 0;
        
        int step = 0;
        [loop]
        do {
            currentWp += incrementVector;
            
            float3 screenCoords = getScreenPosition(currentWp);
            
            bool outScreen = !inScreen(screenCoords) && (!startWeapon || currentWp.z<weaponLimit);
            if(outScreen) {
            	currentWp -= incrementVector;
                break;
            }
            
            
            DRT = getDRT(screenCoords.xy);
            if(deltaZ>=0) {
            	if(thickness==0) {
            		thickness += length(incrementVector)*0.5*3;
            	} else {
            		thickness += length(incrementVector)*3;
            	}
            } else {
            	thickness = 0;
            }
            DRT.z += thickness*DRT.x;
            
            
            
            float3 screenWp = getWorldPosition(screenCoords.xy,DRT.x);
            bool behind = currentWp.z>screenWp.z+DRT.z*0.5;
            
            deltaZ = screenWp.z-currentWp.z;
            
            
            
            if(DRT.x>fSkyDepth && result.status<RT_HIT_SKY) {
                result.status = RT_HIT_SKY;
                result.wp = currentWp;
            }
            
            //int crossed = crossing(deltaZbefore,deltaZ);
            bool isHit = hit(currentWp, screenWp, DRT.x,DRT.z);
            float hitDist = behind
        						? currentWp.z - screenWp.z+thickness*0.5
        						: screenWp.z+thickness*0.5 - currentWp.z
        						;
                        
            if(isHit) {	
            	result.status = behind ? RT_HIT_BEHIND : RT_HIT;
            	result.DRT = DRT;
                result.deltaZ = hitDist;
                result.wp = currentWp;
                        
            	return result;

            }
            
        	if(ssr) {
        		float l = max(1,abs(deltaZ)*0.5);
        		incrementVector = normalize(incrementVector)*l;
        	} else {
  			  float2 r = randomCouple(screenCoords.xy);
                float l = 1.00+DRT.x+r.y;
                if(bGIOpti) {
				    l += step*r.x*0.5;
			    }
                
                incrementVector *= l;           
            } 
            
            
            behindBefore = behind;
            
            step++;

        } while(step<32);

        if(ssr && result.status<RT_HIT_GUESS) {
            result.wp = currentWp;
        }
        return result;
    }

// GI

	float2 getRealPixel(float2 coords,int index) {
    	int width = 1.0/DH_RENDER_SCALE;
    	int pixels = width*width;
    	int pix = (framecount+random+index) % pixels;
    	int2 delta = pix%width;
    	delta.y = pix/width;
    	float2 offset = delta*ReShade::PixelSize;
    	return coords -(ReShade::PixelSize/DH_RENDER_SCALE)*0.5+offset;
	}

    void PS_GILightPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0) {
        
        float2 subCoords = coords;
    	
		int subWidth = 1.0/DH_RENDER_SCALE;
		int subMax = subWidth*subWidth;
		int subCoordsIndex = framecount%subMax;
        
        float depth = getDepth(subCoords);
        if(depth>fSkyDepth) {
            outGI = 0.0;
            return;
        }
        
        float3 refWp = getWorldPosition(subCoords,depth);
        float3 refNormal = getNormal(subCoords);
        float3 refColor = getColor(subCoords).rgb;
        
        float2 previousCoords = getPreviousCoords(subCoords);
        float4 previousFrame = getColorSampler(giAccuSampler,previousCoords);
        
        float2 pixelSize = ReShade::PixelSize/DH_RENDER_SCALE;
        
        
#if DX9_MODE
        // No checkerboard rendering on DX9 for now
#else
        if(iCheckerboardRT==1 && halfIndex(coords)!=framecount%2) {
            outGI = previousFrame;
            return;
        }
        if(iCheckerboardRT==2 && quadIndex(coords)!=framecount%4) {
            outGI = previousFrame;
            return;
        }
#endif
		
		float3 screenCoords;
        
        float weightSum = 0;
        float4 mergedGiColor = 0.0;
        float mergedAO = 0.0;
        
        float hits = 0;
        float aoHits = 0;
        int rays = 0;
        
#if !TEX_NOISE
        uint seed = getPixelIndex(coords,RENDER_SIZE)+random+framecount;
#endif
        
#if !TEX_NOISE
        uint seed = getPixelIndex(subCoords,BUFFER_SIZE)+random+framecount;
#endif
        
    #if !OPTIMIZATION_ONE_LOOP_RT
    	int maxRays = iRTMaxRays*(iRTMaxRaysMode?subMax:1);
        
        [loop]
        for(rays=0;rays<maxRays && maxRays<=iRTMaxRays*(iRTMaxRaysMode?subMax:1)*OPTIMIZATION_MAX_RETRIES_FAST_MISS_RATIO && mergedGiColor.a<fRTMinRayBrightness;rays++) {
    #else
        int maxRays = 0;
        int rays = 0;
    #endif
    		
    		if(DH_RENDER_SCALE<1.0) {
	    		subCoordsIndex = (subCoordsIndex+1)%subMax;
	    		int2 delta = 0;
	    		delta.x = subCoordsIndex%subWidth;
	    		delta.y = subCoordsIndex/subWidth;
		        subCoords = coords+ReShade::PixelSize*(delta-subWidth*0.5);
		        depth = getDepth(subCoords);
		        if(bRTHQSubPixel) {
					refWp = getWorldPosition(subCoords,depth);
                	refNormal = getNormal(subCoords);
                }
	        }
#if TEX_NOISE
			float3 rand = randomTriple(subCoords+float2(0.0,(0.05*rays));
#else
			float3 rand = randomTriple(subCoords,seed);
#endif
			
            float3 lightVector = normalize(rand-0.5) - refNormal;

            RTOUT hitPosition = trace(refWp,lightVector,depth,false,float(1+rays)/(iRTMaxRaysMode?subMax:1));
            if(hitPosition.status == RT_MISSED_FAST) {
                maxRays++;
    #if !OPTIMIZATION_ONE_LOOP_RT
                continue;
    #endif
            }
                
            screenCoords = getScreenPosition(hitPosition.wp);
            
            float4 giColor = 0.0;                
                
            if(hitPosition.status==RT_HIT_SKY) {
                giColor = saturate(getColor(screenCoords.xy)*fSkyColor*1.5);
            } else if(hitPosition.status>=0 ) {
            
            	float dist = distance(hitPosition.wp,refWp);
            	
				giColor = getRayColor(screenCoords.xy);
                
#if !DX9_MODE
                giColor *= saturate(safePow(hitPosition.DRT.z,0.25)*0.4);
                
                
                // Distance atenuation
                giColor *= 1.0-fGIDistanceAttenuation+fGIDistanceAttenuation/(1.0+dist*0.01);
				
#endif

				                     
                float ao = dist/(iAODistance*depth);
                if(hitPosition.status==RT_HIT_BEHIND ) {
                	ao *= 48*depth;
                }
                mergedAO += saturate(ao);
                
                hits+=1.0;
            }
            
            float w = (0.1+maxOf3(giColor.rgb)-minOf3(giColor.rgb))*maxOf3(giColor.rgb);
            weightSum += w;
			mergedGiColor.rgb += w*giColor.rgb;
			mergedGiColor.a = maxOf3(mergedGiColor.rgb)+minOf3(mergedGiColor.rgb);
			
                
    #if !OPTIMIZATION_ONE_LOOP_RT
        }
    #endif

        if(hits<=0) {
            mergedAO = 1.0;
        } else {
            mergedAO /= hits;
        }
        
        if(weightSum>0) {
    		mergedGiColor.rgb /= weightSum;
    	}
        
        //mergedGiColor = OKLchtoRGB(mergedGiColor);
        
        float opacity = 1.0/iFrameAccu;

        float previousB = getBrightness(previousFrame.rgb);
        float newB = getBrightness(mergedGiColor.rgb)*(1+opacity);
        

    	if(previousB==0) {
        } else if(hits==0 || newB==0) {
        	mergedGiColor.rgb = previousFrame.rgb*0.95;
		} else {
			mergedGiColor.rgb = (newB*mergedGiColor.rgb+previousB*previousFrame.rgb)/(newB+previousB);
        }
        
        opacity = saturate(1.0/iFrameAccu+0.5*hits);
        
        mergedAO = lerp(previousFrame.a,mergedAO,opacity);
		
        
        outGI = float4(mergedGiColor.rgb,mergedAO);
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
        	subCoordsIndex = (subCoordsIndex*PI)%subMax;
    		delta.x = subCoordsIndex%subWidth;
    		delta.y = subCoordsIndex/subWidth;
	        subCoords = coords+ReShade::PixelSize*(delta-subWidth*0.5);
        }
            
        float depth = getDepth(subCoords);
        
        if(depth>fSkyDepth) {
            outColor = 0.0;
        } else {
        
            float3 result = 0;
            float weightSum = 0;
            
            [loop]
            for(int rays=0;rays<(bSSRHQSubPixel && DH_RENDER_SCALE<1.0 ?subMax:1);rays++) {
        		
        		if(bSSRHQSubPixel && DH_RENDER_SCALE<1.0) {
    	    		subCoordsIndex = (subCoordsIndex+1)%subMax;
    	    		delta.x = subCoordsIndex%subWidth;
    	    		delta.y = subCoordsIndex/subWidth;
    		        subCoords = coords+ReShade::PixelSize*(delta-subWidth*0.5);
    		        depth = getDepth(subCoords);
    	        }
                
                float3 targetWp = getWorldPosition(subCoords,depth);         
                float3 targetNormal = getNormal(subCoords);
                
        
                float3 lightVector = reflect(targetWp,targetNormal)*0.01;
                
                RTOUT hitPosition = trace(targetWp,lightVector,depth,true,rays);

                if(hitPosition.status<RT_HIT_SKY) {
                	//result += float4(0,0,0,0.1);
                } else if(hitPosition.status==RT_HIT_BEHIND) {
                	weightSum += 0.5;
    			} else {
                    float3 screenPosition = getScreenPosition(hitPosition.wp.xyz);
                    float2 previousCoords = getPreviousCoords(screenPosition.xy);
                    float3 c = getColorSampler(resultSampler,previousCoords).rgb;
                    
                    float w = getBrightness(c)*10.0+1.0;
                    if(hitPosition.status==RT_HIT_SKY) {
                    	w = 0.5;
                    }
                    result += c*w;
                    weightSum += w;
                
                }
            }

            if(weightSum>0) {
                outColor = float4(result/weightSum,(bSSRHQSubPixel?1:subMax)*weightSum/32.0);
            } else {
                outColor = float4(0,0,0,0.1);
            }
        }
        
            
    }
    
    void smooth(
        sampler sourceGISampler,
        sampler sourceSSRSampler,
        float2 coords, out float4 outGI, out float4 outSSR,bool firstPass
    ) {
        float3 pixelSize = float3(1.0/tex2Dsize(sourceGISampler),0);
        
        float refDepth = getDepth(coords);
        if(refDepth>fSkyDepth) {
            outGI = getColor(coords);
            outSSR = float4(0,0,0,1);
            return;
        }
        
        float3 refNormal = getNormal(coords);  
 
        float4 giAo = 0.0;
        float4 ssr = 0.0;
        
        float3 weightSum; // gi, ao, ssr
        
        float2 previousCoords = getPreviousCoords(coords);    
        
        float4 refColor;   
        float3 refColorHSV;
        if(firstPass) {
            refColor = getColorSampler(giAccuSampler,previousCoords);            
            refColorHSV = RGBtoHSV(refColor.rgb);
        }
        
        float4 previousColor = firstPass ? getColorSampler(giAccuSampler,coords) : 0;
        float4 previousSSRm = bSSR && firstPass ? getColorSampler(ssrAccuSampler,previousCoords) : 0;
		//float4 previousSSR = bSSR && firstPass ? getColorSampler(ssrAccuSampler,coords) : 0;

        
        float4 refSSR = getColorSampler(sourceSSRSampler,coords);
        
        float refB = getBrightness(refColor.rgb);
        
        float2 currentCoords;
        
        int2 delta;
        

        float op = 1.0/iFrameAccu;
        
        [loop]
        for(delta.x=-iSmoothRadius;delta.x<=iSmoothRadius;delta.x++) {
            [loop]
            for(delta.y=-iSmoothRadius;delta.y<=iSmoothRadius;delta.y++) {
                float dist = length(delta);
                
                if(dist>iSmoothRadius) continue;
                currentCoords = coords+delta*pixelSize.xy*(firstPass ? dist : 1);
                            	
                
                float depth = getDepth(currentCoords);
                if(depth>fSkyDepth) continue;
                
                float4 curGiAo = getColorSampler(sourceGISampler,currentCoords);
				if(firstPass) {
					curGiAo.rgb = max(curGiAo.rgb,refColor.rgb*min(1.0-op,0.9));
				}
                
                // Distance weight | gi,ao,ssr 
                float3 weight = 1.0/(1.0+dist*dist);
                
            	
#if DX9_MODE
        // No checkerboard rendering on DX9 for now
#else
				if(dist>0 && firstPass) {
			        if(iCheckerboardRT==1 && halfIndex(currentCoords)!=framecount%2) {
			            continue;
			        }
			        if(iCheckerboardRT==2 && quadIndex(currentCoords)!=framecount%4) {
			            continue;
			        }
            	}
#endif
				
                { // AO dist to 0.5
                    float aoMidW = smoothstep(0,1,curGiAo.a);
                    if(curGiAo.a<0.5) aoMidW = 1.0-aoMidW;
                    weight.y += aoMidW*15;
                }
                
                float b = getBrightness(curGiAo.rgb);
                    
                { // GI brightness dist
                    //float b = getBrightness(curGiAo.rgb);
                    float d = 1.0-abs(b-refB);
                    weight.x *= 0.5+d;
                }
                
                if(firstPass) {
                	float colorDist = maxOf3(saturate(curGiAo.rgb-refColor.rgb));
                    weight.xy *= 0.1+saturate(1.1-colorDist);
                }
                
                
                
                
                float3 normal = getNormal(currentCoords);
                float3 t = normal-refNormal;
                float dist2 = max(dot(t,t), 0.0);
                float nw = min(exp(-(dist2)/0.5), 1.0);
                
				curGiAo.rgb *= saturate(0.5+nw);
                
                weight.xy *= nw*nw;
                weight.z *= safePow(nw,100);
                
                
                {
                	float aoDist = 1.0-abs(curGiAo.a-previousColor.a);
	                weight.y *= 0.5+aoDist*10;
                }
	                    
                
                { // Depth weight
                    float t = (1.0-refDepth)*abs(depth-refDepth)*0.2;
                    float dw = saturate(0.007-t);
                    
                    weight *= dw;
                }
                
                {
                	float colorDist = 1.0-maxOf3(abs(curGiAo.rgb-previousColor.rgb));
	    			weight.x *= colorDist;
                }
                
                
                
                giAo.rgb += curGiAo.rgb*weight.x;
                giAo.a += curGiAo.a*weight.y;
                
                
                if(bSSR && (bSSRFilter || dist<1)) {
                    currentCoords = coords+delta*pixelSize.xy;
                    
                    float4 ssrColor = getColorSampler(sourceSSRSampler,currentCoords);
                    if(maxOf3(ssrColor.rgb)==0) {
                    	weight.z = 0;
                    }
                    
                    if(firstPass) ssrColor.rgb *= ssrColor.a<1.0?0.8:1;
                    
                    weight.z *= 0.1+maxOf3(ssrColor.rgb);
                    
                    if(firstPass) {
                        weight.z *= ssrColor.a;
                        
                        float colorDist = 1.0-maxOf3(abs(ssrColor.rgb-previousSSRm.rgb));
	                    weight.z *= 0.5+colorDist*20;
                    }
                    
                    if(firstPass && dist>0) {
                    	weight.z *= maxOf3(saturate(refSSR.rgb-ssrColor.rgb));
                    }
	                    
                    
                    
                    ssr += ssrColor.rgb*weight.z;

                } else {
                	weight.z = 0;
                }
                
                weightSum += weight;
                
                        
            } // end for y
        } // end for x
        
        giAo.rgb /= weightSum.x;
        giAo.a /= weightSum.y;
                
        if(weightSum.z>0) {
        	ssr /=  weightSum.z;
        } else {
        	ssr = 0;
        }
        
        
        if(firstPass) {
            float4 previousPass = getColorSampler(giAccuSampler,previousCoords);
            
            if(op<1) {
	            {
	                float motionDistance = distance(previousCoords*BUFFER_SIZE,coords*BUFFER_SIZE)*0.025;
	                op = saturate(op+motionDistance*fTempoGS);
	            }
	            
	            
            	float giP = (1.1-getPureness(giAo.rgb))*(1.0-op);
            	float pP = (1.1-getPureness(previousPass.rgb))*(op);
            	giAo.rgb = (giAo.rgb*giP+previousPass.rgb*pP)/(giP+pP);
            }
            
            outGI = lerp(previousPass,giAo,op);
            
            

            if(bSSR) {
                op = 1.0/iFrameAccu;
                    
                float3 ssrColor;
                
                {
                    float b = getBrightness(ssr.rgb);
                    float pb = getBrightness(previousSSRm.rgb);
                    op = saturate(op+saturate(0.5*(0.1+saturate(b/pb)))*(1.0/safePow(iFrameAccu,0.5)*0.5));
                    
                    float motionDistance = max(0,0.01*(distance(previousCoords.xy*BUFFER_SIZE,coords.xy*BUFFER_SIZE)-1.0));
                    float colorDist = fTempoGS*motionDistance;//*maxOf3(abs(previousSSRm.rgb-ssr.rgb));
                    op = saturate(op+colorDist*24);
                    
                    
                }
                
                if(weightSum.z>0) {
	                ssrColor = lerp(
                        previousSSRm.rgb,
                        ssr.rgb,
                        saturate(op*(0.5+weightSum.z*50)*0.25*(1.2-maxOf3(ssr.rgb)))
                    );
                } else {
                    ssrColor = previousSSRm.rgb;
                }
                
                outSSR = float4(ssrColor,1.0);
            } else {
                outSSR = 0;
            }
        } else {
            
            outGI = giAo;
            if(bSSR) {
                outSSR = float4(ssr.rgb,1.0);
            }
        }


        
        
    }
    
    void PS_SmoothPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0, out float4 outSSR : SV_Target1) {
		smooth(giPassSampler,ssrPassSampler,coords,outGI,outSSR, true);
    }
    
    void PS_AccuPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0, out float4 outSSR : SV_Target1) {
        smooth(giSmoothPassSampler,ssrSmoothPassSampler,coords,outGI,outSSR, false);
    }
    
    float computeColorPreservationGI(float colorBrightness, float giBrightness) {
        return 1.0;
    }
    
    float computeColorPreservationAO(float colorBrightness, float giBrightness) {
        float colorPreservation = 1.0;
        return colorPreservation;
    } 
    
    float computeAo(float ao,float colorBrightness, float giBrightness) {
    	
        //giBrightness = smoothstep(0,0.5,giBrightness);
        
        //ao = fAOMultiplier-(1.0-ao)*fAOMultiplier;
        ao = 1.0-saturate((1.0-ao)*fAOMultiplier);
        
		if(fAOBoostFromGI>0) {
			ao = lerp(ao,ao*giBrightness,fAOBoostFromGI);
        }
        
        
        
        
        ao = safePow(ao,fAOPow);
        
        ao = saturate(ao);
        ao = lerp(ao,1.0,saturate(giBrightness*fAoProtectGi*4.0));
        ao = lerp(ao,1.0,saturate(safePow(colorBrightness,fAOLightPower)*fAOLightProtect*2.0));
        ao = lerp(ao,1.0,saturate((1.0-colorBrightness)*fAODarkProtect*2.0));
        
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
        
        float roughness = getRT(coords).x;
        
        float rCoef = lerp(1.0,saturate(1.0-roughness*10),fMergingRoughness);
        float coef = fMergingSSR*(1.0-brightness)*rCoef;
        
        return ssr.rgb*coef;
            
    }

    void PS_UpdateResult(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outResult : SV_Target) {
        float depth = getDepth(coords);
        float3 color = getColor(coords).rgb;
        float3 colorHSV = RGBtoHSV(color);
        
        if(depth>fSkyDepth) {
            outResult = float4(color,1.0);
        } else {   
            float originalColorBrightness = maxOf3(color);
#if AMBIENT_ON
            if(iRemoveAmbientMode==0 || iRemoveAmbientMode==2) {
                color = filterAmbiantLight(color);
            }
#endif
            
            color = saturate(color*fBaseColor);
            
            
            
            float4 passColor = getColorSampler(giAccuSampler,coords);
            
            float3 gi = passColor.rgb;
            float3 giHSV = RGBtoHSV(gi);
            float giBrightness =  getBrightness(gi);            
            colorHSV = RGBtoHSV(color);
           
            float colorBrightness = getBrightness(color);
            
            if(giBrightness>0) { // Apply hue to source color 
            
                float3 newColor = colorBrightness * gi / giBrightness;
                
                float coef = saturate(
                    fGIHueBiais
                    *80.0 // base
                    *lerp(1,giHSV.y,0.75) // gi saturation
                    *clamp((1.0-colorHSV.y)*20,0,6)
                    *giHSV.z
                    *(1.0-sqrt(originalColorBrightness)) // color brightness bonus
                    *(1.0-originalColorBrightness*0.8) // color brightness
                    *(1.0-giBrightness) // gi brightness
                    *giBrightness
                    *sqrt(originalColorBrightness)
                );                  
                color = lerp(color,newColor,coef);
            }
            
            // Base color
            float3 result = color;
            
            // GI
            
            // Dark areas
        	result += safePow(result,fGIDarkPower)*gi*saturate((1.0-colorBrightness)*fGIDarkMerging*2);
            
            
            // Light areas
            result += result*gi*saturate(colorBrightness*fGILightMerging*2)*min(giBrightness,1.0-colorBrightness);
            
            
        	// Overbright
        	if(fGIOverbrightToWhite>0) {
        		float b = maxOf3(result);
	        	if(b>1) {
	        		result += (b-1)*fGIOverbrightToWhite;
	        	}
        	}
            
            // Mixing
            result = lerp(color,result,fGIFinalMerging);
            
            // Apply AO after GI
            {
                float resultB = getBrightness(result);
                float ao = passColor.a;
                ao = computeAo(ao,resultB,giBrightness);
                result *= ao;
            }
            
            
            outResult = float4(saturate(result),1.0);
            
            
        }
    }
    

    
    void PS_DisplayResult(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outPixel : SV_Target0)
    {        
        float3 result = 0;
        
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
            if(fDistanceFading<1.0 && depth>fDistanceFading) {
                float diff = depth-fDistanceFading;
                float max = 1.0-fDistanceFading;
                float ratio = diff/max;
                result = result*(1.0-ratio)+color*ratio;
            }
            
            result = saturate(result);
            
        } else if(iDebug==DEBUG_GI) {
            float4 passColor =  getColorSampler(giAccuSampler,coords);
            float3 gi =  passColor.rgb;
            
            if(bDebugShowIntensity) {
            	float3 color = getColor(coords).rgb;
#if AMBIENT_ON
	            if(iRemoveAmbientMode==0 || iRemoveAmbientMode==2) {
	                color = filterAmbiantLight(color);
	            }
#endif
            
            	color = saturate(color*fBaseColor);
            	
        		float colorBrightness = getBrightness(color);
        		float giBrightness = getBrightness(gi);
				
            	float3 r = 0;
            	// Dark areas
	        	r += safePow(color,fGIDarkPower)*gi*saturate((1.0-colorBrightness)*fGIDarkMerging*2);
	            
	            
	            // Light areas
	            result += color+r*gi*saturate(colorBrightness*fGILightMerging*2)*min(giBrightness,1.0-colorBrightness);
            
            	if(fGIOverbrightToWhite>0) {
	        		float b = maxOf3(colorBrightness+r);
		        	if(b>1) {
		        		r += (b-1)*fGIOverbrightToWhite;
		        	}
	        	}
            	
            	r *= fGIFinalMerging;
            	
            	r = saturate(r);
            	
            	gi = r;
            }
                    	
        	result = gi;
            
        } else if(iDebug==DEBUG_AO) {
            float4 passColor =  getColorSampler(giAccuSampler,coords);
            float ao = passColor.a;
            float giBrightness = getBrightness(passColor.rgb);
	        if(bDebugShowIntensity) {

	            
	            float3 color = getColor(coords).rgb;
	            float colorBrightness = getBrightness(color);
	            
	            ao = computeAo(ao,colorBrightness,giBrightness);
	            
	            result = ao;
            } else {
            	//giBrightness = smoothstep(0,0.5,giBrightness);
		        
		        ao = 1.0-saturate((1.0-ao)*fAOMultiplier);
    			if(fAOBoostFromGI>0) {
    				ao = lerp(ao,ao*giBrightness,fAOBoostFromGI);
        		}
        		
    
    			ao = safePow(ao,fAOPow);
    
				ao = saturate(ao);
    			ao = 1.0-saturate((1.0-ao)*fAOMultiplier);
				result = ao;
			}
            
        } else if(iDebug==DEBUG_SSR) {
        	float4 ssr = getColorSampler(ssrAccuSampler,coords);
        	
        	if(bDebugShowIntensity) {
        		float3 color = getColorSampler(resultSampler,coords).rgb;
        		float colorBrightness = getBrightness(color);
				ssr = computeSSR(coords,colorBrightness);
        	}
        	result = ssr.rgb;
            
        } else if(iDebug==DEBUG_ROUGHNESS) {
            float3 RT = getColorSampler(RTSampler,coords).xyz;
            //result = RT.x>fSkyDepth?1.0:0.0;
            
            result = RT.x;
        } else if(iDebug==DEBUG_DEPTH) {
            float depth = getDepth(coords);
            result = depth;
            
        } else if(iDebug==DEBUG_NORMAL) {
            result = getColorSampler(normalSampler,coords).rgb;
            
        } else if(iDebug==DEBUG_SKY) {
            float depth = getDepth(coords);
            result = depth>fSkyDepth?1.0:0.0;
            
            result = getColorSampler(rayColorSampler,coords).rgb;          
            //result = getColorSampler(sphereSampler,coords).rgb;  
      
        } else if(iDebug==DEBUG_MOTION) {
            float2  motion = getPreviousCoords(coords);
            motion = 0.5+(motion-coords)*25;
            result = float3(motion,0.5);
            
        } else if(iDebug==DEBUG_AMBIENT) {
#if AMBIENT_ON
            result = getRemovedAmbiantColor();
#else   
            result = 0;
#endif    
        }
        
        outPixel = float4(result,1.0);
    }


// TEHCNIQUES 
    
    technique DH_UBER_RT <
        ui_label = "DH_UBER_RT 0.18.1-dev";
        ui_tooltip = 
            "_____________ DH_UBER_RT _____________\n"
            "\n"
            " ver 0.18.1-dev (2024-04-14)  by AlucardDH\n"
#if DX9_MODE
            "         DX9 limited edition\n"
#endif
            "\n"
            "______________________________________";
    > {
#if AMBIENT_ON
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_SavePreviousAmbientPass;
            RenderTarget = previousAmbientTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_AmbientPass;
            RenderTarget = ambientTex;
            
            ClearRenderTargets = false;
                        
            BlendEnable = true;
            BlendOp = ADD;
            SrcBlend = SRCALPHA;
            SrcBlendAlpha = ONE;
            DestBlend = INVSRCALPHA;
            DestBlendAlpha = ONE;
        }
#endif
        // Normal Roughness
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_RT_save;
            RenderTarget = previousRTTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_DRT;
            RenderTarget = RTTex;
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
        /*
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
        */
        
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_GILightPass;
            RenderTarget = giPassTex;
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
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_DisplayResult;
        }
    }
}