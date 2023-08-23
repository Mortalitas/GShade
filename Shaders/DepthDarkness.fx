////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Depth Darkness shader for ReShade
// By Frans Bouma, aka Otis / Infuse Project (Otis_Inf)
// https://fransbouma.com 
//
// This shader has been released under the following license:
//
// Copyright (c) 2023 Frans Bouma
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
// Version History
// 23-apr-2020:		v1.0: First release
//
////////////////////////////////////////////////////////////////////////////////////////////////////


#include "ReShade.fxh"

namespace DepthDarkness
{
// Uncomment line below for debug info / code / controls
//	#define CD_DEBUG 1
	
	#define DEPTH_DARKNESS_VERSION "v1.0"

	//////////////////////////////////////////////////
	//
	// User interface controls
	//
	//////////////////////////////////////////////////

	uniform float FocusPlane <
		ui_label= "Focus plane";
		ui_type = "drag";
		ui_min = 0.001; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The depth of the plane where the blur starts, related to the camera";
	> = 0.010;
	uniform float FocusRange <
		ui_label= "Focus range";
		ui_type = "drag";
		ui_min = 0.001; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The range around the focus plane that's more or less not blurred.\n1.0 is the FocusPlaneMaxRange.";
	> = 0.001;
	uniform float FocusPlaneMaxRange <
		ui_label= "Focus plane max range";
		ui_type = "drag";
		ui_min = 10; ui_max = 300;
		ui_step = 1;
		ui_tooltip = "The max range Focus Plane for when Focus Plane is 1.0.\n1000 is the horizon.";
	> = 50;
	uniform float3 DarknessColor <
		ui_label = "Darkness color";
		ui_type= "color";
	> = float3(0.0, 0.0, 0.0);
	uniform float BlendFactor <
		ui_label="Blend factor";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 1.00;
		ui_tooltip = "How strong the effect is applied to the original image. 1.0 is 100%, 0.0 is 0%.";
		ui_step = 0.01;
	> = 1.000;	
#if CD_DEBUG
	// ------------- DEBUG
	uniform bool DBVal1 <
		ui_category = "Debugging";
	> = false;
	uniform bool DBVal2 <
		ui_category = "Debugging";
	> = false;
	uniform float DBVal3f <
		ui_category = "Debugging";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 1.00;
		ui_step = 0.01;
	> = 0.0;
	uniform float DBVal4f <
		ui_category = "Debugging";
		ui_type = "drag";
		ui_min = 0.00; ui_max = 10.00;
		ui_step = 0.01;
	> = 1.0;
#endif
	//////////////////////////////////////////////////
	//
	// Defines, constants, samplers, textures, uniforms, structs
	//
	//////////////////////////////////////////////////

#ifndef BUFFER_PIXEL_SIZE
	#define BUFFER_PIXEL_SIZE	ReShade::PixelSize
#endif
#ifndef BUFFER_SCREEN_SIZE
	#define BUFFER_SCREEN_SIZE	ReShade::ScreenSize
#endif
	
	void PS_ApplyDarkness(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target0)
	{
		float colorDepth = ReShade::GetLinearizedDepth(texcoord);
		float focusRangeStart = (FocusPlane * FocusPlaneMaxRange) / 1000.0f;
		float focusRangeToUse = ((FocusRange * FocusPlaneMaxRange) / 10000.0f);
		float focusRangeEnd = focusRangeStart + focusRangeToUse;
		float4 color = tex2Dlod(ReShade::BackBuffer, float4(texcoord, 0.0f, 0.0f));
		// if color depth >= focus plane, we have to blend the darkness color with it. 
		float3 fragmentPreBlend = colorDepth < focusRangeStart ? color.rgb : lerp(color.rgb, DarknessColor, saturate(1-((focusRangeEnd-colorDepth) / focusRangeToUse)));
		fragment = float4(lerp(color.rgb, fragmentPreBlend.rgb, BlendFactor), 1.0f);
	}

	technique DepthDarkness
#if __RESHADE__ >= 40000
	< ui_tooltip = "Depth Darkness "
			DEPTH_DARKNESS_VERSION
			"\n===========================================\n\n"
			"Super-simple shader to apply a darkness at a depth\n"
			"with a softness edge\n\n"
			"By Frans 'Otis_Inf' Bouma and is part of OtisFX\n"
			"https://fransbouma.com | https://github.com/FransBouma/OtisFX"; >
#endif	
	{
		pass ApplyDarkness { VertexShader = PostProcessVS; PixelShader = PS_ApplyDarkness; }
	}
}