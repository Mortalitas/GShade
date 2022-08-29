/** Lens Distortion PS, version 1.0.0

This code © 2022 Jakub Maksymilian Fober

This work is licensed under the Creative Commons
Attribution-NonCommercial-NoDerivs 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-nc-nd/3.0/.

Copyright owner further grants permission for commercial reuse of
image recordings derived from the Work (e.g. let's play video,
gameplay stream with ReShade filters, screenshots with ReShade
filters) provided that any use is accompanied by the name of the
shader used and a link to ReShade website https://reshade.me.

If you need additional licensing for your commercial product, contact
me at jakub.m.fober@protonmail.com.

For updates visit GitHub repository at
https://github.com/Fubaxiusz/fubax-shaders.

This shader version is based upon following research papers:
	Temporally-smooth Antialiasing and Lens Distortion
	with Rasterization Map
	arXiv:2010.04077 [cs.GR] (2020)
	https://arxiv.org/abs/2010.04077
and
	Pantomorphic Perspective for Immersive Imagery
	arXiv:2102.12682 [cs.GR] (2021)
	https://arxiv.org/abs/2102.12682
by Fober, J. M.
*/

	/* MACROS */

// Alternative anamorphic mode
#ifndef PATNOMORPHIC_LENS_MODE
	#define PATNOMORPHIC_LENS_MODE 0
#endif

	/* COMMONS */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "ColorAndDither.fxh"

	/* MENU */

uniform bool ShowGrid < __UNIFORM_INPUT_BOOL1
	ui_label = "Display calibration grid";
	ui_tooltip =
		"This can be used in conjunction with Image.fx\n"
		"to display real-world camera lens image and\n"
		"match its distortion profile.";
> = false;

#if PATNOMORPHIC_LENS_MODE==0
	uniform float4 K < __UNIFORM_DRAG_FLOAT4
		ui_min = -0.2;
		ui_max =  0.2;
		ui_label = "Radial distortion";
		ui_tooltip = "Radial distortion coefficients K1, K2, K3, K4.";
		ui_category = "Geometrical lens distortions";
	> = 0f;

	uniform float S < __UNIFORM_SLIDER_FLOAT1
		ui_min = 1f;
		ui_max = 2f;
		ui_step = 0.05;
		ui_label = "Anamorphic";
		ui_tooltip =
			"Anamorphic squeeze factor S,\n"
			"affects vertical axis:\n"
			"\n"
			"1      spherical lens\n"
			"1.25   Ultra Panavision 70\n"
			"1.33   16x9 TV\n"
			"1.5    Technirama\n"
			"1.6    digital anamorphic\n"
			"1.8    4x3 full-frame\n"
			"2      golden-standard";
		ui_category = "Geometrical lens distortions";
	> = 1f;
#else
	uniform float4 Ky < __UNIFORM_DRAG_FLOAT4
		ui_min = -0.2;
		ui_max =  0.2;
		ui_label = "Radial distortion - vertical";
		ui_tooltip =
			"Radial distortion coefficients K1, K2, K3, K4\n"
			"for vertical distortion.";
		ui_category = "Geometrical lens distortions";
	> = 0f;

	uniform float4 Kx < __UNIFORM_DRAG_FLOAT4
		ui_min = -0.2;
		ui_max =  0.2;
		ui_label = "Radial distortion - horizontal";
		ui_tooltip =
			"Radial distortion coefficients K1, K2, K3, K4\n"
			"for horizontal distortion.";
		ui_category = "Geometrical lens distortions";
	> = 0f;
#endif

// Color

uniform bool UseVignette < __UNIFORM_DRAG_FLOAT2
	ui_label = "Brightness aberration";
	ui_tooltip = "Automatically change image brightness based on projection area.";
	ui_category = "Color aberrations";
> = true;

uniform float T < __UNIFORM_DRAG_FLOAT1
	ui_min = -0.2;
	ui_max =  0.2;
	ui_label = "Chromatic radius";
	ui_tooltip = "Color separation amount using T.";
	ui_category = "Color aberrations";
> = -0.2;

// Miss-alignment

uniform float2 P < __UNIFORM_DRAG_FLOAT2
	ui_min = -0.1;
	ui_max =  0.1;
	ui_label = "Decentering";
	ui_tooltip = "Correct image sensor alignment to the optical axis, using P1, P2.";
	ui_category = "Elements misalignment";
> = 0f;

uniform float2 Q < __UNIFORM_DRAG_FLOAT2
	ui_min = -0.05;
	ui_max =  0.05;
	ui_label = "Thin prism";
	ui_tooltip = "Correct optical elements offset from the optical axis, using Q1, Q2.";
	ui_category = "Elements misalignment";
> = 0f;

uniform float2 C < __UNIFORM_DRAG_FLOAT2
	ui_min = -0.05;
	ui_max =  0.05;
	ui_label = "Center";
	ui_tooltip = "Offset lens optical center, to correct image cropping, using C1, C2.";
	ui_category = "Elements misalignment";
> = 0f;

// Border

uniform bool MirrorBorder < __UNIFORM_INPUT_BOOL1
	ui_label = "Mirror on border";
	ui_tooltip = "Choose between mirrored image or original background on the border.";
	ui_category = "Border";
	ui_category_closed = true;
> = true;

uniform bool BorderVignette < __UNIFORM_INPUT_BOOL1
	ui_label = "Brightness aberration on border";
	ui_tooltip = "Apply brightness aberration effect to the border.";
	ui_category = "Border";
> = true;

uniform float4 BorderColor < __UNIFORM_COLOR_FLOAT4
	ui_label = "Border color";
	ui_tooltip = "Use alpha to change border transparency.";
	ui_category = "Border";
> = float4(0.027, 0.027, 0.027, 0.96);

uniform float BorderCorner < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0f; ui_max = 1f;
	ui_label = "Corner radius";
	ui_tooltip = "Value of 0.0 gives sharp corners.";
	ui_category = "Border";
> = 0.062;

uniform uint BorderGContinuity < __UNIFORM_SLIDER_INT1
	ui_min = 1u; ui_max = 3u;
	ui_label = "Corner roundness";
	ui_tooltip =
		"G-surfacing continuity level for the corners:\n"
		"\n"
		"G0   sharp\n"
		"G1   circular\n"
		"G2   smooth\n"
		"G3   very smooth";
	ui_category = "Border";
> = 3u;

// GRID

uniform float DimGridBackground < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 1f; ui_step = 0.1;
	ui_label = "Dim background";
	ui_tooltip = "Adjust background visibility.";
	ui_category = "Grid";
	ui_category_closed = true;
	ui_text =
		"Use this in conjunction with Image.fx, to match\n"
		"lens distortion with a real-world camera profile.";
> = 1f;

uniform uint GridLook < __UNIFORM_COMBO_INT1
	ui_items =
		"yellow grid\0"
		"black grid\0"
		"white grid\0"
		"red-green grid\0";
	ui_label = "Grid look";
	ui_tooltip = "Select look of the grid.";
	ui_category = "Grid";
> = 0u;

uniform uint GridSize < __UNIFORM_SLIDER_INT1
	ui_min = 1u; ui_max = 32u;
	ui_label = "Grid size";
	ui_tooltip = "Adjust calibration grid size.";
	ui_category = "Grid";
> = 16u;

uniform uint GridWidth < __UNIFORM_SLIDER_INT1
	ui_min = 1u; ui_max = 8u;
	ui_label = "Grid bar width";
	ui_tooltip = "Adjust calibration grid bar width in pixels.";
	ui_category = "Grid";
> = 1u;

// Performance

uniform uint ChromaticSamples < __UNIFORM_SLIDER_INT1
	ui_min = 6u; ui_max = 32u; ui_step = 2u;
	ui_label = "Chromatic aberration samples";
	ui_tooltip =
		"Amount of samples (steps) for color fringing.\n"
		"Only even numbers are accepted, odd numbers will be clamped.";
	ui_category = "Performance";
> = 8u;

	/* TEXTURES */

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
	SRGBTexture = true;
#endif
	// Border style
	AddressU = MIRROR;
	AddressV = MIRROR;
};

	/* FUNCTIONS */

// Get reciprocal screen aspect ratio (1/x)
#define BUFFER_RCP_ASPECT_RATIO (BUFFER_HEIGHT*BUFFER_RCP_WIDTH)

/** G continuity distance function by Jakub Max Fober.
	Determined empirically. (G from 0, to 3)
		G=0 .... Sharp corners
		G=1 .... Round corners
		G=2 .... Smooth corners
		G=3 .... Luxury corners
*/
float glength(uint G, float2 pos)
{
	// Sharp corner
	if (G==0u) return max(abs(pos.x), abs(pos.y)); // G0
	// Higher-power length function
	pos = pow(abs(pos), ++G); // Power of G+1
	return pow(pos.x+pos.y, rcp(G)); // Power G+1 root
}

/** Linear pixel step function for anti-aliasing by Jakub Max Fober.
	This algorithm is part of scientific paper:
	· arXiv:2010.04077 [cs.GR] (2020)
*/
float aastep(float grad)
{
	// Differential vector
	float2 Del = float2(ddx(grad), ddy(grad));
	// Gradient normalization to pixel size, centered at the step edge
	return saturate(rsqrt(dot(Del, Del))*grad+0.5); // half-pixel offset
}

/** Chromatic aberration hue color generator by Fober J. M.
    hue = index/samples;
    where index ∊ [0, samples-1] and samples is an even number
*/
float3 Spectrum(float hue)
{
	float3 hueColor;
	hue *= 4f; // Slope
	hueColor.rg = hue-float2(1f, 2f);
	hueColor.rg = saturate(1.5-abs(hueColor.rg));
	hueColor.r += saturate(hue-3.5);
	hueColor.b = 1f-hueColor.r;
	return hueColor;
}

// Border mask shader with rounded corners
float GetBorderMask(float2 borderCoord)
{
	// Get coordinates for each corner
	borderCoord = abs(borderCoord);
	if (BorderGContinuity!=0u && BorderCorner!=0f) // If round corners
	{
		// Correct corner aspect ratio
		if (BUFFER_ASPECT_RATIO>1f) // If in landscape mode
			borderCoord.x = borderCoord.x*BUFFER_ASPECT_RATIO+(1f-BUFFER_ASPECT_RATIO);
		else if (BUFFER_ASPECT_RATIO<1f) // If in portrait mode
			borderCoord.y = borderCoord.y*BUFFER_RCP_ASPECT_RATIO+(1f-BUFFER_RCP_ASPECT_RATIO);
		// Generate scaled coordinates
		borderCoord = max(borderCoord+(BorderCorner-1f), 0f)/BorderCorner;

		// Round corner
		return aastep(glength(BorderGContinuity, borderCoord)-1f); // with G1 to G3 continuity
	}
	else // Just sharp corner, G0
		return aastep(glength(0u, borderCoord)-1f);
}

	/* SHADERS */

// Vertex shader generating a triangle covering the entire screen
void LensDistortVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 viewCoord : TEXCOORD)
{
	// Define vertex position
	const float2 vertexPos[3] =
	{
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	// Export screen centered texture coordinates
	viewCoord.x =  vertexPos[id].x;
	viewCoord.y = -vertexPos[id].y;
	// Correct aspect ratio, normalized to the corner
	viewCoord *= normalize(BUFFER_SCREEN_SIZE);
	// Export vertex position
	position = float4(vertexPos[id], 0f, 1f);
}

// Lens distortion pixel shader
void LensDistortPS(float4 pixelPos : SV_Position, float2 viewCoord : TEXCOORD, out float3 color : SV_Target)
{
	// Bypass all effects
#if PATNOMORPHIC_LENS_MODE==0
	if (!ShowGrid && all(K==0f) && all(P==0f) && all(Q==0f))
#else
	if (!ShowGrid && all(Kx==0f) && all(Ky==0f) && all(P==0f) && all(Q==0f))
#endif
	{
		color = tex2Dfetch(ReShade::BackBuffer, uint2(pixelPos.xy)).rgb;
		return;
	}

	// Get aspect-ratio transform vector for the view coordinates
	const float2 aspectScalar = 0.5/normalize(BUFFER_SCREEN_SIZE);

#if PATNOMORPHIC_LENS_MODE==0
	bool isDistorted = any(K!=0f) || any(P!=0f) || any(Q!=0f);
#else
	bool isDistorted = any(Kx!=0f) || any(Ky!=0f) || any(P!=0f) || any(Q!=0f);
#endif
	if (isDistorted) // distort coordinates
	{
		viewCoord -= C; // Cardinal offset (a)
#if PATNOMORPHIC_LENS_MODE==0
		// Get anamorphic coordinates
		float2 anamViewCoord = viewCoord; anamViewCoord.y /= S;
		// Get radius at increasing even powers
		float4 anamorphR;
		anamorphR[0] = dot(anamViewCoord, anamViewCoord); // Anamorphic r²
		anamorphR[1] = anamorphR[0]*anamorphR[0]; // Anamorphic r⁴
		anamorphR[2] = anamorphR[1]*anamorphR[0]; // Anamorphic r⁶
		anamorphR[3] = anamorphR[2]*anamorphR[0]; // Anamorphic r⁸
		float R2 = dot(viewCoord, viewCoord); // r²
		// Primary distortion
		viewCoord *=
			  rcp(1f+dot(K, anamorphR)) // Radial distortion
			+ dot(viewCoord, P); // Decentering
		// Secondary distortion
		viewCoord +=
			  R2*Q // Thin prism
			+ C;     // Cardinal offset (b)
#else
		// Get radius at increasing even powers
		float4 R;
		R[0] = dot(viewCoord, viewCoord); // r²
		R[1] = R[0]*R[0]; // r⁴
		R[2] = R[1]*R[0]; // r⁶
		R[3] = R[2]*R[0]; // r⁸
		// Get pantomorphic interpolation weight
		float2 phiWeight = viewCoord*viewCoord/R[0];
		// Pantomorphic distortion
		viewCoord *=
			  rcp(1f+dot(Kx, R))*phiWeight.x // Horizontal radial distortion
			+ rcp(1f+dot(Ky, R))*phiWeight.y // Vertical radial distortion
			+ dot(viewCoord, P); // Decentering
		// Secondary distortion
		viewCoord +=
			  R[0]*Q // Thin prism
			+ C;     // Cardinal offset (b)
#endif
	}

	// Transform view coordinates to texture coordinates
	float2 texCoord = viewCoord*aspectScalar+0.5;

	if (isDistorted && T!=0f && !ShowGrid) // generate chromatic aberration
	{
		// Get unaltered texture coordinates
		float2 orygTexCoord = (pixelPos.xy+0.5)*BUFFER_PIXEL_SIZE;
		// Get distortion offset vector
		float2 distortion = texCoord-orygTexCoord;
		// Get even number of samples to avoid color cast
		uint evenSampleCount = ChromaticSamples-ChromaticSamples%2u;
		// Sample background with multiple color filters at multiple offsets
		color = 0f; // initialize color
		for (uint i=0u; i<evenSampleCount; i++)
			color += tex2Dlod(
				BackBuffer, // Image source
				float4(
					(T*(i/float(evenSampleCount-1u)-0.5)+1f) // Aberration offset
					*distortion // Distortion coordinates
					+orygTexCoord, // Original coordinates
				0f, 0f)
			).rgb
			*Spectrum(i/float(evenSampleCount)); // Blur layer color
		// Preserve brightness
		color *= 2f/evenSampleCount;
	}
	else if (ShowGrid) // generate lens-match grid
	{
		// Sample background without distortion
		color = tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb;

		// Get coordinates pixel size
		float2 delX = float2(ddx(viewCoord.x), ddy(viewCoord.x));
		float2 delY = float2(ddx(viewCoord.y), ddy(viewCoord.y));
		// Scale coordinates to grid size and center
		viewCoord = frac(viewCoord*GridSize)-0.5;
		/* Scale coordinates to pixel size for anti-aliasing of grid
		   using anti-aliasing step function from research paper
		   arXiv:2010.04077 [cs.GR] (2020) */
		viewCoord *= float2(
			rsqrt(dot(delX, delX)),
			rsqrt(dot(delY, delY))
		)/GridSize; // Pixel density
		// Set grid with
		viewCoord = GridWidth-abs(viewCoord);
		viewCoord = saturate(viewCoord); // Clamp values

		// Adjust grid look
		color *= DimGridBackground;
		switch (GridLook)
		{
			default:
			// Yellow
				color = lerp(float3(1f, 1f, 0f), color, (1f-viewCoord.x)*(1f-viewCoord.y));
				break;
			case 1:
			// Black
				color *= (1f-viewCoord.x)*(1f-viewCoord.y);
				break;
			case 2:
			// White
				color = 1f-(1f-viewCoord.x)*(1f-viewCoord.y)*(1f-color);
				break;
			case 3:
			// Color red-green
				color = lerp(color, float3(1f, 0f, 0f), viewCoord.y);
				color = lerp(color, float3(0f, 1f, 0f), viewCoord.x);
				break;
		}
	}
	else // sample background with distortion
		color = tex2D(BackBuffer, texCoord).rgb;


	if (!ShowGrid) // draw border and vignette
	{
		// Get vignette
		texCoord *= BUFFER_SCREEN_SIZE;
		float vignetteMask = UseVignette? ddx(texCoord.x)*ddy(texCoord.y) : 1f;

		// Aspect ratio back to square, normalized to the edges
		viewCoord *= aspectScalar*2f;
		// Get border
		float3 border = lerp(
			// Border background
			MirrorBorder? color : tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb,
#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
			TO_LINEAR_GAMMA_HQ(BorderColor.rgb), // Border color
			TO_LINEAR_GAMMA_HQ(BorderColor.a)    // Border alpha
#else
			BorderColor.rgb, // Border color
			BorderColor.a    // Border alpha
#endif
		);

		// Apply vignette with border
		color = BorderVignette?
			vignetteMask*lerp(color, border, GetBorderMask(viewCoord)): // Vignette on border
			lerp(vignetteMask*color, border, GetBorderMask(viewCoord)); // Vignette only inside
		color = saturate(color);
	}

#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
	color = TO_DISPLAY_GAMMA_HQ(color); // Correct gamma
	color = BlueNoise::dither(uint2(pixelPos.xy), color); // Dither
#endif
}

	/* OUTPUT */

technique LensDistort
<
	ui_label = "Lens distortion";
	ui_tooltip =
		"Apply camera lens distortion to the image.\n"
		"\n"
		"	· Brown-Conrady lens division model\n"
#if PATNOMORPHIC_LENS_MODE==0
		"	· Anamorphic distortion\n"
#else
		"	· Pantomorphic distortion\n"
#endif
		"	· Chromatic aberration\n"
		"	· Lens vignetting\n"
		"\n"
		"The algorithm is part of a scientific papers:\n"
		"	arXiv:2010.04077 [cs.GR] (2020)\n"
		"	arXiv:2102.12682 [cs.GR] (2021)\n"
		"\n"
		"This effect © 2022 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-NC-ND 3.0 + additional permissions (see source).";
>
{
	pass
	{
		VertexShader = LensDistortVS;
		PixelShader = LensDistortPS;
	}
}
