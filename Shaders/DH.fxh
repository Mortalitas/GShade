#pragma once


#define RES_WIDTH_DH BUFFER_WIDTH
#define RES_HEIGHT_DH BUFFER_HEIGHT

#define BUFFER_SIZE_DH int2(RES_WIDTH_DH, RES_HEIGHT_DH)
#define BUFFER_SIZE3_DH int3(RES_WIDTH_DH, RES_HEIGHT_DH, RESHADE_DEPTH_LINEARIZATION_FAR_PLANE)
#define min3_DH(v) min(min(v.x, v.y), v.z)
#define max3_DH(v) max(max(v.x, v.y), v.z)
#define mean3_DH(v) ((v.x + v.y + v.z) / 3)
#define pow2_DH(x) (x * x)
#define diff3_DH(v1, v2) any(v1.xyz - v2.xyz)

#define getTex2D_DH(s, c) tex2Dlod(s, float4(c, 0, 0))
#define getTex2Dlod_DH(s, c, l) tex2Dlod(s,float4(c, 0, l))
#define getColor_DH(c) tex2D(ReShade::BackBuffer, c)
#define getColorLod_DH(c, l) tex2D(colorSampler, c, l)
#define getDepth_DH(c) ReShade::GetLinearizedDepth(c)

namespace DH
{

//////// COLOR SPACE
	float RGBCVtoHUE(in float3 RGB, in float C, in float V) {
	    float3 Delta = (V - RGB) / C;
	    Delta.rgb -= Delta.brg;
	    Delta.rgb += float3(2, 4, 6);
	    Delta.brg = step(V, RGB) * Delta.brg;
	    return max(Delta.r, max(Delta.g, Delta.b)) / 6;
	}

	float3 RGBtoHSL(in float3 RGB) {
	    float3 HSL = 0;
	    const float U = -min(RGB.r, min(RGB.g, RGB.b));
	    const float V = max(RGB.r, max(RGB.g, RGB.b));
	    HSL.z = ((V - U) * 0.5);
	    const float C = V + U;
	    if (C != 0)
	    {
	      	HSL.x = RGBCVtoHUE(RGB, C, V);
	      	HSL.y = C / (1 - abs(2 * HSL.z - 1));
	    }
	    return HSL;
	}
	  
	float3 HUEtoRGB(in float H) 
	{
		return saturate(float3(abs(H * 6 - 3) - 1, 2 - abs(H * 6 - 2), 2 - abs(H * 6 - 4)));
	}
	  
	float3 HSLtoRGB(in float3 HSL)
	{
	    return (HUEtoRGB(HSL.x) - 0.5) * ((1 - abs(2 * HSL.z - 1)) * HSL.y) + HSL.z;
	}


//////// DISTANCES

	float distance2(float2 p1, float2 p2) {
		const float2 diff = p1 - p2;
		return dot(diff, diff);
	}
	
	float distance2(float3 p1, float3 p2) {
		const float3 diff = p1 - p2;
		return dot(diff, diff);
	}

//////// COORDS

	float2 getPixelSize() {
		return 1.0 / BUFFER_SIZE_DH;
	} 

	float3 getWorldPosition(float2 coords, float depth, int3 bufferSize) {
		return float3((coords - 0.5) * depth, depth) * bufferSize;
	}
	
	float3 getWorldPosition(float3 coords, int3 bufferSize) {
		return getWorldPosition(coords.xy, coords.z, bufferSize);
	}
	
	float3 getWorldPosition(float2 coords, float depth) {
		return getWorldPosition(coords, depth, int3(BUFFER_WIDTH, BUFFER_HEIGHT, RESHADE_DEPTH_LINEARIZATION_FAR_PLANE));
	}
	
	float3 getWorldPosition(float3 coords) {
		return getWorldPosition(coords.xy, coords.z, int3(BUFFER_WIDTH, BUFFER_HEIGHT, RESHADE_DEPTH_LINEARIZATION_FAR_PLANE));
	}
	
	float3 getWorldPosition(float2 coords, int3 bufferSize) {
		return getWorldPosition(coords, getDepth_DH(coords), bufferSize);
	}
	
	float3 getWorldPosition(float2 coords) {
		return getWorldPosition(getDepth_DH(coords), getDepth_DH(coords));
	}
	
	float2 getScreenPosition(float3 wp,int3 bufferSize) {
		float3 result = wp / bufferSize;
		result /= result.z;
		return result.xy + 0.5;
	}

//////// NORMALS
	float3 computeNormal(float2 coords, int3 samplerSize)
	{
		const float3 offset = float3(ReShade::PixelSize.xy, 0.0) / 10;
		
		const float3 posCenter = getWorldPosition(coords,samplerSize);
		const float3 posNorth  = getWorldPosition(coords - offset.zy,samplerSize);
		const float3 posEast   = getWorldPosition(coords + offset.xz,samplerSize);
		return float3((coords - 0.5) / 6.0, 0.5) + normalize(cross(posCenter - posNorth, posCenter - posEast));
	}

	void saveNormal(out float4 outNormal,float3 normal) {
		outNormal = float4(normal / 2.0 + 0.5, 1.0);
	}

	float3 loadNormal(sampler s, float2 coords) {
		return (tex2Dlod(s, float4(coords, 0.0, 0.0)).xyz - 0.5) * 2.0;
	}
}
