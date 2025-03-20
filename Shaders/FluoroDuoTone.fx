////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Fluoro Duotone shader for Reshade. 
// By Frans Bouma, aka Otis / Infuse Project (Otis_Inf)
// https://fransbouma.com 
//
// This shader has been released under the following license:
//
// Copyright (c) 2018-2019 Frans Bouma
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// 
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
////////////////////////////////////////////////////////////////////////////////////////////////////
// 
// This shader mimics the 80-ies fluoro duo tone effect, see this photoshop tutorial for more info:
// https://blog.spoongraphics.co.uk/tutorials/how-to-create-a-colorful-fluoro-pop-art-photo-effect
//
// After an idea by PhilGPT
////////////////////////////////////////////////////////////////////////////////////////////////////

#include "Reshade.fxh"

namespace FluoroDuoTone
{
	uniform float3 Layer1ShadowColor <
		ui_category = "Layer 1";
		ui_label= "Shadow color";
		ui_type = "color";
		ui_min = 0.0; ui_max = 1.0;
	> = float3(0.0, 0.0, 0.4);

	uniform float3 Layer1HighlightColor <
		ui_category = "Layer 1";
		ui_label= "Highlight color";
		ui_type = "color";
		ui_min = 0.0; ui_max = 1.0;
	> = float3(1.0, 1.0, 0.4);

	uniform float Layer1Opacity <
		ui_category = "Layer 1";
		ui_label= "Opacity";
		ui_type = "drag";
		ui_min = 0.0; ui_max = 1.0;
	> = 1.0;
	
	uniform float3 Layer2ShadowColor <
		ui_category = "Layer 2";
		ui_label= "Shadow color";
		ui_type = "color";
		ui_min = 0.0; ui_max = 1.0;
	> = float3(0.4, 0.0, 0.0);

	uniform float3 Layer2HighlightColor <
		ui_category = "Layer 2";
		ui_label= "Highlight color";
		ui_type = "color";
		ui_min = 0.0; ui_max = 1.0;
	> = float3(0.0, 0.5, 1.0);

	uniform float Layer2Opacity <
		ui_category = "Layer 2";
		ui_label= "Opacity";
		ui_type = "drag";
		ui_min = 0.0; ui_max = 1.0;
	> = 0.2;
	
	uniform float PatternOpacity <
		ui_category = "Pattern";
		ui_label= "Opacity";
		ui_type = "drag";
		ui_min = 0.0; ui_max = 1.0;
	> = 0.2;

	uniform float PatternDotSize <
		ui_category = "Pattern";
		ui_label= "Dot size (in pixels)";
		ui_type = "drag";
		ui_min = 1.0; ui_max = 100.0;
		ui_step = 0.1;
	> = 2.0;

	void PS_DoDuoTone(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0, out float4 fragment : SV_Target)
	{
		fragment = 0.0;
		const float3 currentFragment = tex2D(ReShade::BackBuffer, texcoord).rgb;
		const float luma = dot(currentFragment, float3(0.3, 0.59, 0.11));
		
		const float3 layer1Color = lerp(Layer1ShadowColor, Layer1HighlightColor, luma);
		const float3 layer2Color = lerp(Layer2ShadowColor, Layer2HighlightColor, luma);
		fragment.rgb = lerp(currentFragment, layer1Color, Layer1Opacity);
		fragment.rgb = lerp(fragment.rgb, layer2Color, Layer2Opacity);
		
		// add pattern.
		const float2 pixelCoords = ((texcoord / ReShade::PixelSize) / (PatternDotSize * ReShade::AspectRatio)) % 2;
		if(pixelCoords.x <= 1.0 || pixelCoords.y <= 1.0)
		{
			const float3 ditheredFragment = lerp(fragment.rgb, float3(0,0,0), 1-luma);
			fragment.rgb = lerp(fragment.rgb, ditheredFragment, PatternOpacity);
		}
	}

	technique FluoroDuoTone
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_DoDuoTone;
		}
	}
}