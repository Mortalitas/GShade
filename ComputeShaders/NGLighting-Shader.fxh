//Stochastic Screen Space Ray Tracing
//Written by MJ_Ehsan for Reshade
//Version 0.8

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
//7- [v]Add second temporal pass after second spatial pass.
//8- [o]Add Spatiotemporal upscaling. have to either add jitter to the RayMarching pass or a checkerboard pattern.
//9- [v]Add Smooth Normals.
//10-[v]Use pre-calulated blue noise instead of white. From Nvidia's SpatioTemporal Blue Noise sequence
//11-[v]Add depth awareness to smooth normals. To do so, add depth in the alpha channel of 
//	  NormTex and NormTex1 for optimization.
//12-[ ]Make normal based edge awareness of all passes based on angular distance of the 2 normals.
//13-[ ]Make sample distance of smooth normals exponential.
//14-[ ]

///////////////Include/////////////////////

#include "ReShade.fxh"
#include "NGLightingUI.fxh"

uniform float Timer < source = "timer"; >;
uniform float Frame < source = "framecount"; >;

static const float2 pix = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

#define LDepth ReShade::GetLinearizedDepth

#define FAR_PLANE RESHADE_DEPTH_LINEARIZATION_FAR_PLANE 

#define PI 3.1415927
static const float PI2div360 = PI/180;
#define rad(x) x*PI2div360
///////////////Include/////////////////////
///////////////PreProcessor-Definitions////

#include "NGLighting-Configs.fxh"

///////////////PreProcessor-Definitions////
///////////////Textures-Samplers///////////

texture TexColor : COLOR;
sampler sTexColor {Texture = TexColor; SRGBTexture = false;};

texture TexDepth : DEPTH;
sampler sTexDepth {Texture = TexDepth;};

texture SSSR_BlueNoise <source="BlueNoise-64frames128x128.png";> { Width = 1024; Height = 1024; Format = RGBA8;};
sampler sSSSR_BlueNoise { Texture = SSSR_BlueNoise; AddressU = REPEAT; AddressV = REPEAT; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler SamplerMotionVectors { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

texture SSSR_ReflectionTex  { Width = BUFFER_WIDTH*RESOLUTION_SCALE_; Height = BUFFER_HEIGHT*RESOLUTION_SCALE_; Format = RGBA16f; };
sampler sSSSR_ReflectionTex { Texture = SSSR_ReflectionTex; };

texture SSSR_HitDistTex { Width = BUFFER_WIDTH*RESOLUTION_SCALE_; Height = BUFFER_HEIGHT*RESOLUTION_SCALE_; Format = R16f; MipLevels = 7; };
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

texture SSSR_MaskRoughTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG8; };
sampler sSSSR_MaskRoughTex { Texture = SSSR_MaskRoughTex; };

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

float GetSpecularDominantFactor(float NoV, float roughness)
{
	float a = 0.298475 * log(39.4115 - 39.0029 * roughness);
	float f = pow(saturate(1.0 - NoV), 10.8649)*(1.0 - a) + a;
	
	return saturate(f);
}

float GetHLDivion(in float HL)
{
	return HL * ((IT_Intensity > 0.99) ? 1 : 1);
	//return 0;
}

float2 GetPixelSize(in float HL)
{
	float2 DepthSize = tex2Dsize(sTexDepth) / BUFFER_SCREEN_SIZE;
	
	HL = GetHLDivion(HL);
	float2 ColorSize = rcp(RESOLUTION_SCALE_);
	float lod = min(NGLi_MAX_MipFilter, max(0, (NGLi_MAX_MipFilter)-HL));
	ColorSize /= exp2(lod);
	float2 MinResRcp = max(ColorSize, DepthSize);
	
	return MinResRcp;
}

float2 GetPixelSizeWithMip(in float mip)
{
	float2 DepthSize = tex2Dsize(sTexDepth) / BUFFER_SCREEN_SIZE;
	
	float2 ColorSize = rcp(RESOLUTION_SCALE_);
	ColorSize /= exp2(mip);
	
	float2 MinResRcp = max(ColorSize, DepthSize);
	
	return MinResRcp;
}

float2 sampleMotion(float2 texcoord)
{
    return tex2D(SamplerMotionVectors, texcoord).rg;
}

float WN(float2 co)
{
  return frac(sin(dot(co.xy ,float2(1.0,73))) * 437580.5453);
}

float3 WN3dts(float2 co, float HL)
{
	co += (Frame%HL)/120.3476687;
	//co += s/16.3542625435332254;
	return float3( WN(co), WN(co+0.6432168421), WN(co+0.19216811));
}

float IGN(float2 n)
{
    float f = 0.06711056 * n.x + 0.00583715 * n.y;
    return frac(52.9829189 * frac(f));
}

float3 IGN3dts(float2 texcoord, float HL)
{
	float3 OutColor;
	float2 seed = texcoord*BUFFER_SCREEN_SIZE+(Frame%HL)*5.588238;
	OutColor.r = IGN(seed);
	OutColor.g = IGN(seed + 5.588238 * 64);
	OutColor.b = IGN(seed + 5.588238 * 128);
	return OutColor;
}

float3 BN3dts(float2 texcoord, float HL)
{
	texcoord *= BUFFER_SCREEN_SIZE; //convert to pixel index
	
	texcoord = texcoord%128; //limit to texture size
	
	float frame = Frame%MAX_Frames; //limit frame index to history length
	int2 F;
	F.x = frame%8; //Go from left to right each frame. start over after 8th
	F.y = floor(frame/8)%8; //Go from top to buttom each 8 frame. start over after 8th
	F *= 128; //Each step jumps to the next texture 
	texcoord += F;
	
	texcoord /= 1024; //divide by atlas size
	float3 Tex = tex2D(sSSSR_BlueNoise, texcoord).rgb;
	return Tex;
}

float3 UVtoPos(float2 texcoord)
{
	float3 scrncoord = float3(texcoord.xy*2-1, LDepth(texcoord) * FAR_PLANE);
	scrncoord.xy *= scrncoord.z;
	scrncoord.xy *= NGAspectRatio;
	scrncoord.xy *= rad(fov);
	//scrncoord.xy *= ;
	
	return scrncoord.xyz;
}

float3 UVtoPos(float2 texcoord, float depth)
{
	float3 scrncoord = float3(texcoord.xy*2-1, depth * FAR_PLANE);
	scrncoord.xy *= scrncoord.z;
	scrncoord *= NGAspectRatio;
	scrncoord *= rad(fov);
	//scrncoord.xy *= ;
	
	return scrncoord.xyz;
}

float2 PostoUV(float3 position)
{
	float2 scrnpos = position.xy;
	scrnpos /= rad(fov);
	scrnpos /= NGAspectRatio;
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

float lum(in float3 color)
{
	return (color.r+color.g+color.b)/3;
}

float GetRoughTex(float2 texcoord)
{
	float2 p = pix;
	
	if(!GI)
	{
		//depth threshold to validate samples
		const float Threshold = 0.02;
		
		//calculating curve and levels
		float roughfac; float2 fromrough, torough;
		roughfac = (1 - roughness);
		fromrough.x = lerp(0, 0.1, saturate(roughness*10));
		fromrough.y = 0.8;
		torough = float2(0, pow(max(roughness, 0.0), roughfac));
		
		float3 center = toYCC(tex2D(sTexColor, texcoord).rgb);
		float depth = LDepth(texcoord);

		float Roughness = 0.0;
		//cross (+)
		float2 offsets[4] = {float2(p.x,0), float2(-p.x,0),float2( 0,-p.y),float2(0,p.y)};
		[unroll]for(int x; x < 4; x++)
		{
			float2 SampleCoord = texcoord + offsets[x];
			float  SampleDepth = LDepth(SampleCoord);
			if(abs(SampleDepth - depth) < Threshold)
			{
				float3 SampleColor = toYCC(tex2D( sTexColor, SampleCoord).rgb);
				SampleColor = min(abs(center.g - SampleColor.g), 0.25);
				Roughness += SampleColor.r;
			}
		}
		
		Roughness = pow( max(Roughness, 0.0), roughfac*0.66);
		Roughness = clamp(Roughness, fromrough.x, fromrough.y);
		Roughness = (Roughness - fromrough.x) / ( 1 - fromrough.x );
		Roughness = Roughness / fromrough.y;
		Roughness = clamp(Roughness, torough.x, torough.y);
		
		return saturate(Roughness);
	} 
	return 0;//RoughnessTex
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
    n1 += float3( 0, 0, 1);
    n2 *= float3(-1, -1, 1);
    return n1*dot(n1, n2)/n1.z - n2;
}

static const float LinearGamma = 0.454545;
static const float sRGBGamma = 2.2;

float3 InvTonemapper(float3 color)
{//Timothy Lottes fast_reversible
	if(LinearConvert)color = pow(max(color, 0.0), LinearGamma);
	
	float L = max(max(color.r, color.g), color.b);
	return color / ((1.0 + max(1-IT_Intensity,0.001)) - L);
}

float3 Tonemapper(float3 color)
{//Timothy Lottes fast_reversible
	float L = max(max(color.r, color.g), color.b);
	color = color / ((1.0 + max(1-IT_Intensity,0.001)) + L);
	
	if(LinearConvert)color = pow(max(color, 0.0), sRGBGamma);
	return color;
}

float3 FixWhitePoint()
{
	return rcp(Tonemapper(InvTonemapper(float3(1,1,1))));
}

float InvTonemapper(float color)
{//Reinhardt reversible
	return color / (1.001 - color);
}

float dilate(in sampler color, in float2 texcoord, in float2 p, in float mip)
{
	float result = 99999999;
	p *= GetPixelSize(mip);
	int r = 3;
	[unroll]for(float x = -r; x <= r; x++){
	[unroll]for(float y = -r; y <= r; y++){
		result = min(result, tex2D(color, texcoord + float2(x,y)*p).r);
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

    float2 f  = samplePos - texPos1;
	float2 f2 = f * f;
	float2 hf = f * 0.5;
	float2 hf1= f * 1.5;
    float2 w0 = f * (-0.5f + f * (1.0f - hf));
    float2 w1 = 1.0f + f2 * (-2.5f + hf1);
    float2 w2 = f * (0.5f + f * (2.0f - hf1));
    float2 w3 = f2 * (-0.5f + hf);
	
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

///////////////Functions///////////////////
///////////////Pixel Shader////////////////

void GBuffer1
(
	float4 vpos : SV_Position,
	float2 texcoord : TexCoord,
	out float4 normal : SV_Target0,
	out float2 roughness : SV_Target1) //SSSR_NormTex
{
	normal.rgb = Normal(texcoord.xy);
	normal.a   = LDepth(texcoord.xy);
#if SMOOTH_NORMALS <= 0
	normal.rgb = blend_normals( Bump(texcoord, BUMP), normal.rgb);
#endif
	roughness = float2(0.0, GetRoughTex(texcoord));
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

void DoRayMarch(float3 noise, float3 position, float3 raydir, out float3 Reflection, out float HitDistance, out float a) 
{
	float3 raypos, Check; float2 UVraypos; float raydepth, steplength; bool hit; uint i;
	float bias = -position.z * rcp(FAR_PLANE);
	
	steplength = 1 + noise.x * STEPNOISE;
	steplength = steplength * 10 * position.z * rcp(FAR_PLANE);
	
	raypos = position + raydir * steplength;
	raydepth = -RAYDEPTH;
	
	[loop]for( i = 0; i < UI_RAYSTEPS; i++)
	{
			UVraypos = PostoUV(raypos);
			Check = UVtoPos(UVraypos) - raypos;
			
			hit = Check.z < bias && Check.z > raydepth * steplength;
			if(hit)
			{
				a=1; a *= UVraypos.y >= 0;
				i += UI_RAYSTEPS;
			}
			if(TemporalRefine&&Check.z < 0) i += UI_RAYSTEPS;
			
			raypos += raydir * steplength;
			steplength *= RAYINC;
	}
	
	Reflection = tex2D(sTexColor, UVraypos.xy).rgb*a;
	
	if(IsSaturatedStrict(UVraypos.xy)) Reflection = 0;
	HitDistance = distance(raypos, position);
}

void RayMarch(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0, out float4 HitDistance : SV_Target1)
{
	float4 Geometry = tex2D(sSSSR_NormTex, texcoord); 
	HitDistance = 0;
	FinalColor.rgba = float4(tex2D(sTexColor, texcoord).rgb, 0);
	if(Geometry.w<SkyDepth)
	{
		float Roughness = tex2D(sSSSR_MaskRoughTex, texcoord).y; 
		float HL = max(1, tex2D(sSSSR_HLTex0, texcoord).r);
		
		float3 BlueNoise  = BN3dts(texcoord, HL);
		float3 IGNoise    = IGN3dts(texcoord, HL); //Interleaved Gradient Noise
		float3 WhiteNoise = WN3dts(texcoord, HL);
		
		float3 noise = (HL <= 3) ? IGNoise :
					   (HL > 64) ? WhiteNoise :
								   BlueNoise;
		
		float3 position = UVtoPos (texcoord);
		float3 normal   = Geometry.xyz;
		float3 eyedir   = normalize(position);
		
		float3 raydirG   = reflect(eyedir, normal);
		float3 raydirR   = normalize(noise*2-1);
		if(dot(raydirR, Normal(texcoord))>0) raydirR *= -1;
		
		float raybias    = dot(raydirG, raydirR);
		
		float3 raydir;
		float4 reflection;
		float a;
		if(!GI)raydir = lerp(raydirG, raydirR, pow(max(1-(0.5*cos(raybias*PI)+0.5), 0.0), rsqrt(InvTonemapper((GI)?1:Roughness))));
		else raydir = raydirR;
		
		//Dots and shit
		float3 H    = normalize(raydir + eyedir);
		float NdotH = dot(normal, H);
		float VdotH = dot(eyedir, H);
		float NdotL = dot(normal, raydir);
		float LdotV = dot(raydir, eyedir);
		float NdotV = dot(normal, eyedir);
		float F0    = 0.04; //reflectance at 0deg angle
		
		DoRayMarch(IGNoise, position, raydir, reflection.rgb, HitDistance.r, a);
		//reflection *= ggx_smith_brdf(NdotL, NdotV, NdotH, VdotH, F0, Roughness*Roughness, texcoord);
		
		FinalColor.rgb = reflection.rgb;
		FinalColor.rgb = InvTonemapper(FinalColor.rgb);
		
		if(!GI)FinalColor.a = a;
		
		float AORadius = rcp(max(1, max(AO_Radius_Reflection, AO_Radius_Background)));

		if( GI)FinalColor.a = saturate((HitDistance.r)*20*AORadius/FAR_PLANE);
		FinalColor.rgb *= a;
	}//depth check if end
}//ReflectionTex

void TemporalFilter0(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float mask : SV_Target0)
{//Writes the mask to a texture. Then the texture will be dilated in the next pass to avoid masking edges when camera jitters
	float depth = LDepth(texcoord);
	if(depth>SkyDepth){mask=1;}else{
	float4 past_normal; float3 normal, ogcolor, past_ogcolor; float2 MotionVectors; float2 outbound; float past_depth, HistoryLength;
	//Inputs
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
	mask = abs(lum(normal) - lum(past_normal.rgb)) * 1
		 + abs(depth - past_depth)				 * 1
		 + abs(ogcolor.g - past_ogcolor.g)  	   * 1
		 > Tthreshold;
	}//sky mask end
}

void TemporalFilter1(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0, out float HLOut : SV_Target1)
{
	float depth = LDepth(texcoord);
	float4 Current, History; float3 Xvirtual, eyedir; float2 MotionVectors, p, pixelUvVirtualPrev; float past_depth, mask, HistoryLength;
	
	if(Tthreshold<1)MotionVectors = sampleMotion(texcoord);
	HistoryLength = tex2D(sSSSR_HLTex1, texcoord + MotionVectors).r;
	p = pix;
	float Roughness = tex2D(sSSSR_MaskRoughTex, texcoord).y;
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
		SDF      = GetSpecularDominantFactor(NoV, Roughness);
		HitDist  = tex2D(sSSSR_HitDistTex, texcoord);
		Xvirtual = HitDist.rgb - eyedir * HitDist.a;
		pixelUvVirtualPrev = PostoUV( gWorldToClipPrev.rgb + Xvirtual/1000);
	}
#endif
	float2 outbound = texcoord + MotionVectors;
	outbound = float2(max(outbound.r, outbound.g), min(outbound.r, outbound.g));
	outbound.rg = (outbound.r > 1 || outbound.g < 0);
	
	mask = dilate(sSSSR_MaskRoughTex, texcoord, p, 0).x;
	mask = 1-max(outbound.r, mask);
	//mask = tex2D(sSSSR_MaskRoughTex, texcoord);
	HistoryLength = tex2D(sSSSR_HLTex1, texcoord + MotionVectors).r;

	Current = tex2Dcatrom(sSSSR_ReflectionTex, texcoord, BUFFER_SCREEN_SIZE*RESOLUTION_SCALE_).rgba;
	History = tex2D(sSSSR_FilterTex1, texcoord + MotionVectors);

	HistoryLength *= mask;             //sets the history length to 0 for discarded samples
	HLOut = HistoryLength + mask;      //+1 for accepted samples
	HLOut = min(HLOut, MAX_Frames      //Limits the linear accumulation to MAX_Frames, The rest will be accumulated exponentialy with the speed = (1-1/Max_Frames)
		  * max(sqrt((GI)?1:Roughness),//Weaker hisotry for lower roughness
		    max(0.0001, STEPNOISE)));  //Weaker for low stepnoise
		    
	//HLOut *= 1-saturate(10 * (1-Tthreshold) * abs(normalize(tex2D(sSSSR_FilterTex3, texcoord + MotionVectors).rgb).b - normalize(History.rgb).b));
	
	if(!GI)HLOut = HLOut
				 * max(saturate(1 - length(MotionVectors) //Weaker history for faster movements
				 * (1 - sqrt(Roughness))                  //More effective on lower roughnesses
				 * MBSDMultiplier), 					  //Motion Based Deghosting Multiplier
				   MBSDThreshold);						//Motion Based Deghosting Max Threshold
	
	HLOut = max(HLOut, 0.001);
	if( TemporalRefine)FinalColor = lerp(History, Current, min((Current.a != 0) ? 1/HLOut : TRThreshold, mask));
	if(!TemporalRefine)FinalColor = lerp(History, Current, min(                   1/HLOut,         	  mask));
	FinalColor = (mask||depth==0)?FinalColor:Current;
	if(MAX_Frames>128)FinalColor += (BN3dts(texcoord, HLOut).r-0.5)/255;
}

bool CheckBilinearize(float HLOut)
{
	return (HLOut < VeryLarge)
		|| (HLOut < Medium && HLOut >= Large)
		|| (HLOut < VerySmall && HLOut >= Small);
}

float GetRoughness(float2 texcoord)
{ return tex2D(sSSSR_MaskRoughTex, texcoord).y;}

float GetHitDistanceAdaptation(float2 texcoord, float Roughness)
{
	float HD = tex2Dlod(sSSSR_HitDistTex, float4(texcoord, 0, 5)).r;
	HD = lerp(saturate(4 * HD * rcp(FAR_PLANE)), 1, Roughness);
	return HD;
}

void GetNormalAndDepthFromGeometry(in float2 texcoord, out float3 Normal, out float Depth)
{
	float4 Geometry = tex2D(sSSSR_NormTex, texcoord);
	Normal = Geometry.rgb;
	Depth = Geometry.a;
}

//mode 0 is specular. mode 1 is diffuse
//size 0 is for SF 0. size 1 is for SF 1.
//Tex is the sampler of the texture that should recieve the filter.
float4 AdaptiveBox(in int size, in sampler Tex, in float2 texcoord, in float HLOut)
{
	float2 p = pix;// p *= IT_Intensity>=0.97?2:1;
	float radius = 1;
	bool Bilinearize = CheckBilinearize(HLOut);
	float Roughness = 1;
	
	float3 normal; float depth;
	GetNormalAndDepthFromGeometry(texcoord, normal, depth);
	
	float ST = Sthreshold;
	if(HLOut < HistoryFix1 && MAX_Frames > HistoryFix1)ST *= 10;
	
	float lod = min(NGLi_MAX_MipFilter, max(0, (NGLi_MAX_MipFilter)-HLOut));
	
	if(Bilinearize) p *=
		(size==0) ? 5  :
		(size==2) ? 15 :
				    1.5;
	else p *=
		(size==0) ? 3:
		(size==2) ? 9:
					1;

	p *= rcp(RESOLUTION_SCALE_);
	
	if(!GI)
	{
		Roughness = GetRoughness(texcoord);
		float HitDistance = GetHitDistanceAdaptation(texcoord, Roughness);
		radius = saturate(Roughness * 8) * (HitDistance);
		lod *= radius * saturate(Roughness);
		p *= radius;
	}

	p *= exp2(lod);
	
	float2 offset[8];
	float  weight[8];
	offset = {
		float2(-p.x,-p.y),float2(0, p.y),float2( p.x,-p.y),
		float2(-p.x,   0),			   float2( p.x,   0),
		float2(-p.x, p.y),float2(0,-p.y),float2( p.x, p.y)};
	
	if(Bilinearize&&size==1)//corners:4, edges: 2, center: 1
	weight = {4,2,4,2,2,4,2,4};
	else //all: 1
	weight = {1,1,1,1,1,1,1,1};

	float4 color = tex2Dlod(Tex, float4(texcoord, 0, lod));
	int samples = 1;
	[unroll]for(int i = 0; i <= 7; i++)
	{
		offset[i].xy += texcoord;
		
		float3 snormal; float sdepth;
		GetNormalAndDepthFromGeometry(offset[i], snormal, sdepth);
 
		float sRoughness = 1;
		if(!GI)sRoughness = GetRoughness(offset[i]);
			
		bool determinator = lum(abs(snormal    - normal)) +
								abs(sdepth     - depth )  +
								abs(sRoughness - Roughness) *1 < ST;
		if(determinator)
		{
			color += tex2Dlod(Tex, float4(offset[i].xy, 0, lod)) * weight[i];
			samples += weight[i];
		}
	}
	color /= samples;
	return color;
}

void SpatialFilter0( in float4 vpos : SV_Position, in float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0)
{
	float HLOut = tex2D(sSSSR_HLTex0, texcoord).r;
	float HL = GetHLDivion(HLOut);
	if(HL<Large&&Sthreshold>0)
	{
		float4 color = AdaptiveBox(2, sSSSR_FilterTex0, texcoord, HL);
		if(HL > 8)color.a = tex2D(sSSSR_FilterTex0, texcoord).a;
		FinalColor = color;
	}
	else
	{
		FinalColor = tex2D(sSSSR_FilterTex0, texcoord).rgba;
	}
}
		
void SpatialFilter1( in float4 vpos : SV_Position, in float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0)
{
	float HLOut = tex2D(sSSSR_HLTex0, texcoord).r;
	float HL = GetHLDivion(HLOut);
	if(HL<Small&&Sthreshold>0)
	{
		float4 color = AdaptiveBox(0, sSSSR_FilterTex1, texcoord, HL);
		if(HL > 16)color.a = tex2D(sSSSR_FilterTex1, texcoord).a;
		FinalColor = color;
	}
	else
	{
		FinalColor = tex2D(sSSSR_FilterTex1, texcoord).rgba;
	}
}

void SpatialFilter2(
	in  float4 vpos       : SV_Position,
	in  float2 texcoord   : TexCoord,
	out float4 FinalColor : SV_Target0,//FilterTex1
	out float4 Geometry   : SV_Target1,//PNormalTex
	out float3 Ogcol      : SV_Target2,//POGColTex
	out float  HLOut      : SV_Target3,//HLTex1
	out float4 TSHistory  : SV_Target4)//FilterTex2
{
	HLOut = tex2D(sSSSR_HLTex0, texcoord).r;
	float HL = GetHLDivion(HLOut);
	if(HL<Off&&Sthreshold>0)
	{
		float4 color = AdaptiveBox(1, sSSSR_FilterTex0, texcoord, HL);
		color.a = lerp(color.a, tex2D(sSSSR_FilterTex0, texcoord).a, HL > 24 ? 0.3 : 0);
		FinalColor = color;
	}
	else
	{
		FinalColor = tex2D(sSSSR_FilterTex0, texcoord).rgba;
	}
	
	Geometry   = tex2D(sSSSR_NormTex, texcoord);
	TSHistory  = tex2D(sSSSR_FilterTex3, texcoord).rgba;
	Ogcol      = tex2D(sTexColor, texcoord).rgb;
}

void TemporalStabilizer(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float4 FinalColor : SV_Target0)
{
	float HL = tex2D(sSSSR_HLTex0, texcoord).r;
	float2 MinResRcp = GetPixelSize(HL);
	float2 p = pix; p *= MinResRcp;
	
	float Roughness = tex2D(sSSSR_MaskRoughTex, texcoord).y;
	float2 MotionVectors = 0;
	if(Tthreshold<1)MotionVectors = sampleMotion(texcoord);

	float4 current = tex2D(sSSSR_FilterTex1, texcoord);	
	float4 history = tex2Dcatrom(sSSSR_FilterTex2, texcoord +  MotionVectors, BUFFER_SCREEN_SIZE);
	//history.rgb = Tonemapper(history.rgb);
	history.rgb = toYCC(history.rgb);
	
	const int r = 1;
	float4 Max = 0, Min = 1000000;
	float4 SCurrent; int x, y;
	[unroll]for(x = -r; x<=r; x++){
	[unroll]for(y = -r; y<=r; y++){
		SCurrent = tex2D(sSSSR_FilterTex1, texcoord + float2(x,y)*p);
		SCurrent.rgb = toYCC(SCurrent.rgb);
		
		Max = max(SCurrent, Max);
		Min = min(SCurrent, Min);
	}
	}
	
	float ClampIntensity = 1;
	float4 chistory = lerp(history, clamp(history, Min, Max), ClampIntensity);
	float4 diff = saturate((abs(chistory - history)));
	//diff = 0;
	chistory.rgb = toRGB(chistory.rgb);
	//chistory.rgb = InvTonemapper(chistory.rgb);
	
	float2 outbound = texcoord + MotionVectors;
	outbound = float2(max(outbound.r, outbound.g), min(outbound.r, outbound.g));
	outbound.rg = (outbound.r > 1 || outbound.g < 0);
	
	float4 LerpFac = TSIntensity                        //main factor
					*(1 - outbound.r)                   //0 if the pixel is out of boundary
					//*max(0.8, pow(GI ? 1 : Roughness, 1.0)) //decrease if roughness is low
					//*max(0.8, (1 - diff))                  //decrease if the difference between original and clamped history is high
					//*max(0.8, 1 - 5 * length(MotionVectors))  //decrease if movement is fast
					;
	LerpFac = saturate(LerpFac);
	
	FinalColor = lerp(current, chistory, LerpFac);
}
//0.9388342510

float4 sharpen(in sampler Tex, in float2 texcoord, inout float4 GI)
{
	float2 p = pix;
	const float shape = 8;
	float2 offsets[8] = 
	{
		float2(p.x,  0), float2(-p.x,   0), float2(  0,-p.y), float2(   0,p.y),
		float2(p.x,p.y), float2(-p.x,-p.y), float2(p.x,-p.y), float2(-p.x,p.y)
	};
	
	float4 GIsum = GI; float4 Min = min(GI, 1000000), Max = max(GI, 0);
	[unroll]for(int x; x < shape; x++)
	{
		float4 GIsamp = tex2Dlod(Tex, float4(texcoord + offsets[x],0,0)).rgba;
		GIsum += GIsamp;
		
		Min = min(Min, GIsamp);
		Max = max(Max, GIsamp);
	}
	
	GIsum /= shape+1;
	GIsum = GI - GIsum;
	const float overshoot = 0.0;
	GI = clamp(GI + GIsum * 10, Min-overshoot, Max+overshoot);
	
	return 0;
}

void Output(float4 vpos : SV_Position, float2 texcoord : TexCoord, out float3 FinalColor : SV_Target0)
{
	FinalColor = 0;
	float2 p = pix;
	float3 Background = tex2D(sTexColor, texcoord).rgb;
	float  Depth      = LDepth(texcoord);
	float  Roughness  = tex2D(sSSSR_MaskRoughTex, texcoord).y;
	float HL = tex2D(sSSSR_HLTex0, texcoord).r;
	
	//Lighting debug
	if(debug==1)Background = 0.5;
	
	//if(Depth>=SkyDepth)FinalColor = Background;
	if(debug == 0 || debug == 1)
	{
		if(GI)
		{
			float4 GI = tex2D(sSSSR_FilterTex3, texcoord).rgba;
			//Box sharpening to combat TAA blurring. Isn't enough for temporal upscalers.
			if(SharpenGI)sharpen(sSSSR_FilterTex3, texcoord, GI); //Clamps to avoid ringing.
			//Invtonemaps the background so we can blend it with GI in HDR space. Gives better results.
			float3 HDR_Background = InvTonemapper(Background);
			
			//calculate AO Intensity
			float2 AO;
				//When radiis are higher than 1, the inital radius will increase. This value 
			float Div = max(1, max(AO_Radius_Reflection, AO_Radius_Background));
			AO.g = saturate(GI.a * Div / AO_Radius_Reflection);
			AO.r = saturate(GI.a * Div / AO_Radius_Background);
			AO   = saturate(pow(max(AO, 0.0), AO_Intensity));
			
			//modify saturation and exposure
			GI.rgb *= SatExp.g;
			GI.rgb = lerp(lum(GI.rgb), GI.rgb, SatExp.r);
			
			//apply AO
			float3 Img_AO = HDR_Background * AO.r;
			float3  GI_AO = GI.rgb * AO.g;
			//apply GI
			float3 Img_GI = Img_AO + GI_AO * HDR_Background;
			Img_GI = Tonemapper(Img_GI.rgb);
			//fix highlights by reducing the GI intensity
			FinalColor = Img_GI;
		}
		else 
		{
			float3 Reflection = tex2D(sSSSR_FilterTex3, texcoord).rgb;
			
			//calculate Fresnel
			float3 Normal  = tex2D(sSSSR_NormTex, texcoord).rgb;
			float3 Eyedir  = normalize(UVtoPos(texcoord));
			float  Coeff   = pow(abs(1 - dot(Normal, Eyedir)), lerp(EXP, 0, Roughness));
			float  Fresnel = lerp(0.05, 1, Coeff);
			
			//modify saturation and exposure
			Reflection  = lerp(lum(Reflection), Reflection, SatExp.r);
			Reflection *= SatExp.g;
			
			//apply Reflection
			float3 Img_Reflection = lerp(InvTonemapper(Background), Reflection, Fresnel);
			Img_Reflection = Tonemapper(Img_Reflection);
			//fix highlights by reducing the Reflection intensity
			FinalColor = Img_Reflection;
		}
		//Fixes White Point dimming after Inverse/Re-Tonemapping
		FinalColor *= FixWhitePoint();
		//Depth fade curve
		FinalColor = lerp(FinalColor, Background, pow(max(Depth, 0.0), InvTonemapper(depthfade)));
	}
	
	//debug views: depth, normal, history length, roughness
	else if(debug == 2) FinalColor = Depth;
	else if(debug == 3) FinalColor = tex2D(sSSSR_NormTex, texcoord).rgb * 0.5 + 0.5;
	else if(debug == 4) FinalColor = tex2D(sSSSR_HLTex1, texcoord).r/MAX_Frames;
	else if(debug == 5) FinalColor = Roughness;
	
	//Avoids covering menues in black
	if(Depth == 0) FinalColor = Background;
	//FinalColor = normalize(FinalColor);
}
			
			
	

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////
///////////////Techniques//////////////////
