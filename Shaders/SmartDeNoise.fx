//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//  Copyright (c) 2018-2019 Michele Morrone
//  All rights reserved.
//
//  https://michelemorrone.eu - https://BrutPitt.com
//
//  me@michelemorrone.eu - brutpitt@gmail.com
//  twitter: @BrutPitt - github: BrutPitt
//  
//  https://github.com/BrutPitt/glslSmartDeNoise/
//
//  This software is distributed under the terms of the BSD 2-Clause license
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#include "ReShade.fxh"

uniform float uSigma <
	ui_label = "Standard Deviation Sigma Radius";
	ui_tooltip = "Standard Deviation Sigma Radius * K Factor Sigma Coefficient = Radius of the circular kernel.";
	ui_type = "slider";
	ui_min = 0.001;
	ui_max = 8.0;
	ui_step = 0.001;
> = 1.25;
uniform float uThreshold <
	ui_label = "Edge Sharpening Threshold";
	ui_type = "slider";
	ui_min = 0.001;
	ui_max = 0.25;
	ui_step = 0.001;
> = 0.05;
uniform float uKSigma <
	ui_label = "K Factor Sigma Coefficient";
	ui_tooltip = "Standard Deviation Sigma Radius * K Factor Sigma Coefficient = Radius of the circular kernel.";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 3.0;
	ui_step = 0.001;
> = 1.5;

#define INV_SQRT_OF_2PI 0.39894228040143267793994605993439  // 1.0/SQRT_OF_2PI
#define INV_PI 0.31830988618379067153776752674503
//  smartDeNoise - parameters
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  sampler2D tex     - sampler image / texture
//  float2 uv           - actual fragment coord
//  float sigma  >  0 - sigma Standard Deviation
//  float kSigma >= 0 - sigma coefficient 
//      kSigma * sigma  -->  radius of the circular kernel
//  float threshold   - edge sharpening threshold 

void PS_SmartDeNoise (in float4 pos : SV_Position, float2 uv : TEXCOORD, out float4 color : SV_Target)
{
    const float radius = round(uKSigma * uSigma);
    const float radQ = radius * radius;

    const float invSigmaQx2 = .5 / (uSigma * uSigma);      // 1.0 / ((uSigma * uSigma) * 2.0)
    const float invSigmaQx2PI = INV_PI * invSigmaQx2;    // // 1/(2 * PI * (uSigma * uSigma))

    const float invThresholdSqx2 = .5 / (uThreshold * uThreshold);     // 1.0 / ((uSigma * uSigma) * 2.0)
    const float invThresholdSqrt2PI = INV_SQRT_OF_2PI / uThreshold;   // 1.0 / (sqrt(2*PI) * uSigma)

    const float4 centrPx = tex2D(ReShade::BackBuffer, uv); 

    float zBuff = 0.0;
    float4 aBuff = float4(0.0, 0.0, 0.0, 0.0);
    const float2 size = ReShade::GetScreenSize();

    float2 d;
    for (d.x =- radius; d.x <= radius; d.x++) {
        float pt = sqrt(radQ - d.x * d.x);       // pt = yRadius: have circular trend
        for (d.y =- pt; d.y <= pt; d.y++) {
            float4 walkPx =  tex2Dlod(ReShade::BackBuffer, float4(uv + d / size, 0.0, 0.0));
            float4 dC = walkPx - centrPx;
            float deltaFactor = exp(-dot(dC, dC) * invThresholdSqx2) * invThresholdSqrt2PI * (exp(-dot(d , d) * invSigmaQx2) * invSigmaQx2PI);

            zBuff += deltaFactor;
            aBuff += deltaFactor * walkPx;
        }
    }
    color = aBuff / zBuff;
}

//  About Standard Deviations (watch Gauss curve)
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  kSigma = 1*sigma cover 68% of data
//  kSigma = 2*sigma cover 95% of data - but there are over 3 times 
//                   more points to compute
//  kSigma = 3*sigma cover 99.7% of data - but needs more than double 
//                   the calculations of 2*sigma


//  Optimizations (description)
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  fX = exp( -(x*x) * invSigmaSqx2 ) * invSigmaxSqrt2PI; 
//  fY = exp( -(y*y) * invSigmaSqx2 ) * invSigmaxSqrt2PI; 
//  where...
//      invSigmaSqx2     = 1.0 / (sigma^2 * 2.0)
//      invSigmaxSqrt2PI = 1.0 / (sqrt(2 * PI) * sigma)
//
//  now, fX*fY can be written in unique expression...
//
//      e^(a*X) * e^(a*Y) * c*c
//
//      where:
//        a = invSigmaSqx2, X = (x*x), Y = (y*y), c = invSigmaxSqrt2PI
//
//           -[(x*x) * 1/(2 * sigma^2)]             -[(y*y) * 1/(2 * sigma^2)] 
//          e                                      e
//  fX = -------------------------------    fY = -------------------------------
//                ________                               ________
//              \/ 2 * PI  * sigma                     \/ 2 * PI  * sigma
//
//      now with... 
//        a = 1/(2 * sigma^2), 
//        X = (x*x) 
//        Y = (y*y) ________
//        c = 1 / \/ 2 * PI  * sigma
//
//      we have...
//              -[aX]              -[aY]
//        fX = e      * c;   fY = e      * c;
//
//      and...
//                 -[aX + aY]    [2]     -[a(X + Y)]    [2]
//        fX*fY = e           * c     = e            * c   
//
//      well...
//
//                    -[(x*x + y*y) * 1/(2 * sigma^2)]
//                   e                                
//        fX*fY = --------------------------------------
//                                        [2]           
//                          2 * PI * sigma           
//      
//      now with assigned constants...
//
//          invSigmaQx2   = 1/(2 * sigma^2)
//          invSigmaQx2PI = 1/(2 * PI * sigma^2) = invSigmaQx2 * INV_PI 
//
//      and the kernel vector 
//
//          k = vec2(x,y)
//
//      we can write:
//
//          fXY = exp( -dot(k,k) * invSigmaQx2) * invSigmaQx2PI
//

technique SmartDeNoise {
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_SmartDeNoise;
	}
}
