////----------//
////** UIShadow by Lolika **////
////** License: CC0 **////
//----------////

// Currently this identifies Pixels that are not UI or only "partially" UI and right next to "full" UI pixels (alpha channel = 1)
// This means transparent text will not become more readable, like distant nameplates, but prevents a boatload of weird artifacts across the entire UI

// TODO: Blur the border created by the Shader. Looks fine on my 4k screen at this distance but other people may see the aliasing.

#include "ReShade.fxh"

#ifndef UiShadowNumDilations
	// 0, 1 or 2, adjust to your needs
	#define UiShadowNumDilations 1
#endif

uniform int iUIShadowNumDialations <
	ui_type = "slider";
	ui_label = "Shadow Radius";
	ui_min = 0;
	ui_max = 2;
	ui_tooltip = "Expands and contracts the shadow radius.";
	ui_bind = "UiShadowNumDilations";
> = 1;

// At least one of NumDilations or NumBlurs has to be >= 1!
#ifndef UiShadowNumBlurs
	// 0, 1, 2, or 3 adjust to your needs
	#define UiShadowNumBlurs 2
#endif

uniform int iUIShadowNumBlurs <
	ui_type = "slider";
	ui_label = "Blur Strength";
	ui_min = 0;
	ui_max = 3;
	ui_tooltip = "Adjusts the blur strength.";
	ui_bind = "UiShadowNumBlurs";
> = 2;


// Avoid undefined behaviour for wrong values
#if (UiShadowNumDilations < 0) || (UiShadowNumDilations > 2)
#undef UiShadowNumDilations
#define UiShadowNumDilations 1
#endif

#if (UiShadowNumBlurs < 0) || (UiShadowNumBlurs > 3)
#undef UiShadowNumBlurs
#define UiShadowNumBlurs 2
#endif

// Yes, really, you aren't breaking this, bad boi
#if (UiShadowNumDilations + UiShadowNumBlurs) == 0
#undef UiShadowNumDilations
#define UiShadowNumDilations 1
#undef UiShadowNumBlurs
#define UiShadowNumBlurs 2
#endif

texture2D shadowTex < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
texture2D shadowTexPong { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };

sampler2D texNearest
{
	Texture = ReShade::BackBufferTex;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
	MinLOD = 0.0f;
	MaxLOD = 1000.0f;
	MipLODBias = 0.0f;
	SRGBTexture = false;
};

sampler2D shadowSampler
{
	Texture = shadowTex;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	MipFilter = LINEAR;
	MinLOD = 0.0f;
	MaxLOD = 1000.0f;
	MipLODBias = 0.0f;
	SRGBTexture = false;
};

sampler2D shadowPongSampler
{
	Texture = shadowTexPong;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	MipFilter = LINEAR;
	MinLOD = 0.0f;
	MaxLOD = 1000.0f;
	MipLODBias = 0.0f;
	SRGBTexture = false;
};

#if ((UiShadowNumDilations + UiShadowNumBlurs) % 2) == 1
#define UI_SHADOW_FINAL_SAMPLER shadowPongSampler
#else
#define UI_SHADOW_FINAL_SAMPLER shadowSampler
#endif

#if (UiShadowNumDilations % 2) == 1
#define UI_SHADOW_TARGET_A shadowTex
#define UI_SHADOW_SAMPLE_A shadowPongSampler
#define UI_SHADOW_TARGET_B shadowTexPong
#define UI_SHADOW_SAMPLE_B shadowSampler
#else
#define UI_SHADOW_TARGET_B shadowTex
#define UI_SHADOW_SAMPLE_B shadowPongSampler
#define UI_SHADOW_TARGET_A shadowTexPong
#define UI_SHADOW_SAMPLE_A shadowSampler
#endif

float calcUIBorder(float2 texcoord) {
	const int2 pixelCoord = texcoord * BUFFER_SCREEN_SIZE;

	// Get the 8-neighborhood alpha-Values
	const float4 ul = float4(tex2DgatherA(ReShade::BackBuffer, texcoord - 0.5 * BUFFER_PIXEL_SIZE).rba, tex2Dfetch(ReShade::BackBuffer, pixelCoord + int2(-1, 1)).a);
	const float4 lr = float4(tex2DgatherA(ReShade::BackBuffer, texcoord + 0.5 * BUFFER_PIXEL_SIZE).rgb, tex2Dfetch(ReShade::BackBuffer, pixelCoord + int2( 1,-1)).a);

	// Find Maximum
	float brd = max(max(ul.r, ul.g), max(ul.b, ul.a));
	brd = max(max(max(lr.r, lr.g), max(lr.b, lr.a)), brd);

	// A Pixel is on the UI edge if it has alpha < 1 (not/partially UI) and borders at least one fully-UI pixel (alpha = 1)
   	return float((tex2Dfetch(texNearest, pixelCoord).a < 1) && (brd >= 1));
}


float4 PS_UISH(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
   	return float4(calcUIBorder(texcoord), 0, 0, 0);
}

float4 PS_SHSH(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float s = 1.0 - tex2D(UI_SHADOW_FINAL_SAMPLER, texcoord).r; // Invert the blurred edge image to get the actual shadow
	const float4 c = tex2D(texNearest, texcoord);
   	return float4 (lerp(s*c.rgb, c.rgb, c.a), c.a); // Interpolate between shadowed image and regular image depending on how much the pixel belongs to the UI
}

// Simple dilates the UI Edge for a more pronounced shadow, as the edge found is often part of the antialiased portion of the UI and thus will not be very visible
float4 PS_DilateShadowA(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 tmp = tex2DgatherR(shadowSampler, texcoord - 0.5 * BUFFER_PIXEL_SIZE);
	float output = max(max(tmp.r, tmp.g), max(tmp.b, tmp.a));
	tmp = tex2DgatherR(shadowSampler, texcoord + 0.5 * BUFFER_PIXEL_SIZE);
	output = max(max(max(tmp.r, tmp.g), max(tmp.b, tmp.a)), output);
	tmp = tex2DgatherR(shadowSampler, texcoord + float2(0.5, -0.5) * BUFFER_PIXEL_SIZE);
	output = max(max(max(tmp.r, tmp.g), max(tmp.b, tmp.a)), output);
	tmp = tex2DgatherR(shadowSampler, texcoord + float2(-0.5, 0.5) * BUFFER_PIXEL_SIZE);
	output = max(max(max(tmp.r, tmp.g), max(tmp.b, tmp.a)), output);

	return float4(output, 0, 0, 0);
}

float4 PS_DilateShadowB(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 tmp = tex2DgatherR(shadowPongSampler, texcoord - 0.5 * BUFFER_PIXEL_SIZE);
	float output = max(max(tmp.r, tmp.g), max(tmp.b, tmp.a));
	tmp = tex2DgatherR(shadowPongSampler, texcoord + 0.5 * BUFFER_PIXEL_SIZE);
	output = max(max(max(tmp.r, tmp.g), max(tmp.b, tmp.a)), output);
	tmp = tex2DgatherR(shadowPongSampler, texcoord + float2(0.5, -0.5) * BUFFER_PIXEL_SIZE);
	output = max(max(max(tmp.r, tmp.g), max(tmp.b, tmp.a)), output);
	tmp = tex2DgatherR(shadowPongSampler, texcoord + float2(-0.5, 0.5) * BUFFER_PIXEL_SIZE);
	output = max(max(max(tmp.r, tmp.g), max(tmp.b, tmp.a)), output);

	return float4(output, 0, 0, 0);
}

// A Blur with the following kernel (* 1/16) - i.e. a super simple binomial filter:
// 1 2 1
// 2 4 2
// 1 2 1
float4 PS_BlurA(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float output = dot(tex2DgatherR(UI_SHADOW_SAMPLE_A, texcoord - 0.5 * BUFFER_PIXEL_SIZE), float4(1,1,1,1));
	output += dot(tex2DgatherR(UI_SHADOW_SAMPLE_A, texcoord + 0.5 * BUFFER_PIXEL_SIZE), float4(1,1,1,1));
	output += dot(tex2DgatherR(UI_SHADOW_SAMPLE_A, texcoord + float2(0.5, -0.5) * BUFFER_PIXEL_SIZE), float4(1,1,1,1));
	output += dot(tex2DgatherR(UI_SHADOW_SAMPLE_A, texcoord + float2(-0.5, 0.5) * BUFFER_PIXEL_SIZE), float4(1,1,1,1));

	return float4(output * 0.0625, 0, 0, 0);
}

// Same Blur, Buffers swapped
float4 PS_BlurB(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float output = dot(tex2DgatherR(UI_SHADOW_SAMPLE_B, texcoord - 0.5 * BUFFER_PIXEL_SIZE), float4(1,1,1,1));
	output += dot(tex2DgatherR(UI_SHADOW_SAMPLE_B, texcoord + 0.5 * BUFFER_PIXEL_SIZE), float4(1,1,1,1));
	output += dot(tex2DgatherR(UI_SHADOW_SAMPLE_B, texcoord + float2(0.5, -0.5) * BUFFER_PIXEL_SIZE), float4(1,1,1,1));
	output += dot(tex2DgatherR(UI_SHADOW_SAMPLE_B, texcoord + float2(-0.5, 0.5) * BUFFER_PIXEL_SIZE), float4(1,1,1,1));

	return float4(output * 0.0625, 0, 0, 0);
}

technique UIShadowShader
{
	pass FindUIEdge
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_UISH;
		RenderTarget = shadowTex;
	}
	#if UiShadowNumDilations >= 1
	pass DilateShadow
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DilateShadowA;
		RenderTarget = shadowTexPong;
	}
	#endif
	#if UiShadowNumDilations >= 2
	pass DilateShadow
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DilateShadowB;
		RenderTarget = shadowTex;
	}
	#endif
	#if UiShadowNumBlurs >= 1
	pass BlurShadow1
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_BlurA;
		RenderTarget = UI_SHADOW_TARGET_A;
	}
	#endif
	#if UiShadowNumBlurs >= 2
	pass BlurShadow2
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_BlurB;
		RenderTarget = UI_SHADOW_TARGET_B;
	}
	#endif
	#if UiShadowNumBlurs >= 3
	pass BlurShadow3
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_BlurA;
		RenderTarget = UI_SHADOW_TARGET_A;
	}
	#endif
	pass AddUIShadow
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_SHSH;
	}
}
