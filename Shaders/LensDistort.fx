/*------------------.
| :: Description :: |
'-------------------/

Lens Distortion PS (version 1.4.1)

Copyright:
This code © 2022-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons Attribution-NonCommercial-
NoDerivs 3.0 Unported License. To view a copy of this license, visit
http://creativecommons.org/licenses/by-nc-nd/3.0/

Additional permissions under Creative Commons Plus (CC+):

§ 1. The copyright owner further grants permission for commercial reuse of image
recordings based on the work (e.g., Let's Play videos, gameplay streams, and
screenshots featuring ReShade filters). Any such use must include credit to the
creator and the name of the used shader.
 Intent §: To facilitate non-corporate, common use of the shader at no cost.
Outcome §: That recognition of the work in any derivative images is ensured.

§ 2. Additionally, permission is granted for the translation of the front-end UI
text within this shader.
 Intent §: To increase accessibility and understanding across different
languages.
Outcome §: That usability across users from diverse linguistic backgrounds is
promoted, allowing them to fully engage with the shader.

Contact:
If you want additional licensing for your commercial product, please contact me:
jakub.m.fober@protonmail.com

██████████▀▀▀▀▀      ▄▄▄▄▄▄▄      ▀▀▀▀▀███████████
██▀▀▀           █████▀▀▀▀▀▀▀█████            ▀▀▀██
▀               ███           ███                ▀
                ██             ██
                ██             ██
                ██             ██
▄               ███           ███                ▄
██▄▄▄           █████▄▄▄▄▄▄▄█████            ▄▄▄██
██████████▄▄▄▄▄      ▀▀▀▀▀▀▀      ▄▄▄▄▄███████████
  P   A   N   T   O   M   O   R   P   H   I   C

For updates visit GitHub repository at
https://github.com/Fubaxiusz/fubax-shaders.

About:
This shader version is based upon following research article:
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

/*-------------.
| :: Macros :: |
'-------------*/

// Alternative anamorphic mode
#ifndef PATNOMORPHIC_LENS_MODE
	#define PATNOMORPHIC_LENS_MODE 0
#endif
// Parallax aberration mode
#ifndef PARALLAX_ABERRATION
	#define PARALLAX_ABERRATION 1
#endif
// Maximum number of samples for chromatic aberration
#define CHROMATIC_ABERRATION_MAX_SAMPLES 64u
#if PARALLAX_ABERRATION
	// Maximum number of samples for parallax aberration
	#define PARRALLAX_ABERRATION_MAX_SAMPLES 255u
#endif

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"
#include "ColorConversion.fxh"
#include "LinearGammaWorkflow.fxh"
#include "BlueNoiseDither.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

uniform bool ShowGrid
<
	ui_type = "input";
	ui_label = "Display calibration grid";
	ui_tooltip =
		"This can be used in conjunction with Image.fx\n"
		"to display real-world camera lens image and\n"
		"match its distortion profile.";
> = false;

// :: Main distortion :: //

#if PATNOMORPHIC_LENS_MODE==0
	uniform float4 K
<
		ui_type = "drag";
		ui_min = -0.2;
		ui_max =  0.2;
		ui_label = "Radial distortion";
		ui_tooltip = "Radial distortion coefficients K1, K2, K3, K4.";
		ui_category = "Geometrical lens distortions";
	> = 0f;

	uniform float S
	<
		ui_type = "slider";
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
	uniform float4 Ky
<
		ui_type = "drag";
		ui_min = -0.2;
		ui_max =  0.2;
		ui_label = "Radial distortion - vertical";
		ui_tooltip =
			"Radial distortion coefficients K1, K2, K3, K4\n"
			"for vertical distortion.";
		ui_category = "Geometrical lens distortions";
	> = 0f;

	uniform float4 Kx
<
		ui_type = "drag";
		ui_min = -0.2;
		ui_max =  0.2;
		ui_label = "Radial distortion - horizontal";
		ui_tooltip =
			"Radial distortion coefficients K1, K2, K3, K4\n"
			"for horizontal distortion.";
		ui_category = "Geometrical lens distortions";
	> = 0f;
#endif

// :: Color :: //

uniform bool UseVignette
<
	ui_type = "drag";
	ui_label = "Brightness aberration";
	ui_tooltip = "Automatically change image brightness based on projection area.";
	ui_category = "Color aberrations";
> = true;

uniform float T
<
	ui_type = "drag";
	ui_min = -0.2;
	ui_max =  0.2;
	ui_label = "Chromatic radius";
	ui_tooltip = "Color separation amount using T.";
	ui_category = "Color aberrations";
> = -0.2;

// :: Miss-alignment :: //

uniform float2 P
<
	ui_type = "drag";
	ui_min = -0.1;
	ui_max =  0.1;
	ui_label = "Decentering";
	ui_tooltip = "Correct image sensor alignment to the optical axis, using P1, P2.";
	ui_category = "Elements misalignment";
> = 0f;

uniform float2 Q
<
	ui_type = "drag";
	ui_min = -0.05;
	ui_max =  0.05;
	ui_label = "Thin prism";
	ui_tooltip = "Correct optical elements offset from the optical axis, using Q1, Q2.";
	ui_category = "Elements misalignment";
> = 0f;

uniform float2 C
<
	ui_type = "drag";
	ui_min = -0.05;
	ui_max =  0.05;
	ui_label = "Center";
	ui_tooltip = "Offset lens optical center, to correct image cropping, using C1, C2.";
	ui_category = "Elements misalignment";
> = 0f;

#if PARALLAX_ABERRATION

// :: Parallax :: //

uniform float4 Kp
<
	ui_type = "drag";
	ui_min = -0.2;
	ui_max = 0f;
	ui_label = "Radial parallax";
	ui_tooltip =
		"Parallax aberration radial coefficients K1, K2, K3, K4.\n"
		"Requires depth-buffer access.";
	ui_category = "Parallax aberration";
> = 0f;
#endif

// :: Border :: //

uniform bool MirrorBorder
<
	ui_type = "input";
	ui_label = "Mirror on border";
	ui_tooltip = "Choose between mirrored image or original background on the border.";
	ui_category = "Border";
	ui_category_closed = true;
> = true;

uniform bool BorderVignette
<
	ui_type = "input";
	ui_label = "Brightness aberration on border";
	ui_tooltip = "Apply brightness aberration effect to the border.";
	ui_category = "Border";
> = true;

uniform float4 BorderColor
<
	ui_type = "color";
	ui_label = "Border color";
	ui_tooltip = "Use alpha to change border transparency.";
	ui_category = "Border";
> = float4(0.027, 0.027, 0.027, 0.96);

uniform float BorderCorner
<
	ui_type = "slider";
	ui_min = 0f; ui_max = 1f;
	ui_label = "Corner radius";
	ui_tooltip = "Value of 0.0 gives sharp corners.";
	ui_category = "Border";
> = 0.062;

uniform uint BorderGContinuity
<
	ui_type = "slider";
	ui_min = 1u; ui_max = 3u;
	ui_units = "G";
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

// :: Grid :: //

uniform float DimGridBackground
<
	ui_type = "slider";
	ui_min = 0.25; ui_max = 1f; ui_step = 0.1;
	ui_label = "Dim background";
	ui_tooltip = "Adjust background visibility.";
	ui_category = "Grid";
	ui_category_closed = true;
	ui_text =
		"Use this in conjunction with Image.fx, to match\n"
		"lens distortion with a real-world camera profile.";
> = 1f;

uniform uint GridLook
<
	ui_type = "combo";
	ui_items =
		"yellow grid\0"
		"black grid\0"
		"white grid\0"
		"red-green grid\0";
	ui_label = "Grid look";
	ui_tooltip = "Select look of the grid.";
	ui_category = "Grid";
> = 0u;

uniform uint GridSize
<
	ui_type = "slider";
	ui_min = 1u; ui_max = 32u;
	ui_label = "Grid size";
	ui_tooltip = "Adjust calibration grid size.";
	ui_category = "Grid";
> = 16u;

uniform uint GridWidth
<
	ui_type = "slider";
	ui_min = 2u; ui_max = 16u;
	ui_units = " pixels";
	ui_label = "Grid bar width";
	ui_tooltip = "Adjust calibration grid bar width in pixels.";
	ui_category = "Grid";
> = 2u;

uniform float GridTilt
<
	ui_type = "slider";
	ui_min = -1f; ui_max = 1f; ui_step = 0.01;
	ui_units = "°";
	ui_label = "Tilt grid";
	ui_tooltip = "Adjust calibration grid tilt in degrees.";
	ui_category = "Grid";
> = 0f;

// :: Performance :: //

uniform uint ChromaticSamplesLimit
<
	ui_type = "slider";
	ui_min = 6u; ui_max = CHROMATIC_ABERRATION_MAX_SAMPLES; ui_step = 2u;
	ui_label = "Chromatic aberration samples limit";
	ui_tooltip =
		"Sample count is generated automatically per pixel, based on visible amount.\n"
		"This option limits maximum sample (steps) count allowed for color fringing.\n"
		"Only even numbers are accepted, odd numbers will be clamped.";
	ui_category = "Performance";
> = 32u;

#if PARALLAX_ABERRATION
uniform uint ParallaxSamples
<
	ui_type = "slider";
	ui_min = 2u; ui_max = 64u;
	ui_label = "Parallax aberration samples";
	ui_tooltip =
		"Amount of samples (steps) for parallax aberration mapping.";
	ui_category = "Performance";
> = 32u;
#endif

/*---------------.
| :: Textures :: |
'---------------*/

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
	// Border style
	AddressU = MIRROR;
	AddressV = MIRROR;
};

/*----------------.
| :: Functions :: |
'----------------*/

// Get reciprocal screen aspect ratio (1/x)
#define BUFFER_RCP_ASPECT_RATIO (BUFFER_HEIGHT*BUFFER_RCP_WIDTH)

/* G continuity distance function by Jakub Max Fober.
   Determined empirically. (G from 0, to 3)
   G=0   Sharp corners
   G=1   Round corners
   G=2   Smooth corners
   G=3   Luxury corners */
float glength(uint G, float2 pos)
{
	// Sharp corner
	if (G==0u) return max(abs(pos.x), abs(pos.y)); // G0
	// Higher-power length function
	pos = pow(abs(pos), ++G); // Power of G+1
	return pow(pos.x+pos.y, rcp(G)); // Power G+1 root
}

/* Linear pixel step function for anti-aliasing by Jakub Max Fober.
   This algorithm is part of scientific paper:
   · arXiv:2010.04077 [cs.GR] (2020) */
float aastep(float grad)
{
	// Differential vector
	float2 Del = float2(ddx(grad), ddy(grad));
	// Gradient normalization to pixel size, centered at the step edge
	return saturate(rsqrt(dot(Del, Del))*grad+0.5); // half-pixel offset
}

/* Chromatic aberration hue color generator by Fober J. M.
   hue = index/samples;
   where index ∊ [0, samples-1] and samples is an even number */
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
	else // just sharp corner, G0
		return aastep(glength(0u, borderCoord)-1f);
}

/*--------------.
| :: Shaders :: |
'--------------*/

// Vertex shader generating a triangle covering the entire screen
void LensDistortVS(
	in  uint   id        : SV_VertexID,
	out float4 position  : SV_Position,
	out float2 viewCoord : TEXCOORD
)
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

#if PARALLAX_ABERRATION
// Parallax aberration pixel shader
void ParallaxPS(
	float4 pixelPos  : SV_Position,
	float2 viewCoord : TEXCOORD,
	out float3 color : SV_Target
)
{
	if (all(Kp==0f)) // bypass parallax aberration
	{
		color = tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb;
		return;
	}

	// Get aspect-ratio transform vector for the view coordinates
	const float2 aspectScalar = 0.5/normalize(BUFFER_SCREEN_SIZE);
	// Transform view coordinates to texture coordinates
	float2 texCoord = viewCoord*aspectScalar+0.5;

	// Get radius at increasing even powers
	float4 R;
	R[0] = dot(viewCoord, viewCoord); // r²
	R[1] = R[0]*R[0]; // r⁴
	R[2] = R[1]*R[0]; // r⁶
	R[3] = R[2]*R[0]; // r⁸
	// Parallax aberration amount
	float2 centerCoord = texCoord-0.5;
	centerCoord *= rcp(1f+dot(Kp, R))-1f;

	// Get maximum allowed number of steps
	uint maxStepAmount = clamp(ParallaxSamples, 2u, PARRALLAX_ABERRATION_MAX_SAMPLES);
	// Initialize
	float offset; // Found offset value
	float stepSize = rcp(maxStepAmount-1u);
	for (int counter = maxStepAmount-1u; counter >= 0; counter--)
	{
		offset = counter*stepSize;
		float reverseDepth = 1f-ReShade::GetLinearizedDepth(texCoord-centerCoord*offset);
		if (offset <= reverseDepth)
		{
			float prevOffset = (counter+3u)*stepSize;
			float prevDifference = prevOffset-1f+ReShade::GetLinearizedDepth(texCoord-centerCoord*prevOffset);
			// Interpolate offset
			offset = lerp(prevOffset, offset, prevDifference/(prevDifference+reverseDepth-offset));
			break;
		}
	}
	// Apply parallax offset
	texCoord -= centerCoord*offset;

	color = tex2D(BackBuffer, texCoord).rgb;
}
#endif

// Lens distortion pixel shader
void LensDistortPS(
	float4 pixelPos  : SV_Position,
	float2 viewCoord : TEXCOORD,
	out float3 color : SV_Target
)
{
	// Bypass all effects
#if PATNOMORPHIC_LENS_MODE==0
	if (!ShowGrid && all(K==0f) && all(P==0f) && all(Q==0f))
#else
	if (!ShowGrid && all(Kx==0f) && all(Ky==0f) && all(P==0f) && all(Q==0f))
#endif
	{
		color = tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb;
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
		// Get maximum number of samples allowed
		uint evenSampleCount = min(ChromaticSamplesLimit-ChromaticSamplesLimit%2u, CHROMATIC_ABERRATION_MAX_SAMPLES); // Clamp value
		// Get total offset in pixels for automatic sample amount
		uint totalPixelOffset = uint(ceil(length(T*(distortion*BUFFER_SCREEN_SIZE))));
		// Set dynamic even number sample count, limited in range
		evenSampleCount = clamp(totalPixelOffset+totalPixelOffset%2u, 4u, evenSampleCount);

		// Sample background with multiple color filters at multiple offsets
		color = 0f; // initialize color
		for (uint i=0u; i<evenSampleCount; i++)
			// Manual gamma correction
			color += GammaConvert::to_linear(tex2Dlod(
				BackBuffer, // Image source
				float4(
					(T*(i/float(evenSampleCount-1u)-0.5)+1f) // Aberration offset
					*distortion // Distortion coordinates
					+orygTexCoord, // Original coordinates
				0f, 0f)
			).rgb)
			*Spectrum(i/float(evenSampleCount)); // Blur layer color
		// Preserve brightness
		color *= 2f/evenSampleCount;
	}
	else if (ShowGrid) // generate lens-match grid
	{
		// Sample background without distortion
		color = GammaConvert::to_linear(tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb); // manual gamma correction

		// Tilt view coordinates
		{
			// Convert angle to radians
			float tiltRad = radians(GridTilt);
			// Get rotation matrix components
			float tiltSin = sin(tiltRad);
			float tiltCos = cos(tiltRad);
			// Rotate coordinates
			viewCoord = mul(
				// Get rotation matrix
				float2x2(
					 tiltCos, tiltSin,
					-tiltSin, tiltCos
				),
				viewCoord
			);
		}

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
		viewCoord = GridWidth*0.5-abs(viewCoord);
		viewCoord = saturate(viewCoord); // Clamp values

		// Adjust grid look
		color = lerp(
			// Linear workflow
			GammaConvert::to_linear(16f/255f),
			color,
			DimGridBackground
		);
		switch (GridLook)
		{
			// Black
			case 1:
				color *= (1f-viewCoord.x)*(1f-viewCoord.y);
				break;
			// White
			case 2:
				color = 1f-(1f-viewCoord.x)*(1f-viewCoord.y)*(1f-color);
				break;
			// Color red-green
			case 3:
			{
				color = lerp(color, float3(1f, 0f, 0f), viewCoord.y);
				color = lerp(color, float3(0f, 1f, 0f), viewCoord.x);
			}  break;
			// Yellow
			default:
				color = lerp(float3(1f, 1f, 0f), color, (1f-viewCoord.x)*(1f-viewCoord.y));
				break;
		}
	}
	else // sample background with distortion
		color = GammaConvert::to_linear(tex2D(BackBuffer, texCoord).rgb); // manual gamma correction

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
			MirrorBorder? color : GammaConvert::to_linear(tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb), // manual gamma correction

			// Linear workflow
			GammaConvert::to_linear(BorderColor.rgb), // Border color
			GammaConvert::to_linear(BorderColor.a)    // Border alpha
		);

		// Apply vignette with border
		color = BorderVignette?
			vignetteMask*lerp(color, border, GetBorderMask(viewCoord)): // Vignette on border
			lerp(vignetteMask*color, border, GetBorderMask(viewCoord)); // Vignette only inside
		color = saturate(color);
	}

	// Linear workflow
	color = GammaConvert::to_display(color); // Correct gamma
	color = BlueNoise::dither(color, uint2(pixelPos.xy)); // Dither
}

/*-------------.
| :: Output :: |
'-------------*/

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
#if PARALLAX_ABERRATION
		"	· Parallax aberration\n"
#endif
		"	· Chromatic aberration\n"
		"	· Lens vignetting\n"
		"\n"
		"The algorithm is part of a scientific article:\n"
		"	arXiv:2010.04077 [cs.GR] (2020)\n"
		"	arXiv:2102.12682 [cs.GR] (2021)\n"
		"\n"
		"This effect © 2022-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-NC-ND 3.0 +\n"
		"for additional permissions see the source code.";
>
{
#if PARALLAX_ABERRATION
	pass Parallax
	{
		VertexShader = LensDistortVS;
		PixelShader = ParallaxPS;
	}
#endif
	pass Distort
	{
		VertexShader = LensDistortVS;
		PixelShader = LensDistortPS;
	}
}
