////////////////////////////////////////////////////////////////////////////////////////////////////////
// Frequency (Frquency_CS.fx) by SirCobra
// Version 0.2.0
// You can find info and all my shaders here: https://github.com/LordKobra/CobraFX
//
// --------Description---------
// Frequency_CS.fx creates an effect also known as `Frequency Modulation`, which
// scans the image from left to right and releases a wave whenever a luminance-
// based threshold is reached. The pixel luminance is summed up and modulated
// depending on a given period. Additional parameters give the effect a unique
// look. A masking stage enables filtering affected colors and depth.
//
// ----------Credits-----------
// Thanks to...
// ... TeoTave for introducing me to this effect!
// ... https://dominik.ws/art/movingdots/ for showcasing a concrete example on how the effect can look!
// ... Marty McFly, Lord of Lunacy and CeeJayDK for technical discussions!
//
// ----------License-----------
// The MIT License (MIT)
//
// Copyright (c) 2025 SirCobra ( https://github.com/LordKobra )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////////////

#include "Reshade.fxh"

uniform float timer <
    source = "timer";
> ;

// Shader Start

//  Namespace everything!

namespace COBRA_XFRQ
{

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                            Defines & UI
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Defines

    #define COBRA_XFRQ_VERSION "0.2.0"

    #define COBRA_UTL_MODE 0
    #include ".\CobraUtility.fxh"

    #if (COBRA_UTL_VERSION_NUMBER < 1030)
        #error "CobraUtility.fxh outdated! Please update CobraFX!"
    #endif

    #define COBRA_XFRQ_THREADS 16
    #define COBRA_XFRQ_THREAD_WIDTH 16
    #define COBRA_XFRQ_DISPATCHES ROUNDUP(BUFFER_HEIGHT, COBRA_XFRQ_THREADS)

    // We need Compute Shader Support
    #if (((__RENDERER__ >= 0xb000 && __RENDERER__ < 0x10000) || (__RENDERER__ >= 0x14300)) && __RESHADE__ >= 40800)
        #define COBRA_XFRQ_COMPUTE 1
    #else
        #define COBRA_XFRQ_COMPUTE 0
        #warning "Frequency_CS.fx does only work with ReShade 4.8 or newer, DirectX 11 or newer, OpenGL 4.3 or newer and Vulkan."
    #endif

    #if COBRA_XFRQ_COMPUTE != 0

    // UI

    uniform uint UI_Frequency <
        ui_label     = " Period";
        ui_type      = "slider";
        ui_spacing   = 2;
        ui_min       = 1;
        ui_max       = 200;
        ui_step      = 1;
        ui_tooltip   = "Determines the frequency of the wave appearance. Low values let the wave appear in\n"
                       "short intervals.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 20;

    uniform float UI_Thickness <
        ui_label     = " Thickness";
        ui_type      = "slider";
        ui_min       = 1;
        ui_max       = 100;
        ui_step      = 1;
        ui_units     = "px";
        ui_tooltip   = "The thickness of the wave in pixel.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 4;

    uniform float UI_Gamma <
        ui_label     = " Gamma";
        ui_type      = "slider";
        ui_min       = 0.4;
        ui_max       = 4.4;
        ui_step      = 0.01;
        ui_tooltip   = "The gamma correction value. The default value is 1.0. The higher this value, the more\n"
                       "persistent highlights will be.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.0;

    uniform float UI_BaseIncrease <
        ui_label     = " Base Increase";
        ui_type      = "slider";
        ui_min       = 0.00;
        ui_max       = 10.00;
        ui_step      = 0.01;
        ui_tooltip   = "This value is added to every pixel to create a base frequency independent of the image.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0.15;

    uniform bool UI_BaseMultiply <
        ui_label     = " Multiply Base with Background";
        ui_tooltip   = "The base value is multiplied with the scene value to depend on the image content.\n"
                       "It now serves as a multiplier of the image value.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform float UI_Decay <
        ui_label     = " Decay";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "Decay of the wave frequency after each wave. Highly instable, but can produce\n"
                       "interesting results. Not recommended above 0 with animated waves.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0.000;

    uniform float UI_Offset <
        ui_label     = " Offset";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 100.0;
        ui_step      = 0.1;
        ui_units     = "%%";
        ui_tooltip   = "Initial offset of the first wave.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0.1;

    uniform int UI_BlendMode <
        ui_label     = " Blend Mode";
        ui_type      = "combo";
        ui_items     = "Tint\0Color\0Value\0";
        ui_tooltip   = "The blend mode applied to the wave.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 2;

    uniform float3 UI_EffectTint <
        ui_label     = " Tint";
        ui_type      = "color";
        ui_tooltip   = "Specifies the tint of the wave, when blend mode is set to tint.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = float3(1.00, 0.50, 0.50);

    uniform float UI_Transparency <
        ui_label     = " Black Transparency";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 100.0;
        ui_step      = 0.1;
        ui_units     = "%%";
        ui_tooltip   = "Transparency of the area not affected by the waves.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0.0;

    uniform uint UI_RotationType <
        ui_label     = " Direction";
        ui_type      = "combo";
        ui_items     = "Left\0Bottom\0Right\0Top\0";
        ui_tooltip   = "The direction from which the effect starts.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0;

    uniform int UI_Blur <
        ui_label     = " Blur";
        ui_type      = "combo";
        ui_items     = "None\0Two\0Four\0Six\0Eight\0";
        ui_tooltip   = "The blur applied to the input. Higher values smoothen the wave.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 2;

    uniform bool UI_Animate <
        ui_label     = " Animate";
        ui_tooltip   = "Make the wave move with time.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = true;

    uniform bool UI_Invert <
        ui_label     = " Invert";
        ui_tooltip   = "Invert the wave.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform bool UI_UseDepth <
        ui_label     = " Use Depth";
        ui_tooltip   = "The waves will respond to scene depth instead of the scene luminance.\n"
                       "Requires a working depth buffer.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform float UI_DepthMultiplier <
        ui_label     = " Depth Multiplier";
        ui_type      = "slider";
        ui_min       = 0.01;
        ui_max       = 10.00;
        ui_tooltip   = "Multiplier of the depth value when depth is used.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.0;

    uniform bool UI_HotsamplingMode <
        ui_label     = " Hotsampling Mode";
        ui_tooltip   = "Activate this, then adjust your options and the effect will stay similar at\n"
                       "all resolutions. Turn this off when you do not intend to hotsample.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    #define COBRA_UTL_MODE 1
    #include ".\CobraUtility.fxh"

    uniform int UI_BufferEnd <
        ui_type     = "radio";
        ui_spacing  = 2;
        ui_text     = " Shader Version: " COBRA_XFRQ_VERSION;
        ui_label    = " ";
    > ;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                             Textures & Samplers & Storage & Shared Memory
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Texture

    texture TEX_Frequency
    {
        Width  = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = R8; // quasi-bool
    };

    texture TEX_Mask
    {
        Width  = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
        Format = R16F; // linear luminance
    };

    // Sampler

    sampler2D SAM_Frequency { Texture = TEX_Frequency; };
    sampler2D SAM_Mask { Texture = TEX_Mask; };

    // Storage

    storage STOR_Frequency { Texture = TEX_Frequency; };
    storage STOR_Mask { Texture = TEX_Mask; };

    // Groupshared Memory
    groupshared float summary[COBRA_XFRQ_THREADS * COBRA_XFRQ_THREAD_WIDTH];
    groupshared uint overlap[COBRA_XFRQ_THREADS * COBRA_XFRQ_THREAD_WIDTH];
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                           Helper Functions
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    #define COBRA_UTL_MODE 2
    #define COBRA_UTL_COLOR 1
    #include "CobraUtility.fxh"

    // rotate the screen
    float2 rotate(float2 texcoord1, bool revert)
    {
        float2 texcoord = texcoord1.xy;
        uint ANGLE      = UI_RotationType * 90 + (360 - 2 * UI_RotationType * 90) * revert;
        float2 rotated  = texcoord;

        // easy cases to avoid dividing by zero; values 0 & 360 are trivial
        rotated = (ANGLE == 90) ? float2(texcoord.y, 1 - texcoord.x) : rotated;
        rotated = (ANGLE == 180) ? float2(1 - texcoord.x, 1 - texcoord.y) : rotated;
        rotated = (ANGLE == 270) ? float2(1 - texcoord.y, texcoord.x) : rotated;
        return rotated.xy;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                              Shaders
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    void PS_Mask(float4 vpos : SV_Position, out float fragment : SV_TARGET)
    {
        float val    = 0.0;
        uint counter = 0;
        [unroll] for (int i = -8; i <= 8; i++)
        {
            if (((vpos.y + i) > 0) && ((vpos.y + i) < BUFFER_HEIGHT) && (abs(i) <= (2 * UI_Blur)))
            {
                float2 texcoord = (vpos.xy + int2(0, i)) / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
                texcoord        = rotate(texcoord, false);
                float3 srgb     = tex2D(ReShade::BackBuffer, texcoord).rgb; //@BlendOp ? bicubic interpolation?
                float3 rgb      = enc_to_lin(srgb);
                float depth     = ReShade::GetLinearizedDepth(texcoord);
                float f         = check_focus(rgb, depth, texcoord);
                if (f)
                {
                    val += UI_UseDepth ? f * UI_DepthMultiplier * pow(abs(depth), UI_Gamma) 
                                       : f * csp_to_luminance(pow(abs(rgb), UI_Gamma));
                    counter++;
                }
            }
        }

        float HS_MULT       = UI_HotsamplingMode ? 1920.0 / BUFFER_WIDTH : 1.0;
        fragment            = val / max(counter, 0.5);
        float intermediate  = UI_BaseMultiply ? fragment : 1.0;
        fragment            = fragment + UI_BaseIncrease * intermediate;
        fragment           *= HS_MULT;
    }

    void CS_Frequency(uint3 id : SV_DispatchThreadID, uint3 tid : SV_GroupThreadID)
    {
        uint start       = id.x * ROUNDUP(BUFFER_WIDTH, COBRA_XFRQ_THREAD_WIDTH);
        uint end         = min(start + ROUNDUP(BUFFER_WIDTH, COBRA_XFRQ_THREAD_WIDTH) - 1, BUFFER_WIDTH - 1);
        uint global_zero = tid.y * COBRA_XFRQ_THREAD_WIDTH;
        float accum_s    = UI_Offset / 100.0 * UI_Frequency - fmod(UI_Animate * timer / 200.0, UI_Frequency);
        accum_s          = (id.x == 0) ? accum_s : 0.0;
        float accum      = accum_s;
        float section[ROUNDUP(BUFFER_WIDTH, COBRA_XFRQ_THREAD_WIDTH)];
        // parallel prefix sum version
        // 1) add local array, write sum to global thread array -> global write
        if (id.y < BUFFER_HEIGHT)
        {
            for (uint i = start; i <= end; i++)
            {
                section[i - start] = tex2Dfetch(SAM_Mask, int2(i, id.y)).r;
                accum += section[i - start];
            }
            summary[global_zero + id.x] = accum;
        }

        // 1.5) clear global array, due to two arrays we dont need another sync
        overlap[global_zero + id.x] = 0;

        barrier();
        // 2) sync arrays and add sum -> global read
        float accum_l = accum_s;
        if (id.y < BUFFER_HEIGHT)
        {
            for (uint i = 0; i < id.x; i++)
            {
                accum_l += summary[global_zero + i];
            }
        }

        // 3) calculate modulos: if decay==0 by modulo in local array, if decay > 0 by subtracting iterations from
        //     total value until in cell.
        //    Also shade areas and write overlap to thread array (forward or backward reading?
        //    probably forward with atomicAdd) -> forward add
        float decay         = 1.0;
        uint remaining      = 0;
        uint first_position = end;
        const uint R        = UI_HotsamplingMode ? UI_Thickness * float(BUFFER_WIDTH) / 1920.0 : UI_Thickness;
        const float U       = 1.0 + UI_Decay;
        if (id.y < BUFFER_HEIGHT)
        {
            /*  the math idea for future corrections
                accum - ((f) + (f * u) + (f * u * u) + ...) < 0
                accum < (f) + (f * u) + (f * u * u) + ...
                accum < f *((1) + (1 * u) + (1 * u * u) + ...);
                accum < s(n) with a = UI_Frequency, r = u;
                accum < a (1- u^n) / (1-u) // (1-u) negative cause u>1
                accum/a*(1-u) > (1-u^n) // * -1
                -accum/a*(1-u) < u^n - 1
                1 -accum/a*(1-u) < u^n
                log(1 -accum/a*(1-u)) < n * log(u) // logu > 0
                log(1 -accum/a*(1-u))/ log(u) < n
                n = ceil(log(1 -accum/a*(1-u))/ log(u))
                accum -= s(n)
                accum -= a * (1- u^n) / (1-u)

                ==1 case:
                accum < an
                accumfd < n
                n = ceil(accumfd)
                accum - UI_Frequency*n
            */
            //float accumfd = uint(accum_l) / UI_Frequency; // @TODO for some reason i need uint conversion
                                                            // and additional while pass
            /* if (!(U > 1.0)) // always produces rounding issues past initial thread.
            {
                uint n = ROUNDUP(uint(accum_l), UI_Frequency);
                accum_l -= UI_Frequency * n;
            } */
            /* else
            {  // currently doesn't work properly although math should be correct
                uint n = ceil(log(1-accumfd*(1-u)) * rcp(log(u)));
                decay = (1-pow(u,n))/(1-u);
                accum_l -= UI_Frequency * decay;
            } */

            while (accum_l > 0.0)
            {
                accum_l -= UI_Frequency * decay;
                decay *= U;
            }

            for (uint i = start; i <= end; i++)
            {
                accum_l += section[i - start];
                if (accum_l > 0.0)
                {
                    remaining      = R;
                    first_position = min(i, first_position);
                    accum_l -= UI_Frequency * decay;
                    decay *= U;
                }

                if (remaining > 0)
                {
                    remaining--;
                    tex2Dstore(STOR_Frequency, int2(i, id.y), 1.0);
                }
            }

            uint next = 1;
            while (remaining > 0 && ((id.x + next) < COBRA_XFRQ_THREAD_WIDTH))
            {
                atomicMax(overlap[global_zero + id.x + next++], remaining);
                remaining = max(int(remaining) - ROUNDUP(BUFFER_WIDTH, COBRA_XFRQ_THREAD_WIDTH), 0);
            }
        }

        barrier();

        // 4) shade overlap
        if (id.y < BUFFER_HEIGHT)
        {
            remaining = overlap[global_zero + id.x];
            for (uint i = start; i < first_position; i++)
            {
                if (remaining > 0)
                {
                    remaining--;
                    tex2Dstore(STOR_Frequency, int2(i, id.y), 1.0); // @TODO coords
                }
            }
        }
    }

    // reproject to output window
    void PS_PrintFrequency(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
    {
        float4 srgb         = tex2Dfetch(ReShade::BackBuffer, floor(vpos.xy));
        float3 rgb          = enc_to_lin(srgb.rgb);
        float3 intermediate = UI_BlendMode == 2 ? csp_to_luminance(rgb.rgb) : rgb;
        intermediate        = UI_BlendMode == 0 ? ui_to_csp(UI_EffectTint) : intermediate; //@BlendOp
        float2 texcoord_new = rotate(texcoord, true);
        float intensity     = tex2D(SAM_Frequency, texcoord_new).r;
        intensity           = intensity + (1.0 - 2.0 * intensity) * UI_Invert;
        fragment.rgb        = intensity * intermediate + (1.0 - intensity) * rgb * UI_Transparency / 100.0;
        fragment.rgb        = UI_ShowMask ? saturate(1.0 - tex2D(SAM_Mask, texcoord_new).rrr) : fragment.rgb; //@BlendOp
        fragment.rgb        = (UI_ShowSelectedHue * UI_FilterColor) ? show_hue(texcoord, fragment.rgb) : fragment.rgb;
        fragment.rgb        = lin_to_enc(fragment.rgb);
        fragment.a          = srgb.a; // preserve alpha
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                             Techniques
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    technique TECH_Frequency <
        ui_label     = "Frequency";
        ui_tooltip   = "------About-------\n"
                       "Frequency_CS.fx creates an effect also known as 'Frequency Modulation', which\n"
                       "scans the image from left to right and releases a wave whenever a luminance-\n"
                       "based threshold is reached. The pixel luminance is summed up and modulated\n"
                       "depending on a given period. Additional parameters give the effect a unique\n"
                       "look. A masking stage enables filtering affected colors and depth.\n\n"
                       "Version:    " COBRA_XFRQ_VERSION "\nAuthor:     SirCobra\nCollection: CobraFX\n"
                       "            https://github.com/LordKobra/CobraFX";
    >
    {
        pass Mask
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_Mask;
            RenderTarget = TEX_Mask;
        }

        pass PrepareFrequency
        {
            VertexShader       = VS_Clear;
            PixelShader        = PS_Clear;
            RenderTarget0      = TEX_Frequency;
            ClearRenderTargets = true;
            PrimitiveTopology  = POINTLIST;
            VertexCount        = 1;
        }

        pass Frequency
        {
            ComputeShader = CS_Frequency<COBRA_XFRQ_THREAD_WIDTH, COBRA_XFRQ_THREADS>;
            DispatchSizeX = 1;
            DispatchSizeY = COBRA_XFRQ_DISPATCHES;
        }

        pass PrintFrequency
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_PrintFrequency;
        }
    }

#endif // Shader End

} // Namespace End

/*-------------.
| ::  TODO  :: |
'--------------/

* RGB channels independent
* full rotation support
* hotsampling
* mask displacement (2 Techniques)
* 3rd Technique for Frequency AA
*/
