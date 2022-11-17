////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Height Fog shader to create a volumetric plane with fog in a 3D scene
// By Marty McFly and Otis_Inf
// (c) 2022 All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// This shader has been released under the following license:
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
// Additional Credits:
// Plane intersection code by Inigo 'Iq' Quilez: https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
// 
////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Version history:
// 17-nov-2022:		Added filter circle support so you can define an area where the fog should appear
// 12-sep-2022:		Added opacity max, max blending based on fog texture and evenly distributed fog.
// 17-apr-2022: 	Removed HDR blending as it results in fog that's too dark.
// 29-mar-2022: 	Fixed Fog start, it now works as intended, and added smoothing to the fog so it doesn't create hard edges anymore around geometry. 
//                  Overall it looks better now.
// 25-mar-2022: 	Added vertical/horizontal cloud control and wider range so more cloud details are possible
//                  Added blending in HDR
// 22-mar-2022: 	First release
////////////////////////////////////////////////////////////////////////////////////////////////////

#include "Reshade.fxh"

namespace Heightfog
{
	#define HEIGHT_FOG_VERSION  "1.0.5"

// uncomment the line below to enable debug mode
//#define HF_DEBUG 1

	uniform float3 FogColor <
		ui_category = "General";
		ui_label = "Fog color";
		ui_type = "color";
	> = float3(0.8, 0.8, 0.8);
	
	uniform float FogDensity <
		ui_category = "General";
		ui_type = "slider";
		ui_label = "Fog density";
		ui_min = 0.000; ui_max=1.000;
		ui_step = 0.001;
		ui_tooltip = "Controls how thick the fog is at its thickest point";
	> = 1.0;
	
	uniform float OveralFogDensityMax <
		ui_type = "drag";
		ui_label = "Overall fog density maximum";
		ui_min = 0.0; ui_max=1.0;
		ui_step = 0.01;
		ui_category = "General";
	> = 1.0;

	uniform float FogStart <
		ui_category = "General";
		ui_label = "Fog start";
		ui_type = "slider";
		ui_min = 0.0; ui_max=1.000;
		ui_tooltip = "Controls where the fog starts, relative to the camera";
		ui_step = 0.001;
	> = 0;

	uniform float FogCurve <
		ui_category = "General";
		ui_type = "slider";
		ui_label = "Fog curve";
		ui_min = 0.001; ui_max=1000.00;
		ui_tooltip = "Controls how quickly the fog gets thicker";
		ui_step = 0.1;
	> = 25;

	uniform float FoV <
		ui_category = "General";
		ui_type = "slider";
		ui_label = "FoV (degrees)";
		ui_tooltip = "The Field of View of the scene, for being able to correctly place the fog in the scene";
		ui_min = 10; ui_max=140;
		ui_step = 0.1;
	> = 60;

	uniform float2 PlaneOrientation <
		ui_category = "General";
		ui_type = "slider";
		ui_label = "Fog plane orientation";
		ui_tooltip = "Rotates the fog plane to match the scene.\nFirst value is roll, second value is up/down";
		ui_min = -2; ui_max=2;
		ui_step = 0.001;
	> = float2(1.751, -0.464);

	uniform float PlaneZ <
		ui_category = "General";
		ui_type = "slider";
		ui_label = "Fog plane Z";
		ui_tooltip = "Moves the fog plane up/down. Negative values are moving the plane downwards";
		ui_min = -2; ui_max=2;
		ui_step = 0.001;
	> = -0.001;

	uniform bool EvenlyDistributeFog <
		ui_category = "General";
		ui_label = "Fog is evenly distributed";
		ui_tooltip = "If checked it'll evenly distribute fog so fog close by is as thick as further away.";
	> = false;
	
	uniform bool MovingFog <
		ui_label = "Moving fog";
		ui_tooltip = "Controls whether the fog clouds are static or moving across the plane";
		ui_category = "Cloud configuration";
	> = false;

	uniform float MovementSpeed <
		ui_type = "slider";
		ui_label = "Cloud movement speed";
		ui_tooltip = "Configures the speed the clouds move. 0.0 is no movement, 1.0 is max speed";
		ui_min = 0; ui_max=1;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = 0.4;
	
	uniform float FogCloudScaleMax <
		ui_type = "drag";
		ui_label = "Cloud scale (Max)";
		ui_tooltip = "Configures the cloud size of the fog, used for max values";
		ui_min = 0.0; ui_max=20;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = 1.0;

	uniform float FogCloudScaleVertical <
		ui_type = "slider";
		ui_label = "Cloud scale (vertical)";
		ui_tooltip = "Configures the cloud size of the fog, vertically";
		ui_min = 0.0; ui_max=20;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = 1.0;
	
	uniform float FogCloudScaleHorizontal <
		ui_type = "slider";
		ui_label = "Cloud scale (horizotal)";
		ui_tooltip = "Configures the cloud size of the fog, horizontally";
		ui_min = 0.0; ui_max=10;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = 1.0;

	uniform float FogCloudFactor <
		ui_type = "slider";
		ui_label = "Cloud factor";
		ui_tooltip = "Configures the amount of cloud forming in the fog.\n1.0 means full clouds, 0.0 means no clouds";
		ui_min = 0; ui_max=1;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = 1.0;
	
	uniform float2 FogCloudOffset <
		ui_type = "slider";
		ui_label = "Cloud offset";
		ui_tooltip = "Configures the offset in the cloud texture of the fog.\nUse this instead of Moving fog to control the cloud position";
		ui_min = 0.0; ui_max=1;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = float2(0.0, 0.0);

	uniform float2 FogMaxOffset <
		ui_type = "drag";
		ui_label = "Max offsets";
		ui_tooltip = "Configures the offset in the cloud texture of the fog.\nUse this instead of Moving fog to control the cloud position";
		ui_min = 0.0; ui_max=1;
		ui_step = 0.01;
		ui_category = "Cloud configuration";
	> = float2(0.0, 0.0);
	
	uniform bool UseFilterCircle <
		ui_category = "Filter circle edge filtering";
		ui_tooltip = "Controls whether the edge filter is active or not";
	> = false;
	uniform bool FocusPointViewFilterCircleOnMouseDown <
		ui_category = "Filter circle edge filtering";
		ui_label = "Show filter circle on mouse down";
		ui_tooltip = "If checked, an overlay is shown with the current filter circle.\Red means no fog will be present,\ntransparent means fog will be present";
	> = false;
	uniform float2 FilterCircleCenterPoint <
		ui_category = "Filter circle edge filtering";
		ui_label = "Center point";
		ui_type = "drag";
		ui_step = 0.001;
		ui_min = 0.000; ui_max = 1.000;
		ui_tooltip = "The X and Y coordinates of the filter circle center\n0,0 is the upper left corner, and 0.5, 0.5 is at the center of the screen.";
	> = float2(0.5, 0.5);
	uniform float FilterCircleRadius <
		ui_category = "Filter circle edge filtering";
		ui_label = "Radius";
		ui_type = "drag";
		ui_min = 0.000; ui_max = 2.000;
		ui_step = 0.001;
		ui_tooltip = "The radius of the filter circle.\nAll points outside this circle are not or only partially fogged";
	> = 0.1;
	uniform float2 FilterCircleDeformFactors <
		ui_category = "Filter circle edge filtering";
		ui_label = "Deform factors";
		ui_type = "drag";
		ui_min = 0.000; ui_max = 2.000;
		ui_step = 0.001;
		ui_tooltip = "The radius factors for width and height of the filter circle.\n1.0 means no deformation, another value means deformation in that direction";
	> = float2(1.0, 1.0);
	uniform float FilterCircleRotationFactor <
		ui_category = "Filter circle edge filtering";
		ui_label = "Rotation factor";
		ui_type = "drag";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The rotation factor of the filter circle";
	> = 0.0;
	uniform float FilterCircleFeather <
		ui_category = "Filter circle edge filtering";
		ui_label = "Feather";
		ui_type = "drag";
		ui_min = 0.000; ui_max = 1.000;
		ui_step = 0.001;
		ui_tooltip = "The feather area within the filter circle.\n1.0 means the whole inner area is feathered,\n0.0 means no feather area.";
	> = 0.1;

#ifdef HF_DEBUG
	uniform bool DBVal1 <
		ui_label = "DBVal1";
		ui_category = "Debug";
	> = false;
	uniform bool DBVal2 <
		ui_label = "DBVal2";
		ui_category = "Debug";
	> = false;
	uniform float DBVal3f <
		ui_type = "slider";
		ui_label = "DBVal3f";
		ui_min = 1.0; ui_max=10;
		ui_step = 0.01;
		ui_category = "Debug";
	> = 1.0;
	uniform float DBVal4f <
		ui_type = "drag";
		ui_label = "DBVal4f";
		ui_min = 0.0; ui_max=100.0;
		ui_step = 0.01;
		ui_category = "Debug";
	> = 1.0;
#endif

	uniform float timer < source = "timer"; >; // Time in milliseconds it took for the last frame 
	uniform bool LeftMouseDown < source = "mousebutton"; keycode = 0; toggle = false; >;
	
#ifndef M_PI
	#define M_PI 3.1415927
#endif

#ifndef M_2PI
	#define M_2PI 6.283185
#endif

	#define PITCH_MULTIPLIER		1.751
	#define YAW_MULTIPLIER			-0.464
	#define BUFFER_ASPECT_RATIO2     float2(1.0, BUFFER_WIDTH * BUFFER_RCP_HEIGHT)

	texture texFogNoise				< source = "fognoise.jpg"; > { Width = 512; Height = 512; Format = RGBA8; };
	texture texFilterCircle { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };

	sampler SamplerFogNoise				{ Texture = texFogNoise; AddressU = WRAP; AddressV = WRAP; AddressW = WRAP;};
	sampler samplerFilterCircle { Texture = texFilterCircle; };
		
	struct VSPIXELINFO
	{
		float4 vpos : SV_Position;
		float2 texCoords : TEXCOORD0;
		float2x2 rotationMatrix: TEXCOORD6;
		float2 centerDisplacementDelta: TEXCOORD8;
		float featherRadius: TEXCOORD9;
	};
	
	//////////////////////////////////////////////////
	//
	// Functions
	//
	//////////////////////////////////////////////////
	
	float3 uvToProj(float2 uv, float z)
	{
		//optimized math to simplify matrix mul
		const float3 uvtoprojADD = float3(-tan(radians(FoV) * 0.5).xx, 1.0) * BUFFER_ASPECT_RATIO2.yxx;
		const float3 uvtoprojMUL = float3(-2.0 * uvtoprojADD.xy, 0.0);

		return (uv.xyx * uvtoprojMUL + uvtoprojADD) * z;
	}


	// from iq
	float planeIntersect(float3 ro, float3 rd, float4 p)
	{
		return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
	}
	
	//////////////////////////////////////////////////
	//
	// Vertex Shaders
	//
	//////////////////////////////////////////////////
	
	VSPIXELINFO VS_PixelInfo(in uint id : SV_VertexID)
	{
		VSPIXELINFO pixelInfo;
		
		pixelInfo.texCoords.x = (id == 2) ? 2.0 : 0.0;
		pixelInfo.texCoords.y = (id == 1) ? 2.0 : 0.0;
		pixelInfo.vpos = float4(pixelInfo.texCoords * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
		// rotation matrix for focus point filter circle rotation
		float2 sincosFactor = float2(0,0);
		sincos(6.28318530717958 * FilterCircleRotationFactor, sincosFactor.x, sincosFactor.y);
		pixelInfo.rotationMatrix = float2x2(sincosFactor.y, sincosFactor.x, -sincosFactor.x, sincosFactor.y);
		// displacement delta for focus point to properly apply deformation
		pixelInfo.centerDisplacementDelta = FilterCircleCenterPoint - float2(0.5, 0.5);
		pixelInfo.featherRadius = FilterCircleRadius - (FilterCircleRadius * FilterCircleFeather); 
		return pixelInfo;
	}
	
	//////////////////////////////////////////////////
	//
	// PIXEL Shaders
	//
	//////////////////////////////////////////////////
	
	void PS_FogIt(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		float4 originalFragment = tex2D(ReShade::BackBuffer, pixelInfo.texCoords);
		float depth = lerp(1.0, 1000.0, ReShade::GetLinearizedDepth(pixelInfo.texCoords))/1000.0;
		float phi = PlaneOrientation.x * M_2PI; //I can never tell longitude and latitude apart... let's use wikipedia definitions
		float theta = PlaneOrientation.y * M_PI;

		float3 planeNormal;
		planeNormal.x = cos(phi)*sin(theta);
		planeNormal.y = sin(phi)*sin(theta);
		planeNormal.z = cos(theta);
		planeNormal = normalize(planeNormal); //for sanity

		float4 iqplane = float4(planeNormal, PlaneZ);	//anchor point is _apparently_ ray dir * this length in IQ formula
		float3 scenePosition = uvToProj(pixelInfo.texCoords, depth); 
		float sceneDistance = length(scenePosition); //actually length(position - camera) but as camera is 0 0 0, it's just length(position)
		float3 rayDirection = scenePosition / sceneDistance; //normalize(scenePosition)

		//camera at 0 0 0, so we pass 0.0 for ray origin (the first argument)
		float distanceToIntersect = planeIntersect(0, rayDirection, iqplane); //produces negative numbers if looking away from camera - makes sense as if you look away, you need to go _backwards_ i.e. in negative view direction
		float speedFactor = 100000.0 * (1-(MovementSpeed-0.01));
		float fogTextureValueHorizontally = tex2D(SamplerFogNoise, (pixelInfo.texCoords + FogCloudOffset) * FogCloudScaleHorizontal + (MovingFog ? frac(timer / speedFactor) : 0.0)).r;
		float fogTextureValueVertically = tex2D(SamplerFogNoise, (pixelInfo.texCoords + FogCloudOffset) * FogCloudScaleVertical + (MovingFog ? frac(timer / speedFactor) : 0.0)).r;
		float fogMaxValue = tex2D(SamplerFogNoise, (pixelInfo.texCoords + FogMaxOffset) * FogCloudScaleMax + (MovingFog ? frac(timer / speedFactor) : 0.0)).r;
		
		distanceToIntersect = distanceToIntersect < 0 ? 10000000 : distanceToIntersect; //if negative, we didn't hit it, so set hit distance to infinity
		distanceToIntersect *= lerp(1.0, fogTextureValueVertically, FogCloudFactor);
		float distanceTraveled = (depth - distanceToIntersect);
		distanceTraveled = saturate(distanceTraveled-saturate(0.5 * (FogStart - distanceToIntersect)));
		distanceTraveled = EvenlyDistributeFog ? distanceTraveled / 50.0f : (distanceTraveled * distanceTraveled);
		distanceTraveled *= fogMaxValue;
		float filterCircleValue = UseFilterCircle ? tex2Dlod(samplerFilterCircle, float4(pixelInfo.texCoords, 0, 0)).r : 0.0f;
		float lerpFactor = saturate(distanceTraveled * 10.0 * FogCurve * FogDensity * lerp(1.0, fogTextureValueHorizontally, FogCloudFactor)) * OveralFogDensityMax * saturate(1-filterCircleValue);
		fragment.rgb = sceneDistance < distanceToIntersect ? originalFragment.rgb 
														   : lerp(originalFragment.rgb, FogColor.rgb, lerpFactor);
		fragment.a = 1.0;
		
		if(FocusPointViewFilterCircleOnMouseDown && LeftMouseDown)
		{
			fragment.rgb = lerp(fragment.rgb, float3(1.0f, 0.0f, 0.0f), filterCircleValue * 0.7f);
		}
	}
	
		
	
	void PS_CreateFilterCircle(VSPIXELINFO pixelInfo, out float4 fragment : SV_Target0)
	{
		fragment = 0.0f;
		// apply deform factors to the texcoord
		// rotate the texcoord with the matrix we constructed so a pixel which normally wouldn't end up in the filter circle will potentially do now
		// so we rotate the frame instead of the circle (as we do cheap deformation with a single vector)
		float2 texcoordCenterNormalized = mul(((pixelInfo.texCoords-pixelInfo.centerDisplacementDelta) - 0.5), pixelInfo.rotationMatrix) * FilterCircleDeformFactors;
		float2 focusPointCenterNormalized = (FilterCircleCenterPoint-pixelInfo.centerDisplacementDelta) - 0.5;
		float texcoordDistance = distance(texcoordCenterNormalized, focusPointCenterNormalized);
		// if the distance is larger than the filter circle radius, blur is always done. If it's smaller, we have to
		// take into account the feather width. So radius-feather is the feather band
		if(texcoordDistance < pixelInfo.featherRadius)
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
				float featherbandWidth = FilterCircleRadius - pixelInfo.featherRadius;
				fragment = lerp(0.0f, 1.0f, (texcoordDistance - pixelInfo.featherRadius) / (featherbandWidth + (featherbandWidth==0)));
			}
		}
	}
	
	technique HeightFog
#if __RESHADE__ >= 40000
	< ui_tooltip = "Height Fog "
			HEIGHT_FOG_VERSION
			"\n===========================================\n\n"
			"Height Fog shader to introduce a volumetric fog plane into a 3D scene,\n"
			"Height Fog was written by Marty McFly and Otis_Inf"; >
#endif
	{
		pass CreateFilterCircle { VertexShader = VS_PixelInfo; PixelShader = PS_CreateFilterCircle; RenderTarget = texFilterCircle; }
		pass ApplyFog { VertexShader = VS_PixelInfo; PixelShader = PS_FogIt; }
	}
}
