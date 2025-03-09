// KeepUI for FFXIV, Phantasy Star Online, and other games with a UI present as alpha data or a depth of 0.
// Authors: seri14 & Marot Satil
// 
// This is free and unencumbered software released into the public domain.
// 
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
// 
// In jurisdictions that recognize copyright laws, the author or authors
// of this software dedicate any and all copyright interest in the
// software to the public domain. We make this dedication for the benefit
// of the public at large and to the detriment of our heirs and
// successors. We intend this dedication to be an overt act of
// relinquishment in perpetuity of all present and future rights to this
// software under copyright law.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
// OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// Lightly optimized by Marot Satil for the GShade project.
// Special thanks to Sleeps_Hungry for the addition of the FFOccludeUI technique.

#ifndef KeepUIDebug
    #define KeepUIDebug 0 // Set to 1 if you need to use KeepUI's debug features.
#endif

#ifndef KeepUIType
    #define KeepUIType 0 // 0 - Default, turns off UI saving for unsupported games only. | 1 - Alpha-based/Final Fantasy XIV's UI saving mode | 2 - Shared depth buffer UI saving. | 3 - Dedicated depth buffer/Phantasy Star Online 2: New Genesis's UI saving mode.

    #if (__APPLICATION__ == 0x6f24790f || (__APPLICATION__ == 0xf133c441 && !(__RENDERER__ & 0x20000))) && KeepUIType == 0 // Final Fantasy XIV & The Sims 4 (DirectX 9 Only)
        #undef KeepUIType
        #define KeepUIType 1
        #define KeepUIOverride 1
    // PSO 2 depth saving via GShade's Depth II addon.
    #elif (__APPLICATION__ == 0x21050ce9 || __APPLICATION__ == 0x31d39829 || __APPLICATION__ == 0xfe44e135) && KeepUIType == 0 // Phantasy Star Online 2: New Genesis
        #undef KeepUIType
        #define KeepUIType 3
        #define KeepUIOverride 3
    #endif
#endif

uniform int bKeepUIForceType <
    ui_type = "combo";
    ui_category = "Options";
    ui_label = "UI Detection Type Override";
#ifndef __GSHADE__
#if !ADDON_RESHADE_EFFECT_SHADER_TOGGLER
    ui_tooltip = "Manually enable a specific UI detection type for unsupported games.\n\nIn order to use this setting as shown, please install the \"UIBind\" addon created by cot6.\n\nAlternatively, you may specify the type of UI saving you would like to use in the Preprocessor Definitions below by adjusting KeepUIType";
#else
    ui_tooltip = "KeepUI.fx is currently disabled due to the presence of the ReShade Effect Toggler (REST) Add-on. Changing this setting will have no effect.";
#endif
    ui_items = "Disabled\0Alpha\0Shared Depth\0";
#else
#if !ADDON_RESHADE_EFFECT_SHADER_TOGGLER
    ui_tooltip = "Manually enable a specific UI detection type for unsupported games.";
#else
    ui_tooltip = "KeepUI.fx is currently disabled due to the presence of the ReShade Effect Toggler (REST) Add-on. Changing this setting will have no effect.";
#endif
    ui_items = "Disabled\0Alpha\0Shared Depth\0Dedicated Depth\0";
#endif
    ui_bind = "KeepUIType";
#if KeepUIOverride == 1 // Final Fantasy XIV (DirectX 11 Only) & The Sims 4 (DirectX 9 Only)
> = 1;
#elif KeepUIOverride == 2
> = 2;
#elif KeepUIOverride == 3 // Phantasy Star Online 2
> = 3;
#else
> = 0;
#endif

#if KeepUIType != 0 && !ADDON_RESHADE_EFFECT_SHADER_TOGGLER // Supported game & REST add-on is not present.
uniform bool bKeepUIOcclude <
    ui_category = "Options";
    ui_label = "Occlusion Assistance";
    ui_tooltip = "Enable if you notice odd graphical issues with Bloom or similar shaders. May cause problems with SSDO when enabled.";
    ui_bind = "KeepUIOccludeAssist";
> = 0;

#ifndef KeepUIOccludeAssist
    #define KeepUIOccludeAssist 0
#endif

#if KeepUIOccludeAssist
uniform float fKeepUIOccludeMinAlpha <
    ui_type = "slider";
    ui_category = "Options";
    ui_label = "Occlusion Assistance Alpha Threshold";
    ui_tooltip = "Set a minimum opacity threshold for occlusion assistance. If UI opacity is below the threshold, occlusion assistance will not be applied. Helps with screenspace illumination and DoF shaders.";
    ui_min = 0; ui_max = 1;
> = 0;
#endif

uniform bool bKeepUIHideInScreenshot <
    ui_category = "Options";
    ui_label = "Hide KeepUI In Screenshots";
    ui_tooltip = "Enable to hide the effects of KeepUI when taking screenshots.\n\nThis is very helpful in games where portions of the screen which are not part of the UI may be detected as such.";
    ui_bind = "KeepUIHideInScreenshots";
> = 0;

#ifndef KeepUIHideInScreenshots
    #define KeepUIHideInScreenshots 0
#endif

#if KeepUIDebug
uniform bool bTroubleshootOpacityIssue <
    ui_category = "Troubleshooting (Do not use)";
    ui_label = "Enable UI Highlighting";
    ui_tooltip = "If you notice invalid colors on objects, enable FXAA in Final Fantasy XIV's Graphics Settings.\n"
                 "Open [System Configuration]\n"
                 "  -> [Graphics Settings]\n"
                 "  -> [General]\n"
                 " Set [Edge Smoothing (Anti-aliasing)] from \"Off\" to \"FXAA\"";
> = false;

uniform int iBlendSource <
    ui_category = "Troubleshooting (Do not use)";
    ui_label = "Blend Type"; ui_type = "combo";
    ui_items = "Checkerboard\0Negative\0";
> = 0;
#endif

#include "ReShade.fxh"
#if KeepUIType == 3
#include "GShade.fxh"
#endif
#endif

#if KeepUIType != 0 && !ADDON_RESHADE_EFFECT_SHADER_TOGGLER // Supported game & REST add-on is not present.
texture KeepUI_Tex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler KeepUI_Sampler { Texture = KeepUI_Tex; };

void PS_KeepUI(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
    color = tex2D(ReShade::BackBuffer, texcoord);
#if KeepUIType == 2
    color.a = step(1.0, 1.0 - ReShade::GetLinearizedDepth(texcoord));
#elif KeepUIType == 3
    color.a = step(1.0, 1.0 - GShade::GetLinearizedDepthII(texcoord));
#endif
}

#if KeepUIOccludeAssist
void PS_OccludeUI(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
    float4 keep = tex2D(KeepUI_Sampler, texcoord);
    keep.a *= step(fKeepUIOccludeMinAlpha, keep.a);
    color = float4(lerp(tex2D(ReShade::BackBuffer, texcoord), float4(0, 0, 0, 0), keep.a).rgb, keep.a);
}
#endif

void PS_RestoreUI(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
#if KeepUIDebug
    const float4 keep = tex2D(KeepUI_Sampler, texcoord);

    if (bTroubleshootOpacityIssue)
    {
        if (0 == iBlendSource)
        {
            if (step(1, pos.x / 32 % 2) == step(1, pos.y / 32 % 2))
                color = lerp(0.45, keep, keep.a);
            else
                color = lerp(0.55, keep, keep.a);
            color.a = keep.a;
        }
        else
        {
            if (step(1.19209e-07, keep.a))
                color = lerp(1 - keep, keep, 1-keep.a);
            else
                color = lerp(keep, keep, 1 - keep.a);
            color.a = keep.a;
        }
    }
    else
    {
        color   = float4(lerp(tex2D(ReShade::BackBuffer, texcoord), keep, keep.a).rgb, keep.a);
    }
#else
    color = tex2D(ReShade::BackBuffer, texcoord);
    const float4 keep = tex2D(KeepUI_Sampler, texcoord);

    color.rgb   = lerp(color.rgb, keep.rgb, keep.a).rgb;
#endif
}
#endif

technique FFKeepUI <
#if !ADDON_RESHADE_EFFECT_SHADER_TOGGLER
    ui_tooltip = "Place this at the top of your Technique list to save the UI into a texture for restoration with FFRestoreUI.\n"
                 "To use this Technique, you must also enable \"FFRestoreUI\".\n";
#else
    ui_tooltip = "KeepUI.fx is currently disabled due to the presence of the ReShade Effect Toggler (REST) Add-on.";
#endif
>
{
#if KeepUIType != 0 && !ADDON_RESHADE_EFFECT_SHADER_TOGGLER // Supported game & REST add-on is not present.
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_KeepUI;
        RenderTarget = KeepUI_Tex;
    }
#if KeepUIOccludeAssist
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_OccludeUI;
    }
#endif
#endif
}

technique FFRestoreUI <
#if !ADDON_RESHADE_EFFECT_SHADER_TOGGLER
    ui_tooltip = "Place this at the bottom of your Technique list to restore the UI texture saved by FFKeepUI.\n"
                 "To use this Technique, you must also enable \"FFKeepUI\".\n";
#else
    ui_tooltip = "KeepUI.fx is currently disabled due to the presence of the ReShade Effect Toggler (REST) Add-on.";
#endif
#if KeepUIHideInScreenshots
    enabled_in_screenshot = false;
#endif
>
{
#if KeepUIType != 0 && !ADDON_RESHADE_EFFECT_SHADER_TOGGLER // Supported game & REST add-on is not present.
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_RestoreUI;
    }
#endif
}
