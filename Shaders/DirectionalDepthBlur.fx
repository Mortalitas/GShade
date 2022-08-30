////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Directional Depth Blur shader for ReShade
// By Frans Bouma, aka Otis / Infuse Project (Otis_Inf)
// https://fransbouma.com 
//
// This shader has been released under the following license:
//
// Copyright (c) 2022 Frans Bouma
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
// 30-aug-2022: 	v1.3: Added filter circle with feather support for focus point strokes mode.
// 18-apr-2020:		v1.2: Added blend factor for blur
// 13-apr-2020:		v1.1: Added highlight control (I know it flips the hue in focus point mode, it's a bug that actually looks great), 
//					      higher precision in buffers, better defaults
// 10-apr-2020:		v1.0: First release
//
////////////////////////////////////////////////////////////////////////////////////////////////////


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

namespace DirectionalDepthBlur
{
// Uncomment line below for debug info / code / controls
	#define CD_DEBUG 1
	
	#define DIRECTIONAL_DEPTH_BLUR_VERSION "v1.3"

	//////////////////////////////////////////////////
	//
	// User interface controls
	//
	//////////////////////////////////////////////////

	uniform float FocusPlane <
		ui_category = "Focusing";
		ui_label= "Focus plane";
		ui_type = "slider";
		ui_min = 0.001; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The depth of the plane where the blur starts, related to the camera";
	> = 0.010;
	uniform float FocusRange <
		ui_category = "Focusing";
		ui_label= "Focus range";
		ui_type = "slider";
		ui_min = 0.001; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The range around the focus plane that's more or less not blurred.\n1.0 is the FocusPlaneMaxRange.";
	> = 0.001;
	uniform float FocusPlaneMaxRange <
		ui_category = "Focusing";
		ui_label= "Focus plane max range";
		ui_type = "slider";
		ui_min = 10; ui_max = 300;
		ui_step = 1;
		ui_tooltip = "The max range Focus Plane for when Focus Plane is 1.0.\n1000 is the horizon.";
	> = 150;
	uniform float BlurAngle <
		ui_category = "Blur tweaking";
		ui_label="Blur angle";
		ui_type = "slider";
		ui_min = 0.01; ui_max = 1.00;
		ui_tooltip = "The angle of the blur direction";
		ui_step = 0.01;
	> = 1.0;
	uniform float BlurLength <
		ui_category = "Blur tweaking";
		ui_label = "Blur length";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.0;
		ui_step = 0.001;
		ui_tooltip = "The length of the blur strokes per pixel. 1.0 is the entire screen.";
	> = 0.1;
	uniform float BlurQuality <
		ui_category = "Blur tweaking";
		ui_label = "Blur quality";
		ui_type = "slider";
		ui_min = 0.01; ui_max = 1.0;
		ui_step = 0.01;
		ui_tooltip = "The quality of the blur. 1.0 means all pixels in the blur length are\nread, 0.5 means half of them are read.";
	> = 0.5;
	uniform float ScaleFactor <
		ui_category = "Blur tweaking";
		ui_label = "Scale factor";
		ui_type = "slider";
		ui_min = 0.010; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The scale factor for the pixels to blur. Lower values downscale the\nsource frame and will result in wider blur strokes.";
	> = 1.000;
	uniform int BlurType < 
		ui_category = "Blur tweaking";
		ui_type = "combo";
		ui_min= 0; ui_max=1;
		ui_items="Parallel Strokes\0Focus Point Targeting Strokes\0";
		ui_label = "The blur type";
		ui_tooltip = "The blur type. Focus Point Targeting Strokes means the blur directions\nper pixel are towards the Focus Point.";
	> = 0;
	uniform float2 FocusPoint <
		ui_category = "Blur tweaking, Focus Point";
		ui_label = "Blur focus point";
		ui_type = "slider";
		ui_step = 0.001;
		ui_min = 0.000; ui_max = 1.000;
		ui_tooltip = "The X and Y coordinates of the blur focus point, which is used for\nthe Blur type 'Focus Point Targeting Strokes'. 0,0 is the\nupper left corner, and 0.5, 0.5 is at the center of the screen.";
	> = float2(0.5, 0.5);
	uniform float3 FocusPointBlendColor <
		ui_category = "Blur tweaking, Focus Point";
		ui_label = "Color";
		ui_type= "color";
		ui_tooltip = "The color of the focus point in Point focused mode. The closer a\npixel is to the focus point, the more it will become this color.\nIn (red , green, blue)";
	> = float3(0.0,0.0,0.0);
	uniform float FocusPointBlendFactor <
		ui_category = "Blur tweaking, Focus Point";
		ui_label = "Color blend factor";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The factor with which the focus point color is blended with the final image";
	> = 1.000;
	uniform bool FocusPointViewFilterCircleOnMouseDown <
		ui_category = "Blur tweaking, Focus Point";
		ui_label = "Show filter circle on mouse down";
		ui_tooltip = "For Focus Point Targeting Strokes blur type:\nIf checked, an overlay is shown with the current filter circle.\nWhite means blur will be present,\ntransparent means no blur will be present";
	> = false;
	uniform float FilterCircleRadius <
		ui_category = "Blur tweaking, Focus Point";
		ui_label = "Filter circle radius";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "For Focus Point Targeting Strokes blur type:\nThe radius of the filter circle.\nAll points within this circle are not or only partially blurred";
	> = 0.1;
	uniform float2 FilterCircleDeformFactors <
		ui_category = "Blur tweaking, Focus Point";
		ui_label = "Filter circle deform factors";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 2.000;
		ui_step = 0.001;
		ui_tooltip = "For Focus Point Targeting Strokes blur type:\nThe radius factors for width and height of the filter circle.\n1.0 means no deformation, another value means deformation in that direction";
	> = float2(1.0, 1.0);
	uniform float FilterCircleRotationFactor <
		ui_category = "Blur tweaking, Focus Point";
		ui_label = "Filter circle rotation factor";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "For Focus Point Targeting Strokes blur type:\nThe rotation factor of the filter circle";
	> = 0.1;
	uniform float FilterCircleFeather <
		ui_category = "Blur tweaking, Focus Point";
		ui_label = "Filter circle feather";
		ui_type = "slider";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "For Focus Point Targeting Strokes blur type:\nThe feather area within the filter circle.\n1.0 means the whole inner area is feathered,\n0.0 means no feather area.";
	> = 0.1;
	
	uniform float HighlightGain <
		ui_category = "Blur tweaking";
		ui_label="Highlight gain";
		ui_type = "slider";
		ui_min = 0.00; ui_max = 5.00;
		ui_tooltip = "The gain for highlights in the strokes plane. The higher the more a highlight gets\nbrighter.";
		ui_step = 0.01;
	> = 0.500;	
	uniform float BlendFactor <
		ui_category = "Blur tweaking";
		ui_label="Blend factor";
		ui_type = "slider";
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
		ui_type = "slider";
		ui_min = 0.00; ui_max = 1.00;
		ui_step = 0.01;
	> = 0.0;
	uniform float DBVal4f <
		ui_category = "Debugging";
		ui_type = "slider";
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
	#define PI 					3.1415926535897932
	
	uniform float2 MouseCoords < source = "mousepoint"; >;
	uniform bool LeftMouseDown < source = "mousebutton"; keycode = 0; toggle = false; >;
	
	texture texDownsampledBackBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
	texture texBlurDestination { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; }; 
	texture texFilterCircle { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };
	
	sampler samplerDownsampledBackBuffer { Texture = texDownsampledBackBuffer; AddressU = MIRROR; AddressV = MIRROR; AddressW = MIRROR;};
	sampler samplerBlurDestination { Texture = texBlurDestination; };
	sampler samplerFilterCircle { Texture = texFilterCircle; };
	
	struct VSPIXELINFO
	{
		float4 vpos : SV_Position;
		float2 texCoords : TEXCOORD0;
		float2 pixelDelta: TEXCOORD1;
		float blurLengthInPixels: TEXCOORD2;
		float focusPlane: TEXCOORD3;
		float focusRange: TEXCOORD4;
		float4 texCoordsScaled: TEXCOORD5;
	};
	
	//////////////////////////////////////////////////
	//
	// Functions
	//
	//////////////////////////////////////////////////
	
	float2 CalculatePixelDeltas(float2 texCoords)
	{
		float2 mouseCoords = MouseCoords * BUFFER_PIXEL_SIZE;
		
		return (float2(FocusPoint.x - texCoords.x, FocusPoint.y - texCoords.y)) * length(BUFFER_PIXEL_SIZE);
	}
	
	float3 AccentuateWhites(float3 fragment)
	{
		return fragment / (1.5 - clamp(fragment, 0, 1.49));	// accentuate 'whites'. 1.5 factor was empirically determined.
	}
	
	float3 CorrectForWhiteAccentuation(float3 fragment)
	{
		return (fragment.rgb * 1.5) / (1.0 + fragment.rgb);		// correct for 'whites' accentuation in taps. 1.5 factor was empirically determined.
	}
	
	float3 PostProcessBlurredFragment(float3 fragment, float maxLuma, float3 averageGained, float normalizationFactor)
	{
		const float3 lumaDotWeight = float3(0.3, 0.59, 0.11);

		averageGained.rgb = CorrectForWhiteAccentuation(averageGained.rgb);
		// increase luma to the max luma found on the gained taps. This over-boosts the luma on the averageGained, which we'll use to blend
		// together with the non-boosted fragment using the normalization factor to smoothly merge the highlights.
		averageGained.rgb *= 1+saturate(maxLuma - dot(fragment, lumaDotWeight));
		fragment = (1-normalizationFactor) * fragment + normalizationFactor * averageGained.rgb;
		return fragment;
	}
	
	//////////////////////////////////////////////////
	//
	// Vertex Shaders
	//
	//////////////////////////////////////////////////
	
	VSPIXELINFO VS_PixelInfo(in uint id : SV_VertexID)
	{
		VSPIXELINFO pixelInfo;
		
		if (id == 2)
			pixelInfo.texCoords.x = 2.0;
		else
			pixelInfo.texCoords.x = 0.0;
		if (id == 1)
			pixelInfo.texCoords.y = 2.0;
		else
			pixelInfo.texCoords.y = 0.0;
		pixelInfo.vpos = float4(pixelInfo.texCoords * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
		sincos(6.28318530717958 * BlurAngle, pixelInfo.pixelDelta.y, pixelInfo.pixelDelta.x);
		pixelInfo.pixelDelta *= length(BUFFER_PIXEL_SIZE);
		pixelInfo.blurLengthInPixels = length(BUFFER_SCREEN_SIZE) * BlurLength;
		pixelInfo.focusPlane = (FocusPlane * FocusPlaneMaxRange) / 1000.0; 
		pixelInfo.focusRange = (FocusRange * FocusPlaneMaxRange) / 1000.0;
		pixelInfo.texCoordsScaled = float4(pixelInfo.texCoords * ScaleFactor, pixelInfo.texCoords / ScaleFactor);
		return pixelInfo;
	}

	//////////////////////////////////////////////////
	//
	// Pixel Shaders
	//
	//////////////////////////////////////////////////

	void PS_Blur(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		const float3 lumaDotWeight = float3(0.3, 0.59, 0.11);
		// pixelInfo.texCoordsScaled.xy is for scaled down UV, pixelInfo.texCoordsScaled.zw is for scaled up UV
		float4 average = float4(tex2Dlod(samplerDownsampledBackBuffer, float4(pixelInfo.texCoordsScaled.xy, 0, 0)).rgb, 1.0);
		float3 averageGained = AccentuateWhites(average.rgb);
		float2 pixelDelta;
		if (BlurType == 0)
			pixelDelta = pixelInfo.pixelDelta;
		else
			pixelDelta = CalculatePixelDeltas(pixelInfo.texCoords);
		float maxLuma = dot(AccentuateWhites(float4(tex2Dlod(samplerDownsampledBackBuffer, float4(pixelInfo.texCoordsScaled.xy, 0, 0)).rgb, 1.0).rgb).rgb, lumaDotWeight);
		for(float tapIndex=0.0;tapIndex<pixelInfo.blurLengthInPixels;tapIndex+=(1/BlurQuality))
		{
			float2 tapCoords = (pixelInfo.texCoords + (pixelDelta * tapIndex));
			float3 tapColor = tex2Dlod(samplerDownsampledBackBuffer, float4(tapCoords * ScaleFactor, 0, 0)).rgb;
			float weight;
			if (ReShade::GetLinearizedDepth(tapCoords) <= pixelInfo.focusPlane)
				weight = 0.0;
			else
				weight = 1-(tapIndex/ pixelInfo.blurLengthInPixels);
			average.rgb+=(tapColor * weight);
			average.a+=weight;
			float3 gainedTap = AccentuateWhites(tapColor.rgb);
			averageGained += gainedTap * weight;
			if (weight > 0)
				maxLuma = max(maxLuma, saturate(dot(gainedTap, lumaDotWeight)));
		}
		fragment.rgb = average.rgb / (average.a + (average.a==0));
		if (BlurType != 0)
			fragment.rgb = lerp(fragment.rgb, lerp(FocusPointBlendColor, fragment.rgb, smoothstep(0, 1, distanceToFocusPoint)), FocusPointBlendFactor);
		fragment.rgb = lerp(color, PostProcessBlurredFragment(fragment.rgb, saturate(maxLuma), (averageGained / (average.a + (average.a==0))), HighlightGain), BlendFactor);
		fragment.a = 1.0;
	}


	void PS_Combiner(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		const float colorDepth = ReShade::GetLinearizedDepth(pixelInfo.texCoords);
		float4 realColor = tex2Dlod(ReShade::BackBuffer, float4(pixelInfo.texCoords, 0, 0));
		float filterCircleValue = tex2Dlod(samplerFilterCircle, float4(pixelInfo.texCoords, 0, 0)).r;
		if(colorDepth <= pixelInfo.focusPlane || (BlurLength <= 0.0))
			return;
		}
		const float rangeEnd = (pixelInfo.focusPlane+pixelInfo.focusRange);
		float blendFactor = rangeEnd < colorDepth 
								? 1.0 
								: smoothstep(0, 1, 1-((rangeEnd-colorDepth) / pixelInfo.focusRange));
		if(BlurType==1)
		{
			blendFactor *= filterCircleValue;
		}
		fragment.rgb = lerp(realColor.rgb, tex2Dlod(samplerBlurDestination, float4(pixelInfo.texCoords, 0, 0)).rgb, blendFactor);
		if(FocusPointViewFilterCircleOnMouseDown && LeftMouseDown && BlurType==1)
		{
			fragment.rgb = lerp(fragment.rgb, float3(1.0f, 1.0f, 1.0f), filterCircleValue * 0.7f);
		}
	}
	
	void PS_DownSample(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		// pixelInfo.texCoordsScaled.xy is for scaled down UV, pixelInfo.texCoordsScaled.zw is for scaled up UV
		const float2 sourceCoords = pixelInfo.texCoordsScaled.zw;
		if(max(sourceCoords.x, sourceCoords.y) > 1.0001)
		{
			// source pixel is outside the frame
			discard;
		}
		fragment = tex2D(ReShade::BackBuffer, sourceCoords);
	}
	
	
	void PS_CreateFilterCircle(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float fragment : SV_Target0)
	{
		fragment = 0.0f;
		if(BlurType==1)
		{
			// calculate the rotation matrix for rotating the circle
			float2 sincosFactor = float2(0,0);
			sincos(2.0 * PI * FilterCircleRotationFactor, sincosFactor.x, sincosFactor.y);
			float2x2 rotationMatrix = float2x2(sincosFactor.y, sincosFactor.x, -sincosFactor.x, sincosFactor.y);
		
			// apply deform factors to the texcoord
			// rotate the texcoord with the matrix we constructed so a pixel which normally wouldn't end up in the filter circle will potentially do now
			// so we rotate the frame instead of the circle (as we do cheap deformation with a single vector)
			float2 texcoordCenterNormalized = mul((texcoord - 0.5), rotationMatrix) * FilterCircleDeformFactors;
			float2 focusPointCenterNormalized = FocusPoint - 0.5;
			float texcoordDistance = distance(texcoordCenterNormalized, focusPointCenterNormalized);
			// if the distance is larger than the filter circle radius, blur is always done. If it's smaller, we have to
			// take into account the feather width. So radius-feather is the feather band
			float featherRadius = FilterCircleRadius - (FilterCircleRadius * FilterCircleFeather); 
			if(texcoordDistance < featherRadius)
			{
				// inside the feather band start, so always transparent
				fragment = 0.0f;
			}
			else
			{
				if(texcoordDistance > FilterCircleRadius)
				{
					// outside the filter circle
					fragment = 1.0f;
				}
				else
				{
					// within the featherband
					float featherbandWidth = FilterCircleRadius - featherRadius;
					fragment = lerp(0.0f, 1.0f, (texcoordDistance - featherRadius) / (featherbandWidth + (featherbandWidth==0)));
				}
			}
		}
	}
	
	//////////////////////////////////////////////////
	//
	// Techniques
	//
	//////////////////////////////////////////////////

	technique DirectionalDepthBlur
	< ui_tooltip = "Directional Depth Blur "
			DIRECTIONAL_DEPTH_BLUR_VERSION
			"\n===========================================\n\n"
			"Directional Depth Blur is a shader for adding far plane directional blur\n"
			"based on the depth of each pixel\n\n"
			"Directional Depth Blur was written by Frans 'Otis_Inf' Bouma and is part of OtisFX\n"
			"https://fransbouma.com | https://github.com/FransBouma/OtisFX"; >
	{
		pass CreateFilterCircle { VertexShader = PostProcessVS; PixelShader = PS_CreateFilterCircle; RenderTarget = texFilterCircle; }
		pass Downsample { VertexShader = VS_PixelInfo ; PixelShader = PS_DownSample; RenderTarget = texDownsampledBackBuffer; }
		pass BlurPass { VertexShader = VS_PixelInfo; PixelShader = PS_Blur; RenderTarget = texBlurDestination; }
		pass Combiner { VertexShader = VS_PixelInfo; PixelShader = PS_Combiner; }
	}
}
