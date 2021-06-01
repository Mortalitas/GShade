#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#ifndef BAD_BLOOM_DOWN_SCALE
#define BAD_BLOOM_DOWN_SCALE 8
#endif

uniform float3 uColor <
	ui_label = "Color";
	ui_type = "color";
> = float3(1.0,1.0,1.0);

uniform float uAmount <
	ui_label = "Amount";
	ui_tooltip = "Default: 1.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 10.0;
	ui_step = 0.001;
> = 1.0;

uniform float uThreshold <
	ui_label = "Threshold";
	ui_tooltip =
		"Minimum pixel brightness required to generate bloom.\n"
		"Anything below this will be cut-off before blurring.\n"
		"Default: 0.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 0.0;

uniform float uCutOff <
	ui_label = "Cut-Off";
	ui_tooltip = 
		"Same as threshold but applied to the post-blur bloom texture.\n"
		"Anything below this will be be cut-off after blurring.\n"
		"Default: 0.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 0.0;

uniform float uCurve <
	ui_label = "Curve";
	ui_tooltip = "Default: 1.0";
	ui_type = "slider";
	ui_min = 0.001;
	ui_max = 10.0;
	ui_step = 0.01;
> = 1.0;

uniform float2 uScale <
	ui_label = "Scale";
	ui_tooltip = "Default: 1.0 1.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 10.0;
	ui_step = 0.001;
> = float2(1, 1);

uniform float uMaxBrightness <
	ui_label = "Max Brightness";
	ui_tooltip = "Default: 100.0";
	ui_type = "slider";
	ui_min = 1.0;
	ui_max = 1000.0;
	ui_step = 1.0;
> = 100.0;

texture tBadBloom_Threshold {
	Width = BUFFER_WIDTH / BAD_BLOOM_DOWN_SCALE;
	Height = BUFFER_HEIGHT / BAD_BLOOM_DOWN_SCALE;
	Format = RGBA16F;
};
sampler sThreshold {
	Texture = tBadBloom_Threshold;
};

texture tBadBloom_Blur {
	Width = BUFFER_WIDTH / BAD_BLOOM_DOWN_SCALE;
	Height = BUFFER_HEIGHT / BAD_BLOOM_DOWN_SCALE;
};
sampler sBlur {
	Texture = tBadBloom_Blur;
};

float4 gamma(float4 col, float g)
{
    const float i = 1.0 / g;
    return float4(pow(col.x, i)
              , pow(col.y, i)
              , pow(col.z, i)
			  , col.w);
}

float3 jodieReinhardTonemap(float3 c){
    const float l = dot(c, float3(0.2126, 0.7152, 0.0722));
    const float3 tc = c / (c + 1.0);

    return lerp(c / (l + 1.0), tc, tc);
}

float3 inv_reinhard(float3 color, float inv_max) {
	return (color / max(1.0 - color, inv_max));
}

float3 inv_reinhard_lum(float3 color, float inv_max) {
	float lum = max(color.r, max(color.g, color.b));
	return color * (lum / max(1.0 - lum, inv_max));
}

float3 reinhard(float3 color) {
	return color / (1.0 + color);
}

float4 PS_Threshold(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
	float4 color = tex2D(ReShade::BackBuffer, uv);

	// Change to inv_reinhard_lum if you feel colors are overly saturated.
	color.rgb = inv_reinhard(color.rgb, 1.0 / uMaxBrightness);

	color.rgb *= step(uThreshold, dot(color.rgb, float3(0.299, 0.587, 0.114)));
	color.rgb = pow(abs(color.rgb), uCurve);

	return color;
}

float4 PS_Blur(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
	float4 color = tex2D(sThreshold,uv);
	const float2 pix = uScale * BUFFER_PIXEL_SIZE;

	color = tex2D(sThreshold, uv) * 0.204164;

	//H
    color += tex2D(sThreshold, uv + float2(pix.x * 8 * 1.407333,0)) * 0.304005;
    color += tex2D(sThreshold, uv - float2(pix.x * 4 * 1.407333,0)) * 0.304005;
    color += tex2D(sThreshold, uv + float2(pix.x * 2 * 3.294215,0)) * 0.093913;
    color += tex2D(sThreshold, uv - float2(pix.x * 1 * 3.294215,0)) * 0.093913;

	//V
    color += tex2D(sThreshold,( uv + float2(0,pix.y * 8 * 1.407333))) * 0.304005;
    color += tex2D(sThreshold,( uv - float2(0,pix.y * 4 * 1.407333))) * 0.304005;
    color += tex2D(sThreshold,( uv + float2(0,pix.y * 2 * 3.294215))) * 0.093913;
    color += tex2D(sThreshold,( uv - float2(0,pix.y * 1 * 3.294215))) * 0.093913;

	color *= 0.25;
	return color;
}

float4 PS_Blend(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
	float4 color = tex2D(ReShade::BackBuffer, uv);
	color.rgb = inv_reinhard(color.rgb, 1.0 / uMaxBrightness);

	float4 blur = tex2D(sBlur, uv);
	blur *= step(uCutOff, blur);

	color.rgb = mad(blur.rgb, uAmount * uColor, color.rgb);
	color.rgb = reinhard(color.rgb);
 
#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, uv, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
	return color;
#endif
}

technique BadBloomPS2 {
	pass Threshold {
		VertexShader = PostProcessVS;
		PixelShader = PS_Threshold;
		RenderTarget = tBadBloom_Threshold;
	}
	pass BlurPS2 {
		VertexShader = PostProcessVS;
		PixelShader = PS_Blur;
		RenderTarget = tBadBloom_Blur;
	}
	pass BlendPS2 {
		VertexShader = PostProcessVS;
		PixelShader = PS_Blend;
	}
}