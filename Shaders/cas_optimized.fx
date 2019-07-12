// LICENSE
// =======
// Copyright (c) 2017-2019 Advanced Micro Devices, Inc. All rights reserved.
// -------
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// -------
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// -------
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

//Initial port to ReShade: SLSNe    https://gist.github.com/SLSNe/bbaf2d77db0b2a2a0755df581b3cf00c
//Optimizations by Marty McFly:
//     vectorized math, even with scalar gcn hardware this should work
//     out the same, order of operations has not changed
//     For some reason, it went from 64 to 48 instructions, a lot of MOV gone
//     Also modified the way the final window is calculated
//      
//     reordered min() and max() operations, from 11 down to 9 registers    
//
//     restructured final weighting, 49 -> 48 instructions
//
//     delayed RCP to replace SQRT with RSQRT
//
//     removed the saturate() from the control var as it is clamped
//     by UI manager already, 48 -> 47 instructions
//
//     replaced tex2D with tex2Doffset intrinsic (address offset by immediate integer)
//     47 -> 43 instructions
//     9 -> 8 registers

uniform float Sharpness <
	ui_type = "drag";
    ui_label = "Sharpening strength";
    ui_tooltip = "0 := no sharpening, to 1 := full sharpening.\nScaled by the sharpness knob while being transformed to a negative lobe (values from -1/5 to -1/8 for A=1)";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

#include "ReShade.fxh"

float3 CASPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{    
    // fetch a 3x3 neighborhood around the pixel 'e',
    //  a b c
    //  d(e)f
    //  g h i
    float3 a = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, -1)).rgb;
    float3 b = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, -1)).rgb;
    float3 c = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, -1)).rgb;
    float3 d = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb;
    float3 e = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, 0)).rgb;
    float3 f = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, 0)).rgb;
    float3 g = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, 1)).rgb;
    float3 h = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, 1)).rgb;
    float3 i = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, 1)).rgb;
  
	// Soft min and max.
	//  a b c             b
	//  d e f * 0.5  +  d e f * 0.5
	//  g h i             h
    // These are 2.0x bigger (factored out the extra multiply).
    float3 mnRGB = min(min(min(d, e), min(f, b)), h);
    float3 mnRGB2 = min(mnRGB, min(min(a, c), min(g, i)));
    mnRGB += mnRGB2;

    float3 mxRGB = max(max(max(d, e), max(f, b)), h);
    float3 mxRGB2 = max(mxRGB, max(max(a, c), max(g, i)));
    mxRGB += mxRGB2;

    // Smooth minimum distance to signal limit divided by smooth max.
    float3 rcpMRGB = rcp(mxRGB);
    float3 ampRGB = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);    
    
    // Shaping amount of sharpening.
    ampRGB = rsqrt(ampRGB);

    float peak = 8.0 - 3.0 * Sharpness;
    float3 wRGB = -rcp(ampRGB * peak);

    float3 rcpWeightRGB = rcp(1.0 + 4.0 * wRGB);

    //                          0 w 0
    //  Filter shape:           w 1 w
    //                          0 w 0  
    float3 window = (b + d) + (f + h);
    float3 outColor = saturate((window * wRGB + e) * rcpWeightRGB);

    return outColor;
}

technique ContrastAdaptiveSharpen
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CASPass;
	}
}
