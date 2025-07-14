////////////////////////////////////////////////////////////////////////////////////////////////////////
// Cobra Utility (CobraUtility.fxh) by SirCobra
// Version 0.3.1
// You can find info and all my shaders here: https://github.com/LordKobra/CobraFX
//
// --------Description---------
// This header file contains useful functions and definitions for other shaders to use.
//
// ----------Credits-----------
// The credits are written above the functions.
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

// Mode: 0: Includes
//       1: UI
//       2: Helper functions
#ifndef COBRA_UTL_MODE
    #error "COBRA_UTL_MODE not defined"
#endif

// Use color & depth functions
#ifndef COBRA_UTL_COLOR
    #define COBRA_UTL_COLOR 0
#endif

// Hide UI Elements in UI Section
#ifndef COBRA_UTL_HIDE_FADE
    #define COBRA_UTL_HIDE_FADE false
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//                                            Defines & UI
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

#if (COBRA_UTL_MODE == 0)

    #ifndef M_PI
        #define M_PI 3.1415927
    #endif

    #ifndef M_E
        #define M_E 2.71828183
    #endif

    #define COBRA_UTL_VERSION "0.3.1"
    #define COBRA_UTL_VERSION_NUMBER 1030

    #define COBRA_UTL_UI_GENERAL "\n / General Options /\n"
    #define COBRA_UTL_UI_COLOR "\n /  Color Masking  /\n"
    #define COBRA_UTL_UI_DEPTH "\n /  Depth Masking  /\n"
    #define COBRA_UTL_UI_EXTRAS "\n /      Extras     /\n"

    // vector mod and normal fmod
    #undef fmod
    #define fmod(x, y) (frac((x)*rcp(y)) * (y))

    #undef ROUNDUP
    #define ROUNDUP(x, y) (((x - 1) / y) + 1)

    /* 
    BUFFER_COLOR_BIT_DEPTH Color bit depth of the backbuffer (8, 10 or 16)
    BUFFER_COLOR_SPACE Color space type for presentation:
    0 = unknown -> do nothing
    1 = sRGB -> s2lrgb               sRGB transfer function + BT.709 primaries
    2 = scRGB -> sc2lrgb             linear + BT.709 primaries
    3 = HDR10 ST2084 (PQ) -> pq2lrgb PQ + BT.2020 primaries
    4 = HDR10 HLG -> HLGToLRGB       HLG + BT.2020 primaries)
    */
    #define COBRA_UTL_CSP_UNKNOWN ((BUFFER_COLOR_SPACE == 0))
    #define COBRA_UTL_CSP_SRGB    ((BUFFER_COLOR_SPACE == 1))
    #define COBRA_UTL_CSP_SCRGB   ((BUFFER_COLOR_SPACE == 2))
    #define COBRA_UTL_CSP_ST2084  ((BUFFER_COLOR_SPACE == 3))
    #define COBRA_UTL_CSP_HLG     ((BUFFER_COLOR_SPACE == 4))

    // The rest is considered REC709 for now, scRGB is converted to Rec2020
    #define COBRA_UTL_CSP_REC2020 (COBRA_UTL_CSP_SCRGB || (COBRA_UTL_CSP_ST2084 || COBRA_UTL_CSP_HLG)) 

    #define COBRA_UTL_SDR_WHITEPOINT 203.0
    #define COBRA_UTL_HDR_MAXCLL 1000.0

    #if COBRA_UTL_CSP_SRGB
        #define COBRA_UTL_MAXCLL COBRA_UTL_SDR_WHITEPOINT
    #else
        #define COBRA_UTL_MAXCLL COBRA_UTL_HDR_MAXCLL
    #endif
#endif

#if (COBRA_UTL_MODE == 1)

    uniform bool UI_ShowMask <
        ui_label     = " Show Mask";
        ui_spacing   = 2;
        ui_tooltip   = "Show the masked pixels. White areas will be preserved, black/grey areas can be affected by\n"
                       "the shaders encompassed.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform bool UI_InvertMask <
        ui_label     = " Invert Mask";
        ui_tooltip   = "Invert the mask.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform bool UI_FilterColor <
        ui_label     = " Filter by Color";
        ui_spacing   = 2;
        ui_tooltip   = "Activates the color masking option.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = false;

    uniform bool UI_ShowSelectedHue <
        ui_label     = " Show Selected Hue";
        ui_tooltip   = "Display the currently selected hue range at the top of the image.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = false;

    uniform float UI_Lightness <
        ui_label     = " Lightness";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "Lightness describes the perceived luminance of a color in comparsion to perceptually uniform\n"
                       "greyscale. In simple terms, it is comparable to brightness.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.000;

    uniform float UI_LightnessRange <
        ui_label     = " Lightness Range";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.001;
        ui_step      = 0.001;
        ui_tooltip   = "The tolerance around the Lightness.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.001;

    uniform float UI_LightnessEdge <
        ui_label     = " Lightness Fade";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The smoothness beyond the Lightness range.";
        ui_category  = COBRA_UTL_UI_COLOR;
        hidden       = COBRA_UTL_HIDE_FADE;
    >                = 0.000;

    uniform float UI_Chroma <
        ui_label     = " Chroma";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "Chroma describes how distinct a color is from a grey tone of the same lightness.\n"
                       "Pure hues possess high chroma, tints and shades possess a lower chroma, with\n"
                       "pure grey at zero.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.000;

    uniform float UI_ChromaRange <
        ui_label     = " Chroma Range";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.001;
        ui_step      = 0.001;
        ui_tooltip   = "The tolerance around the Chroma.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.001;

    uniform float UI_ChromaEdge <
        ui_label     = " Chroma Fade";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The smoothness beyond the Chroma range.";
        ui_category  = COBRA_UTL_UI_COLOR;
        hidden       = COBRA_UTL_HIDE_FADE;
    >                = 0.000;

    uniform float UI_Hue <
        ui_label     = " Hue";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "Hue describes the color category. It can be red, orange, yellow, green, blue,\n"
                       "violet or inbetween.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 1.000;

    uniform float UI_HueRange <
        ui_label     = " Hue Range";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 0.501;
        ui_step      = 0.001;
        ui_tooltip   = "The tolerance around the hue.";
        ui_category  = COBRA_UTL_UI_COLOR;
    >                = 0.501;

    uniform float UI_HueEdge <
        ui_label     = " Hue Fade";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 0.501;
        ui_step      = 0.001;
        ui_tooltip   = "The smoothness beyond the hue range.";
        ui_category  = COBRA_UTL_UI_COLOR;
        hidden       = COBRA_UTL_HIDE_FADE;
    >                = 0.000;

    uniform bool UI_FilterDepth <
        ui_label     = " Filter By Depth";
        ui_spacing   = 2;
        ui_tooltip   = "Activates the depth masking option.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = false;

    uniform float UI_FocusDepth <
        ui_label     = " Focus Depth";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "Manual focus depth of the point which has the focus. Ranges from 0.0, which means camera is\n"
                       "the focus plane, till 1.0 which means the horizon is the focus plane.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 0.030;

    uniform float UI_FocusRangeDepth <
        ui_label     = " Focus Range";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "The range of the depth around the manual focus which should still be in focus.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 0.020;

    uniform float UI_FocusEdgeDepth <
        ui_label     = " Focus Fade";
        ui_type      = "slider";
        ui_min       = 0.000;
        ui_max       = 1.000;
        ui_tooltip   = "The smoothness of the edge of the focus range. Range from 0.0, which means sudden transition,\n"
                       "till 1.0, which means the effect is smoothly fading towards camera and horizon.";
        ui_step      = 0.001;
        ui_category  = COBRA_UTL_UI_DEPTH;
        hidden       = COBRA_UTL_HIDE_FADE;
    >                = 0.000;

    uniform bool UI_Spherical <
        ui_label     = " Spherical Focus";
        ui_tooltip   = "Enables the mask in a sphere around the focus-point instead of a 2D plane.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = false;

    uniform int UI_SphereFieldOfView <
        ui_label     = " Spherical Field of View";
        ui_type      = "slider";
        ui_min       = 1;
        ui_max       = 180;
        ui_units     = "°";
        ui_tooltip   = "Specifies the estimated Field of View (FOV) you are currently playing with. Range from 1°,\n"
                       "till 180° (half the scene). Normal games tend to use values between 60° and 90°.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 75;

    uniform float UI_SphereFocusHorizontal <
        ui_label     = " Spherical Horizontal Focus";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.0;
        ui_tooltip   = "Specifies the location of the focus point on the horizontal axis. Range from 0, which means\n"
                       "left screen border, till 1 which means right screen border.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 0.5;

    uniform float UI_SphereFocusVertical <
        ui_label     = " Spherical Vertical Focus";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.0;
        ui_tooltip   = "Specifies the location of the focus point on the vertical axis. Range from 0, which means\n"
                       "upper screen border, till 1 which means bottom screen border.";
        ui_category  = COBRA_UTL_UI_DEPTH;
    >                = 0.5;

#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//                                           Helper Functions
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

#if (COBRA_UTL_MODE == 2)

    //
    // Vertex Shader
    //

    struct vs2ps
    {
        float4 vpos : SV_Position;
        float4 uv : TEXCOORD0;
    };

    vs2ps vs_basic(const uint id, float2 extras)
    {
        vs2ps o;
        o.uv.x  = (id == 2) ? 2.0 : 0.0;
        o.uv.y  = (id == 1) ? 2.0 : 0.0;
        o.uv.zw = extras;
        o.vpos  = float4(o.uv.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
        return o;
    }

    void VS_Clear(in uint id : SV_VertexID, out float4 position : SV_Position)
    {
        position = -3;
    }

    void PS_Clear(float4 position : SV_Position, out float4 output0 : SV_TARGET0)
    {
        output0 = 0;
        discard;
    }

    //
    // Math
    //

    // return value [-M_PI, M_PI]
    float atan2_approx(float y, float x)
    {
        return acos(x * rsqrt(y * y + x * x)) * (y < 0 ? -1 : 1);
    }

    // Interleaved gradient noise:
    // Input: 2D integer pixel position
    // Returns: float in range [0,1]
    float ign(float2 pixel)
    {
        return frac(52.9829189 * frac(0.06711056 * pixel.x + 0.00583715 * pixel.y));
    }

    float3 interpolate(float3 a, float3 b, float3 c)
    {
        return abs(b - c) / abs(a - b);
    }

    //
    // Colors
    //

    float3 srgb_to_xyz(float3 srgb)
    {
        const float3x3 M_SRGB_TO_XYZ = float3x3( 0.4124564, 0.3575761, 0.1804375,
                                                 0.2126729, 0.7151522, 0.0721750,
                                                 0.0193339, 0.1191920, 0.9503041  );
        return mul(M_SRGB_TO_XYZ, srgb);
    }

    float3 xyz_to_srgb(float3 xyz)
    {
        const float3x3 M_XYZ_TO_SRGB = float3x3(  3.2404542, -1.5371385, -0.4985314,
                                                 -0.9692660,  1.8760108,  0.0415560,
                                                  0.0556434, -0.2040259,  1.0572252  );
        return mul(M_XYZ_TO_SRGB, xyz);
    }

    float3 xyz_to_cielab(float3 xyz)
    {
        const float3 W_D65_XYZ  = float3(0.95047, 1.000, 1.08883);
        const float EPSILON     = 216.0 / 24389.0;
        const float KAPPA       = 24389.09 / 27.0;

        float3 xyz_r = xyz / W_D65_XYZ;
        float3 f = xyz_r > EPSILON ? pow(abs(xyz_r), 1.0 / 3.0) : KAPPA / 116.0 * xyz_r + 16.0 / 116.0;
        float3 lab = float3(0.0, 0.0, 0.0);
        lab.x = 116.0 * f.y - 16.0;
        lab.y = 500.0 * (f.x - f.y);
        lab.z = 200.0 * (f.y - f.z);
        return lab;
    }

    float3 cielab_to_xyz(float3 lab)
    {
        const float3 W_D65_XYZ  = float3(0.95047, 1.000, 1.08883);
        const float EPSILON     = 216.0 / 24389.0;
        const float KAPPA       = 24389.09 / 27.0;

        float3 f = float3(0.0, 0.0, 0.0);
        f.y = (lab.x + 16.0) / 116.0;
        f.x = lab.y / 500.0 + f.y;
        f.z = f.y - lab.z / 200.0;
        float3 xyz = f > pow(EPSILON, 1.0 / 3.0) ? f * f * f : (f - 16.0 / 116.0) * (116.0 / KAPPA);
        xyz = xyz * W_D65_XYZ;
        return xyz;
    }

    float3 xyz_to_oklab(float3 xyz)
    {
        const float3x3 M_XYZ_TO_LMS    = float3x3( 0.8189330101,  0.3618667424, -0.1288597137,
                                                   0.0329845436,  0.9293118715,  0.0361456387,
                                                   0.0482003018,  0.2643662691,  0.6338517070  );

        const float3x3 M_LMSD_TO_OKLAB = float3x3( 0.2104542553,  0.7936177850, -0.0040720468,
                                                   1.9779984951, -2.4285922050,  0.4505937099,
                                                   0.0259040371,  0.7827717662, -0.8086757660  );
        float3 lms  = mul(M_XYZ_TO_LMS, xyz);
        float3 lmsd = pow(abs(lms), 1.0 / 3.0);
        return mul(M_LMSD_TO_OKLAB, lmsd);
    }

    float3 oklab_to_xyz(float3 oklab)
    {
        const float3x3 M_LMS_TO_XYZ    = float3x3(  1.22701385, -0.55779998,  0.28125615,
                                                   -0.04058018,  1.11225687, -0.07167668,
                                                   -0.07638128, -0.42148198,  1.58616322  );
        const float3x3 M_OKLAB_TO_LMSD = float3x3( 1.00000000,  0.39633779,  0.21580376,
                                                   1.00000001, -0.10556134, -0.06385417,
                                                   1.00000005, -0.08948418, -1.29148554  );
        float3 lmsd = mul(M_OKLAB_TO_LMSD, oklab);
        float3 lms  = pow(abs(lmsd), 3.0);
        return mul(M_LMS_TO_XYZ, lms);
    }

    float3 srgb_to_oklab(float3 srgb)
    {
        const float3x3 M_SRGB_TO_LMS = float3x3( 0.4122214708, 0.5363325363, 0.0514459929,
                                                 0.2119034982, 0.6806995451, 0.1073969566,
                                                 0.0883024619, 0.2817188376, 0.6299787005  );
        const float3x3 M_LMSD_TO_OKLAB = float3x3( 0.2104542553,  0.7936177850, -0.0040720468,
                                                   1.9779984951, -2.4285922050,  0.4505937099,
                                                   0.0259040371,  0.7827717662, -0.8086757660  );
        float3 lms = mul(M_SRGB_TO_LMS, srgb);
        float3 lmsd = pow(abs(lms), 1.0 / 3.0);
        return  mul(M_LMSD_TO_OKLAB, lmsd);
    }

    float3 oklab_to_srgb(float3 oklab)
    {
        const float3x3 M_OKLAB_TO_LMSD = float3x3( 1.00000000,  0.39633779,  0.21580376,
                                                   1.00000001, -0.10556134, -0.06385417,
                                                   1.00000005, -0.08948418, -1.29148554  );
        const float3x3 M_LMS_TO_SRGB = float3x3(  4.0767416621, -3.3077115913,  0.2309699292,
                                                 -1.2684380046,  2.6097574011, -0.3413193965,
                                                 -0.0041960863, -0.7034186147,  1.7076147010  );
        float3 lmsd = mul(M_OKLAB_TO_LMSD, oklab);
        float3 lms = pow(abs(lmsd), 3.0);
        return mul(M_LMS_TO_SRGB, lms);
    }

    float3 oklab_to_oklch(float3 oklab)
    {
        float l = oklab.x; // lightness: [0,1]
        float c = length(oklab.yz); // chrominance [0,0.38)
        float h = (c == 0) ? 0.0 : atan2_approx(oklab.z, oklab.y); // hue [-PI,PI]
        return float3(l, c, h);
    }

    float3 oklch_to_oklab(float3 oklch)
    {
        float l = oklch.x;
        float a = oklch.y * cos(oklch.z);
        float b = oklch.y * sin(oklch.z);
        return float3(l, a, b);
    }

    float3 rec2020_to_xyz(float3 rec2020)
    {
        const float3x3 M_REC2020_TO_XYZ = float3x3( 0.63695806, 0.14461690,  0.16888096,
                                                    0.26270020, 0.67799806,  0.05930171,
                                                    0.00000000, 0.02807269,  1.06098508  );
        return mul(M_REC2020_TO_XYZ, rec2020);
    }

    float3 xyz_to_rec2020(float3 xyz)
    {
        const float3x3 M_XYZ_TO_REC2020 = float3x3(  1.71665120, -0.35567077, -0.25336629,
                                                    -0.66668432,  1.61648118,  0.01576854,
                                                     0.01763985, -0.04277061,  0.94210314  );
        return mul(M_XYZ_TO_REC2020, xyz);
    }

    float3 rec2020_to_rec709(float3 rec2020)
    {
        const float3x3 M_REC2020_TO_REC709 = float3x3(  1.66049098, -0.58764111, -0.07284986,
                                                     -0.12455047,  1.13289988, -0.00834942,
                                                     -0.01815076, -0.10057889,  1.11872971  );
        return mul(M_REC2020_TO_REC709, rec2020);
    }

    float3 rec709_to_rec2020(float3 rec709)
    {
        const float3x3 M_REC709_TO_REC2020 = float3x3(  0.62740391,  0.32928302,  0.04331306,
                                                      0.06909728,  0.91954040,  0.01136231,
                                                      0.01639143,  0.08801330,  0.89559525  );
        return mul(M_REC709_TO_REC2020, rec709);
    }

    // HSV conversions by Sam Hocevar: http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
    float3 srgb_to_hsv(float3 c)
    {
        const float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p       = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        float4 q       = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
        float d        = q.x - min(q.w, q.y);
        const float E  = 1.0e-10;
        return float3(abs(q.z + (q.w - q.y) / (6.0 * d + E)), d / (q.x + E), q.x);
    }

    float3 hsv_to_srgb(float3 c)
    {
        const float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p       = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
        return float3(c.z * lerp(K.xxx, saturate(p - K.xxx), c.y));
    }

    float3 csp_to_oklab(float3 csp)
    {
#if COBRA_UTL_CSP_REC2020
        return xyz_to_oklab(rec2020_to_xyz(csp));
#else
        return srgb_to_oklab(csp);
#endif
    }

    float3 oklab_to_csp(float3 oklab)
    {
#if COBRA_UTL_CSP_REC2020
        return xyz_to_rec2020(oklab_to_xyz(oklab));
#else
        return oklab_to_srgb(oklab);
#endif        
    }

    float3 csp_to_oklch(float3 csp)
    {
        return oklab_to_oklch(csp_to_oklab(csp));
    }

    float3 oklch_to_csp(float3 oklch)
    {
        return oklab_to_csp(oklch_to_oklab(oklch));
    }

    float csp_to_luminance(float3 csp)
    {
#if COBRA_UTL_CSP_REC2020
        const float3 rec2020_weight = float3(0.26270020, 0.67799806,  0.05930171);
        return dot(csp, rec2020_weight);
#else
        const float3 rec709_weight = float3(0.2126729, 0.7151522, 0.0721750);
        return dot(csp, rec709_weight);
#endif
    }

    float3 csp_to_xyz(float3 csp)
    {
#if COBRA_UTL_CSP_REC2020
        return rec2020_to_xyz(csp);
#else
        return srgb_to_xyz(csp);
#endif        
    }

    float3 xyz_to_csp(float3 xyz)
    {
#if COBRA_UTL_CSP_REC2020
        return xyz_to_rec2020(xyz);
#else
        return xyz_to_srgb(xyz);
#endif                
    }

    float3 rec709_to_csp(float3 c)
    {
#if COBRA_UTL_CSP_REC2020
        return rec709_to_rec2020(c);
#else
        return c;
#endif           
    }

    // Transfer functions

    float3 srgb_to_linear(float3 c)
    {   
        // https://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html?m=1
        // Use either formula for 2.2, or formula for 2.4, but dont mix numbers
        // lilium says: for legacy reasons better use 2.2 powerlaw
        //return pow(saturate(c), 2.2);
        return (c < 0.04045) ? c / 12.92 : pow((abs(c) + 0.055) / 1.055, 2.4);
    }

    float3 linear_to_srgb(float3 c)
    {
        // return pow(saturate(c), 1.0 / 2.2);
        return (c < 0.0031308) ? c * 12.92 : 1.055 * pow(c, (1.0 / 2.4)) - 0.055;
    }

    float3 scrgb_to_linear(float3 c)
    {
        c = c * 80.0 / COBRA_UTL_SDR_WHITEPOINT;
        // @TODO for now we convert scRGB to Rec2020 for uniform HDR experience
        return rec709_to_rec2020(c);
    }

    float3 linear_to_scrgb(float3 c)
    {
        c = rec2020_to_rec709(c);
        return c * COBRA_UTL_SDR_WHITEPOINT / 80.0;
    }

    float3 pq_eotf(float3 n) // compressed -> linear
    {
        const float M1 = 2610.0 / 4096.0 * 0.25;
        const float M2 = 2523.0 / 4096.0 * 128.0;
        const float C1 = 3424.0 / 4096.0;
        const float C2 = 2413.0 / 4096.0 * 32.0;
        const float C3 = 2392.0 / 4096.0 * 32.0;
        return pow(max( pow(n, 1.0 / M2) - C1, 0.0) / (C2 - C3 * pow(n, 1.0 / M2)), 1.0 / M1);
    }

    float3 pq_inverse_eotf(float3 l) // linear -> compressed
    {
        const float M1 = 2610.0 / 4096.0 * 0.25;
        const float M2 = 2523.0 / 4096.0 * 128.0;
        const float C1 = 3424.0 / 4096.0;
        const float C2 = 2413.0 / 4096.0 * 32.0;
        const float C3 = 2392.0 / 4096.0 * 32.0;
        return pow((C1 + C2 * pow(l, M1)) / (1.0 + C3 * pow(l, M1)), M2);
    }

    float3 pq_to_linear(float3 c)
    {
        c = pq_eotf(c);
        return c * 10000.0 / COBRA_UTL_SDR_WHITEPOINT;
    }

    float3 linear_to_pq(float3 c)
    {
        c = c * COBRA_UTL_SDR_WHITEPOINT / 10000.0; //requires input: SDR = 1.0
        return pq_inverse_eotf(c);
    }

    float3 hlg_eotf(float3 es)
    {
        const float A = 0.17883277;
        const float B = 1.0 - 4.0 * A;
        const float C = 0.5 - A * log(4.0 * A);
        return es < 0.5 ? (es * es) / 3.0 : (exp((es - C) / A) + B) / 12.0;
    }

    float3 hlg_inverse_eotf(float3 e_in)
    {
        const float  A = 0.17883277;
        const float  B = 1.0 - 4.0 * A;
        const float  C = 0.5 - A * log(4.0 * A);
        float3 e = saturate(e_in);
        return e < 1.0 / 12.0 ? sqrt(3.0 * e) : A * log(12.0 * e - B) + C;
    }

    float3 hlg_to_linear(float3 c)
    {
        c = hlg_eotf(c);
        return c * 1000.0 / COBRA_UTL_SDR_WHITEPOINT;
    }

    float3 linear_to_hlg(float3 c)
    {
        // 1000 nits for now, to comply with reshade
        // https://github.com/crosire/reshade/blob/main/res/shaders/imgui_hdr.hlsl#L56
        c = c * COBRA_UTL_SDR_WHITEPOINT / 1000.0; //requires input: SDR = 1.0
        return hlg_inverse_eotf(c);
    }

    float3 enc_to_lin(float3 c)
    {
#if COBRA_UTL_CSP_SRGB
        return srgb_to_linear(c);
#elif COBRA_UTL_CSP_SCRGB
        return scrgb_to_linear(c);
#elif COBRA_UTL_CSP_ST2084
        return pq_to_linear(c);
#elif COBRA_UTL_CSP_HLG
        return hlg_to_linear(c);
#else
        return c;
#endif
    }

    float3 lin_to_enc(float3 c)
    {
#if COBRA_UTL_CSP_SRGB
        return linear_to_srgb(c);   // Rec.709
#elif COBRA_UTL_CSP_SCRGB
        return linear_to_scrgb(c);  // Rec.709
#elif COBRA_UTL_CSP_ST2084
        return linear_to_pq(c);     // Rec.2020
#elif COBRA_UTL_CSP_HLG
        return linear_to_hlg(c);    // Rec.2020
#else
        return c;
#endif
    }

    float3 dither_linear_to_srgb(float3 linear_color, float2 pixel)
    {
        const float QUANT = 1.0 / (float(1 << BUFFER_COLOR_BIT_DEPTH) - 1.0);
        float noise = ign(pixel);
        float3 c0   = floor(lin_to_enc(linear_color) / QUANT) * QUANT;
        float3 c1   = c0 + QUANT;
        float3 ival = interpolate(enc_to_lin(c0), enc_to_lin(c1), linear_color);
        ival        = noise > ival;
        return lerp(c0, c1, ival);
    }

    float3 dither_linear_to_encoding(float3 linear_color, float2 pixel)
    {
#if (BUFFER_COLOR_BIT_DEPTH == 8)
        return dither_linear_to_srgb(linear_color, pixel);
#else
        return lin_to_enc(linear_color);
#endif
    }

    //
    // Other
    //

    float3 normalize_oklch(float3 oklch, bool hdr_range)
    {
        const float MAX = csp_to_oklab(float3((COBRA_UTL_MAXCLL / COBRA_UTL_SDR_WHITEPOINT).xxx)).x;
        float l_max = hdr_range ? MAX : 1.0; // @BlendOp
        // maxvals for axis normalization in Rec.2020: C: 0.48
        return (oklch + float3(0.0, 0.0, M_PI)) / float3(l_max, 0.48, 2.0 * M_PI);
    }

        float3 ui_to_csp(float3 c)
    {
        c = srgb_to_linear(c);
        c = rec709_to_csp(c);
        return c;
    }

        float get_z_from_depth(float depth)
    {
        const float NEAR = 1.0;
        const float FAR  = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
        // from direct depth
        //return -far * near / (depth * (far - near) - far);
        //from linarized depth
        return depth * (FAR - NEAR) + NEAR;
    }

    float get_z_from_uniform(float depth)
    {
        const float FAR  = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
        return depth * FAR;
    }

    // return 1 if in range, otherwise edge
    float check_range(float value, float ui_val, float ui_range, float ui_edge)
    {
        float val     = saturate(value);
        float edge    = abs(value - ui_val) - ui_range;
        return 1.0 - smoothstep(0.0, ui_edge, edge);
    }

    #if COBRA_UTL_COLOR

        float3 screen_to_camera(float2 texcoord, float z)
        {   
            const float FOVY = float(UI_SphereFieldOfView) * M_PI / 180.0;
            const float FAR  = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
            const float F    = cos(0.5 * FOVY) / sin(0.5 * FOVY);
            const float AR   = ReShade::AspectRatio;//BUFFER_WIDTH * BUFFER_RCP_HEIGHT;

            float2 xy_screen = texcoord * 2.0 - 1.0;
            float4 camera = float4(0.0, 0.0, 0.0, 0.0);
            camera.z      = z;
            camera.w      = -camera.z;
            camera.y      = xy_screen.y * camera.w / F;
            camera.x      = xy_screen.x * camera.w * AR / F;
            return camera.xyz / FAR;
        }

        // show the color bar. inspired by originalnicodrs design
        float3 show_hue(float2 texcoord, float3 fragment)
        {
            const float RANGE = 0.145;
            const float DEPTH = 0.06;
            if (abs(texcoord.x - 0.5) < RANGE && texcoord.y < DEPTH)
            {
                float2 texcoord_new = float2(saturate(texcoord.x - 0.5 + RANGE) 
                                      / (2.0 * RANGE), (1.0 - texcoord.y / DEPTH));
                float3 oklch        = float3(0.75, 0.151 * texcoord_new.y,  texcoord_new.x * 2.0 * M_PI - M_PI);
                float3 oklch_norm   = normalize_oklch(oklch, false);
                float3 col          = oklch_to_csp(oklch);
                // good gradient: lightness: 0.75, chroma 0.121 // Rec.709 compatible
                // clamped but more saturated: lightness: 0.75, chroma 0.15

                //chroma
                float c             = abs(oklch_norm.y - UI_Chroma);
                float c_edge        = saturate(c - (UI_ChromaRange));
                c = 1.0 - smoothstep(0.0, UI_ChromaEdge, c_edge);

                // hue
                float h             = min(float(abs(oklch_norm.z - UI_Hue)), float(1.0 - abs(oklch_norm.z - UI_Hue)));
                h                   = h - rcp(100.0 * saturate((oklch_norm.y < 0.15 ? oklch_norm.y / 0.15 : 1.0) - 0.08)
                                               + 1.0);
                float h_edge        = saturate(h - (UI_HueRange * 1.05 - 0.025));
                h                   = 1.0 - smoothstep(0.0, UI_HueEdge, h_edge);

                fragment = lerp(0.5, col, c * h); // @BlendOp
            }

            return fragment;
        }

        // The effect can be applied to a specific color and depth area
        float check_focus(float3 col, float scene_depth, float2 texcoord)
        {
            // colorfilter
            float3 oklch      = csp_to_oklch(col);
            float3 oklch_norm = normalize_oklch(oklch, true);

            // Lightness
            float l = check_range(oklch_norm.x, UI_Lightness, UI_LightnessRange, UI_LightnessEdge);

            //chroma
            float c      = abs(oklch_norm.y - UI_Chroma);
            float c_edge = saturate(c - (UI_ChromaRange));
            c            = 1.0 - smoothstep(0.0, UI_ChromaEdge, c_edge);

            // hue
            float h      = min(float(abs(oklch_norm.z - UI_Hue)), float(1.0 - abs(oklch_norm.z - UI_Hue)));
            h            = h - rcp(100 * saturate((oklch_norm.y < 0.15 ? oklch_norm.y/0.15 : 1.0) - 0.08) + 1.0);
            float h_edge = saturate(h - (UI_HueRange * 1.05 - 0.025));
            h            = 1.0 - smoothstep(0.0, UI_HueEdge, h_edge);

            float is_color_focus = max(l * c * h, UI_FilterColor == 0);

            // depthfilter
            const float POW_FACTOR       = 2.0;
            const float FOCUS_RANGE      = pow(UI_FocusRangeDepth, POW_FACTOR);
            const float FOCUS_EDGE       = pow(UI_FocusEdgeDepth, POW_FACTOR);
            const float FOCUS_DEPTH      = pow(UI_FocusDepth, POW_FACTOR);
            const float FOCUS_FULL_RANGE = FOCUS_RANGE + FOCUS_EDGE;
            float3 camera_sphere         = screen_to_camera(float2(UI_SphereFocusHorizontal, UI_SphereFocusVertical),
                                                            get_z_from_uniform(FOCUS_DEPTH));
            float3 camera_pixel          = screen_to_camera(texcoord, get_z_from_depth(scene_depth));
            float depth_diff             = UI_Spherical 
                                            ? sqrt(dot(camera_sphere - camera_pixel, camera_sphere - camera_pixel))
                                            : abs(scene_depth - FOCUS_DEPTH);

            float depth_val              = 1.0 - saturate((depth_diff > FOCUS_FULL_RANGE) 
                                           ? 1.0 : smoothstep(FOCUS_RANGE, FOCUS_FULL_RANGE, depth_diff));

            depth_val                    = max(depth_val, UI_FilterDepth == 0);
            float in_focus               = is_color_focus * depth_val;
            return lerp(in_focus, 1.0 - in_focus, UI_InvertMask);
        }

    #endif

#endif

#undef COBRA_UTL_HIDE_FADE
#undef COBRA_UTL_COLOR
#undef COBRA_UTL_MODE
