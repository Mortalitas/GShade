////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                    MMMMMMMM               MMMMMMMM                     ////
////                    M:::::::M             M:::::::M                     ////
////                    M::::::::M           M::::::::M                     ////
////                    M:::::::::M         M:::::::::M                     ////
////                    M::::::::::M       M::::::::::M                     ////
////                    M:::::::::::M     M:::::::::::M                     ////
////                    M:::::::M::::M   M::::M:::::::M                     ////
////                    M::::::M M::::M M::::M M::::::M                     ////
////                    M::::::M  M::::M::::M  M::::::M                     ////
////                    M::::::M   M:::::::M   M::::::M                     ////
////                    M::::::M    M:::::M    M::::::M                     ////
////                    M::::::M     MMMMM     M::::::M                     ////
////                    M::::::M               M::::::M                     ////
////                    M::::::M               M::::::M                     ////
////                    M::::::M               M::::::M                     ////
////                    MMMMMMMM               MMMMMMMM                     ////
////                                                                        ////
////                          MShaders <> by TreyM                          ////
////                             lENS DIFFUSION                             ////
////                             Verision: 1.0                              ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//// DO NOT REDISTRIBUTE WITHOUT PERMISSION                                 ////
////////////////////////////////////////////////////////////////////////////////

// FILE SETUP //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#include "ReShade.fxh"

// Configure MShadersMacros.fxh
//#define  CATEGORIZE  // Enable UI category macros
#include "MShadersMacros.fxh"

// Configure MShadersCommon.fxh
#define _TIMER       // Enable ReShade timer
#define _DITHER      // Enable Dither function
#define _DEPTH_CHECK // Enable checking for depth buffer
#include "MShadersCommon.fxh"

// UI VARIABLES ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
UI_INT_S (DIFF_BLEND,  "Diffusion Amount", "",   0, 100, 75, 0)
UI_INT_S (TINT_AMOUNT, "Lens Coating", "Applies a color tint to the diffusion", 0, 100, 33, 1)
UI_COLOR (TINT_COLOR,  "Lens Coating Color", "", 0.25, 0.0, 1.0, 1)

#ifndef ENABLE_DYNAMIC_DIFFUSION
    // Dynamically adjusts the amount of diffusion based on average scene luminance
    #define ENABLE_DYNAMIC_DIFFUSION 1
#endif


// FUNCTIONS ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define _BLUR_BOUNDS
#define _LOWER_BOUND 0.675
#define _UPPER_BOUND 0.325
#define _LEFT_BOUND  0.325
#define _RIGHT_BOUND 0.675
#include "MShadersGaussianBlurBounds.fxh"
#include "MShadersAVGen.fxh"


// SHADERS /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// DOWNSCALE /////////////////////////////////////
void PS_Downscale(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = tex2D(TextureColor, SCALE(coord, 0.25)).rgb;
}

// HORIZONTAL BLUR ///////////////////////////////
void PS_BlurH(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = tex2D(TextureBlur1, coord).rgb;

    color  = Blur6H(color, TextureBlur1, coord);
}

// VERTICAL BLUR /////////////////////////////////
void PS_BlurV(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = tex2D(TextureBlur2, coord).rgb;

    color  = Blur6V(color, TextureBlur2, coord);
}

// UPSCALE ///////////////////////////////////////
void PS_Upscale(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = tex2Dbicub(TextureBlur1, SCALE(coord, 4.0)).rgb;

    color += Dither(color, coord, BitDepth);
}

// COMBINE ///////////////////////////////////////
void PS_Combine(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    float3 blur, orig, tint;
    float  luma, avg;

    // Grab the scene average luminance
    avg    = GetLuma(pow(max(avGen::get(), 0.0), 0.75));

    // Grab the original scene color
    orig   = tex2D(TextureColor, coord).rgb;

    // Grab the blurred scene color
    blur   = tex2D(TextureBlur2, coord).rgb;

    // Grab the per-pixel scene luminance
    luma   = GetLuma(orig);

    // Prepare the luma mask
    #if (ENABLE_DYNAMIC_DIFFUSION !=0)
        // Dynamic mask based on average scene luminance
        luma   = 1-pow(max(luma, 0.0), lerp(0.01, 1.15, avg));
    #else
        // static luma mask
        luma   = 1-pow(max(luma, 0.0), 0.425);
    #endif

    // Prepare the diffusion tint
    tint   = lerp(1.0, TINT_COLOR, TINT_AMOUNT * 0.01);

    // Apply the tint without affecting diffusion brightness
    blur   = (blur * tint) - GetLuma(blur * tint) + GetLuma(blur);

    // Blend the diffusion into the original scene color
    color  = lerp(orig, lerp(orig, blur, luma), DIFF_BLEND * 0.01);

    // Dither to kill any banding
    color += Dither(color, coord, BitDepth);
}

// TECHNIQUES //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
TECHNIQUE    (LensDiffusion, "Lens Diffusion", "",
    PASS_AVG ()
    PASS_RT  (VS_Tri, PS_Downscale, TexBlur1)
    PASS_RT  (VS_Tri, PS_BlurH,     TexBlur2)
    PASS_RT  (VS_Tri, PS_BlurV,     TexBlur1)
    PASS_RT  (VS_Tri, PS_BlurH,     TexBlur2)
    PASS_RT  (VS_Tri, PS_BlurV,     TexBlur1)
    PASS_RT  (VS_Tri, PS_Upscale,   TexBlur2)
    PASS     (VS_Tri, PS_Combine))
