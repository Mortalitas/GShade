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
////                          ATMOSPHERIC  DENSITY                          ////
////                             Verision: 1.1                              ////
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

// Configure MShadersCommon.fxh
#define _TIMER       // Enable ReShade timer
#define _DITHER      // Enable Dither function
#define _DEPTH_CHECK // Enable checking for depth buffer
#include "MShadersCommon.fxh"

// UI VARIABLES ////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// PREPROCESSOR SETTINGS /////////////////////////
#ifndef ENABLE_MISC_CONTROLS
    #define ENABLE_MISC_CONTROLS 0
#endif

#ifndef ENABLE_LINEAR_GAMMA
    #define ENABLE_LINEAR_GAMMA 0
#endif

#define CATEGORY "Fog Physical Properties" /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
UI_INT_S (DISTANCE, "Density", "Determines the apparent thickness of the fog.", 1, 100, 75, 0)
UI_INT_S (HIGHLIGHT_DIST, "Highlight Distance", "Controls how far into the fog that highlights can penetrate.", 0, 100, 100, 1)

UI_COLOR (FOG_TINT, "Fog Color", "", 0.4, 0.45, 0.5, 5)
UI_COMBO (AUTO_COLOR, "Fog Color Mode", "", 3, 1,
    "Exact Fog Color\0"
    "Preserve Scene Luminance\0"
    "Use Blurred Scene Luminance\0")
UI_INT_S (WIDTH, "Light Scattering", "Controls width of light glow. Needs blurred scene luminance enabled.", 0, 100, 50, 1)
#undef  CATEGORY ///////////////////////////////////////////////////////////////

#if (ENABLE_MISC_CONTROLS != 0)
#define CATEGORY "Misc Controls" ///////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
UI_INT_S (FOG_SAT, "Fog Saturation Boost", "(Unrealistic) Boosts the colorfulness of the fog", 0, 100, 0, 0)
UI_INT_S (BLUR_WIDTH, "Blur Width", "Determines the size of the blur used to generate the fog.", 50, 100, 100, 1)
UI_INT_S (BLEND, "Overall Blend", "(Unrealistic) Simply mixes fog with the original image.\n"
                                  "Anything below 100 is not really correct, but\n"
                                  "the control is here for those who want it.", 0, 100, 100, 1)
#undef  CATEGORY ///////////////////////////////////////////////////////////////
#endif


// FUNCTIONS ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#include "MShadersAVGen.fxh"

// Only run blur calc within downscaled image bounds (thanks for the help, kingeric1992)
#define LOWER_BOUND 0.675
#define UPPER_BOUND 0.325
#define LEFT_BOUND  0.325
#define RIGHT_BOUND 0.675

float3 BlurH (float luma, sampler Samplerluma, float2 coord)
{
    float offset[18] =
    {
        0.0,            1.4953705027, 3.4891992113,
        5.4830312105,   7.4768683759, 9.4707125766,
        11.4645656736, 13.4584295168, 15.4523059431,
        17.4461967743, 19.4661974725, 21.4627427973,
        23.4592916956, 25.455844494,  27.4524015179,
        29.4489630909, 31.445529535,  33.4421011704
    };

    float kernel[18] =
    {
        0.033245,     0.0659162217, 0.0636705814,
        0.0598194658, 0.0546642566, 0.0485871646,
        0.0420045997, 0.0353207015, 0.0288880982,
        0.0229808311, 0.0177815511, 0.013382297,
        0.0097960001, 0.0069746748, 0.0048301008,
        0.0032534598, 0.0021315311, 0.0013582974
    };

    luma *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > RIGHT_BOUND || coord.x < LEFT_BOUND   ||
         coord.y > LOWER_BOUND || coord.y < UPPER_BOUND))
         return luma;

    [loop]
    for(int i = 1; i < 18; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.x + i * BUFFER_PIXEL_SIZE.x) > RIGHT_BOUND  ||
             (coord.x - i * BUFFER_PIXEL_SIZE.x) < LEFT_BOUND)) continue;

        luma += tex2Dlod(Samplerluma, float4(coord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).x * kernel[i];
        luma += tex2Dlod(Samplerluma, float4(coord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).x * kernel[i];
    }

    return float3(luma.xxx);
}

float3 BlurV (float luma, sampler Samplerluma, float2 coord)
{
    float offset[18] =
    {
        0.0,            1.4953705027, 3.4891992113,
        5.4830312105,   7.4768683759, 9.4707125766,
        11.4645656736, 13.4584295168, 15.4523059431,
        17.4461967743, 19.4661974725, 21.4627427973,
        23.4592916956, 25.455844494,  27.4524015179,
        29.4489630909, 31.445529535,  33.4421011704
    };

    float kernel[18] =
    {
        0.033245,     0.0659162217, 0.0636705814,
        0.0598194658, 0.0546642566, 0.0485871646,
        0.0420045997, 0.0353207015, 0.0288880982,
        0.0229808311, 0.0177815511, 0.013382297,
        0.0097960001, 0.0069746748, 0.0048301008,
        0.0032534598, 0.0021315311, 0.0013582974
    };

    luma *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > RIGHT_BOUND || coord.x < LEFT_BOUND   ||
         coord.y > LOWER_BOUND || coord.y < UPPER_BOUND))
         return luma;

    [loop]
    for(int i = 1; i < 18; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.y + i * BUFFER_PIXEL_SIZE.y) > LOWER_BOUND   ||
             (coord.y - i * BUFFER_PIXEL_SIZE.y) < UPPER_BOUND)) continue;

        luma += tex2Dlod(Samplerluma, float4(coord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).x * kernel[i];
        luma += tex2Dlod(Samplerluma, float4(coord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).x * kernel[i];
    }

    return float3(luma.xxx);
}

float3 BlurH (float3 color, sampler SamplerColor, float2 coord)
{
    float offset[18] =
    {
        0.0,            1.4953705027, 3.4891992113,
        5.4830312105,   7.4768683759, 9.4707125766,
        11.4645656736, 13.4584295168, 15.4523059431,
        17.4461967743, 19.4661974725, 21.4627427973,
        23.4592916956, 25.455844494,  27.4524015179,
        29.4489630909, 31.445529535,  33.4421011704
    };

    float kernel[18] =
    {
        0.033245,     0.0659162217, 0.0636705814,
        0.0598194658, 0.0546642566, 0.0485871646,
        0.0420045997, 0.0353207015, 0.0288880982,
        0.0229808311, 0.0177815511, 0.013382297,
        0.0097960001, 0.0069746748, 0.0048301008,
        0.0032534598, 0.0021315311, 0.0013582974
    };

    color *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > RIGHT_BOUND || coord.x < LEFT_BOUND   ||
         coord.y > LOWER_BOUND || coord.y < UPPER_BOUND))
         return color;

    [loop]
    for(int i = 1; i < 18; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.x + i * BUFFER_PIXEL_SIZE.x) > RIGHT_BOUND  ||
             (coord.x - i * BUFFER_PIXEL_SIZE.x) < LEFT_BOUND)) continue;

        color += tex2Dlod(SamplerColor, float4(coord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).rgb * kernel[i];
        color += tex2Dlod(SamplerColor, float4(coord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).rgb * kernel[i];
    }

    return color;
}

float3 BlurV (float3 color, sampler SamplerColor, float2 coord)
{
    float offset[18] =
    {
        0.0,            1.4953705027, 3.4891992113,
        5.4830312105,   7.4768683759, 9.4707125766,
        11.4645656736, 13.4584295168, 15.4523059431,
        17.4461967743, 19.4661974725, 21.4627427973,
        23.4592916956, 25.455844494,  27.4524015179,
        29.4489630909, 31.445529535,  33.4421011704
    };

    float kernel[18] =
    {
        0.033245,     0.0659162217, 0.0636705814,
        0.0598194658, 0.0546642566, 0.0485871646,
        0.0420045997, 0.0353207015, 0.0288880982,
        0.0229808311, 0.0177815511, 0.013382297,
        0.0097960001, 0.0069746748, 0.0048301008,
        0.0032534598, 0.0021315311, 0.0013582974
    };

    color *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > RIGHT_BOUND || coord.x < LEFT_BOUND   ||
         coord.y > LOWER_BOUND || coord.y < UPPER_BOUND))
         return color;

    [loop]
    for(int i = 1; i < 18; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.y + i * BUFFER_PIXEL_SIZE.y) > LOWER_BOUND  ||
             (coord.y - i * BUFFER_PIXEL_SIZE.y) < UPPER_BOUND)) continue;

        color += tex2Dlod(SamplerColor, float4(coord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).rgb * kernel[i];
        color += tex2Dlod(SamplerColor, float4(coord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).rgb * kernel[i];
    }

    return color;
}


// SHADERS /////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define PS_IN(v, c) float4 v : SV_Position, float2 c : TEXCOORD // Laziness macros FTW

// COPY BACKBUFFER ///////////////////////////////
void PS_Copy(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = tex2D(TextureColor, coord).rgb;
}

// CHECK DEPTH BUFFER ////////////////////////////
void PS_CopyDepth(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = ReShade::GetLinearizedDepth(coord);
}

// RESTORE BACKBUFFER ////////////////////////////
void PS_Restore(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = tex2D(TextureCopy, coord).rgb;
}

// IMAGE PREP ////////////////////////////////////
// Luma
void PS_PrepLuma(PS_IN(vpos, coord), out float3 luma : SV_Target)
{
    float depth, sky;
    luma  = tex2D(TextureColor, coord).rgb;
    depth = ReShade::GetLinearizedDepth(coord);
    sky   = all(1-depth);

    // Darken the background with distance
    luma  = lerp(luma, pow(abs(luma), lerp(2.0, 4.0, DISTANCE * 0.01)), depth * sky);

    // Take only the luminance for next step
    luma  = GetLuma(luma);

    #if (ENABLE_LINEAR_GAMMA != 0)
        luma = SRGBToLin(luma);
    #endif
}

// Full backbuffer
void PS_Prep(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    float depth, sky, width, luma;
    float3 tint, orig;
    color  = tex2D(TextureColor, coord).rgb;
    luma   = tex2D(TextureBlur2, coord).x;
    depth  = ReShade::GetLinearizedDepth(coord);
    sky    = all(1-depth);

    // Fog density setting (gamma controls how thick the fog is)
    depth  = pow(abs(depth), lerp(10.0, 0.75, DISTANCE * 0.01));

    // Darken the background with distance
    color  = lerp(color, pow(abs(color), lerp(2.0, 4.0, DISTANCE * 0.01)), depth * sky);

    // Desaturate slightly with distance
    color  = lerp(color, lerp(GetLuma(color), color, lerp(0.75, 1.0, (AUTO_COLOR != 0))), depth);

    // Grab the user defined color value for fog
    tint   = FOG_TINT;

    // Optionally modify the fog color value based on original scene luminance
    if (AUTO_COLOR > 0)
    {
        // Light scattering
        if (AUTO_COLOR > 1)
        {
            // Curve formula taken from CeeJay.dk's Curves shader
            width  = sin(3.1415927 * 0.5 * luma);
            width *= width;
            luma   = lerp(luma, width, lerp(1.0, -1.0, WIDTH * 0.01));
        }

        tint = tint - GetAvg(tint); // Remove average brightness from tint color
        tint = tint + luma;         // Replace tint brightness with scene brightness
    }

    // Overlay fog color to the scene before blurring in next step.
    // Additional masking for highlight protection. Code is a mess, I know.
    color  = lerp(color, lerp(tint + 0.125, tint, tint), depth * (1-smoothstep(0.0, 1.0, color) * (smoothstep(1.0, lerp(0.5, lerp(1.0, 0.75, DISTANCE * 0.01), HIGHLIGHT_DIST * 0.01), depth))));
                         // Avoid black fog                      // Protect highlights using smoothstep on color input, then place the highlights in the scene with a second smoothstep depth mask
                                                                 // (this avoids the original sky color bleeding in on "Exact Fog Color" mode in the UI)

    #if (ENABLE_LINEAR_GAMMA != 0)
        color = SRGBToLin(color);
    #endif
}

// SCALE DOWN ////////////////////////////////////

// Luma downscale
void PS_Downscale1(PS_IN(vpos, coord), out float3 luma : SV_Target)
{
    // If modifying fog color by blurred scene luminance
    if (AUTO_COLOR > 1)
    {
        // Scale down to 12.5% before the blur passes
        #if (ENABLE_MISC_CONTROLS != 0)
            luma = tex2D(TextureColor, SCALE(coord, lerp(0.25, 0.125, BLUR_WIDTH * 0.01))).rgb;
        #else
            luma = tex2D(TextureColor, SCALE(coord, 0.125)).rgb;
        #endif
    }
    else
    {
        // Pass through
        luma = tex2D(TextureColor, coord).rgb;
    }

    luma += Dither(luma, coord, BitDepth);
}

// Downscale pass for simple downscale + bi-cubic upscale for small blur
void PS_Downscale2(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    // Scale down to 50% before the blur passes
    color  = tex2D(TextureColor, SCALE(coord, 0.5)).rgb;
}

// Downscale pass for the large blur
void PS_Downscale3(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    // Scale down to 12.5% before the blur passes
    #if (ENABLE_MISC_CONTROLS != 0)
        color = tex2D(TextureColor, SCALE(coord, lerp(0.25, 0.125, BLUR_WIDTH * 0.01))).rgb;
    #else
        color = tex2D(TextureColor, SCALE(coord, 0.125)).rgb;
    #endif
}

// BI-LATERAL GAUSSIAN BLUR //////////////////////

// Luma blur horizontal pass
void PS_LumaBlurH(PS_IN(vpos, coord), out float3 luma : SV_Target)
{
    luma = tex2D(TextureBlur1, coord).x;

    if (AUTO_COLOR > 1)
    {
        luma  = BlurH(luma, TextureBlur1, coord).xxx;
    }
}
// Luma blur vertical pass
void PS_LumaBlurV(PS_IN(vpos, coord), out float3 luma : SV_Target)
{
    luma  = tex2D(TextureBlur2, coord).x;

    if (AUTO_COLOR > 1)
    {
        luma = BlurV(luma, TextureBlur2, coord).xxx;
    }
}

// Large color blur horizontal pass
void PS_BlurH(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = tex2D(TextureBlur1, coord).rgb;
    color  = BlurH(color, TextureBlur1, coord);
}
// Large color blur vertical pass
void PS_BlurV(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    color  = tex2D(TextureBlur2, coord).rgb;
    color  = BlurV(color, TextureBlur2, coord);
}

// SCALE UP //////////////////////////////////////

// Luma upscale
void PS_UpScale1(PS_IN(vpos, coord), out float3 luma : SV_Target)
{
    // If modifying fog color by blurred scene luminance
    if (AUTO_COLOR > 1)
    {
        // Scale back up to 100%
        #if (ENABLE_MISC_CONTROLS != 0)
            luma  = tex2Dbicub(TextureBlur1, SCALE(coord, (1.0 / lerp(0.25, 0.125, BLUR_WIDTH * 0.01)))).rgb;
        #else
            luma  = tex2Dbicub(TextureBlur1, SCALE(coord, 8.0)).rgb;
        #endif
    }
    else
    {
        // Pass through
        luma  = tex2D(TextureBlur1, coord).xxx;
    }
}

// Simple blur upscale
void PS_UpScale2(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    // Scale simple downscale/upscale blur back up to 100%
    color  = tex2Dbicub(TextureBlur1, SCALE(coord, 2.0)).rgb;
}

// Large blur upscale
void PS_UpScale3(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    // Scale color blur back up to 100%
    #if (ENABLE_MISC_CONTROLS != 0)
        color  = tex2Dbicub(TextureBlur1, SCALE(coord, (1.0 / lerp(0.25, 0.125, BLUR_WIDTH * 0.01)))).rgb;
    #else
        color  = tex2Dbicub(TextureBlur1, SCALE(coord, 8.0)).rgb;
    #endif
}

// DRAW FOG //////////////////////////////////////
void PS_Combine(PS_IN(vpos, coord), out float3 color : SV_Target)
{
    float3 orig, blur, blur2, tint;
    float  depth, depth_avg, sky;

    blur      = tex2D(TextureBlur2, coord).rgb;
    blur2     = tex2D(TextureColor, coord).rgb;
    color     = tex2D(TextureCopy,  coord).rgb;
    depth     = ReShade::GetLinearizedDepth(coord);
    sky       = all(1-depth);
    depth_avg = avGen::get().x;
    orig      = color;

    #if (ENABLE_LINEAR_GAMMA != 0)
        blur = LinToSRGB(blur);
    #endif

    // Fog density setting (gamma controls how thick the fog is)
    depth     = pow(abs(depth), lerp(10.0, 0.33, DISTANCE * 0.01));

    // Use small blur texture to decrease distant detail
    color     = lerp(color, blur2, depth);

    // Darken the already dark parts of the image to give an impression of "shadowing" from fog using the large blur texture
    // Blending this way avoids extra dark halos on bright areas like the sky
    if (AUTO_COLOR < 1)
    {
        color = lerp(color, lerp(color * pow(abs(blur), 10.0), color, color), depth * saturate(1-GetLuma(color * 0.75)) * sky);
    }

    // Overlay the blur texture (while lifting its gamma in "Exact Fog Color" mode in the UI).
    // Mask protects highlights from being darkened
    color     = lerp(color, pow(abs(blur), lerp(0.75, 1.0, (AUTO_COLOR != 0))), depth * saturate(1-GetLuma(color * 0.75)));

    // Do some additive blending to give the impression of scene lights affecting the fog
    #if (ENABLE_MISC_CONTROLS != 0)
        blur  = saturate(lerp(GetLuma(blur), blur, (FOG_SAT + 100) * 0.01));
    #endif
    color     = lerp(color, ((color * 0.5) + pow(abs(blur * 2.0), 0.75)) * 0.5, depth);

    // Dither to kill any banding
    color    += Dither(color, coord, BitDepth);

    // Try to detect when depth buffer is blank to avoid drawing over menus
    if ((depth_avg == 0.0) || (depth_avg == 1.0))
        color = orig;

    #if (ENABLE_MISC_CONTROLS != 0)
        color = lerp(orig, color, BLEND * 0.01);
    #endif
}


// TECHNIQUES //////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
TECHNIQUE    (AtmosphericDensity,   "Atmospheric Density",
             "Atmospheric Density is a psuedo-volumetric\n"
             "fog shader. You will likely need to adjust\n"
             "the fog color to match your scene.",

    // Try to detect depth buffer when it is blank to avoid drawing over stuff like pause menus
    PASS_RT  (VS_Tri, PS_Copy,       TexCopy)  // Copy the backbuffer
    PASS     (VS_Tri, PS_CopyDepth)            // Write the depth buffer to backbuffer
    PASS_AVG ()                                // Generate avgerage depth buffer luma (This helps detect when depth is blank in menus in certain games)
    PASS     (VS_Tri, PS_Restore)              // Restore original backbuffer

    // Blur the scene luminance
    PASS_RT  (VS_Tri, PS_PrepLuma,   TexBlur2) // Prepare the scene for luma blurring
    PASS_RT  (VS_Tri, PS_Downscale1, TexBlur1) // Scale down scene luma 12.5%
    PASS_RT  (VS_Tri, PS_LumaBlurH,  TexBlur2) // Blur horizontally
    PASS_RT  (VS_Tri, PS_LumaBlurV,  TexBlur1) // Blur vertically
    PASS_RT  (VS_Tri, PS_UpScale1,   TexBlur2) // Scale scene luma back up to 100% size

    // Prepare the scene for the color blur pass
    PASS     (VS_Tri, PS_Prep)                 // Prepare the backbuffer for blurring

    // Do a quick downscale + bi-cubic upscale for a small cheap blur
    PASS_RT  (VS_Tri, PS_Downscale2, TexBlur1) // Downscale by 50%
    PASS     (VS_Tri, PS_UpScale2)             // Upscale back to 100% with bi-cubic filtering (this is the small blur)

    // Downscale + blur + upscale for very large blur radius
    PASS_RT  (VS_Tri, PS_Downscale3, TexBlur1) // Scale down prepped backbuffer from above to 12.5%
    PASS_RT  (VS_Tri, PS_BlurH,      TexBlur2) // Blur horizontally
    PASS_RT  (VS_Tri, PS_BlurV,      TexBlur1) // Blur vertically
    PASS_RT  (VS_Tri, PS_UpScale3,   TexBlur2) // Scale back up to 100% size

    // Combine the various blurs and draw the fog
    PASS     (VS_Tri, PS_Combine))             // Blend the blurred data and original backbuffer using depth
