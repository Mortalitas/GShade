/*******************************************************
	ReShade Shader: RetroTint
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

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float3 fUIColor<
    ui_type = "color";
    ui_label = "Color";
> = float3(0.1, 0.0, 0.3);

uniform float fUIStrength<
    ui_type = "slider";
    ui_label = "Srength";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.01;
> = 1.0;

float3 RetroTintPS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
    const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    //Blend mode: Screen
#if GSHADE_DITHER
    const float3 outcolor = lerp(color, 1.0 - (1.0 - color) * (1.0 - fUIColor), fUIStrength);
    return outcolor + TriDither(outcolor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
    return lerp(color, 1.0 - (1.0 - color) * (1.0 - fUIColor), fUIStrength);
#endif
}

technique RetroTint {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = RetroTintPS;
        /* RenderTarget = BackBuffer */
    }
}