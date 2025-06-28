////////////////////////////////////////////////////////////////////////////////////////////////////////
// Greyscale (Greyscale.fx) by SirCobra
// Version 0.1.0
// You can find info and all my shaders here: https://github.com/LordKobra/CobraFX
//
// --------Description---------
// Greyscale.fx allows to transform the image into greyscale. You can chose
// from popular metrics whether to preserve lightness or perceived luminance.
//
// ----------Credits-----------
// Thanks to Lilium, Vortigern and Kaldaien for technical discussions!
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

// Shader Start

// Namespace Everything!

namespace COBRA_GSC
{

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                            Defines & UI
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Defines

    #define COBRA_GSC_VERSION "0.1.0"

    #define COBRA_UTL_MODE 0
    #include ".\CobraUtility.fxh"

    #if (COBRA_UTL_VERSION_NUMBER < 1030)
        #error "CobraUtility.fxh outdated! Please update CobraFX!"
    #endif

    // UI

    uniform int UI_EffectType <
        ui_label     = " Greyscale Metric";
        ui_type      = "radio";
        ui_spacing   = 2;
        ui_items     = "Linear Average\0Luma\0CIE XYZ Relative Luminance Y\0Oklab Perceived Lightness L\0";
        ui_tooltip   = "The type of greyscale conversion.\n\n"
                       "* 'Linear Average' represents the approximate energy of the decoded color signal.\n"
                       "  The simplest metric, it doesn't do a particularly good job at matching color perception.\n\n"
                       "* 'Luma' is an approximation of the luminance directly from the gamma-compressed signal.\n"
                       "  Fast to calculate, it is widely used in post-processing.\n\n"
                       "* 'CIE XYZ Relative Luminance Y' uses the ISO-standardized luminous efficiency function.\n"
                       "  Based on experiments from 1931, it does a good job at mimicking our eyes and often\n"
                       "  serves as reference to other color spaces.\n\n"
                       "* 'Oklab Perceived Lightness L' uses the Oklab color space, which itself is based on the\n"
                       "  CIELAB (1976) color space. CIELAB attempts to achieve better perceptual uniformity\n"
                       "  compared to CIE XYZ, with Oklab (2020) contributing further improvements.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 3;

    uniform float UI_EffectStrength <
        ui_label     = " Strength";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The strength of the conversion.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.000;

    uniform int UI_BufferEnd <
        ui_type     = "radio";
        ui_spacing  = 2;
        ui_text     = " Shader Version: " COBRA_GSC_VERSION;
        ui_label    = " ";
    > ;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                           Helper Functions
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    #define COBRA_UTL_MODE 2
    #include ".\CobraUtility.fxh"

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                              Shaders
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    vs2ps VS_Greyscale(uint id : SV_VertexID) 
    {
        return vs_basic(id, float2(0.0, 0.0));
    }

    void PS_Greyscale(vs2ps o, out float4 fragment : SV_Target)
    {   
        float4 enc   = tex2Dfetch(ReShade::BackBuffer, floor(o.vpos.xy));
        float3 lrgb  = enc_to_lin(enc.rgb);

        // Linear Average 0
        float3 lin_avg   = dot(lrgb, 1.0 / 3.0).xxx;
        lin_avg          = lerp(lrgb, lin_avg, UI_EffectStrength);

        // Luma 1
        float3 luma      = csp_to_luminance(enc.xyz).xxx;
        luma             = lerp(enc.rgb, luma, UI_EffectStrength);

        // CIE XYZ Relative Luminance Y 2
        float3 y                 = csp_to_xyz(lrgb);
        const float3 W_D65_XYZ   = float3(0.95047, 1.000, 1.08883);
        y                        = xyz_to_csp(lerp(y, W_D65_XYZ * y.y, UI_EffectStrength));

        // Oklab Perceived Lightness 3
        float3 oklab     = csp_to_oklab(lrgb);
        oklab.yz         = lerp(oklab.yz, 0.0, UI_EffectStrength);
        oklab            = oklab_to_csp(oklab);

        // Result
        enc.xyz    = UI_EffectType == 1 ? luma : lin_to_enc(lin_avg);
        enc.xyz    = UI_EffectType == 2 ? lin_to_enc(y) : enc.xyz;
        enc.xyz    = UI_EffectType == 3 ? lin_to_enc(oklab): enc.xyz;
        fragment = enc; // preserves alpha!
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                             Techniques
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    technique TECH_Greyscale <
        ui_label     = "Greyscale";
        ui_tooltip   = "------About-------\n"
                       "Greyscale.fx allows to transform the image into greyscale. You can chose\n"
                       "from popular metrics whether to preserve lightness or perceived luminance.\n\n"
                       "Version:    " COBRA_GSC_VERSION "\nAuthor:     SirCobra\nCollection: CobraFX\n"
                       "            https://github.com/LordKobra/CobraFX";
    >
    {
        pass Greyscale
        {
            VertexShader = VS_Greyscale;
            PixelShader  = PS_Greyscale;
        }
    }
}