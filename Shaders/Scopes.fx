/**
Scopes - Vectorscope Shader, version 1.1.5
All rights (c) 2021 Jakub Maksymilian Fober (the Author)

This effect will analyze all the pixels on the screen
and display them as a vectorscope color-wheel

Licensed under the Creative Commons CC BY-NC-ND 3.0,
license available online at http://creativecommons.org/licenses/by-nc-nd/3.0/

If you want to use this shader in commercial production, for example
in a game-dev or maybe you want to integrate it into your game-engine,
contact me, the Author and I will grant you a non-exclusive license.

For inquiries please contact jakub.m.fober@pm.me
For updates visit GitHub repository at
https://github.com/Fubaxiusz/fubax-shaders/
*/

#include "ReShade.fxh"


// Macros

// Draw UI in a vertex shader (aliased)
#ifndef SCOPES_FAST_UI
	#define SCOPES_FAST_UI 1
#endif
// Define color standard for output
#ifndef SCOPES_ITU_REC
	// Available options: 601, 709
	#define SCOPES_ITU_REC 601
#endif
// Determine native scope size
#ifndef SCOPES_TEXTURE_SIZE
	#define SCOPES_TEXTURE_SIZE 256
#endif
// Checkerboard sampling increases performance 2x, gives 4-frame 'motion blur'
#ifndef SCOPES_FAST_CHECKERBOARD
	#define SCOPES_FAST_CHECKERBOARD 1
#endif


// Menu items

uniform int ScopeBrightness <
	ui_type = "slider";
	ui_category = "Vectorscope";
	ui_label = "Vectorscope brightness";
	ui_tooltip = "Adjust vectorscope sensitivity";
	ui_min = 1; ui_max = 1024;
> = 128;

uniform float3 ScopePosition <
	ui_type = "drag";
	ui_category = "Location";
	ui_label = "Position and size";
	ui_tooltip = "Move vectorscope on the screen";
	ui_min = 0.0; ui_max = 1.0;
> = float3(0.988, 0.977, 0.0);

uniform float ScopeUITransparency <
	ui_type = "slider";
	ui_category = "UI";
	ui_label = "UI visibility";
	ui_tooltip = "Set marker-lines transparency-level";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
> = 0.22;

uniform float ScopeTransparency <
	ui_type = "slider";
	ui_category = "UI";
	ui_label = "Background";
	ui_tooltip = "Set vectorscope transparency-level";
	ui_min = 0.5; ui_max = 1.0; ui_step = 0.01;
> = 0.99;

#if SCOPES_FAST_CHECKERBOARD
	// System variable
	uniform uint FRAME_INDEX < source = "framecount"; >;
#endif

// Convert display gamma for all vector types
#if BUFFER_COLOR_BIT_DEPTH!=10
	#define TO_LINEAR_GAMMA(g) pow(abs(g), 2.2)
#else // No gamma change
	#define TO_LINEAR_GAMMA(g) (g)
#endif
// Golden ratio phi (0.618)
#define GOLDEN_RATIO (sqrt(5.0)*0.5-0.5)
// Get scope scale relative to border
#define SCOPES_BORDER_SIZE GOLDEN_RATIO
// Get scope pixel brightness
#define SCOPES_BRIGHTNESS (SCOPES_TEXTURE_SIZE*BUFFER_RCP_WIDTH*BUFFER_RCP_HEIGHT)
// Non-fast UI line thickness
#define SCOPE_LINE_WIDTH 1.0


// Constants

#if SCOPES_ITU_REC==709
	// RGB to Chroma BT.709 matrix
	static const float3x2 ChromaMtx =
		float3x2(
//			float3(0.2126, 0.7152, 0.0722), // Luma (Y)
			float3(-0.1146, -0.3854, 0.5),  // Chroma (Cb)
			float3(0.5, -0.4542, -0.0458)   // Chroma (Cr)
		);
#elif SCOPES_ITU_REC==601
	// RGB to Chroma BT.601 matrix
	static const float3x2 ChromaMtx =
		float3x2(
//			float3(0.299, 0.587, 0.114),       // Luma (Y)
			float3(-0.168736, -0.331264, 0.5), // Chroma (Cb)
			float3(0.5, -0.418688, -0.081312)  // Chroma (Cr)
		);
#endif

#if SCOPES_ITU_REC==709
	// BT.709 YCbCr to RGB matrix
	static const float3x3 RgbMtx =
		float3x3(
			float3(1.0, 0.0, 1.5748),      // Red
			float3(1.0, -0.1873, -0.4681), // Green
			float3(1.0, 1.8556, 0.0)       // Blue
		);
#elif SCOPES_ITU_REC==601
	// BT.601 YCbCr to RGB matrix
	static const float3x3 RgbMtx =
		float3x3(
			float3(1.0, 0.0, 1.402),           // Red
			float3(1.0, -0.344136, -0.714136), // Green
			float3(1.0, 1.772, 0.0)            // Blue
		);
#endif


// Textures

// Vectorscope texture target; gathers chroma quantity statistics
texture2D vectorscopeTex
{
	// Square resolution
	Width  = SCOPES_TEXTURE_SIZE;
	Height = SCOPES_TEXTURE_SIZE;
#if SCOPES_FAST_CHECKERBOARD
	Format = RGBA32F; // Store 4-frames in 4-channels
#else
	Format = R32F;
#endif
};

// Vectorscope texture sampler with black borders
sampler2D vectorscopeSampler
{
	Texture = vectorscopeTex;
	MagFilter = POINT;
	AddressU = BORDER;
	AddressV = BORDER;
};

// Define screen texture with sRGB blending for nice anti-aliasing
#if BUFFER_COLOR_BIT_DEPTH!=10
	sampler2D BackBuffer
	{
		Texture = ReShade::BackBufferTex;
		SRGBTexture = true;
	};
#endif


// Functions

// Returns bounds between full screen and native size
float3 getScopeOffset()
{
	float3 scopeOffset;
	// Get scope offset from screen edge
	scopeOffset.xy = SCOPES_TEXTURE_SIZE*BUFFER_PIXEL_SIZE*SCOPES_BORDER_SIZE;
	// Accommodate for scale-up
#if BUFFER_WIDTH>BUFFER_HEIGHT // Panorama
	scopeOffset.xy = lerp(scopeOffset.xy, float2(BUFFER_HEIGHT*BUFFER_RCP_WIDTH*0.5, 0.5), ScopePosition.z);
#elif BUFFER_WIDTH<BUFFER_HEIGHT // Portrait
	scopeOffset.xy = lerp(scopeOffset.xy, float2(0.5, BUFFER_WIDTH*BUFFER_RCP_HEIGHT*0.5), ScopePosition.z);
#else // Square
	scopeOffset.xy = lerp(scopeOffset.xy, float2(0.5, 0.5), ScopePosition.z);
#endif

	// Limit offset to bounds
	scopeOffset.xy = lerp(scopeOffset.xy, 1.0-scopeOffset.xy, ScopePosition.xy);
	// Get scale limited to bounds
	scopeOffset.z = lerp(SCOPES_TEXTURE_SIZE*max(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT), 0.5/SCOPES_BORDER_SIZE, ScopePosition.z);

	// Offset and scale
	return scopeOffset;
}


// Shaders

#if SCOPES_FAST_CHECKERBOARD
	// Clear render target
	float4 ClearRenderTargetPS(float4 pos : SV_Position, float2 texCoord : TEXCOORD0) : SV_Target
	{
		// Store 4-frames as 4-channels
		// Here, mask stores maximum possible value, for each channel
		static const float4 channelMask[4] =
			{
				float4(0, 1, 1, 1)*(ScopeBrightness*SCOPES_TEXTURE_SIZE/4), // Frame 0
				float4(1, 0, 1, 1)*(ScopeBrightness*SCOPES_TEXTURE_SIZE/4), // Frame 1
				float4(1, 1, 0, 1)*(ScopeBrightness*SCOPES_TEXTURE_SIZE/4), // Frame 2
				float4(1, 1, 1, 0)*(ScopeBrightness*SCOPES_TEXTURE_SIZE/4)  // Frame 3
			};

		return channelMask[FRAME_INDEX%4]; // This mask uses MIN filter
	}
#endif

// Gather chroma statistics and store in a vertex position
void GatherStatsVS(uint pixelID : SV_VertexID, out float4 position : SV_Position, out float2 chroma : TEXCOORD0)
{
	// Initialize some values
	position.z = 0.0; // Not used
	position.w = 0.5; // Fill texture

	uint2 texelCoord; // Get pixel coordinates from vertex ID
#if SCOPES_FAST_CHECKERBOARD
	// Get 1/4-resolution pixel coordinates
	texelCoord.x = pixelID%(BUFFER_WIDTH/2)*2;
	texelCoord.y = pixelID/(BUFFER_WIDTH/2)*2;

	// Checkerboard pattern offset cycle
	static const uint2 offset_Z[4] = // Z-sampling pattern
		{
			uint2(0, 0), // Frame 0
			uint2(1, 0), // Frame 1
			uint2(0, 1), // Frame 2
			uint2(1, 1)  // Frame 3
		};
	// Offset sampled pixel in 4-frame cycle
	texelCoord += offset_Z[FRAME_INDEX%4];
#else
	texelCoord.x = pixelID%BUFFER_WIDTH;
	texelCoord.y = pixelID/BUFFER_WIDTH;
#endif

	// Get current-pixel color data, convert to chroma CbCr and store as position
	position.xy = chroma = mul(ChromaMtx, tex2Dfetch(ReShade::BackBuffer, texelCoord).rgb);
}

// Add pixel data to vectorscope image
#if SCOPES_FAST_CHECKERBOARD
	void GatherStatsPS(float4 pos : SV_Position, float2 chroma : TEXCOORD0, out float4 values : SV_Target)
	{
		// Store 4-frames as 4-channels
		static const float4 channelMask[4] =
			{
				float4(1, 0, 0, 0), // Frame 0
				float4(0, 1, 0, 0), // Frame 1
				float4(0, 0, 1, 0), // Frame 2
				float4(0, 0, 0, 1)  // Frame 3
			};

		// Isolate each channel for each frame
		values = channelMask[FRAME_INDEX%4]*(SCOPES_BRIGHTNESS*ScopeBrightness);
	}
#else
	void GatherStatsPS(float4 pos : SV_Position, float2 chroma : TEXCOORD0, out float value : SV_Target)
	{ value = SCOPES_BRIGHTNESS*ScopeBrightness; }
#endif

#if !SCOPES_FAST_UI
	/** Pixel scale function for anti-aliasing by Jakub Max Fober
	This algorithm is derived from scientific paper:
	arXiv: 20104077 [cs.GR] (2020) */
	float getPixelScale(float gradient)
	{
		// Calculate gradient delta between pixels
		float2 del = float2(ddx(gradient), ddy(gradient));
		// Get reciprocal delta length for anti-aliasing
		return rsqrt(dot(del, del));
	}

	// Function that returns color and alpha-mask for the UI
	float4 DrawUI(float2 texCoord)
	{
		// Convert texture coordinates to chroma coordinates
		texCoord.y = -texCoord.y;
		// Get user interface lines as an array
		float2 hexagonVert[6] = {
			mul(ChromaMtx, float3(1, 0, 0)), // R
			mul(ChromaMtx, float3(1, 1, 0)), // Yl
			mul(ChromaMtx, float3(0, 1, 0)), // G
			mul(ChromaMtx, float3(0, 1, 1)), // Cy
			mul(ChromaMtx, float3(0, 0, 1)), // B
			mul(ChromaMtx, float3(1, 0, 1))  // Mg
		};
		// Formula for skin-tone color engineered by JMF
		float3 skintoneColor = float3(1.0, 1.0-GOLDEN_RATIO, 0.0)*GOLDEN_RATIO;
		// Get skin-tone CbCr position from skin-tone RGB color
		float2 skintonePos = mul(ChromaMtx, skintoneColor);

		// Get rotation vectors for each line of hexagon, used as signed-distance field
		float2 hexagonLine[6] =
		{
			float2(hexagonVert[0].y-hexagonVert[1].y, hexagonVert[1].x-hexagonVert[0].x), // R-Yl
			float2(hexagonVert[1].y-hexagonVert[2].y, hexagonVert[2].x-hexagonVert[1].x), // Yl-G
			float2(hexagonVert[2].y-hexagonVert[3].y, hexagonVert[3].x-hexagonVert[2].x), // G-Cy
			float2(hexagonVert[3].y-hexagonVert[4].y, hexagonVert[4].x-hexagonVert[3].x), // Cy-B
			float2(hexagonVert[4].y-hexagonVert[5].y, hexagonVert[5].x-hexagonVert[4].x), // B-Mg
			float2(hexagonVert[5].y-hexagonVert[0].y, hexagonVert[0].x-hexagonVert[5].x)  // Mg-R
		};
		// Normalize lines
		[unroll] for (uint i=0; i<6; i++) hexagonLine[i] /= dot(hexagonLine[i], hexagonVert[i]);
		// Normalize skin-tone line
		float2 skintoneLine = skintonePos/dot(skintonePos, skintonePos);

		// Initialize variables
		float hexagonGradient[6];
		float skintoneGradient[2];
		float gradientPixelScale[7];
		[unroll] for (uint i=0; i<6; i++)
		{
			// Get R-Yl-G-Cy-B-Mg hexagon signed-distance field
			hexagonGradient[i] = dot(hexagonLine[i], texCoord)-1.0;
			// Get pixel scale for anti-aliasing
			gradientPixelScale[i] = getPixelScale(hexagonGradient[i]);
		}
		// Get skin-tone line signed-distance field
		skintoneGradient[0] = dot(skintoneLine, texCoord);
		// Get pixel scale for anti-aliasing
		gradientPixelScale[6] = getPixelScale(skintoneGradient[0]);
		// Get skin-tone line signed-distance field, rotated 90 degrees
		skintoneGradient[1] = dot(float2(-skintoneLine.y, skintoneLine.x), texCoord);

		// Generate hexagon signed-distance field
		float hexagonSdf100 = -SCOPE_LINE_WIDTH;
		float hexagonSdf75 = -SCOPE_LINE_WIDTH;
		[unroll] for (uint i=0; i<6; i++)
		{
			// Combine 6-edges distance fields into a single hexagon SDF
			hexagonSdf100 = max(hexagonSdf100, hexagonGradient[i]*gradientPixelScale[i]);
			hexagonSdf75 = max(hexagonSdf75, (hexagonGradient[i]+0.25)*gradientPixelScale[i]);
		}

		// Initialize UI color
		float4 uiColor; uiColor.a = 0;
		// Add 100% and 75% saturation hexagon to UI mask
		uiColor.a += saturate(SCOPE_LINE_WIDTH-abs(hexagonSdf100));
		uiColor.a += saturate(SCOPE_LINE_WIDTH-abs(hexagonSdf75));

		// Generate skin-tone line anti-aliased bounds mask
		skintoneGradient[0] = saturate((0.5-abs(skintoneGradient[0]-0.5))*gradientPixelScale[6]+0.5);
		// Generate skin-tone line anti-aliased edge
		skintoneGradient[1] = saturate(SCOPE_LINE_WIDTH-abs(skintoneGradient[1])*gradientPixelScale[6]);

		// Add skin-tone line to UI mask
		uiColor.a += skintoneGradient[0]*skintoneGradient[1];

		// Make skin-tone line constant-color
		if (texCoord.x > skintonePos.x &&
			texCoord.y < skintonePos.y &&
			texCoord.x < 0.0 &&
			texCoord.y > 0.0) // Inside bounding-box
		texCoord = skintonePos/GOLDEN_RATIO;

		// Output UI color
		uiColor.rgb = float3(lerp(1.0, 1.0-GOLDEN_RATIO, ScopeUITransparency), texCoord); // Get UI color in YCbCr
		uiColor.rgb = TO_LINEAR_GAMMA( saturate(mul(RgbMtx, uiColor.rgb)) ); // Convert to RGB

		uiColor.a *= TO_LINEAR_GAMMA(ScopeUITransparency); // Apply UI transparency

		return uiColor;
	}
#endif


// Display vectorscope texture
void DisplayScopePS(float4 pos : SV_Position, float2 texCoord : TEXCOORD0, out float3 color : SV_Target)
{
	// Get background color
#if BUFFER_COLOR_BIT_DEPTH!=10
	float3 background = tex2D(BackBuffer, texCoord).rgb;
#else
	float3 background = tex2D(ReShade::BackBuffer, texCoord).rgb;
#endif

	// Get UI offset
	float3 scopeOffset = getScopeOffset();
	// Move vectorscope UI position
	texCoord -= scopeOffset.xy;
	// Correct aspect ratio
#if BUFFER_WIDTH>BUFFER_HEIGHT // Panorama
	texCoord.x *= BUFFER_ASPECT_RATIO;
#elif BUFFER_WIDTH<BUFFER_HEIGHT // Portrait
	texCoord.y *= BUFFER_HEIGHT*BUFFER_RCP_WIDTH;
#endif
	// Scale vectorscope UI
	texCoord /= scopeOffset.z;

	// Generate round border mask
	float borderMask = clamp(
		0.5-(length(texCoord)-SCOPES_BORDER_SIZE)*min(BUFFER_WIDTH, BUFFER_HEIGHT)*scopeOffset.z, // Scale to pixel size
		0.0, 1.0 // Clamp to visible range
	);

	// Determine vectorscope look
	color = float3(GOLDEN_RATIO, texCoord.x, -texCoord.y); // Base color in YCbCr
	color = mul(RgbMtx, color); // Convert to RGB
	// Mask vectorscope image
#if SCOPES_FAST_CHECKERBOARD
	color *= dot(tex2D(vectorscopeSampler, texCoord+0.5), 1); // Combine all frames encoded in 4-color channels
#else
	color *= tex2D(vectorscopeSampler, texCoord+0.5).r;
#endif

	// Blend with background
	color = lerp(background, color, borderMask*ScopeTransparency);
	color = saturate(color); // Clamp values

#if !SCOPES_FAST_UI
	// Draw anti-aliased UI within bounding-box
	if (all(abs(texCoord)<=SCOPES_BORDER_SIZE))
	{
		// Get the anti-aliased UI color and alpha
		float4 UI = DrawUI(texCoord);
		// Apply the UI to background picture
		color = lerp(color, UI.rgb, UI.a);
	}
#endif
}

#if SCOPES_FAST_UI
	// Generate user interface
	void UserInterfaceVS(uint vertexID : SV_VertexID, out float4 position : SV_Position, out float2 chroma : TEXCOORD0)
	{
		// Initialize some values
		position.z = 0.0; // Not used
		position.w = 1.0; // Not used

		// Get user interface lines as an array
		static const float2 hexagonVert[12] = {
			mul(ChromaMtx, float3(1, 0, 0)), mul(ChromaMtx, float3(1, 1, 0)), // R-Yl
			mul(ChromaMtx, float3(1, 1, 0)), mul(ChromaMtx, float3(0, 1, 0)), // Yl-G
			mul(ChromaMtx, float3(0, 1, 0)), mul(ChromaMtx, float3(0, 1, 1)), // G-Cy
			mul(ChromaMtx, float3(0, 1, 1)), mul(ChromaMtx, float3(0, 0, 1)), // Cy-B
			mul(ChromaMtx, float3(0, 0, 1)), mul(ChromaMtx, float3(1, 0, 1)), // B-Mg
			mul(ChromaMtx, float3(1, 0, 1)), mul(ChromaMtx, float3(1, 0, 0))  // Mg-R
		};
		// Get skin-tone CbCr position from skin-tone RGB color
		// Formula for skin-tone color engineered by JMF
		static const float2 skintonePos = mul(ChromaMtx, float3(1.0, 1.0-GOLDEN_RATIO, 0.0)*GOLDEN_RATIO);

		// 100% saturation ring
		if (vertexID<12) position.xy = chroma = hexagonVert[vertexID];
		// 75% saturation ring
		else if (vertexID<24) position.xy = chroma = hexagonVert[vertexID-12]*0.75;
		else // Skin-tone line
		{
			chroma = skintonePos/GOLDEN_RATIO; // Save skin-tone chroma
			position.xy = skintonePos*(vertexID%2); // Skin-tone line position
		}

		// Get UI offset
		float3 scopeOffset = getScopeOffset()*2.0;
		// Scale vectorscope UI
		position.xy *= scopeOffset.z;
		// Correct aspect ratio
	#if BUFFER_WIDTH>BUFFER_HEIGHT // Panorama
		position.x *= BUFFER_HEIGHT*BUFFER_RCP_WIDTH;
	#elif BUFFER_WIDTH<BUFFER_HEIGHT // Portrait
		position.y *= BUFFER_ASPECT_RATIO;
	#endif
		// Move vectorscope UI position
		position.x += scopeOffset.x-1.0;
		position.y -= scopeOffset.y-1.0;
	}

	// Color user interface
	void UserInterfacePS(float4 pos : SV_Position, float2 chroma : TEXCOORD0, out float4 color : SV_Target)
	{
		color.a = TO_LINEAR_GAMMA(ScopeUITransparency);
		// Get UI color in YCbCr
		color.rgb = float3(lerp(1.0, 1.0-GOLDEN_RATIO, ScopeUITransparency), chroma);
		color.rgb = TO_LINEAR_GAMMA( saturate(mul(RgbMtx, color.rgb)) ); // Convert to RGB
	}
#endif


// Output
technique Vectorscope <
	ui_label = "Vectorscope analysis";
	ui_tooltip =
		"This effect will analyze colors using vectorscope color-wheel"
		"\n\nunder CC BY-NC-ND 3.0 license, (c) 2021 Jakub Maksymilian Fober"
		"\nfor more info, game-production use, contact jakub.m.fober@pm.me";
>
{
#if SCOPES_FAST_CHECKERBOARD
	pass ClearRenderTarget
	{
		BlendEnable = true;
		BlendOp = MIN;
		BlendOpAlpha = MIN;
		// Background
		DestBlend = ONE;
		DestBlendAlpha = ONE;
		// Foreground
		SrcBlend = ONE;
		SrcBlendAlpha = ONE;

		RenderTarget = vectorscopeTex;

		VertexShader = PostProcessVS;
		PixelShader = ClearRenderTargetPS;
	}
	pass AnalyzeColor
	{
		VertexCount = (BUFFER_HEIGHT/2)*(BUFFER_WIDTH/2);
		ClearRenderTargets = false;

		BlendOpAlpha = ADD;
		DestBlendAlpha = ONE; // Background
		SrcBlendAlpha = ONE;  // Foreground
#else
	pass AnalyzeColor
	{
		VertexCount = BUFFER_HEIGHT*BUFFER_WIDTH;
		ClearRenderTargets = true;
#endif
		PrimitiveTopology = POINTLIST;

		BlendEnable = true;
		BlendOp = ADD;
		DestBlend = ONE; // Background
		SrcBlend = ONE;  // Foreground

		RenderTarget = vectorscopeTex;

		VertexShader = GatherStatsVS;
		PixelShader = GatherStatsPS;
	}
	pass DisplayVectorscope
	{
		SRGBWriteEnable = true; // Nice anti-aliasing

		VertexShader = PostProcessVS;
		PixelShader = DisplayScopePS;
	}
#if SCOPES_FAST_UI
	pass DrawUI
	{
		SRGBWriteEnable = true; // Compatibility with anti-aliased UI

		VertexCount = (6+6+1)*2; // Two hexagons plus one skin-tone line
		PrimitiveTopology = LINELIST;

		BlendEnable = true;
		SrcBlend = SRCALPHA;     // Foreground
		DestBlend = INVSRCALPHA; // Background

		VertexShader = UserInterfaceVS;
		PixelShader = UserInterfacePS;
	}
#endif
}