/*============================================================================


                    NVIDIA FXAA 3.11 by TIMOTHY LOTTES


------------------------------------------------------------------------------
COPYRIGHT (C) 2010, 2011 NVIDIA CORPORATION. ALL RIGHTS RESERVED.
------------------------------------------------------------------------------
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED
*AS IS* AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL NVIDIA
OR ITS SUPPLIERS BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR
CONSEQUENTIAL DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR
LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION,
OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE
THIS SOFTWARE, EVEN IF NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

------------------------------------------------------------------------------
                           INTEGRATION CHECKLIST
------------------------------------------------------------------------------
(1.)
In the shader source, setup defines for the desired configuration.
When providing multiple shaders (for different presets),
simply setup the defines differently in multiple files.
Example,

  #define HQ_FXAA_PC 1
  #define HQ_FXAA_HLSL_5 1
  #define HQ_FXAA_QUALITY__PRESET 12

Or,

  #define HQ_FXAA_360 1
  
Or,

  #define HQ_FXAA_PS3 1
  
Etc.

(2.)
Then include this file,

  #include "Fxaa3_11.h"

(3.)
Then call the FXAA pixel shader from within your desired shader.
Look at the FXAA Quality FxaaPixelShader() for docs on inputs.
As for FXAA 3.11 all inputs for all shaders are the same 
to enable easy porting between platforms.

  return FxaaPixelShader(...);

(4.)
Insure pass prior to FXAA outputs RGBL (see next section).
Or use,

  #define HQ_FXAA_GREEN_AS_LUMA 1

(5.)
Setup engine to provide the following constants
which are used in the FxaaPixelShader() inputs,

  HQ_FxaaFloat2 fxaaQualityRcpFrame,
  HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt,
  HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt2,
  HQ_FxaaFloat4 fxaaConsole360RcpFrameOpt2,
  HQ_FxaaFloat fxaaQualitySubpix,
  HQ_FxaaFloat fxaaQualityEdgeThreshold,
  HQ_FxaaFloat fxaaQualityEdgeThresholdMin,
  HQ_FxaaFloat fxaaConsoleEdgeSharpness,
  HQ_FxaaFloat fxaaConsoleEdgeThreshold,
  HQ_FxaaFloat fxaaConsoleEdgeThresholdMin,
  HQ_FxaaFloat4 fxaaConsole360ConstDir

Look at the FXAA Quality FxaaPixelShader() for docs on inputs.

(6.)
Have FXAA vertex shader run as a full screen triangle,
and output "pos" and "fxaaConsolePosPos" 
such that inputs in the pixel shader provide,

  // {xy} = center of pixel
  HQ_FxaaFloat2 pos,

  // {xy__} = upper left of pixel
  // {__zw} = lower right of pixel
  HQ_FxaaFloat4 fxaaConsolePosPos,

(7.)
Insure the texture sampler(s) used by FXAA are set to bilinear filtering.


------------------------------------------------------------------------------
                    INTEGRATION - RGBL AND COLORSPACE
------------------------------------------------------------------------------
FXAA3 requires RGBL as input unless the following is set, 

  #define HQ_FXAA_GREEN_AS_LUMA 1

In which case the engine uses green in place of luma,
and requires RGB input is in a non-linear colorspace.

RGB should be LDR (low dynamic range).
Specifically do FXAA after tonemapping.

RGB data as returned by a texture fetch can be non-linear,
or linear when HQ_FXAA_GREEN_AS_LUMA is not set.
Note an "sRGB format" texture counts as linear,
because the result of a texture fetch is linear data.
Regular "RGBA8" textures in the sRGB colorspace are non-linear.

If HQ_FXAA_GREEN_AS_LUMA is not set,
luma must be stored in the alpha channel prior to running FXAA.
This luma should be in a perceptual space (could be gamma 2.0).
Example pass before FXAA where output is gamma 2.0 encoded,

  color.rgb = ToneMap(color.rgb); // linear color output
  color.rgb = sqrt(color.rgb);    // gamma 2.0 color output
  return color;

To use FXAA,

  color.rgb = ToneMap(color.rgb);  // linear color output
  color.rgb = sqrt(color.rgb);     // gamma 2.0 color output
  color.a = dot(color.rgb, HQ_FxaaFloat3(0.299, 0.587, 0.114)); // compute luma
  return color;

Another example where output is linear encoded,
say for instance writing to an sRGB formated render target,
where the render target does the conversion back to sRGB after blending,

  color.rgb = ToneMap(color.rgb); // linear color output
  return color;

To use FXAA,

  color.rgb = ToneMap(color.rgb); // linear color output
  color.a = sqrt(dot(color.rgb, HQ_FxaaFloat3(0.299, 0.587, 0.114))); // compute luma
  return color;

Getting luma correct is required for the algorithm to work correctly.


------------------------------------------------------------------------------
                          BEING LINEARLY CORRECT?
------------------------------------------------------------------------------
Applying FXAA to a framebuffer with linear RGB color will look worse.
This is very counter intuitive, but happends to be true in this case.
The reason is because dithering artifacts will be more visiable 
in a linear colorspace.


------------------------------------------------------------------------------
                             COMPLEX INTEGRATION
------------------------------------------------------------------------------
Q. What if the engine is blending into RGB before wanting to run FXAA?

A. In the last opaque pass prior to FXAA,
   have the pass write out luma into alpha.
   Then blend into RGB only.
   FXAA should be able to run ok
   assuming the blending pass did not any add aliasing.
   This should be the common case for particles and common blending passes.

A. Or use HQ_FXAA_GREEN_AS_LUMA.

============================================================================*/

/*============================================================================

                             INTEGRATION KNOBS

============================================================================*/
//
// HQ_FXAA_PS3 and HQ_FXAA_360 choose the console algorithm (FXAA3 CONSOLE).
// HQ_FXAA_360_OPT is a prototype for the new optimized 360 version.
//
// 1 = Use API.
// 0 = Don't use API.
//
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_PS3
    #define HQ_FXAA_PS3 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_360
    #define HQ_FXAA_360 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_360_OPT
    #define HQ_FXAA_360_OPT 0
#endif
/*==========================================================================*/
#ifndef HQ_FXAA_PC
    //
    // FXAA Quality
    // The high quality PC algorithm.
    //
    #define HQ_FXAA_PC 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_PC_CONSOLE
    //
    // The console algorithm for PC is included
    // for developers targeting really low spec machines.
    // Likely better to just run HQ_FXAA_PC, and use a really low preset.
    //
    #define HQ_FXAA_PC_CONSOLE 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_GLSL_120
    #define HQ_FXAA_GLSL_120 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_GLSL_130
    #define HQ_FXAA_GLSL_130 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_HLSL_3
    #define HQ_FXAA_HLSL_3 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_HLSL_4
    #define HQ_FXAA_HLSL_4 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_HLSL_5
    #define HQ_FXAA_HLSL_5 0
#endif
/*==========================================================================*/
#ifndef HQ_FXAA_GREEN_AS_LUMA
    //
    // For those using non-linear color,
    // and either not able to get luma in alpha, or not wanting to,
    // this enables FXAA to run using green as a proxy for luma.
    // So with this enabled, no need to pack luma in alpha.
    //
    // This will turn off AA on anything which lacks some amount of green.
    // Pure red and blue or combination of only R and B, will get no AA.
    //
    // Might want to lower the settings for both,
    //    fxaaConsoleEdgeThresholdMin
    //    fxaaQualityEdgeThresholdMin
    // In order to insure AA does not get turned off on colors 
    // which contain a minor amount of green.
    //
    // 1 = On.
    // 0 = Off.
    //
    #define HQ_FXAA_GREEN_AS_LUMA 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_EARLY_EXIT
    //
    // Controls algorithm's early exit path.
    // On PS3 turning this ON adds 2 cycles to the shader.
    // On 360 turning this OFF adds 10ths of a millisecond to the shader.
    // Turning this off on console will result in a more blurry image.
    // So this defaults to on.
    //
    // 1 = On.
    // 0 = Off.
    //
    #define HQ_FXAA_EARLY_EXIT 1
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_DISCARD
    //
    // Only valid for PC OpenGL currently.
    // Probably will not work when HQ_FXAA_GREEN_AS_LUMA = 1.
    //
    // 1 = Use discard on pixels which don't need AA.
    //     For APIs which enable concurrent TEX+ROP from same surface.
    // 0 = Return unchanged color on pixels which don't need AA.
    //
    #define HQ_FXAA_DISCARD 0
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_FAST_PIXEL_OFFSET
    //
    // Used for GLSL 120 only.
    //
    // 1 = GL API supports fast pixel offsets
    // 0 = do not use fast pixel offsets
    //
    #ifdef GL_EXT_gpu_shader4
        #define HQ_FXAA_FAST_PIXEL_OFFSET 1
    #endif
    #ifdef GL_NV_gpu_shader5
        #define HQ_FXAA_FAST_PIXEL_OFFSET 1
    #endif
    #ifdef GL_ARB_gpu_shader5
        #define HQ_FXAA_FAST_PIXEL_OFFSET 1
    #endif
    #ifndef HQ_FXAA_FAST_PIXEL_OFFSET
        #define HQ_FXAA_FAST_PIXEL_OFFSET 0
    #endif
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_GATHER4_ALPHA
    //
    // 1 = API supports gather4 on alpha channel.
    // 0 = API does not support gather4 on alpha channel.
    //
    #if (HQ_FXAA_HLSL_5 == 1)
        #define HQ_FXAA_GATHER4_ALPHA 1
    #endif
    #ifdef GL_ARB_gpu_shader5
        #define HQ_FXAA_GATHER4_ALPHA 1
    #endif
    #ifdef GL_NV_gpu_shader5
        #define HQ_FXAA_GATHER4_ALPHA 1
    #endif
    #ifndef HQ_FXAA_GATHER4_ALPHA
        #define HQ_FXAA_GATHER4_ALPHA 0
    #endif
#endif

/*============================================================================
                      FXAA CONSOLE PS3 - TUNING KNOBS
============================================================================*/
#ifndef HQ_FXAA_CONSOLE__PS3_EDGE_SHARPNESS
    //
    // Consoles the sharpness of edges on PS3 only.
    // Non-PS3 tuning is done with shader input.
    //
    // Due to the PS3 being ALU bound,
    // there are only two safe values here: 4 and 8.
    // These options use the shaders ability to a free *|/ by 2|4|8.
    //
    // 8.0 is sharper
    // 4.0 is softer
    // 2.0 is really soft (good for vector graphics inputs)
    //
    #if 1
        #define HQ_FXAA_CONSOLE__PS3_EDGE_SHARPNESS 8.0
    #endif
    #if 0
        #define HQ_FXAA_CONSOLE__PS3_EDGE_SHARPNESS 4.0
    #endif
    #if 0
        #define HQ_FXAA_CONSOLE__PS3_EDGE_SHARPNESS 2.0
    #endif
#endif
/*--------------------------------------------------------------------------*/
#ifndef HQ_FXAA_CONSOLE__PS3_EDGE_THRESHOLD
    //
    // Only effects PS3.
    // Non-PS3 tuning is done with shader input.
    //
    // The minimum amount of local contrast required to apply algorithm.
    // The console setting has a different mapping than the quality setting.
    //
    // This only applies when HQ_FXAA_EARLY_EXIT is 1.
    //
    // Due to the PS3 being ALU bound,
    // there are only two safe values here: 0.25 and 0.125.
    // These options use the shaders ability to a free *|/ by 2|4|8.
    //
    // 0.125 leaves less aliasing, but is softer
    // 0.25 leaves more aliasing, and is sharper
    //
    #if 1
        #define HQ_FXAA_CONSOLE__PS3_EDGE_THRESHOLD 0.125
    #else
        #define HQ_FXAA_CONSOLE__PS3_EDGE_THRESHOLD 0.25
    #endif
#endif

/*============================================================================
                        FXAA QUALITY - TUNING KNOBS
------------------------------------------------------------------------------
NOTE the other tuning knobs are now in the shader function inputs!
============================================================================*/
#ifndef HQ_FXAA_QUALITY__PRESET
    //
    // Choose the quality preset.
    // This needs to be compiled into the shader as it effects code.
    // Best option to include multiple presets is to 
    // in each shader define the preset, then include this file.
    // 
    // OPTIONS
    // -----------------------------------------------------------------------
    // 10 to 15 - default medium dither (10=fastest, 15=highest quality)
    // 20 to 29 - less dither, more expensive (20=fastest, 29=highest quality)
    // 39       - no dither, very expensive 
    //
    // NOTES
    // -----------------------------------------------------------------------
    // 12 = slightly faster then FXAA 3.9 and higher edge quality (default)
    // 13 = about same speed as FXAA 3.9 and better than 12
    // 23 = closest to FXAA 3.9 visually and performance wise
    //  _ = the lowest digit is directly related to performance
    // _  = the highest digit is directly related to style
    // 
    #define HQ_FXAA_QUALITY__PRESET 12
#endif


/*============================================================================

                           FXAA QUALITY - PRESETS

============================================================================*/

/*============================================================================
                     FXAA QUALITY - MEDIUM DITHER PRESETS
============================================================================*/
#if (HQ_FXAA_QUALITY__PRESET == 10)
    #define HQ_FXAA_QUALITY__PS 3
    #define HQ_FXAA_QUALITY__P0 1.5
    #define HQ_FXAA_QUALITY__P1 3.0
    #define HQ_FXAA_QUALITY__P2 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 11)
    #define HQ_FXAA_QUALITY__PS 4
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 3.0
    #define HQ_FXAA_QUALITY__P3 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 12)
    #define HQ_FXAA_QUALITY__PS 5
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 4.0
    #define HQ_FXAA_QUALITY__P4 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 13)
    #define HQ_FXAA_QUALITY__PS 6
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 4.0
    #define HQ_FXAA_QUALITY__P5 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 14)
    #define HQ_FXAA_QUALITY__PS 7
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 2.0
    #define HQ_FXAA_QUALITY__P5 4.0
    #define HQ_FXAA_QUALITY__P6 12.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 15)
    #define HQ_FXAA_QUALITY__PS 8
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 2.0
    #define HQ_FXAA_QUALITY__P5 2.0
    #define HQ_FXAA_QUALITY__P6 4.0
    #define HQ_FXAA_QUALITY__P7 12.0
#endif

/*============================================================================
                     FXAA QUALITY - LOW DITHER PRESETS
============================================================================*/
#if (HQ_FXAA_QUALITY__PRESET == 20)
    #define HQ_FXAA_QUALITY__PS 3
    #define HQ_FXAA_QUALITY__P0 1.5
    #define HQ_FXAA_QUALITY__P1 2.0
    #define HQ_FXAA_QUALITY__P2 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 21)
    #define HQ_FXAA_QUALITY__PS 4
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 22)
    #define HQ_FXAA_QUALITY__PS 5
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 23)
    #define HQ_FXAA_QUALITY__PS 6
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 2.0
    #define HQ_FXAA_QUALITY__P5 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 24)
    #define HQ_FXAA_QUALITY__PS 7
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 2.0
    #define HQ_FXAA_QUALITY__P5 3.0
    #define HQ_FXAA_QUALITY__P6 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 25)
    #define HQ_FXAA_QUALITY__PS 8
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 2.0
    #define HQ_FXAA_QUALITY__P5 2.0
    #define HQ_FXAA_QUALITY__P6 4.0
    #define HQ_FXAA_QUALITY__P7 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 26)
    #define HQ_FXAA_QUALITY__PS 9
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 2.0
    #define HQ_FXAA_QUALITY__P5 2.0
    #define HQ_FXAA_QUALITY__P6 2.0
    #define HQ_FXAA_QUALITY__P7 4.0
    #define HQ_FXAA_QUALITY__P8 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 27)
    #define HQ_FXAA_QUALITY__PS 10
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 2.0
    #define HQ_FXAA_QUALITY__P5 2.0
    #define HQ_FXAA_QUALITY__P6 2.0
    #define HQ_FXAA_QUALITY__P7 2.0
    #define HQ_FXAA_QUALITY__P8 4.0
    #define HQ_FXAA_QUALITY__P9 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 28)
    #define HQ_FXAA_QUALITY__PS 11
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 2.0
    #define HQ_FXAA_QUALITY__P5 2.0
    #define HQ_FXAA_QUALITY__P6 2.0
    #define HQ_FXAA_QUALITY__P7 2.0
    #define HQ_FXAA_QUALITY__P8 2.0
    #define HQ_FXAA_QUALITY__P9 4.0
    #define HQ_FXAA_QUALITY__P10 8.0
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_QUALITY__PRESET == 29)
    #define HQ_FXAA_QUALITY__PS 12
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.5
    #define HQ_FXAA_QUALITY__P2 2.0
    #define HQ_FXAA_QUALITY__P3 2.0
    #define HQ_FXAA_QUALITY__P4 2.0
    #define HQ_FXAA_QUALITY__P5 2.0
    #define HQ_FXAA_QUALITY__P6 2.0
    #define HQ_FXAA_QUALITY__P7 2.0
    #define HQ_FXAA_QUALITY__P8 2.0
    #define HQ_FXAA_QUALITY__P9 2.0
    #define HQ_FXAA_QUALITY__P10 4.0
    #define HQ_FXAA_QUALITY__P11 8.0
#endif

/*============================================================================
                     FXAA QUALITY - EXTREME QUALITY
============================================================================*/
#if (HQ_FXAA_QUALITY__PRESET == 39)
    #define HQ_FXAA_QUALITY__PS 12
    #define HQ_FXAA_QUALITY__P0 1.0
    #define HQ_FXAA_QUALITY__P1 1.0
    #define HQ_FXAA_QUALITY__P2 1.0
    #define HQ_FXAA_QUALITY__P3 1.0
    #define HQ_FXAA_QUALITY__P4 1.0
    #define HQ_FXAA_QUALITY__P5 1.5
    #define HQ_FXAA_QUALITY__P6 2.0
    #define HQ_FXAA_QUALITY__P7 2.0
    #define HQ_FXAA_QUALITY__P8 2.0
    #define HQ_FXAA_QUALITY__P9 2.0
    #define HQ_FXAA_QUALITY__P10 4.0
    #define HQ_FXAA_QUALITY__P11 8.0
#endif



/*============================================================================

                                API PORTING

============================================================================*/
#if (HQ_FXAA_GLSL_120 == 1) || (HQ_FXAA_GLSL_130 == 1)
    #define HQ_FxaaBool bool
    #define HQ_FxaaDiscard discard
    #define HQ_FxaaFloat float
    #define HQ_FxaaFloat2 vec2
    #define HQ_FxaaFloat3 vec3
    #define HQ_FxaaFloat4 vec4
    #define HQ_FxaaHalf float
    #define HQ_FxaaHalf2 vec2
    #define HQ_FxaaHalf3 vec3
    #define HQ_FxaaHalf4 vec4
    #define HQ_FxaaInt2 ivec2
    #define HQ_FxaaSat(x) clamp(x, 0.0, 1.0)
    #define HQ_FxaaTex sampler2D
#else
    #define HQ_FxaaBool bool
    #define HQ_FxaaDiscard clip(-1)
    #define HQ_FxaaFloat float
    #define HQ_FxaaFloat2 float2
    #define HQ_FxaaFloat3 float3
    #define HQ_FxaaFloat4 float4
    #define HQ_FxaaHalf half
    #define HQ_FxaaHalf2 half2
    #define HQ_FxaaHalf3 half3
    #define HQ_FxaaHalf4 half4
    #define HQ_FxaaSat(x) saturate(x)
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_GLSL_120 == 1)
    // Requires,
    //  #version 120
    // And at least,
    //  #extension GL_EXT_gpu_shader4 : enable
    //  (or set HQ_FXAA_FAST_PIXEL_OFFSET 1 to work like DX9)
    #define HQ_FxaaTexTop(t, p) texture2DLod(t, p, 0.0)
    #if (HQ_FXAA_FAST_PIXEL_OFFSET == 1)
        #define HQ_FxaaTexOff(t, p, o, r) texture2DLodOffset(t, p, 0.0, o)
    #else
        #define HQ_FxaaTexOff(t, p, o, r) texture2DLod(t, p + (o * r), 0.0)
    #endif
    #if (HQ_FXAA_GATHER4_ALPHA == 1)
        // use #extension GL_ARB_gpu_shader5 : enable
        #define HQ_FxaaTexAlpha4(t, p) textureGather(t, p, 3)
        #define HQ_FxaaTexOffAlpha4(t, p, o) textureGatherOffset(t, p, o, 3)
        #define HQ_FxaaTexGreen4(t, p) textureGather(t, p, 1)
        #define HQ_FxaaTexOffGreen4(t, p, o) textureGatherOffset(t, p, o, 1)
    #endif
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_GLSL_130 == 1)
    // Requires "#version 130" or better
    #define HQ_FxaaTexTop(t, p) textureLod(t, p, 0.0)
    #define HQ_FxaaTexOff(t, p, o, r) textureLodOffset(t, p, 0.0, o)
    #if (HQ_FXAA_GATHER4_ALPHA == 1)
        // use #extension GL_ARB_gpu_shader5 : enable
        #define HQ_FxaaTexAlpha4(t, p) textureGather(t, p, 3)
        #define HQ_FxaaTexOffAlpha4(t, p, o) textureGatherOffset(t, p, o, 3)
        #define HQ_FxaaTexGreen4(t, p) textureGather(t, p, 1)
        #define HQ_FxaaTexOffGreen4(t, p, o) textureGatherOffset(t, p, o, 1)
    #endif
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_HLSL_3 == 1) || (HQ_FXAA_360 == 1) || (HQ_FXAA_PS3 == 1)
    #define HQ_FxaaInt2 float2
    #define HQ_FxaaTex sampler2D
    #define HQ_FxaaTexTop(t, p) tex2Dlod(t, float4(p, 0.0, 0.0))
    #define HQ_FxaaTexOff(t, p, o, r) tex2Dlod(t, float4(p + (o * r), 0, 0))
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_HLSL_4 == 1)
    #define HQ_FxaaInt2 int2
    struct HQ_FxaaTex { SamplerState smpl; Texture2D tex; };
    #define HQ_FxaaTexTop(t, p) t.tex.SampleLevel(t.smpl, p, 0.0)
    #define HQ_FxaaTexOff(t, p, o, r) t.tex.SampleLevel(t.smpl, p, 0.0, o)
#endif
/*--------------------------------------------------------------------------*/
#if (HQ_FXAA_HLSL_5 == 1)
    #define HQ_FxaaInt2 int2
    struct HQ_FxaaTex { SamplerState smpl; Texture2D tex; };
    #define HQ_FxaaTexTop(t, p) t.tex.SampleLevel(t.smpl, p, 0.0)
    #define HQ_FxaaTexOff(t, p, o, r) t.tex.SampleLevel(t.smpl, p, 0.0, o)
    #define HQ_FxaaTexAlpha4(t, p) t.tex.GatherAlpha(t.smpl, p)
    #define HQ_FxaaTexOffAlpha4(t, p, o) t.tex.GatherAlpha(t.smpl, p, o)
    #define HQ_FxaaTexGreen4(t, p) t.tex.GatherGreen(t.smpl, p)
    #define HQ_FxaaTexOffGreen4(t, p, o) t.tex.GatherGreen(t.smpl, p, o)
#endif


/*============================================================================
                   GREEN AS LUMA OPTION SUPPORT FUNCTION
============================================================================*/
#if (HQ_FXAA_GREEN_AS_LUMA == 0)
    HQ_FxaaFloat FxaaLuma(HQ_FxaaFloat4 rgba) { return rgba.w; }
#else
    HQ_FxaaFloat FxaaLuma(HQ_FxaaFloat4 rgba) { return rgba.y; }
#endif    




/*============================================================================

                             FXAA3 QUALITY - PC

============================================================================*/
#if (HQ_FXAA_PC == 1)
/*--------------------------------------------------------------------------*/
HQ_FxaaFloat4 FxaaPixelShader(
    //
    // Use noperspective interpolation here (turn off perspective interpolation).
    // {xy} = center of pixel
    HQ_FxaaFloat2 pos,
    //
    // Used only for FXAA Console, and not used on the 360 version.
    // Use noperspective interpolation here (turn off perspective interpolation).
    // {xy__} = upper left of pixel
    // {__zw} = lower right of pixel
    HQ_FxaaFloat4 fxaaConsolePosPos,
    //
    // Input color texture.
    // {rgb_} = color in linear or perceptual color space
    // if (HQ_FXAA_GREEN_AS_LUMA == 0)
    //     {___a} = luma in perceptual color space (not linear)
    HQ_FxaaTex tex,
    //
    // Only used on the optimized 360 version of FXAA Console.
    // For everything but 360, just use the same input here as for "tex".
    // For 360, same texture, just alias with a 2nd sampler.
    // This sampler needs to have an exponent bias of -1.
    HQ_FxaaTex fxaaConsole360TexExpBiasNegOne,
    //
    // Only used on the optimized 360 version of FXAA Console.
    // For everything but 360, just use the same input here as for "tex".
    // For 360, same texture, just alias with a 3nd sampler.
    // This sampler needs to have an exponent bias of -2.
    HQ_FxaaTex fxaaConsole360TexExpBiasNegTwo,
    //
    // Only used on FXAA Quality.
    // This must be from a constant/uniform.
    // {x_} = 1.0/screenWidthInPixels
    // {_y} = 1.0/screenHeightInPixels
    HQ_FxaaFloat2 fxaaQualityRcpFrame,
    //
    // Only used on FXAA Console.
    // This must be from a constant/uniform.
    // This effects sub-pixel AA quality and inversely sharpness.
    //   Where N ranges between,
    //     N = 0.50 (default)
    //     N = 0.33 (sharper)
    // {x___} = -N/screenWidthInPixels  
    // {_y__} = -N/screenHeightInPixels
    // {__z_} =  N/screenWidthInPixels  
    // {___w} =  N/screenHeightInPixels 
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt,
    //
    // Only used on FXAA Console.
    // Not used on 360, but used on PS3 and PC.
    // This must be from a constant/uniform.
    // {x___} = -2.0/screenWidthInPixels  
    // {_y__} = -2.0/screenHeightInPixels
    // {__z_} =  2.0/screenWidthInPixels  
    // {___w} =  2.0/screenHeightInPixels 
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt2,
    //
    // Only used on FXAA Console.
    // Only used on 360 in place of fxaaConsoleRcpFrameOpt2.
    // This must be from a constant/uniform.
    // {x___} =  8.0/screenWidthInPixels  
    // {_y__} =  8.0/screenHeightInPixels
    // {__z_} = -4.0/screenWidthInPixels  
    // {___w} = -4.0/screenHeightInPixels 
    HQ_FxaaFloat4 fxaaConsole360RcpFrameOpt2,
    //
    // Only used on FXAA Quality.
    // This used to be the FXAA_QUALITY__SUBPIX define.
    // It is here now to allow easier tuning.
    // Choose the amount of sub-pixel aliasing removal.
    // This can effect sharpness.
    //   1.00 - upper limit (softer)
    //   0.75 - default amount of filtering
    //   0.50 - lower limit (sharper, less sub-pixel aliasing removal)
    //   0.25 - almost off
    //   0.00 - completely off
    HQ_FxaaFloat fxaaQualitySubpix,
    //
    // Only used on FXAA Quality.
    // This used to be the FXAA_QUALITY__EDGE_THRESHOLD define.
    // It is here now to allow easier tuning.
    // The minimum amount of local contrast required to apply algorithm.
    //   0.333 - too little (faster)
    //   0.250 - low quality
    //   0.166 - default
    //   0.125 - high quality 
    //   0.063 - overkill (slower)
    HQ_FxaaFloat fxaaQualityEdgeThreshold,
    //
    // Only used on FXAA Quality.
    // This used to be the FXAA_QUALITY__EDGE_THRESHOLD_MIN define.
    // It is here now to allow easier tuning.
    // Trims the algorithm from processing darks.
    //   0.0833 - upper limit (default, the start of visible unfiltered edges)
    //   0.0625 - high quality (faster)
    //   0.0312 - visible limit (slower)
    // Special notes when using HQ_FXAA_GREEN_AS_LUMA,
    //   Likely want to set this to zero.
    //   As colors that are mostly not-green
    //   will appear very dark in the green channel!
    //   Tune by looking at mostly non-green content,
    //   then start at zero and increase until aliasing is a problem.
    HQ_FxaaFloat fxaaQualityEdgeThresholdMin,
    // 
    // Only used on FXAA Console.
    // This used to be the FXAA_CONSOLE__EDGE_SHARPNESS define.
    // It is here now to allow easier tuning.
    // This does not effect PS3, as this needs to be compiled in.
    //   Use HQ_FXAA_CONSOLE__PS3_EDGE_SHARPNESS for PS3.
    //   Due to the PS3 being ALU bound,
    //   there are only three safe values here: 2 and 4 and 8.
    //   These options use the shaders ability to a free *|/ by 2|4|8.
    // For all other platforms can be a non-power of two.
    //   8.0 is sharper (default!!!)
    //   4.0 is softer
    //   2.0 is really soft (good only for vector graphics inputs)
    HQ_FxaaFloat fxaaConsoleEdgeSharpness,
    //
    // Only used on FXAA Console.
    // This used to be the FXAA_CONSOLE__EDGE_THRESHOLD define.
    // It is here now to allow easier tuning.
    // This does not effect PS3, as this needs to be compiled in.
    //   Use HQ_FXAA_CONSOLE__PS3_EDGE_THRESHOLD for PS3.
    //   Due to the PS3 being ALU bound,
    //   there are only two safe values here: 1/4 and 1/8.
    //   These options use the shaders ability to a free *|/ by 2|4|8.
    // The console setting has a different mapping than the quality setting.
    // Other platforms can use other values.
    //   0.125 leaves less aliasing, but is softer (default!!!)
    //   0.25 leaves more aliasing, and is sharper
    HQ_FxaaFloat fxaaConsoleEdgeThreshold,
    //
    // Only used on FXAA Console.
    // This used to be the FXAA_CONSOLE__EDGE_THRESHOLD_MIN define.
    // It is here now to allow easier tuning.
    // Trims the algorithm from processing darks.
    // The console setting has a different mapping than the quality setting.
    // This only applies when HQ_FXAA_EARLY_EXIT is 1.
    // This does not apply to PS3, 
    // PS3 was simplified to avoid more shader instructions.
    //   0.06 - faster but more aliasing in darks
    //   0.05 - default
    //   0.04 - slower and less aliasing in darks
    // Special notes when using HQ_FXAA_GREEN_AS_LUMA,
    //   Likely want to set this to zero.
    //   As colors that are mostly not-green
    //   will appear very dark in the green channel!
    //   Tune by looking at mostly non-green content,
    //   then start at zero and increase until aliasing is a problem.
    HQ_FxaaFloat fxaaConsoleEdgeThresholdMin,
    //    
    // Extra constants for 360 FXAA Console only.
    // Use zeros or anything else for other platforms.
    // These must be in physical constant registers and NOT immedates.
    // Immedates will result in compiler un-optimizing.
    // {xyzw} = float4(1.0, -1.0, 0.25, -0.25)
    HQ_FxaaFloat4 fxaaConsole360ConstDir
) {
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat2 posM;
    posM.x = pos.x;
    posM.y = pos.y;
    #if (HQ_FXAA_GATHER4_ALPHA == 1)
        #if (HQ_FXAA_DISCARD == 0)
            HQ_FxaaFloat4 rgbyM = HQ_FxaaTexTop(tex, posM);
            #if (HQ_FXAA_GREEN_AS_LUMA == 0)
                #define lumaM rgbyM.w
            #else
                #define lumaM rgbyM.y
            #endif
        #endif
        #if (HQ_FXAA_GREEN_AS_LUMA == 0)
            HQ_FxaaFloat4 luma4A = HQ_FxaaTexAlpha4(tex, posM);
            HQ_FxaaFloat4 luma4B = HQ_FxaaTexOffAlpha4(tex, posM, HQ_FxaaInt2(-1, -1));
        #else
            HQ_FxaaFloat4 luma4A = HQ_FxaaTexGreen4(tex, posM);
            HQ_FxaaFloat4 luma4B = HQ_FxaaTexOffGreen4(tex, posM, HQ_FxaaInt2(-1, -1));
        #endif
        #if (HQ_FXAA_DISCARD == 1)
            #define lumaM luma4A.w
        #endif
        #define lumaE luma4A.z
        #define lumaS luma4A.x
        #define lumaSE luma4A.y
        #define lumaNW luma4B.w
        #define lumaN luma4B.z
        #define lumaW luma4B.x
    #else
        HQ_FxaaFloat4 rgbyM = HQ_FxaaTexTop(tex, posM);
        #if (HQ_FXAA_GREEN_AS_LUMA == 0)
            #define lumaM rgbyM.w
        #else
            #define lumaM rgbyM.y
        #endif
        HQ_FxaaFloat lumaS = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2( 0, 1), fxaaQualityRcpFrame.xy));
        HQ_FxaaFloat lumaE = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2( 1, 0), fxaaQualityRcpFrame.xy));
        HQ_FxaaFloat lumaN = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2( 0,-1), fxaaQualityRcpFrame.xy));
        HQ_FxaaFloat lumaW = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2(-1, 0), fxaaQualityRcpFrame.xy));
    #endif
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat maxSM = max(lumaS, lumaM);
    HQ_FxaaFloat minSM = min(lumaS, lumaM);
    HQ_FxaaFloat maxESM = max(lumaE, maxSM);
    HQ_FxaaFloat minESM = min(lumaE, minSM);
    HQ_FxaaFloat maxWN = max(lumaN, lumaW);
    HQ_FxaaFloat minWN = min(lumaN, lumaW);
    HQ_FxaaFloat rangeMax = max(maxWN, maxESM);
    HQ_FxaaFloat rangeMin = min(minWN, minESM);
    HQ_FxaaFloat rangeMaxScaled = rangeMax * fxaaQualityEdgeThreshold;
    HQ_FxaaFloat range = rangeMax - rangeMin;
    HQ_FxaaFloat rangeMaxClamped = max(fxaaQualityEdgeThresholdMin, rangeMaxScaled);
    HQ_FxaaBool earlyExit = range < rangeMaxClamped;
/*--------------------------------------------------------------------------*/
    if(earlyExit)
        #if (HQ_FXAA_DISCARD == 1)
            HQ_FxaaDiscard;
        #else
            return rgbyM;
        #endif
/*--------------------------------------------------------------------------*/
    #if (HQ_FXAA_GATHER4_ALPHA == 0)
        HQ_FxaaFloat lumaNW = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2(-1,-1), fxaaQualityRcpFrame.xy));
        HQ_FxaaFloat lumaSE = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2( 1, 1), fxaaQualityRcpFrame.xy));
        HQ_FxaaFloat lumaNE = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2( 1,-1), fxaaQualityRcpFrame.xy));
        HQ_FxaaFloat lumaSW = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2(-1, 1), fxaaQualityRcpFrame.xy));
    #else
        HQ_FxaaFloat lumaNE = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2(1, -1), fxaaQualityRcpFrame.xy));
        HQ_FxaaFloat lumaSW = FxaaLuma(HQ_FxaaTexOff(tex, posM, HQ_FxaaInt2(-1, 1), fxaaQualityRcpFrame.xy));
    #endif
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat lumaNS = lumaN + lumaS;
    HQ_FxaaFloat lumaWE = lumaW + lumaE;
    HQ_FxaaFloat subpixRcpRange = 1.0/range;
    HQ_FxaaFloat subpixNSWE = lumaNS + lumaWE;
    HQ_FxaaFloat edgeHorz1 = (-2.0 * lumaM) + lumaNS;
    HQ_FxaaFloat edgeVert1 = (-2.0 * lumaM) + lumaWE;
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat lumaNESE = lumaNE + lumaSE;
    HQ_FxaaFloat lumaNWNE = lumaNW + lumaNE;
    HQ_FxaaFloat edgeHorz2 = (-2.0 * lumaE) + lumaNESE;
    HQ_FxaaFloat edgeVert2 = (-2.0 * lumaN) + lumaNWNE;
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat lumaNWSW = lumaNW + lumaSW;
    HQ_FxaaFloat lumaSWSE = lumaSW + lumaSE;
    HQ_FxaaFloat edgeHorz4 = (abs(edgeHorz1) * 2.0) + abs(edgeHorz2);
    HQ_FxaaFloat edgeVert4 = (abs(edgeVert1) * 2.0) + abs(edgeVert2);
    HQ_FxaaFloat edgeHorz3 = (-2.0 * lumaW) + lumaNWSW;
    HQ_FxaaFloat edgeVert3 = (-2.0 * lumaS) + lumaSWSE;
    HQ_FxaaFloat edgeHorz = abs(edgeHorz3) + edgeHorz4;
    HQ_FxaaFloat edgeVert = abs(edgeVert3) + edgeVert4;
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat subpixNWSWNESE = lumaNWSW + lumaNESE;
    HQ_FxaaFloat lengthSign = fxaaQualityRcpFrame.x;
    HQ_FxaaBool horzSpan = edgeHorz >= edgeVert;
    HQ_FxaaFloat subpixA = subpixNSWE * 2.0 + subpixNWSWNESE;
/*--------------------------------------------------------------------------*/
    if(!horzSpan) lumaN = lumaW;
    if(!horzSpan) lumaS = lumaE;
    if(horzSpan) lengthSign = fxaaQualityRcpFrame.y;
    HQ_FxaaFloat subpixB = (subpixA * (1.0/12.0)) - lumaM;
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat gradientN = lumaN - lumaM;
    HQ_FxaaFloat gradientS = lumaS - lumaM;
    HQ_FxaaFloat lumaNN = lumaN + lumaM;
    HQ_FxaaFloat lumaSS = lumaS + lumaM;
    HQ_FxaaBool pairN = abs(gradientN) >= abs(gradientS);
    HQ_FxaaFloat gradient = max(abs(gradientN), abs(gradientS));
    if(pairN) lengthSign = -lengthSign;
    HQ_FxaaFloat subpixC = HQ_FxaaSat(abs(subpixB) * subpixRcpRange);
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat2 posB;
    posB.x = posM.x;
    posB.y = posM.y;
    HQ_FxaaFloat2 offNP;
    if (!horzSpan)
        offNP.x = 0.0;
    else
        offNP.x = fxaaQualityRcpFrame.x;
    if ( horzSpan)
        offNP.y = 0.0;
    else
        offNP.y = fxaaQualityRcpFrame.y;
    if(!horzSpan) posB.x += lengthSign * 0.5;
    if( horzSpan) posB.y += lengthSign * 0.5;
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat2 posN;
    posN.x = posB.x - offNP.x * HQ_FXAA_QUALITY__P0;
    posN.y = posB.y - offNP.y * HQ_FXAA_QUALITY__P0;
    HQ_FxaaFloat2 posP;
    posP.x = posB.x + offNP.x * HQ_FXAA_QUALITY__P0;
    posP.y = posB.y + offNP.y * HQ_FXAA_QUALITY__P0;
    HQ_FxaaFloat subpixD = ((-2.0)*subpixC) + 3.0;
    HQ_FxaaFloat lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN));
    HQ_FxaaFloat subpixE = subpixC * subpixC;
    HQ_FxaaFloat lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP));
/*--------------------------------------------------------------------------*/
    if(!pairN) lumaNN = lumaSS;
    HQ_FxaaFloat gradientScaled = gradient * 1.0/4.0;
    HQ_FxaaFloat lumaMM = lumaM - lumaNN * 0.5;
    HQ_FxaaFloat subpixF = subpixD * subpixE;
    HQ_FxaaBool lumaMLTZero = lumaMM < 0.0;
/*--------------------------------------------------------------------------*/
    lumaEndN -= lumaNN * 0.5;
    lumaEndP -= lumaNN * 0.5;
    HQ_FxaaBool doneN = abs(lumaEndN) >= gradientScaled;
    HQ_FxaaBool doneP = abs(lumaEndP) >= gradientScaled;
    if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P1;
    if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P1;
    HQ_FxaaBool doneNP = (!doneN) || (!doneP);
    if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P1;
    if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P1;
/*--------------------------------------------------------------------------*/
    if(doneNP) {
        if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
        if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
        doneN = abs(lumaEndN) >= gradientScaled;
        doneP = abs(lumaEndP) >= gradientScaled;
        if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P2;
        if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P2;
        doneNP = (!doneN) || (!doneP);
        if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P2;
        if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P2;
/*--------------------------------------------------------------------------*/
        #if (HQ_FXAA_QUALITY__PS > 3)
        if(doneNP) {
            if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
            if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
            if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
            if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
            doneN = abs(lumaEndN) >= gradientScaled;
            doneP = abs(lumaEndP) >= gradientScaled;
            if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P3;
            if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P3;
            doneNP = (!doneN) || (!doneP);
            if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P3;
            if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P3;
/*--------------------------------------------------------------------------*/
            #if (HQ_FXAA_QUALITY__PS > 4)
            if(doneNP) {
                if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
                if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
                if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                doneN = abs(lumaEndN) >= gradientScaled;
                doneP = abs(lumaEndP) >= gradientScaled;
                if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P4;
                if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P4;
                doneNP = (!doneN) || (!doneP);
                if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P4;
                if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P4;
/*--------------------------------------------------------------------------*/
                #if (HQ_FXAA_QUALITY__PS > 5)
                if(doneNP) {
                    if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
                    if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
                    if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                    if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                    doneN = abs(lumaEndN) >= gradientScaled;
                    doneP = abs(lumaEndP) >= gradientScaled;
                    if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P5;
                    if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P5;
                    doneNP = (!doneN) || (!doneP);
                    if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P5;
                    if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P5;
/*--------------------------------------------------------------------------*/
                    #if (HQ_FXAA_QUALITY__PS > 6)
                    if(doneNP) {
                        if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
                        if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
                        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                        doneN = abs(lumaEndN) >= gradientScaled;
                        doneP = abs(lumaEndP) >= gradientScaled;
                        if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P6;
                        if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P6;
                        doneNP = (!doneN) || (!doneP);
                        if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P6;
                        if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P6;
/*--------------------------------------------------------------------------*/
                        #if (HQ_FXAA_QUALITY__PS > 7)
                        if(doneNP) {
                            if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
                            if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
                            if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                            if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                            doneN = abs(lumaEndN) >= gradientScaled;
                            doneP = abs(lumaEndP) >= gradientScaled;
                            if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P7;
                            if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P7;
                            doneNP = (!doneN) || (!doneP);
                            if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P7;
                            if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P7;
/*--------------------------------------------------------------------------*/
    #if (HQ_FXAA_QUALITY__PS > 8)
    if(doneNP) {
        if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
        if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
        doneN = abs(lumaEndN) >= gradientScaled;
        doneP = abs(lumaEndP) >= gradientScaled;
        if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P8;
        if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P8;
        doneNP = (!doneN) || (!doneP);
        if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P8;
        if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P8;
/*--------------------------------------------------------------------------*/
        #if (HQ_FXAA_QUALITY__PS > 9)
        if(doneNP) {
            if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
            if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
            if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
            if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
            doneN = abs(lumaEndN) >= gradientScaled;
            doneP = abs(lumaEndP) >= gradientScaled;
            if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P9;
            if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P9;
            doneNP = (!doneN) || (!doneP);
            if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P9;
            if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P9;
/*--------------------------------------------------------------------------*/
            #if (HQ_FXAA_QUALITY__PS > 10)
            if(doneNP) {
                if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
                if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
                if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                doneN = abs(lumaEndN) >= gradientScaled;
                doneP = abs(lumaEndP) >= gradientScaled;
                if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P10;
                if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P10;
                doneNP = (!doneN) || (!doneP);
                if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P10;
                if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P10;
/*--------------------------------------------------------------------------*/
                #if (HQ_FXAA_QUALITY__PS > 11)
                if(doneNP) {
                    if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
                    if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
                    if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                    if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                    doneN = abs(lumaEndN) >= gradientScaled;
                    doneP = abs(lumaEndP) >= gradientScaled;
                    if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P11;
                    if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P11;
                    doneNP = (!doneN) || (!doneP);
                    if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P11;
                    if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P11;
/*--------------------------------------------------------------------------*/
                    #if (HQ_FXAA_QUALITY__PS > 12)
                    if(doneNP) {
                        if(!doneN) lumaEndN = FxaaLuma(HQ_FxaaTexTop(tex, posN.xy));
                        if(!doneP) lumaEndP = FxaaLuma(HQ_FxaaTexTop(tex, posP.xy));
                        if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                        if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                        doneN = abs(lumaEndN) >= gradientScaled;
                        doneP = abs(lumaEndP) >= gradientScaled;
                        if(!doneN) posN.x -= offNP.x * HQ_FXAA_QUALITY__P12;
                        if(!doneN) posN.y -= offNP.y * HQ_FXAA_QUALITY__P12;
                        doneNP = (!doneN) || (!doneP);
                        if(!doneP) posP.x += offNP.x * HQ_FXAA_QUALITY__P12;
                        if(!doneP) posP.y += offNP.y * HQ_FXAA_QUALITY__P12;
/*--------------------------------------------------------------------------*/
                    }
                    #endif
/*--------------------------------------------------------------------------*/
                }
                #endif
/*--------------------------------------------------------------------------*/
            }
            #endif
/*--------------------------------------------------------------------------*/
        }
        #endif
/*--------------------------------------------------------------------------*/
    }
    #endif
/*--------------------------------------------------------------------------*/
                        }
                        #endif
/*--------------------------------------------------------------------------*/
                    }
                    #endif
/*--------------------------------------------------------------------------*/
                }
                #endif
/*--------------------------------------------------------------------------*/
            }
            #endif
/*--------------------------------------------------------------------------*/
        }
        #endif
/*--------------------------------------------------------------------------*/
    }
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat dstN = posM.x - posN.x;
    HQ_FxaaFloat dstP = posP.x - posM.x;
    if(!horzSpan) dstN = posM.y - posN.y;
    if(!horzSpan) dstP = posP.y - posM.y;
/*--------------------------------------------------------------------------*/
    HQ_FxaaBool goodSpanN = (lumaEndN < 0.0) != lumaMLTZero;
    HQ_FxaaFloat spanLength = (dstP + dstN);
    HQ_FxaaBool goodSpanP = (lumaEndP < 0.0) != lumaMLTZero;
    HQ_FxaaFloat spanLengthRcp = 1.0/spanLength;
/*--------------------------------------------------------------------------*/
    HQ_FxaaBool directionN = dstN < dstP;
    HQ_FxaaFloat dst = min(dstN, dstP);
    HQ_FxaaBool goodSpan;
    if (directionN)
        goodSpan = goodSpanN;
    else
        goodSpan = goodSpanP;
    HQ_FxaaFloat subpixG = subpixF * subpixF;
    HQ_FxaaFloat pixelOffset = (dst * (-spanLengthRcp)) + 0.5;
    HQ_FxaaFloat subpixH = subpixG * fxaaQualitySubpix;
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat pixelOffsetGood;
    if (goodSpan)
        pixelOffsetGood = pixelOffset;
    else
        pixelOffsetGood = 0.0;
    HQ_FxaaFloat pixelOffsetSubpix = max(pixelOffsetGood, subpixH);
    if(!horzSpan) posM.x += pixelOffsetSubpix * lengthSign;
    if( horzSpan) posM.y += pixelOffsetSubpix * lengthSign;
    #if (HQ_FXAA_DISCARD == 1)
        return HQ_FxaaTexTop(tex, posM);
    #else
        return HQ_FxaaFloat4(HQ_FxaaTexTop(tex, posM).xyz, lumaM);
    #endif
}
/*==========================================================================*/
#endif




/*============================================================================

                         FXAA3 CONSOLE - PC VERSION
                         
------------------------------------------------------------------------------
Instead of using this on PC, I'd suggest just using FXAA Quality with
    #define HQ_FXAA_QUALITY__PRESET 10
Or 
    #define HQ_FXAA_QUALITY__PRESET 20
Either are higher qualilty and almost as fast as this on modern PC GPUs.
============================================================================*/
#if (HQ_FXAA_PC_CONSOLE == 1)
/*--------------------------------------------------------------------------*/
HQ_FxaaFloat4 FxaaPixelShader(
    // See FXAA Quality FxaaPixelShader() source for docs on Inputs!
    HQ_FxaaFloat2 pos,
    HQ_FxaaFloat4 fxaaConsolePosPos,
    HQ_FxaaTex tex,
    HQ_FxaaTex fxaaConsole360TexExpBiasNegOne,
    HQ_FxaaTex fxaaConsole360TexExpBiasNegTwo,
    HQ_FxaaFloat2 fxaaQualityRcpFrame,
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt,
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt2,
    HQ_FxaaFloat4 fxaaConsole360RcpFrameOpt2,
    HQ_FxaaFloat fxaaQualitySubpix,
    HQ_FxaaFloat fxaaQualityEdgeThreshold,
    HQ_FxaaFloat fxaaQualityEdgeThresholdMin,
    HQ_FxaaFloat fxaaConsoleEdgeSharpness,
    HQ_FxaaFloat fxaaConsoleEdgeThreshold,
    HQ_FxaaFloat fxaaConsoleEdgeThresholdMin,
    HQ_FxaaFloat4 fxaaConsole360ConstDir
) {
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat lumaNw = FxaaLuma(HQ_FxaaTexTop(tex, fxaaConsolePosPos.xy));
    HQ_FxaaFloat lumaSw = FxaaLuma(HQ_FxaaTexTop(tex, fxaaConsolePosPos.xw));
    HQ_FxaaFloat lumaNe = FxaaLuma(HQ_FxaaTexTop(tex, fxaaConsolePosPos.zy));
    HQ_FxaaFloat lumaSe = FxaaLuma(HQ_FxaaTexTop(tex, fxaaConsolePosPos.zw));
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat4 rgbyM = HQ_FxaaTexTop(tex, pos.xy);
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        HQ_FxaaFloat lumaM = rgbyM.w;
    #else
        HQ_FxaaFloat lumaM = rgbyM.y;
    #endif
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat lumaMaxNwSw = max(lumaNw, lumaSw);
    lumaNe += 1.0/384.0;
    HQ_FxaaFloat lumaMinNwSw = min(lumaNw, lumaSw);
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat lumaMaxNeSe = max(lumaNe, lumaSe);
    HQ_FxaaFloat lumaMinNeSe = min(lumaNe, lumaSe);
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat lumaMax = max(lumaMaxNeSe, lumaMaxNwSw);
    HQ_FxaaFloat lumaMin = min(lumaMinNeSe, lumaMinNwSw);
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat lumaMaxScaled = lumaMax * fxaaConsoleEdgeThreshold;
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat lumaMinM = min(lumaMin, lumaM);
    HQ_FxaaFloat lumaMaxScaledClamped = max(fxaaConsoleEdgeThresholdMin, lumaMaxScaled);
    HQ_FxaaFloat lumaMaxM = max(lumaMax, lumaM);
    HQ_FxaaFloat dirSwMinusNe = lumaSw - lumaNe;
    HQ_FxaaFloat lumaMaxSubMinM = lumaMaxM - lumaMinM;
    HQ_FxaaFloat dirSeMinusNw = lumaSe - lumaNw;
    if(lumaMaxSubMinM < lumaMaxScaledClamped) return rgbyM;
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat2 dir;
    dir.x = dirSwMinusNe + dirSeMinusNw;
    dir.y = dirSwMinusNe - dirSeMinusNw;
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat2 dir1 = normalize(dir.xy);
    HQ_FxaaFloat4 rgbyN1 = HQ_FxaaTexTop(tex, pos.xy - dir1 * fxaaConsoleRcpFrameOpt.zw);
    HQ_FxaaFloat4 rgbyP1 = HQ_FxaaTexTop(tex, pos.xy + dir1 * fxaaConsoleRcpFrameOpt.zw);
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat dirAbsMinTimesC = min(abs(dir1.x), abs(dir1.y)) * fxaaConsoleEdgeSharpness;
    HQ_FxaaFloat2 dir2 = clamp(dir1.xy / dirAbsMinTimesC, -2.0, 2.0);
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat4 rgbyN2 = HQ_FxaaTexTop(tex, pos.xy - dir2 * fxaaConsoleRcpFrameOpt2.zw);
    HQ_FxaaFloat4 rgbyP2 = HQ_FxaaTexTop(tex, pos.xy + dir2 * fxaaConsoleRcpFrameOpt2.zw);
/*--------------------------------------------------------------------------*/
    HQ_FxaaFloat4 rgbyA = rgbyN1 + rgbyP1;
    HQ_FxaaFloat4 rgbyB = ((rgbyN2 + rgbyP2) * 0.25) + (rgbyA * 0.25);
/*--------------------------------------------------------------------------*/
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        HQ_FxaaBool twoTap = (rgbyB.w < lumaMin) || (rgbyB.w > lumaMax);
    #else
        HQ_FxaaBool twoTap = (rgbyB.y < lumaMin) || (rgbyB.y > lumaMax);
    #endif
    if(twoTap) rgbyB.xyz = rgbyA.xyz * 0.5;
    return rgbyB; }
/*==========================================================================*/
#endif



/*============================================================================

                      FXAA3 CONSOLE - 360 PIXEL SHADER 

------------------------------------------------------------------------------
This optimized version thanks to suggestions from Andy Luedke.
Should be fully tex bound in all cases.
As of the FXAA 3.11 release, I have still not tested this code,
however I fixed a bug which was in both FXAA 3.9 and FXAA 3.10.
And note this is replacing the old unoptimized version.
If it does not work, please let me know so I can fix it.
============================================================================*/
#if (HQ_FXAA_360 == 1)
/*--------------------------------------------------------------------------*/
[reduceTempRegUsage(4)]
float4 FxaaPixelShader(
    // See FXAA Quality FxaaPixelShader() source for docs on Inputs!
    HQ_FxaaFloat2 pos,
    HQ_FxaaFloat4 fxaaConsolePosPos,
    HQ_FxaaTex tex,
    HQ_FxaaTex fxaaConsole360TexExpBiasNegOne,
    HQ_FxaaTex fxaaConsole360TexExpBiasNegTwo,
    HQ_FxaaFloat2 fxaaQualityRcpFrame,
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt,
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt2,
    HQ_FxaaFloat4 fxaaConsole360RcpFrameOpt2,
    HQ_FxaaFloat fxaaQualitySubpix,
    HQ_FxaaFloat fxaaQualityEdgeThreshold,
    HQ_FxaaFloat fxaaQualityEdgeThresholdMin,
    HQ_FxaaFloat fxaaConsoleEdgeSharpness,
    HQ_FxaaFloat fxaaConsoleEdgeThreshold,
    HQ_FxaaFloat fxaaConsoleEdgeThresholdMin,
    HQ_FxaaFloat4 fxaaConsole360ConstDir
) {
/*--------------------------------------------------------------------------*/
    float4 lumaNwNeSwSe;
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        asm { 
            tfetch2D lumaNwNeSwSe.w___, tex, pos.xy, OffsetX = -0.5, OffsetY = -0.5, UseComputedLOD=false
            tfetch2D lumaNwNeSwSe._w__, tex, pos.xy, OffsetX =  0.5, OffsetY = -0.5, UseComputedLOD=false
            tfetch2D lumaNwNeSwSe.__w_, tex, pos.xy, OffsetX = -0.5, OffsetY =  0.5, UseComputedLOD=false
            tfetch2D lumaNwNeSwSe.___w, tex, pos.xy, OffsetX =  0.5, OffsetY =  0.5, UseComputedLOD=false
        };
    #else
        asm { 
            tfetch2D lumaNwNeSwSe.y___, tex, pos.xy, OffsetX = -0.5, OffsetY = -0.5, UseComputedLOD=false
            tfetch2D lumaNwNeSwSe._y__, tex, pos.xy, OffsetX =  0.5, OffsetY = -0.5, UseComputedLOD=false
            tfetch2D lumaNwNeSwSe.__y_, tex, pos.xy, OffsetX = -0.5, OffsetY =  0.5, UseComputedLOD=false
            tfetch2D lumaNwNeSwSe.___y, tex, pos.xy, OffsetX =  0.5, OffsetY =  0.5, UseComputedLOD=false
        };
    #endif
/*--------------------------------------------------------------------------*/
    lumaNwNeSwSe.y += 1.0/384.0;
    float2 lumaMinTemp = min(lumaNwNeSwSe.xy, lumaNwNeSwSe.zw);
    float2 lumaMaxTemp = max(lumaNwNeSwSe.xy, lumaNwNeSwSe.zw);
    float lumaMin = min(lumaMinTemp.x, lumaMinTemp.y);
    float lumaMax = max(lumaMaxTemp.x, lumaMaxTemp.y);
/*--------------------------------------------------------------------------*/
    float4 rgbyM = tex2Dlod(tex, float4(pos.xy, 0.0, 0.0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        float lumaMinM = min(lumaMin, rgbyM.w);
        float lumaMaxM = max(lumaMax, rgbyM.w);
    #else
        float lumaMinM = min(lumaMin, rgbyM.y);
        float lumaMaxM = max(lumaMax, rgbyM.y);
    #endif        
    if((lumaMaxM - lumaMinM) < max(fxaaConsoleEdgeThresholdMin, lumaMax * fxaaConsoleEdgeThreshold)) return rgbyM;
/*--------------------------------------------------------------------------*/
    float2 dir;
    dir.x = dot(lumaNwNeSwSe, fxaaConsole360ConstDir.yyxx);
    dir.y = dot(lumaNwNeSwSe, fxaaConsole360ConstDir.xyxy);
    dir = normalize(dir);
/*--------------------------------------------------------------------------*/
    float4 dir1 = dir.xyxy * fxaaConsoleRcpFrameOpt.xyzw;
/*--------------------------------------------------------------------------*/
    float4 dir2;
    float dirAbsMinTimesC = min(abs(dir.x), abs(dir.y)) * fxaaConsoleEdgeSharpness;
    dir2 = saturate(fxaaConsole360ConstDir.zzww * dir.xyxy / dirAbsMinTimesC + 0.5);
    dir2 = dir2 * fxaaConsole360RcpFrameOpt2.xyxy + fxaaConsole360RcpFrameOpt2.zwzw;
/*--------------------------------------------------------------------------*/
    float4 rgbyN1 = tex2Dlod(fxaaConsole360TexExpBiasNegOne, float4(pos.xy + dir1.xy, 0.0, 0.0));
    float4 rgbyP1 = tex2Dlod(fxaaConsole360TexExpBiasNegOne, float4(pos.xy + dir1.zw, 0.0, 0.0));
    float4 rgbyN2 = tex2Dlod(fxaaConsole360TexExpBiasNegTwo, float4(pos.xy + dir2.xy, 0.0, 0.0));
    float4 rgbyP2 = tex2Dlod(fxaaConsole360TexExpBiasNegTwo, float4(pos.xy + dir2.zw, 0.0, 0.0));
/*--------------------------------------------------------------------------*/
    float4 rgbyA = rgbyN1 + rgbyP1;
    float4 rgbyB = rgbyN2 + rgbyP2 + rgbyA * 0.5;
/*--------------------------------------------------------------------------*/
    float4 rgbyR;
    if ((FxaaLuma(rgbyB) - lumaMax) > 0.0)
        rgbyR = rgbyA;
    else
        rgbyR = rgbyB;
    if ((FxaaLuma(rgbyB) - lumaMin) < 0.0);
        rgbyR = rgbyA;
    return rgbyR; }
/*==========================================================================*/
#endif



/*============================================================================

         FXAA3 CONSOLE - OPTIMIZED PS3 PIXEL SHADER (NO EARLY EXIT)

==============================================================================
The code below does not exactly match the assembly.
I have a feeling that 12 cycles is possible, but was not able to get there.
Might have to increase register count to get full performance.
Note this shader does not use perspective interpolation.

Use the following cgc options,

  --fenable-bx2 --fastmath --fastprecision --nofloatbindings

------------------------------------------------------------------------------
                             NVSHADERPERF OUTPUT
------------------------------------------------------------------------------
For reference and to aid in debug, output of NVShaderPerf should match this,

Shader to schedule:
  0: texpkb h0.w(TRUE), v5.zyxx, #0
  2: addh h2.z(TRUE), h0.w, constant(0.001953, 0.000000, 0.000000, 0.000000).x
  4: texpkb h0.w(TRUE), v5.xwxx, #0
  6: addh h0.z(TRUE), -h2, h0.w
  7: texpkb h1.w(TRUE), v5, #0
  9: addh h0.x(TRUE), h0.z, -h1.w
 10: addh h3.w(TRUE), h0.z, h1
 11: texpkb h2.w(TRUE), v5.zwzz, #0
 13: addh h0.z(TRUE), h3.w, -h2.w
 14: addh h0.x(TRUE), h2.w, h0
 15: nrmh h1.xz(TRUE), h0_n
 16: minh_m8 h0.x(TRUE), |h1|, |h1.z|
 17: maxh h4.w(TRUE), h0, h1
 18: divx h2.xy(TRUE), h1_n.xzzw, h0_n
 19: movr r1.zw(TRUE), v4.xxxy
 20: madr r2.xz(TRUE), -h1, constant(cConst5.x, cConst5.y, cConst5.z, cConst5.w).zzww, r1.zzww
 22: minh h5.w(TRUE), h0, h1
 23: texpkb h0(TRUE), r2.xzxx, #0
 25: madr r0.zw(TRUE), h1.xzxz, constant(cConst5.x, cConst5.y, cConst5.z, cConst5.w), r1
 27: maxh h4.x(TRUE), h2.z, h2.w
 28: texpkb h1(TRUE), r0.zwzz, #0
 30: addh_d2 h1(TRUE), h0, h1
 31: madr r0.xy(TRUE), -h2, constant(cConst5.x, cConst5.y, cConst5.z, cConst5.w).xyxx, r1.zwzz
 33: texpkb h0(TRUE), r0, #0
 35: minh h4.z(TRUE), h2, h2.w
 36: fenct TRUE
 37: madr r1.xy(TRUE), h2, constant(cConst5.x, cConst5.y, cConst5.z, cConst5.w).xyxx, r1.zwzz
 39: texpkb h2(TRUE), r1, #0
 41: addh_d2 h0(TRUE), h0, h2
 42: maxh h2.w(TRUE), h4, h4.x
 43: minh h2.x(TRUE), h5.w, h4.z
 44: addh_d2 h0(TRUE), h0, h1
 45: slth h2.x(TRUE), h0.w, h2
 46: sgth h2.w(TRUE), h0, h2
 47: movh h0(TRUE), h0
 48: addx.c0 rc(TRUE), h2, h2.w
 49: movh h0(c0.NE.x), h1

IPU0 ------ Simplified schedule: --------
Pass |  Unit  |  uOp |  PC:  Op
-----+--------+------+-------------------------
   1 | SCT0/1 |  mov |   0:  TXLr h0.w, g[TEX1].zyxx, const.xxxx, TEX0;
     |    TEX |  txl |   0:  TXLr h0.w, g[TEX1].zyxx, const.xxxx, TEX0;
     |   SCB1 |  add |   2:  ADDh h2.z, h0.--w-, const.--x-;
     |        |      |
   2 | SCT0/1 |  mov |   4:  TXLr h0.w, g[TEX1].xwxx, const.xxxx, TEX0;
     |    TEX |  txl |   4:  TXLr h0.w, g[TEX1].xwxx, const.xxxx, TEX0;
     |   SCB1 |  add |   6:  ADDh h0.z,-h2, h0.--w-;
     |        |      |
   3 | SCT0/1 |  mov |   7:  TXLr h1.w, g[TEX1], const.xxxx, TEX0;
     |    TEX |  txl |   7:  TXLr h1.w, g[TEX1], const.xxxx, TEX0;
     |   SCB0 |  add |   9:  ADDh h0.x, h0.z---,-h1.w---;
     |   SCB1 |  add |  10:  ADDh h3.w, h0.---z, h1;
     |        |      |
   4 | SCT0/1 |  mov |  11:  TXLr h2.w, g[TEX1].zwzz, const.xxxx, TEX0;
     |    TEX |  txl |  11:  TXLr h2.w, g[TEX1].zwzz, const.xxxx, TEX0;
     |   SCB0 |  add |  14:  ADDh h0.x, h2.w---, h0;
     |   SCB1 |  add |  13:  ADDh h0.z, h3.--w-,-h2.--w-;
     |        |      |
   5 |   SCT1 |  mov |  15:  NRMh h1.xz, h0;
     |    SRB |  nrm |  15:  NRMh h1.xz, h0;
     |   SCB0 |  min |  16:  MINh*8 h0.x, |h1|, |h1.z---|;
     |   SCB1 |  max |  17:  MAXh h4.w, h0, h1;
     |        |      |
   6 |   SCT0 |  div |  18:  DIVx h2.xy, h1.xz--, h0;
     |   SCT1 |  mov |  19:  MOVr r1.zw, g[TEX0].--xy;
     |   SCB0 |  mad |  20:  MADr r2.xz,-h1, const.z-w-, r1.z-w-;
     |   SCB1 |  min |  22:  MINh h5.w, h0, h1;
     |        |      |
   7 | SCT0/1 |  mov |  23:  TXLr h0, r2.xzxx, const.xxxx, TEX0;
     |    TEX |  txl |  23:  TXLr h0, r2.xzxx, const.xxxx, TEX0;
     |   SCB0 |  max |  27:  MAXh h4.x, h2.z---, h2.w---;
     |   SCB1 |  mad |  25:  MADr r0.zw, h1.--xz, const, r1;
     |        |      |
   8 | SCT0/1 |  mov |  28:  TXLr h1, r0.zwzz, const.xxxx, TEX0;
     |    TEX |  txl |  28:  TXLr h1, r0.zwzz, const.xxxx, TEX0;
     | SCB0/1 |  add |  30:  ADDh/2 h1, h0, h1;
     |        |      |
   9 |   SCT0 |  mad |  31:  MADr r0.xy,-h2, const.xy--, r1.zw--;
     |   SCT1 |  mov |  33:  TXLr h0, r0, const.zzzz, TEX0;
     |    TEX |  txl |  33:  TXLr h0, r0, const.zzzz, TEX0;
     |   SCB1 |  min |  35:  MINh h4.z, h2, h2.--w-;
     |        |      |
  10 |   SCT0 |  mad |  37:  MADr r1.xy, h2, const.xy--, r1.zw--;
     |   SCT1 |  mov |  39:  TXLr h2, r1, const.zzzz, TEX0;
     |    TEX |  txl |  39:  TXLr h2, r1, const.zzzz, TEX0;
     | SCB0/1 |  add |  41:  ADDh/2 h0, h0, h2;
     |        |      |
  11 |   SCT0 |  min |  43:  MINh h2.x, h5.w---, h4.z---;
     |   SCT1 |  max |  42:  MAXh h2.w, h4, h4.---x;
     | SCB0/1 |  add |  44:  ADDh/2 h0, h0, h1;
     |        |      |
  12 |   SCT0 |  set |  45:  SLTh h2.x, h0.w---, h2;
     |   SCT1 |  set |  46:  SGTh h2.w, h0, h2;
     | SCB0/1 |  mul |  47:  MOVh h0, h0;
     |        |      |
  13 |   SCT0 |  mad |  48:  ADDxc0_s rc, h2, h2.w---;
     | SCB0/1 |  mul |  49:  MOVh h0(NE0.xxxx), h1;
 
Pass   SCT  TEX  SCB
  1:   0% 100%  25%
  2:   0% 100%  25%
  3:   0% 100%  50%
  4:   0% 100%  50%
  5:   0%   0%  50%
  6: 100%   0%  75%
  7:   0% 100%  75%
  8:   0% 100% 100%
  9:   0% 100%  25%
 10:   0% 100% 100%
 11:  50%   0% 100%
 12:  50%   0% 100%
 13:  25%   0% 100%

MEAN:  17%  61%  67%

Pass   SCT0  SCT1   TEX  SCB0  SCB1
  1:    0%    0%  100%    0%  100%
  2:    0%    0%  100%    0%  100%
  3:    0%    0%  100%  100%  100%
  4:    0%    0%  100%  100%  100%
  5:    0%    0%    0%  100%  100%
  6:  100%  100%    0%  100%  100%
  7:    0%    0%  100%  100%  100%
  8:    0%    0%  100%  100%  100%
  9:    0%    0%  100%    0%  100%
 10:    0%    0%  100%  100%  100%
 11:  100%  100%    0%  100%  100%
 12:  100%  100%    0%  100%  100%
 13:  100%    0%    0%  100%  100%

MEAN:   30%   23%   61%   76%  100%
Fragment Performance Setup: Driver RSX Compiler, GPU RSX, Flags 0x5
Results 13 cycles, 3 r regs, 923,076,923 pixels/s
============================================================================*/
#if (HQ_FXAA_PS3 == 1) && (HQ_FXAA_EARLY_EXIT == 0)
/*--------------------------------------------------------------------------*/
#pragma regcount 7
#pragma disablepc all
#pragma option O3
#pragma option OutColorPrec=fp16
#pragma texformat default RGBA8
/*==========================================================================*/
half4 FxaaPixelShader(
    // See FXAA Quality FxaaPixelShader() source for docs on Inputs!
    HQ_FxaaFloat2 pos,
    HQ_FxaaFloat4 fxaaConsolePosPos,
    HQ_FxaaTex tex,
    HQ_FxaaTex fxaaConsole360TexExpBiasNegOne,
    HQ_FxaaTex fxaaConsole360TexExpBiasNegTwo,
    HQ_FxaaFloat2 fxaaQualityRcpFrame,
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt,
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt2,
    HQ_FxaaFloat4 fxaaConsole360RcpFrameOpt2,
    HQ_FxaaFloat fxaaQualitySubpix,
    HQ_FxaaFloat fxaaQualityEdgeThreshold,
    HQ_FxaaFloat fxaaQualityEdgeThresholdMin,
    HQ_FxaaFloat fxaaConsoleEdgeSharpness,
    HQ_FxaaFloat fxaaConsoleEdgeThreshold,
    HQ_FxaaFloat fxaaConsoleEdgeThresholdMin,
    HQ_FxaaFloat4 fxaaConsole360ConstDir
) {
/*--------------------------------------------------------------------------*/
// (1)
    half4 dir;
    half4 lumaNe = h4tex2Dlod(tex, half4(fxaaConsolePosPos.zy, 0, 0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        lumaNe.w += half(1.0/512.0);
        dir.x = -lumaNe.w;
        dir.z = -lumaNe.w;
    #else
        lumaNe.y += half(1.0/512.0);
        dir.x = -lumaNe.y;
        dir.z = -lumaNe.y;
    #endif
/*--------------------------------------------------------------------------*/
// (2)
    half4 lumaSw = h4tex2Dlod(tex, half4(fxaaConsolePosPos.xw, 0, 0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        dir.x += lumaSw.w;
        dir.z += lumaSw.w;
    #else
        dir.x += lumaSw.y;
        dir.z += lumaSw.y;
    #endif        
/*--------------------------------------------------------------------------*/
// (3)
    half4 lumaNw = h4tex2Dlod(tex, half4(fxaaConsolePosPos.xy, 0, 0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        dir.x -= lumaNw.w;
        dir.z += lumaNw.w;
    #else
        dir.x -= lumaNw.y;
        dir.z += lumaNw.y;
    #endif
/*--------------------------------------------------------------------------*/
// (4)
    half4 lumaSe = h4tex2Dlod(tex, half4(fxaaConsolePosPos.zw, 0, 0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        dir.x += lumaSe.w;
        dir.z -= lumaSe.w;
    #else
        dir.x += lumaSe.y;
        dir.z -= lumaSe.y;
    #endif
/*--------------------------------------------------------------------------*/
// (5)
    half4 dir1_pos;
    dir1_pos.xy = normalize(dir.xyz).xz;
    half dirAbsMinTimesC = min(abs(dir1_pos.x), abs(dir1_pos.y)) * half(HQ_FXAA_CONSOLE__PS3_EDGE_SHARPNESS);
/*--------------------------------------------------------------------------*/
// (6)
    half4 dir2_pos;
    dir2_pos.xy = clamp(dir1_pos.xy / dirAbsMinTimesC, half(-2.0), half(2.0));
    dir1_pos.zw = pos.xy;
    dir2_pos.zw = pos.xy;
    half4 temp1N;
    temp1N.xy = dir1_pos.zw - dir1_pos.xy * fxaaConsoleRcpFrameOpt.zw;
/*--------------------------------------------------------------------------*/
// (7)
    temp1N = h4tex2Dlod(tex, half4(temp1N.xy, 0.0, 0.0));
    half4 rgby1;
    rgby1.xy = dir1_pos.zw + dir1_pos.xy * fxaaConsoleRcpFrameOpt.zw;
/*--------------------------------------------------------------------------*/
// (8)
    rgby1 = h4tex2Dlod(tex, half4(rgby1.xy, 0.0, 0.0));
    rgby1 = (temp1N + rgby1) * 0.5;
/*--------------------------------------------------------------------------*/
// (9)
    half4 temp2N;
    temp2N.xy = dir2_pos.zw - dir2_pos.xy * fxaaConsoleRcpFrameOpt2.zw;
    temp2N = h4tex2Dlod(tex, half4(temp2N.xy, 0.0, 0.0));
/*--------------------------------------------------------------------------*/
// (10)
    half4 rgby2;
    rgby2.xy = dir2_pos.zw + dir2_pos.xy * fxaaConsoleRcpFrameOpt2.zw;
    rgby2 = h4tex2Dlod(tex, half4(rgby2.xy, 0.0, 0.0));
    rgby2 = (temp2N + rgby2) * 0.5;
/*--------------------------------------------------------------------------*/
// (11)
    // compilier moves these scalar ops up to other cycles
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        half lumaMin = min(min(lumaNw.w, lumaSw.w), min(lumaNe.w, lumaSe.w));
        half lumaMax = max(max(lumaNw.w, lumaSw.w), max(lumaNe.w, lumaSe.w));
    #else
        half lumaMin = min(min(lumaNw.y, lumaSw.y), min(lumaNe.y, lumaSe.y));
        half lumaMax = max(max(lumaNw.y, lumaSw.y), max(lumaNe.y, lumaSe.y));
    #endif        
    rgby2 = (rgby2 + rgby1) * 0.5;
/*--------------------------------------------------------------------------*/
// (12)
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        bool twoTapLt = rgby2.w < lumaMin;
        bool twoTapGt = rgby2.w > lumaMax;
    #else
        bool twoTapLt = rgby2.y < lumaMin;
        bool twoTapGt = rgby2.y > lumaMax;
    #endif
/*--------------------------------------------------------------------------*/
// (13)
    if(twoTapLt || twoTapGt) rgby2 = rgby1;
/*--------------------------------------------------------------------------*/
    return rgby2; }
/*==========================================================================*/
#endif



/*============================================================================

       FXAA3 CONSOLE - OPTIMIZED PS3 PIXEL SHADER (WITH EARLY EXIT)

==============================================================================
The code mostly matches the assembly.
I have a feeling that 14 cycles is possible, but was not able to get there.
Might have to increase register count to get full performance.
Note this shader does not use perspective interpolation.

Use the following cgc options,

 --fenable-bx2 --fastmath --fastprecision --nofloatbindings

Use of HQ_FXAA_GREEN_AS_LUMA currently adds a cycle (16 clks).
Will look at fixing this for FXAA 3.12.
------------------------------------------------------------------------------
                             NVSHADERPERF OUTPUT
------------------------------------------------------------------------------
For reference and to aid in debug, output of NVShaderPerf should match this,

Shader to schedule:
  0: texpkb h0.w(TRUE), v5.zyxx, #0
  2: addh h2.y(TRUE), h0.w, constant(0.001953, 0.000000, 0.000000, 0.000000).x
  4: texpkb h1.w(TRUE), v5.xwxx, #0
  6: addh h0.x(TRUE), h1.w, -h2.y
  7: texpkb h2.w(TRUE), v5.zwzz, #0
  9: minh h4.w(TRUE), h2.y, h2
 10: maxh h5.x(TRUE), h2.y, h2.w
 11: texpkb h0.w(TRUE), v5, #0
 13: addh h3.w(TRUE), -h0, h0.x
 14: addh h0.x(TRUE), h0.w, h0
 15: addh h0.z(TRUE), -h2.w, h0.x
 16: addh h0.x(TRUE), h2.w, h3.w
 17: minh h5.y(TRUE), h0.w, h1.w
 18: nrmh h2.xz(TRUE), h0_n
 19: minh_m8 h2.w(TRUE), |h2.x|, |h2.z|
 20: divx h4.xy(TRUE), h2_n.xzzw, h2_n.w
 21: movr r1.zw(TRUE), v4.xxxy
 22: maxh h2.w(TRUE), h0, h1
 23: fenct TRUE
 24: madr r0.xy(TRUE), -h2.xzzw, constant(cConst5.x, cConst5.y, cConst5.z, cConst5.w).zwzz, r1.zwzz
 26: texpkb h0(TRUE), r0, #0
 28: maxh h5.x(TRUE), h2.w, h5
 29: minh h5.w(TRUE), h5.y, h4
 30: madr r1.xy(TRUE), h2.xzzw, constant(cConst5.x, cConst5.y, cConst5.z, cConst5.w).zwzz, r1.zwzz
 32: texpkb h2(TRUE), r1, #0
 34: addh_d2 h2(TRUE), h0, h2
 35: texpkb h1(TRUE), v4, #0
 37: maxh h5.y(TRUE), h5.x, h1.w
 38: minh h4.w(TRUE), h1, h5
 39: madr r0.xy(TRUE), -h4, constant(cConst5.x, cConst5.y, cConst5.z, cConst5.w).xyxx, r1.zwzz
 41: texpkb h0(TRUE), r0, #0
 43: addh_m8 h5.z(TRUE), h5.y, -h4.w
 44: madr r2.xy(TRUE), h4, constant(cConst5.x, cConst5.y, cConst5.z, cConst5.w).xyxx, r1.zwzz
 46: texpkb h3(TRUE), r2, #0
 48: addh_d2 h0(TRUE), h0, h3
 49: addh_d2 h3(TRUE), h0, h2
 50: movh h0(TRUE), h3
 51: slth h3.x(TRUE), h3.w, h5.w
 52: sgth h3.w(TRUE), h3, h5.x
 53: addx.c0 rc(TRUE), h3.x, h3
 54: slth.c0 rc(TRUE), h5.z, h5
 55: movh h0(c0.NE.w), h2
 56: movh h0(c0.NE.x), h1

IPU0 ------ Simplified schedule: --------
Pass |  Unit  |  uOp |  PC:  Op
-----+--------+------+-------------------------
   1 | SCT0/1 |  mov |   0:  TXLr h0.w, g[TEX1].zyxx, const.xxxx, TEX0;
     |    TEX |  txl |   0:  TXLr h0.w, g[TEX1].zyxx, const.xxxx, TEX0;
     |   SCB0 |  add |   2:  ADDh h2.y, h0.-w--, const.-x--;
     |        |      |
   2 | SCT0/1 |  mov |   4:  TXLr h1.w, g[TEX1].xwxx, const.xxxx, TEX0;
     |    TEX |  txl |   4:  TXLr h1.w, g[TEX1].xwxx, const.xxxx, TEX0;
     |   SCB0 |  add |   6:  ADDh h0.x, h1.w---,-h2.y---;
     |        |      |
   3 | SCT0/1 |  mov |   7:  TXLr h2.w, g[TEX1].zwzz, const.xxxx, TEX0;
     |    TEX |  txl |   7:  TXLr h2.w, g[TEX1].zwzz, const.xxxx, TEX0;
     |   SCB0 |  max |  10:  MAXh h5.x, h2.y---, h2.w---;
     |   SCB1 |  min |   9:  MINh h4.w, h2.---y, h2;
     |        |      |
   4 | SCT0/1 |  mov |  11:  TXLr h0.w, g[TEX1], const.xxxx, TEX0;
     |    TEX |  txl |  11:  TXLr h0.w, g[TEX1], const.xxxx, TEX0;
     |   SCB0 |  add |  14:  ADDh h0.x, h0.w---, h0;
     |   SCB1 |  add |  13:  ADDh h3.w,-h0, h0.---x;
     |        |      |
   5 |   SCT0 |  mad |  16:  ADDh h0.x, h2.w---, h3.w---;
     |   SCT1 |  mad |  15:  ADDh h0.z,-h2.--w-, h0.--x-;
     |   SCB0 |  min |  17:  MINh h5.y, h0.-w--, h1.-w--;
     |        |      |
   6 |   SCT1 |  mov |  18:  NRMh h2.xz, h0;
     |    SRB |  nrm |  18:  NRMh h2.xz, h0;
     |   SCB1 |  min |  19:  MINh*8 h2.w, |h2.---x|, |h2.---z|;
     |        |      |
   7 |   SCT0 |  div |  20:  DIVx h4.xy, h2.xz--, h2.ww--;
     |   SCT1 |  mov |  21:  MOVr r1.zw, g[TEX0].--xy;
     |   SCB1 |  max |  22:  MAXh h2.w, h0, h1;
     |        |      |
   8 |   SCT0 |  mad |  24:  MADr r0.xy,-h2.xz--, const.zw--, r1.zw--;
     |   SCT1 |  mov |  26:  TXLr h0, r0, const.xxxx, TEX0;
     |    TEX |  txl |  26:  TXLr h0, r0, const.xxxx, TEX0;
     |   SCB0 |  max |  28:  MAXh h5.x, h2.w---, h5;
     |   SCB1 |  min |  29:  MINh h5.w, h5.---y, h4;
     |        |      |
   9 |   SCT0 |  mad |  30:  MADr r1.xy, h2.xz--, const.zw--, r1.zw--;
     |   SCT1 |  mov |  32:  TXLr h2, r1, const.xxxx, TEX0;
     |    TEX |  txl |  32:  TXLr h2, r1, const.xxxx, TEX0;
     | SCB0/1 |  add |  34:  ADDh/2 h2, h0, h2;
     |        |      |
  10 | SCT0/1 |  mov |  35:  TXLr h1, g[TEX0], const.xxxx, TEX0;
     |    TEX |  txl |  35:  TXLr h1, g[TEX0], const.xxxx, TEX0;
     |   SCB0 |  max |  37:  MAXh h5.y, h5.-x--, h1.-w--;
     |   SCB1 |  min |  38:  MINh h4.w, h1, h5;
     |        |      |
  11 |   SCT0 |  mad |  39:  MADr r0.xy,-h4, const.xy--, r1.zw--;
     |   SCT1 |  mov |  41:  TXLr h0, r0, const.zzzz, TEX0;
     |    TEX |  txl |  41:  TXLr h0, r0, const.zzzz, TEX0;
     |   SCB0 |  mad |  44:  MADr r2.xy, h4, const.xy--, r1.zw--;
     |   SCB1 |  add |  43:  ADDh*8 h5.z, h5.--y-,-h4.--w-;
     |        |      |
  12 | SCT0/1 |  mov |  46:  TXLr h3, r2, const.xxxx, TEX0;
     |    TEX |  txl |  46:  TXLr h3, r2, const.xxxx, TEX0;
     | SCB0/1 |  add |  48:  ADDh/2 h0, h0, h3;
     |        |      |
  13 | SCT0/1 |  mad |  49:  ADDh/2 h3, h0, h2;
     | SCB0/1 |  mul |  50:  MOVh h0, h3;
     |        |      |
  14 |   SCT0 |  set |  51:  SLTh h3.x, h3.w---, h5.w---;
     |   SCT1 |  set |  52:  SGTh h3.w, h3, h5.---x;
     |   SCB0 |  set |  54:  SLThc0 rc, h5.z---, h5;
     |   SCB1 |  add |  53:  ADDxc0_s rc, h3.---x, h3;
     |        |      |
  15 | SCT0/1 |  mul |  55:  MOVh h0(NE0.wwww), h2;
     | SCB0/1 |  mul |  56:  MOVh h0(NE0.xxxx), h1;
 
Pass   SCT  TEX  SCB
  1:   0% 100%  25%
  2:   0% 100%  25%
  3:   0% 100%  50%
  4:   0% 100%  50%
  5:  50%   0%  25%
  6:   0%   0%  25%
  7: 100%   0%  25%
  8:   0% 100%  50%
  9:   0% 100% 100%
 10:   0% 100%  50%
 11:   0% 100%  75%
 12:   0% 100% 100%
 13: 100%   0% 100%
 14:  50%   0%  50%
 15: 100%   0% 100%

MEAN:  26%  60%  56%

Pass   SCT0  SCT1   TEX  SCB0  SCB1
  1:    0%    0%  100%  100%    0%
  2:    0%    0%  100%  100%    0%
  3:    0%    0%  100%  100%  100%
  4:    0%    0%  100%  100%  100%
  5:  100%  100%    0%  100%    0%
  6:    0%    0%    0%    0%  100%
  7:  100%  100%    0%    0%  100%
  8:    0%    0%  100%  100%  100%
  9:    0%    0%  100%  100%  100%
 10:    0%    0%  100%  100%  100%
 11:    0%    0%  100%  100%  100%
 12:    0%    0%  100%  100%  100%
 13:  100%  100%    0%  100%  100%
 14:  100%  100%    0%  100%  100%
 15:  100%  100%    0%  100%  100%

MEAN:   33%   33%   60%   86%   80%
Fragment Performance Setup: Driver RSX Compiler, GPU RSX, Flags 0x5
Results 15 cycles, 3 r regs, 800,000,000 pixels/s
============================================================================*/
#if (HQ_FXAA_PS3 == 1) && (HQ_FXAA_EARLY_EXIT == 1)
/*--------------------------------------------------------------------------*/
#pragma regcount 7
#pragma disablepc all
#pragma option O2
#pragma option OutColorPrec=fp16
#pragma texformat default RGBA8
/*==========================================================================*/
half4 FxaaPixelShader(
    // See FXAA Quality FxaaPixelShader() source for docs on Inputs!
    HQ_FxaaFloat2 pos,
    HQ_FxaaFloat4 fxaaConsolePosPos,
    HQ_FxaaTex tex,
    HQ_FxaaTex fxaaConsole360TexExpBiasNegOne,
    HQ_FxaaTex fxaaConsole360TexExpBiasNegTwo,
    HQ_FxaaFloat2 fxaaQualityRcpFrame,
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt,
    HQ_FxaaFloat4 fxaaConsoleRcpFrameOpt2,
    HQ_FxaaFloat4 fxaaConsole360RcpFrameOpt2,
    HQ_FxaaFloat fxaaQualitySubpix,
    HQ_FxaaFloat fxaaQualityEdgeThreshold,
    HQ_FxaaFloat fxaaQualityEdgeThresholdMin,
    HQ_FxaaFloat fxaaConsoleEdgeSharpness,
    HQ_FxaaFloat fxaaConsoleEdgeThreshold,
    HQ_FxaaFloat fxaaConsoleEdgeThresholdMin,
    HQ_FxaaFloat4 fxaaConsole360ConstDir
) {
/*--------------------------------------------------------------------------*/
// (1)
    half4 rgbyNe = h4tex2Dlod(tex, half4(fxaaConsolePosPos.zy, 0, 0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        half lumaNe = rgbyNe.w + half(1.0/512.0);
    #else
        half lumaNe = rgbyNe.y + half(1.0/512.0);
    #endif
/*--------------------------------------------------------------------------*/
// (2)
    half4 lumaSw = h4tex2Dlod(tex, half4(fxaaConsolePosPos.xw, 0, 0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        half lumaSwNegNe = lumaSw.w - lumaNe;
    #else
        half lumaSwNegNe = lumaSw.y - lumaNe;
    #endif
/*--------------------------------------------------------------------------*/
// (3)
    half4 lumaNw = h4tex2Dlod(tex, half4(fxaaConsolePosPos.xy, 0, 0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        half lumaMaxNwSw = max(lumaNw.w, lumaSw.w);
        half lumaMinNwSw = min(lumaNw.w, lumaSw.w);
    #else
        half lumaMaxNwSw = max(lumaNw.y, lumaSw.y);
        half lumaMinNwSw = min(lumaNw.y, lumaSw.y);
    #endif
/*--------------------------------------------------------------------------*/
// (4)
    half4 lumaSe = h4tex2Dlod(tex, half4(fxaaConsolePosPos.zw, 0, 0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        half dirZ =  lumaNw.w + lumaSwNegNe;
        half dirX = -lumaNw.w + lumaSwNegNe;
    #else
        half dirZ =  lumaNw.y + lumaSwNegNe;
        half dirX = -lumaNw.y + lumaSwNegNe;
    #endif
/*--------------------------------------------------------------------------*/
// (5)
    half3 dir;
    dir.y = 0.0;
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        dir.x =  lumaSe.w + dirX;
        dir.z = -lumaSe.w + dirZ;
        half lumaMinNeSe = min(lumaNe, lumaSe.w);
    #else
        dir.x =  lumaSe.y + dirX;
        dir.z = -lumaSe.y + dirZ;
        half lumaMinNeSe = min(lumaNe, lumaSe.y);
    #endif
/*--------------------------------------------------------------------------*/
// (6)
    half4 dir1_pos;
    dir1_pos.xy = normalize(dir).xz;
    half dirAbsMinTimes8 = min(abs(dir1_pos.x), abs(dir1_pos.y)) * half(HQ_FXAA_CONSOLE__PS3_EDGE_SHARPNESS);
/*--------------------------------------------------------------------------*/
// (7)
    half4 dir2_pos;
    dir2_pos.xy = clamp(dir1_pos.xy / dirAbsMinTimes8, half(-2.0), half(2.0));
    dir1_pos.zw = pos.xy;
    dir2_pos.zw = pos.xy;
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        half lumaMaxNeSe = max(lumaNe, lumaSe.w);
    #else
        half lumaMaxNeSe = max(lumaNe, lumaSe.y);
    #endif
/*--------------------------------------------------------------------------*/
// (8)
    half4 temp1N;
    temp1N.xy = dir1_pos.zw - dir1_pos.xy * fxaaConsoleRcpFrameOpt.zw;
    temp1N = h4tex2Dlod(tex, half4(temp1N.xy, 0.0, 0.0));
    half lumaMax = max(lumaMaxNwSw, lumaMaxNeSe);
    half lumaMin = min(lumaMinNwSw, lumaMinNeSe);
/*--------------------------------------------------------------------------*/
// (9)
    half4 rgby1;
    rgby1.xy = dir1_pos.zw + dir1_pos.xy * fxaaConsoleRcpFrameOpt.zw;
    rgby1 = h4tex2Dlod(tex, half4(rgby1.xy, 0.0, 0.0));
    rgby1 = (temp1N + rgby1) * 0.5;
/*--------------------------------------------------------------------------*/
// (10)
    half4 rgbyM = h4tex2Dlod(tex, half4(pos.xy, 0.0, 0.0));
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        half lumaMaxM = max(lumaMax, rgbyM.w);
        half lumaMinM = min(lumaMin, rgbyM.w);
    #else
        half lumaMaxM = max(lumaMax, rgbyM.y);
        half lumaMinM = min(lumaMin, rgbyM.y);
    #endif
/*--------------------------------------------------------------------------*/
// (11)
    half4 temp2N;
    temp2N.xy = dir2_pos.zw - dir2_pos.xy * fxaaConsoleRcpFrameOpt2.zw;
    temp2N = h4tex2Dlod(tex, half4(temp2N.xy, 0.0, 0.0));
    half4 rgby2;
    rgby2.xy = dir2_pos.zw + dir2_pos.xy * fxaaConsoleRcpFrameOpt2.zw;
    half lumaRangeM = (lumaMaxM - lumaMinM) / HQ_FXAA_CONSOLE__PS3_EDGE_THRESHOLD;
/*--------------------------------------------------------------------------*/
// (12)
    rgby2 = h4tex2Dlod(tex, half4(rgby2.xy, 0.0, 0.0));
    rgby2 = (temp2N + rgby2) * 0.5;
/*--------------------------------------------------------------------------*/
// (13)
    rgby2 = (rgby2 + rgby1) * 0.5;
/*--------------------------------------------------------------------------*/
// (14)
    #if (HQ_FXAA_GREEN_AS_LUMA == 0)
        bool twoTapLt = rgby2.w < lumaMin;
        bool twoTapGt = rgby2.w > lumaMax;
    #else
        bool twoTapLt = rgby2.y < lumaMin;
        bool twoTapGt = rgby2.y > lumaMax;
    #endif
    bool earlyExit = lumaRangeM < lumaMax;
    bool twoTap = twoTapLt || twoTapGt;
/*--------------------------------------------------------------------------*/
// (15)
    if(twoTap) rgby2 = rgby1;
    if(earlyExit) rgby2 = rgbyM;
/*--------------------------------------------------------------------------*/
    return rgby2; }
/*==========================================================================*/
#endif

/**
 * Copyright (C) 2013 Jorge Jimenez (jorge@iryoku.com)
 * Copyright (C) 2013 Jose I. Echevarria (joseignacioechevarria@gmail.com)
 * Copyright (C) 2013 Belen Masia (bmasia@unizar.es)
 * Copyright (C) 2013 Fernando Navarro (fernandn@microsoft.com)
 * Copyright (C) 2013 Diego Gutierrez (diegog@unizar.es)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to
 * do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software. As clarification, there
 * is no requirement that the copyright notice and permission be included in
 * binary distributions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
 // Lightly optimized by Marot Satil for the GShade project.


/**
 *                  _______  ___  ___       ___           ___
 *                 /       ||   \/   |     /   \         /   \
 *                |   (---- |  \  /  |    /  ^  \       /  ^  \
 *                 \   \    |  |\/|  |   /  /_\  \     /  /_\  \
 *              ----)   |   |  |  |  |  /  _____  \   /  _____  \
 *             |_______/    |__|  |__| /__/     \__\ /__/     \__\
 * 
 *                               E N H A N C E D
 *       S U B P I X E L   M O R P H O L O G I C A L   A N T I A L I A S I N G
 *
 *                         http://www.iryoku.com/smaa/
 *
 * Hi, welcome aboard!
 * 
 * Here you'll find instructions to get the shader up and running as fast as
 * possible.
 *
 * IMPORTANTE NOTICE: when updating, remember to update both this file and the
 * precomputed textures! They may change from version to version.
 *
 * The shader has three passes, chained together as follows:
 *
 *                           |input|------------------+
 *                              v                     |
 *                    [ SMAA*EdgeDetection ]          |
 *                              v                     |
 *                          |edgesTex|                |
 *                              v                     |
 *              [ SMAABlendingWeightCalculation ]     |
 *                              v                     |
 *                          |blendTex|                |
 *                              v                     |
 *                [ SMAANeighborhoodBlending ] <------+
 *                              v
 *                           |output|
 *
 * Note that each [pass] has its own vertex and pixel shader. Remember to use
 * oversized triangles instead of quads to avoid overshading along the
 * diagonal.
 *
 * You've three edge detection methods to choose from: luma, color or depth.
 * They represent different quality/performance and anti-aliasing/sharpness
 * tradeoffs, so our recommendation is for you to choose the one that best
 * suits your particular scenario:
 *
 * - Depth edge detection is usually the fastest but it may miss some edges.
 *
 * - Luma edge detection is usually more expensive than depth edge detection,
 *   but catches visible edges that depth edge detection can miss.
 *
 * - Color edge detection is usually the most expensive one but catches
 *   chroma-only edges.
 *
 * For quickstarters: just use luma edge detection.
 *
 * The general advice is to not rush the integration process and ensure each
 * step is done correctly (don't try to integrate SMAA T2x with predicated edge
 * detection from the start!). Ok then, let's go!
 *
 *  1. The first step is to create two RGBA temporal render targets for holding
 *     |edgesTex| and |blendTex|.
 *
 *     In DX10 or DX11, you can use a RG render target for the edges texture.
 *     In the case of NVIDIA GPUs, using RG render targets seems to actually be
 *     slower.
 *
 *     On the Xbox 360, you can use the same render target for resolving both
 *     |edgesTex| and |blendTex|, as they aren't needed simultaneously.
 *
 *  2. Both temporal render targets |edgesTex| and |blendTex| must be cleared
 *     each frame. Do not forget to clear the alpha channel!
 *
 *  3. The next step is loading the two supporting precalculated textures,
 *     'areaTex' and 'searchTex'. You'll find them in the 'Textures' folder as
 *     C++ headers, and also as regular DDS files. They'll be needed for the
 *     'SMAABlendingWeightCalculation' pass.
 *
 *     If you use the C++ headers, be sure to load them in the format specified
 *     inside of them.
 *
 *     You can also compress 'areaTex' and 'searchTex' using BC5 and BC4
 *     respectively, if you have that option in your content processor pipeline.
 *     When compressing then, you get a non-perceptible quality decrease, and a
 *     marginal performance increase.
 *
 *  4. All samplers must be set to linear filtering and clamp.
 *
 *     After you get the technique working, remember that 64-bit inputs have
 *     half-rate linear filtering on GCN.
 *
 *     If SMAA is applied to 64-bit color buffers, switching to point filtering
 *     when accesing them will increase the performance. Search for
 *     'HQ_SMAASamplePoint' to see which textures may benefit from point
 *     filtering, and where (which is basically the color input in the edge
 *     detection and resolve passes).
 *
 *  5. All texture reads and buffer writes must be non-sRGB, with the exception
 *     of the input read and the output write in
 *     'SMAANeighborhoodBlending' (and only in this pass!). If sRGB reads in
 *     this last pass are not possible, the technique will work anyway, but
 *     will perform antialiasing in gamma space.
 *
 *     IMPORTANT: for best results the input read for the color/luma edge 
 *     detection should *NOT* be sRGB.
 *
 *  6. Before including SMAA.h you'll have to setup the render target metrics,
 *     the target and any optional configuration defines. Optionally you can
 *     use a preset.
 *
 *     You have the following targets available: 
 *         HQ_SMAA_HLSL_3
 *         HQ_SMAA_HLSL_4
 *         HQ_SMAA_HLSL_4_1
 *         HQ_SMAA_GLSL_3 *
 *         HQ_SMAA_GLSL_4 *
 *
 *         * (See HQ_SMAA_INCLUDE_VS and HQ_SMAA_INCLUDE_PS below).
 *
 *     And four presets:
 *         HQ_SMAA_PRESET_LOW          (%60 of the quality)
 *         HQ_SMAA_PRESET_MEDIUM       (%80 of the quality)
 *         HQ_SMAA_PRESET_HIGH         (%95 of the quality)
 *         HQ_SMAA_PRESET_ULTRA        (%99 of the quality)
 *
 *     For example:
 *         #define HQ_SMAA_RT_METRICS float4(1.0 / 1280.0, 1.0 / 720.0, 1280.0, 720.0)
 *         #define HQ_SMAA_HLSL_4
 *         #define HQ_SMAA_PRESET_HIGH
 *         #include "SMAA.h"
 *
 *     Note that HQ_SMAA_RT_METRICS doesn't need to be a macro, it can be a
 *     uniform variable. The code is designed to minimize the impact of not
 *     using a constant value, but it is still better to hardcode it.
 *
 *     Depending on how you encoded 'areaTex' and 'searchTex', you may have to
 *     add (and customize) the following defines before including SMAA.h:
 *          #define HQ_SMAA_AREATEX_SELECT(sample) sample.rg
 *          #define HQ_SMAA_SEARCHTEX_SELECT(sample) sample.r
 *
 *     If your engine is already using porting macros, you can define
 *     HQ_SMAA_CUSTOM_SL, and define the porting functions by yourself.
 *
 *  7. Then, you'll have to setup the passes as indicated in the scheme above.
 *     You can take a look into SMAA.fx, to see how we did it for our demo.
 *     Checkout the function wrappers, you may want to copy-paste them!
 *
 *  8. It's recommended to validate the produced |edgesTex| and |blendTex|.
 *     You can use a screenshot from your engine to compare the |edgesTex|
 *     and |blendTex| produced inside of the engine with the results obtained
 *     with the reference demo.
 *
 *  9. After you get the last pass to work, it's time to optimize. You'll have
 *     to initialize a stencil buffer in the first pass (discard is already in
 *     the code), then mask execution by using it the second pass. The last
 *     pass should be executed in all pixels.
 *
 *
 * After this point you can choose to enable predicated thresholding,
 * temporal supersampling and motion blur integration:
 *
 * a) If you want to use predicated thresholding, take a look into
 *    HQ_SMAA_PREDICATION; you'll need to pass an extra texture in the edge
 *    detection pass.
 *
 * b) If you want to enable temporal supersampling (SMAA T2x):
 *
 * 1. The first step is to render using subpixel jitters. I won't go into
 *    detail, but it's as simple as moving each vertex position in the
 *    vertex shader, you can check how we do it in our DX10 demo.
 *
 * 2. Then, you must setup the temporal resolve. You may want to take a look
 *    into SMAAResolve for resolving 2x modes. After you get it working, you'll
 *    probably see ghosting everywhere. But fear not, you can enable the
 *    CryENGINE temporal reprojection by setting the HQ_SMAA_REPROJECTION macro.
 *    Check out HQ_SMAA_DECODE_VELOCITY if your velocity buffer is encoded.
 *
 * 3. The next step is to apply SMAA to each subpixel jittered frame, just as
 *    done for 1x.
 *
 * 4. At this point you should already have something usable, but for best
 *    results the proper area textures must be set depending on current jitter.
 *    For this, the parameter 'subsampleIndices' of
 *    'SMAABlendingWeightCalculationPS' must be set as follows, for our T2x
 *    mode:
 *
 *    @SUBSAMPLE_INDICES
 *
 *    | S# |  Camera Jitter   |  subsampleIndices    |
 *    +----+------------------+---------------------+
 *    |  0 |  ( 0.25, -0.25)  |  float4(1, 1, 1, 0)  |
 *    |  1 |  (-0.25,  0.25)  |  float4(2, 2, 2, 0)  |
 *
 *    These jitter positions assume a bottom-to-top y axis. S# stands for the
 *    sample number.
 *
 * More information about temporal supersampling here:
 *    http://iryoku.com/aacourse/downloads/13-Anti-Aliasing-Methods-in-CryENGINE-3.pdf
 *
 * c) If you want to enable spatial multisampling (SMAA S2x):
 *
 * 1. The scene must be rendered using MSAA 2x. The MSAA 2x buffer must be
 *    created with:
 *      - DX10:     see below (*)
 *      - DX10.1:   D3D10_STANDARD_MULTISAMPLE_PATTERN or
 *      - DX11:     D3D11_STANDARD_MULTISAMPLE_PATTERN
 *
 *    This allows to ensure that the subsample order matches the table in
 *    @SUBSAMPLE_INDICES.
 *
 *    (*) In the case of DX10, we refer the reader to:
 *      - SMAA::detectMSAAOrder and
 *      - SMAA::msaaReorder
 *
 *    These functions allow to match the standard multisample patterns by
 *    detecting the subsample order for a specific GPU, and reordering
 *    them appropriately.
 *
 * 2. A shader must be run to output each subsample into a separate buffer
 *    (DX10 is required). You can use SMAASeparate for this purpose, or just do
 *    it in an existing pass (for example, in the tone mapping pass, which has
 *    the advantage of feeding tone mapped subsamples to SMAA, which will yield
 *    better results).
 *
 * 3. The full SMAA 1x pipeline must be run for each separated buffer, storing
 *    the results in the final buffer. The second run should alpha blend with
 *    the existing final buffer using a blending factor of 0.5.
 *    'subsampleIndices' must be adjusted as in the SMAA T2x case (see point
 *    b).
 *
 * d) If you want to enable temporal supersampling on top of SMAA S2x
 *    (which actually is SMAA 4x):
 *
 * 1. SMAA 4x consists on temporally jittering SMAA S2x, so the first step is
 *    to calculate SMAA S2x for current frame. In this case, 'subsampleIndices'
 *    must be set as follows:
 *
 *    | F# | S# |   Camera Jitter    |    Net Jitter     |   subsampleIndices   |
 *    +----+----+--------------------+-------------------+----------------------+
 *    |  0 |  0 |  ( 0.125,  0.125)  |  ( 0.375, -0.125) |  float4(5, 3, 1, 3)  |
 *    |  0 |  1 |  ( 0.125,  0.125)  |  (-0.125,  0.375) |  float4(4, 6, 2, 3)  |
 *    +----+----+--------------------+-------------------+----------------------+
 *    |  1 |  2 |  (-0.125, -0.125)  |  ( 0.125, -0.375) |  float4(3, 5, 1, 4)  |
 *    |  1 |  3 |  (-0.125, -0.125)  |  (-0.375,  0.125) |  float4(6, 4, 2, 4)  |
 *
 *    These jitter positions assume a bottom-to-top y axis. F# stands for the
 *    frame number. S# stands for the sample number.
 *
 * 2. After calculating SMAA S2x for current frame (with the new subsample
 *    indices), previous frame must be reprojected as in SMAA T2x mode (see
 *    point b).
 *
 * e) If motion blur is used, you may want to do the edge detection pass
 *    together with motion blur. This has two advantages:
 *
 * 1. Pixels under heavy motion can be omitted from the edge detection process.
 *    For these pixels we can just store "no edge", as motion blur will take
 *    care of them.
 * 2. The center pixel tap is reused.
 *
 * Note that in this case depth testing should be used instead of stenciling,
 * as we have to write all the pixels in the motion blur pass.
 *
 * That's it!
 */

//-----------------------------------------------------------------------------
// SMAA Presets

/**
 * Note that if you use one of these presets, the following configuration
 * macros will be ignored if set in the "Configurable Defines" section.
 */

#if defined(HQ_SMAA_PRESET_LOW)
#define HQ_SMAA_THRESHOLD 0.15
#define HQ_SMAA_MAX_SEARCH_STEPS 4
#define HQ_SMAA_DISABLE_DIAG_DETECTION
#define HQ_SMAA_DISABLE_CORNER_DETECTION
#elif defined(HQ_SMAA_PRESET_MEDIUM)
#define HQ_SMAA_THRESHOLD 0.1
#define HQ_SMAA_MAX_SEARCH_STEPS 8
#define HQ_SMAA_DISABLE_DIAG_DETECTION
#define HQ_SMAA_DISABLE_CORNER_DETECTION
#elif defined(HQ_SMAA_PRESET_HIGH)
#define HQ_SMAA_THRESHOLD 0.1
#define HQ_SMAA_MAX_SEARCH_STEPS 16
#define HQ_SMAA_MAX_SEARCH_STEPS_DIAG 8
#define HQ_SMAA_CORNER_ROUNDING 25
#elif defined(HQ_SMAA_PRESET_ULTRA)
#define HQ_SMAA_THRESHOLD 0.05
#define HQ_SMAA_MAX_SEARCH_STEPS 32
#define HQ_SMAA_MAX_SEARCH_STEPS_DIAG 16
#define HQ_SMAA_CORNER_ROUNDING 25
#endif

//-----------------------------------------------------------------------------
// Configurable Defines

/**
 * HQ_SMAA_THRESHOLD specifies the threshold or sensitivity to edges.
 * Lowering this value you will be able to detect more edges at the expense of
 * performance. 
 *
 * Range: [0, 0.5]
 *   0.1 is a reasonable value, and allows to catch most visible edges.
 *   0.05 is a rather overkill value, that allows to catch 'em all.
 *
 *   If temporal supersampling is used, 0.2 could be a reasonable value, as low
 *   contrast edges are properly filtered by just 2x.
 */
#ifndef HQ_SMAA_THRESHOLD
#define HQ_SMAA_THRESHOLD 0.1
#endif

/**
 * HQ_SMAA_DEPTH_THRESHOLD specifies the threshold for depth edge detection.
 * 
 * Range: depends on the depth range of the scene.
 */
#ifndef HQ_SMAA_DEPTH_THRESHOLD
#define HQ_SMAA_DEPTH_THRESHOLD (0.1 * HQ_SMAA_THRESHOLD)
#endif

/**
 * HQ_SMAA_MAX_SEARCH_STEPS specifies the maximum steps performed in the
 * horizontal/vertical pattern searches, at each side of the pixel.
 *
 * In number of pixels, it's actually the double. So the maximum line length
 * perfectly handled by, for example 16, is 64 (by perfectly, we meant that
 * longer lines won't look as good, but still antialiased).
 *
 * Range: [0, 112]
 */
#ifndef HQ_SMAA_MAX_SEARCH_STEPS
#define HQ_SMAA_MAX_SEARCH_STEPS 16
#endif

/**
 * HQ_SMAA_MAX_SEARCH_STEPS_DIAG specifies the maximum steps performed in the
 * diagonal pattern searches, at each side of the pixel. In this case we jump
 * one pixel at time, instead of two.
 *
 * Range: [0, 20]
 *
 * On high-end machines it is cheap (between a 0.8x and 0.9x slower for 16 
 * steps), but it can have a significant impact on older machines.
 *
 * Define HQ_SMAA_DISABLE_DIAG_DETECTION to disable diagonal processing.
 */
#ifndef HQ_SMAA_MAX_SEARCH_STEPS_DIAG
#define HQ_SMAA_MAX_SEARCH_STEPS_DIAG 8
#endif

/**
 * HQ_SMAA_CORNER_ROUNDING specifies how much sharp corners will be rounded.
 *
 * Range: [0, 100]
 *
 * Define HQ_SMAA_DISABLE_CORNER_DETECTION to disable corner processing.
 */
#ifndef HQ_SMAA_CORNER_ROUNDING
#define HQ_SMAA_CORNER_ROUNDING 25
#endif

/**
 * If there is an neighbor edge that has HQ_SMAA_LOCAL_CONTRAST_FACTOR times
 * bigger contrast than current edge, current edge will be discarded.
 *
 * This allows to eliminate spurious crossing edges, and is based on the fact
 * that, if there is too much contrast in a direction, that will hide
 * perceptually contrast in the other neighbors.
 */
#ifndef HQ_SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR
#define HQ_SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR 2.0
#endif

/**
 * Predicated thresholding allows to better preserve texture details and to
 * improve performance, by decreasing the number of detected edges using an
 * additional buffer like the light accumulation buffer, object ids or even the
 * depth buffer (the depth buffer usage may be limited to indoor or short range
 * scenes).
 *
 * It locally decreases the luma or color threshold if an edge is found in an
 * additional buffer (so the global threshold can be higher).
 *
 * This method was developed by Playstation EDGE MLAA team, and used in 
 * Killzone 3, by using the light accumulation buffer. More information here:
 *     http://iryoku.com/aacourse/downloads/06-MLAA-on-PS3.pptx 
 */
#ifndef HQ_SMAA_PREDICATION
#define HQ_SMAA_PREDICATION 0
#endif

/**
 * Threshold to be used in the additional predication buffer. 
 *
 * Range: depends on the input, so you'll have to find the magic number that
 * works for you.
 */
#ifndef HQ_SMAA_PREDICATION_THRESHOLD
#define HQ_SMAA_PREDICATION_THRESHOLD 0.01
#endif

/**
 * How much to scale the global threshold used for luma or color edge
 * detection when using predication.
 *
 * Range: [1, 16]
 */
#ifndef HQ_SMAA_PREDICATION_SCALE
#define HQ_SMAA_PREDICATION_SCALE 2.0
#endif

/**
 * How much to locally decrease the threshold.
 *
 * Range: [0, 4]
 */
#ifndef HQ_SMAA_PREDICATION_STRENGTH
#define HQ_SMAA_PREDICATION_STRENGTH 0.4
#endif

/**
 * Temporal reprojection allows to remove ghosting artifacts when using
 * temporal supersampling. We use the CryEngine 3 method which also introduces
 * velocity weighting. This feature is of extreme importance for totally
 * removing ghosting. More information here:
 *    http://iryoku.com/aacourse/downloads/13-Anti-Aliasing-Methods-in-CryENGINE-3.pdf
 *
 * Note that you'll need to setup a velocity buffer for enabling reprojection.
 * For static geometry, saving the previous depth buffer is a viable
 * alternative.
 */
#ifndef HQ_SMAA_REPROJECTION
#define HQ_SMAA_REPROJECTION 0
#endif

/**
 * HQ_SMAA_REPROJECTION_WEIGHT_SCALE controls the velocity weighting. It allows to
 * remove ghosting trails behind the moving object, which are not removed by
 * just using reprojection. Using low values will exhibit ghosting, while using
 * high values will disable temporal supersampling under motion.
 *
 * Behind the scenes, velocity weighting removes temporal supersampling when
 * the velocity of the subsamples differs (meaning they are different objects).
 *
 * Range: [0, 80]
 */
#ifndef HQ_SMAA_REPROJECTION_WEIGHT_SCALE
#define HQ_SMAA_REPROJECTION_WEIGHT_SCALE 30.0
#endif

/**
 * On some compilers, discard cannot be used in vertex shaders. Thus, they need
 * to be compiled separately.
 */
#ifndef HQ_SMAA_INCLUDE_VS
#define HQ_SMAA_INCLUDE_VS 1
#endif
#ifndef HQ_SMAA_INCLUDE_PS
#define HQ_SMAA_INCLUDE_PS 1
#endif

//-----------------------------------------------------------------------------
// Texture Access Defines

#ifndef HQ_SMAA_AREATEX_SELECT
#if defined(HQ_SMAA_HLSL_3)
#define HQ_SMAA_AREATEX_SELECT(sample) sample.ra
#else
#define HQ_SMAA_AREATEX_SELECT(sample) sample.rg
#endif
#endif

#ifndef HQ_SMAA_SEARCHTEX_SELECT
#define HQ_SMAA_SEARCHTEX_SELECT(sample) sample.r
#endif

#ifndef HQ_SMAA_DECODE_VELOCITY
#define HQ_SMAA_DECODE_VELOCITY(sample) sample.rg
#endif

//-----------------------------------------------------------------------------
// Non-Configurable Defines

#define HQ_SMAA_AREATEX_MAX_DISTANCE 16
#define HQ_SMAA_AREATEX_MAX_DISTANCE_DIAG 20
#define HQ_SMAA_AREATEX_PIXEL_SIZE (1.0 / float2(160.0, 560.0))
#define HQ_SMAA_AREATEX_SUBTEX_SIZE (1.0 / 7.0)
#define HQ_SMAA_SEARCHTEX_SIZE float2(66.0, 33.0)
#define HQ_SMAA_SEARCHTEX_PACKED_SIZE float2(64.0, 16.0)
#define HQ_SMAA_CORNER_ROUNDING_NORM (float(HQ_SMAA_CORNER_ROUNDING) / 100.0)

//-----------------------------------------------------------------------------
// Porting Functions

#if defined(HQ_SMAA_HLSL_3)
#define HQ_SMAATexture2D(tex) sampler2D tex
#define HQ_SMAATexturePass2D(tex) tex
#define HQ_SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, 0.0, 0.0))
#define HQ_SMAASampleLevelZeroPoint(tex, coord) tex2Dlod(tex, float4(coord, 0.0, 0.0))
#define HQ_SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlod(tex, float4(coord + offset * HQ_SMAA_RT_METRICS.xy, 0.0, 0.0))
#define HQ_SMAASample(tex, coord) tex2D(tex, coord)
#define HQ_SMAASamplePoint(tex, coord) tex2D(tex, coord)
#define HQ_SMAASampleOffset(tex, coord, offset) tex2D(tex, coord + offset * HQ_SMAA_RT_METRICS.xy)
#define HQ_SMAA_FLATTEN [flatten]
#define HQ_SMAA_BRANCH [branch]
#endif
#if defined(HQ_SMAA_HLSL_4) || defined(HQ_SMAA_HLSL_4_1)
SamplerState LinearSampler { Filter = MIN_MAG_LINEAR_MIP_POINT; AddressU = Clamp; AddressV = Clamp; };
SamplerState PointSampler { Filter = MIN_MAG_MIP_POINT; AddressU = Clamp; AddressV = Clamp; };
#define HQ_SMAATexture2D(tex) Texture2D tex
#define HQ_SMAATexturePass2D(tex) tex
#define HQ_SMAASampleLevelZero(tex, coord) tex.SampleLevel(LinearSampler, coord, 0)
#define HQ_SMAASampleLevelZeroPoint(tex, coord) tex.SampleLevel(PointSampler, coord, 0)
#define HQ_SMAASampleLevelZeroOffset(tex, coord, offset) tex.SampleLevel(LinearSampler, coord, 0, offset)
#define HQ_SMAASample(tex, coord) tex.Sample(LinearSampler, coord)
#define HQ_SMAASamplePoint(tex, coord) tex.Sample(PointSampler, coord)
#define HQ_SMAASampleOffset(tex, coord, offset) tex.Sample(LinearSampler, coord, offset)
#define HQ_SMAA_FLATTEN [flatten]
#define HQ_SMAA_BRANCH [branch]
#define HQ_SMAATexture2DMS2(tex) Texture2DMS<float4, 2> tex
#define SMAALoad(tex, pos, sample) tex.Load(pos, sample)
#if defined(HQ_SMAA_HLSL_4_1)
#define HQ_SMAAGather(tex, coord) tex.Gather(LinearSampler, coord, 0)
#endif
#endif
#if defined(HQ_SMAA_GLSL_3) || defined(HQ_SMAA_GLSL_4)
#define HQ_SMAATexture2D(tex) sampler2D tex
#define HQ_SMAATexturePass2D(tex) tex
#define HQ_SMAASampleLevelZero(tex, coord) textureLod(tex, coord, 0.0)
#define HQ_SMAASampleLevelZeroPoint(tex, coord) textureLod(tex, coord, 0.0)
#define HQ_SMAASampleLevelZeroOffset(tex, coord, offset) textureLodOffset(tex, coord, 0.0, offset)
#define HQ_SMAASample(tex, coord) texture(tex, coord)
#define HQ_SMAASamplePoint(tex, coord) texture(tex, coord)
#define HQ_SMAASampleOffset(tex, coord, offset) texture(tex, coord, offset)
#define HQ_SMAA_FLATTEN
#define HQ_SMAA_BRANCH
#ifndef lerp
#define lerp(a, b, t) mix(a, b, t)
#endif
#ifndef saturate
#define saturate(a) clamp(a, 0.0, 1.0)
#endif
#if defined(HQ_SMAA_GLSL_4)
#ifndef mad
#define mad(a, b, c) fma(a, b, c)
#endif
#define HQ_SMAAGather(tex, coord) textureGather(tex, coord)
#else
#ifndef mad
#define mad(a, b, c) (a * b + c)
#endif
#endif
#ifndef float2
#define float2 vec2
#endif
#ifndef float3
#define float3 vec3
#endif
#ifndef float4
#define float4 vec4
#endif
#ifndef int2
#define int2 ivec2
#endif
#ifndef int3
#define int3 ivec3
#endif
#ifndef int4
#define int4 ivec4
#endif
#ifndef bool2
#define bool2 bvec2
#endif
#ifndef bool3
#define bool3 bvec3
#endif
#ifndef bool4
#define bool4 bvec4
#endif
#endif

#if !defined(HQ_SMAA_HLSL_3) && !defined(HQ_SMAA_HLSL_4) && !defined(HQ_SMAA_HLSL_4_1) && !defined(HQ_SMAA_GLSL_3) && !defined(HQ_SMAA_GLSL_4) && !defined(HQ_SMAA_CUSTOM_SL)
#error you must define the shading language: HQ_SMAA_HLSL_*, HQ_SMAA_GLSL_* or HQ_SMAA_CUSTOM_SL
#endif

//-----------------------------------------------------------------------------
// Misc functions

/**
 * Gathers current pixel, and the top-left neighbors.
 */
float3 HQ_SMAAGatherNeighbours(float2 texcoord,
                            float4 offset[3],
                            HQ_SMAATexture2D(tex)) {
    #ifdef HQ_SMAAGather
    return HQ_SMAAGather(tex, texcoord + HQ_SMAA_RT_METRICS.xy * float2(-0.5, -0.5)).grb;
    #else
    const float P = HQ_SMAASamplePoint(tex, texcoord).r;
    const float Pleft = HQ_SMAASamplePoint(tex, offset[0].xy).r;
    const float Ptop  = HQ_SMAASamplePoint(tex, offset[0].zw).r;
    return float3(P, Pleft, Ptop);
    #endif
}

/**
 * Adjusts the threshold by means of predication.
 */
float2 SMAACalculatePredicatedThreshold(float2 texcoord,
                                        float4 offset[3],
                                        HQ_SMAATexture2D(predicationTex)) {
    const float3 neighbours = HQ_SMAAGatherNeighbours(texcoord, offset, HQ_SMAATexturePass2D(predicationTex));
    const float2 delta = abs(neighbours.xx - neighbours.yz);
    const float2 edges = step(HQ_SMAA_PREDICATION_THRESHOLD, delta);
    return HQ_SMAA_PREDICATION_SCALE * HQ_SMAA_THRESHOLD * (1.0 - HQ_SMAA_PREDICATION_STRENGTH * edges);
}

/**
 * Conditional move:
 */
void SMAAMovc(bool2 cond, inout float2 variable, float2 value) {
    HQ_SMAA_FLATTEN if (cond.x) variable.x = value.x;
    HQ_SMAA_FLATTEN if (cond.y) variable.y = value.y;
}

void SMAAMovc(bool4 cond, inout float4 variable, float4 value) {
    SMAAMovc(cond.xy, variable.xy, value.xy);
    SMAAMovc(cond.zw, variable.zw, value.zw);
}


#if HQ_SMAA_INCLUDE_VS
//-----------------------------------------------------------------------------
// Vertex Shaders

/**
 * Edge Detection Vertex Shader
 */
void SMAAEdgeDetectionVS(float2 texcoord,
                         out float4 offset[3]) {
    offset[0] = mad(HQ_SMAA_RT_METRICS.xyxy, float4(-1.0, 0.0, 0.0, -1.0), texcoord.xyxy);
    offset[1] = mad(HQ_SMAA_RT_METRICS.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
    offset[2] = mad(HQ_SMAA_RT_METRICS.xyxy, float4(-2.0, 0.0, 0.0, -2.0), texcoord.xyxy);
}

/**
 * Blend Weight Calculation Vertex Shader
 */
void SMAABlendingWeightCalculationVS(float2 texcoord,
                                     out float2 pixcoord,
                                     out float4 offset[3]) {
    pixcoord = texcoord * HQ_SMAA_RT_METRICS.zw;

    // We will use these offsets for the searches later on (see @PSEUDO_GATHER4):
    offset[0] = mad(HQ_SMAA_RT_METRICS.xyxy, float4(-0.25, -0.125,  1.25, -0.125), texcoord.xyxy);
    offset[1] = mad(HQ_SMAA_RT_METRICS.xyxy, float4(-0.125, -0.25, -0.125,  1.25), texcoord.xyxy);

    // And these for the searches, they indicate the ends of the loops:
    offset[2] = mad(HQ_SMAA_RT_METRICS.xxyy,
                    float4(-2.0, 2.0, -2.0, 2.0) * float(HQ_SMAA_MAX_SEARCH_STEPS),
                    float4(offset[0].xz, offset[1].yw));
}

/**
 * Neighborhood Blending Vertex Shader
 */
void SMAANeighborhoodBlendingVS(float2 texcoord,
                                out float4 offset) {
    offset = mad(HQ_SMAA_RT_METRICS.xyxy, float4( 1.0, 0.0, 0.0,  1.0), texcoord.xyxy);
}
#endif // HQ_SMAA_INCLUDE_VS

#if HQ_SMAA_INCLUDE_PS
//-----------------------------------------------------------------------------
// Edge Detection Pixel Shaders (First Pass)

/**
 * Luma Edge Detection
 *
 * IMPORTANT NOTICE: luma edge detection requires gamma-corrected colors, and
 * thus 'colorTex' should be a non-sRGB texture.
 */
float2 SMAALumaEdgeDetectionPS(float2 texcoord,
                               float4 offset[3],
                               HQ_SMAATexture2D(colorTex)
                               ) {
    // Calculate the threshold:
	const float2 threshold = float2(HQ_SMAA_THRESHOLD, HQ_SMAA_THRESHOLD);

    // Calculate lumas:
    const float3 weights = float3(0.2126, 0.7152, 0.0722);
    const float L = dot(HQ_SMAASamplePoint(colorTex, texcoord).rgb, weights);

    const float Lleft = dot(HQ_SMAASamplePoint(colorTex, offset[0].xy).rgb, weights);
    const float Ltop  = dot(HQ_SMAASamplePoint(colorTex, offset[0].zw).rgb, weights);

    // We do the usual threshold:
    float4 delta;
    delta.xy = abs(L - float2(Lleft, Ltop));
    float2 edges = step(threshold, delta.xy);

    // Then discard if there is no edge:
    if (dot(edges, float2(1.0, 1.0)) == 0.0)
        discard;

    // Calculate right and bottom deltas:
    const float Lright = dot(HQ_SMAASamplePoint(colorTex, offset[1].xy).rgb, weights);
    const float Lbottom  = dot(HQ_SMAASamplePoint(colorTex, offset[1].zw).rgb, weights);
    delta.zw = abs(L - float2(Lright, Lbottom));

    // Calculate the maximum delta in the direct neighborhood:
    float2 maxDelta = max(delta.xy, delta.zw);

    // Calculate left-left and top-top deltas:
    const float Lleftleft = dot(HQ_SMAASamplePoint(colorTex, offset[2].xy).rgb, weights);
    const float Ltoptop = dot(HQ_SMAASamplePoint(colorTex, offset[2].zw).rgb, weights);
    delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));

    // Calculate the final maximum delta:
    maxDelta = max(maxDelta.xy, delta.zw);
    const float finalDelta = max(maxDelta.x, maxDelta.y);

    // Local contrast adaptation:
    edges.xy *= step(finalDelta, HQ_SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR * delta.xy);

    return edges;
}

float2 SMAALumaEdgePredicationDetectionPS(float2 texcoord,
                               float4 offset[3],
                               HQ_SMAATexture2D(colorTex)
                               , HQ_SMAATexture2D(predicationTex)
                               ) {
    // Calculate the threshold:
	const float2 threshold = SMAACalculatePredicatedThreshold(texcoord, offset, HQ_SMAATexturePass2D(predicationTex));

    // Calculate lumas:
    const float3 weights = float3(0.2126, 0.7152, 0.0722);
    const float L = dot(HQ_SMAASamplePoint(colorTex, texcoord).rgb, weights);

    const float Lleft = dot(HQ_SMAASamplePoint(colorTex, offset[0].xy).rgb, weights);
    const float Ltop  = dot(HQ_SMAASamplePoint(colorTex, offset[0].zw).rgb, weights);

    // We do the usual threshold:
    float4 delta;
    delta.xy = abs(L - float2(Lleft, Ltop));
    float2 edges = step(threshold, delta.xy);

    // Then discard if there is no edge:
    if (dot(edges, float2(1.0, 1.0)) == 0.0)
        discard;

    // Calculate right and bottom deltas:
    const float Lright = dot(HQ_SMAASamplePoint(colorTex, offset[1].xy).rgb, weights);
    const float Lbottom  = dot(HQ_SMAASamplePoint(colorTex, offset[1].zw).rgb, weights);
    delta.zw = abs(L - float2(Lright, Lbottom));

    // Calculate the maximum delta in the direct neighborhood:
    float2 maxDelta = max(delta.xy, delta.zw);

    // Calculate left-left and top-top deltas:
    const float Lleftleft = dot(HQ_SMAASamplePoint(colorTex, offset[2].xy).rgb, weights);
    const float Ltoptop = dot(HQ_SMAASamplePoint(colorTex, offset[2].zw).rgb, weights);
    delta.zw = abs(float2(Lleft, Ltop) - float2(Lleftleft, Ltoptop));

    // Calculate the final maximum delta:
    maxDelta = max(maxDelta.xy, delta.zw);
    const float finalDelta = max(maxDelta.x, maxDelta.y);

    // Local contrast adaptation:
    edges.xy *= step(finalDelta, HQ_SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR * delta.xy);

    return edges;
}

/**
 * Color Edge Detection
 *
 * IMPORTANT NOTICE: color edge detection requires gamma-corrected colors, and
 * thus 'colorTex' should be a non-sRGB texture.
 */
float2 SMAAColorEdgeDetectionPS(float2 texcoord,
                                float4 offset[3],
                                HQ_SMAATexture2D(colorTex)
                                ) {
    // Calculate the threshold:
    const float2 threshold = float2(HQ_SMAA_THRESHOLD, HQ_SMAA_THRESHOLD);

    // Calculate color deltas:
    float4 delta;
    const float3 C = HQ_SMAASamplePoint(colorTex, texcoord).rgb;

    const float3 Cleft = HQ_SMAASamplePoint(colorTex, offset[0].xy).rgb;
    float3 t = abs(C - Cleft);
    delta.x = max(max(t.r, t.g), t.b);

    const float3 Ctop  = HQ_SMAASamplePoint(colorTex, offset[0].zw).rgb;
    t = abs(C - Ctop);
    delta.y = max(max(t.r, t.g), t.b);

    // We do the usual threshold:
    float2 edges = step(threshold, delta.xy);

    // Then discard if there is no edge:
    if (dot(edges, float2(1.0, 1.0)) == 0.0)
        discard;

    // Calculate right and bottom deltas:
    const float3 Cright = HQ_SMAASamplePoint(colorTex, offset[1].xy).rgb;
    t = abs(C - Cright);
    delta.z = max(max(t.r, t.g), t.b);

    const float3 Cbottom  = HQ_SMAASamplePoint(colorTex, offset[1].zw).rgb;
    t = abs(C - Cbottom);
    delta.w = max(max(t.r, t.g), t.b);

    // Calculate the maximum delta in the direct neighborhood:
    float2 maxDelta = max(delta.xy, delta.zw);

    // Calculate left-left and top-top deltas:
    const float3 Cleftleft  = HQ_SMAASamplePoint(colorTex, offset[2].xy).rgb;
    t = abs(Cleft - Cleftleft);
    delta.z = max(max(t.r, t.g), t.b);

    const float3 Ctoptop = HQ_SMAASamplePoint(colorTex, offset[2].zw).rgb;
    t = abs(Ctop - Ctoptop);
    delta.w = max(max(t.r, t.g), t.b);

    // Calculate the final maximum delta:
    maxDelta = max(maxDelta.xy, delta.zw);
    const float finalDelta = max(maxDelta.x, maxDelta.y);

    // Local contrast adaptation:
    edges.xy *= step(finalDelta, HQ_SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR * delta.xy);

    return edges;
}

float2 SMAAColorEdgePredicationDetectionPS(float2 texcoord,
                                float4 offset[3],
                                HQ_SMAATexture2D(colorTex)
                                , HQ_SMAATexture2D(predicationTex)
                                ) {
    // Calculate the threshold:
    const float2 threshold = SMAACalculatePredicatedThreshold(texcoord, offset, predicationTex);

    // Calculate color deltas:
    float4 delta;
    const float3 C = HQ_SMAASamplePoint(colorTex, texcoord).rgb;

    const float3 Cleft = HQ_SMAASamplePoint(colorTex, offset[0].xy).rgb;
    float3 t = abs(C - Cleft);
    delta.x = max(max(t.r, t.g), t.b);

    const float3 Ctop  = HQ_SMAASamplePoint(colorTex, offset[0].zw).rgb;
    t = abs(C - Ctop);
    delta.y = max(max(t.r, t.g), t.b);

    // We do the usual threshold:
    float2 edges = step(threshold, delta.xy);

    // Then discard if there is no edge:
    if (dot(edges, float2(1.0, 1.0)) == 0.0)
        discard;

    // Calculate right and bottom deltas:
    const float3 Cright = HQ_SMAASamplePoint(colorTex, offset[1].xy).rgb;
    t = abs(C - Cright);
    delta.z = max(max(t.r, t.g), t.b);

    const float3 Cbottom  = HQ_SMAASamplePoint(colorTex, offset[1].zw).rgb;
    t = abs(C - Cbottom);
    delta.w = max(max(t.r, t.g), t.b);

    // Calculate the maximum delta in the direct neighborhood:
    float2 maxDelta = max(delta.xy, delta.zw);

    // Calculate left-left and top-top deltas:
    const float3 Cleftleft  = HQ_SMAASamplePoint(colorTex, offset[2].xy).rgb;
    t = abs(Cleft - Cleftleft);
    delta.z = max(max(t.r, t.g), t.b);

    const float3 Ctoptop = HQ_SMAASamplePoint(colorTex, offset[2].zw).rgb;
    t = abs(Ctop - Ctoptop);
    delta.w = max(max(t.r, t.g), t.b);

    // Calculate the final maximum delta:
    maxDelta = max(maxDelta.xy, delta.zw);
    const float finalDelta = max(maxDelta.x, maxDelta.y);

    // Local contrast adaptation:
    edges.xy *= step(finalDelta, HQ_SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR * delta.xy);

    return edges;
}

/**
 * Depth Edge Detection
 */
float2 SMAADepthEdgeDetectionPS(float2 texcoord,
                                float4 offset[3],
                                HQ_SMAATexture2D(depthTex)) {
    const float3 neighbours = HQ_SMAAGatherNeighbours(texcoord, offset, HQ_SMAATexturePass2D(depthTex));
    const float2 delta = abs(neighbours.xx - float2(neighbours.y, neighbours.z));
    const float2 edges = step(HQ_SMAA_DEPTH_THRESHOLD, delta);

    if (dot(edges, float2(1.0, 1.0)) == 0.0)
        discard;

    return edges;
}

//-----------------------------------------------------------------------------
// Diagonal Search Functions

#if !defined(HQ_SMAA_DISABLE_DIAG_DETECTION)

/**
 * Allows to decode two binary values from a bilinear-filtered access.
 */
float2 SMAADecodeDiagBilinearAccess(float2 e) {
    // Bilinear access for fetching 'e' have a 0.25 offset, and we are
    // interested in the R and G edges:
    //
    // +---G---+-------+
    // |   x o R   x   |
    // +-------+-------+
    //
    // Then, if one of these edge is enabled:
    //   Red:   (0.75 * X + 0.25 * 1) => 0.25 or 1.0
    //   Green: (0.75 * 1 + 0.25 * X) => 0.75 or 1.0
    //
    // This function will unpack the values (mad + mul + round):
    // wolframalpha.com: round(x * abs(5 * x - 5 * 0.75)) plot 0 to 1
    e.r = e.r * abs(5.0 * e.r - 5.0 * 0.75);
    return round(e);
}

float4 SMAADecodeDiagBilinearAccess(float4 e) {
    e.rb = e.rb * abs(5.0 * e.rb - 5.0 * 0.75);
    return round(e);
}

/**
 * These functions allows to perform diagonal pattern searches.
 */
float2 SMAASearchDiag1(HQ_SMAATexture2D(edgesTex), float2 texcoord, float2 dir, out float2 e) {
    float4 coord = float4(texcoord, -1.0, 1.0);
    const float3 t = float3(HQ_SMAA_RT_METRICS.xy, 1.0);
    while (coord.z < float(HQ_SMAA_MAX_SEARCH_STEPS_DIAG - 1) &&
           coord.w > 0.9) {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);
        e = HQ_SMAASampleLevelZero(edgesTex, coord.xy).rg;
        coord.w = dot(e, float2(0.5, 0.5));
    }
    return coord.zw;
}

float2 SMAASearchDiag2(HQ_SMAATexture2D(edgesTex), float2 texcoord, float2 dir, out float2 e) {
    float4 coord = float4(texcoord, -1.0, 1.0);
    coord.x += 0.25 * HQ_SMAA_RT_METRICS.x; // See @SearchDiag2Optimization
    const float3 t = float3(HQ_SMAA_RT_METRICS.xy, 1.0);
    while (coord.z < float(HQ_SMAA_MAX_SEARCH_STEPS_DIAG - 1) &&
           coord.w > 0.9) {
        coord.xyz = mad(t, float3(dir, 1.0), coord.xyz);

        // @SearchDiag2Optimization
        // Fetch both edges at once using bilinear filtering:
        e = HQ_SMAASampleLevelZero(edgesTex, coord.xy).rg;
        e = SMAADecodeDiagBilinearAccess(e);

        // Non-optimized version:
        // e.g = HQ_SMAASampleLevelZero(edgesTex, coord.xy).g;
        // e.r = HQ_SMAASampleLevelZeroOffset(edgesTex, coord.xy, int2(1, 0)).r;

        coord.w = dot(e, float2(0.5, 0.5));
    }
    return coord.zw;
}

/** 
 * Similar to SMAAArea, this calculates the area corresponding to a certain
 * diagonal distance and crossing edges 'e'.
 */
float2 SMAAAreaDiag(HQ_SMAATexture2D(areaTex), float2 dist, float2 e, float offset) {
    float2 texcoord = mad(float2(HQ_SMAA_AREATEX_MAX_DISTANCE_DIAG, HQ_SMAA_AREATEX_MAX_DISTANCE_DIAG), e, dist);

    // We do a scale and bias for mapping to texel space:
    texcoord = mad(HQ_SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * HQ_SMAA_AREATEX_PIXEL_SIZE);

    // Diagonal areas are on the second half of the texture:
    texcoord.x += 0.5;

    // Move to proper place, according to the subpixel offset:
    texcoord.y += HQ_SMAA_AREATEX_SUBTEX_SIZE * offset;

    // Do it!
    return HQ_SMAA_AREATEX_SELECT(HQ_SMAASampleLevelZero(areaTex, texcoord));
}

/**
 * This searches for diagonal patterns and returns the corresponding weights.
 */
float2 SMAACalculateDiagWeights(HQ_SMAATexture2D(edgesTex), HQ_SMAATexture2D(areaTex), float2 texcoord, float2 e, float4 subsampleIndices) {
    float2 weights = float2(0.0, 0.0);

    // Search for the line ends:
    float4 d;
    float2 end;
    if (e.r > 0.0) {
        d.xz = SMAASearchDiag1(HQ_SMAATexturePass2D(edgesTex), texcoord, float2(-1.0,  1.0), end);
        d.x += float(end.y > 0.9);
    } else
        d.xz = float2(0.0, 0.0);
    d.yw = SMAASearchDiag1(HQ_SMAATexturePass2D(edgesTex), texcoord, float2(1.0, -1.0), end);

    HQ_SMAA_BRANCH
    if (d.x + d.y > 2.0) { // d.x + d.y + 1 > 3
        // Fetch the crossing edges:
        const float4 coords = mad(float4(-d.x + 0.25, d.x, d.y, -d.y - 0.25), HQ_SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        float4 c;
        c.xy = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.xy, int2(-1,  0)).rg;
        c.zw = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.zw, int2( 1,  0)).rg;
        c.yxwz = SMAADecodeDiagBilinearAccess(c.xyzw);

        // Non-optimized version:
        // float4 coords = mad(float4(-d.x, d.x, d.y, -d.y), HQ_SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        // float4 c;
        // c.x = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.xy, int2(-1,  0)).g;
        // c.y = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.xy, int2( 0,  0)).r;
        // c.z = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.zw, int2( 1,  0)).g;
        // c.w = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.zw, int2( 1, -1)).r;

        // Merge crossing edges at each side into a single value:
        float2 cc = mad(float2(2.0, 2.0), c.xz, c.yw);

        // Remove the crossing edge if we didn't found the end of the line:
        SMAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));

        // Fetch the areas for this line:
        weights += SMAAAreaDiag(HQ_SMAATexturePass2D(areaTex), d.xy, cc, subsampleIndices.z);
    }

    // Search for the line ends:
    d.xz = SMAASearchDiag2(HQ_SMAATexturePass2D(edgesTex), texcoord, float2(-1.0, -1.0), end);
    if (HQ_SMAASampleLevelZeroOffset(edgesTex, texcoord, int2(1, 0)).r > 0.0) {
        d.yw = SMAASearchDiag2(HQ_SMAATexturePass2D(edgesTex), texcoord, float2(1.0, 1.0), end);
        d.y += float(end.y > 0.9);
    } else
        d.yw = float2(0.0, 0.0);

    HQ_SMAA_BRANCH
    if (d.x + d.y > 2.0) { // d.x + d.y + 1 > 3
        // Fetch the crossing edges:
        const float4 coords = mad(float4(-d.x, -d.x, d.y, d.y), HQ_SMAA_RT_METRICS.xyxy, texcoord.xyxy);
        float4 c;
        c.x  = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.xy, int2(-1,  0)).g;
        c.y  = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.xy, int2( 0, -1)).r;
        c.zw = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.zw, int2( 1,  0)).gr;
        float2 cc = mad(float2(2.0, 2.0), c.xz, c.yw);

        // Remove the crossing edge if we didn't found the end of the line:
        SMAAMovc(bool2(step(0.9, d.zw)), cc, float2(0.0, 0.0));

        // Fetch the areas for this line:
        weights += SMAAAreaDiag(HQ_SMAATexturePass2D(areaTex), d.xy, cc, subsampleIndices.w).gr;
    }

    return weights;
}
#endif

//-----------------------------------------------------------------------------
// Horizontal/Vertical Search Functions

/**
 * This allows to determine how much length should we add in the last step
 * of the searches. It takes the bilinearly interpolated edge (see 
 * @PSEUDO_GATHER4), and adds 0, 1 or 2, depending on which edges and
 * crossing edges are active.
 */
float SMAASearchLength(HQ_SMAATexture2D(searchTex), float2 e, float offset) {
    // The texture is flipped vertically, with left and right cases taking half
    // of the space horizontally:
    float2 scale = HQ_SMAA_SEARCHTEX_SIZE * float2(0.5, -1.0);
    float2 bias = HQ_SMAA_SEARCHTEX_SIZE * float2(offset, 1.0);

    // Scale and bias to access texel centers:
    scale += float2(-1.0,  1.0);
    bias  += float2( 0.5, -0.5);

    // Convert from pixel coordinates to texcoords:
    // (We use HQ_SMAA_SEARCHTEX_PACKED_SIZE because the texture is cropped)
    scale *= 1.0 / HQ_SMAA_SEARCHTEX_PACKED_SIZE;
    bias *= 1.0 / HQ_SMAA_SEARCHTEX_PACKED_SIZE;

    // Lookup the search texture:
    return HQ_SMAA_SEARCHTEX_SELECT(HQ_SMAASampleLevelZero(searchTex, mad(scale, e, bias)));
}

/**
 * Horizontal/vertical search functions for the 2nd pass.
 */
float SMAASearchXLeft(HQ_SMAATexture2D(edgesTex), HQ_SMAATexture2D(searchTex), float2 texcoord, float end) {
    /**
     * @PSEUDO_GATHER4
     * This texcoord has been offset by (-0.25, -0.125) in the vertex shader to
     * sample between edge, thus fetching four edges in a row.
     * Sampling with different offsets in each direction allows to disambiguate
     * which edges are active from the four fetched ones.
     */
    float2 e = float2(0.0, 1.0);
    while (texcoord.x > end && 
           e.g > 0.8281 && // Is there some edge not activated?
           e.r == 0.0) { // Or is there a crossing edge that breaks the line?
        e = HQ_SMAASampleLevelZero(edgesTex, texcoord).rg;
        texcoord = mad(-float2(2.0, 0.0), HQ_SMAA_RT_METRICS.xy, texcoord);
    }

    const float offset = mad(-(255.0 / 127.0), SMAASearchLength(HQ_SMAATexturePass2D(searchTex), e, 0.0), 3.25);
    return mad(HQ_SMAA_RT_METRICS.x, offset, texcoord.x);

    // Non-optimized version:
    // We correct the previous (-0.25, -0.125) offset we applied:
    // texcoord.x += 0.25 * HQ_SMAA_RT_METRICS.x;

    // The searches are bias by 1, so adjust the coords accordingly:
    // texcoord.x += HQ_SMAA_RT_METRICS.x;

    // Disambiguate the length added by the last step:
    // texcoord.x += 2.0 * HQ_SMAA_RT_METRICS.x; // Undo last step
    // texcoord.x -= HQ_SMAA_RT_METRICS.x * (255.0 / 127.0) * SMAASearchLength(HQ_SMAATexturePass2D(searchTex), e, 0.0);
    // return mad(HQ_SMAA_RT_METRICS.x, offset, texcoord.x);
}

float SMAASearchXRight(HQ_SMAATexture2D(edgesTex), HQ_SMAATexture2D(searchTex), float2 texcoord, float end) {
    float2 e = float2(0.0, 1.0);
    while (texcoord.x < end && 
           e.g > 0.8281 && // Is there some edge not activated?
           e.r == 0.0) { // Or is there a crossing edge that breaks the line?
        e = HQ_SMAASampleLevelZero(edgesTex, texcoord).rg;
        texcoord = mad(float2(2.0, 0.0), HQ_SMAA_RT_METRICS.xy, texcoord);
    }
    const float offset = mad(-(255.0 / 127.0), SMAASearchLength(HQ_SMAATexturePass2D(searchTex), e, 0.5), 3.25);
    return mad(-HQ_SMAA_RT_METRICS.x, offset, texcoord.x);
}

float SMAASearchYUp(HQ_SMAATexture2D(edgesTex), HQ_SMAATexture2D(searchTex), float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    while (texcoord.y > end && 
           e.r > 0.8281 && // Is there some edge not activated?
           e.g == 0.0) { // Or is there a crossing edge that breaks the line?
        e = HQ_SMAASampleLevelZero(edgesTex, texcoord).rg;
        texcoord = mad(-float2(0.0, 2.0), HQ_SMAA_RT_METRICS.xy, texcoord);
    }
    const float offset = mad(-(255.0 / 127.0), SMAASearchLength(HQ_SMAATexturePass2D(searchTex), e.gr, 0.0), 3.25);
    return mad(HQ_SMAA_RT_METRICS.y, offset, texcoord.y);
}

float SMAASearchYDown(HQ_SMAATexture2D(edgesTex), HQ_SMAATexture2D(searchTex), float2 texcoord, float end) {
    float2 e = float2(1.0, 0.0);
    while (texcoord.y < end && 
           e.r > 0.8281 && // Is there some edge not activated?
           e.g == 0.0) { // Or is there a crossing edge that breaks the line?
        e = HQ_SMAASampleLevelZero(edgesTex, texcoord).rg;
        texcoord = mad(float2(0.0, 2.0), HQ_SMAA_RT_METRICS.xy, texcoord);
    }
    const float offset = mad(-(255.0 / 127.0), SMAASearchLength(HQ_SMAATexturePass2D(searchTex), e.gr, 0.5), 3.25);
    return mad(-HQ_SMAA_RT_METRICS.y, offset, texcoord.y);
}

/** 
 * Ok, we have the distance and both crossing edges. So, what are the areas
 * at each side of current edge?
 */
float2 SMAAArea(HQ_SMAATexture2D(areaTex), float2 dist, float e1, float e2, float offset) {
    // Rounding prevents precision errors of bilinear filtering:
    float2 texcoord = mad(float2(HQ_SMAA_AREATEX_MAX_DISTANCE, HQ_SMAA_AREATEX_MAX_DISTANCE), round(4.0 * float2(e1, e2)), dist);
    
    // We do a scale and bias for mapping to texel space:
    texcoord = mad(HQ_SMAA_AREATEX_PIXEL_SIZE, texcoord, 0.5 * HQ_SMAA_AREATEX_PIXEL_SIZE);

    // Move to proper place, according to the subpixel offset:
    texcoord.y = mad(HQ_SMAA_AREATEX_SUBTEX_SIZE, offset, texcoord.y);

    // Do it!
    return HQ_SMAA_AREATEX_SELECT(HQ_SMAASampleLevelZero(areaTex, texcoord));
}

//-----------------------------------------------------------------------------
// Corner Detection Functions

void SMAADetectHorizontalCornerPattern(HQ_SMAATexture2D(edgesTex), inout float2 weights, float4 texcoord, float2 d) {
    #if !defined(HQ_SMAA_DISABLE_CORNER_DETECTION)
    const float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - HQ_SMAA_CORNER_ROUNDING_NORM) * leftRight;

    rounding /= leftRight.x + leftRight.y; // Reduce blending for pixels in the center of a line.

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * HQ_SMAASampleLevelZeroOffset(edgesTex, texcoord.xy, int2(0,  1)).r;
    factor.x -= rounding.y * HQ_SMAASampleLevelZeroOffset(edgesTex, texcoord.zw, int2(1,  1)).r;
    factor.y -= rounding.x * HQ_SMAASampleLevelZeroOffset(edgesTex, texcoord.xy, int2(0, -2)).r;
    factor.y -= rounding.y * HQ_SMAASampleLevelZeroOffset(edgesTex, texcoord.zw, int2(1, -2)).r;

    weights *= saturate(factor);
    #endif
}

void SMAADetectVerticalCornerPattern(HQ_SMAATexture2D(edgesTex), inout float2 weights, float4 texcoord, float2 d) {
    #if !defined(HQ_SMAA_DISABLE_CORNER_DETECTION)
    const float2 leftRight = step(d.xy, d.yx);
    float2 rounding = (1.0 - HQ_SMAA_CORNER_ROUNDING_NORM) * leftRight;

    rounding /= leftRight.x + leftRight.y;

    float2 factor = float2(1.0, 1.0);
    factor.x -= rounding.x * HQ_SMAASampleLevelZeroOffset(edgesTex, texcoord.xy, int2( 1, 0)).g;
    factor.x -= rounding.y * HQ_SMAASampleLevelZeroOffset(edgesTex, texcoord.zw, int2( 1, 1)).g;
    factor.y -= rounding.x * HQ_SMAASampleLevelZeroOffset(edgesTex, texcoord.xy, int2(-2, 0)).g;
    factor.y -= rounding.y * HQ_SMAASampleLevelZeroOffset(edgesTex, texcoord.zw, int2(-2, 1)).g;

    weights *= saturate(factor);
    #endif
}

//-----------------------------------------------------------------------------
// Blending Weight Calculation Pixel Shader (Second Pass)

float4 SMAABlendingWeightCalculationPS(float2 texcoord,
                                       float2 pixcoord,
                                       float4 offset[3],
                                       HQ_SMAATexture2D(edgesTex),
                                       HQ_SMAATexture2D(areaTex),
                                       HQ_SMAATexture2D(searchTex),
                                       float4 subsampleIndices) { // Just pass zero for SMAA 1x, see @SUBSAMPLE_INDICES.
    float4 weights = float4(0.0, 0.0, 0.0, 0.0);

    float2 e = HQ_SMAASample(edgesTex, texcoord).rg;

    HQ_SMAA_BRANCH
    if (e.g > 0.0) { // Edge at north
        #if !defined(HQ_SMAA_DISABLE_DIAG_DETECTION)
        // Diagonals have both north and west edges, so searching for them in
        // one of the boundaries is enough.
        weights.rg = SMAACalculateDiagWeights(HQ_SMAATexturePass2D(edgesTex), HQ_SMAATexturePass2D(areaTex), texcoord, e, subsampleIndices);

        // We give priority to diagonals, so if we find a diagonal we skip 
        // horizontal/vertical processing.
        HQ_SMAA_BRANCH
        if (weights.r == -weights.g) { // weights.r + weights.g == 0.0
        #endif

        float2 d;

        // Find the distance to the left:
        float3 coords;
        coords.x = SMAASearchXLeft(HQ_SMAATexturePass2D(edgesTex), HQ_SMAATexturePass2D(searchTex), offset[0].xy, offset[2].x);
        coords.y = offset[1].y; // offset[1].y = texcoord.y - 0.25 * HQ_SMAA_RT_METRICS.y (@CROSSING_OFFSET)
        d.x = coords.x;

        // Now fetch the left crossing edges, two at a time using bilinear
        // filtering. Sampling at -0.25 (see @CROSSING_OFFSET) enables to
        // discern what value each edge has:
        const float e1 = HQ_SMAASampleLevelZero(edgesTex, coords.xy).r;

        // Find the distance to the right:
        coords.z = SMAASearchXRight(HQ_SMAATexturePass2D(edgesTex), HQ_SMAATexturePass2D(searchTex), offset[0].zw, offset[2].y);
        d.y = coords.z;

        // We want the distances to be in pixel units (doing this here allow to
        // better interleave arithmetic and memory accesses):
        d = abs(round(mad(HQ_SMAA_RT_METRICS.zz, d, -pixcoord.xx)));

        // SMAAArea below needs a sqrt, as the areas texture is compressed
        // quadratically:
        const float2 sqrt_d = sqrt(d);

        // Fetch the right crossing edges:
        const float e2 = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.zy, int2(1, 0)).r;

        // Ok, we know how this pattern looks like, now it is time for getting
        // the actual area:
        weights.rg = SMAAArea(HQ_SMAATexturePass2D(areaTex), sqrt_d, e1, e2, subsampleIndices.y);

        // Fix corners:
        coords.y = texcoord.y;
        SMAADetectHorizontalCornerPattern(HQ_SMAATexturePass2D(edgesTex), weights.rg, coords.xyzy, d);

        #if !defined(HQ_SMAA_DISABLE_DIAG_DETECTION)
        } else
            e.r = 0.0; // Skip vertical processing.
        #endif
    }

    HQ_SMAA_BRANCH
    if (e.r > 0.0) { // Edge at west
        float2 d;

        // Find the distance to the top:
        float3 coords;
        coords.y = SMAASearchYUp(HQ_SMAATexturePass2D(edgesTex), HQ_SMAATexturePass2D(searchTex), offset[1].xy, offset[2].z);
        coords.x = offset[0].x; // offset[1].x = texcoord.x - 0.25 * HQ_SMAA_RT_METRICS.x;
        d.x = coords.y;

        // Fetch the top crossing edges:
        const float e1 = HQ_SMAASampleLevelZero(edgesTex, coords.xy).g;

        // Find the distance to the bottom:
        coords.z = SMAASearchYDown(HQ_SMAATexturePass2D(edgesTex), HQ_SMAATexturePass2D(searchTex), offset[1].zw, offset[2].w);
        d.y = coords.z;

        // We want the distances to be in pixel units:
        d = abs(round(mad(HQ_SMAA_RT_METRICS.ww, d, -pixcoord.yy)));

        // SMAAArea below needs a sqrt, as the areas texture is compressed 
        // quadratically:
        const float2 sqrt_d = sqrt(d);

        // Fetch the bottom crossing edges:
        const float e2 = HQ_SMAASampleLevelZeroOffset(edgesTex, coords.xz, int2(0, 1)).g;

        // Get the area for this direction:
        weights.ba = SMAAArea(HQ_SMAATexturePass2D(areaTex), sqrt_d, e1, e2, subsampleIndices.x);

        // Fix corners:
        coords.x = texcoord.x;
        SMAADetectVerticalCornerPattern(HQ_SMAATexturePass2D(edgesTex), weights.ba, coords.xyxz, d);
    }

    return weights;
}

//-----------------------------------------------------------------------------
// Neighborhood Blending Pixel Shader (Third Pass)

float4 SMAANeighborhoodBlendingPS(float2 texcoord,
                                  float4 offset,
                                  HQ_SMAATexture2D(colorTex),
                                  HQ_SMAATexture2D(blendTex)
                                  #if HQ_SMAA_REPROJECTION
                                  , HQ_SMAATexture2D(velocityTex)
                                  #endif
                                  ) {
    // Fetch the blending weights for current pixel:
    float4 a;
    a.x = HQ_SMAASample(blendTex, offset.xy).a; // Right
    a.y = HQ_SMAASample(blendTex, offset.zw).g; // Top
    a.wz = HQ_SMAASample(blendTex, texcoord).xz; // Bottom / Left

    // Is there any blending weight with a value greater than 0.0?
    HQ_SMAA_BRANCH
    if (dot(a, float4(1.0, 1.0, 1.0, 1.0)) < 1e-5) {
        float4 color = HQ_SMAASampleLevelZero(colorTex, texcoord);

        #if HQ_SMAA_REPROJECTION
        const float2 velocity = HQ_SMAA_DECODE_VELOCITY(HQ_SMAASampleLevelZero(velocityTex, texcoord));

        // Pack velocity into the alpha channel:
        color.a = sqrt(5.0 * length(velocity));
        #endif

        return color;
    } else {
        bool h = max(a.x, a.z) > max(a.y, a.w); // max(horizontal) > max(vertical)

        // Calculate the blending offsets:
        float4 blendingOffset = float4(0.0, a.y, 0.0, a.w);
        float2 blendingWeight = a.yw;
        SMAAMovc(bool4(h, h, h, h), blendingOffset, float4(a.x, 0.0, a.z, 0.0));
        SMAAMovc(bool2(h, h), blendingWeight, a.xz);
        blendingWeight /= dot(blendingWeight, float2(1.0, 1.0));

        // Calculate the texture coordinates:
        const float4 blendingCoord = mad(blendingOffset, float4(HQ_SMAA_RT_METRICS.xy, -HQ_SMAA_RT_METRICS.xy), texcoord.xyxy);

        // We exploit bilinear filtering to mix current pixel with the chosen
        // neighbor:
        float4 color = blendingWeight.x * HQ_SMAASampleLevelZero(colorTex, blendingCoord.xy);
        color += blendingWeight.y * HQ_SMAASampleLevelZero(colorTex, blendingCoord.zw);

        #if HQ_SMAA_REPROJECTION
        // Antialias velocity for proper reprojection in a later stage:
        float2 velocity = blendingWeight.x * HQ_SMAA_DECODE_VELOCITY(HQ_SMAASampleLevelZero(velocityTex, blendingCoord.xy));
        velocity += blendingWeight.y * HQ_SMAA_DECODE_VELOCITY(HQ_SMAASampleLevelZero(velocityTex, blendingCoord.zw));

        // Pack velocity into the alpha channel:
        color.a = sqrt(5.0 * length(velocity));
        #endif

        return color;
    }
}

//-----------------------------------------------------------------------------
// Temporal Resolve Pixel Shader (Optional Pass)

float4 SMAAResolvePS(float2 texcoord,
                     HQ_SMAATexture2D(currentColorTex),
                     HQ_SMAATexture2D(previousColorTex)
                     #if HQ_SMAA_REPROJECTION
                     , HQ_SMAATexture2D(velocityTex)
                     #endif
                     ) {
    #if HQ_SMAA_REPROJECTION
    // Velocity is assumed to be calculated for motion blur, so we need to
    // inverse it for reprojection:
    const float2 velocity = -HQ_SMAA_DECODE_VELOCITY(HQ_SMAASamplePoint(velocityTex, texcoord).rg);

    // Fetch current pixel:
    const float4 current = HQ_SMAASamplePoint(currentColorTex, texcoord);

    // Reproject current coordinates and fetch previous pixel:
    const float4 previous = HQ_SMAASamplePoint(previousColorTex, texcoord + velocity);

    // Attenuate the previous pixel if the velocity is different:
    const float delta = abs(current.a * current.a - previous.a * previous.a) / 5.0;
    const float weight = 0.5 * saturate(1.0 - sqrt(delta) * HQ_SMAA_REPROJECTION_WEIGHT_SCALE);

    // Blend the pixels according to the calculated weight:
    return lerp(current, previous, weight);
    #else
    // Just blend the pixels:
    const float4 current = HQ_SMAASamplePoint(currentColorTex, texcoord);
    const float4 previous = HQ_SMAASamplePoint(previousColorTex, texcoord);
    return lerp(current, previous, 0.5);
    #endif
}

//-----------------------------------------------------------------------------
// Separate Multisamples Pixel Shader (Optional Pass)

#ifdef SMAALoad
void SMAASeparatePS(float4 position,
                    float2 texcoord,
                    out float4 target0,
                    out float4 target1,
                    HQ_SMAATexture2DMS2(colorTexMS)) {
    const int2 pos = int2(position.xy);
    target0 = SMAALoad(colorTexMS, pos, 0);
    target1 = SMAALoad(colorTexMS, pos, 1);
}
#endif

//-----------------------------------------------------------------------------
#endif // HQ_SMAA_INCLUDE_PS
