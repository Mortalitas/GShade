//Bandwidth Efficient Graphics (Dual Kawase Blur):
//https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_marius_2D00_notes.pdf

#include "ReShade.fxh"

uniform int ZN_LocalContrast <
	ui_type = "radio";
	ui_label = " ";
	ui_text = "ZN Local Contrast is a low cost unsharp mask and bloom shader\n"
		"It leverages a heavy blur to increase overall contrast and reduce washed out colors without 'Deep Frying' the image";
	ui_category = "ZN Local Contrast";
	ui_category_closed = true;
> = 0;

uniform float BLUR_OFFSET <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 20.0;
	ui_label = "Blur Offset";
	ui_tooltip = "Blur radius for Unsharp and bloom";
> = 15.0;

uniform float INTENSITY <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Intensity";
	ui_tooltip = "Effect Intensity";
> = 0.3;

uniform float BLOOM_INTENSITY <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Bloom Intensity";
	ui_tooltip = "How much bloom is added into the original image";
> = 0.2;

uniform bool DEBUG <
> = 0;

#define BackBuf ReShade::BackBuffer
texture DYDownTex0{Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8;};
texture DYDownTex1{Width = BUFFER_WIDTH / 4; Height = BUFFER_HEIGHT / 4; Format = RGBA8;};
texture DYDownTex2{Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA8;};
texture DYDownTex3{Width = BUFFER_WIDTH / 16; Height = BUFFER_HEIGHT / 16; Format = RGBA8;};
texture DYUpTex0{Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA8;};
texture DYUpTex1{Width = BUFFER_WIDTH / 4; Height = BUFFER_HEIGHT / 4; Format = RGBA8;};
texture DYUpTex2{Width = BUFFER_WIDTH / 2; Height = BUFFER_HEIGHT / 2; Format = RGBA8;};
texture DYUpTex3{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};

sampler DownSam0{Texture = DYDownTex0;};
sampler DownSam1{Texture = DYDownTex1;};
sampler DownSam2{Texture = DYDownTex2;};
sampler DownSam3{Texture = DYDownTex3;};
sampler UpSam0{Texture = DYUpTex0;};
sampler UpSam1{Texture = DYUpTex1;};
sampler UpSam2{Texture = DYUpTex2;};
sampler UpSam3{Texture = DYUpTex3;};


float4 DownSample0(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	//float2 xy = texcoord;
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = BLUR_OFFSET;

    float3 acc = tex2D(ReShade::BackBuffer, xy).rgb * 4.0;
    acc += tex2D(ReShade::BackBuffer, xy - hp * offset).rgb;
    acc += tex2D(ReShade::BackBuffer, xy + hp * offset).rgb;
    acc += tex2D(ReShade::BackBuffer, xy + float2(hp.x, -hp.y) * offset).rgb;
    acc += tex2D(ReShade::BackBuffer, xy - float2(hp.x, -hp.y) * offset).rgb;

    return float4(acc / 8.0, 1.0);

}

float4 DownSample1(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	//float2 xy = texcoord;
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = BLUR_OFFSET;

    float3 acc = tex2D(DownSam0, xy).rgb * 4.0;
    acc += tex2D(DownSam0, xy - hp * offset).rgb;
    acc += tex2D(DownSam0, xy + hp * offset).rgb;
    acc += tex2D(DownSam0, xy + float2(hp.x, -hp.y) * offset).rgb;
    acc += tex2D(DownSam0, xy - float2(hp.x, -hp.y) * offset).rgb;

    return float4(acc / 8.0, 1.0);

}

float4 DownSample2(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	//float2 xy = texcoord;
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = BLUR_OFFSET;

    float3 acc = tex2D(DownSam1, xy).rgb * 4.0;
    acc += tex2D(DownSam1, xy - hp * offset).rgb;
    acc += tex2D(DownSam1, xy + hp * offset).rgb;
    acc += tex2D(DownSam1, xy + float2(hp.x, -hp.y) * offset).rgb;
    acc += tex2D(DownSam1, xy - float2(hp.x, -hp.y) * offset).rgb;

    return float4(acc / 8.0, 1.0);

}

float4 DownSample3(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	//float2 xy = texcoord;
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = BLUR_OFFSET;

    float3 acc = tex2D(DownSam1, xy).rgb * 4.0;
    acc += tex2D(DownSam2, xy - hp * offset).rgb;
    acc += tex2D(DownSam2, xy + hp * offset).rgb;
    acc += tex2D(DownSam2, xy + float2(hp.x, -hp.y) * offset).rgb;
    acc += tex2D(DownSam2, xy - float2(hp.x, -hp.y) * offset).rgb;

    return float4(acc / 8.0, 1.0);

}

float4 UpSample0(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	//float2 xy = texcoord;
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = BLUR_OFFSET;
	float3 acc = tex2D(DownSam3, xy + float2(-hp.x * 2.0, 0.0) * offset).rgb;
    
    acc += tex2D(DownSam3, xy + float2(-hp.x, hp.y) * offset).rgb * 2.0;
    acc += tex2D(DownSam3, xy + float2(0.0, hp.y * 2.0) * offset).rgb;
    acc += tex2D(DownSam3, xy + float2(hp.x, hp.y) * offset).rgb * 2.0;
    acc += tex2D(DownSam3, xy + float2(hp.x * 2.0, 0.0) * offset).rgb;
    acc += tex2D(DownSam3, xy + float2(hp.x, -hp.y) * offset).rgb * 2.0;
    acc += tex2D(DownSam3, xy + float2(0.0, -hp.y * 2.0) * offset).rgb;
    acc += tex2D(DownSam3, xy + float2(-hp.x, -hp.y) * offset).rgb * 2.0;

    return float4(acc / 12.0, 1.0);
}



float4 UpSample1(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	//float2 xy = texcoord;
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = BLUR_OFFSET;
	float3 acc = tex2D(UpSam0, xy + float2(-hp.x * 2.0, 0.0) * offset).rgb;
    
    acc += tex2D(UpSam0, xy + float2(-hp.x, hp.y) * offset).rgb * 2.0;
    acc += tex2D(UpSam0, xy + float2(0.0, hp.y * 2.0) * offset).rgb;
    acc += tex2D(UpSam0, xy + float2(hp.x, hp.y) * offset).rgb * 2.0;
    acc += tex2D(UpSam0, xy + float2(hp.x * 2.0, 0.0) * offset).rgb;
    acc += tex2D(UpSam0, xy + float2(hp.x, -hp.y) * offset).rgb * 2.0;
    acc += tex2D(UpSam0, xy + float2(0.0, -hp.y * 2.0) * offset).rgb;
    acc += tex2D(UpSam0, xy + float2(-hp.x, -hp.y) * offset).rgb * 2.0;

    return float4(acc / 12.0, 1.0);
}

float4 UpSample2(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	//float2 xy = texcoord;
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = BLUR_OFFSET;
	float3 acc = tex2D(UpSam0, xy + float2(-hp.x * 2.0, 0.0) * offset).rgb;
    
    acc += tex2D(UpSam1, xy + float2(-hp.x, hp.y) * offset).rgb * 2.0;
    acc += tex2D(UpSam1, xy + float2(0.0, hp.y * 2.0) * offset).rgb;
    acc += tex2D(UpSam1, xy + float2(hp.x, hp.y) * offset).rgb * 2.0;
    acc += tex2D(UpSam1, xy + float2(hp.x * 2.0, 0.0) * offset).rgb;
    acc += tex2D(UpSam1, xy + float2(hp.x, -hp.y) * offset).rgb * 2.0;
    acc += tex2D(UpSam1, xy + float2(0.0, -hp.y * 2.0) * offset).rgb;
    acc += tex2D(UpSam1, xy + float2(-hp.x, -hp.y) * offset).rgb * 2.0;

    return float4(acc / 12.0, 1.0);
}

float4 UpSample3(float4 vpos : SV_Position, float2 xy : TexCoord) : SV_Target
{
	//float2 xy = texcoord;
	float2 res = float2(BUFFER_WIDTH, BUFFER_HEIGHT) / 2.0;
    float2 hp = 0.5 / res;
    float offset = BLUR_OFFSET;
	float3 acc = tex2D(UpSam2, xy + float2(-hp.x * 2.0, 0.0) * offset).rgb;
    
    acc += tex2D(UpSam2, xy + float2(-hp.x, hp.y) * offset).rgb * 2.0;
    acc += tex2D(UpSam2, xy + float2(0.0, hp.y * 2.0) * offset).rgb;
    acc += tex2D(UpSam2, xy + float2(hp.x, hp.y) * offset).rgb * 2.0;
    acc += tex2D(UpSam2, xy + float2(hp.x * 2.0, 0.0) * offset).rgb;
    acc += tex2D(UpSam2, xy + float2(hp.x, -hp.y) * offset).rgb * 2.0;
    acc += tex2D(UpSam2, xy + float2(0.0, -hp.y * 2.0) * offset).rgb;
    acc += tex2D(UpSam2, xy + float2(-hp.x, -hp.y) * offset).rgb * 2.0;

    return float4(acc / 12.0, 1.0);
}

float3 ZN_DUAL(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float3 blur = tex2D(UpSam3, texcoord).rgb;
	float3 bloom = pow(blur, 2.2) * BLOOM_INTENSITY;
	float blurLum = blur.r * 0.2126 + blur.g * 0.7152 + blur.b * 0.0722;
	
	if(DEBUG) {return INTENSITY * (input - blur) + bloom;}
	return input + INTENSITY * (input - blurLum) + bloom;
}

technique ZN_LocalContrast
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DownSample0;
		RenderTarget = DYDownTex0;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DownSample1;
		RenderTarget = DYDownTex1;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DownSample2;
		RenderTarget = DYDownTex2;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DownSample3;
		RenderTarget = DYDownTex3;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = UpSample0;
		RenderTarget = DYUpTex0;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = UpSample1;
		RenderTarget = DYUpTex1;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = UpSample2;
		RenderTarget = DYUpTex2;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = UpSample3;
		RenderTarget = DYUpTex3;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ZN_DUAL;
	}
}
