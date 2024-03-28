////////////////////////////////////////////////////////
// Screen Space Directional Indirect Lighting
// Author: Zenteon
// License: GPLv3
// Repository: https://github.com/Zenteon/ZN_FX
////////////////////////////////////////////////////////

#include "ReShade.fxh"

#ifndef TOTAL_RAY_LODS
//============================================================================================
	#define TOTAL_RAY_LODS 3 //How many Lods are checked during sampling, moderate impact
//============================================================================================
#endif

	


#define FarPlane RESHADE_DEPTH_LINEARIZATION_FAR_PLANE



uniform float FOV <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 110.0;
	ui_label = "FOV";
	ui_tooltip = "Adjust to match ingame FOV";
	ui_category = "Depth Buffer Settings";
	ui_step = 1;
> = 70;



uniform float NearPlane <
	ui_type = "slider";
	ui_min = 0.05;
	ui_max = 10.0;
	ui_label = "Near Plane";
	ui_tooltip = "Adjust min depth for depth buffer, increase slightly if dark lines are visible";
	ui_category = "Depth Buffer Settings";
> = 0.7;


uniform float Intensity <
	ui_type = "slider";
	ui_min = 0.01;
	ui_max = 1.0;
	ui_label = "Intensity";
	ui_tooltip = "Intensity of the effect";
	ui_category = "Display";
> = 0.25;

uniform int BlendMode <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 1;
	ui_label = "Blend Mode";
	ui_tooltip = "Switch between hybrid and additive blending modes";
	ui_category = "Display";
> = 0;

uniform float AmbientNeg <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 0.5;
	ui_label = "Ambient light offset";
	ui_tooltip = "Removes ambient light before applying GI (Only applies to blend mode 1)";
	ui_category = "Display";
> = 0.1;

uniform float LightEx <
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 2.2;
	ui_label = "LightEx";
	ui_tooltip = "Converts lightmap to linear, lower slightly if you see extra banding when enabling the effect";
	ui_category = "Display";
> = 2.2;

uniform float distMask <
	ui_type = "slider";
	ui_label = "Distance Mask";
	ui_tooltip = "Prevents washing out of clouds, and reduces artifacts from fog";
	ui_category = "Display";
> = 0.0;

uniform bool addR <
	ui_label = "Additive Casting";
	ui_tooltip = "Stacks samples linearly as instead or resetting them\n" 
"Increases ray range and significantly improves shading quality || Moderate Performance impact";
	ui_category = "Sampling";
> = 0;

uniform bool doDenoising <
	ui_label = "Denoising";
	ui_tooltip = "Runs a gaussian denoising pass || Moderate Performance impact"; 
	ui_category = "Sampling";
> = 1;

uniform int sLod <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 2;
	ui_label = "Starting LOD";
	ui_tooltip = "Changes the starting LOD value, increases sample range at the cose of fine details \n"
"Aliasing artifacts can be very noticable || Moderate Performance impact";
	ui_category = "Sampling";
> = 0;


uniform float LigM <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 1.0;
	ui_label = "Brightness power";
	ui_tooltip = "Exponent of light sources. Recommended to decrease when increasing 'Ray Range'|| No Performance impact";
	ui_category = "Sampling";
> = 1.0;

uniform float disD <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 2.0;
	ui_label = "Distance Power";
	ui_tooltip = "Modifies the laws of physics, 2 is physically accurate || No Performance impact";
	ui_category = "Sampling";
> = 2.0;

uniform float disM <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 1.0;
	ui_label = "Distance Scale";
	ui_tooltip = "Scale of the world distance calculations are made";
	ui_category = "Sampling";
> = 0.25;

uniform float sampR <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 20.0;
	ui_label = "Ray Range";
	ui_tooltip = "Increases GI range without detail loss, may create noise at higher levels || Low Performance impact";
	ui_category = "Sampling";
> = 7.0;

uniform bool debug <
	ui_label = "Debug";
	ui_tooltip = "Displays GI";
> = 0;


//============================================================================================
//Textures and samplers
//============================================================================================
texture GIBlueNoiseTex < source = "ZNbluenoise512.png"; >
{
	Width  = 512.0;
	Height = 512.0;
	Format = RGBA8;
};
texture GINorTex{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 1;};
texture GIBufTex{Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = R16; MipLevels = 7;};
texture GILumTex{Width = BUFFER_WIDTH / 4; Height = BUFFER_HEIGHT / 4; Format = RGBA8; MipLevels = 6;};
texture GIHalfTex{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 2;};
texture GIBlurTex1{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 2;};



sampler NormalSam{Texture = GINorTex;};
sampler BufferSam{Texture = GIBufTex;};
sampler LightSam{Texture = GILumTex;};
sampler NoiseSam{Texture = GIBlueNoiseTex;};
sampler HalfSam{Texture = GIHalfTex;};
sampler BlurSam1{Texture = GIBlurTex1;};

//============================================================================================
//Buffer Definitions
//============================================================================================

//Saves LightMap and LODS
float4 LightMap(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float p = LightEx;
	float3 te = tex2D(ReShade::BackBuffer, texcoord).rgb;
	return float4(pow(te, p), 1.0);
}

//Saves DepthBuffer and LODS
float LinearBuffer(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float f = FarPlane;
	float n = NearPlane;
	float depth = ReShade::GetLinearizedDepth(texcoord);
	depth = lerp(n, f, depth);
	return depth / (f - n);
}

//Generates Normal Buffer from depth
float4 NormalBuffer(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 uvd = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float vc =  ReShade::GetLinearizedDepth(texcoord);
	 
	float vx;
	float vxl = vc - ReShade::GetLinearizedDepth(texcoord + float2(-1, 0) / uvd);	
	float vxl2 = vc - ReShade::GetLinearizedDepth(texcoord + float2(-2, 0) / uvd);
	float exlC = lerp(vxl2, vxl, 2.0);
	
	float vxr = vc - ReShade::GetLinearizedDepth(texcoord + float2(1, 0) / uvd);
	float vxr2 = vc - ReShade::GetLinearizedDepth(texcoord + float2(2, 0) / uvd);
	float exrC = lerp(vxr2, vxr, 2.0);
	
	if(abs(exlC - vc) > abs(exrC - vc)) {vx = -vxl;}
	else {vx = vxr;}
	
	float vy;
	float vyl = vc - ReShade::GetLinearizedDepth(texcoord + float2(0, -1) / uvd);
	float vyl2 = vc - ReShade::GetLinearizedDepth(texcoord + float2(0, -2) / uvd);
	float eylC = lerp(vyl2, vyl, 2.0);
	
	float vyr = vc - ReShade::GetLinearizedDepth(texcoord + float2(0, 1) / uvd);
	float vyr2 = vc - ReShade::GetLinearizedDepth(texcoord + float2(0, 2) / uvd);
	float eyrC = lerp(vyr2, vyr, 2.0);
	
	if(abs(eylC - vc) > abs(eyrC - vc)) {vy = -vyl;}
	else {vy = vyr;}
	
	return float4(0.5 + 0.5 * normalize(float3(vx, vy, vc / FarPlane)), 1.0);
}

//============================================================================================
//Lighting Calculations
//============================================================================================

float3 eyePos(float2 xy, float z, float2 pw)//takes screen coords (0-1) and depth (0-1) and converts to eyespace position
{
	float fn = FarPlane - NearPlane;
	float2 nxy = 2.0 * xy - 1.0;
	float3 eyp = float3(nxy * pw * z, fn * z);
	return eyp;
}

float3 sampGI(float2 coord, float3 offset, float2 pw)
{
    float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float fn = FarPlane - NearPlane;
	
	float2 dir[8]; //Clockwise from verticle
	dir[0] = normalize(float2(-1, -1) + 1.0*offset.xy);
    dir[1] = normalize(float2(-1, 0) + 1.0*offset.xz);
    dir[2] = normalize(float2(-1, 1) + 1.0*offset.yx);
    dir[3] = normalize(float2(0, -1) + 1.0*offset.yz);
    dir[4] = normalize(float2(0, 1) + 1.0*offset.xy);
    dir[5] = normalize(float2(1, -1) + 1.0*offset.xz);
    dir[6] = normalize(float2(1, 0) + 1.0*offset.yx);
    dir[7] = normalize(float2(1, 1) + 1.0*offset.yz);
    
    float rayS;
    float3 ac;
    float3 map;
 	
    float trueDepth = ReShade::GetLinearizedDepth(coord);
	if(trueDepth == 1.0) {return AmbientNeg;}    
	float3 surfN = normalize(1.0 - 2.0 * tex2D(NormalSam, coord).rgb);
 	
    for(int i = 0; i < 8; i++)
    {
        
    	
		float depth = trueDepth;
		float minDep = trueDepth;
		float3 rayP = float3(coord, depth); 
	        for(rayS = sLod; rayS <= (TOTAL_RAY_LODS + sLod); rayS++)
	        {
	         
					float ld = min(rayS - 1, 0);
					float ll = min(rayS - 2, 0);
					
					float2 moDir = float2(dir[i].x, dir[i].y);
					if(addR == 0) {rayP = float3(coord, depth);}
					rayP += sampR * (offset.r + 1.5) * pow(2.0, rayS) * normalize(float3(moDir, 0)) / float3(res, 1.0);
	    			
					depth = tex2Dlod(BufferSam, float4(rayP.xy, ld, ld)).r;
					minDep = min(minDep, depth);           
					
					map = tex2Dlod(LightSam, float4(rayP.xy, ll, ll)).rgb;
					map = -map / (map - 1.1);
					map *= 1.0 + pow(distance(eyePos(rayP.xy, rayP.z, pw), 0.0), disD) / fn;
					
					
	                float pd = 1.0 + disM * distance(eyePos(rayP.xy, rayP.z, pw), eyePos(coord, depth, pw));
					map /= pow(pd, disD);
					
					float3 rayD = float3(coord, trueDepth) - rayP;
					rayD = normalize(rayD);
					
					
					float3 amb = 0.5 + 0.5 * dot(surfN, -rayD);
					
					float comp = ceil(depth - minDep);
					ac += amb * map * comp;
	            	             
	        }
        
    }
    ac /= 8 * TOTAL_RAY_LODS;
    ac =pow(ac,  LigM);
   
	return pow((ac * sqrt(TOTAL_RAY_LODS)), 1.0 / 2.2);
}

//============================================================================================
//Denoising
//============================================================================================

float3 Denoise(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	if(doDenoising == 0) {return tex2D(HalfSam, texcoord).rgb;}    
	int gaussianK[25] =
	{1,4,7,4,1,
    4,16,26,16,4,
    7,26,41,26,7,
    4,16,26,16,4,
    1,4,7,4,1};
    
    float fn = FarPlane - NearPlane;
    float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    float3 col;
    float gd = ReShade::GetLinearizedDepth(texcoord);
    for(int i = 0; i < 5; i++)
    {
        for(int ii = 0; ii < 5; ii++)
        {
            int s = (i) + (ii);
            float g = float(gaussianK[s]);
            float2 c = ((texcoord * res)-3.0 + float2(i, ii)) / res;
            float d = ReShade::GetLinearizedDepth(c);
            float3 sam = g * tex2D(HalfSam, c).rgb;
            sam /= 1.0 + disM * pow(distance(eyePos(c, d, FarPlane), eyePos(texcoord, gd, FarPlane)), disD) / fn;
  		  col += sam;      
		}
    }
    return 1.5 * col / 273.0;
}


//GI Texture
float4 GlobalPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 aspectPos= float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	float3 noise = tex2D(NoiseSam, frac(texcoord * (aspectPos / 512))).rgb;
	float2 PW = 2.0 * tan(FOV * 0.00875) * (FarPlane - NearPlane); //Dimensions of FarPlane
	PW.y *= aspectPos.x / aspectPos.y;
	
	float3 input = sampGI(texcoord, (0.5 - noise), PW);
	return float4(saturate(input), 1.0);
}

float3 ZN_Stylize_FXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float2 bxy= float2(BUFFER_WIDTH, BUFFER_HEIGHT);
	
	float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 noise = tex2D(NoiseSam, frac(0.5 + texcoord * (bxy / 512))).rgb;
	float3 light = tex2D(LightSam, texcoord).rgb;
	float depth = tex2D(BufferSam, texcoord).r;
	
	float lightG = light.r * 0.2126 + light.g * 0.7152 + light.b * 0.0722;
	
	float3 GI = tex2Dlod(BlurSam1, float4(texcoord, 1,1)).rgb;
	GI *= 1.0 - pow(depth, 1.0 - distMask);
	
	if(BlendMode == 0){
		input = input * abs(debug - 1.0)
			+ pow(Intensity, abs(debug - 1.0))
			* (clamp(GI - noise * 0.05 - lightG, 0.0, 1.0)
			- AmbientNeg * abs(debug - 1.0));
	}
	
	else{
		input = abs(debug - 1.0) * input + pow(Intensity, abs(debug - 1.0)) * GI;
	}
	return saturate(input);
}

technique ZN_SDIL
<
    ui_label = "ZN_SDIL";
    ui_tooltip =        
        "             Zentient - Screen Space Directional Indirect Lighting             \n"
        "\n"
        "\n"
        "A relatively lightweight Screen Space Global Illumination implementation that samples LODS\n"
        "\n"
        "\n";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LightMap;
		RenderTarget = GILumTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LinearBuffer;
		RenderTarget = GIBufTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = NormalBuffer;
		RenderTarget = GINorTex;
	}
	
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = GlobalPass;
		RenderTarget = GIHalfTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Denoise;
		RenderTarget = GIBlurTex1;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ZN_Stylize_FXmain;
	}
}
