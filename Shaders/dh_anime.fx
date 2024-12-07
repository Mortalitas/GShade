////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_Anime
//
// This shader is free, if you paid for it, you have been ripped and should ask for a refund.
//
// This shader is developed by AlucardDH (Damien Hembert)
//
// Get more here : https://alucarddh.github.io
// Join my Discord server for news, request, bug reports or help : https://discord.gg/V9HgyBRgMW
//
// License: GNU GPL-2.0
//
////////////////////////////////////////////////////////////////////////////////////////////////
#include "ReShade.fxh"

#define NOISE_SIZE 32
#define BUFFER_SIZE int2(BUFFER_WIDTH,BUFFER_HEIGHT)
#define getColor(c) tex2Dlod(ReShade::BackBuffer,float4(c,0.0,0.0))
#define getBlur(c) tex2Dlod(blurSampler,float4(c,0.0,0.0))
#define getDepth(c) ReShade::GetLinearizedDepth(c)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
#define diff3t(v1,v2,t) (abs(v1.x-v2.x)>t || abs(v1.y-v2.y)>t || abs(v1.z-v2.z)>t)
#define maxOf3(a) max(max(a.x,a.y),a.z)

namespace DHAnime11 {

	texture blueNoiseTex < source ="dh_rt_noise.png" ; > { Width = NOISE_SIZE; Height = NOISE_SIZE; MipLevels = 1; Format = RGBA8; };
    sampler blueNoiseSampler { Texture = blueNoiseTex;  AddressU = REPEAT;	AddressV = REPEAT;	AddressW = REPEAT;};


//// uniform
/*
uniform bool bTest = false;
uniform bool bTest2 = false;
uniform float fTest <
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.5;
uniform float fTest2 <
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.5;
*/
	
	
	uniform bool bDepthBlackLine <
	    ui_category = "Black lines";
		ui_label = "Depth based";
	> = true;
	uniform int iDepthBlackLineThickness <
	    ui_category = "Black lines";
		ui_label = "Thickness (depth)";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 16;
	    ui_step = 1;
	> = 3;
	uniform float fDepthBlackLineThreshold <
	    ui_category = "Black lines";
		ui_label = "Threshold (depth)";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.995;

	uniform bool bColorBlackLine <
	    ui_category = "Black lines";
		ui_label = "Color based";
	> = true;
	uniform int iColorBlackLineThickness <
	    ui_category = "Black lines";
		ui_label = "Thickness (color)";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 16;
	    ui_step = 1;
	> = 3;
	uniform float fColorBlackLineThreshold <
	    ui_category = "Black lines";
		ui_label = "Threshold (color)";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.935;
	
	uniform float iSurfaceBlur <
		ui_category = "Colors";
		ui_label = "Surface blur";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 16;
	    ui_step = 1;
	> = 3;
	
	uniform float fSaturation <
		ui_category = "Colors";
		ui_label = "Saturation multiplier";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 5.0;
	    ui_step = 0.01;
	> = 2.0;

	uniform float iShadingSteps <
		ui_category = "Colors";
		ui_label = "Shading steps";
		ui_type = "slider";
	    ui_min = 1;
	    ui_max = 255;
	    ui_step = 1;
	> = 16;
	
	uniform float iShadingRamp <
		ui_category = "Colors";
		ui_label = "Shading Ramp";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 3;
	    ui_step = 1;
	> = 0;
	
	uniform bool bDithering <
	    ui_category = "Colors";
		ui_label = "Dithering";
	> = false;
	
	uniform bool bHueFilter <
	    ui_category = "Hue filter";
		ui_label = "Enabled";
	> = false;
	uniform float fHueFilter <
	    ui_category = "Hue filter";
		ui_label = "Selected hue";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.0;
	uniform float fHueFilterRange <
	    ui_category = "Hue filter";
		ui_label = "Range";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.150;
	

//// textures

	texture normalTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
	sampler normalSampler { Texture = normalTex; };
	
	texture linesTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
	sampler linesSampler { Texture = linesTex; };

	texture blurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
	sampler blurSampler { Texture = blurTex; };

//// Functions

	// Normals

	float3 normal(float2 texcoord)
	{
		float3 offset = float3(ReShade::PixelSize.xy, 0.0);
		float2 posCenter = texcoord.xy;
		float2 posNorth  = posCenter - offset.zy;
		float2 posEast   = posCenter + offset.xz;
	
		float3 vertCenter = float3(posCenter - 0.5, 1) * getDepth(posCenter);
		float3 vertNorth  = float3(posNorth - 0.5,  1) * getDepth(posNorth);
		float3 vertEast   = float3(posEast - 0.5,   1) * getDepth(posEast);
	
		return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast));
	}

	
	void saveNormal(in float3 normal, out float4 outNormal) 
	{
		outNormal = float4(normal*0.5+0.5,1.0);
	}
	
	float3 loadNormal(in float2 coords) {
		return (tex2Dlod(normalSampler,float4(coords,0,0)).xyz-0.5)*2.0;
	}

	// Color space

	float RGBCVtoHUE(in float3 RGB, in float C, in float V) {
	      float3 Delta = (V - RGB) / C;
	      Delta.rgb -= Delta.brg;
	      Delta.rgb += float3(2,4,6);
	      Delta.brg = step(V, RGB) * Delta.brg;
	      float H;
	      H = max(Delta.r, max(Delta.g, Delta.b));
	      return frac(H / 6);
	}

	float3 RGBtoHSL(in float3 RGB) {
	    float3 HSL = 0;
	    float U, V;
	    U = -min(RGB.r, min(RGB.g, RGB.b));
	    V = max(RGB.r, max(RGB.g, RGB.b));
	    HSL.z = ((V - U) * 0.5);
	    float C = V + U;
	    if (C != 0)
	    {
	    	HSL.x = RGBCVtoHUE(RGB, C, V);
	    	HSL.y = C / (1 - abs(2 * HSL.z - 1));
	    }
	    return HSL;
	}
	  
	float3 HUEtoRGB(in float H) 
	{
	    float R = abs(H * 6 - 3) - 1;
	    float G = 2 - abs(H * 6 - 2);
	    float B = 2 - abs(H * 6 - 4);
	    return saturate(float3(R,G,B));
	}
	  
	float3 HSLtoRGB(in float3 HSL)
	{
	    float3 RGB = HUEtoRGB(HSL.x);
	    float C = (1 - abs(2 * HSL.z - 1)) * HSL.y;
	    return (RGB - 0.5) * C + HSL.z;
	}


//// PS

	void PS_Input(float4 vpos : SV_Position, in float2 coords : TEXCOORD0, out float4 outNormal : SV_Target, out float4 outBlur : SV_Target1)
	{
		float3 normal = normal(coords);
		saveNormal(normal,outNormal);
		
		if(iSurfaceBlur>0) {
			float4 sum;
			int count;
			
			int maxDistance = iSurfaceBlur*iSurfaceBlur;
			float depth = getDepth(coords);
			
			int2 delta;
			for(delta.x=-iSurfaceBlur;delta.x<=iSurfaceBlur;delta.x++) {
				for(delta.y=-iSurfaceBlur;delta.y<=iSurfaceBlur;delta.y++) {
					int d = dot(delta,delta);
					if(d<=maxDistance) {
						float2 searchCoords = coords+ReShade::PixelSize*delta;
						float searchDepth = getDepth(searchCoords);
						float dRatio = depth/searchDepth;
						
						if(dRatio>=0.95 && dRatio<=1.05) {
							sum += getColor(searchCoords);
							count++;
						}
					}
				}
			}
			outBlur = sum/count;
		} else {
			outBlur = getColor(coords);
		}
	}
	
	void PS_LinePass(float4 vpos : SV_Position, in float2 coords : TEXCOORD0, out float4 outPixel : SV_Target) {
		if(!bColorBlackLine || iDepthBlackLineThickness<1) discard;
    
    	float refDepth = getDepth(coords);
        float3 refColor = getColor(coords).rgb;
        
        float roughness = 0.0;
        float ws = 0;
            
        float3 previousX = refColor;
        float3 previousY = refColor;
        
        float threshold = 1.0-saturate(fColorBlackLineThreshold);
        [loop]
        for(int d = 1;d<=iColorBlackLineThickness;d++) {
            float w = 1.0/pow(d,0.5);
            
            float3 color = getColor(float2(coords.x+ReShade::PixelSize.x*d,coords.y)).rgb;
            float3 diff = abs(previousX-color);
            roughness += maxOf3(diff)*w>threshold ? 1 : 0;
            ws += w;
            previousX = color;
            
            color = getColor(float2(coords.x,coords.y+ReShade::PixelSize.y*d)).rgb;
            diff = abs(previousY-color);
            roughness += maxOf3(diff)*w>threshold ? 1 : 0;
            ws += w;
            previousY = color;
        }
        
        previousX = refColor;
        previousY = refColor;
        
        [loop]
        for(int d = 1;d<=iColorBlackLineThickness;d++) {
            float w = 1.0/pow(d,0.5);
            
            float3 color = getColor(float2(coords.x-ReShade::PixelSize.x*d,coords.y)).rgb;
            float3 diff = abs(previousX-color);
            roughness += maxOf3(diff)*w>threshold ? 1 : 0;
            ws += w;
            previousX = color;
            
            color = getColor(float2(coords.x,coords.y-ReShade::PixelSize.y*d)).rgb;
            diff = abs(previousY-color);
            roughness += maxOf3(diff)*w>threshold ? 1 : 0;
            ws += w;
            previousY = color;
        }
        
        float refB = maxOf3(refColor);      
        roughness *= pow(refB,0.5);
        roughness *= pow(1.0-refB,2.0);
        
        //roughness *= 0.5+refDepth*2;
        float3 r = 1.0-roughness;
        outPixel = float4(r,1);
    }

	void PS_Result(float4 vpos : SV_Position, in float2 coords : TEXCOORD0, out float4 outPixel : SV_Target)
	{
		float3 color = getBlur(coords).rgb;
		float3 hsl = RGBtoHSL(color);
		
		// black lines depth
		if(bDepthBlackLine && iDepthBlackLineThickness>0) {
			float depthLineMul = 1;
			int maxDistance = iDepthBlackLineThickness*iDepthBlackLineThickness;
			float depth = getDepth(coords);
			float3 normal = loadNormal(coords);
			
			int2 delta;
			for(delta.x=-iDepthBlackLineThickness;depthLineMul>0 && delta.x<=iDepthBlackLineThickness;delta.x++) {
				for(delta.y=-iDepthBlackLineThickness;depthLineMul>0 && delta.y<=iDepthBlackLineThickness;delta.y++) {
					int d = dot(delta,delta);
					if(d<=maxDistance) {
						float2 searchCoords = coords+ReShade::PixelSize*delta;
						float searchDepth = getDepth(searchCoords);
						float3 searchNormal = loadNormal(searchCoords);

						if(depth/searchDepth<=fDepthBlackLineThreshold && diff3t(normal,searchNormal,0.1)) {
							depthLineMul = 0;
						}
					}
				}
			}
			hsl.z *= depthLineMul;
		}

		// black lines color
		if(bColorBlackLine && iDepthBlackLineThickness>0) { 
			float lines = tex2D(linesSampler,coords).r;
			hsl.z *= pow(lines,iDepthBlackLineThickness);
		}
		
		if(iShadingRamp==1) {
			hsl.z = smoothstep(0,1,hsl.z);
		} else if(iShadingRamp==2) {
			hsl.z = sqrt(hsl.z);
		} else if(iShadingRamp==3) {
			hsl.z *= hsl.z;
		}
		
		
		
		// shading steps
		float stepSize = 1.0/iShadingSteps;
		if(bDithering) {
			int2 coordsNoise = int2(coords*BUFFER_SIZE)%NOISE_SIZE;
			float noise = tex2Dfetch(blueNoiseSampler,coordsNoise).r;

			hsl.z = round(((noise-0.7)*0.75+hsl.z)/stepSize)/iShadingSteps;
		} else {
			hsl.z = round(hsl.z/stepSize)/iShadingSteps;
		}

		// saturation
		hsl.y = saturate(hsl.y*fSaturation);
		if(bHueFilter) {
			// fHueFilter
			float hueDist = (fHueFilter<hsl.x
				? min(hsl.x-fHueFilter,1+fHueFilter-hsl.x)
				: min(fHueFilter-hsl.x,1-fHueFilter+hsl.x)
				)*16;
			
			hueDist = smoothstep(0,1,saturate(hueDist));
			
			hsl.y *= 1.0-saturate(hueDist*(1.0-fHueFilterRange));
		} 
		

		color = HSLtoRGB(hsl);

		outPixel = float4(color,1.0);	
	}

//// Techniques

	technique DH_Anime_11 <
        ui_label = "DH_Anime 1.1";
	>
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_Input;
			RenderTarget = normalTex;
			RenderTarget1 = blurTex;
		}
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_LinePass;
			RenderTarget = linesTex;
		}
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_Result;
		}
	}

}