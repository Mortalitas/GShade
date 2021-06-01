/**
 * Adaptive Color Grading
 * Runs two LUTs simultaneously, smoothly lerping between them based on luma.
 * By moriz1
 * Original LUT shader by Marty McFly
 */

#ifndef fLUT_TextureDay
	#define fLUT_TextureDay "lutDAY.png"
#endif
#ifndef fLUT_TextureNight
	#define fLUT_TextureNight "lutNIGHT.png"
#endif
#ifndef fLUT_TileSizeXY
	#define fLUT_TileSizeXY 32
#endif
#ifndef fLUT_TileAmount
	#define fLUT_TileAmount 32
#endif

uniform bool DebugLuma <
    ui_label = "Show Luma Debug Bars";
	ui_tooltip = "Draws debug bars on top left of screen";
> = false;

uniform bool DebugLumaOutput <
    ui_label = "Show Luma Output";
	ui_tooltip = "Black/White blurry mode!";
> = false;

uniform bool DebugLumaOutputHQ <
    ui_label = "Show Luma Output at Native Resolution";
	ui_tooltip = "Black/White mode!";
> = false;

uniform bool EnableHighlightsInDarkScenes <
	ui_label = "Enable Highlights";
    ui_tooltip = "Add highlights to bright objects when in dark scenes";
> = true;

uniform bool DebugHighlights <
    ui_label = "Show Debug Highlights";
	ui_tooltip = "If any highlights are in the frame, this colours them magenta";
> = false;

uniform float LumaChangeSpeed <
	ui_label = "Adaptation Speed";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.05;

uniform float LumaHigh <
	ui_label = "Luma Max Threshold";
	ui_tooltip = "Luma above this level uses full Daytime LUT\nSet higher than Min Threshold";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.75;

uniform float LumaLow <
	ui_label = "Luma Min Threshold";
	ui_tooltip = "Luma below this level uses full NightTime LUT\nSet lower than Max Threshold";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.2;

uniform float AmbientHighlightThreshold <
	ui_label = "Low Luma Highlight Start";
	ui_tooltip = "If average luma falls below this limit, start adding highlights\nSimulates HDR look in low light";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.5;

uniform float HighlightThreshold <
	ui_label = "Minimum Luma For Highlights";
	ui_tooltip = "Any luma value above this will have highlights\nSimulates HDR look in low light";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.5;

uniform float HighlightMaxThreshold <
	ui_label = "Max Luma For Highlights";
	ui_tooltip = "Highlights reach maximum strength at this luma value\nSimulates HDR look in low light";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.8;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

texture LumaInputTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; MipLevels = 6; };
sampler LumaInputSampler { Texture = LumaInputTex; MipLODBias = 6.0f; };
sampler LumaInputSamplerHQ { Texture = LumaInputTex; };

texture LumaTex { Width = 1; Height = 1; Format = R8; };
sampler LumaSampler { Texture = LumaTex; };

texture LumaTexLF { Width = 1; Height = 1; Format = R8; };
sampler LumaSamplerLF { Texture = LumaTexLF; };

texture texLUTDay < source = fLUT_TextureDay; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTDay	{ Texture = texLUTDay; };

texture texLUTNight < source = fLUT_TextureNight; > { Width = fLUT_TileSizeXY*fLUT_TileAmount; Height = fLUT_TileSizeXY; Format = RGBA8; };
sampler	SamplerLUTNight	{ Texture = texLUTNight; };

float SampleLuma(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target {
	float luma = 0.0;

	const int width = BUFFER_WIDTH / 64;
	const int height = BUFFER_HEIGHT / 64;

	for (int i = width/3; i < 2*width/3; i++) {
		for (int j = height/3; j < 2*height/3; j++) {
			luma += tex2Dlod(LumaInputSampler, float4(i, j, 0, 6)).x;
		}
	}

	luma /= (width * 1/3) * (height * 1/3);

	const float lastFrameLuma = tex2D(LumaSamplerLF, float2(0.5, 0.5)).x;

	return lerp(lastFrameLuma, luma, LumaChangeSpeed);
}

float LumaInput(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target {
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).xyz;

	return pow(abs((color.r*2 + color.b + color.g*3) / 6), 1/2.2);
}

float3 ApplyLUT(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target {
	float3 color = tex2D(ReShade::BackBuffer, texcoord.xy).rgb;
	const float lumaVal = tex2D(LumaSampler, float2(0.5, 0.5)).x;
	const float highlightLuma = tex2D(LumaInputSamplerHQ, texcoord.xy).x;

	if (DebugLumaOutputHQ) {
		return highlightLuma;
	}
	else if (DebugLumaOutput) {
		return lumaVal;
	}

	if (DebugLuma) {
		if (texcoord.y <= 0.01 && texcoord.x <= 0.01) {
			return lumaVal;
		}
		if (texcoord.y <= 0.01 && texcoord.x > 0.01 && texcoord.x <= 0.02) {
			if (lumaVal > LumaHigh) {
				return float3(1.0, 1.0, 1.0);
			}
			else {
				return float3(0.0, 0.0, 0.0);
			}
		}
		if (texcoord.y <= 0.01 && texcoord.x > 0.02 && texcoord.x <= 0.03) {
			if (lumaVal <= LumaHigh && lumaVal >= LumaLow) {
				return float3(1.0, 1.0, 1.0);
			}
			else {
				return float3(0.0, 0.0, 0.0);
			}
		}
		if (texcoord.y <= 0.01 && texcoord.x > 0.03 && texcoord.x <= 0.04) {
			if (lumaVal < LumaLow) {
				return float3(1.0, 1.0, 1.0);
			}
			else {
				return float3(0.0, 0.0, 0.0);
			}
		}
	}

	float2 texelsize = 1.0 / fLUT_TileSizeXY;
	texelsize.x /= fLUT_TileAmount;

	float3 lutcoord = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
	const float lerpfact = frac(lutcoord.z);

	lutcoord.x += (lutcoord.z-lerpfact)*texelsize.y;
	
	const float3 color1 = lerp(tex2D(SamplerLUTDay, lutcoord.xy).xyz, tex2D(SamplerLUTDay, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);
	const float3 color2 = lerp(tex2D(SamplerLUTNight, lutcoord.xy).xyz, tex2D(SamplerLUTNight, float2(lutcoord.x+texelsize.y,lutcoord.y)).xyz,lerpfact);	

	const float range = (lumaVal - LumaLow)/(LumaHigh - LumaLow);

	if (lumaVal > LumaHigh) {
		color.xyz = color1.xyz;
	}
	else if (lumaVal < LumaLow) {
		color.xyz = color2.xyz;
	}
	else {
		color.xyz = lerp(color2.xyz, color1.xyz, range);
	}

	float3 lutcoord2 = float3((color.xy*fLUT_TileSizeXY-color.xy+0.5)*texelsize.xy,color.z*fLUT_TileSizeXY-color.z);
	const float lerpfact2 = frac(lutcoord2.z);

	lutcoord2.x += (lutcoord2.z-lerpfact2)*texelsize.y;
	
	const float3 highlightColor = lerp(tex2D(SamplerLUTDay, lutcoord2.xy).xyz, tex2D(SamplerLUTDay, float2(lutcoord2.x+texelsize.y,lutcoord2.y)).xyz,lerpfact2);

	//apply highlights
	if (EnableHighlightsInDarkScenes) {
		if (lumaVal < AmbientHighlightThreshold && highlightLuma > HighlightThreshold) {
			const float range = saturate((highlightLuma - HighlightThreshold)/(HighlightMaxThreshold - HighlightThreshold)) * 
							saturate((AmbientHighlightThreshold - lumaVal)/(0.1));

			if (DebugHighlights) {
				color.xyz = lerp(color.xyz, float3(1.0, 0.0, 1.0), range);
				
				if (range >= 1.0) {
					color.xyz = float3(1.0, 0.0, 0.0);
				}
			}

			color.xyz = lerp(color.xyz, highlightColor.xyz, range);
		}
	}
#if GSHADE_DITHER
	return color += TriDither(color.xyz, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return color;
#endif
}

float SampleLumaLF(float4 position : SV_Position, float2 texcoord: TexCoord) : SV_Target {
	return tex2D(LumaSampler, float2(0.5, 0.5)).x;
}

technique AdaptiveColorGrading {
	pass Input {
		VertexShader = PostProcessVS;
		PixelShader = LumaInput;
		RenderTarget = LumaInputTex
	;
	}
	pass StoreLuma {
		VertexShader = PostProcessVS;
		PixelShader = SampleLuma;
		RenderTarget = LumaTex;
	}
	pass Apply_LUT {
		VertexShader = PostProcessVS;
		PixelShader = ApplyLUT;
	}
	pass StoreLumaLF {
		VertexShader = PostProcessVS;
		PixelShader = SampleLumaLF;
		RenderTarget = LumaTexLF;
	}
}
