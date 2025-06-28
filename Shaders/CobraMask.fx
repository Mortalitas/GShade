////////////////////////////////////////////////////////////////////////////////////////////////////////
// Cobra Mask (CobraMask.fx) by SirCobra
// Version 0.4.0
// You can find info and all my shaders here: https://github.com/LordKobra/CobraFX
//
// --------Description---------
// CobraMask.fx allows to apply ReShade shaders exclusively to a selected part of the screen.
// The mask can be defined through color and scene-depth parameters. The parameters are
// specifically designed to work in accordance with the color and depth selection of other
// CobraFX shaders. This shader works the following way: In the effect window, you put
// "Cobra Mask: Start" above, and "Cobra Mask: Finish" below the shaders you want to be
// affected by the mask. When you turn it on, the effects in between will only affect the
// part of the screen with the correct color and depth.
//
// ----------Credits-----------
// 1) The effect can be applied to a specific area like a DoF shader. The basic methods for this were
// taken with permission from: https://github.com/FransBouma/OtisFX/blob/master/Shaders/Emphasize.fx
// 2) HSV conversions by Sam Hocevar: http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
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

namespace COBRA_MSK
{

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                            Defines & UI
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Defines
    #define COBRA_MSK_VERSION "0.4.0"

    #define COBRA_UTL_MODE 0
    #include ".\CobraUtility.fxh"

    #if (COBRA_UTL_VERSION_NUMBER < 1030)
        #error "CobraUtility.fxh outdated! Please update CobraFX!"
    #endif

    // UI

    uniform float UI_Opacity <
        ui_label     = " Effect Opacity";
        ui_type      = "slider";
        ui_spacing   = 2;
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_tooltip   = "The general opacity.";
        ui_step      = 0.001;
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.000;

    #define COBRA_UTL_MODE 1
    #include ".\CobraUtility.fxh"

    uniform int UI_BufferEnd <
        ui_type     = "radio";
        ui_spacing  = 2;
        ui_text     = " Shader Version: " COBRA_MSK_VERSION;
        ui_label    = " ";
    > ;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                         Textures & Samplers
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Texture

    texture TEX_Mask
    {
        Width  = BUFFER_WIDTH;
        Height = BUFFER_HEIGHT;
#if (BUFFER_COLOR_BIT_DEPTH == 8)
        Format = RGBA8;
#else 
        Format = RGBA16F; // We need a strong alpha channel for gradient blending
#endif
    };

    // Sampler

    sampler2D SAM_Mask
    {
        Texture   = TEX_Mask;
        MagFilter = POINT;
        MinFilter = POINT;
        MipFilter = POINT;
    };

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                           Helper Functions
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    #define COBRA_UTL_MODE 2
    #define COBRA_UTL_COLOR 1
    #include ".\CobraUtility.fxh"

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                              Shaders
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    void PS_MaskStart(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
    {
        float4 srgb    = tex2Dfetch(ReShade::BackBuffer, floor(vpos.xy));
        float3 lrgb    = enc_to_lin(srgb.rgb);
        float depth    = ReShade::GetLinearizedDepth(texcoord);
        float in_focus = check_focus(lrgb, depth, texcoord);
        fragment       = float4(srgb.rgb, in_focus);
    }

    void PS_MaskEnd(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
    {
        fragment     = tex2Dfetch(SAM_Mask, floor(vpos.xy));
        fragment.rgb = enc_to_lin(fragment.rgb);
        float4 srgb  = tex2Dfetch(ReShade::BackBuffer, floor(vpos.xy));
        float3 lrgb  = enc_to_lin(srgb.rgb);
        fragment.rgb    = UI_ShowMask
                      ? 1.0 - fragment.aaa
                      : lerp(lrgb, fragment.rgb, (1.0 - fragment.a * UI_Opacity)); // @BlendOp
        fragment.rgb    = (UI_ShowSelectedHue * UI_FilterColor) ? show_hue(texcoord, fragment.rgb) : fragment.rgb;
        fragment.rgb    = lin_to_enc(fragment.rgb);
        fragment.a      = srgb.a; // preserve alpha
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                             Techniques
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    technique TECH_CobraMaskStart <
        ui_label     = "Cobra Mask: Start";
        ui_tooltip   = "Place this -above- the shaders you want to mask.\n"
                       "The masked area is copied and stored here, meaning all effects\n"
                       "applied between Start and Finish only affect the unmasked area.\n\n"
                       "------About-------\n"
                       "CobraMask.fx allows to apply ReShade shaders exclusively to a selected part of the screen.\n"
                       "The mask can be defined through color and scene-depth parameters. The parameters are\n"
                       "specifically designed to work in accordance with the color and depth selection of other\n"
                       "CobraFX shaders.\n\n"
                       "Version:    " COBRA_MSK_VERSION "\nAuthor:     SirCobra\nCollection: CobraFX\n"
                       "            https://github.com/LordKobra/CobraFX";
    >
    {
        pass MaskStart
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_MaskStart;
            RenderTarget = TEX_Mask;
        }
    }

    technique TECH_CobraMaskFinish <
        ui_label     = "Cobra Mask: Finish";
        ui_tooltip   = "Place this -below- the shaders you want to mask.\n"
                       "The masked area is applied again onto the screen.\n\n"
                       "------About-------\n"
                       "CobraMask.fx allows to apply ReShade shaders exclusively to a selected part of the screen.\n"
                       "The mask can be defined through color and scene-depth parameters. The parameters are\n"
                       "specifically designed to work in accordance with the color and depth selection of other\n"
                       "CobraFX shaders.\n\n"
                       "Version:    " COBRA_MSK_VERSION "\nAuthor:     SirCobra\nCollection: CobraFX\n"
                       "            https://github.com/LordKobra/CobraFX";
    >
    {
        pass MaskEnd
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_MaskEnd;
        }
    }
}