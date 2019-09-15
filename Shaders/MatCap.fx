// Lightly optimized by Marot Satil for the GShade project.
#include "ReShade.fxh"

//Macros//////////////////////////////////////////////////////////////////////////////////////////////

#define GET_NORMALS(uv) get_normals(uv)

//Uniforms////////////////////////////////////////////////////////////////////////////////////////////

uniform bool bDisplayOutlines <
	ui_label = "Display Outlines";
> = false;

uniform float fOutlinesCorrection <
	ui_label = "Outlines Correction";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1000.0;
	ui_step = 0.1;
> = 20.0;

//Functions///////////////////////////////////////////////////////////////////////////////////////////

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

//Shaders/////////////////////////////////////////////////////////////////////////////////////////////

float4 PS_Outlines(
	const float4 pos : SV_POSITION,
	const float2 uv : TEXCOORD
) : SV_TARGET {
	float3 col = tex2D(ReShade::BackBuffer, uv).rgb;
	const float3 normals = GET_NORMALS(uv);
	
	float outlines = dot(normals, float3(0.0, 0.0, 1.0));
	outlines *= fOutlinesCorrection;
	outlines = saturate(outlines);
	
	const float gs = (col.r + col.g + col.b) / 3.0;

	if (bDisplayOutlines)
		col = outlines;
	else
		col = col * outlines;

	//col = normals;

	return float4(col, 1.0);
}

float4 PS_Experimental(
	const float4 pos : SV_POSITION,
	const float2 uv : TEXCOORD
) : SV_TARGET {
	const float3 normals = GET_NORMALS(uv);
	float3 col = tex2D(ReShade::BackBuffer, uv).rgb;
	
	//float fresnel = pow(length(normals.xy), 10.0) * normals.y;
	const float fresnel = length(normals.xy) * normals.y;
	
	//float3 sky_color = float3(0.0, 0.5, 1.0);
	const float3 sky_color = (tex2D(ReShade::BackBuffer, float2(0.0, 1.0)).rgb
	                 +  tex2D(ReShade::BackBuffer, float2(0.5, 1.0)).rgb
					 +  tex2D(ReShade::BackBuffer, float2(1.0, 1.0)).rgb) / 3.0;

	//col = lerp(col, blend_screen(col, sky_color), saturate(fresnel));
	//col = blend_screen(col, sky_color, saturate(fresnel));
	//col = max(col, sky_color * fresnel);
	//col = col + sky_color * col * fresnel;
	//col = col + col * col * saturate(fresnel);
	//col 

	const float3 light  = col + col * col;
	const float3 shadow = col * col;

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

technique MatCap_Experimental {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_Experimental;
	}
}
