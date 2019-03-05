#include "ReShade.fxh"

//Macros//////////////////////////////////////////////////////////////////////////////////////////////

#ifndef MATCAP_TEX_WIDTH
#define MATCAP_TEX_WIDTH 256
#endif

#ifndef MATCAP_TEX_HEIGHT
#define MATCAP_TEX_HEIGHT 256
#endif

#ifndef MATCAP_FASTNORMALS
#define MATCAP_FASTNORMALS 0
#endif

#if MATCAP_FASTNORMALS
#define GET_NORMALS(uv) get_normals_fast(uv)
#else
#define GET_NORMALS(uv) get_normals(uv)
#endif

//Uniforms////////////////////////////////////////////////////////////////////////////////////////////

uniform bool bDisplayOutlines <
	ui_label = "Display Outlines";
> = false;

uniform float fOutlinesCorrection <
	ui_label = "Outlines Correction";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 1000.0;
	ui_step = 1.0;
> = 20.0;

//Textures////////////////////////////////////////////////////////////////////////////////////////////

texture tMatCap <source="MatCap.png";> { 
	Width = MATCAP_TEX_WIDTH; 
	Height = MATCAP_TEX_HEIGHT; 
};
sampler sMatCap { 
	Texture = tMatCap; 
	AddressU = BORDER; 
	AddressV = BORDER;
};

//Functions///////////////////////////////////////////////////////////////////////////////////////////

float4 _tex2D(sampler2D sp, float2 uv) {
	return tex2Dlod(sp, float4(uv, 0.0, 0.0));
}

float get_lum(float3 col) {
	return max(col.r, max(col.g, col.b));
}

float get_depth(float2 uv) {
	return ReShade::GetLinearizedDepth(uv);
}

float get_depth_ddx(float2 uv) {
	static const float2 offset = float2(BUFFER_RCP_WIDTH, 0.0); // 1 / Width
	return (get_depth(uv + offset) - get_depth(uv - offset)) * BUFFER_WIDTH * 0.5;
}

float get_depth_ddy(float2 uv) {
	static const float2 offset = float2(0.0, BUFFER_RCP_HEIGHT); // 1 / Height
	return (get_depth(uv - offset) - get_depth(uv + offset)) * BUFFER_HEIGHT * 0.5;
}

float3 get_normals(float2 uv) {
	return normalize(float3(
		get_depth_ddx(uv),
		get_depth_ddy(uv),
		get_depth(uv)
	));
}

float3 get_normals_fast(float2 uv) {
	return normalize(float3(
		ddx(get_depth(uv)) * BUFFER_WIDTH,
		ddy(-get_depth(uv)) * BUFFER_HEIGHT,
		get_depth(uv)
	));
}

float3 get_color_ddx(sampler sp, float2 uv) {
	static const float2 offset = float2(BUFFER_RCP_WIDTH, 0.0); // 1 / width
	return (_tex2D(sp, uv + offset).rgb - _tex2D(sp, uv - offset).rgb) * BUFFER_WIDTH * 0.5;
}

float3 get_color_ddy(sampler sp, float2 uv) {
	static const float2 offset = float2(0.0, BUFFER_RCP_HEIGHT); // 1 / width
	return (_tex2D(sp, uv - offset).rgb - _tex2D(sp, uv + offset).rgb) * BUFFER_HEIGHT * 0.5;
}

float3 get_color_normals(sampler sp, float2 uv) {
	return normalize(float3(
		get_lum(get_color_ddx(sp, uv)),
		get_lum(get_color_ddy(sp, uv)),
		0.0
	));
}

float3 blend_screen(float3 a, float3 b, float w) {
	return lerp(a, (1.0 - (1.0 - a) * (1.0 - b)), w);
}

//Shaders/////////////////////////////////////////////////////////////////////////////////////////////

float4 PS_Outlines(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD
) : SV_TARGET {
	float3 col = tex2D(ReShade::BackBuffer, uv).rgb;
	float3 normals = GET_NORMALS(uv);
	
	float outlines = dot(normals, float3(0.0, 0.0, 1.0));
	outlines *= fOutlinesCorrection;
	outlines = saturate(outlines);
	
	float gs = (col.r + col.g + col.b) / 3.0;

	col = bDisplayOutlines ? outlines : col * outlines;

	//col = normals;

	return float4(col, 1.0);
}

float4 PS_DisplayNormals(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD
) : SV_TARGET {
	float3 normals = GET_NORMALS(uv);

	normals = lerp(normals, 1.0, 0.5);

	return float4(normals, 1.0);
}

float4 PS_TextureReplace(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD
) : SV_TARGET {
	//float3 col = tex2D(ReShade::BackBuffer, uv).rgb;
	float3 normals = GET_NORMALS(uv);
	//float2 uv_blend = (uv - normals.xy) * 2.0;
	//float2 uv_blend = (-uv * -normals.z);
	float2 uv_blend = normals.xy;

	float3 col = float3(uv_blend, 0.0);
	//float3 col = tex2D(sMatCap, uv_blend).rgb;

	return float4(col, 1.0);
}

float4 PS_Rainbow(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD
) : SV_TARGET {
	static const float3 arr[9] = {
		float3(0.0, 0.0, 0.0), //black
		float3(1.0, 0.0, 0.0), //red
		float3(1.0, 0.5, 0.0), //orange
		float3(1.0, 1.0, 0.0), //yellow
		float3(0.0, 1.0, 0.0), //green
		float3(0.0, 0.0, 1.0), //blue
		float3(0.3, 0.0, 0.5), //indigo
		float3(0.5, 0.0, 1.0), //violet
		float3(1.0, 1.0, 1.0)  //white
	};
	float3 normals = GET_NORMALS(uv);
	float3 col = arr[int(normals.x + normals.y * 8)];
	return float4(col, 1.0);
}

float4 PS_SmoothNormals(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD
) : SV_TARGET {
	float3 normals_depth = get_normals(uv);
	float3 normals_color = get_color_normals(ReShade::BackBuffer, uv);

	float3 normals_blend = (normals_depth + normals_color) * 0.5;

	float3 col = normals_blend;
	//float3 col = (normals_depth - normals_color) * 0.5;
	
	return float4(col, 1.0);
}

float4 PS_Experimental(
	float4 pos : SV_POSITION,
	float2 uv : TEXCOORD
) : SV_TARGET {
	float3 normals = GET_NORMALS(uv);
	float3 col = tex2D(ReShade::BackBuffer, uv).rgb;
	
	//float fresnel = pow(length(normals.xy), 10.0) * normals.y;
	float fresnel = length(normals.xy) * normals.y;
	
	//float3 sky_color = float3(0.0, 0.5, 1.0);
	float3 sky_color = (tex2D(ReShade::BackBuffer, float2(0.0, 1.0)).rgb
	                 +  tex2D(ReShade::BackBuffer, float2(0.5, 1.0)).rgb
					 +  tex2D(ReShade::BackBuffer, float2(1.0, 1.0)).rgb) / 3.0;

	//col = lerp(col, blend_screen(col, sky_color), saturate(fresnel));
	//col = blend_screen(col, sky_color, saturate(fresnel));
	//col = max(col, sky_color * fresnel);
	//col = col + sky_color * col * fresnel;
	//col = col + col * col * saturate(fresnel);
	//col 

	float3 light  = col + col * col;
	float3 shadow = col * col;

	//col = lerp(shadow, light, saturate(fresnel));

	col = lerp(shadow, light, saturate(fresnel));

	return float4(col, 1.0);
}

//Technique///////////////////////////////////////////////////////////////////////////////////////////

technique MatCap_Outlines {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_Outlines;
	}
}

technique MatCap_DisplayNormals {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_DisplayNormals;
	}
}

technique MatCap_Rainbow {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_Rainbow;
	}
}

technique MatCap_TextureReplace {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_TextureReplace;
	}
}

technique MatCap_SmoothNormals {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_SmoothNormals;
	}
}

technique MatCap_Experimental {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_Experimental;
	}
}
