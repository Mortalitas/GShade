// SkySave
// Author: Marot Satil
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

#include "ReShade.fxh"

texture SkySave_Tex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler SkySave_Sampler { Texture = SkySave_Tex; };

uniform float fSkySaveDepth <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Depth";
> = 0.999;

void PS_SkySave(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	if (ReShade::GetLinearizedDepth(texcoord) > fSkySaveDepth)
	{
        color = tex2D(ReShade::BackBuffer, texcoord);
	}
	else
	{
		color = float4(0.0, 0.0, 0.0, 2.0);
	}
}

void PS_SkyRestore(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
    const float4 keep = tex2D(SkySave_Sampler, texcoord);

	if (keep.a != 2.0)
	{
		color = keep;
	}
	else
	{
		color = tex2D(ReShade::BackBuffer, texcoord);
	}
}

technique SkySave <
    ui_tooltip = "Place this at the point in your load order where you want to save the sky for later restoration with SkyRestore.\n"
                 "To use this Technique, you must also enable \"SkyRestore\".\n";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SkySave;
        RenderTarget = SkySave_Tex;
    }
}

technique SkyRestore <
    ui_tooltip = "Place this at the point in your load order where you want to restore the sky previously saved by SkySave.\n"
                 "To use this Technique, you must also enable \"SkySave\".\n";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SkyRestore;
    }
}
