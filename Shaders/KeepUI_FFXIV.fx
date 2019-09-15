// KeepUI for FFXIV
// Author: seri14
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
#define KeepUIDebug 0
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

uniform bool iOccludeToggle <
  ui_label = "Occlusion Assistance";
> = 0;

#include "ReShade.fxh"

texture FFKeepUI_Tex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler FFKeepUI_Sampler { Texture = FFKeepUI_Tex; };

void PS_FFKeepUI(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	color = tex2D(ReShade::BackBuffer, texcoord);
}

void PS_FFOccludeUI(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	const float4 keep = tex2D(FFKeepUI_Sampler, texcoord);
	if (iOccludeToggle)
  {
    const float4 back = tex2D(ReShade::BackBuffer, texcoord);
    color = lerp(back, float4(0, 0, 0, 0), keep.a);
    color.a = keep.a;
  }
  else
    color = keep;
}

void PS_FFRestoreUI(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	const float4 keep = tex2D(FFKeepUI_Sampler, texcoord);
	const float4 back = tex2D(ReShade::BackBuffer, texcoord);
	
#if KeepUIDebug
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
		color   = lerp(back, keep, keep.a);
		color.a = keep.a;
	}
#else
		color   = lerp(back, keep, keep.a);
		color.a = keep.a;
#endif
}

#undef KeepUIDebug

technique FFKeepUI <
	ui_tooltip = "Place this at the top of your Technique list to save the UI into a texture for restoration with FFRestoreUI.\n"
	             "To use this Technique, you must also enable \"FFRestoreUI\".\n"
	             "To enable Debug mode for testing, set the value of the preprocessor definition \"KeepUIDebug\" to 1.";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_FFKeepUI;
		RenderTarget = FFKeepUI_Tex;
	}

	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_FFOccludeUI;
	}
}

technique FFRestoreUI <
	ui_tooltip = "Place this at the bottom of your Technique list to restore the UI texture saved by FFKeepUI.\n"
	             "To use this Technique, you must also enable \"FFKeepUI\".\n"
	             "To enable Debug mode for testing, set the value of the preprocessor definition \"KeepUIDebug\" to 1.";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_FFRestoreUI;
	}
}
