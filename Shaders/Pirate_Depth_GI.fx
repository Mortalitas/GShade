////////////////////////////////////////////////////////
// Pirate Depth GI
// Author: Heathen
// Repository: https://github.com/Heathen/Pirate-Shaders
////////////////////////////////////////////////////////

//===================================================================================================================
//Preprocess Settings
#ifndef GI_DEPTH_MIPLEVELS
	#define GI_DEPTH_MIPLEVELS		11	//[>1] Mip levels to increase speed at the cost of quality
#endif
#ifndef GI_DEPTH_TEXTURE_QUALITY
	#define GI_DEPTH_TEXTURE_QUALITY		1.0	//[>0.0] 1.0 - Screen resolution. Lowering this might ruin the AO precision. Go from 1.0 to AO texture quality.
#endif
#ifndef GI_DIFFUSE_PASSES
	#define GI_DIFFUSE_PASSES		4	//[>1] Number of passes in the shader.
#endif
#ifndef GI_TEXTURE_QUALITY
	#define GI_TEXTURE_QUALITY 		1.0	//[>0.0] 1.0 - Screen resolution.
#endif
#ifndef GI_VECTOR_MODE
	#define GI_VECTOR_MODE			2	//[0, 1, or 2] 0 - Static, 1 - Depth based (Avoids still patterns), 2 - Depth based with random length, noisier but avoids interference patterns.
#endif
#ifndef GI_VARIABLE_MIPLEVELS
	#define GI_VARIABLE_MIPLEVELS 		0	//[0 or 1] 0 - Manual miplevel set in the shader config. 1 - Automatic miplevels.
#endif
#include "ReShade.fxh"

//===================================================================================================================
uniform float GI_DIFFUSE_RADIUS <
	ui_label = "GI - Radius";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 200.0;
	> = 1.0;
uniform float GI_DIFFUSE_STRENGTH <
	ui_label = "GI - Diffuse - Strength";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 30.0;
	> = 4.0;
#if (GI_VARIABLE_MIPLEVELS == 0)	
uniform int GI_DIFFUSE_MIPLEVEL <
	ui_label = "GI - Diffuse - Miplevel";
	ui_type = "slider";
	ui_min = 0; ui_max = GI_DEPTH_MIPLEVELS;
	> = 4;
#endif
uniform int GI_DIFFUSE_CURVE_MODE <
	ui_label = "GI - Diffuse - Curve Mode";
	ui_type = "combo";
	ui_items = "Linear\0Squared\0Log\0Sine\0Mid Range Sine\0";
	> = 4;
uniform int GI_DIFFUSE_BLEND_MODE <
	ui_label = "GI - Diffuse - Blend Mode";
	ui_type = "combo";
	ui_items = "Linear\0Screen\0Soft Light\0Color Dodge\0Hybrid\0";
	> = 2;
uniform float GI_REFLECT_RADIUS <
	ui_label = "GI - Reflection - Radius";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 200.0;
	> = 1.0;
uniform int GI_DIFFUSE_DEBUG <
	ui_label = "GI - Debug";
	ui_type = "combo";
	ui_items = "None\0Color\0Gatherer\0";
	> = 0;
uniform int GI_FOV <
	ui_label = "FoV";
	ui_type = "slider";
	ui_min = 10; ui_max = 90;
	> = 75;

//===================================================================================================================
texture2D	TexGINormalDepth {Width = BUFFER_WIDTH * GI_DEPTH_TEXTURE_QUALITY; Height = BUFFER_HEIGHT * GI_DEPTH_TEXTURE_QUALITY; Format = RGBA16; MipLevels = GI_DEPTH_MIPLEVELS;};
sampler2D	SamplerGIND {Texture = TexGINormalDepth; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};

texture2D	TexGI {Width = BUFFER_WIDTH * GI_TEXTURE_QUALITY; Height = BUFFER_HEIGHT * GI_TEXTURE_QUALITY; Format = RGBA8;};
sampler2D	SamplerGI {Texture = TexGI; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; AddressU = Clamp; AddressV = Clamp;};
//===================================================================================================================
float GetRandom(float2 co)
{
	// From http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
	return frac(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
}

float2 GetRandomVector(float2 coords)
{
	return normalize(float2(GetRandom(coords)*2-1, GetRandom(1.42 * coords)*2-1));
}

float2 Rotate45(float2 coords) {
	#define sincos45 0.70710678118
	float x = coords.x * sincos45;
	float y = coords.y * sincos45;
	return float2(x - y, x + y);
}

float2 Rotate90(float2 coords)
{
	return float2(-coords.y, coords.x);
}

float3 EyeVector(float3 vec)
{
	vec.xy = vec.xy * 2.0 - 1.0;
	vec.x -= vec.x * (1.0 - vec.z) * sin(radians(GI_FOV));
	vec.y -= vec.y * (1.0 - vec.z) * sin(radians(GI_FOV * (ReShade::PixelSize.y / ReShade::PixelSize.x)));
	return vec;
}

float3 BlendScreen(float3 a, float3 b)
{
	return 1 - ((1 - a) * (1 - b));
}

float3 BlendSoftLight(float3 a, float3 b)
{
	return (1 - 2 * b) * pow(a, 2) + 2 * b * a;
}

float3 BlendColorDodge(float3 a, float3 b)
{
	return a / (1 - b);
}

//===================================================================================================================
float4 PS_DepthPrePass(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	const float2 offsety = float2(0.0, ReShade::PixelSize.y);
  	const float2 offsetx = float2(ReShade::PixelSize.x, 0.0);
	
	float pointdepth = saturate(ReShade::GetLinearizedDepth(texcoord));
	#define NORMAL_MODE 2
	
	#if (NORMAL_MODE == 0) 
	const float3 p = EyeVector(float3(texcoord, pointdepth));
	float3 py1 = EyeVector(float3(texcoord + offsety, saturate(ReShade::GetLinearizedDepth(texcoord + offsety)))) - p;
  	float3 px1 = EyeVector(float3(texcoord + offsetx, saturate(ReShade::GetLinearizedDepth(texcoord + offsetx)))) - p;
	#elif (NORMAL_MODE == 1) 
	float3 py1 = EyeVector(float3(texcoord + offsety, saturate(ReShade::GetLinearizedDepth(texcoord + offsety)))) - EyeVector(float3(texcoord - offsety, GetDepth(texcoord - offsety)));
  	float3 px1 = EyeVector(float3(texcoord + offsetx, saturate(ReShade::GetLinearizedDepth(texcoord + offsetx)))) - EyeVector(float3(texcoord - offsetx, GetDepth(texcoord - offsetx)));
	#elif (NORMAL_MODE == 2)
	const float3 p = EyeVector(float3(texcoord, pointdepth));
	float3 py1 = EyeVector(float3(texcoord + offsety, saturate(ReShade::GetLinearizedDepth(texcoord + offsety)))) - p;
	const float3 py2 = p - EyeVector(float3(texcoord - offsety, saturate(ReShade::GetLinearizedDepth(texcoord - offsety))));
  	float3 px1 = EyeVector(float3(texcoord + offsetx, saturate(ReShade::GetLinearizedDepth(texcoord + offsetx)))) - p;
	const float3 px2 = p - EyeVector(float3(texcoord - offsetx, saturate(ReShade::GetLinearizedDepth(texcoord - offsetx))));
	py1 = lerp(py1, py2, abs(py1.z) > abs(py2.z));
	px1 = lerp(px1, px2, abs(px1.z) > abs(px2.z));
	#endif
  
  	return float4((normalize(cross(py1, px1)) + 1.0) * 0.5, pointdepth);
}

float4 PS_GIDiffuse(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	float4 res;
	float4 pointnd = tex2D(SamplerGIND, texcoord);
	if (pointnd.w == 1.0) return 0.0;
	pointnd.xyz = (pointnd.xyz * 2.0) - 1.0;

	const float3 pointvector = EyeVector(float3(texcoord, pointnd.w));

	#if (GI_VECTOR_MODE == 0)
	float2 randomvector = GetRandomVector(texcoord);
	#elif (GI_VECTOR_MODE == 1)
	float2 randomvector = GetRandomVector(texcoord * pointnd.w);
	#elif (GI_VECTOR_MODE == 2)
	float2 randomvector = GetRandomVector(texcoord * pointnd.w) * (0.5 + GetRandom(texcoord)/2);
	#endif

	float2 psize = lerp(GI_DIFFUSE_RADIUS, 1.0, pow(abs(pointnd.w), 0.25)) * ReShade::PixelSize;
	psize /= GI_TEXTURE_QUALITY;

	for(int p=1; p <= GI_DIFFUSE_PASSES; p++)
	{
		float2 coordmult = psize * p;
		#if GI_VARIABLE_MIPLEVELS
		int miplevel = round(smoothstep(1, GI_DIFFUSE_PASSES, p) * GI_DEPTH_MIPLEVELS);
		#endif
		
		for(int i=0; i < 4; i++)
		{
			randomvector = Rotate90(randomvector);
			float2 tapcoord = texcoord + randomvector * coordmult;
			#if GI_VARIABLE_MIPLEVELS
			float4 tapnd = tex2Dlod(SamplerGIND, float4(tapcoord, 0, miplevel));
			#else
			float4 tapnd = tex2Dlod(SamplerGIND, float4(tapcoord, 0, GI_DIFFUSE_MIPLEVEL));
			#endif
			tapnd.xyz = (tapnd.xyz * 2.0) - 1.0;
			if (tapnd.w == 1.0) continue;
			float3 tapvector = EyeVector(float3(tapcoord, tapnd.w));

			float3 pttvector = tapvector - pointvector;
				
			float weight = (1.0 - max(0.0, dot(pointnd.xyz, tapnd.xyz))); // How much normals are facing each other
			weight *= max(0.0, -dot(normalize(pttvector), tapnd.xyz)); // How much the normal is facing the center point
			weight *= saturate(coordmult.x - abs(pttvector.z)) / coordmult.x; // Z distance
			float3 coltap = tex2Dlod(ReShade::BackBuffer, float4(tapcoord, 0, 0)).rgb;
			res.rgb += coltap * weight;
			res.w += weight;
		}
		randomvector = Rotate45(randomvector);
	}

	res /= 4 * GI_DIFFUSE_PASSES;
	
	return res;
}

#define threepitwo 4.71238898038f
#define pi 3.14159265358
float4 PS_GICombine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : COLOR
{
	float4 diffuse = tex2D(SamplerGI, texcoord);
	float4 res = tex2D(ReShade::BackBuffer, texcoord);

	//if (GI_DIFFUSE_CURVE_MODE == 0) // Linear
		//Do Nothing
	if (GI_DIFFUSE_CURVE_MODE == 1) // Squared
		diffuse = pow(diffuse, 2);
	else if (GI_DIFFUSE_CURVE_MODE == 2) // Logarithm
		diffuse = log10(diffuse * 10.0);
	else if (GI_DIFFUSE_CURVE_MODE == 3) // Sine
		diffuse = (sin(threepitwo + diffuse * pi) + 1) / 2;
	else if (GI_DIFFUSE_CURVE_MODE == 4) // Mid range Sine
		diffuse = sin(diffuse * pi);
	diffuse = saturate(diffuse * GI_DIFFUSE_STRENGTH);

	if (GI_DIFFUSE_BLEND_MODE == 0) // Linear
		res.rgb += diffuse.rgb;
	else if (GI_DIFFUSE_BLEND_MODE == 1) // Screen
		res.rgb = BlendScreen(res.rgb, diffuse.rgb);
	else if (GI_DIFFUSE_BLEND_MODE == 2) // Soft Light
		res.rgb = BlendSoftLight(res.rgb, 0.5 + diffuse.rgb);
	else if (GI_DIFFUSE_BLEND_MODE == 3) // Color Dodge
		res.rgb = BlendColorDodge(res.rgb, diffuse.rgb);
	else // Hybrid based on point brightness
		res.rgb = lerp(res.rgb + diffuse.rgb, res.rgb * (1.0 + diffuse.rgb), dot(res.rgb, 0.3333));
	

	if (GI_DIFFUSE_DEBUG == 1)
		res.rgb = diffuse.rgb;
	else if (GI_DIFFUSE_DEBUG == 2)
		res.rgb = diffuse.w;

	return float4(res.rgb, 1.0);
}
//===================================================================================================================
technique Pirate_GI
{
	pass DepthPre
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_DepthPrePass;
		RenderTarget = TexGINormalDepth;
	}
	pass Diffuse
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_GIDiffuse;
		RenderTarget = TexGI;
	}
	pass GITest
	{
		VertexShader = PostProcessVS;
		PixelShader  = PS_GICombine;
	}
}