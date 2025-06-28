////////////////////////////////////////////////////////////////////////////////////////////////////////
// Gravity CS (Gravity_CS.fx) by SirCobra
// Version 0.4.0
// You can find info and all my shaders here: https://github.com/LordKobra/CobraFX
//
// --------Description---------
// Gravity_CS.fx lets pixels gravitate towards the bottom of the screen in the game's 3D environment.
// You can filter the affected pixels by depth and by color.
// It uses a custom seed (currently the Mandelbrot set) to determine the intensity of each pixel.
// Make sure to also test out the texture-RNG variant with the picture "gravity_noise.png" provided
// in the Textures folder. You can replace the texture with your own picture, as long as it
// is 1920x1080, RGBA8 and has the same name. Only the red-intensity is taken. So either use red
// images or greyscale images.
// The effect is quite resource consuming. On small resolutions, Gravity.fx may be faster. Lower
// the integer value of GRAVITY_HEIGHT to increase performance at cost of visual fidelity.
// ----------Credits-----------
// The effect can be applied to a specific area like a DoF shader. The basic methods for this were taken
// with permission from https://github.com/FransBouma/OtisFX/blob/master/Shaders/Emphasize.fx
// Code basis for the Mandelbrot set: http://nuclear.mutantstargoat.com/articles/sdr_fract/
// Thanks to kingeric1992 for optimizing the code!
// Thanks to FransBouma, Lord of Lunacy and Annihlator for advice on my first shader :)
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

namespace COBRA_XGRV
{

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                            Defines & UI
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Defines

    #define COBRA_XGRV_VERSION "0.4.0"

    #define COBRA_UTL_MODE 0
    #include ".\CobraUtility.fxh"

    #if (COBRA_UTL_VERSION_NUMBER < 1030)
        #error "CobraUtility.fxh outdated! Please update CobraFX!"
    #endif

    #ifndef GRAVITY_HEIGHT
        #define GRAVITY_HEIGHT 1080
    #endif

    #define COBRA_MIN(a, b) (int((a) < (b)) * (a) + int((b) <= (a)) * (b))
    #define COBRA_XGRV_HEIGHT COBRA_MIN(GRAVITY_HEIGHT, 2000)
    #define COBRA_XGRV_RES_Y (float(BUFFER_HEIGHT) / COBRA_XGRV_HEIGHT)
    #define COBRA_XGRV_RES_X 1
    #define GRAVITY_WIDTH (float(BUFFER_WIDTH) / COBRA_XGRV_RES_X)
    #define COBRA_XGRV_WORKLOAD 8
    #define COBRA_XGRV_THREADS ROUNDUP(COBRA_XGRV_HEIGHT, COBRA_XGRV_WORKLOAD)
    #define COBRA_XGRV_MEMORY_HEIGHT (COBRA_XGRV_THREADS * COBRA_XGRV_WORKLOAD)

    // We need Compute Shader Support
    #if (((__RENDERER__ >= 0xb000 && __RENDERER__ < 0x10000) || (__RENDERER__ >= 0x14300)) && __RESHADE__ >= 50900)
        #define COBRA_XGRV_COMPUTE 1
    #else
        #define COBRA_XGRV_COMPUTE 0
        #warning "Gravity_CS.fx does only work with ReShade 5.9 or newer, DirectX 11 or newer, OpenGL 4.3 or newer and Vulkan."
    #endif

    #if COBRA_XGRV_COMPUTE != 0

    // UI

    uniform float UI_GravityIntensity <
        ui_label     = " Gravity Intensity";
        ui_type      = "slider";
        ui_spacing   = 2;
        ui_min       = 0.00;
        ui_max       = 1.00;
        ui_step      = 0.01;
        ui_tooltip   = "Gravity strength. Higher values look cooler but can decrease FPS!";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0.50;

    uniform float UI_GravityRNG <
        ui_label     = " Gravity RNG";
        ui_type      = "slider";
        ui_min       = 0.01;
        ui_max       = 0.99;
        ui_step      = 0.02;
        ui_tooltip   = "Changes the random intensity of each pixel.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 0.75;

    uniform bool UI_UseImage <
        ui_label     = " Use Image";
        ui_tooltip   = "Changes the RNG to the input image called gravity_noise.png located in the Textures folder.\n"
                       "You can change the image for your own RNG as long as the name and resolution stay the same.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = true;

    uniform bool UI_InvertGravity <
        ui_label     = " Invert Gravity";
        ui_tooltip   = "Pixels will gravitate upwards.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform bool UI_AllowOverlapping <
        ui_label     = " Allow Overlapping";
        ui_tooltip   = "This way, the effect does not get hidden behind other objects.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    uniform float UI_NoiseSize <
        ui_label     = " Noise Size";
        ui_type      = "slider";
        ui_min       = 0.001;
        ui_max       = 1.000;
        ui_step      = 0.001;
        ui_tooltip   = "Size of the noise texture. A lower value means larger noise pixels.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = 1.000;

    uniform bool UI_HotsamplingMode <
        ui_label     = " Hotsampling Mode";
        ui_tooltip   = "The noise will be the same at all resolutions. Activate this, then adjust your options\n"
                       "and it will stay the same at all resolutions. Turn this off when you do not intend\n"
                       "to hotsample.";
        ui_category  = COBRA_UTL_UI_GENERAL;
    >                = false;

    #define COBRA_UTL_MODE 1
    #include ".\CobraUtility.fxh"

    /*     uniform int UI_BlendMode <
            ui_label     = " Blend Mode";
            ui_type      = "radio";
            ui_spacing   = 2;
            ui_items     = "Tint\0Saturate\0Desaturate\0Oversaturate\0";
            ui_tooltip   = "The blend mode applied to the pixel, depending on its distance travelled.";
            ui_category  = COBRA_XGRV_UI_EXTRAS;
        >                = 0; */

    uniform bool UI_LockLightness <
        ui_label           = " Lock Lightness";
        ui_spacing         = 2;
        ui_tooltip         = "Lock the lightness to the ingame lightness.";
        ui_category        = COBRA_UTL_UI_EXTRAS;
        ui_category_closed = true; // Remains here just in case
    >                      = true;

    uniform bool UI_LockChroma <
        ui_label     = " Lock Chroma";
        ui_tooltip   = "Lock the chroma to the ingame chroma.";
        ui_category  = COBRA_UTL_UI_EXTRAS;
    >                = false;

    uniform bool UI_LockHue <
        ui_label     = " Lock Hue";
        ui_tooltip   = "Lock the hue to the ingame hue.";
        ui_category  = COBRA_UTL_UI_EXTRAS;
    >                = false;

    uniform float3 UI_EffectTint <
        ui_label     = " Effect Tint";
        ui_type      = "color";
        ui_tooltip   = "Specifies the tint of the gravitating pixels, the further they move away from their origin.";
        ui_category  = COBRA_UTL_UI_EXTRAS;
    >                = float3(0.50, 0.50, 0.50);

    uniform float UI_BlendIntensity <
        ui_label     = " Blend Intensity";
        ui_type      = "slider";
        ui_min       = 0.0;
        ui_max       = 1.0;
        ui_tooltip   = "Specifies intensity of the blending applied to the gravitating pixels. Range from 0.0, which\n"
                       "means no change, till 1.0, which means fully blended.";
        ui_category  = COBRA_UTL_UI_EXTRAS;
    >                = 0.0;

    uniform int UI_BufferEnd <
        ui_type     = "radio";
        ui_spacing  = 2;
        ui_text     = " Preprocessor Options:\n * GRAVITY_HEIGHT (default value: 1024) defines the "
                      "resolution of the effect along the gravitational axis. The value needs to be integer. "
                      "Smaller values give performance at cost of visual fidelity. 768: Performance 1080: HD Quality. "
                      "Set it to 'BUFFER_HEIGHT' if you always want to run the effect at native resolution.\n\n"
                      " Shader Version: " COBRA_XGRV_VERSION;
        ui_label    = " ";
    > ;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                         Textures & Samplers
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Texture

    texture TEX_GravitySeedMap
    {
        Width  = GRAVITY_WIDTH;
        Height = COBRA_XGRV_HEIGHT;
        Format = R16F;
    };

    texture TEX_GravitySeedMap2 <
        source = "gravity_noise.png";
    >
    {
        Width  = 1920;
        Height = 1080;
        Format = R8;
    };

    texture TEX_GravityCurrentSettings
    {
        Width  = 1;
        Height = 1;
        Format = R16F;
    };

    texture TEX_GravityMain
    {
        Width  = GRAVITY_WIDTH;
        Height = COBRA_XGRV_HEIGHT;
#if (BUFFER_COLOR_BIT_DEPTH == 8)
        Format = RGBA8;
#elif (BUFFER_COLOR_BIT_DEPTH == 10)
        Format = RGB10A2;
#else
        Format = RGBA16F;
#endif
    };

    // Sampler

    sampler2D SAM_GravitySeedMap
    {
        Texture   = TEX_GravitySeedMap;
        MagFilter = POINT;
        MinFilter = POINT;
        MipFilter = POINT;
    };

    sampler2D SAM_GravitySeedMap2
    {
        Texture   = TEX_GravitySeedMap2;
        MagFilter = POINT;
        MinFilter = POINT;
        MipFilter = POINT;
        // AddressU = REPEAT;
        // AddressV = REPEAT;
    };
    sampler2D SAM_GravityCurrentSettings { Texture = TEX_GravityCurrentSettings; };

    sampler2D SAM_GravityMain
    {
        Texture   = TEX_GravityMain;
        MagFilter = POINT;
        MinFilter = POINT;
        MipFilter = POINT;
    };

    // Storage

    storage STOR_GravityMain { Texture = TEX_GravityMain; };

    // Groupshared Memory

    groupshared uint final_list[COBRA_XGRV_MEMORY_HEIGHT];
    groupshared float depth_list[COBRA_XGRV_MEMORY_HEIGHT];
    groupshared float depth_listU[COBRA_XGRV_MEMORY_HEIGHT];
    groupshared uint strengthen[COBRA_XGRV_MEMORY_HEIGHT];
    groupshared uint max_str;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                           Helper Functions
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    #define COBRA_UTL_MODE 2
    #define COBRA_UTL_COLOR 1
    #include "CobraUtility.fxh"

    // calculate Mandelbrot Seed
    // inspired by http://nuclear.mutantstargoat.com/articles/sdr_fract/
    float mandelbrot_rng(float2 texcoord : TEXCOORD)
    {
        const float2 CENTER = float2(0.675, 0.46);           // an interesting center at the mandelbrot for our zoom
        const float ZOOM    = 0.033 * UI_GravityRNG;                                // smaller numbers increase zoom
        const float AR      = float(ReShade::ScreenSize.x) / ReShade::ScreenSize.y; // format to screenspace
        float2 c            = float2(AR, 1.0) * (texcoord - 0.5) * ZOOM - CENTER;
        float2 z            = c;
        uint i;
        for (i = 0; i < 100; i++)
        {
            float x = z.x * z.x - z.y * z.y + c.x;
            float y = 2.0 * z.x * z.y + c.y;
            if ((x * x + y * y) > 4.0)
                break;
            z.x = x;
            z.y = y;
        }

        const float INTENSITY = 1.0;
        return saturate(((INTENSITY * (i == 100 ? 0.0 : float(i)) / 100.0) - 0.8) / 0.22);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                              Shaders
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    void CS_Gravity(uint3 id : SV_DispatchThreadID, uint3 tid : SV_GroupThreadID, uint gi : SV_GroupIndex)
    {
        uint max_strength = 0;
        if(tid.y == 0) 
            max_str = 0;

        barrier();
        uint start        = tid.y * COBRA_XGRV_WORKLOAD;
        uint finish       = -1 + COBRA_XGRV_WORKLOAD;
        float x_norm      = (round(id.x * COBRA_XGRV_RES_X) + 0.5) / BUFFER_WIDTH;
        // At resolutions below 1920x1080 the texture will be too small for hotsampling mode and it looks off
        // The thread write interval distribution function: We have O(n*n) total required writes split equally
        const uint F   = COBRA_XGRV_HEIGHT * COBRA_XGRV_WORKLOAD;
        uint fi_start  = round(sqrt(tid.y * F));
        uint fi_finish = UI_AllowOverlapping ? COBRA_XGRV_HEIGHT - 1 : round(sqrt((tid.y + 1) * F)) - 1;

        // populate arrays
        [unroll] for (uint yz = 0; yz <= finish; yz++)
        {
            uint y        = yz + start;
            uint yi       = y + (COBRA_XGRV_HEIGHT - 1 - 2 * y) * UI_InvertGravity;
            final_list[y] = y;
            depth_list[y] = depth_listU[y] = ReShade::GetLinearizedDepth(float2(x_norm, (round(yi * COBRA_XGRV_RES_Y) + 0.5) / BUFFER_HEIGHT));
            float3 rgb                     = tex2Dfetch(ReShade::BackBuffer, int2(id.x * COBRA_XGRV_RES_X, yi * COBRA_XGRV_RES_Y)).rgb;
            rgb                            = enc_to_lin(rgb);
            float strength                 = tex2Dfetch(SAM_GravitySeedMap, int2(id.x, yi)).r;
            strength     *= check_focus(rgb, depth_list[y], float2(x_norm, (round(y * COBRA_XGRV_RES_Y) + 0.5) / BUFFER_HEIGHT));
            strengthen[y] = strength * UI_GravityIntensity * (COBRA_XGRV_HEIGHT - 2.0);
            max_strength = max(max_strength, strengthen[y]);
        }
        atomicMax(max_str, max_strength);
        barrier();

        max_strength = max_str;

        uint paint_iterator = 0;

        // heuristic. close pixel with long dist probably completely cover pixels below which we can then skip
        uint skip_position = 0;
        float skip_depth   = 1.0; // PIXEL INDEX, DEPTH

        // apply gravity to array
        for (uint y = max(0, fi_start - max_strength - 1); y < fi_finish; y++) //< , because last entry only occludes itself
        {
            float scene_depth = depth_list[y];
            uint strength     = strengthen[y];

            if (!UI_AllowOverlapping)
            {
                // normal
                uint yymax = min(fi_finish, min(y + strength, COBRA_XGRV_HEIGHT - 1));
                bool skip  = (skip_position >= yymax && skip_depth <= scene_depth || yymax < fi_start);
                if (skip)
                    continue;

                if (yymax > skip_position)
                {
                    skip_position = yymax;
                    skip_depth    = scene_depth;
                }

                for (uint yy = max(y + 1, fi_start); yy <= yymax; yy++)
                {
                    if (depth_listU[yy] > scene_depth) // affected
                    {
                        final_list[yy]  = y;
                        depth_listU[yy] = depth_list[y];
                        // atomicExchange(final_list[yy], y);
                    }
                }
            }
            else
            {
                if (tid.y == 0)
                { // version for overlapping is not multithreaded (runs as fast as single thread though)
                    if (paint_iterator == y)
                        paint_iterator++;

                    uint imax      = min(y + strength, COBRA_XGRV_HEIGHT - 1);
                    uint i         = paint_iterator;
                    paint_iterator = max(paint_iterator, imax);

                    for (i; i <= imax; i++)
                    {
                        final_list[i] = y;
                        // depth_listU[i] = 0.0;
                    }
                }
            }
        }

        barrier();

        uint3 LOCK              = uint3(UI_LockLightness, UI_LockChroma, UI_LockHue);
        float3 effect_oklch     = csp_to_oklch(ui_to_csp(UI_EffectTint));
        effect_oklch            = effect_oklch * (1.0 - LOCK);
        float4 store_val        = 1.0;
        // store result in the buffer
        //[unroll] 
        for (uint yy = 0; yy <= finish; yy++)
        {
            uint y  = yy + start;
            uint fi = final_list[y] + (COBRA_XGRV_HEIGHT - 1 - 2 * final_list[y]) * UI_InvertGravity;
            uint yi = y + (COBRA_XGRV_HEIGHT - 1 - 2 * y) * UI_InvertGravity;
            if (y != final_list[y])
            {
                store_val.rgb         = tex2Dfetch(ReShade::BackBuffer, int2(id.x, fi * COBRA_XGRV_RES_Y)).rgb; // access
                store_val.rgb         = enc_to_lin(store_val.rgb);
                float blend_intensity = smoothstep(0.0, strengthen[final_list[y]], distance(y, final_list[y]));
                float3 source_oklab   = csp_to_oklab(store_val.rgb);
                float3 source_oklch   = oklab_to_oklch(source_oklab);
                float3 target_oklab   = oklch_to_oklab(source_oklch * LOCK + effect_oklch);
                target_oklab          = lerp(source_oklab, target_oklab, blend_intensity * UI_BlendIntensity); //@BlendOp
                store_val.rgb         = oklab_to_csp(target_oklab);
                store_val.rgb         = lin_to_enc(store_val.rgb);
                tex2Dstore(STOR_GravityMain, float2(id.x, yi), store_val);
            }
        }
    }

    /// SETUP

    void PS_GenerateRNGSetup(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float fragment : SV_Target)
    {
        uint2 coords = fmod(vpos.xy * UI_NoiseSize, float2(1920, 1080));
        coords       = UI_HotsamplingMode ? vpos.xy * float2(1919.0, 1079.0) 
                                            / (float2(GRAVITY_WIDTH, COBRA_XGRV_HEIGHT) - 1.0) * UI_NoiseSize 
                                          : coords;
        float value  = tex2Dfetch(SAM_GravitySeedMap2, coords).r;
        value        = saturate((value - 1.0 + UI_GravityRNG) / UI_GravityRNG);
        fragment     = UI_UseImage ? value : mandelbrot_rng(texcoord.xy);
    }

    /// MAIN

    // Generate new RNG if settings have changed
    vs2ps VS_GenerateRNG(uint id : SV_VertexID)
    {
        float settings = tex2Dfetch(SAM_GravityCurrentSettings, int2(0, 0)).r;
        float new_rng  = UI_NoiseSize * 1000 + UI_UseImage * 100 + UI_HotsamplingMode + UI_GravityRNG;
        bool renew     = abs(settings - new_rng) > 0.005;
        vs2ps o        = vs_basic(id, 0.0);
        if (!renew)
            o.vpos.xy = 0.0;

        return o;
    }

    void PS_GenerateRNG(vs2ps o, out float fragment : SV_Target)
    {
        uint2 coords = fmod(o.vpos.xy * UI_NoiseSize, float2(1920, 1080));
        coords       = UI_HotsamplingMode ? o.vpos.xy * float2(1919.0, 1079.0) 
                       / (float2(GRAVITY_WIDTH, COBRA_XGRV_HEIGHT) - 1) * UI_NoiseSize : coords;
        float value  = tex2Dfetch(SAM_GravitySeedMap2, coords).r;
        value        = saturate((value - 1.0 + UI_GravityRNG) / UI_GravityRNG);
        fragment     = UI_UseImage ? value : mandelbrot_rng(o.uv.xy);
    }

    /* void VS_Clear(in uint id : SV_VertexID, out float4 position : SV_Position)
    {
        position = -3;
    }

    void PS_Clear(float4 position : SV_Position, out float4 output0 : SV_TARGET0)
    {
        output0 = 0;
        discard;
    } */

    // update current settings - careful with pipeline placement -> goes at the end
    void PS_UpdateRNGSettings(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float fragment : SV_Target)
    {
        fragment = UI_NoiseSize * 1000 + UI_UseImage * 100 + UI_HotsamplingMode + UI_GravityRNG;
    }

    // Write to the backbuffer
    void PS_PrintGravity(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
    {
        fragment               = tex2D(SAM_GravityMain, texcoord);
        fragment.rgb           = enc_to_lin(fragment.rgb);
        float depth            = ReShade::GetLinearizedDepth(texcoord);
        float3 color           = tex2Dfetch(ReShade::BackBuffer, floor(vpos.xy)).rgb;
        color                  = enc_to_lin(color);
        fragment.rgb    = fragment.a ? fragment.rgb : color;
        float focus     = 1.0 - check_focus(color, depth, texcoord);
        fragment        = UI_ShowMask ? focus : fragment;
        fragment.rgb    = (UI_ShowSelectedHue * UI_FilterColor) ? show_hue(texcoord, fragment.rgb) : fragment.rgb;
        fragment.rgb    = lin_to_enc(fragment.rgb);
        fragment.a      = 1.0;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    //                                             Techniques
    //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    technique TECH_PreGravity < // @TODO move to VS culling
        hidden     = true;
        enabled    = true;
        timeout    = 1;
    >
    {
        pass GenerateRNG
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_GenerateRNGSetup;
            RenderTarget = TEX_GravitySeedMap;
        }
    }

    technique TECH_GravityCS <
        ui_label     = "Gravity CS";
        ui_tooltip   = "------About-------\n"
                       "Gravity_CS.fx lets pixels gravitate towards the bottom of the screen in the game's 3D environment.\n"
                       "You can filter the affected pixels by depth and by color.\n"
                       "It uses a custom seed (currently the Mandelbrot set) to determine the intensity of each pixel.\n"
                       "Make sure to also test out the image-RNG variant with the picture 'gravity_noise.png' provided\n"
                       "in the Textures folder. You can replace the texture with your own picture, as long as it\n"
                       "is 1920x1080, RGBA8 and has the same name. Only the red-intensity is taken. So either use red\n"
                       "images or greyscale images.\n"
                       "CS is the compute shader version of Gravity.fx, it works best on resolutions above 1080p,\n"
                       "although it can still perform like as Gravity.fx at lower resolutions. For quality-perfomance\n"
                       "balancing, read the preprocessor tooltip of GRAVITY_HEIGHT.\n\n"
                       "Version:    " COBRA_XGRV_VERSION "\nAuthor:     SirCobra\nCollection: CobraFX\n"
                       "            https://github.com/LordKobra/CobraFX";
    >
    {
        pass GenerateRNG
        {
            VertexShader = VS_GenerateRNG;
            PixelShader  = PS_GenerateRNG;
            RenderTarget = TEX_GravitySeedMap;
        }

        pass PrepareGravity
        {
            VertexShader       = VS_Clear;
            PixelShader        = PS_Clear;
            RenderTarget0      = TEX_GravityMain;
            ClearRenderTargets = true;
            PrimitiveTopology  = POINTLIST;
            VertexCount        = 1;
        }

        pass GravityMain
        {
            ComputeShader = CS_Gravity<1, COBRA_XGRV_THREADS>;
            DispatchSizeX = GRAVITY_WIDTH;
            DispatchSizeY = 1;
        }

        pass UpdateSettings
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_UpdateRNGSettings;
            RenderTarget = TEX_GravityCurrentSettings;
        }

        pass PrintGravity
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_PrintGravity;
        }
    }

    #endif // Shader End
}
