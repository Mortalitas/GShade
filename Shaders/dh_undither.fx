////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_Undither
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

#define getColor(s,c) tex2Dlod(s,float4(c,0,0))

namespace DH {

//// uniform

	uniform int iPS <
		ui_label = "Pixel size";
		ui_type = "slider";
	    ui_min = 1;
	    ui_max = 4;
	    ui_step = 1;
	> = 1;

	uniform int iRadius <
		ui_label = "Radius";
		ui_type = "slider";
	    ui_min = 1;
	    ui_max = 10;
	    ui_step = 1;
	> = 3;
	
	uniform bool bKeepHue <
		ui_label = "Keep source hue";
	> = false;
	
	uniform float fHueMaxDistance <
		ui_label = "Hue Max Distance";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.01;
	> = 0.2;

	uniform float fSatMaxDistance <
		ui_label = "Sat Max Distance";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.01;
	> = 0.35;

	uniform float fLumMaxDistance <
		ui_label = "Lum Max Distance";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.01;
	> = 0.20;



//// textures

//// Functions

//////// COLOR SPACE
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

	float hueDistance(float3 hsl1,float3 hsl2) {
		float minH;
		float maxH;
		if(hsl1.x==hsl2.x) {
			return 0;
		}
		if(hsl1.x<hsl2.x) {
			minH = hsl1.x;
			maxH = hsl2.x;
		} else {
			minH = hsl1.x;
			maxH = hsl2.x;
		}

		return 2*min(maxH-minH,1+minH-maxH);
	}	


//// PS

	void PS_undither(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outPixel : SV_Target)
	{
		float3 rgb = getColor(ReShade::BackBuffer,coords).rgb;
		float3 hsl = RGBtoHSL(rgb);

		float maxDist = iRadius*iRadius;
		float2 pixelSize = ReShade::PixelSize;

		float2 minCoords = saturate(coords-iRadius*pixelSize);
		float2 maxCoords = saturate(coords+iRadius*pixelSize);

		float2 currentCoords;

		//float3 sumHsl;
		float3 sumRgb;
		float sumWeight;

		for(currentCoords.x=minCoords.x;currentCoords.x<=maxCoords.x;currentCoords.x+=pixelSize.x) {
			for(currentCoords.y=minCoords.y;currentCoords.y<=maxCoords.y;currentCoords.y+=pixelSize.y) {
				int2 delta = (currentCoords-coords)/pixelSize;
				float posDist = dot(delta,delta);

				if(posDist>maxDist) {
					continue;
				}

				
				float3 currentRgb = getColor(ReShade::BackBuffer,currentCoords).xyz;
				float3 currentHsl = RGBtoHSL(currentRgb);

				float satDist = abs(hsl.y-currentHsl.y);
				if(satDist>fSatMaxDistance) {
					continue;
				}
				
				float lumDist = abs(hsl.z-currentHsl.z);
				if(lumDist>fLumMaxDistance) {
					continue;
				}

				float hueDist = hueDistance(hsl,currentHsl);
				if(hueDist>fHueMaxDistance) {
					continue;
				}

				float weight = (1-hueDist)+(1-satDist)+(1-lumDist)+(1+maxDist-posDist)/(maxDist+1);
				//float weight = (1+maxDist-posDist)/(maxDist+1);
				sumWeight += weight;
				sumRgb += weight*currentRgb;
			}
		}

		float3 resultRgb = sumRgb/sumWeight;
		if(bKeepHue) {
			float3 resultHsl = RGBtoHSL(resultRgb);
			resultHsl.x = hsl.x;
			resultRgb = HSLtoRGB(resultHsl);
		}
		outPixel = float4(resultRgb,1.0);	
	}


//// Techniques

	technique DH_undither <
	>
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_undither;
		}

	}

}