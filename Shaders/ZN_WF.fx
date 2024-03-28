////////////////////////////////////////////////////////
// Wireframe
// Author: Zenteon
// License: GPLv3
// Repository: https://github.com/Zenteon/ZN_FX
////////////////////////////////////////////////////////

#include "ReShade.fxh"



uniform float FRAME_BOOST <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 30.0;
	ui_label = "Sensitivity";
	ui_tooltip = "Enhances small details in the wireframe";
> = 10.0;

uniform float3 FRAME_COLOR <
	ui_label = "Wireframe Color";
	ui_type = "color";
> = float3(0.2, 1.0, 0.0);

uniform bool OVERLAY_MODE <
	ui_label = "Overlay Frame";
	ui_tooltip = "Overlays outline on top of the image";
> = 0;

uniform bool FAST_AFN <
	ui_label = "Normals speed mode";
	ui_tooltip = "Uses less accurate normal approximations to speed up performance";
> = 0;

uniform bool FAST_AFS <
	ui_label = "Sample speed mode";
	ui_tooltip = "Uses less accurate sampling approximations to speed up performance";
> = 0;


texture WFNormalTex {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 3;};


sampler NormalSam { Texture = WFNormalTex;};


float eyeDis(float2 xy, float2 pw)
{
	return ReShade::GetLinearizedDepth(xy);//eyePos(xy, ReShade::GetLinearizedDepth(xy), pw).z;
}


float4 NormalBuffer(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 output;
	
	
	float FarPlane = RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
	float2 aspectPos= float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float2 PW = 0;//2.0 * tan(70.0 * 0.00875) * (FarPlane - 1); //Dimensions of FarPlane
	PW.y *= aspectPos.x / aspectPos.y;
	float2 uvd = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float vc = eyeDis(texcoord, PW);
	
	if(FAST_AFN)
	{
		float vx = vc - eyeDis(texcoord + float2(1, 0) / uvd, PW);
		float vy = vc - eyeDis(texcoord + float2(0, 1) / uvd, PW);
		output = 0.5 + 0.5 * normalize(float3(vx, vy, vc / FarPlane));
	}
	else
	{
		
		
		
		
		 
		float vx;
		float vxl = vc - eyeDis(texcoord + float2(-1, 0) / uvd, PW);	
		float vxl2 = vc - eyeDis(texcoord + float2(-2, 0) / uvd, PW);
		float exlC = lerp(vxl2, vxl, 2.0);
		
		float vxr = vc - eyeDis(texcoord + float2(1, 0) / uvd, PW);
		float vxr2 = vc - eyeDis(texcoord + float2(2, 0) / uvd, PW);
		float exrC = lerp(vxr2, vxr, 2.0);
		
		if(abs(exlC - vc) > abs(exrC - vc)) {vx = -vxl;}
		else {vx = vxr;}
		
		float vy;
		float vyl = vc - eyeDis(texcoord + float2(0, -1) / uvd, PW);
		float vyl2 = vc - eyeDis(texcoord + float2(0, -2) / uvd, PW);
		float eylC = lerp(vyl2, vyl, 2.0);
		
		float vyr = vc - eyeDis(texcoord + float2(0, 1) / uvd, PW);
		float vyr2 = vc - eyeDis(texcoord + float2(0, 2) / uvd, PW);
		float eyrC = lerp(vyr2, vyr, 2.0);
		
		if(abs(eylC - vc) > abs(eyrC - vc)) {vy = -vyl;}
		else {vy = vyr;}
		
		output = float3(0.5 + 0.5 * normalize(float3(vx, vy, vc / FarPlane)));
	}
	return float4(output, 1.0);	
}

float WireFrame(float2 xy)
{
	float output;
	if(FAST_AFS)
	{
		float3 norA = tex2D(NormalSam, xy).xyz;
		float3 norB = tex2Dlod(NormalSam, float4(xy, 0, 1)).xyz;
		norA = abs(norA - norB);
		output = (norA.r + norA.g + norA.b) / 3.0;
	}
	else
	{
		//int gaussianK[9] = {1,2,1,2,4,2,1,2,1};  
		float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	
		float3 norA = tex2D(NormalSam, xy).xyz;
		float3 norB;
		for(int i = 0; i < 2; i++){
			for(int ii = 0; ii < 2; ii++)
			{
				//float g = gaussianK[ii + (i * 3)] / 1;
				float2 p = 0.66667 * float2(i - 0.5, ii - 0.5) / res;
				norB += tex2D(NormalSam, xy + p).xyz;
				
			}}
			norB /= 4.0;
		float3 diff = abs(norA - norB);
		output = (diff.r + diff.g + diff.b) / 3.0;
	}
	return output;
}




float3 ZN_WF_FX(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 bxy = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float bri = saturate(FRAME_BOOST * WireFrame(texcoord));
	if(OVERLAY_MODE == 1){
		input = lerp(input, bri * FRAME_COLOR, bri);
		}
	else {return bri * FRAME_COLOR;}
	
	return input;//OVERLAY_MODE;
}

technique ZN_WireFrame
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalBuffer;
		RenderTarget = WFNormalTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ZN_WF_FX;
	}
}
