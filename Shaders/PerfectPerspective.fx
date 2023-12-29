/* >> Description << */

/* Perfect Perspective PS (version 5.8.8)

Copyright:
This code © 2018-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
Unported License + additional permissions. To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/3.0/

Additional permissions under Creative Commons Plus protocol (CC+):

§ 1. The copyright owner further downgrades the licensing terms to the CC-BY 3.0
variant of the license, waiving the ShareAlike terms, for the purpose of
journalistic publications talking about this work, and/or for the use in
gameplay videos/images specifically published by common gamers.
Intents §: To facilitate the practical use of the shader and specifically its
           derivative images/videos by the journalists of the video-game
           industry, professional and amateur and by common gamers. At the same
           time preventing typically closed-source commercial plugins utilizing
           this work from being published by some third-party.
Outcome §: That it would be practically and legally acceptable for journalists
           and games to promote this work if they want to share their image/
           video material under their own terms.

Contact:
For inquiries regarding alternative licensing options, please contact me at:
jakub.m.fober@protonmail.com

--------------------------------------------------------------------------------
For updates visit GitHub repository at
https://github.com/Fubaxiusz/fubax-shaders.

About:
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
	Axomorphic Perspective Projection Model for Immersive Imagery
	arXiv:2102.12682 [cs.GR] (2021)
	https://arxiv.org/abs/2102.12682
by Fober, J. M.
*/

/* >> Macros << */

/* Alternative to anamorphic.
   1 gives separate distortion option for vertical axis.
   2 gives separate option for top and bottom half. */
#ifndef AXOMORPHIC_MODE
	#define AXOMORPHIC_MODE 1
#endif

/* >> Commons << */

#include "ReShade.fxh"
#include "ColorConversion.fxh"
#include "LinearGammaWorkflow.fxh"
#include "BlueNoiseDither.fxh"

/* >> Menu << */

// Field of View

uniform uint FovAngle
<
	ui_type = "slider";
	ui_category = "In game";
	ui_category_closed = true;
	ui_text = "(Match game settings)";
	ui_units = "°";
	ui_label = "Field of view (FoV)";
	ui_tooltip = "This should match your in-game FoV value.";
	ui_max = 140u;
> = 90u;

uniform uint FovType
<
	ui_type = "combo";
	ui_category = "In game";
	ui_label = "Field of view type";
	ui_tooltip =
		"This should match game-specific FoV type.\n"
		"\n"
		"Adjust so that round objects are still round when at the corner, and not oblong.\n"
		"Tilt head to see better.\n"
		"\n"
		"Instruction:\n"
		"\n"
		"	If image bulges in movement, change it to 'diagonal'.\n"
		"	When proportions are distorted at the periphery,\n"
		"	choose 'vertical' or '4:3'. For ultra-wide display\n"
		"	you may want '16:9' instead.\n"
		"\n"
#if AXOMORPHIC_MODE
		"	This method only works with all k = 0.5.";
#else
		"	This method only works with k = 0.5 and s = 1.0.";
#endif
	ui_items =
		"horizontal\0"
		"diagonal\0"
		"vertical\0"
		"horizontal 4:3\0"
		"horizontal 16:9\0";
> = 0u;

// Perspective

#if AXOMORPHIC_MODE>=2 // vertical axis projection is driven by separate ky top and ky bottom parameter
uniform float Ky
<
	ui_type = "slider";
	ui_category = "Distortion";
	ui_category_closed = true;
	ui_text = "(brightness[-1], distances[-0.5], speed[0], shapes[0.5], straight-lines[1])";
	ui_label = "Projection type 'k' top (asymmetrical)";
	ui_tooltip =
		"Projection coefficient 'k' top, represents\n"
		"various azimuthal projections types:\n"
		"\n"
		"	 Perception of | Value |  Projection  	\n"
		"	---------------+-------+--------------	\n"
		"	  brightness   |  -1   |  Orthographic	\n"
		"	   distances   | -0.5  |   Equisolid  	\n"
		"	     speed     |   0   |  Equidistant 	\n"
		"	    shapes     |  0.5  | Stereographic	\n"
		"	straight lines |   1   |  Rectilinear 	\n"
		"\n"
		"\n"
		"[Ctrl+click] to type value.";
	ui_min = -1f; ui_max = 1f; ui_step = 0.01;
> = 0.5;
#endif

// k indicates horizontal axis or whole picture projection type
uniform float K
<
	ui_type = "slider";
	ui_category = "Distortion";
#if AXOMORPHIC_MODE==1
	ui_category_closed = true;
	ui_text = "(brightness[-1], distances[-0.5], speed[0], shapes[0.5], straight-lines[1])";
#endif
#if AXOMORPHIC_MODE // k indicates horizontal axis projection type
	ui_label = "Projection type 'k' horizontal";
	ui_tooltip = "Projection coefficient 'k' horizontal, represents\n"
#else // k represents whole picture projection type
	ui_category_closed = true;
	ui_text = "(brightness[-1], distances[-0.5], speed[0], shapes[0.5], straight-lines[1])";
	ui_label = "Projection type 'k'";
	ui_tooltip = "Projection coefficient 'k', represents\n"
#endif
		"various azimuthal projections types:\n"
		"\n"
		"	 Perception of | Value |  Projection  	\n"
		"	---------------+-------+--------------	\n"
		"	  brightness   |  -1   |  Orthographic	\n"
		"	   distances   | -0.5  |   Equisolid  	\n"
		"	     speed     |   0   |  Equidistant 	\n"
		"	    shapes     |  0.5  | Stereographic	\n"
		"	straight lines |   1   |  Rectilinear 	\n"
		"\n"
		"\n"
		"[Ctrl+click] to type value.";
	ui_min = -1f; ui_max = 1f; ui_step = 0.01;
> = 0.5;

#if AXOMORPHIC_MODE==1 // vertical axis projection is driven by separate k parameter
uniform float Ky
<
	ui_type = "slider";
	ui_category = "Distortion";
	ui_label = "Projection type 'k' vertical";
	ui_tooltip =
		"Projection coefficient 'k' vertical, represents\n"
		"various azimuthal projections types:\n"
		"\n"
		"	 Perception of | Value |  Projection  	\n"
		"	---------------+-------+--------------	\n"
		"	  brightness   |  -1   |  Orthographic	\n"
		"	   distances   | -0.5  |   Equisolid  	\n"
		"	     speed     |   0   |  Equidistant 	\n"
		"	    shapes     |  0.5  | Stereographic	\n"
		"	straight lines |   1   |  Rectilinear 	\n"
		"\n"
		"\n"
		"[Ctrl+click] to type value.";
	ui_min = -1f; ui_max = 1f; ui_step = 0.01;
> = 0.5;

#elif AXOMORPHIC_MODE>=2 // vertical axis projection is driven by separate ky top and ky bottom parameter
uniform float KyA
<
	ui_type = "slider";
	ui_category = "Distortion";
	ui_label = "Projection type 'k' bottom (asymmetrical)";
	ui_tooltip =
		"Projection coefficient 'k' bottom, represents\n"
		"various azimuthal projections types:\n"
		"\n"
		"	 Perception of | Value |  Projection  	\n"
		"	---------------+-------+--------------	\n"
		"	  brightness   |  -1   |  Orthographic	\n"
		"	   distances   | -0.5  |   Equisolid  	\n"
		"	     speed     |   0   |  Equidistant 	\n"
		"	    shapes     |  0.5  | Stereographic	\n"
		"	straight lines |   1   |  Rectilinear 	\n"
		"\n"
		"\n"
		"[Ctrl+click] to type value.";
	ui_min = -1f; ui_max = 1f; ui_step = 0.01;
> = 0.5;
#else // vertical axis distortion can be elongated by the anamorphic squeeze factor
uniform float S
<
	ui_type = "slider";
	ui_category = "Distortion";
	ui_label = "Anamorphic squeeze 's'";
	ui_tooltip =
		"Anamorphic squeeze factor 's', affects\n"
		"vertical axis:\n"
		"\n"
		"	Value | Lens Type          	\n"
		"	------+--------------------	\n"
		"	  1   | spherical lens     	\n"
		"	 1.25 | Ultra Panavision 70	\n"
		"	 1.33 | 16x9 TV            	\n"
		"	 1.5  | Technirama         	\n"
		"	 1.6  | digital anamorphic 	\n"
		"	 1.8  | 4x3 full-frame     	\n"
		"	  2   | golden-standard    	\n"
		"\n"
		"\n"
		"These are typical values used in film.\n";
	ui_min = 1f; ui_max = 4f; ui_step = 0.01;
> = 1f;
#endif

uniform bool UseVignette
<
	ui_type = "input";
	ui_category = "Distortion";
	ui_label = "Apply vignetting";
	ui_tooltip = "Apply lens-correct natural vignetting effect.";
> = true;

// Border

uniform float CroppingFactor
<
	ui_type = "slider";
	ui_text = "(circular[0], cropped-circle[0.5], full-frame[1])";
	ui_category = "Border appearance";
	ui_category_closed = true;
	ui_label = "Cropping";
	ui_tooltip =
		"Adjusts image scale and cropped area size:\n"
		"\n"
		"	Value | Cropping      	\n"
		"	------+---------------	\n"
		"	    0 | circular      	\n"
		"	  0.5 | cropped-circle	\n"
		"	    1 | full-frame    	\n"
		"\n"
		"\n"
		"For horizontal display, circular will snap to vertical bounds,\n"
		"cropped-circle to horizontal bounds, and full-frame to corners.";
	ui_min = 0f; ui_max = 1f;
> = 0.5;

uniform bool MirrorBorder
<
	ui_type = "input";
	ui_category = "Border appearance";
	ui_label = "Mirror on border";
	ui_tooltip = "Choose mirrored or original image on the border.";
> = false;

uniform float VignetteOffset
<
	ui_type = "slider";
	ui_category = "Cosmetics";
	ui_category_closed = true;
	ui_label = "Vignette brightness";
	ui_tooltip = "Brighten the image with vignette enabled.";
	ui_min = 0f;
	ui_max = 0.2;
> = 0.05;

uniform bool BorderVignette
<
	ui_type = "input";
	ui_category = "Cosmetics";
	ui_label = "Vignette on border";
	ui_tooltip = "Apply vignetting effect to border.";
> = false;

uniform float4 BorderColor
<
	ui_type = "color";
	ui_category = "Cosmetics";
	ui_label = "Border color";
	ui_tooltip = "Use alpha to change border transparency.";
> = float4(0.027, 0.027, 0.027, 0.96);

uniform float BorderCorner
<
	ui_type = "slider";
	ui_category = "Cosmetics";
	ui_label = "Corner radius";
	ui_tooltip = "Value of 0 gives sharp corners.";
	ui_min = 0f; ui_max = 1f;
> = 0.062;

uniform uint BorderGContinuity
<
	ui_type = "slider";
	ui_category = "Cosmetics";
	ui_units = "G";
	ui_label = "Corner roundness";
	ui_tooltip =
		"G-surfacing continuity level for the corners:\n"
		"\n"
		"	Continuity | Result     	\n"
		"	-----------+------------	\n"
		"	        G0 | sharp      	\n"
		"	        G1 | circular   	\n"
		"	        G2 | smooth     	\n"
		"	        G3 | very smooth	\n"
		"\n"
		"\n"
		"G is a commonly used indicator for industrial design,\n"
		"where G1 is reserved for heavy-duty, G2 for common items,\n"
		"and G3 for luxurious items.";
	ui_min = 1u; ui_max = 3u;
> = 3u;

// Calibration Options

uniform bool CalibrationModeView
<
	ui_type = "input";
	ui_label = "Display calibration mode";
	ui_tooltip =
		"Display calibration grid for lens-matching or\n"
		"pixel scale-map for resolution matching.";
	ui_category = "Calibration mode";
	ui_category_closed = true;
> = false;

uniform uint CalibrationMode
<
	ui_type = "combo";
	ui_items =
		"Calibration grid\0"
		"Pixel scale-map\0";
	ui_label = "Select test mode";
	ui_tooltip =
		"Calibration grid:\n"
		"\n"
		"	Use calibration grid in conjunction with Image.fx, to match\n"
		"	lens distortion with a real-world camera profile.\n"
		"\n"
		"Pixel scale-map:\n"
		"\n"
		"	Use pixel scale-map to get optimal resolution for super-sampling.\n"
		"\n"
		"	Value | Definition    	\n"
		"	------+---------------	\n"
		"	  red | under-sampling	\n"
		"	green | 1:1           	\n"
		"	 blue | oversampling  	\n"
		"\n"
		"\n"
		"This color scheme makes it easy to spot regions with magnified pixels,\n"
		"and pixels which are squeezed together.";
	ui_text = "Testing mode:";
	ui_category = "Calibration mode";
> = 0u;

uniform float DimCalibrationBackground
<
	ui_type = "slider";
	ui_min = 0.25; ui_max = 1f; ui_step = 0.1;
	ui_label = "Dim background";
	ui_tooltip = "Adjust background visibility.";
	ui_category = "Calibration mode";
> = 1f;

// Grid

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
	ui_text = "Calibration grid settings:";
	ui_category = "Calibration mode";
	ui_category_closed = true;
> = 0u;

uniform uint GridSize
<
	ui_type = "slider";
	ui_min = 1u; ui_max = 32u;
	ui_label = "Grid size";
	ui_tooltip = "Adjust calibration grid size.";
	ui_category = "Calibration mode";
> = 16u;

uniform uint GridWidth
<
	ui_type = "slider";
	ui_min = 2u; ui_max = 16u;
	ui_units = " pixels";
	ui_label = "Grid bar width";
	ui_tooltip = "Adjust calibration grid bar width in pixels.";
	ui_category = "Calibration mode";
> = 2u;

uniform float GridTilt
<
	ui_type = "slider";
	ui_min = -1f; ui_max = 1f; ui_step = 0.01;
	ui_units = "°";
	ui_label = "Tilt grid";
	ui_tooltip = "Adjust calibration grid tilt in degrees.";
	ui_category = "Calibration mode";
> = 0f;

// Pixel Scale Map

uniform uint ResScaleScreen
<
	ui_type = "input";
	ui_units = " pixels";
	ui_label = "Screen (native) resolution";
	ui_tooltip = "Set it to default screen resolution.";
	ui_text = "Pixel scale-map settings:";
	ui_category = "Calibration mode";
	ui_category_closed = true;
> = BUFFER_WIDTH;

uniform uint ResScaleVirtual
<
	ui_type = "drag";
	ui_min = 16u; ui_max = 16384u;
	ui_units = " pixels";
	ui_label = "Virtual resolution";
	ui_tooltip =
		"Simulates application running beyond native\n"
		"screen resolution (using VSR or DSR).";
	ui_category = "Calibration mode";
> = BUFFER_WIDTH;

/* >> Textures << */

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
	// Border style
	AddressU = MIRROR;
	AddressV = MIRROR;
};

/* >> Functions << */

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
	if (G==0u) return max(abs(pos.x), abs(pos.y)); // g0
	// Higher-power length function
	pos = pow(abs(pos), ++G); // power of G+1
	return pow(pos.x+pos.y, rcp(G)); // power G+1 root
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
float get_radius(float theta, float rcp_f, float k) // get image radius
{
	if      (k>0f)  return tan(k*theta)/(rcp_f*k); // stereographic, rectilinear projections
	else if (k<0f)  return sin(k*theta)/(rcp_f*k); // equisolid, orthographic projections
	else  /*k==0f*/ return       theta / rcp_f;    // equidistant projection
}
#define get_rcp_focal(halfOmega, radiusOfOmega, k) get_radius(halfOmega, radiusOfOmega, k) // get reciprocal focal length
float get_theta(float radius, float rcp_f, float k) // get spherical θ angle
{
	if      (k>0f)  return atan(k*radius*rcp_f)/k; // stereographic, rectilinear projections
	else if (k<0f)  return asin(k*radius*rcp_f)/k; // equisolid, orthographic projections
	else  /*k==0f*/ return        radius*rcp_f;    // equidistant projection
}
float get_vignette(float theta, float r, float rcp_f) // get vignetting mask in linear color space
{ return sin(theta)/(r*rcp_f); }
float2 get_phi_weights(float2 viewCoord) // get axomorphic interpolation weights
{
	viewCoord *= viewCoord; // squared vector coordinates
	return viewCoord/(viewCoord.x+viewCoord.y); // [cos²φ sin²φ] vector
}

// Get radius at Ω for a given FoV type
float getRadiusOfOmega(float2 viewProportions)
{
	switch (FovType) // uniform input
	{
		case 1u: // diagonal
			return 1f;
		case 2u: // vertical
			return viewProportions.y;
		case 3u: // 4x3
			return viewProportions.y*4f/3f;
		case 4u: // 16x9
			return viewProportions.y*16f/9f;
		default: // horizontal
			return viewProportions.x;
	}
}

#if AXOMORPHIC_MODE==1
// Search for corner point radius at diagonal Ω in Axomorphic perspective
float binarySearchCorner(float halfOmega, float radiusOfOmega, float rcp_focal)
{
	float croppingDigonal = 0.5;
	// Diagonal pint φ weight
	const static float2 diagonalPhi = get_phi_weights(BUFFER_SCREEN_SIZE);
	// Diagonal half-Ω angle
	const static float diagonalHalfOmega = atan(tan(halfOmega)/radiusOfOmega);
	// Find diagonal point radius with pixel resolution
	for (uint d=4u; d<=ceil(length(BUFFER_SCREEN_SIZE)*2u); d*=2u) // log2 complexity
	{
		// Get θ angle at current homing radius value
		float diagonalTheta = dot(
			diagonalPhi,
			float2(
				get_theta(croppingDigonal, rcp_focal, K),
				get_theta(croppingDigonal, rcp_focal, Ky)
			)
		);
		// Perform value homing, if the cropping point is before the corner point,
		// add half-step, if behind, subtract half-step
		croppingDigonal += diagonalTheta>diagonalHalfOmega ? -rcp(d) : rcp(d); // move forward or backward
	}

	return croppingDigonal;
}
#elif AXOMORPHIC_MODE>=2
// Search for corner point radius at diagonal Ω in Axomorphic asymmetrical perspective
float2 binarySearchCorner(float halfOmega, float radiusOfOmega, float rcp_focal)
{
	float2 croppingDigonal = 0.5;
	// Diagonal pint φ weight
	const static float2 diagonalPhi = get_phi_weights(BUFFER_SCREEN_SIZE);
	// Diagonal half-Ω angle
	const static float diagonalHalfOmega = atan(tan(halfOmega)/radiusOfOmega);
	// Search resolution
	const uint searchResolution = ceil(length(BUFFER_SCREEN_SIZE)*2u); // sub-pixel
	// Find diagonal point top radius with pixel resolution
	for (uint d=2u; d<=searchResolution; d*=2u) // log2 complexity
	{
		// Get θ angle at current homing radius value
		float diagonalTheta = dot(
			diagonalPhi,
			float2(
				get_theta(croppingDigonal.s, rcp_focal, K),
				get_theta(croppingDigonal.s, rcp_focal, Ky)
			)
		);
		// Perform value homing, if the cropping point is before the corner point,
		// add half-step, if behind, subtract half-step
		croppingDigonal.s += diagonalTheta>diagonalHalfOmega ? -rcp(d) : rcp(d); // move forward or backward
	}
	// Find diagonal point bottom radius with pixel resolution
	for (uint d=2u; d<=searchResolution; d*=2u) // log2 complexity
	{
		// Get θ angle at current homing radius value
		float diagonalTheta = dot(
			diagonalPhi,
			float2(
				get_theta(croppingDigonal.t, rcp_focal, K),
				get_theta(croppingDigonal.t, rcp_focal, KyA)
			)
		);
		// Perform value homing, if the cropping point is before the corner point,
		// add half-step, if behind, subtract half-step
		croppingDigonal.t += diagonalTheta>diagonalHalfOmega ? -rcp(d) : rcp(d); // move forward or backward
	}

	return croppingDigonal;
}
#endif

/* >> Shaders << */

// Border mask shader with rounded corners
float GetBorderMask(float2 borderCoord)
{
	// Get coordinates for each corner
	borderCoord = abs(borderCoord);
	if (BorderGContinuity!=0u && BorderCorner!=0f) // if round corners
	{
		// Correct corner aspect ratio
		if (BUFFER_ASPECT_RATIO>1f) // if in landscape mode
			borderCoord.x = mad(borderCoord.x, BUFFER_ASPECT_RATIO, 1f-BUFFER_ASPECT_RATIO);
		else if (BUFFER_ASPECT_RATIO<1f) // if in portrait mode
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
	float3 display
)
{
	// Sample background without distortion
	display = GammaConvert::to_linear(tex2Dfetch(BackBuffer, pixelCoord).rgb); // manual gamma correction

	// Get view coordinates, normalized at the corner
	texCoord = (texCoord*2f-1f)*normalize(BUFFER_SCREEN_SIZE);

	if (GridTilt!=0f) // tilt view coordinates
	{
		// Convert angle to radians
		const static float tiltRad = radians(GridTilt);
		// Get rotation matrix components
		const static float tiltSin = sin(tiltRad);
		const static float tiltCos = cos(tiltRad);
		// Rotate coordinates
		texCoord = mul(
			// Get rotation matrix
			float2x2(
				 tiltCos, tiltSin,
				-tiltSin, tiltCos
			),
			texCoord // rotated coordinates
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
	)/GridSize; // pixel density
	// Set grid with
	texCoord = saturate(GridWidth*0.5-abs(texCoord)); // clamp values

	// Adjust grid look
	{
		// Safe bottom-color in linear range
		static float safeBottomColor = GammaConvert::to_linear(16f/255f); // linear workflow
		safeBottomColor *= 1f-DimCalibrationBackground;
		display = mad(
			display, // background
			DimCalibrationBackground, // dimming amount
			safeBottomColor
		);
	}
	// Apply calibration grid colors
	switch (GridLook)
	{
		case 1: // black
			display *= (1f-texCoord.x)*(1f-texCoord.y);
			break;
		case 2: // white
			display = 1f-(1f-texCoord.x)*(1f-texCoord.y)*(1f-display);
			break;
		case 3: // display red-green
		{
			display = lerp(display, float3(1f, 0f, 0f), texCoord.y);
			display = lerp(display, float3(0f, 1f, 0f), texCoord.x);
		} break;
		default: // yellow
			display = lerp(float3(1f, 1f, 0f), display, (1f-texCoord.x)*(1f-texCoord.y));
			break;
	}

	return display; // background picture with grid superimposed over it
}

// Debug view mode shader
float3 SamplingScaleModeViewPass(
	float2 texCoord,
	float3 display
)
{
	// Define Mapping color
	const static float3   underSample = float3(235f, 16f, 16f)/255f; // red
	const static float3 neutralSample = float3(16f, 235f, 16f)/255f; // green
	const static float3   superSample = float3(16f, 16f, 235f)/255f; // blue

	// Scale texture coordinates to pixel size
	texCoord *= BUFFER_SCREEN_SIZE*ResScaleVirtual/float(ResScaleScreen);
	texCoord = float2(
		length(float2(ddx(texCoord.x), ddy(texCoord.x))),
		length(float2(ddx(texCoord.y), ddy(texCoord.y)))
	);
	// Get pixel area
	float pixelScale = texCoord.x*texCoord.y*2f;
	// Get pixel area in false-color
	float3 pixelScaleMap = lerp(
		lerp(
			underSample,
			neutralSample,
			s_curve(saturate(pixelScale-1f)) // ↤ [0, 1] area range
		),
		superSample,
		s_curve(saturate(pixelScale-2f)) // ↤ [1, 2] area range
	);

	// Linear workflow
	display = GammaConvert::to_display(display);

	const static float safeRange[2] = {16f/255f, 235f/255f};
	// Get luma channel mapped to save range
	display.x = lerp(
		safeRange[0], // safe range bottom
		safeRange[1], // safe range top
		ColorConvert::RGB_to_Luma(display)
	);
	// Adjust background look
	display = lerp(
		safeRange[0], // safe bottom-color range
		display, // background
		DimCalibrationBackground // dimming amount
	);
	// Adjust background look
	display = lerp(
		// Linear workflow
		GammaConvert::to_linear(display.x), // background
		pixelScaleMap, // pixel scale map
		sqrt(1.25)-0.5 // golden ratio by JMF
	);
	return display;
}

// Vertex shader generating a triangle covering the entire screen
void PerfectPerspectiveVS(
	in  uint   id        : SV_VertexID,
	out float4 position  : SV_Position,
	out float2 texCoord  : TEXCOORD0,
	out float2 viewCoord : TEXCOORD1
)
{
	// Define vertex position
	const static float2 vertexPos[3] =
	{
		float2(-1f, 1f), // top left
		float2(-1f,-3f), // bottom left
		float2( 3f, 1f)  // top right
	};
	// Export vertex position
	position = float4(vertexPos[id], 0f, 1f);
	// Export screen centered texture coordinates
	texCoord.x = viewCoord.x =  vertexPos[id].x;
	texCoord.y = viewCoord.y = -vertexPos[id].y;
	// Map to corner and normalize texture coordinates
	texCoord = texCoord*0.5+0.5;
	// Get aspect ratio transformation vector
	const static float2 viewProportions = normalize(BUFFER_SCREEN_SIZE);
	// Correct aspect ratio, normalized to the corner
	viewCoord *= viewProportions;

//----------------------------------------------
// begin cropping of image bounds

	// Half field of view angle in radians
	const static float halfOmega = radians(FovAngle*0.5);
	// Get radius at Ω for a given FoV type
	const static float radiusOfOmega = getRadiusOfOmega(viewProportions);
	// Reciprocal focal length
	const static float rcp_focal = get_rcp_focal(halfOmega, radiusOfOmega, K);

	// Horizontal point radius
	const static float croppingHorizontal = get_radius(
			atan(tan(halfOmega)/radiusOfOmega*viewProportions.x),
		rcp_focal, K)/viewProportions.x;
#if AXOMORPHIC_MODE==1
	// Vertical point radius
	const static float croppingVertical = get_radius(
			atan(tan(halfOmega)/radiusOfOmega*viewProportions.y),
		rcp_focal, Ky)/viewProportions.y;
	// Diagonal point radius
	const static float croppingDigonal = binarySearchCorner(halfOmega, radiusOfOmega, rcp_focal);

	// Circular fish-eye
	const static float circularFishEye = max(croppingHorizontal, croppingVertical);
	// Cropped circle
	const static float croppedCircle = min(croppingHorizontal, croppingVertical);
	// Full-frame
	const static float fullFrame = croppingDigonal;
#elif AXOMORPHIC_MODE>=2
	// Vertical point radius
	const static float2 croppingVertical = float2(
		get_radius(
			atan(tan(halfOmega)/radiusOfOmega*viewProportions.y),
			rcp_focal, Ky),
		get_radius(
			atan(tan(halfOmega)/radiusOfOmega*viewProportions.y),
			rcp_focal, KyA)
	)/viewProportions.y;
	// Diagonal point radius
	const static float2 croppingDigonal = binarySearchCorner(halfOmega, radiusOfOmega, rcp_focal);

	// Circular fish-eye
	const static float circularFishEye = max(max(croppingHorizontal, croppingVertical.s), croppingVertical.t);
	// Cropped circle
	const static float croppedCircle = min(min(croppingHorizontal, croppingVertical.s), croppingVertical.t);
	// Full-frame
	const static float fullFrame = min(croppingDigonal.s, croppingDigonal.t);
#else // border cropping radius is in anamorphic coordinates
	// Vertical point radius
	const static float croppingVertical = get_radius(
			atan(tan(halfOmega)/radiusOfOmega*viewProportions.y*rsqrt(S)),
		rcp_focal, K)/viewProportions.y*sqrt(S);
	// Diagonal point radius
	const static float anamorphicDiagonal = length(float2(
		viewProportions.x,
		viewProportions.y*rsqrt(S)
	));
	const static float croppingDigonal = get_radius(
			atan(tan(halfOmega)/radiusOfOmega*anamorphicDiagonal),
		rcp_focal, K)/anamorphicDiagonal;

	// Circular fish-eye
	const static float circularFishEye = max(croppingHorizontal, croppingVertical);
	// Cropped circle
	const static float croppedCircle = min(croppingHorizontal, croppingVertical);
	// Full-frame
	const static float fullFrame = croppingDigonal;
#endif
	// Get radius scaling for bounds alignment
	const static float croppingScalar =
		CroppingFactor<0.5
		? lerp(
			circularFishEye, // circular fish-eye
			croppedCircle,   // cropped circle
			max(CroppingFactor*2f, 0f) // ↤ [0,1] range
		)
		: lerp(
			croppedCircle, // cropped circle
			fullFrame, // full-frame
			min(CroppingFactor*2f-1f, 1f) // ↤ [1,2] range
		);

	// Scale view coordinates to cropping bounds
	viewCoord *= croppingScalar;
}

// Main perspective shader pass
float3 PerfectPerspectivePS(
	float4 pixelPos  : SV_Position,
	float2 texCoord  : TEXCOORD0,
	float2 viewCoord : TEXCOORD1
) : SV_Target
{

//----------------------------------------------
// begin distortion mapping bypass

#if AXOMORPHIC_MODE==1 // take vertical k factor into account
	if (FovAngle==0u || (K==1f && Ky==1f && !UseVignette))
#elif AXOMORPHIC_MODE>=2 // take both vertical k factors into account
	if (FovAngle==0u || (K==1f && Ky==1f && KyA==1f && !UseVignette))
#else // consider only global k
	if (FovAngle==0u || (K==1f && !UseVignette))
#endif
	// Bypass perspective mapping
	{
		float3 display;
		if (CalibrationModeView)
		{
			switch (CalibrationMode) // choose output type
			{
				case 1u: // pixel scale-map
					display = SamplingScaleModeViewPass(
						texCoord,
						GammaConvert::to_linear(tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb) // manual gamma correction
					); break;
				default: // calibration grid
					display = GridModeViewPass(uint2(pixelPos.xy), texCoord, display);
					break;
			}
			// Linear workflow
			display = GammaConvert::to_display(display); // manually correct gamma

			return BlueNoise::dither(display, uint2(pixelPos.xy)); // dither final 8/10-bit result
		}
		else // bypass all effects
		{
			display = tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb;

			if (UseVignette && VignetteOffset!=0f) // maintain constant brightness across all FoV values
			{
				// Manually correct gamma
				display = GammaConvert::to_linear(display);
				display *= 1f+VignetteOffset;
				display = GammaConvert::to_display(display);
				// Dither final 8/10-bit result
				display = BlueNoise::dither(display, uint2(pixelPos.xy));
			}

			return display;
		}
	}

// end of distortion mapping bypass
//----------------------------------------------

//----------------------------------------------
// begin of perspective mapping

	// Aspect ratio transformation vector
	const static float2 viewProportions = normalize(BUFFER_SCREEN_SIZE);
	// Half field of view angle in radians
	const static float halfOmega = radians(FovAngle*0.5);
	// Get radius at Ω for a given FoV type
	const static float radiusOfOmega = getRadiusOfOmega(viewProportions);
	// Reciprocal focal length
	const static float rcp_focal = get_rcp_focal(halfOmega, radiusOfOmega, K);

	// Image radius
#if AXOMORPHIC_MODE // simple length function for radius
	float radius = length(viewCoord);
#else // derive radius from anamorphic coordinates
	float radius = S==1f
		? dot(viewCoord, viewCoord) // spherical
		: viewCoord.y*viewCoord.y/S+viewCoord.x*viewCoord.x; // anamorphic
	float rcp_radius = rsqrt(radius); radius = sqrt(radius);
#endif

#if AXOMORPHIC_MODE // derive θ angle from two distinct projections
	// Axomorphic interpolation weights
	float2 phiMtx = get_phi_weights(viewCoord);
	// Horizontal and vertical incident angle
	float2 theta2 = float2(
		get_theta(radius, rcp_focal, K),
	#if AXOMORPHIC_MODE==1
		get_theta(radius, rcp_focal, Ky)
	#elif AXOMORPHIC_MODE>=2
		get_theta(radius, rcp_focal, viewCoord.y>=0f ? KyA : Ky)
	#endif
	);
	float vignette = UseVignette
		? dot(phiMtx, float2(
			get_vignette(theta2.x, radius, rcp_focal),
			get_vignette(theta2.y, radius, rcp_focal)))+VignetteOffset
		: 1f;
	float theta = dot(phiMtx, theta2); // axomorphic incident
#else // get θ from anamorphic radius
	float theta = get_theta(radius, rcp_focal, K);
	float vignette;
	if (UseVignette)
	{
		if (S!=1f) // get actual theta and radius
		{
			// Get anamorphic-incident 3D vector
			float3 incident = float3(
				(sin(theta)*rcp_radius)*viewCoord,
				 cos(theta)
			);
			vignette = get_vignette(acos(normalize(incident).z), length(viewCoord), rcp_focal)+VignetteOffset;
		}
		else vignette = get_vignette(theta, radius, rcp_focal)+VignetteOffset;
	}
	else vignette = 1f; // no vignetting
#endif

	// Rectilinear perspective transformation
#if AXOMORPHIC_MODE // simple rectilinear transformation
	viewCoord = tan(theta)*normalize(viewCoord);
#else // normalize by anamorphic radius
	viewCoord *= tan(theta)*rcp_radius;
#endif

	// Back to normalized, centered coordinates
	const static float2 toUvCoord = radiusOfOmega/(tan(halfOmega)*viewProportions);
	viewCoord *= toUvCoord;

// end of perspective mapping
//----------------------------------------------

	// Back to UV Coordinates
	texCoord = viewCoord*0.5+0.5;

	// Sample display image
	float3 display =
		K!=1f
#if AXOMORPHIC_MODE==1 // take vertical k factor into account
		|| Ky!=1f
#elif AXOMORPHIC_MODE>=2 // take both vertical k factors into account
		|| Ky!=1f || KyA!=1f
#endif // consider only global k
		? tex2D(BackBuffer, texCoord).rgb // perspective projection lookup
		: tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb; // no perspective change

	// manual gamma correction
	display = GammaConvert::to_linear(display);

	// Display calibration view
	if (CalibrationModeView)
	switch (CalibrationMode) // choose output type
	{
		case 1u: // pixel scale-map
			display = SamplingScaleModeViewPass(texCoord, display);
			break;
		default: // calibration grid
			display = GridModeViewPass(uint2(pixelPos.xy), texCoord, display);
			break;
	}

	// Display border
	if (
#if AXOMORPHIC_MODE==1 // take vertical k factor into account
		(K!=1f || Ky!=1f)
#elif AXOMORPHIC_MODE>=2 // take both vertical k factors into account
		(K!=1f || Ky!=1f || KyA!=1f)
#else // consider only global k
		K!=1f
#endif
		&& CroppingFactor<1f) // visible borders
	{
		// Get border image
		float3 border = lerp(
			// manual gamma correction
			MirrorBorder ? display : GammaConvert::to_linear(tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb), // border background
			// Linear workflow
			GammaConvert::to_linear(BorderColor.rgb), // border color
			GammaConvert::to_linear(BorderColor.a)    // border alpha
		);

		// Outside border mask with anti-aliasing
		float borderMask = GetBorderMask(viewCoord);
		// Apply vignette with border
		display = BorderVignette
			? vignette*lerp(display, border, borderMask)  // vignette on border
			: lerp(vignette*display, border, borderMask); // vignette only inside
	}
	else if (UseVignette) // apply vignette
		display *= vignette;

	// Manually correct gamma
	display = GammaConvert::to_display(display);

	// Dither final 8/10-bit result
	return BlueNoise::dither(display, uint2(pixelPos.xy));
}

/* >> Output << */

technique PerfectPerspective
<
	ui_label = "Perfect Perspective (fisheye, anamorphic, axomorphic)";
	ui_tooltip =
		"Adjust perspective for distortion-free picture:\n"
		"\n"
		"	· Fish-eye\n"
		"	· Panini\n"
		"	· Axomorphic (*)\n"
		"	· Axomorphic asymmetrical (**)\n"
		"	· Anamorphic\n"
		"	· Vignetting (natural)\n"
		"\n"
		"Instruction:\n"
		"\n"
		"	1# select proper FoV angle and type. If FoV type is unknown,\n"
		"	   find a round object within the game and look at it upfront,\n"
		"	   then rotate the camera so that the object is in the corner.\n"
#if AXOMORPHIC_MODE
		"	   Make sure all 'k' parameters are equal 0.5 and adjust FoV type such that\n"
#else
		"	   Set 'k' to 0.5, change squeeze factor to 1x and adjust FoV type such that\n"
#endif
		"	   the object does not have an egg shape, but a perfect round shape.\n"
		"\n"
		"	2# adjust perspective type according to game-play style.\n"
#if AXOMORPHIC_MODE
		"	   If you look mostly at the horizon, 'k.y' can be increased.\n"
#else
		"	   If you look mostly at the horizon, anamorphic squeeze can be increased.\n"
#endif
		"	   For curved-display correction, set it to higher value.\n"
		"\n"
		"	3# adjust visible borders. You can change the zoom factor,\n"
		"	   such that no borders are visible, or that no image area is lost.\n"
		"\n"
		"	4# use 4lex4nder/ReshadeEffectShaderToggler addon, to render the distortion\n"
		"	   under user interface.\n"
		"\n"
		"	5# additionally for sharp image, use sharpening FX or run game at a\n"
		"	   Super-Resolution. Debug options can help you find the proper value.\n"
		"\n"
		"	(*) for more available settings set AXOMORPHIC_MODE value to 0, 1 or 2.\n"
		"\n"
		"\n"
		"The algorithm is part of a scientific article:\n"
		"	arXiv:2003.10558 [cs.GR] (2020)\n"
		"	arXiv:2010.04077 [cs.GR] (2020)\n"
		"	arXiv:2102.12682 [cs.GR] (2021)\n"
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC+ BY-SA 3.0\n"
		"for additional permissions see the source code.";
>
{
	pass PerspectiveDistortion
	{
		VertexShader = PerfectPerspectiveVS;
		PixelShader = PerfectPerspectivePS;
	}
}
