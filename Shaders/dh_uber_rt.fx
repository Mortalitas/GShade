////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_UBER_RT 0.17.3.1 (2024-03-05)
//
// This shader is free, if you paid for it, you have been ripped and should ask for a refund.
//
// This shader is developed by AlucardDH (Damien Hembert)
//
// Get more here : https://alucarddh.github.io
// Join my Discord server for news, request, bug reports or help : https://discord.gg/V9HgyBRgMW
//
////////////////////////////////////////////////////////////////////////////////////////////////
#include "Reshade.fxh"

// VISIBLE PERFORMANCE SETTINGS /////////////////////////////////////////////////////////////////

// Define the working resolution of the intermediate steps of the shader
// Default is 0.5. 1.0 for full-res, 0.5 for quarter-res
// It can go lower for a performance boost like 0.25 but the image will be more blurry and noisy
// It can go higher (lile 2.0) if you have GPU to spare
#ifndef DH_RENDER_SCALE
 #define DH_RENDER_SCALE 0.5
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
#define BUFFER_SIZE3 int3(INPUT_WIDTH,INPUT_HEIGHT,RESHADE_DEPTH_LINEARIZATION_FAR_PLANE*fDepthMultiplier)


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
namespace DH_UBER_RT_01731 {

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
    texture previousRTTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA8; };
    sampler previousRTSampler { Texture = previousRTTex; };
    texture RTTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA8; };
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
    texture rayColorTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; MipLevels = 6; };
    sampler rayColorSampler { Texture = rayColorTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    texture giPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; MipLevels = 6; };
    sampler giPassSampler { Texture = giPassTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    texture giSmoothPassTex { Width = RENDER_WIDTH; Height = RENDER_HEIGHT; Format = RGBA8; MipLevels = 6; };
    sampler giSmoothPassSampler { Texture = giSmoothPassTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    texture giAccuTex { Width = INPUT_WIDTH; Height = INPUT_HEIGHT; Format = RGBA16F; MipLevels = 6; };
    sampler giAccuSampler { Texture = giAccuTex; MinLOD = 0.0f; MaxLOD = 5.0f;};

    // SSR textures
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
    uniform float fTest <ui_category="Test";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0.0;
    uniform float fTest2 <ui_category="Test";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 25.0;
        ui_step = 0.001;
    > = 0.0;
    uniform float fTest3 <ui_category="Test";
        ui_type = "slider";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
    > = 0;
    uniform int iTest <ui_category="Test";
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
    
// DEPTH

    uniform float fDepthMultiplier <
        ui_type = "slider";
        ui_category = "Common Depth";
        ui_label = "Depth multiplier";
        ui_min = 0.1; ui_max = 10;
        ui_step = 0.01;
        ui_tooltip = "Multiply the depth returned by the game\n"
                    "Can help to make mutitple shaders work together";
    > = 1.0;

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
    
    uniform int iRTCheckHitPrecision <
        ui_category = "Common RT";
        ui_type = "slider";
        ui_label = "RT Hit precision";
        ui_min = 1; ui_max = 6;
        ui_step = 1;
        ui_tooltip = "Lower=better performance, less quality\n"
                    "Higher=better detection of small geometry, less performances\n"
                    "/!\\ HAS A VARIABLE INPACT ON PERFORMANCES\n";
    > = 1;
    
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
    

    
#if DX9_MODE
	#define iRayStepPrecision 0
#else
    uniform int iRayStepPrecision <
        ui_type = "slider";
        ui_category = "Common RT";
        ui_label = "Step Precision";
        ui_min = 0; ui_max = 16;
        ui_step = 1;
        ui_tooltip = "Define the length of the steps during ray tracing.\n"
                    "Lower=better performance, less quality\n"
                    "Higher=better detection of small geometry, less performances\n"
                    "/!\\ HAS A VARIABLE INPACT ON PERFORMANCES";
    > = 8;
#endif

#if !OPTIMIZATION_ONE_LOOP_RT
    uniform int iRTMaxRays <
        ui_type = "slider";
        ui_category = "Common RT";
        ui_label = "Max rays per pixel";
        ui_min = 1; ui_max = 6;
        ui_step = 1;
        ui_tooltip = "Maximum number of rays from 1 pixel if the first miss\n"
                    "Lower=Darker image, better performance\n"
                    "Higher=Less noise, brighter image\n"
                    "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 2;
    
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
    > = 0.2;
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
    > = 0.35;
    
    uniform float fGIDarkAmplify <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "Dark color compensation";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Brighten dark colors, useful in dark corners";
    > = 0.50;
    
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
    > = 0.4;
    uniform float fGICvB <
        ui_type = "slider";
        ui_category = "GI";
        ui_label = "Color absorption";
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
    > = 0.25;
    
    uniform float fAOMultiplier <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Multiplier";
        ui_min = 0.0; ui_max = 5;
        ui_step = 0.01;
        ui_tooltip = "Define the intensity of AO";
    > = 1.5;
    
    uniform int iAODistance <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Distance";
        ui_min = 0; ui_max = BUFFER_WIDTH;
        ui_step = 1;
    > = BUFFER_WIDTH/8;
    
    uniform float fAOPow <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Pow";
        ui_min = 0.001; ui_max = 2.0;
        ui_step = 0.001;
        ui_tooltip = "Define the intensity of the gradient of AO";
    > = 1.25;
    
    uniform float fAOLightProtect <
        ui_type = "slider";
        ui_category = "AO";
        ui_label = "Light protection";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.01;
        ui_tooltip = "Protection of bright areas to avoid washed out highlights";
    > = 0.50;
    
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
    > = 0.50;
    


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
        ui_min = 1; ui_max = 8;
        ui_step = 1;
        ui_tooltip = "Define the max distance of smoothing.\n"
                    "Higher:less noise, less performances\n"
                    "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 2;
    
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
    
    float3 getDRT(float2 coords) {
        float3 drt = getDepth(coords);
        drt.yz = getColorSampler(RTSampler,coords).xy;
        drt.z = (0.1+drt.z)*drt.x*320;
        
        return drt;
    }
    
    bool inScreen(float3 coords) {
        return coords.x>=0.0 && coords.x<=1.0
            && coords.y>=0.0 && coords.y<=1.0
            && coords.z>=0.0 && coords.z<=1.0;
    }
    
    float3 getWorldPosition(float2 coords,float depth) {
        float3 result = float3((coords-0.5)*depth,depth);
        result *= BUFFER_SIZE3;
        return result;
    }
    
    float3 getWorldPositionForNormal(float2 coords) {
        float3 drt = getDRT(coords);
        if(fNormalRoughness>0) {
            drt.x += drt.x*drt.y*fNormalRoughness*0.1;
        }
        float3 result = float3((coords-0.5)*drt.x,drt.x);
        if(drt.x<fWeaponDepth) {
            result.z /= RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
        }
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
        
        // roughness decrease with depth
        roughness = refDepth>0.5 ? 0 : lerp(roughness,0,refDepth/0.5);
        
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
        RT.y += thicknessPass(coords,depth);
        
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
    
    
    void PS_RayColorPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0) {

        float3 color = getColor(coords).rgb;
 
#if AMBIENT_ON
        if(iRemoveAmbientMode<2) {  
            color = filterAmbiantLight(color);
        }
#endif

		float3 colorHSV = RGBtoHSV(color);
		if(fSaturationBoost>0 && colorHSV.z*colorHSV.y>0.05) {
			colorHSV.y = (colorHSV.y+fSaturationBoost);
			color = HSVtoRGB(colorHSV);
		}
        
        float2 previousCoords = getPreviousCoords(coords);
        
        if(fGIBounce>0.0) {
        	float3 previousColor = getColorSampler(resultSampler,previousCoords).rgb;
        	color = lerp(color,previousColor,fGIBounce);
        }
        

        float b = getBrightness(color);
        float originalB = b;
        
        if(iGIRayColorMode==1) { // smoothstep
            b *= smoothstep(fGIRayColorMinBrightness,1.0,b);
        } else if(iGIRayColorMode==2) { // linear
            b *= saturate(b-fGIRayColorMinBrightness)/(1.0-fGIRayColorMinBrightness);
        } else if(iGIRayColorMode==3) { // gamma
            b *= safePow(saturate(b-fGIRayColorMinBrightness)/(1.0-fGIRayColorMinBrightness),2.2);
        }
        
        
        float3 result = originalB>0 ? color * b / originalB : 0;
        
        if(fGIDarkAmplify>0) {
        	float3 colorHSV = RGBtoHSV(result);
            result *= 1.0+fGIDarkAmplify*(1.0-maxOf3(result))*4.0*(0.4+colorHSV.y*0.6);
        }   
        
        
		
        if(fGIBounce>0.0) {
        	float3 gi = getColorSampler(giAccuSampler,previousCoords).rgb;
            result += gi*(1.0-b)*fGIBounce*0.5;
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
    
    
    bool hittingSSR(float deltaZ, float3 DRT, float3 incrementVector) {
        if(length(incrementVector)<1) {
            return false;
        }
        return (deltaZ<=0 && -deltaZ<DRT.z*0.1);
    }
    
    bool hittingGI(float deltaZ, float3 DRT) {
        return deltaZ<=0.5 && -deltaZ<DRT.z*DRT.x;
    }
    
    int crossing(float deltaZbefore, float deltaZ) {      
        if(deltaZ<=0 && deltaZbefore>0) return -1;
        if(deltaZ>=0 && deltaZbefore<0) return 1;
        return  0;
    }
    
    RTOUT trace(float3 refWp,float3 incrementVector,float startDepth,bool ssr) {
    
        RTOUT result;
        
        int rayStepPrecision = ssr ? 600*startDepth : iRayStepPrecision;
        float stepRatio;
        float stepLength = 0.01/(1.0+rayStepPrecision);
        
        if(!ssr) stepLength *= 0.5;
        
        float3 currentWp = refWp;
        float3 refNormal = getNormal(getScreenPosition(currentWp).xy);

#if OPTIMIZATION_ONE_LOOP_RT
		if(!ssr)
			incrementVector = reflect(incrementVector,refNormal);
#endif
        
        incrementVector *= stepLength;
#if DX9_MODE
		incrementVector *= 2.0;
#endif
        incrementVector *= 1+2000*startDepth;
        
        
        
        float deltaZ = 0.0;
        float deltaZbefore = 0.0;        
        
        bool startWeapon = startDepth<fWeaponDepth;
        float weaponLimit = fWeaponDepth*BUFFER_SIZE3.z;
        
        bool outSource = false;
        
        int step = 0;
        
        while(!outSource && step<4)
        {
            currentWp += incrementVector;
            
            float3 screenCoords = getScreenPosition(currentWp);
            
            bool outScreen = !inScreen(screenCoords) && (!startWeapon || currentWp.z<weaponLimit);
            if(outScreen || (step>0 && deltaZ<0)) {
            	result.status = RT_MISSED_FAST;
	            return result;                
            }
            
            float3 DRT = getDRT(screenCoords.xy);
            if(DRT.x>fSkyDepth) {
                result.status = RT_HIT_SKY;
                result.wp = currentWp;
            }       
            
            float3 screenWp = getWorldPosition(screenCoords.xy,DRT.x);
            
            deltaZ = screenWp.z-currentWp.z;
            
            outSource = ssr ? !hittingSSR(deltaZ,DRT,incrementVector) : !hittingGI(deltaZ,DRT);
            step++;                
        }        
            
        deltaZbefore = deltaZ;
        
        float3 crossedWp = 0;
        
        int searching = -1;
        float screenZBefore = 0;
        
        result.status = RT_MISSED;
        
        int maxSearching = ssr?32:iRTCheckHitPrecision;
        
        [loop]
        do {

            currentWp += incrementVector;
            
            float3 screenCoords = getScreenPosition(currentWp);
            
            bool outScreen = !inScreen(screenCoords) && (!startWeapon || currentWp.z<weaponLimit);
            if(outScreen) {
                break;
            }
            
            float3 DRT = getDRT(screenCoords.xy);
            float3 screenWp = getWorldPosition(screenCoords.xy,DRT.x);
            
            deltaZ = screenWp.z-currentWp.z;
            
            if(DRT.x>fSkyDepth && result.status<RT_HIT_SKY) {
                result.status = RT_HIT_SKY;
                result.wp = currentWp;
            }
            
            
            bool crossed = crossing(
                deltaZbefore,
                deltaZ
            );
            
            if(crossed) {
                crossedWp = currentWp;
                
                searching += 1;
                
                if(ssr ? hittingSSR(deltaZ,DRT,incrementVector) : hittingGI(deltaZ,DRT)) {
                    if(bGIAvoidThin && !ssr && DRT.z<0.2*currentWp.z) {
                    } else {
                        result.status = RT_HIT;
                        result.DRT = DRT;
                        result.deltaZ = deltaZ;
                        result.wp = currentWp;
                    }
                }
                
                if(searching<maxSearching) {
                    currentWp -= incrementVector;
                    incrementVector *= 0.5;
                    deltaZ = deltaZbefore;

                } else if(result.status==RT_HIT) {
                    return result;

                } else {
                    searching = -1;
                }

            }
            
            deltaZbefore = deltaZ;
            screenZBefore = screenWp.z;
            
            if(searching==-1) {
            	if(ssr) {
            		float l = max(1,abs(deltaZ)*0.5);
            		incrementVector = normalize(incrementVector)*l;
            	} else {
      
	                float2 r = randomCouple(screenCoords.xy);
	                
	                stepRatio = 1.00+DRT.x+r.y;
	                
	                incrementVector *= stepRatio;
                }
            }
            step++;

        } while(step<(ssr?30:16));

        if(ssr && result.status<RT_HIT) {
            result.wp = currentWp;
        }
        return result;
    }

// GI

    void PS_GILightPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outGI : SV_Target0) {
        
        float3 DRT = getDRT(coords);
        if(DRT.x>fSkyDepth) {
            outGI = 0.0;
            return;
        }
        
        float3 refWp = getWorldPosition(coords,DRT.x);
        float3 refNormal = getNormal(coords);
        float3 refColor = getColor(coords).rgb;
        
        float2 previousCoords = getPreviousCoords(coords);
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
        
        float4 mergedGiColor = 0.0;
        float mergedAO = 0.0;
        
        float hits = 0;
        float aoHits = 0;
        
        
    #if !OPTIMIZATION_ONE_LOOP_RT
        int maxRays = iRTMaxRays;
        [loop]
        for(int rays=0;rays<2 || (rays<maxRays && maxRays<=iRTMaxRays*OPTIMIZATION_MAX_RETRIES_FAST_MISS_RATIO && (hits==0||mergedGiColor.a<fRTMinRayBrightness));rays++) {
    #else
        int maxRays = 0;
        int rays = 0;
    #endif
    		float3 rand = randomTriple(coords+float2(0.0,0.05*rays));
			
            float3 lightVector = normalize(rand-0.5);       
            
            RTOUT hitPosition = trace(refWp,lightVector,DRT.x,false);
            if(hitPosition.status == RT_MISSED_FAST) {
                maxRays++;
    #if !OPTIMIZATION_ONE_LOOP_RT
                continue;
    #endif
            }
                
            screenCoords = getScreenPosition(hitPosition.wp);
            
            float4 giColor = 0.0;                
                
            if(hitPosition.status==RT_HIT_SKY) {
                giColor = getColor(screenCoords.xy)*fSkyColor;
            } else if(hitPosition.status>=0 ) {
                float dist = distance(hitPosition.wp,refWp);
                
                if(hitPosition.status==RT_HIT_BEHIND) {
                //	float2 sphereCoords = (screenCoords.xy+1.0)/3.0;
				//	giColor = getColorSampler(sphereSampler,sphereCoords);
				
                } else {
                	giColor = getRayColor(screenCoords.xy);
                }
                
#if !DX9_MODE
                giColor *= clamp(pow(hitPosition.DRT.z,0.25)*0.4,0,2);
                
                
                // Distance atenuation
                float r = 0.85;
                giColor *= r+(1.0-r)/(1.0+max(0,dist*0.01 - saturate(2*abs(screenCoords.z))));

                // Light hit orientation
                float orientationSource = dot(lightVector,-refNormal);
                giColor *= saturate(0.25+saturate(orientationSource)*4);
#endif
                                    
                if(dist<iAODistance*DRT.x && DRT.x>=fWeaponDepth) {
                    aoHits += 1;
                        
                    float ao = dist/(iAODistance*DRT.x);
                    mergedAO += saturate(ao);
                }
                
                hits+=1.0;
            }
            
            mergedGiColor.rgb = max(giColor.rgb,mergedGiColor.rgb);
            mergedGiColor.a = getBrightness(mergedGiColor.rgb);
                
                
                
    #if !OPTIMIZATION_ONE_LOOP_RT
        }
    #endif
    
    

        if(aoHits<=0) {
            mergedAO = 1.0;
        } else {
            mergedAO /= aoHits;
        }
        
        //mergedGiColor = OKLchtoRGB(mergedGiColor);
        
        float opacity = 1.0/iFrameAccu;
            
        float previousB = getBrightness(previousFrame.rgb);
        float newB = getBrightness(mergedGiColor.rgb)*(1+hits);
        
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
        
        float3 DRT = getDRT(coords);
        if(DRT.x>fSkyDepth) {
            outColor = 0.0;
        } else {
            
            float3 targetWp = getWorldPosition(coords,DRT.x);            
            float3 targetNormal = getNormal(coords);
            
    
            float3 lightVector = reflect(targetWp,targetNormal)*0.01;
            
            RTOUT hitPosition = trace(targetWp,lightVector,DRT.x,true);
            
            if(hitPosition.status<RT_HIT_SKY) {
            	outColor = float4(0.0,0.0,0.0,0.1);
            } else if(hitPosition.status==RT_HIT_BEHIND) {
			//	float3 screenPosition = getScreenPosition(hitPosition.wp);
            //    outColor = getColorSampler(sphereSampler,(screenPosition.xy-0.5)*3 + 0.5);
            	outColor = 0;
			} else {
                float3 screenPosition = getScreenPosition(hitPosition.wp.xyz);
                float2 previousCoords = getPreviousCoords(screenPosition.xy);
                float3 c = getColorSampler(resultSampler,previousCoords).rgb;
                outColor = float4(c,1.0);
            }
        }
        
            
    }
    
    void fillSSR(
        float2 coords, out float4 outSSR
    ) {
        
    }
    
    void smooth(
        sampler sourceGISampler,
        sampler sourceSSRSampler,
        float2 coords, out float4 outGI, out float4 outSSR,bool firstPass
    ) {
        float3 pixelSize = float3(1.0/tex2Dsize(sourceGISampler),0);
        
        float3 refDRT = getDRT(coords);
        if(refDRT.x>fSkyDepth) {
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
        float4 previousSSR = bSSR && firstPass ? getColorSampler(ssrAccuSampler,previousCoords) : 0;

        
        float4 refSSR = getColorSampler(sourceSSRSampler,coords);
        
        float refB = getBrightness(refColor.rgb);
        
        float2 currentCoords;
        
        int2 delta;
        
        float2 offset = (randomCouple(coords.xy)-0.5)*pixelSize.xy;
        
        [loop]
        for(delta.x=-iSmoothRadius;delta.x<=iSmoothRadius;delta.x++) {
            [loop]
            for(delta.y=-iSmoothRadius;delta.y<=iSmoothRadius;delta.y++) {
                float dist = length(delta);
                if(dist>iSmoothRadius) continue;
                
                int step = dist;
                
                currentCoords = coords+delta*pixelSize.xy*(firstPass ? step : 1);
                
                
                
                if(dist>0 && firstPass) {
                	currentCoords += offset*step;
                }
            
                
                float3 DRT = getDRT(currentCoords);
                if(DRT.x>fSkyDepth) continue;
                
                float4 curGiAo = getColorSampler(sourceGISampler,currentCoords);

                
                // Distance weight | gi,ao,ssr 
                float3 weight = 1.0/(1.0+dist*dist);
				
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
                    weight.xy *= 0.5+colorDist*b*8;
                }
                
                
                
                
                float3 normal = getNormal(currentCoords);
                float3 t = normal-refNormal;
                float dist2 = max(dot(t,t), 0.0);
                float nw = min(exp(-(dist2)/0.5), 1.0);
                
                weight.xy *= nw*nw;
                weight.z *= safePow(nw,100);
                
                
                {
                	float colorDist = 1.0-maxOf3(abs(curGiAo.rgb-previousColor.rgb));
	                weight.x *= 0.5+colorDist*10;
                }
                
                {
                	float aoDist = 1.0-abs(curGiAo.a-previousColor.a);
	                weight.y *= 0.5+aoDist*10;
                }
	                    
                
                { // Depth weight
                    float t = (1.0-refDRT.x)*abs(DRT.x-refDRT.x)*0.2;
                    float dw = saturate(0.007-t);
                    
                    weight *= dw;
                }
                
                giAo.rgb += curGiAo.rgb*weight.x;
                giAo.a += curGiAo.a*weight.y;
                
                
                if(bSSR) {
                    currentCoords = coords+delta*pixelSize.xy;
                    
                    float4 ssrColor = getColorSampler(sourceSSRSampler,currentCoords);
                    
                    if(firstPass) ssrColor.rgb *= ssrColor.a<1.0?0.8:1;
                    
                    
                    weight.z *= 0.1+maxOf3(ssrColor.rgb);
                    
                    if(firstPass) {
                        weight.z *= ssrColor.a;
                        
                        float colorDist = 1.0-maxOf3(abs(ssrColor.rgb-previousSSR.rgb));
	                    weight.z *= 0.5+colorDist*20;
                    }
                    
                    ssr += ssrColor.rgb*weight.z;

                }
                
                weightSum += weight;
                
                        
            } // end for y
        } // end for x
        
        giAo.rgb /= weightSum.x;
        giAo.a /= weightSum.y;
        
        ssr /=  weightSum.z;
        
        if(firstPass) {
            float4 previousPass = getColorSampler(giAccuSampler,previousCoords);
            
            
            float op = 1.0/iFrameAccu;
            {
                float motionDistance = distance(previousCoords*BUFFER_SIZE,coords*BUFFER_SIZE)*0.025;
                op = saturate(op+motionDistance);
            }

            outGI = lerp(previousPass,giAo,op);
            

            if(bSSR) {
                float op = 1.0/iFrameAccu;
                    
                float3 ssrColor;
                
                {
                    float motionDistance = max(0,0.01*(distance(previousCoords*BUFFER_SIZE,coords*BUFFER_SIZE)-1.0));
                    float colorDist = motionDistance*maxOf3(abs(previousSSR.rgb-ssr.rgb));
                    op = saturate(op+colorDist*6);
                    float b = getBrightness(ssr.rgb);
                    float pb = getBrightness(previousSSR.rgb);
                    op = saturate(op+saturate(0.5*b/pb)*(1.0/safePow(iFrameAccu,0.5)*0.5));
                    
                }
                
                
                if(weightSum.z>0) {
                    ssrColor = lerp(
                        previousSSR.rgb,
                        ssr.rgb,
                        saturate(op*(0.5+weightSum.z*50)*0.25*(1.2-maxOf3(ssr.rgb)))
                    );
                } else {
                    ssrColor = previousSSR.rgb;
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
    	
        giBrightness = smoothstep(0,0.5,giBrightness);
        ao = lerp(ao,1.0,saturate(giBrightness*fAoProtectGi));
        
        if(fAOBoostFromGI>0) {
        	ao = min(ao,lerp(1.0,giBrightness,fAOBoostFromGI));
        }
        //ao = fAOMultiplier-(1.0-ao)*fAOMultiplier;
        ao = 1.0-saturate((1.0-ao)*fAOMultiplier);
        
        
        ao = safePow(ao,fAOPow);
        
        ao = saturate(ao);
        ao = lerp(ao,1,saturate(colorBrightness*fAOLightProtect*2.0));
        ao = lerp(ao,1,saturate((1.0-colorBrightness)*fAODarkProtect*2.0));
         
        return saturate(ao);
        
    }
    
    float3 computeSSR(float2 coords,float brightness) {
        float4 ssr = getColorSampler(ssrAccuSampler,coords);
        if(ssr.a==0) return 0;
        
        float3 ssrHSV = RGBtoHSV(ssr.rgb);
        
        float ssrBrightness = getBrightness(ssr.rgb);
        float ssrChroma = ssrHSV.y;
        
        float colorPreservation = lerp(1,safePow(brightness,2),1.0-safePow(1.0-brightness,10));
        
        ssr = lerp(ssr,ssr*0.5,saturate(ssrBrightness-ssrChroma));
        
        float3 DRT = getDRT(coords);
        float roughness = DRT.y;
        
        float rCoef = lerp(1.0,saturate(1.0-roughness*10),fMergingRoughness);
        float coef = fMergingSSR*(1.0-brightness)*rCoef;
        
        return ssr.rgb*coef;
            
    }
    
    float3 getColorForGI(float3 color) {
    	float brightness = getBrightness(color);
    	return lerp(brightness,color,fGICvB);
    }

    void PS_UpdateResult(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outResult : SV_Target) {
        float3 DRT = getDRT(coords);
        float3 color = getColor(coords).rgb;
        float3 colorHSV = RGBtoHSV(color);
        
        if(DRT.x>fSkyDepth) {
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
        	result += safePow(getColorForGI(result),fGIDarkPower)*gi*saturate((1.0-colorBrightness)*fGIDarkMerging*2);
            
            
            // Light areas
            result += getColorForGI(result)*gi*saturate(colorBrightness*fGILightMerging*2)*min(giBrightness,1.0-colorBrightness);
            
            
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
            float3 DRT = getDRT(coords);
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
            if(fDistanceFading<1.0 && DRT.x>fDistanceFading) {
                float diff = DRT.x-fDistanceFading;
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
	        	r += safePow(getColorForGI(color),fGIDarkPower)*gi*saturate((1.0-colorBrightness)*fGIDarkMerging*2);
	            
	            
	            // Light areas
	            result += getColorForGI(color+r)*gi*saturate(colorBrightness*fGILightMerging*2)*min(giBrightness,1.0-colorBrightness);
            
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
            if(bDebugShowIntensity) {

	            float giBrightness = getBrightness(passColor.rgb);
	            
	            float3 color = getColor(coords).rgb;
	            float colorBrightness = getBrightness(color);
	            
	            float ao = passColor.a;
	            ao = computeAo(ao,colorBrightness,giBrightness);
	            
	            result = ao;
            } else {
				result = passColor.a;
			}
            
        } else if(iDebug==DEBUG_SSR) {
        	float3 ssr = getColorSampler(ssrAccuSampler,coords).rgb;
        	if(bDebugShowIntensity) {
        		float3 color = getColorSampler(resultSampler,coords).rgb;
        		float colorBrightness = getBrightness(color);
				ssr = computeSSR(coords,colorBrightness);
        	}
        	result = ssr;
            
        } else if(iDebug==DEBUG_ROUGHNESS) {
            float3 RT = getColorSampler(RTSampler,coords).xyz;
            //result = RT.x>fSkyDepth?1.0:0.0;
            
            result = RT.x;
        } else if(iDebug==DEBUG_DEPTH) {
            float3 DRT = getDRT(coords);
            result = DRT.x;
            
        } else if(iDebug==DEBUG_NORMAL) {
            result = getColorSampler(normalSampler,coords).rgb;
            
        } else if(iDebug==DEBUG_SKY) {
            float depth = getDepth(coords);
            result = depth>fSkyDepth?1.0:0.0;
            
            //result = getColorSampler(rayColorSampler,coords).rgb;          
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
        } else if(iDebug==DEBUG_THICKNESS) {
            float3 DRT = getDRT(coords);
            
            result = DRT.z/320;
      
        }
        
        outPixel = float4(result,1.0);
    }


// TEHCNIQUES 
    
    technique DH_UBER_RT<
        ui_label = "DH_UBER_RT 0.17.3.1";
        ui_tooltip = 
            "_____________ DH_UBER_RT _____________\n"
            "\n"
            " ver 0.17.3.1 (2024-03-05)  by AlucardDH\n"
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