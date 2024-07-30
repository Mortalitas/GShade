/*******************************************************
	ReShade Shader: Composition
	https://github.com/Daodan317081/reshade-shaders
	License: BSD 3-Clause
	Modified by Marot for ReShade 4.0 compatibility and lightly optimized for the GShade project.

	BSD 3-Clause License

	Copyright (c) 2018-2019, Alexander Federwisch
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this
	list of conditions and the following disclaimer.

	* Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.

	* Neither the name of the copyright holder nor the names of its
	contributors may be used to endorse or promote products derived from
	this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************/

#include "ReShade.fxh"

#define COMP_GOLDEN_RATIO 1.6180339887
#define COMP_INV_GOLDEN_RATIO  1.0 / 1.6180339887

uniform int UIGridType <
    ui_type = "combo";
    ui_label = "Grid Type";
    ui_items = "Center Lines\0Thirds\0Fifths\0Golden Ratio\0Diagonals\0";
> = 0;

uniform float4 UIGridColor <
	ui_type = "color";
    ui_label = "Grid Color";
> = float4(0.0, 0.0, 0.0, 1.0);

uniform float UIGridLineWidth <
	ui_type = "slider";
    ui_label = "Grid Line Width";
    ui_min = 0.0; ui_max = 5.0;
    ui_steps = 0.01;
> = 1.0;

struct sctpoint {
    float3 color;
    float2 coord;
    float2 offset;
};

sctpoint NewPoint(float3 color, float2 offset, float2 coord)
{
    sctpoint p;
    p.color = color;
    p.offset = offset;
    p.coord = coord;
    return p;
}

float3 DrawPoint(float3 texcolor, sctpoint p, float2 texcoord)
{
    float2 pixelsize = BUFFER_PIXEL_SIZE * p.offset;
    
    if(p.coord.x == -1 || p.coord.y == -1)
        return texcolor;

    if(texcoord.x <= p.coord.x + pixelsize.x &&
    texcoord.x >= p.coord.x - pixelsize.x &&
    texcoord.y <= p.coord.y + pixelsize.y &&
    texcoord.y >= p.coord.y - pixelsize.y)
        return p.color;
    return texcolor;
}

float3 Composition_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    const float3 background = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 result;

    switch (UIGridType)
    {
        // Center Lines
        case 0:
        {
            sctpoint lineV1 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(0.5, texcoord.y));
            sctpoint lineH1 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(texcoord.x, 0.5));
    
            result = DrawPoint(background, lineV1, texcoord);
            result = DrawPoint(result, lineH1, texcoord);
            break;
        }
        // Thirds
        case 1:
        {
            sctpoint lineV1 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(1.0 / 3.0, texcoord.y));
            sctpoint lineV2 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(2.0 / 3.0, texcoord.y));

            sctpoint lineH1 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(texcoord.x, 1.0 / 3.0));
            sctpoint lineH2 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(texcoord.x, 2.0 / 3.0));
    
            result = DrawPoint(background, lineV1, texcoord);
            result = DrawPoint(result, lineV2, texcoord);
            result = DrawPoint(result, lineH1, texcoord);
            result = DrawPoint(result, lineH2, texcoord);

            break;
        }
        // Fifths
        case 2:
        {
            sctpoint lineV1 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(1.0 / 5.0, texcoord.y));
            sctpoint lineV2 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(2.0 / 5.0, texcoord.y));
            sctpoint lineV3 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(3.0 / 5.0, texcoord.y));
            sctpoint lineV4 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(4.0 / 5.0, texcoord.y));

            sctpoint lineH1 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(texcoord.x, 1.0 / 5.0));
            sctpoint lineH2 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(texcoord.x, 2.0 / 5.0));
            sctpoint lineH3 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(texcoord.x, 3.0 / 5.0));
            sctpoint lineH4 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(texcoord.x, 4.0 / 5.0));
    
            result = DrawPoint(background, lineV1, texcoord);
            result = DrawPoint(result, lineV2, texcoord);
            result = DrawPoint(result, lineV3, texcoord);
            result = DrawPoint(result, lineV4, texcoord);
            result = DrawPoint(result, lineH1, texcoord);
            result = DrawPoint(result, lineH2, texcoord);
            result = DrawPoint(result, lineH3, texcoord);
            result = DrawPoint(result, lineH4, texcoord);

            break;
        }
        // Golden Ratio
        case 3:
        {
            sctpoint lineV1 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(1.0 / COMP_GOLDEN_RATIO, texcoord.y));
            sctpoint lineV2 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(1.0 - 1.0 / COMP_GOLDEN_RATIO, texcoord.y));

            sctpoint lineH1 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(texcoord.x, 1.0 / COMP_GOLDEN_RATIO));
            sctpoint lineH2 = NewPoint(UIGridColor.rgb, UIGridLineWidth, float2(texcoord.x, 1.0 - 1.0 / COMP_GOLDEN_RATIO));

            result = DrawPoint(background, lineV1, texcoord);
            result = DrawPoint(result, lineV2, texcoord);
            result = DrawPoint(result, lineH1, texcoord);
            result = DrawPoint(result, lineH2, texcoord);

            break;
        }
        // Diagonals
        case 4:
        {
            float slope = (float)BUFFER_WIDTH / (float)BUFFER_HEIGHT;

            sctpoint line1 = NewPoint(UIGridColor.rgb, UIGridLineWidth,    float2(texcoord.x, texcoord.x * slope));
            sctpoint line2 = NewPoint(UIGridColor.rgb, UIGridLineWidth,  float2(texcoord.x, 1.0 - texcoord.x * slope));
            sctpoint line3 = NewPoint(UIGridColor.rgb, UIGridLineWidth,   float2(texcoord.x, (1.0 - texcoord.x) * slope));
            sctpoint line4 = NewPoint(UIGridColor.rgb, UIGridLineWidth,  float2(texcoord.x, texcoord.x * slope + 1.0 - slope));
    
            result = DrawPoint(background, line1, texcoord);
            result = DrawPoint(result, line2, texcoord);
            result = DrawPoint(result, line3, texcoord);
            result = DrawPoint(result, line4, texcoord);

            break;
        }
    }

    return lerp(background, result, UIGridColor.w);
}


technique Composition
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = Composition_PS;
	}
}