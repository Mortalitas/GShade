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

#include "ReShade.fxh"

texture FFKeepUI_Tex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler FFKeepUI_Sampler { Texture = FFKeepUI_Tex; };

void PS_FFKeepUI(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	color = tex2D(ReShade::BackBuffer, texcoord);
}

void PS_FFRestoreUI(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	float4 back = tex2D(ReShade::BackBuffer, texcoord);
	float4 keep = tex2D(FFKeepUI_Sampler, texcoord);

	color = lerp(back, keep, keep.a);
}

technique FFKeepUI <
	ui_tooltip = "Put me at the top of your shader list!";
	enabled = false;
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_FFKeepUI;
		RenderTarget = FFKeepUI_Tex;
	}
}

technique FFRestoreUI <
	ui_tooltip = "Put me after any effects you want to not alter the UI in your shader list!";
	enabled = false;
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_FFRestoreUI;
	}
}
