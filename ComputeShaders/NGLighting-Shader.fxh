//Stochastic Screen Space Ray Tracing
//Written by MJ_Ehsan for Reshade
//Version 0.7

//license
//CC0 ^_^


//Thanks Lord of Lunacy, Leftfarian, and other devs for helping me. <3
//Thanks Alea & MassiHancer for testing. <3

//Credits:
//Thanks Crosire for ReShade.
//https://reshade.me/

//Thanks Jakob for DRME.
//https://github.com/JakobPCoder/ReshadeMotionEstimation

//I learnt a lot from qUINT_SSR. Thanks Pascal Gilcher.
//https://github.com/martymcmodding/qUINT

//Also a lot from DH_RTGI. Thanks Demien Hambert.
//https://github.com/AlucardDH/dh-reshade-shaders

//Thanks Radegast for Unity Sponza Test Scene.
//https://mega.nz/#!qVwGhYwT!rEwOWergoVOCAoCP3jbKKiuWlRLuHo9bf1mInc9dDGE

//Thanks Timothy Lottes and AMD for the Tonemapper and the Inverse Tonemapper.
//https://gpuopen.com/learn/optimized-reversible-tonemapper-for-resolve/

//Thanks Eric Reinhard for the Luminance Tonemapper and  the Inverse.
//https://www.cs.utah.edu/docs/techreports/2002/pdf/UUCS-02-001.pdf

//Thanks sujay for the noise function. Ported from ShaderToy.
//https://www.shadertoy.com/view/lldBRn

//////////////////////////////////////////
//TO DO
//1- [v]Add another spatial filtering pass
//2- [ ]Add Hybrid GI/Reflection
//3- [v]Add Simple Mode UI with setup assist
//4- [ ]Add internal comaptibility with Volumetric Fog V1 and V2
//      By using the background texture provided by VFog to blend the Reflection.
//      Then Blending back the fog to the image. This way fog affects the reflection.
//      But the reflection doesn't break the fog.
//5- [ ]Add ACEScg and or Filmic inverse tonemapping as optional alternatives to Timothy Lottes
//6- [v]Add AO support
//7- [x]Add second temporal pass after second spatial pass.
//8- [o]Add Spatiotemporal upscaling. have to either add jitter to the RayMarching pass or a checkerboard pattern.
//9- [v]Add Smooth Normals.
//10-[ ]Use pre-calulated blue noise instead of white. From https://www.shadertoy.com/view/sdVyWc
//11-[ ]Add depth awareness to smooth normals. To do so, add depth in the alpha channel of 
//	  NormTex and NormTex1 for optimization.
//12-[ ]Make normal based edge awareness of all passes based on angular distance of the 2 normals.
//13-[ ]Make sample distance of smooth normals exponential.
//14-[ ]

///////////////Include/////////////////////

#include "ReShade.fxh"
#include "NGLightingUI.fxh"

uniform float Timer < source = "timer"; >;
uniform float Frame < source = "framecount"; >;

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

#define LDepth ReShade::GetLinearizedDepth

#define FAR_PLANE RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 

#define PI 3.1415927
#define PI2 2*PI
#define rad(x) (x/360)*PI2 
///////////////Include/////////////////////
///////////////PreProcessor-Definitions////

#ifndef UI_DIFFICULTY
 #define UI_DIFFICULTY 0
#endif

#define NG_AspectRatio (BUFFER_WIDTH/BUFFER_HEIGHT)      

#ifndef SMOOTH_NORMALS
 #define SMOOTH_NORMALS 1
#endif

#ifndef RESOLUTION_SCALE_
 #define RESOLUTION_SCALE_ 0.67
#endif

//Full res denoising on all passes. Otherwise only Spatial Filter 1 will be full res.
//Deprecated. Always HQ. LQ performance benefit isn't enough to sacrifice that much of the quality.
//But kept the code in case I regret. :')
//#ifndef HQ_UPSCALING
// #define HQ_UPSCALING 1
//#endif

#define HQ_SPECULAR_REPROJECTION 0  //WIP!

//Blur radius adaptivity threshold depending on the number of accumulated frames per pixel
#define Off       80  //Default is 80 //no filter
#define VerySmall 48  //Default is 60 //one 3*3 cross filter, TODO
#define Small     24  //Default is 40 //one 3*3 box filter
#define Medium    12  //Default is 15 //one 5*5 box filter
#define Large     8   //Default is 8  //two pass (3*3 and 3*3) Atrous 9*9 box filter
#define VeryLarge 6   //Default is 4  //two pass (3*3 and 5*5) Atrous 15*15 box filter
#define Largest   4   //Default is 4  //three pass (3*3 and 3*3 and 5*5) Atrous 45*45 box filter

//if the History Length is lower than this threshold, edge avoiding function will be ignored to make
//sure the temporally underaccumulated pixel is getting enough spatial accumulation.
//HistoryFix0 should be lower or equal to HistoryFix1 in order to avoid artifacts.
#define HistoryFix0 0 //Big one  . Default is 1
#define HistoryFix1 0 //Small one. Default is 1
#define NGLi_MAX_MipFilter 0 //additional mip based blur (radius = 2^MAX_MipFilters). Default is 3

//Motion Based Deghosting Threshold is the minimum value to be multiplied to the history length.
//Higher value causes more ghosting but less blur. Too low values might result in strong flickering in motion.
#define MBSDThreshold 0.5 //Default is 0.05
#define MBSDMultiplier 80 //Default is 90

//Temporal stabilizer Intensity
#define TSIntensity 0.9

//Temporal Refine min blend value. lower is more stable but ghosty and too low values may introduce banding
#define TRThreshold 0.001

//Smooth Normals configs. It uses a separable bilateral blur which uses only normals as determinator. 
#define SNThreshold 0.7 //Bilateral Blur Threshold for Smooth normals passes. default is 0.5
#define SNDepthW FAR_PLANE*1*SNThreshold //depth weight as a determinator. default is 100/SNThreshold
#if SMOOTH_NORMALS <= 1 //13*13 8taps
 #define LODD 0.5    //Don't touch this for God's sake
 #define SNWidth 5.5 //Blur pixel offset for Smooth Normals
 #define SNSamples 1 //actually SNSamples*4+4!
#elif SMOOTH_NORMALS == 2 //16*16 16taps
 #define LODD 0.5
 #define SNWidth 2.5
 #define SNSamples 3
#elif SMOOTH_NORMALS > 2 //41*41 84taps
 #warning "SMOOTH_NORMALS 3 is slow and should to be used for photography or old games. Otherwise set to 2 or 1."
 #define LODD 0
 #define SNWidth 1.5
 #define SNSamples 30
#endif

///////////////PreProcessor-Definitions////
///////////////Textures-Samplers///////////

texture TexColor : COLOR;
sampler sTexColor {Texture = TexColor; SRGBTexture = false;};

texture TexDepth : DEPTH;
sampler sTexDepth {Texture = TexDepth;};

texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler SamplerMotionVectors { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

texture SSSR_ReflectionTex  { Width = BUFFER_WIDTH*RESOLUTION_SCALE_; Height = BUFFER_HEIGHT*RESOLUTION_SCALE_; Format = RGBA16f; };
sampler sSSSR_ReflectionTex { Texture = SSSR_ReflectionTex; };

texture SSSR_HitDistTex { Width = BUFFER_WIDTH*RESOLUTION_SCALE_; Height = BUFFER_HEIGHT*RESOLUTION_SCALE_; Format = RGBA16f; };
sampler sSSSR_HitDistTex { Texture = SSSR_HitDistTex; };

texture SSSR_POGColTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler sSSSR_POGColTex { Texture = SSSR_POGColTex; };

texture SSSR_FilterTex0  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = NGLi_MAX_MipFilter+2; };
sampler sSSSR_FilterTex0 { Texture = SSSR_FilterTex0; };

texture SSSR_FilterTex1  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = NGLi_MAX_MipFilter+2; };
sampler sSSSR_FilterTex1 { Texture = SSSR_FilterTex1; };

texture SSSR_FilterTex2  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = NGLi_MAX_MipFilter+2; };
sampler sSSSR_FilterTex2 { Texture = SSSR_FilterTex2; };

texture SSSR_FilterTex3  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = NGLi_MAX_MipFilter+2; };
sampler sSSSR_FilterTex3 { Texture = SSSR_FilterTex3; };

texture SSSR_PNormalTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_PNormalTex { Texture = SSSR_PNormalTex; };

texture SSSR_NormTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_NormTex { Texture = SSSR_NormTex; };

texture SSSR_NormTex1  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_NormTex1 { Texture = SSSR_NormTex1; };

texture SSSR_HLTex0 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; };
sampler sSSSR_HLTex0 { Texture = SSSR_HLTex0; };

texture SSSR_HLTex1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; };
sampler sSSSR_HLTex1 { Texture = SSSR_HLTex1; };

texture SSSR_MaskTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
sampler sSSSR_MaskTex { Texture = SSSR_MaskTex; };

#if NGL_HYBRID_MODE

texture SSSR_ReflectionTexD  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sSSSR_ReflectionTexD { Texture = SSSR_ReflectionTexD; };

texture SSSR_FilterTex0D  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = NGLi_MAX_MipFilter+2; };
sampler sSSSR_FilterTex0D { Texture = SSSR_FilterTex0D; };

texture SSSR_FilterTex1D  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = NGLi_MAX_MipFilter+2; };
sampler sSSSR_FilterTex1D { Texture = SSSR_FilterTex1D; };

texture SSSR_FilterTex2D  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = NGLi_MAX_MipFilter+2; };
sampler sSSSR_FilterTex2D { Texture = SSSR_FilterTex2D; };

texture SSSR_FilterTex3D  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = NGLi_MAX_MipFilter+2; };
sampler sSSSR_FilterTex3D { Texture = SSSR_FilterTex3D; };

#endif //NGL_HYBRID_MODE

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////
///////////////UI//////////////////////////
///////////////Vertex Shader///////////////
///////////////Vertex Shader///////////////
///////////////Functions///////////////////

float GetSpecularDominantFactor(float NoV, float roughness)
{
	float a = 0.298475 * log(39.4115 - 39.0029 * roughness);
	float f = pow(saturate(1.0 - NoV), 10.8649)*(1.0 - a) + a;
	
	return saturate(f);
}

float2 sampleMotion(float2 texcoord)
{
    return tex2D(SamplerMotionVectors, texcoord).rg;
}

float noise(float2 co)
{
  return frac(sin(dot(co.xy ,float2(1.0,73))) * 437580.5453);
}

float3 noise3dts(float2 co, float s, float frame)
{
	co += sin(frame/120.347668756453546);
	co += s/16.3542625435332254;
	return float3( noise(co), noise(co+0.6432168421), noise(co+0.19216811));
}

float3 UVtoPos(float2 texcoord)
{
	float3 scrncoord = float3(texcoord.xy*2-1, LDepth(texcoord) * FAR_PLANE);
	scrncoord.xy *= scrncoord.z * (rad(fov*0.5));
	scrncoord.x *= NG_AspectRatio;
	//scrncoord.xy *= ;
	
	return scrncoord.xyz;
}

float3 UVtoPos(float2 texcoord, float depth)
{
	float3 scrncoord = float3(texcoord.xy*2-1, depth * FAR_PLANE);
	scrncoord.xy *= scrncoord.z * (rad(fov*0.5));
	scrncoord.x *= NG_AspectRatio;
	//scrncoord.xy *= ;
	
	return scrncoord.xyz;
}

float2 PostoUV(float3 position)
{
	float2 scrnpos = position.xy;
	scrnpos /= rad(fov/2);
	scrnpos.x /= NG_AspectRatio;
	scrnpos /= position.z;
	
	return scrnpos/2 + 0.5;
}
	

float3 Normal(float2 texcoord)
{
	float2 p = pix;
	float3 u,d,l,r,u2,d2,l2,r2;
	
	u = UVtoPos( texcoord + float2( 0, p.y));
	d = UVtoPos( texcoord - float2( 0, p.y));
	l = UVtoPos( texcoord + float2( p.x, 0));
	r = UVtoPos( texcoord - float2( p.x, 0));
	
	p *= 2;
	
	u2 = UVtoPos( texcoord + float2( 0, p.y));
	d2 = UVtoPos( texcoord - float2( 0, p.y));
	l2 = UVtoPos( texcoord + float2( p.x, 0));
	r2 = UVtoPos( texcoord - float2( p.x, 0));
	
	u2 = u + (u - u2);
	d2 = d + (d - d2);
	l2 = l + (l - l2);
	r2 = r + (r - r2);
	
	float3 c = UVtoPos( texcoord);
	
	float3 v = u-c; float3 h = r-c;
	
	if( abs(d2.z-c.z) < abs(u2.z-c.z) ) v = c-d;
	if( abs(l2.z-c.z) < abs(r2.z-c.z) ) h = c-l;
	
	return normalize(cross( v, h));
}

float3 Bump(float2 texcoord, float height)
{
	float2 p = pix;
	
	float3 s[3];
	s[0] = tex2D(sTexColor, texcoord + float2(p.x, 0)).rgb * height;
	s[1] = tex2D(sTexColor, texcoord + float2(0, p.y)).rgb * height;
	s[2] = tex2D(sTexColor, texcoord).rgb * height;
	
	float3 XB = s[2]-s[0];
	float3 YB = s[2]-s[1];
	
	float3 bump = float3(XB.x*2, YB.y*2, 1);
	bump = normalize(bump);
	return bump;
}

float3 blend_normals(float3 n1, float3 n2)
{
    //return normalize(float3(n1.xy*n2.z + n2.xy*n1.z, n1.z*n2.z));
    n1 += float3( 0, 0, 1);
    n2 *= float3(-1, -1, 1);
    return n1*dot(n1, n2)/n1.z - n2;
}

float lum(in float3 color)
{
	return (color.r+color.g+color.b)/3;
}

float3 InvTonemapper(float3 color)
{//Timothy Lottes fast_reversible
	return color.rgb / ((1.0 + max(1-(IT_Intensity*((GI)?1:roughness*0.4)),0.001)) - max(color.r, max(color.g, color.b)));
}

float3 Tonemapper(float3 color)
{//Timothy Lottes fast_reversible
	return color.rgb / ((1.0 + max(1-(IT_Intensity*((GI)?1:roughness*0.4)),0.001)) + max(color.r, max(color.g, color.b)));
}

float InvTonemapper(float color)
{//Reinhardt reversible
	return color / (1.001 - color);
}

float dilate(in sampler color, in float2 texcoord, in float2 p, in float mip)
{
	float result = 99999999;
	
	[unroll]for(float x = -p.x; x <= p.x; x+=p.x){
	[unroll]for(float y = -p.y; y <= p.y; y+=p.y){
		result = min(result, tex2D(color, texcoord + float2(x,y)).r);
	}}
	
	return result;
}

bool IsSaturated(float2 coord)
{
	float2 a = float2(max(coord.r, coord.g), min(coord.r, coord.g));
	return coord.r > 1 || coord.g < 0;
}

bool IsSaturatedStrict(float2 coord)
{
	float2 a = float2(max(coord.r, coord.g), min(coord.r, coord.g));
	return coord.r >= 1 || coord.g <= 0;
}

// The following code is licensed under the MIT license: https://gist.github.com/TheRealMJP/bc503b0b87b643d3505d41eab8b332ae
// Samples a texture with Catmull-Rom filtering, using 9 texture fetches instead of 16.
// See http://vec3.ca/bicubic-filtering-in-fewer-taps/ for more details
float4 tex2Dcatrom(in sampler tex, in float2 uv, in float2 texsize)
{
	float4 result = 0.0f;
	
	if(UseCatrom){
    float2 samplePos = uv; samplePos *= texsize;
    float2 texPos1 = floor(samplePos - 0.5f) + 0.5f;

    float2 f = samplePos - texPos1;

    float2 w0 = f * (-0.5f + f * (1.0f - 0.5f * f));
    float2 w1 = 1.0f + f * f * (-2.5f + 1.5f * f);
    float2 w2 = f * (0.5f + f * (2.0f - 1.5f * f));
    float2 w3 = f * f * (-0.5f + 0.5f * f);
	
	float2 w12 = w1 + w2;
    float2 offset12 = w2 / (w1 + w2);

    float2 texPos0 = texPos1 - 1;
    float2 texPos3 = texPos1 + 2;
    float2 texPos12 = texPos1 + offset12;

    texPos0 /= texsize;
    texPos3 /= texsize;
    texPos12 /= texsize;

    result += tex2D(tex, float2(texPos0.x, texPos0.y)) * w0.x * w0.y;
    result += tex2D(tex, float2(texPos12.x, texPos0.y)) * w12.x * w0.y;
    result += tex2D(tex, float2(texPos3.x, texPos0.y)) * w3.x * w0.y;
    result += tex2D(tex, float2(texPos0.x, texPos12.y)) * w0.x * w12.y;
    result += tex2D(tex, float2(texPos12.x, texPos12.y)) * w12.x * w12.y;
    result += tex2D(tex, float2(texPos3.x, texPos12.y)) * w3.x * w12.y;
    result += tex2D(tex, float2(texPos0.x, texPos3.y)) * w0.x * w3.y;
    result += tex2D(tex, float2(texPos12.x, texPos3.y)) * w12.x * w3.y;
    result += tex2D(tex, float2(texPos3.x, texPos3.y)) * w3.x * w3.y;
	} //UseCatrom
	else{
	result = tex2D(tex, uv);
	} //UseBilinear
    return max(0, result);
}

//from: https://www.shadertoy.com/view/XsSfzV
// by Nikos Papadopoulos, 4rknova / 2015
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
float3 toYCC(float3 rgb)
{
	float Y  =  .299 * rgb.x + .587 * rgb.y + .114 * rgb.z; // Luminance
	float Cb = -.169 * rgb.x - .331 * rgb.y + .500 * rgb.z; // Chrominance Blue
	float Cr =  .500 * rgb.x - .419 * rgb.y - .081 * rgb.z; // Chrominance Red
    return float3(Y,Cb + 128./255.,Cr + 128./255.);
}

float3 toRGB(float3 ycc)
{
    float3 c = ycc - float3(0., 128./255., 128./255.);
    
    float R = c.x + 1.400 * c.z;
	float G = c.x - 0.343 * c.y - 0.711 * c.z;
	float B = c.x + 1.765 * c.y;
    return float3(R,G,B);
}

///////////////Functions///////////////////
///////////////Pixel Shader////////////////

void GBuffer1
(
	float4 vpos : SV_Position,
	float2 texcoord : TexCoord,
	out float4 normal : SV_Target) //SSSR_NormTex
{
	normal.rgb = Normal(texcoord.xy);
	normal.a   = LDepth(texcoord.xy);
#if SMOOTH_NORMALS <= 0
	normal.rgb = blend_normals( Bump(texcoord, BUMP), normal.rgb);
#endif
}

float4 SNH(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color = tex2D(sSSSR_NormTex, texcoord);
	float4 s, s1; float sc;
	
	float2 p = pix; p*=SNWidth;
	
	float T = SNThreshold * saturate(2*(1-color.a));
	T = rcp(max(T, 0.0001));
	
	for (int i = -SNSamples; i <= SNSamples; i++)
	{
		s = tex2D(sSSSR_NormTex, float2(texcoord + float2(i*p.x, 0)/*, 0, LODD*/));
		float diff = dot(0.333, abs(s.rgb - color.rgb)) + abs(s.a - color.a)*SNDepthW;
		diff = 1-saturate(diff*T);
		s1 += s*diff;
		sc += diff;
	}
	
	return s1.rgba/sc;
}

float4 SNV(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color = tex2Dlod(sSSSR_NormTex1, float4(texcoord, 0, 0));
	float4 s, s1; float sc;

	float2 p = pix; p*=SNWidth;
	float T = SNThreshold * saturate(2*(1-color.a)); T = rcp(max(T, 0.0001));
	for (int i = -SNSamples; i <= SNSamples; i++)
	{
		s = tex2D(sSSSR_NormTex1, float2(texcoord + float2(0, i*p.y)/*, 0, LODD*/));
		float diff = dot(0.333, abs(s.rgb - color.rgb)) + abs(s.a - color.a)*SNDepthW;
		diff = 1-saturate(diff*T*2);
		s1 += s*diff;
		sc += diff;
	}
	
	s1.rgba = s1.rgba/sc;
	s1.rgb = blend_normals( Bump(texcoord, BUMP), s1.rgb);
	return float4(s1.rgb, LDepth(texcoord));
}

void DoRayMarch(float2 texcoord, float3 noise, float3 position, float3 normal, float3 raydir, out float3 Reflection, out float4 HitData, out float a) 
{
	float3 raypos, Check; float2 UVraypos; float raydepth, steplength; bool hit; uint i;
	
	steplength = 1+noise.x*STEPNOISE;
	
	raypos = position + raydir * steplength;
	raydepth = -RAYDEPTH;
	
	[loop]for( i = 0; i < UI_RAYSTEPS; i++)
	{
			UVraypos = PostoUV(raypos);
			Check = UVtoPos(UVraypos) - raypos;
			
			hit = Check.z < 0 && Check.z > raydepth * steplength;
			if(hit)
			{
				a=1; a *= UVraypos.y >= 0;
				i += UI_RAYSTEPS;
			}
			if(TemporalRefine&&Check.z < 0) i += UI_RAYSTEPS;
			
			raypos += raydir * steplength;
			steplength *= RAYINC;
	}
	
	Reflection = tex2D(sTexColor, UVraypos.xy).rgb;
	
	if(IsSaturatedStrict(UVraypos.xy)) Reflection = 0;
	HitData.rgb = raypos;
	HitData.a = distance(raypos, position);
}

void RayMarch(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0, out float4 HitData : SV_Target1)
{
	float3 depth    = LDepth  (texcoord); 
	HitData = 0;
	FinalColor.rgba = float4(tex2D(sTexColor, texcoord).rgb, 0);
	if(depth.x<SkyDepth){
		float3 reflection, Check, image, position, normal, eyedir, raydirR, raydirG, raydir, raypos, noise; float2 UVraypos; float raybias, HL, a; bool hit;

		HL = max(1, tex2D(sSSSR_HLTex0, texcoord).r);
		noise = noise3dts(texcoord, 0, Frame%HL);
		
		position = UVtoPos (texcoord);
		normal   = tex2D(sSSSR_NormTex, texcoord).rgb;
		eyedir   = normalize(position);
		
		raydirG   = reflect(eyedir, normal);
		raydirR   = lerp(raydirG, noise-0.5, 0.5);
		raybias   = dot(raydirG, raydirR);
		raydir    = lerp(raydirG, raydirR, pow(max(1.0-(0.5*cos(raybias*PI)+0.5), 0.0), rsqrt(InvTonemapper((GI)?1:roughness))));
		
		DoRayMarch(texcoord, noise, position, normal, raydir, reflection, HitData, a);
		
		FinalColor.rgb = reflection;
		
		if(GI&&LinearConvert)FinalColor.rgb = pow(abs(FinalColor.rgb), 1 / 2.2);
		FinalColor.rgb = clamp(InvTonemapper(FinalColor.rgb), -1000, 1000);
		
		if(!GI)FinalColor.a = a;
		if( GI)FinalColor.a = saturate(distance(HitData.rgb, position)/100);
		
		FinalColor.rgb *= a;
	}//depth check if end
}//ReflectionTex

void TemporalFilter0(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float mask : SV_Target0, out float4 Filter1to0 : SV_Target1)
{//Writes the mask to a texture. Then the texture will be dilated in the next pass to avoid masking edges when camera jitters
	Filter1to0 = tex2D(sSSSR_FilterTex1, texcoord);
	float depth = LDepth(texcoord);
	if(depth>SkyDepth){mask=0;}else{
	float4 past_normal; float3 normal, ogcolor, past_ogcolor; float2 MotionVectors; float2 outbound; float past_depth, HistoryLength;
	//Inputs
	MotionVectors = 0;
	MotionVectors = sampleMotion(texcoord);

	HistoryLength = tex2D(sSSSR_HLTex1, texcoord + MotionVectors).r;
	//Normal
	normal = tex2D(sSSSR_NormTex, texcoord).rgb;// * 0.5 + 0.5;
	past_normal = tex2D(sSSSR_PNormalTex, texcoord + MotionVectors);
	//Depth
	past_depth = past_normal.a;
	//Original Background Color
	ogcolor = toYCC(tex2D(sTexColor, texcoord).rgb);
	past_ogcolor = toYCC(tex2D(sSSSR_POGColTex, texcoord + MotionVectors).rgb);
	
	ogcolor.g += ogcolor.b;
	past_ogcolor.g += past_ogcolor.b;
	//Disocclusion masking and Motion Estimation Error masking
	//outbound = IsSaturated(texcoord + MotionVectors);
	outbound = texcoord + MotionVectors;
	outbound = float2(max(outbound.r, outbound.g), min(outbound.r, outbound.g));
	outbound.rg = (outbound.r > 1 || outbound.g < 0);
	
	mask = abs(lum(normal) - lum(past_normal.rgb)) * 1
		 + abs(depth - past_depth)				 * 1
		 + abs(ogcolor.g - past_ogcolor.g)  	   * 5
		 > Tthreshold;
		 
	mask = max(mask, outbound.r);
	}//sky mask end
}

void TemporalFilter1(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0, out float HLOut : SV_Target1)
{
	float depth = LDepth(texcoord);
	float4 Current, History; float3 Xvirtual, eyedir; float2 MotionVectors, p, pixelUvVirtualPrev; float past_depth, mask, HistoryLength;
	
	MotionVectors = sampleMotion(texcoord);
	HistoryLength = tex2D(sSSSR_HLTex1, texcoord + MotionVectors).r;
	p = pix;
//#if HQ_UPSCALING == 0
	p *= lerp(1, rcp(RESOLUTION_SCALE_), 0.5);
//#endif
#if HQ_SPECULAR_REPROJECTION
	float NoV, SDF; float4 HitDist, gWorldToClipPrev; 
	if(!GI)
	{
		past_depth       = tex2D(sSSSR_PNormalTex, texcoord + MotionVectors).a;
		gWorldToClipPrev = UVtoPos(texcoord + MotionVectors, past_depth);
		eyedir   = normalize(UVtoPos(texcoord));
		NoV      = dot(eyedir, Normal(texcoord));
		SDF      = GetSpecularDominantFactor(NoV, roughness);
		HitDist  = tex2D(sSSSR_HitDistTex, texcoord);
		Xvirtual = HitDist.rgb - eyedir * HitDist.a;
		pixelUvVirtualPrev = PostoUV( gWorldToClipPrev.rgb + Xvirtual/1000);
	}
#endif
	mask = 1-dilate(sSSSR_MaskTex, texcoord, p, 0);
	//mask = 1-tex2D(sSSSR_MaskTex, texcoord).r;
	Current = tex2Dcatrom(sSSSR_ReflectionTex, texcoord, BUFFER_SCREEN_SIZE*RESOLUTION_SCALE_).rgba;
	History = tex2D(sSSSR_FilterTex1, texcoord + MotionVectors).rgba;
	HistoryLength = tex2D(sSSSR_HLTex1, texcoord + MotionVectors).r;
	
	HistoryLength *= mask; //sets the history length to 0 for discarded samples
	HLOut = HistoryLength + mask; //+1 for accepted samples
	HLOut = min(HLOut, MAX_Frames*max(sqrt((GI)?1:roughness), max(0.0001, STEPNOISE))); //Limits the linear accumulation to MAX_Frames, The rest will be accumulated exponentialy with the speed = (1-1/Max_Frames)
	
	if(!GI)HLOut = HLOut * max(saturate(1-length(MotionVectors)*(1-sqrt(roughness))*MBSDMultiplier), MBSDThreshold); //Motion Vector Based Deghosting for specular reflections
	
	HLOut = max(HLOut, 0.001);
	if( TemporalRefine)FinalColor = lerp(History, Current, min((Current.a != 0) ? 1/HLOut : TRThreshold, mask));
	if(!TemporalRefine)FinalColor = lerp(History, Current, min(                   1/HLOut,         	  mask));
	FinalColor = (mask||depth==0)?FinalColor:Current;
}

//mode 0 is specular. mode 1 is diffuse
//size 0 is for SF 0. size 1 is for SF 1.
//Tex is the sampler of the texture that should recieve the filter.
float4 AdaptiveAtrous(in bool mode, in int size, in sampler Tex, in float2 texcoord, in float HLOut)
{
	float2 p = pix;
	
	float Roughness = (GI)?1:roughness;
	float HitDist = tex2D(sSSSR_HitDistTex, texcoord).r; //Make the texture single channel
	float4 Geometry = tex2D(sSSSR_NormTex, texcoord);
		float3 normal = Geometry.rgb;
		float depth = Geometry.a;
	
	float ST = Sthreshold;
	bool HF = HLOut < HistoryFix1 && MAX_Frames > HistoryFix1;
	if(HF)ST *= 20;
	
	float radius = 1;
	if(!mode)
	radius = saturate(Roughness * 8 / HLOut) * saturate((HitDist * 5) / FAR_PLANE);
	
	float lod = min(NGLi_MAX_MipFilter, max(0, (NGLi_MAX_MipFilter)-HLOut));
	lod *= radius * saturate(roughness);
	
	bool Larger = HLOut < VeryLarge;

	p = radius * p * pow(2, max(0, lod));
	if(size==0){p *= Larger ? 5 : 3;}
	else if(size==2){p *= 15;}
	else if(Larger){p *= 1.5;}
	p *= rcp(RESOLUTION_SCALE_);
	
	float2 offset[8];
	float  weight[8];
	offset = {
		float2(-p.x,-p.y),float2(0, p.y),float2( p.x,-p.y),
		float2(-p.x,   0),			   float2( p.x,   0),
		float2(-p.x, p.y),float2(0,-p.y),float2( p.x, p.y)};
	
	if(Larger&&size==1){
	weight = {
		4,2,4,
		2,  2,
		4,2,4};}
	else{
	weight = {
		1,1,1,
		1,  1,
		1,1,1};}

	float4 color = tex2Dlod(Tex, float4(texcoord, 0, lod));
	int samples = 1;
	[unroll]for(int i = 0; i <= 7; i++)
	{
		offset[i].xy += texcoord;
		
		float4 sGeometry = tex2D(sSSSR_NormTex, offset[i]);
			float3 snormal = sGeometry.rgb;
			float sdepth = sGeometry.a;
			
		bool determinator = lum(abs(snormal - normal))+abs(sdepth-depth) < ST;
		if(determinator)
		{
			color += tex2Dlod(Tex, float4(offset[i].xy, 0, lod)) * weight[i];
			samples += weight[i];
		}
	}
	color /= samples;
	return color;
}

void SpatialFilter2( in float4 vpos : SV_Position, in float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0)
{
	float HLOut = tex2D(sSSSR_HLTex0, texcoord).r;
	if(HLOut<Largest)
	{
		float4 color = AdaptiveAtrous(GI, 2, sSSSR_FilterTex0, texcoord, HLOut);
		FinalColor = color;
	}
	else
	{
	FinalColor = tex2D(sSSSR_FilterTex0, texcoord).rgba;
	}
}
		
void SpatialFilter0( in float4 vpos : SV_Position, in float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0)
{
	float HLOut = tex2D(sSSSR_HLTex0, texcoord).r;
	if(HLOut<Medium)
	{
		float4 color = AdaptiveAtrous(GI, 0, sSSSR_FilterTex1, texcoord, HLOut);
		FinalColor = color;
	}
	else
	{
	FinalColor = tex2D(sSSSR_FilterTex1, texcoord).rgba;
	}
}

void SpatialFilter1(
	in  float4 vpos       : SV_Position,
	in  float2 texcoord   : TexCoord,
	out float4 FinalColor : SV_Target0,//FilterTex1
	out float4 Geometry   : SV_Target1,//PNormalTex
	out float3 Ogcol      : SV_Target2,//POGColTex
	out float  HLOut      : SV_Target3,//HLTex1
	out float4 TSHistory  : SV_Target4)//FilterTex2
{
	HLOut = tex2D(sSSSR_HLTex0, texcoord).r;
	
	float4 color = AdaptiveAtrous(GI, 1, sSSSR_FilterTex0, texcoord, HLOut);
	FinalColor = color;

	Geometry   = tex2D(sSSSR_NormTex, texcoord);
	TSHistory  = tex2D(sSSSR_FilterTex3, texcoord).rgba;
	Ogcol      = tex2D(sTexColor, texcoord).rgb;
}

void TemporalStabilizer(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0)
{
	float2 p = pix; p *= rcp(RESOLUTION_SCALE_);
	
	float4 SCurrent;
	
	float2 MotionVectors = sampleMotion(texcoord);
	float4 history = tex2Dcatrom(sSSSR_FilterTex2, texcoord +  MotionVectors, BUFFER_SCREEN_SIZE);
	//history.rgb = toYCC(history.rgb);
	
	int r = 1;
	     if(IT_Intensity > 0.99){r=4;}
	else if(IT_Intensity > 0.96){r=2;}
	
	float4 Max = 0; float4 Min = 1;
	int x, y;
	[unroll]for(x = -r; x<=r; x++){
	[unroll]for(y = -r; y<=r; y++){
		SCurrent = tex2D(sSSSR_FilterTex1, texcoord + float2(x,y)*p);
		//SCurrent.rgb = toYCC(SCurrent.rgb);
		
		Max = max(SCurrent, Max);
		Min = min(SCurrent, Min);
	}
	}
	
	float4 chistory = clamp(history, Min, Max);
	//chistory.rgb = toRGB(chistory.rgb);
	
	float diff = 1 - min(0.8, dot(0.25, abs(chistory.rgba - history.rgba)) * 2);
	
	float4 current = tex2D(sSSSR_FilterTex1, texcoord);
	
	float2 outbound = texcoord + MotionVectors;
	outbound = float2(max(outbound.r, outbound.g), min(outbound.r, outbound.g));
	outbound.rg = (outbound.r > 1 || outbound.g < 0);
	
	float LerpFac = TSIntensity                         //main factor
					*(1 - outbound.r)                   //0 if the pixel is out of boundary
					*max(0.5, pow(GI?1:max(roughness, 0.0), 0.1)) //decrease if roughness is low
					*diff                               //decrease if the difference between original and clamped history is high
					*(1 - 5 * length(MotionVectors));   //decrease if movement is fast
	LerpFac = min(1, LerpFac);
	
	FinalColor = lerp(current, chistory, LerpFac);
}
	
void output(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float3 FinalColor : SV_Target0)
{
	float4 Background, Reflection; float3 albedo, BGOG, normal; float2 AO; float depth, Fresnel;
	
	Background   = tex2D(sTexColor, texcoord).rgba;
	depth        = LDepth(texcoord);
	if(depth>=SkyDepth){FinalColor = Background.rgb;} else{
	BGOG		 = Background.rgb;
	Reflection   = tex2D(sSSSR_FilterTex3, texcoord).rgba;
	
	if(!GI){
	normal = tex2D(sSSSR_NormTex, texcoord).rgb;
	Fresnel      = lerp(0.05, 1, (pow(abs(1 - dot(normal, normalize(UVtoPos (texcoord)))), lerp(EXP, 0, roughness))));}
	
	if(GI){
	AO.r = saturate(Reflection.a / AO_Radius_Background);
	AO.g = saturate(Reflection.a / AO_Radius_Reflection);
	AO = pow(max(AO, 0.0), AO_Intensity);}
	
	if(GI)if(LinearConvert) Reflection.rgb = pow(abs(Reflection.rgb), 2.2);
	Reflection.rgb = Tonemapper(Reflection.rgb);
	
	Reflection.rgb = lerp(lum(Reflection.rgb), Reflection.rgb, SatExp.r);
	Reflection.rgb *= SatExp.g;
	
	albedo = lerp(Background.rgb, Background.rgb/dot(Background.rgb, 1), 0);
	
	if(debug==1)Background.rgb = (GI)?0.5:0;
	if(GI)FinalColor = lerp(AO.r*Background.rgb + Reflection.rgb*Background.rgb*AO.g, Background.rgb, (HLFix&&!debug==1)?pow(abs(Background.rgb),1.5):0);
	else  FinalColor = lerp( lerp(Background.rgb, Reflection.rgb, Fresnel), Background.rgb,  (HLFix&&!debug==1)?pow(abs(Background.rgb),1.5):0);
	if(debug==0)FinalColor = lerp(FinalColor, BGOG.rgb, pow(abs(depth), InvTonemapper(depthfade)));}
	if(debug==2)FinalColor = depth;
	if(debug==3)FinalColor = tex2D(sSSSR_NormTex, texcoord).rgb * 0.5 + 0.5;
	if(debug==4)FinalColor = tex2D(sSSSR_HLTex1, texcoord).r/MAX_Frames;
	//FinalColor =
	if(depth==0)FinalColor = BGOG;
}

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////
///////////////Techniques//////////////////
