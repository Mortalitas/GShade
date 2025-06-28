////////////////////////////////////////////////////////////////////////////////////////////////////////
// Droste Effect (Droste.fx) by SirCobra
// Version 0.4.3
// You can find info and all my shaders here: https://github.com/LordKobra/CobraFX
//
// --------Description---------
// The Droste effect warps the image-space to recursively appear within itself.
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

namespace COBRA_DRO
{

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                            Defines & UI
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Defines

    #define COBRA_DRO_VERSION "0.4.3"

    #define COBRA_UTL_MODE 0
    #include ".\CobraUtility.fxh"

    // UI

    uniform int UI_EffectType <
        ui_label     = " Effect Type";
        ui_type      = "radio";
        ui_spacing   = 2;
        ui_items     = "Circular\0Rectangular\0";
        ui_tooltip   = "Shape of the recursive appearance.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0;

    uniform bool UI_Spiral <
        ui_label     = " Spiral";
        ui_spacing   = 2;
        ui_tooltip   = "Warp space into a spiral.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = true;

    uniform float UI_OuterRing <
        ui_label     = " Outer Ring Size";
        ui_type      = "slider";
        ui_min       = 0.00;
        ui_max       = 1.00;
        ui_step      = 0.01;
        ui_tooltip   = "The outer ring defines the texture border towards the edge of the screen.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.00;

    uniform float UI_Zoom <
        ui_label     = " Zoom";
        ui_type      = "slider";
        ui_min       = 0.00;
        ui_max       = 9.90;
        ui_step      = 0.01;
        ui_tooltip   = "Zoom into the output.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.00;

    uniform float UI_Frequency <
        ui_label     = " Frequency";
        ui_type      = "slider";
        ui_min       = 0.10;
        ui_max       = 5.00;
        ui_step      = 0.01;
        ui_tooltip   = "Defines the frequency of the recursion.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.00;

    uniform float UI_X_Offset <
        ui_label     = " Center Horizontal Offset";
        ui_type      = "slider";
        ui_min       = -0.50;
        ui_max       = 0.50;
        ui_step      = 0.01;
        ui_tooltip   = "Change the horizontal position of the center. Keep it at 0 to get the best results.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0.00;

    uniform float UI_Y_Offset <
        ui_label     = " Center Vertical Offset";
        ui_type      = "slider";
        ui_min       = -0.50;
        ui_max       = 0.50;
        ui_step      = 0.01;
        ui_tooltip   = "Change the Y position of the center. Keep it at 0 to get the best results.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0.00;

    uniform int UI_BufferEnd <
        ui_type     = "radio";
        ui_spacing  = 2;
        ui_text     = " Shader Version: " COBRA_DRO_VERSION;
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

    vs2ps VS_Droste(uint id : SV_VertexID)
    {
        const float2 AR                 = UI_EffectType == 0 ? float2(float(BUFFER_WIDTH) / BUFFER_HEIGHT, 1.0) 
                                                             : float2(1.0, 1.0);
        const float2 OFFSET             = float2(UI_X_Offset, UI_Y_Offset);
        const float NEW_CENTER_ANGLE    = abs(OFFSET.x) + abs(OFFSET.y) < 0.01 
                                          ? 1.0 
                                          : (atan2_approx(-OFFSET.x * AR.x, -OFFSET.y) + M_PI) / (2.0 * M_PI);
        const float INNER_RING          = 1.0 / exp(1.0 / (UI_Frequency));
        return vs_basic(id, float2(NEW_CENTER_ANGLE, INNER_RING));
    }

    void PS_Droste(vs2ps o, out float4 fragment : SV_Target)
    {
        // transform coordinate system
        const float2 AR     = UI_EffectType == 0 ? float2(float(BUFFER_WIDTH) / BUFFER_HEIGHT, 1.0) : 1.0;
        const float2 OFFSET = float2(UI_X_Offset, UI_Y_Offset);
        float2 new_pos      = (o.uv.xy - 0.5 + OFFSET) * AR;

        // calculate orientation of center and pixel
        const float NEW_CENTER_DISTANCE =  (1.0 - 2.0 * max(abs(OFFSET.x), abs(OFFSET.y)));
        const float NEW_CENTER_ANGLE    = o.uv.z;

        // calculate and normalize angle
        float angle                     = (atan2_approx(new_pos.x, new_pos.y) + M_PI) / (2.0 * M_PI);
        float val                       = angle * UI_Spiral;
        angle                           = 1.0 - fmod(abs(abs(angle - NEW_CENTER_ANGLE) - 0.5), 0.5) * 2.0;

        //smooth off-center projection
        float angle_smooth = (1.0 - cos(angle * angle * M_PI)) / 2.0;
        float intensity    = lerp(NEW_CENTER_DISTANCE, 1.0, angle_smooth);

        // calculate distance from center
        float cicle_dist = sqrt(dot(new_pos, new_pos)) / intensity;
        float rect_dist  = max(abs(new_pos.x), abs(new_pos.y));
        float rcdist     = UI_EffectType == 0 ? cicle_dist : rect_dist;
        rcdist           = log(rcdist * (10.0 - UI_Zoom)) * UI_Frequency;
        val             += rcdist;
        val              = (exp(fmod(val, 1.0) / UI_Frequency) - 1.0) / (rcp(o.uv.w) - 1.0);

        // normalized vector
        float vector_length     = sqrt(dot(new_pos, new_pos));
        float unit_circle_ratio = UI_EffectType == 0 ? 0.5 / vector_length : 0.5 / max(abs(new_pos.x), abs(new_pos.y));
        float2 normalized       = new_pos * unit_circle_ratio;

        // calculate relative position towards outer and inner ring and interpolate
        const float INNER_RING = o.uv.w * UI_OuterRing;
        float real_scale       = lerp(INNER_RING, UI_OuterRing, val);
        real_scale            *= intensity;
        float2 adjusted        = normalized * real_scale / AR + 0.5 - OFFSET;
        fragment               = tex2D(ReShade::BackBuffer, adjusted);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                             Techniques
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    technique TECH_Droste <
        ui_label     = "Droste Effect";
        ui_tooltip   = "------About-------\n"
                       "Droste.fx warps the image-space to recursively appear within itself.\n\n"
                       "Version:    " COBRA_DRO_VERSION "\nAuthor:     SirCobra\nCollection: CobraFX\n"
                       "            https://github.com/LordKobra/CobraFX";
    >
    {
        pass Droste
        {
            VertexShader = VS_Droste;
            PixelShader  = PS_Droste;
        }
    }
}
