/** Perfect Perspective PS, version 5.0.7

This code © 2018-2023 Jakub Maksymilian Fober

This work is licensed under the Creative Commons,
Attribution-NonCommercial-NoDerivs 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-nc-nd/3.0/.

§ The copyright owner further grants permission for commercial reuse
of image recordings based on the work (e.g. Let's Play videos,
gameplay streams, and screenshots featuring ReShade filters) provided
that any use is accompanied by the name of the used shader and a link
to the ReShade website https://reshade.me.
§ This is intended to make the effect available free of charge for
non-corporate, common use.
§ The desired outcome is for the work to be easily recognizable in any
derivative images.

If you need additional licensing for your commercial product, contact
me at jakub.m.fober@protonmail.com.

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

This shader version is based upon following research article:
	Perspective picture from Visual Sphere:
	a new approach to image rasterization
	arXiv:2003.10558 [cs.GR] (2020)
	https://arxiv.org/abs/2003.10558
and
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

// Alternative to anamorphic
#ifndef PATNOMORPHIC_MODE
	#define PATNOMORPHIC_MODE 0
#endif
// Stereo 3D mode
#ifndef SIDE_BY_SIDE_3D
	#define SIDE_BY_SIDE_3D 0
#endif
// ITU REC 601 YCbCr
#define ITU_REC 601

	/* COMMONS */

#include "ReShade.fxh"
#include "ColorAndDither.fxh"

	/* MENU */

// FIELD OF VIEW

uniform uint FovAngle <
	ui_type = "slider";
	ui_category = "Game";
	ui_text = "(Match game settings)";
	ui_label = "Field of view (FOV)";
	ui_tooltip = "This should match your in-game FOV value.";
	#if __RESHADE__ < 40000
		ui_step = 0.2;
	#endif
	ui_max = 170u;
> = 90u;

uniform uint FovType <
	ui_type = "combo";
	ui_category = "Game";
	ui_label = "Field of view type";
	ui_tooltip =
		"This should match game-specific FOV type.\n"
		"\n"
		"Adjust so that round objects are still round when at the corner, and not oblong.\n"
		"Tilt head to see better.\n"
		"\n"
		"Tip:\n"
		"	If image bulges in movement, change it to 'diagonal'.\n"
		"	When proportions are distorted at the periphery, choose 'vertical' or '4:3'.\n"
		"	For ultra-wide display you may want '16:9' instead.\n"
		"\n"
		"	This method only works with k = 0.5 and s = 1.0.";
	ui_items =
		"horizontal\0"
		"diagonal\0"
		"vertical\0"
		"horizontal 4:3\0"
		"horizontal 16:9\0";
> = 0u;

// PERSPECTIVE

uniform float K <
	ui_type = "slider";
	ui_category = "Distortion";
#if PATNOMORPHIC_MODE // k indicates horizontal axis projection type
	ui_label = "Projection type 'k.x'";
#else // k represents whole picture projection type
	ui_label = "Projection type 'k'";
#endif
	ui_tooltip =
		"Projection coefficient 'k', represents\n"
		"various azimuthal projections types:\n"
		"\n"
		"Perception     Value  Projection\n"
		"\n"
		"straight path   1     Rectilinear\n"
		"shape           0.5   Stereographic\n"
		"distance        0     Equidistant\n"
		"depth          -0.5   Equisolid\n"
		"illumination   -1     Orthographic\n"
		"\n"
		"\n"
		"[Ctrl+click] to type value.";
	ui_min = -1f; ui_max = 1f; ui_step = 0.05;
> = 0.5;

#if PATNOMORPHIC_MODE // vertical axis projection is driven by separate k parameter
uniform float Ky <
	ui_type = "slider";
	ui_category = "Distortion";
	ui_label = "Projection type 'k.y'";
	ui_tooltip =
		"Projection coefficient 'k', represents\n"
		"various azimuthal projections types:\n"
		"\n"
		"Perception     Value  Projection\n"
		"\n"
		"straight path   1     Rectilinear\n"
		"shape           0.5   Stereographic\n"
		"distance        0     Equidistant\n"
		"depth          -0.5   Equisolid\n"
		"illumination   -1     Orthographic\n"
		"\n"
		"\n"
		"[Ctrl+click] to type value.";
	ui_min = -1f; ui_max = 1f; ui_step = 0.05;
> = 0.5;
#else // vertical axis distortion can be elongated by the anamorphic squeeze factor
uniform float S <
	ui_type = "slider";
	ui_category = "Distortion";
	ui_label = "Anamorphic squeeze 's'";
	ui_tooltip =
		"Anamorphic squeeze factor 's', affects\n"
		"vertical axis:\n"
		"\n"
		"1      spherical lens\n"
		"1.25   Ultra Panavision 70\n"
		"1.33   16x9 TV\n"
		"1.5    Technirama\n"
		"1.6    digital anamorphic\n"
		"1.8    4x3 full-frame\n"
		"2      golden-standard";
	ui_min = 1f; ui_max = 4f; ui_step = 0.05;
> = 1f;
#endif

uniform bool UseVignette <
	ui_type = "input";
	ui_category = "Distortion";
	ui_label = "Apply vignetting";
	ui_tooltip = "Apply lens-correct natural vignetting effect.";
> = true;

// BORDER

uniform float CroppingFactor <
	ui_type = "slider";
	ui_category = "Border";
	ui_category_closed = true;
	ui_label = "Cropping";
	ui_tooltip =
		"Adjusts image scale and cropped area size:\n"
		"\n"
		"Value Cropping\n"
		"\n"
		"  0   circular\n"
#if PATNOMORPHIC_MODE // Range limited to [0,1]
		"  1   cropped-circle";
	ui_min = 0f; ui_max = 1f;
#else // Includes full-frame cropping mode at 2
		"  1   cropped-circle\n"
		"  2   full-frame";
	ui_min = 0f; ui_max = 2f;
#endif
> = 1f;

uniform bool MirrorBorder <
	ui_type = "input";
	ui_category = "Border";
	ui_label = "Mirror on border";
	ui_tooltip = "Choose mirrored or original image on the border.";
> = true;

uniform bool BorderVignette <
	ui_type = "input";
	ui_category = "Border";
	ui_label = "Vignette on border";
	ui_tooltip = "Apply vignetting effect to border.";
> = false;

uniform float4 BorderColor <
	ui_type = "color";
	ui_category = "Border";
	ui_label = "Border color";
	ui_tooltip = "Use alpha to change border transparency.";
> = float4(0.027, 0.027, 0.027, 0.96);

uniform float BorderCorner <
	ui_type = "slider";
	ui_category = "Border";
	ui_label = "Corner radius";
	ui_tooltip = "Value of 0 gives sharp corners.";
	ui_min = 0f; ui_max = 1f;
> = 0.062;

uniform uint BorderGContinuity <
	ui_type = "slider";
	ui_category = "Border";
	ui_label = "Corner roundness";
	ui_tooltip =
		"G-surfacing continuity level for the corners:\n"
		"\n"
		"G0   sharp\n"
		"G1   circular\n"
		"G2   smooth\n"
		"G3   very smooth";
	ui_min = 1u; ui_max = 3u;
> = 3u;

// DEBUG OPTIONS

uniform bool DebugModePreview <
	ui_type = "input";
	ui_label = "Display debug mode";
	ui_tooltip =
		"Display calibration grid for lens-matching or\n"
		"pixel scale-map for resolution matching.";
	ui_category = "Debugging mode";
	ui_category_closed = true;
> = false;

uniform uint DebugMode <
	ui_type = "combo";
	ui_items =
		"calibration grid\0"
		"pixel scale-map\0";
	ui_label = "Select debug mode";
	ui_tooltip =
		"Calibration grid:\n"
		"\n"
		"	Display distorted grid on-top of undistorted image.\n"
		"	This can be used in conjunction with Image.fx\n"
		"	to display real-world camera lens image and\n"
		"	match its distortion profile.\n"
		"\n"
		"Pixel scale-map:\n"
		"\n"
		"	Display resolution-scale color map.\n"
		"	Can indicate if super-resolution is required:\n"
		"\n"
		"	Color   Definition\n"
		"\n"
		"	red     under-sampling\n"
		"	green   oversampling\n"
		"	blue    1:1";
	ui_category = "Debugging mode";
> = 0u;

uniform float DimDebugBackground <
	ui_type = "slider";
	ui_min = 0.25; ui_max = 1f; ui_step = 0.1;
	ui_label = "Dim background";
	ui_tooltip = "Adjust background visibility.";
	ui_category = "Debugging mode";
> = 1f;

	// GRID

uniform uint GridLook <
	ui_type = "combo";
	ui_items =
		"yellow grid\0"
		"black grid\0"
		"white grid\0"
		"red-green grid\0";
	ui_label = "Grid look";
	ui_tooltip = "Select look of the grid.";
	ui_text =
		"Use calibration grid in conjunction with Image.fx, to match\n"
		"lens distortion with a real-world camera profile.";
	ui_category = "Debugging calibration grid";
	ui_category_closed = true;
> = 0u;

uniform uint GridSize <
	ui_type = "slider";
	ui_min = 1u; ui_max = 32u;
	ui_label = "Grid size";
	ui_tooltip = "Adjust calibration grid size.";
	ui_category = "Debugging calibration grid";
> = 16u;

uniform uint GridWidth <
	ui_type = "slider";
	ui_min = 2u; ui_max = 16u;
	ui_label = "Grid bar width";
	ui_tooltip = "Adjust calibration grid bar width in pixels.";
	ui_category = "Debugging calibration grid";
> = 2u;

uniform float GridTilt <
	ui_type = "slider";
	ui_min = -1f; ui_max = 1f; ui_step = 0.01;
	ui_label = "Tilt grid";
	ui_tooltip = "Adjust calibration grid tilt in degrees.";
	ui_category = "Debugging calibration grid";
> = 0f;

	// Pixel scale map

uniform uint ResScaleScreen <
	ui_type = "input";
	ui_label = "Screen (native) resolution";
	ui_tooltip = "Set it to default screen resolution.";
	ui_text = "Use pixel scale-map to get optimal resolution for super-sampling.";
	ui_category = "Debugging pixel scale-map";
	ui_category_closed = true;
> = 1920u;

uniform uint ResScaleVirtual <
	ui_type = "drag";
	ui_step = 0.2;
	ui_min = 16u; ui_max = 16384u;
	ui_label = "Virtual resolution";
	ui_tooltip =
		"Simulates application running beyond native\n"
		"screen resolution (using VSR or DSR).";
	ui_category = "Debugging pixel scale-map";
> = 1920u;

	/* TEXTURES */

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
#if BUFFER_COLOR_SPACE <= 2 && BUFFER_COLOR_BIT_DEPTH != 10 // Linear workflow
	SRGBTexture = true;
#endif
	// Border style
	AddressU = MIRROR;
	AddressV = MIRROR;
};

	/* FUNCTIONS */

// Get reciprocal screen aspect ratio (1/x)
#define BUFFER_RCP_ASPECT_RATIO (BUFFER_HEIGHT*BUFFER_RCP_WIDTH)

/* S curve by JMF
   Generates smooth half-bell falloff for blur.
   Input is in [0, 1] range. */
float s_curve(float gradient)
{
	float top = max(gradient, 0.5);
	float bottom = min(gradient, 0.5);
	return 2f*((bottom*bottom+top)-(top*top-top))-1.5;
}
/* G continuity distance function by Jakub Max Fober.
   Represents derivative level continuity. (G from 0, to 3)
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
	return saturate(mad(rsqrt(dot(Del, Del)), grad, 0.5)); // half-pixel offset
}

/* Azimuthal spherical perspective projection equations © 2022 Jakub Maksymilian Fober
   These algorithms are part of the following scientific papers:
   · arXiv:2003.10558 [cs.GR] (2020)
   · arXiv:2010.04077 [cs.GR] (2020) */
float get_radius(float theta, float rcp_f, float k) // Get image radius
{
	if      (k>0f)   return tan(k*theta)/(rcp_f*k); // Stereographic, rectilinear projections
	else if (k<0f)   return sin(k*theta)/(rcp_f*k); // Equisolid, orthographic projections
	else /*(k==0f)*/ return       theta / rcp_f;     // Equidistant projection
}
float get_rcp_focal(float halfOmega, float radiusAtOmega, float k) // Get reciprocal focal length
{ return get_radius(halfOmega, radiusAtOmega, k); }
float get_theta(float radius, float rcp_f, float k) // Get spherical θ angle
{
	if      (k>0f)   return atan(k*radius*rcp_f)/k; // Stereographic, rectilinear projections
	else if (k<0f)   return asin(k*radius*rcp_f)/k; // Equisolid, orthographic projections
	else /*(k==0f)*/ return        radius*rcp_f;    // Equidistant projection
}
float get_vignette(float theta, float k) // Get vignetting mask in linear color space
{
	// Create spherical vignette |cos(max(|k|,1/2)θ)|^(k/2+3/2)
	float spherical_vignette = cos(max(abs(k), 0.5)*theta); // Limit FOV span, |k'| ∈ [0.5, 1] range
	// Mix cosine-law of illumination and inverse-square law
	return pow(abs(spherical_vignette), mad(k, 0.5, 1.5));
}
float2 get_phi_weights(float2 texCoord)
{
	texCoord *= texCoord; // Squared vector coordinates
	return texCoord/(texCoord.x+texCoord.y); // [cosφ² sinφ²] vector
}

	/* SHADER */

// Border mask shader with rounded corners
float GetBorderMask(float2 borderCoord)
{
	// Get coordinates for each corner
	borderCoord = abs(borderCoord);
	if (BorderGContinuity!=0u && BorderCorner!=0f) // If round corners
	{
		// Correct corner aspect ratio
		if (BUFFER_ASPECT_RATIO>1f) // If in landscape mode
			borderCoord.x = mad(borderCoord.x, BUFFER_ASPECT_RATIO, 1f-BUFFER_ASPECT_RATIO);
		else if (BUFFER_ASPECT_RATIO<1f) // If in portrait mode
			borderCoord.y = mad(borderCoord.y, BUFFER_RCP_ASPECT_RATIO, 1f-BUFFER_RCP_ASPECT_RATIO);
		// Generate scaled coordinates
		borderCoord = max(borderCoord+(BorderCorner-1f), 0f)/BorderCorner;

		// Round corner
		return aastep(glength(BorderGContinuity, borderCoord)-1f); // ...with G1 to G3 continuity
	}
	else // just sharp corner, G0
		return aastep(glength(0u, borderCoord)-1f);
}

// Generate lens-match grid
float3 GridModeViewPass(
	uint2  pixelCoord,
	float2 texCoord,
	float3 display)
{
	// Sample background without distortion
#if BUFFER_COLOR_SPACE <= 2 && BUFFER_COLOR_BIT_DEPTH == 10 // Manual gamma correction
	display = to_linear_gamma_hq(tex2Dfetch(BackBuffer, pixelCoord).rgb);
#else
	display = tex2Dfetch(BackBuffer, pixelCoord).rgb;
#endif

	// Get view coordinates, normalized at the corner
	texCoord = (texCoord*2f-1f)*normalize(BUFFER_SCREEN_SIZE);

	if (GridTilt!=0f) // tilt view coordinates
	{
		// Convert angle to radians
		float tiltRad = radians(GridTilt);
		// Get rotation matrix components
		float tiltSin = sin(tiltRad);
		float tiltCos = cos(tiltRad);
		// Rotate coordinates
		texCoord = mul(
			// Get rotation matrix
			float2x2(
				 tiltCos, tiltSin,
				-tiltSin, tiltCos
			),
			texCoord // Rotated coordinates
		);
	}

	// Get coordinates pixel size
	float2 delX = float2(ddx(texCoord.x), ddy(texCoord.x));
	float2 delY = float2(ddx(texCoord.y), ddy(texCoord.y));
	// Scale coordinates to grid size and center
	texCoord = frac(texCoord*GridSize)-0.5;
	/* Scale coordinates to pixel size for anti-aliasing of grid
	   using anti-aliasing step function from research paper
	   arXiv:2010.04077 [cs.GR] (2020) */
	texCoord *= float2(
		rsqrt(dot(delX, delX)),
		rsqrt(dot(delY, delY))
	)/GridSize; // Pixel density
	// Set grid with
	texCoord = saturate(GridWidth*0.5-abs(texCoord)); // Clamp values

	// Adjust grid look
	display = lerp(
#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
		to_linear_gamma_hq(16f/255f), // Safe bottom-color in linear range
#else
		16f/255f, // Safe bottom-color range
#endif
		display, // Background
		DimDebugBackground // Dimming amount
	);
	// Apply calibration grid colors
	switch (GridLook)
	{
		// Black
		case 1:  display *= (1f-texCoord.x)*(1f-texCoord.y); break;
		// White
		case 2:  display  = 1f-(1f-texCoord.x)*(1f-texCoord.y)*(1f-display); break;
		// display red-green
		case 3:
		{
			display = lerp(display, float3(1f, 0f, 0f), texCoord.y);
			display = lerp(display, float3(0f, 1f, 0f), texCoord.x);
		} break;
		// Yellow
		default: display  = lerp(float3(1f, 1f, 0f), display, (1f-texCoord.x)*(1f-texCoord.y)); break;
	}

	return display; // Background picture with grid superimposed over it
}

// Debug view mode shader
float3 SamplingScaleModeViewPass(
	float2 texCoord,
	float3 display)
{
	// Define Mapping color
	const float3   underSample = float3(235f, 16f, 16f)/255f; // Red
	const float3   superSample = float3(16f, 235f, 16f)/255f; // Green
	const float3 neutralSample = float3(16f, 16f, 235f)/255f; // Blue

	// Scale texture coordinates to pixel size
	texCoord *= BUFFER_SCREEN_SIZE*ResScaleVirtual/float(ResScaleScreen);
	texCoord = float2(
		length(float2(ddx(texCoord.x), ddy(texCoord.x))),
		length(float2(ddx(texCoord.y), ddy(texCoord.y)))
	);
	// Get pixel area
	float pixelScale = texCoord.x*texCoord.y;
	// Get pixel area in false-color
	float3 pixelScaleMap = lerp(
		lerp(
			underSample,
			neutralSample,
			s_curve(saturate(pixelScale*2f-1f)) // ↤ [0, 1] area range
		),
		superSample,
		s_curve(saturate(pixelScale*2f-2f)) // ↤ [1, 2] area range
	);


#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
	display = to_display_gamma_hq(display);
#endif
	// Get luma channel mapped to save range
	display.x = lerp(
		 16f/255f, // Safe range bottom
		235f/255f, // Safe range top
		dot(LumaMtx, display)
	);
	// Adjust background look
	display = lerp(
		16f/255f, // Safe bottom-color range
		display, // Background
		DimDebugBackground // Dimming amount
	);
	// Adjust background look
	display = lerp(
#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
		to_linear_gamma_hq(display.x), // Background
#else
		display.x, // Background
#endif
		pixelScaleMap, // Pixel scale map
		sqrt(1.25)-0.5 // Golden ratio by JMF
	);
	return display;
}

// Main perspective shader pass
float3 PerfectPerspectivePS(
	float4 pixelPos : SV_Position,
	float2 texCoord : TEXCOORD0) : SV_Target
{
	// Bypass perspective mapping
#if PATNOMORPHIC_MODE // take vertical k factor into account
	if (FovAngle==0u || (K==1f && Ky==1f && !UseVignette))
#else // consider only global k
	if (FovAngle==0u || (K==1f && !UseVignette))
#endif
		if (DebugModePreview)
		{
			float3 display; switch (DebugMode) // Choose output type
			{
				// Calibration grid
				default: display = GridModeViewPass(uint2(pixelPos.xy), texCoord, display); break;
				// Pixel scale-map
#if BUFFER_COLOR_SPACE <= 2 && BUFFER_COLOR_BIT_DEPTH == 10 // Manual gamma correction
				case 1u: display = SamplingScaleModeViewPass(texCoord, to_linear_gamma_hq(tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb)); break;
#else
				case 1u: display = SamplingScaleModeViewPass(texCoord, tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb); break;
#endif
			}
#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
			display = to_display_gamma_hq(display); // Manually correct gamma
#endif
			return BlueNoise::dither(uint2(pixelPos.xy), display); // Dither final 8/10-bit result
		}
		else // bypass all effects
			return tex2D(ReShade::BackBuffer, texCoord).rgb;

#if SIDE_BY_SIDE_3D // Side-by-side 3D content
	float SBS3D = texCoord.x*2f;
	texCoord.x = frac(SBS3D);
	SBS3D = floor(SBS3D);
#endif

	// Aspect ratio transformation vector
	const float2 viewProportions = normalize(BUFFER_SCREEN_SIZE);
	// Half field of view angle in radians
	const float halfOmega = radians(FovAngle*0.5);

	// Convert UV to centered coordinates
	texCoord = texCoord*2f-1f;
	// Normalize texture coordinates diagonally and correct aspect
	texCoord *= viewProportions;

	// Get radius at Omega for a given FOV type
	static float radiusAtOmega; switch (FovType)
	{
		default: radiusAtOmega = viewProportions.x; break; // Horizontal
		case 1u: radiusAtOmega = 1f; break; // Diagonal
		case 2u: radiusAtOmega = viewProportions.y; break; // Vertical
		case 3u: radiusAtOmega = viewProportions.y*4f/3f; break; // 4x3
		case 4u: radiusAtOmega = viewProportions.y*16f/9f; break; // 16x9
	}

	// Reciprocal focal length
	const float rcp_focal = get_rcp_focal(halfOmega, radiusAtOmega, K);
	// Image radius
#if PATNOMORPHIC_MODE // Simple length function for radius
	float radius = length(texCoord);
#else // derive radius from anamorphic coordinates
	float radius = S==1f ?
		dot(texCoord, texCoord) : // Spherical
		(texCoord.y*texCoord.y)/S+(texCoord.x*texCoord.x); // Anamorphic
	float rcp_radius = rsqrt(radius); radius = sqrt(radius);
#endif
	{
		// Horizontal edge radius
		const float croppingHorizontal = get_radius(
				atan(tan(halfOmega)/radiusAtOmega*viewProportions.x),
			rcp_focal, K)/viewProportions.x;
#if PATNOMORPHIC_MODE // Does not include diagonal cropping radius for full-frame mode
		// Vertical edge radius
		const float croppingVertical = get_radius(
				atan(tan(halfOmega)/radiusAtOmega*viewProportions.y),
			rcp_focal, Ky)/viewProportions.y;
		// Get radius scaling for bounds alignment
		const float croppingScalar = lerp(
				max(croppingHorizontal, croppingVertical), // Circular fish-eye
				min(croppingHorizontal, croppingVertical), // Cropped circle
				clamp(CroppingFactor, 0f, 1f)
			);
#else // border cropping radius is in anamorphic coordinates
		// Vertical edge radius
		const float croppingVertical = get_radius(
				atan(tan(halfOmega)/radiusAtOmega*viewProportions.y*rsqrt(S)),
			rcp_focal, K)/viewProportions.y*sqrt(S);
		// Diagonal point radius
		const float anamorphicDiagonal = length(float2(
			viewProportions.x,
			viewProportions.y*rsqrt(S)
		));
		const float croppingDigonal = get_radius(
				atan(tan(halfOmega)/radiusAtOmega*anamorphicDiagonal),
			rcp_focal, K)/anamorphicDiagonal;

		// Get radius scaling for bounds alignment
		const float croppingScalar = CroppingFactor<1f ?
			lerp(
				max(croppingHorizontal, croppingVertical), // Circular fish-eye
				min(croppingHorizontal, croppingVertical), // Cropped circle
				max(CroppingFactor, 0f) // ↤ [0,1] range
			) :
			lerp(
				min(croppingHorizontal, croppingVertical), // Cropped circle
				croppingDigonal, // Full-frame
				min(CroppingFactor-1f, 1f) // ↤ [1,2] range
			);
#endif
		// Scale radius to cropping bounds
		radius *= croppingScalar;
	}

#if PATNOMORPHIC_MODE // derive θ angle from two distinct projections
	// Horizontal and vertical incident angle
	float2 theta2 = float2(
		get_theta(radius, rcp_focal, K),
		get_theta(radius, rcp_focal, Ky)
	);
	// Pantomorphic interpolation weights
	float2 phiMtx = get_phi_weights(texCoord);
	float vignette = UseVignette?
		dot(phiMtx, float2(
			get_vignette(theta2.x, K),
			get_vignette(theta2.y, Ky)
		)) : 1f;
	float theta = dot(phiMtx, theta2); // Pantomorphic incident
#else // get θ from anamorphic radius
	float theta = get_theta(radius, rcp_focal, K);
	float vignette = UseVignette? get_vignette(theta, K) : 1f;
	// Anamorphic vignette correction
	if (UseVignette && S!=1f)
	{
		// Get anamorphic-incident 3D vector
		float3 incident = float3(
			(sin(theta)*rcp_radius)*texCoord,
			 cos(theta)
		);
		vignette /= dot(incident, incident); // Inverse square law
	}
#endif

	// Rectilinear perspective transformation
#if PATNOMORPHIC_MODE // simple rectilinear transformation
	texCoord = tan(theta)*normalize(texCoord);
#else // normalize by anamorphic radius
	texCoord *= tan(theta)*rcp_radius;
#endif

	// Back to normalized, centered coordinates
	const float2 toUvCoord = radiusAtOmega/(tan(halfOmega)*viewProportions);
	texCoord *= toUvCoord;

	// Outside border mask with anti-aliasing
	float borderMask = GetBorderMask(texCoord);

	// Back to UV Coordinates
	texCoord = texCoord*0.5+0.5;

#if SIDE_BY_SIDE_3D // Side-by-side 3D content
	texCoord.x = (texCoord.x+SBS3D)*0.5;
#endif

	// Sample display image
#if PATNOMORPHIC_MODE // take vertical k factor into account
	float3 display = K!=1f || Ky!=1f ?
#else // consider only global k
	float3 display = K!=1f ?
#endif
		tex2D(BackBuffer, texCoord).rgb : // Perspective projection lookup
		tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb; // No perspective change
#if BUFFER_COLOR_SPACE <= 2 && BUFFER_COLOR_BIT_DEPTH == 10 // Manual gamma correction
	display = to_linear_gamma_hq(display);
#endif

	// Display calibration view
	if (DebugModePreview) switch (DebugMode) // Choose output type
	{
		// Calibration grid
		default: display = GridModeViewPass(uint2(pixelPos.xy), texCoord, display); break;
		// Pixel scale-map
		case 1u: display = SamplingScaleModeViewPass(texCoord, display); break;
	}

#if PATNOMORPHIC_MODE // take vertical k factor into account
	if ((K!=1f || Ky!=1f) && CroppingFactor!=2f) // Visible borders
#else // consider only global k
	if (K!=1f && CroppingFactor!=2f) // Visible borders
#endif
	{
		// Get border
		float3 border = lerp(
			// Border background
#if BUFFER_COLOR_SPACE <= 2 && BUFFER_COLOR_BIT_DEPTH == 10 // Manual gamma correction
			MirrorBorder? display : to_linear_gamma_hq(tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb),
#else
			MirrorBorder? display : tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb,
#endif
#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
			to_linear_gamma_hq(BorderColor.rgb), // Border color
			to_linear_gamma_hq(BorderColor.a)    // Border alpha
#else
			BorderColor.rgb, // Border color
			BorderColor.a    // Border alpha
#endif
		);

		// Apply vignette with border
		display = BorderVignette?
			vignette*lerp(display, border, borderMask) : // Vignette on border
			lerp(vignette*display, border, borderMask);  // Vignette only inside
	}
	else // apply vignette
		display *= vignette;

#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
	// Manually correct gamma
	display = to_display_gamma_hq(display);
#endif
	// Dither final 8/10-bit result
	return BlueNoise::dither(uint2(pixelPos.xy), display);
}

	/* OUTPUT */

technique PerfectPerspective
<
	ui_label = "Perfect Perspective";
	ui_tooltip =
		"Adjust perspective for distortion-free picture:\n"
		"\n"
		"	· Fish-eye\n"
		"	· Panini\n"
#if PATNOMORPHIC_MODE
		"	· Pantomorphic\n"
#else
		"	· Anamorphic\n"
#endif
		"	· Vignetting (natural)\n"
		"\n"
		"Instruction:\n"
		"\n"
		"	1# select proper FOV angle and type. If FOV type is unknown,\n"
		"	   find a round object within the game and look at it upfront,\n"
		"	   then rotate the camera so that the object is in the corner.\n"
#if PATNOMORPHIC_MODE
		"	   Make sure all 'k' parameters are equal 0.5 and adjust FOV type such that\n"
#else
		"	   Set 'k' to 0.5, change squeeze factor to 1x and adjust FOV type such that\n"
#endif
		"	   the object does not have an egg shape, but a perfect round shape.\n"
		"\n"
		"	2# adjust perspective type according to game-play style.\n"
#if PATNOMORPHIC_MODE
		"	   If you look mostly at the horizon, 'k.y' can be increased.\n"
#else
		"	   If you look mostly at the horizon, anamorphic squeeze can be increased.\n"
#endif
		"	   For curved-display correction, set it to higher value.\n"
		"\n"
		"	3# adjust visible borders. You can change the zoom factor,\n"
		"	   such that no borders are visible, or that no image area is lost.\n"
		"\n"
		"	4# additionally for sharp image, use sharpening FX or run game at a\n"
		"	   Super-Resolution. Debug options can help you find the proper value.\n"
		"\n"
		"The algorithm is part of a scientific article:\n"
		"	arXiv:2003.10558 [cs.GR] (2020)\n"
		"	arXiv:2010.04077 [cs.GR] (2020)\n"
#if PATNOMORPHIC_MODE
		"	arXiv:2102.12682 [cs.GR] (2021)\n"
#endif
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-NC-ND 3.0 +\n"
		"for additional permissions see the source.";
>
{
	pass PerspectiveDistortion
	{
		VertexShader = PostProcessVS;
		PixelShader = PerfectPerspectivePS;
	}
}
