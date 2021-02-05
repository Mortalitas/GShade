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
////                                VHS-M                                   ////
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
#define  CATEGORIZE  // Enable UI category macros
#include "MShadersMacros.fxh"

#ifndef ENABLE_HIGH_RES
    // Disables a downscale step for higher res luma
    #define ENABLE_HIGH_RES 0
#endif

#ifndef ENABLE_DITHER
    #define ENABLE_DITHER 1
#endif

// Configure MShadersCommon.fxh
#if (ENABLE_DITHER != 0)
    #define _TIMER
    #define _DITHER
#endif
#include "MShadersCommon.fxh"

// UI VARIABLES ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define CATEGORY "VCR Settings" ////////////////////////////////////////////////
UI_COMBO (TAPE_SELECT, "Tape Selection", "Choose your video cassette type.", 2, 0,
    "Betamax\0"
    "S-VHS\0"
    "VHS\0"
    "Bad VHS\0"
    "U-Matic\0")
UI_INT_S (CHROMA_SHIFT, "Misalign Chroma", "Splits the color channels.", -100, 100, 50, 5)
UI_COMBO (SHIFT_MODE, "Misalignment Mode", "Determines the color combination for the split channels", 0, 1,
    "Red / Blue\0"
    "Green / Magenta\0"
    "Yellow / Violet\0")
#undef  CATEGORY




// FUNCTIONS ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#include "MShadersBlendingModes.fxh"

#define LUT_COUNT 5
#define LUT_SIZE  32
#include "MShadersLUTAtlas.fxh"


// DEFINITIONS /////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define VHS_LUMA   float2(0.5, 0.75)
#define VHS_CHROMA float2(0.5, 1.0)


// TEXTURES & SAMPLERS /////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
TEXTURE_FULL_SRC (TexVHSLUTs,    "VideoCassette.png", 1024, 160, RGBA8)
SAMPLER_UV       (TextureVHSLUTs, TexVHSLUTs,                       BORDER)


// SHADERS /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void PS_Copy(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = tex2D(TextureColor, coord).rgb;
}

void PS_Downscale1(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    // Downscale to VHS luma resolution
    color  = tex2D(TextureBlur2, SCALE(coord, VHS_LUMA)).rgb;
}

void PS_Upscale1(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    // Upscale back to 100%
    color  = tex2Dbicub(TextureBlur1, SCALE(coord, (1.0 / VHS_LUMA))).rgb;
}

void PS_SDLuma(PS_IN(vpos, coord), out float4 color : SV_Target)
{
    // Bake 50% scale luma into alpha channel
    color.rgb = tex2D(TextureBlur2, coord).rgb;
    color.a   = GetLuma(tex2D(TextureBlur2, coord).rgb);
}

void PS_Downscale2(PS_IN(vpos, coord), out float4 color : SV_Target)
{
    // Downscale RGB channels, leaving luma alone on the alpha channel
    color.rgb = tex2D(TextureBlur1, SCALE(coord, VHS_LUMA)).rgb;
    color.a   = tex2D(TextureBlur1, coord).a;
}

void PS_Downscale3(PS_IN(vpos, coord), out float4 color : SV_Target)
{
    // Downscale RGB channels, leaving luma alone on the alpha channel
    color.rgb = tex2D(TextureBlur2, SCALE(coord, VHS_CHROMA)).rgb;
    color.a   = tex2D(TextureBlur2, coord).a;
}

void PS_Downscale4(PS_IN(vpos, coord), out float4 color : SV_Target)
{
    // Downscale RGB channels, leaving luma alone on the alpha channel
    color.rgb = tex2D(TextureBlur1, SCALE(coord, VHS_CHROMA)).rgb;
    color.a   = tex2D(TextureBlur1, coord).a;
}

void PS_Upscale2(PS_IN(vpos, coord), out float4 color : SV_Target)
{
    // Upscale the RGB channels, leaving luma alone on the alpha channel
    color.rgb = tex2Dbicub(TextureBlur2, SCALE(coord, (1.0 / VHS_LUMA))).rgb;
    color.a   = tex2D(TextureBlur2, coord).a;
}

void PS_Upscale3(PS_IN(vpos, coord), out float4 color : SV_Target)
{
    // Upscale the RGB channels, leaving luma alone on the alpha channel
    color.rgb = tex2Dbicub(TextureBlur1, SCALE(coord, (1.0 / VHS_CHROMA))).rgb;
    color.a   = tex2D(TextureBlur1, coord).a;
}

void PS_Upscale4(PS_IN(vpos, coord), out float4 color : SV_Target)
{
    // Upscale the RGB channels, leaving luma alone on the alpha channel
    color.rgb = tex2Dbicub(TextureBlur2, SCALE(coord, (1.0 / VHS_CHROMA))).rgb;
    color.a   = tex2D(TextureBlur2, coord).a;
}

void PS_Combine(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    float4 buffer;
    float  luma, shift;

    shift = lerp(0.0, 0.002, CHROMA_SHIFT * 0.01);

    // Grab the 12.5% scaled color channels and shift them
    if      (SHIFT_MODE == 0) // Red / Blue
    {
        buffer.r   = tex2D(TextureBlur1, float2(coord.x + shift, coord.y)).r;
        buffer.g   = tex2D(TextureBlur1, coord).g;
        buffer.b   = tex2D(TextureBlur1, float2(coord.x - shift, coord.y)).b;
    }
    else if (SHIFT_MODE == 1) // Green / Magenta
    {
        buffer.r   = tex2D(TextureBlur1, float2(coord.x - shift, coord.y)).r;
        buffer.g   = tex2D(TextureBlur1, float2(coord.x + shift, coord.y)).g;
        buffer.b   = tex2D(TextureBlur1, coord).b;
    }
    else if (SHIFT_MODE == 2) // Yellow / Violet
    {
        buffer.r   = tex2D(TextureBlur1, coord).r;
        buffer.g   = tex2D(TextureBlur1, float2(coord.x - shift, coord.y)).g;
        buffer.b   = tex2D(TextureBlur1, float2(coord.x + shift, coord.y)).b;
    }

    // Grab the 50% scaled luma channel
    buffer.a   = tex2D(TextureBlur1, coord).a;

    // Grab the 12.5% scaled luma channel
    luma       = GetLuma(tex2D(TextureBlur1, coord).rgb);

    // Remove low res luma and replace it with "high res" luma
    buffer.rgb = buffer.rgb - luma;
    buffer.rgb = buffer.rgb + buffer.a;

    // Video levels
    buffer.rgb = lerp(16 / 255.0, 235 / 255.0, buffer.rgb);

    // Apply the LUT
    color      = LUTAtlas(pow(saturate(buffer.rgb), 0.8), TextureVHSLUTs, TAPE_SELECT, coord);

    #if (ENABLE_DITHER !=0)
        color     += Dither(color, coord, BitDepth);
    #endif
}


// TECHNIQUES //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#if (ENABLE_HIGH_RES < 1) // ENABLE_HIGH_RES = 1 disables a blur step on the luma channel for more sharpness
TECHNIQUE    (VHSM, "VHS-M",
             "Emulates clean, artifact-free, output of a VHS tape",

    // Store the backbuffer in TexBlur2
    PASS_RT  (VS_Tri, PS_Copy,       TexBlur2)

    // Downscale for lower res luma
    PASS_RT  (VS_Tri, PS_Downscale1, TexBlur1)
    PASS_RT  (VS_Tri, PS_Upscale1,   TexBlur2)
    PASS_RT  (VS_Tri, PS_Downscale1, TexBlur1)
    PASS_RT  (VS_Tri, PS_Upscale1,   TexBlur2)

    // Bake luma into alpha channel
    PASS_RT  (VS_Tri, PS_SDLuma,     TexBlur1)

    // Downscale again for even lower res chroma, preserving previous luma res
    PASS_RT  (VS_Tri, PS_Downscale2, TexBlur2)
    PASS_RT  (VS_Tri, PS_Downscale3, TexBlur1)
    PASS_RT  (VS_Tri, PS_Downscale4, TexBlur2)
    PASS_RT  (VS_Tri, PS_Upscale2,   TexBlur1)
    PASS_RT  (VS_Tri, PS_Upscale3,   TexBlur2)
    PASS_RT  (VS_Tri, PS_Upscale4,   TexBlur1)

    // Combine the VHS effect
    PASS     (VS_Tri, PS_Combine))
#else
TECHNIQUE    (VHSM, "VHS-M",
             "Emulates clean, artifact-free, output of a VHS tape",

    // Store the backbuffer in TexBlur2
    PASS_RT  (VS_Tri, PS_Copy,       TexBlur2)

    // Downscale for lower res luma
    PASS_RT  (VS_Tri, PS_Downscale1, TexBlur1)
    PASS_RT  (VS_Tri, PS_Upscale1,   TexBlur2)

    // Bake luma into alpha channel
    PASS_RT  (VS_Tri, PS_SDLuma,     TexBlur1)

    // Downscale again for even lower res chroma, preserving previous luma res
    PASS_RT  (VS_Tri, PS_Downscale2, TexBlur2)
    PASS_RT  (VS_Tri, PS_Downscale3, TexBlur1)
    PASS_RT  (VS_Tri, PS_Downscale4, TexBlur2)
    PASS_RT  (VS_Tri, PS_Upscale2,   TexBlur1)
    PASS_RT  (VS_Tri, PS_Upscale3,   TexBlur2)
    PASS_RT  (VS_Tri, PS_Upscale4,   TexBlur1)

    // Combine the VHS effect
    PASS     (VS_Tri, PS_Combine))
#endif
