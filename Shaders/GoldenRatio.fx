////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Golden Ratio shader for ReShade 3.x+, a port of my old version for reshade v1
// By Frans Bouma, aka Otis / Infuse Project (Otis_Inf)
// https://fransbouma.com 
//
// This shader has been released under the following license:
//
// Copyright (c) 2018-2022 Frans Bouma
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
#include "ReShade.fxh"

namespace GoldenRatio
{
	//////////////////////////////////////////////////
	//
	// User interface controls
	//
	//////////////////////////////////////////////////
	uniform float Opacity <
		ui_category = "General";
		ui_label= "Opacity";
		ui_type = "drag";
		ui_min = 0.000; ui_max = 1.0;
		ui_step = 0.001;
		ui_tooltip = "Opacity of overlay. 0 is invisible, 1 is opaque lines.";
	> = 0.3;
	
	uniform bool ResizeMode <
		ui_category = "General";
		ui_label = "Resize mode";
		ui_tooltip = "Resize mode: 0 is clamp to screen (so resizing of overlay, no golden ratio by definition),\n1: resize to either full with or full height while keeping aspect ratio: golden ratio by definition in lined area.";
	> = true;
	
	//////////////////////////////////////////////////
	//
	// Defines, constants, samplers, textures, uniforms, structs
	//
	//////////////////////////////////////////////////
	texture		texSpirals <source= "GoldenSpirals.png"; > { Width = 1748; Height = 1080; MipLevels = 1; Format = RGBA8; };
	
	sampler	samplerSpirals
	{
		Texture = texSpirals;
		MinFilter = LINEAR;
		MagFilter = LINEAR;
		MipFilter = LINEAR;
		AddressU = Clamp;
		AddressV = Clamp;
	};

	void PS_RenderSpirals(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 outFragment : SV_Target0)
	{
		float4 colFragment = tex2D(ReShade::BackBuffer, texcoord);
		float phiValue = ((1.0 + sqrt(5.0))/2.0);
		float idealWidth = BUFFER_HEIGHT * phiValue;
		float idealHeight = BUFFER_WIDTH / phiValue;
		float4 sourceCoordFactor = float4(1.0, 1.0, 1.0, 1.0);

		if(ResizeMode)
		{
			if(ReShade::AspectRatio < phiValue)
			{
				// display spirals at full width, but resize across height
				sourceCoordFactor = float4(1.0, BUFFER_HEIGHT/idealHeight, 1.0, idealHeight/BUFFER_HEIGHT);
			}
			else
			{
				// display spirals at full height, but resize across width
				sourceCoordFactor = float4(BUFFER_WIDTH/idealWidth, 1.0, idealWidth/BUFFER_WIDTH, 1.0);
			}
		}
		
		float4 spiralFragment = tex2D(samplerSpirals, float2((texcoord.x * sourceCoordFactor.x) - ((1.0-sourceCoordFactor.z)/2.0),
															(texcoord.y * sourceCoordFactor.y) - ((1.0-sourceCoordFactor.w)/2.0)));
		outFragment = saturate(colFragment + (spiralFragment * Opacity));
	}

	technique GoldenRatio
	{
		pass Render
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_RenderSpirals;
		}
	}
}