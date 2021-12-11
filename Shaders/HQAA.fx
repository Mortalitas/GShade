/**
 *               HQAA for ReShade 3.1.1+
 *
 *   Smooshes FXAA and SMAA together as a single shader
 *
 *              v1.53 (likely final) release
 *
 *                     by lordbean
 *
 */


//------------------------------- UI setup -----------------------------------------------

uniform float EdgeThreshold <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Edge Detection Threshold";
	ui_tooltip = "Local contrast required to run shader";
        ui_category = "Normal Usage";
> = 0.075;

uniform float Subpix <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Subpixel Effects Strength";
	ui_tooltip = "Lower = sharper image, Higher = more AA effect";
        ui_category = "Normal Usage";
> = 0.375;

uniform int PmodeWarning <
	ui_type = "radio";
	ui_label = " ";	
	ui_text ="\n>>>> WARNING <<<<\n\nVirtual Photography mode allows HQAA to exceed its normal\nlimits when processing subpixel aliasing and will probably\nresult in too much blurring for everyday usage.\n\nIt is only intended for virtual photography purposes where\nthe game's UI is typically not present on the screen.";
	ui_category = "Virtual Photography";
>;

uniform bool Overdrive <
        ui_label = "Enable Virtual Photography Mode";
        ui_category = "Virtual Photography";
> = false;

uniform float SubpixBoost <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Extra Subpixel Effects Strength";
	ui_tooltip = "Additional boost to subpixel aliasing processing";
        ui_category = "Virtual Photography";
> = 0.00;

//------------------------------ Shader Setup -------------------------------------------

/****** COMPATIBILITY DEFINES (hopefully) *******************/
#ifdef HQ_FXAA_QUALITY_PRESET
	#undef HQ_FXAA_QUALITY_PRESET
#endif
#ifdef HQ_FXAA_GREEN_AS_LUMA
	#undef HQ_FXAA_GREEN_AS_LUMA
#endif
#ifdef HQ_FXAA_LINEAR_LIGHT
	#undef HQ_FXAA_LINEAR_LIGHT
#endif
#ifdef HQ_FXAA_PC
	#undef HQ_FXAA_PC
#endif
#ifdef HQ_FXAA_HLSL_3
	#undef HQ_FXAA_HLSL_3
#endif
#ifdef HQ_FXAA_GATHER4_ALPHA
	#undef HQ_FXAA_GATHER4_ALPHA
#endif
#ifdef HQ_FxaaTexAlpha4
	#undef HQ_FxaaTexAlpha4
#endif
#ifdef HQ_FxaaTexOffAlpha4
	#undef HQ_FxaaTexOffAlpha4
#endif
#ifdef HQ_FxaaTexGreen4
	#undef HQ_FxaaTexGreen4
#endif
#ifdef HQ_FxaaTexOffGreen4
	#undef HQ_FxaaTexOffGreen4
#endif

#ifdef HQ_SMAA_PRESET_LOW
	#undef HQ_SMAA_PRESET_LOW
#endif
#ifdef HQ_SMAA_PRESET_MEDIUM
	#undef HQ_SMAA_PRESET_MEDIUM
#endif
#ifdef HQ_SMAA_PRESET_HIGH
	#undef HQ_SMAA_PRESET_HIGH
#endif
#ifdef HQ_SMAA_PRESET_ULTRA
	#undef HQ_SMAA_PRESET_ULTRA
#endif
#ifdef HQ_SMAA_PRESET_CUSTOM
	#undef HQ_SMAA_PRESET_CUSTOM
#endif
#ifdef HQ_SMAA_THRESHOLD
	#undef HQ_SMAA_THRESHOLD
#endif
#ifdef HQ_SMAA_MAX_SEARCH_STEPS
	#undef HQ_SMAA_MAX_SEARCH_STEPS
#endif
#ifdef HQ_SMAA_MAX_SEARCH_STEPS_DIAG
	#undef HQ_SMAA_MAX_SEARCH_STEPS_DIAG
#endif
#ifdef HQ_SMAA_CORNER_ROUNDING
	#undef HQ_SMAA_CORNER_ROUNDING
#endif
#ifdef HQ_SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR
	#undef HQ_SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR
#endif
#ifdef HQ_SMAA_RT_METRICS
	#undef HQ_SMAA_RT_METRICS
#endif
#ifdef HQ_SMAA_CUSTOM_SL
	#undef HQ_SMAA_CUSTOM_SL
#endif
#ifdef HQ_SMAATexture2D
	#undef HQ_SMAATexture2D
#endif
#ifdef HQ_SMAATexturePass2D
	#undef HQ_SMAATexturePass2D
#endif
#ifdef HQ_SMAASampleLevelZero
	#undef HQ_SMAASampleLevelZero
#endif
#ifdef HQ_SMAASampleLevelZeroPoint
	#undef HQ_SMAASampleLevelZeroPoint
#endif
#ifdef HQ_SMAASampleLevelZeroOffset
	#undef HQ_SMAASampleLevelZeroOffset
#endif
#ifdef HQ_SMAASample
	#undef HQ_SMAASample
#endif
#ifdef HQ_SMAASamplePoint
	#undef HQ_SMAASamplePoint
#endif
#ifdef HQ_SMAASampleOffset
	#undef HQ_SMAASampleOffset
#endif
#ifdef HQ_SMAA_BRANCH
	#undef HQ_SMAA_BRANCH
#endif
#ifdef HQ_SMAA_FLATTEN
	#undef HQ_SMAA_FLATTEN
#endif
#ifdef HQ_SMAAGather
	#undef HQ_SMAAGather
#endif
#ifdef HQ_SMAA_DISABLE_DIAG_DETECTION
	#undef HQ_SMAA_DISABLE_DIAG_DETECTION
#endif
#ifdef HQ_SMAA_PREDICATION
	#undef HQ_SMAA_PREDICATION
#endif
#ifdef HQ_SMAA_REPROJECTION
	#undef HQ_SMAA_REPROJECTION
#endif
/************************************************************/

#define HQ_FXAA_GREEN_AS_LUMA 1    // Seems to play nicer with SMAA, less aliasing artifacts
#define HQ_SMAA_PRESET_CUSTOM
#define HQ_SMAA_THRESHOLD max(0.05, EdgeThreshold)
#define HQ_SMAA_MAX_SEARCH_STEPS 112
#define HQ_SMAA_CORNER_ROUNDING 0
#define HQ_SMAA_MAX_SEARCH_STEPS_DIAG 20
#define HQ_SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR (1.1 + (0.65 * Subpix)) // Range 1.1 to 1.75
#define HQ_FXAA_QUALITY__PRESET 39
#define HQ_FXAA_PC 1
#define HQ_FXAA_HLSL_3 1
#define HQ_SMAA_RT_METRICS float4(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT)
#define HQ_SMAA_CUSTOM_SL 1
#define HQ_SMAATexture2D(tex) sampler tex
#define HQ_SMAATexturePass2D(tex) tex
#define HQ_SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, coord))
#define HQ_SMAASampleLevelZeroPoint(tex, coord) HQ_SMAASampleLevelZero(tex, coord)
#define HQ_SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlodoffset(tex, float4(coord, coord), offset)
#define HQ_SMAASample(tex, coord) tex2D(tex, coord)
#define HQ_SMAASamplePoint(tex, coord) HQ_SMAASample(tex, coord)
#define HQ_SMAASampleOffset(tex, coord, offset) tex2Doffset(tex, coord, offset)
#define HQ_SMAA_BRANCH [branch]
#define HQ_SMAA_FLATTEN [flatten]

#if (__RENDERER__ == 0xb000 || __RENDERER__ == 0xb100)
	#define HQ_SMAAGather(tex, coord) tex2Dgather(tex, coord, 0)
	#define HQ_FXAA_GATHER4_ALPHA 1
	#define HQ_FxaaTexAlpha4(t, p) tex2Dgather(t, p, 3)
	#define HQ_FxaaTexOffAlpha4(t, p, o) tex2Dgatheroffset(t, p, o, 3)
	#define HQ_FxaaTexGreen4(t, p) tex2Dgather(t, p, 1)
	#define HQ_FxaaTexOffGreen4(t, p, o) tex2Dgatheroffset(t, p, o, 1)
#endif

#include "HQAA.fxh"
#include "ReShade.fxh"

#undef HQ_FXAA_QUALITY__PS
#undef HQ_FXAA_QUALITY__P0
#undef HQ_FXAA_QUALITY__P1
#undef HQ_FXAA_QUALITY__P2
#undef HQ_FXAA_QUALITY__P3
#undef HQ_FXAA_QUALITY__P4
#undef HQ_FXAA_QUALITY__P5
#undef HQ_FXAA_QUALITY__P6
#undef HQ_FXAA_QUALITY__P7
#undef HQ_FXAA_QUALITY__P8
#undef HQ_FXAA_QUALITY__P9
#undef HQ_FXAA_QUALITY__P10
#undef HQ_FXAA_QUALITY__P11
#define HQ_FXAA_QUALITY__PS 13
#define HQ_FXAA_QUALITY__P0 0.25
#define HQ_FXAA_QUALITY__P1 0.25
#define HQ_FXAA_QUALITY__P2 0.5
#define HQ_FXAA_QUALITY__P3 0.5
#define HQ_FXAA_QUALITY__P4 0.75
#define HQ_FXAA_QUALITY__P5 0.75
#define HQ_FXAA_QUALITY__P6 1.0
#define HQ_FXAA_QUALITY__P7 1.0
#define HQ_FXAA_QUALITY__P8 1.25
#define HQ_FXAA_QUALITY__P9 1.25
#define HQ_FXAA_QUALITY__P10 1.5
#define HQ_FXAA_QUALITY__P11 1.5
#define HQ_FXAA_QUALITY__P12 2.0

//------------------------------------- Textures -------------------------------------------

texture edgesTex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RG8;
};
texture blendTex < pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	Format = RGBA8;
};

texture areaTex < source = "AreaTex.png"; >
{
	Width = 160;
	Height = 560;
	Format = RG8;
};
texture searchTex < source = "SearchTex.png"; >
{
	Width = 64;
	Height = 16;
	Format = R8;
};

// -------------------------------- Samplers -----------------------------------------------

sampler colorGammaSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler colorLinearSampler
{
	Texture = ReShade::BackBufferTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Point; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = true;
};
sampler edgesSampler
{
	Texture = edgesTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler blendSampler
{
	Texture = blendTex;
	AddressU = Clamp; AddressV = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler areaSampler
{
	Texture = areaTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Linear; MinFilter = Linear; MagFilter = Linear;
	SRGBTexture = false;
};
sampler searchSampler
{
	Texture = searchTex;
	AddressU = Clamp; AddressV = Clamp; AddressW = Clamp;
	MipFilter = Point; MinFilter = Point; MagFilter = Point;
	SRGBTexture = false;
};
sampler FXAATexture
{
	Texture = ReShade::BackBufferTex;
	MinFilter = Linear; MagFilter = Linear;
};

//----------------------------------- Vertex Shaders ---------------------------------------

void SMAAEdgeDetectionWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset[3] : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAAEdgeDetectionVS(texcoord, offset);
}
void SMAABlendingWeightCalculationWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float2 pixcoord : TEXCOORD1,
	out float4 offset[3] : TEXCOORD2)
{
	PostProcessVS(id, position, texcoord);
	SMAABlendingWeightCalculationVS(texcoord, pixcoord, offset);
}
void SMAANeighborhoodBlendingWrapVS(
	in uint id : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texcoord : TEXCOORD0,
	out float4 offset : TEXCOORD1)
{
	PostProcessVS(id, position, texcoord);
	SMAANeighborhoodBlendingVS(texcoord, offset);
}

// -------------------------------- Pixel shaders ------------------------------------------
// SMAA detection method is using ASSMAA "Both, biasing Clarity" to minimize blurring

float2 SMAAEdgeDetectionWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_Target
{
	float2 color = SMAAColorEdgeDetectionPS(texcoord, offset, colorGammaSampler);
	float2 luma = SMAALumaEdgeDetectionPS(texcoord, offset, colorGammaSampler);
	float2 result = float2(sqrt(color.r * luma.r), sqrt(color.g * luma.g));
	return result;
}
float4 SMAABlendingWeightCalculationWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float2 pixcoord : TEXCOORD1,
	float4 offset[3] : TEXCOORD2) : SV_Target
{
	return SMAABlendingWeightCalculationPS(texcoord, pixcoord, offset, edgesSampler, areaSampler, searchSampler, 0.0);
}
float3 SMAANeighborhoodBlendingWrapPS(
	float4 position : SV_Position,
	float2 texcoord : TEXCOORD0,
	float4 offset : TEXCOORD1) : SV_Target
{
	return SMAANeighborhoodBlendingPS(texcoord, offset, colorLinearSampler, blendSampler).rgb;
}

float4 FXAAPixelShaderCoarse(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float TotalSubpix = 0.0;
	if (Overdrive)
	{
		TotalSubpix += SubpixBoost;
		TotalSubpix = TotalSubpix * 0.25;
	}
	#undef HQ_FXAA_QUALITY__PS
	#define HQ_FXAA_QUALITY__PS 2
	return FxaaPixelShader(texcoord,0,FXAATexture,FXAATexture,FXAATexture,BUFFER_PIXEL_SIZE,0,0,0,TotalSubpix,0.925 - (Subpix * 0.125),0.004,0,0,0,0); // Range 0.925 to 0.8
}

float4 FXAAPixelShaderMid(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float TotalSubpix = 0.0;
	if (Overdrive)
	{
		TotalSubpix += SubpixBoost;
		TotalSubpix = TotalSubpix * 0.5;
	}
	#undef HQ_FXAA_QUALITY__PS
	#define HQ_FXAA_QUALITY__PS 5
	return FxaaPixelShader(texcoord,0,FXAATexture,FXAATexture,FXAATexture,BUFFER_PIXEL_SIZE,0,0,0,TotalSubpix,0.85 - (Subpix * 0.15),0.004,0,0,0,0); // Range 0.85 to 0.7
}

float4 FXAAPixelShaderFine(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float TotalSubpix = 0.0;
	if (Overdrive)
	{
		TotalSubpix += SubpixBoost;
		TotalSubpix = TotalSubpix * 0.875;
	}
	TotalSubpix += Subpix * 0.125;
	#undef HQ_FXAA_QUALITY__PS
	#define HQ_FXAA_QUALITY__PS 13
	return FxaaPixelShader(texcoord,0,FXAATexture,FXAATexture,FXAATexture,BUFFER_PIXEL_SIZE,0,0,0,TotalSubpix,max(0.1,0.7 * EdgeThreshold),0.004,0,0,0,0); // Cap maximum sensitivity level for blur control
}

// -------------------------------- Rendering passes ----------------------------------------

technique HQAA <
	ui_tooltip = "Hybrid high-Quality AA combines techniques of both SMAA and FXAA to\n"
	             "produce best possible image quality from using both.";
>
{
	pass SMAAEdgeDetection
	{
		VertexShader = SMAAEdgeDetectionWrapVS;
		PixelShader = SMAAEdgeDetectionWrapPS;
		RenderTarget = edgesTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
		StencilRef = 1;
	}
	pass SMAABlendWeightCalculation
	{
		VertexShader = SMAABlendingWeightCalculationWrapVS;
		PixelShader = SMAABlendingWeightCalculationWrapPS;
		RenderTarget = blendTex;
		ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = KEEP;
		StencilFunc = EQUAL;
		StencilRef = 1;
	}
	pass SMAANeighborhoodBlending
	{
		VertexShader = SMAANeighborhoodBlendingWrapVS;
		PixelShader = SMAANeighborhoodBlendingWrapPS;
		StencilEnable = false;
		SRGBWriteEnable = true;
	}
	pass FXAA1
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderCoarse;
	}
	pass FXAA2
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderMid;
	}
	pass FXAA3
	{
		VertexShader = PostProcessVS;
		PixelShader = FXAAPixelShaderFine;
	}
}
