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

uniform float Sharpness <
	ui_type = "drag";
    ui_label = "Sharpening strength";
    ui_tooltip = "0 := no sharpening, to 1 := full sharpening.\nScaled by the sharpness knob while being transformed to a negative lobe (values from -1/5 to -1/8 for A=1)";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

#include "ReShade.fxh"

float3 min3rgb(float3 x, float3 y, float3 z)
{
     return min(x, min(y, z));
}
float3 max3rgb(float3 x, float3 y, float3 z)
{
     return max(x, max(y, z));
}

float3 CASPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{    
    // fetch a 3x3 neighborhood around the pixel 'e',
    //  a b c
    //  d(e)f
    //  g h i
    float pixelX = ReShade::PixelSize.x;
    float pixelY = ReShade::PixelSize.y;
    
    float3 a = tex2D(ReShade::BackBuffer, texcoord + float2(-pixelX, -pixelY)).rgb;
    float3 b = tex2D(ReShade::BackBuffer, texcoord + float2(0.0, -pixelY)).rgb;
    float3 c = tex2D(ReShade::BackBuffer, texcoord + float2(pixelX, -pixelY)).rgb;
    float3 d = tex2D(ReShade::BackBuffer, texcoord + float2(-pixelX, 0.0)).rgb;
    float3 e = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float3 f = tex2D(ReShade::BackBuffer, texcoord + float2(pixelX, 0.0)).rgb;
    float3 g = tex2D(ReShade::BackBuffer, texcoord + float2(-pixelX, pixelY)).rgb;
    float3 h = tex2D(ReShade::BackBuffer, texcoord + float2(0.0, pixelY)).rgb;
    float3 i = tex2D(ReShade::BackBuffer, texcoord + float2(pixelX, pixelY)).rgb;

    //McFly: vectorize math, even with scalar gcn hardware this should work
    //out the same, order of operations has not changed
  
	// Soft min and max.
	//  a b c             b
	//  d e f * 0.5  +  d e f * 0.5
	//  g h i             h
    // These are 2.0x bigger (factored out the extra multiply).

    float3 mnRGB = min3rgb(min3rgb(d, e, f), b, h);
    float3 mnRGB2 = min3rgb(min3rgb(mnRGB, a, c), g, i);
    mnRGB += mnRGB2;

    float3 mxRGB = max3rgb(max3rgb(d, e, f), b, h);
    float3 mxRGB2 = max3rgb(max3rgb(mxRGB, a, c), g, i);
    mxRGB += mxRGB2;

    // Smooth minimum distance to signal limit divided by smooth max.
    float3 rcpMRGB = rcp(mxRGB);
    float3 ampRGB = saturate(min(mnRGB, 2.0 - mxRGB) * rcpMRGB);    
    
    // Shaping amount of sharpening.
    ampRGB = sqrt(ampRGB);
    
    // Filter shape.
    //  0 w 0
    //  w 1 w
    //  0 w 0  
    float peak = -rcp(lerp(8.0, 5.0, saturate(Sharpness)));
    float3 wRGB = ampRGB * peak;

    float3 rcpWeightRGB = rcp(1.0 + 4.0 * wRGB);

    //McFly: less instructions that way
    float3 window = (b + d) + (f + h);
    float3 outColor = saturate((window * wRGB + e) * rcpWeightRGB);

    return outColor;
}

technique CAS
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CASPass;
	}
}