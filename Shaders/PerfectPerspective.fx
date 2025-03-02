/* >> Description << */

/* Perfect Perspective PS (version 5.13.1)

Copyright:
This code © 2018-2025 Jakub Maksymilian Fober

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
	Aximorphic Perspective Projection Model for Immersive Imagery
	arXiv:2102.12682 [cs.GR] (2021)
	https://arxiv.org/abs/2102.12682
by Fober, J. M.
*/

/* >> Macros << */

/* Special hidden menu options.
   0 disables advanced options.
   1 enables advanced options. */
#ifndef ADVANCED_MENU
	#define ADVANCED_MENU 0
#endif

/* Alternative to anamorphic.
   1 gives separate distortion option for vertical axis.
   2 gives separate option for top and bottom half. */
#ifndef AXIMORPHIC_MODE
	#define AXIMORPHIC_MODE 1
#endif

/* High quality sampling.
   0 disables mipmapping.
   1 gives level 2 mipmap.
   ...
   4 maximum mipmapping lvl, equivalent of x16 anisotropic filtering. */
#ifndef MIPMAPPING_LEVEL
	#define MIPMAPPING_LEVEL 0
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
	ui_text = "> Match game settings <";
	ui_units = "°";
	ui_label = "Field of view (FOV)";
	ui_tooltip = "Should match in-game FOV value.";
	ui_max = 140u;
> = 90u;

uniform uint FovType
<
	ui_type = "combo";
	ui_category = "In game";
	ui_label = "Field of view type";
	ui_tooltip =
		"This should match game-specific FOV type.\n"
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
#if AXIMORPHIC_MODE
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

// k indicates horizontal axis or whole picture projection type
uniform float K
<
	ui_type = "slider";
	ui_category = "Distortion";
	ui_category_closed = true;
	ui_units = " k";
	ui_text =
		"> -0.5 | distance <\n"
		">    0 | speed    <\n"
		">  0.5 | shape    <";
#if AXIMORPHIC_MODE // k indicates horizontal axis projection type
	ui_label = "Horizontal profile";
	ui_tooltip = "Projection coefficient 'k' horizontal, represents\n"
#else // k represents whole picture projection type
	ui_label = "Fisheye profile";
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

#if AXIMORPHIC_MODE==1 // vertical axis projection is driven by separate k parameter
uniform float Ky
<
	ui_type = "slider";
	ui_category = "Distortion";
	ui_units = " k";
	ui_label = "Vertical profile";
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

#elif AXIMORPHIC_MODE>=2 // vertical axis projection is driven by separate ky top and ky bottom parameter
uniform float Ky
<
	ui_type = "slider";
	ui_category = "Distortion";
	ui_units = " k";
	ui_label = "Top profile";
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

uniform float KyA
<
	ui_type = "slider";
	ui_category = "Distortion";
	ui_units = " k";
	ui_label = "Bottom profile";
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
	ui_units = "x";
	ui_label = "Anamorphic squeeze";
	ui_tooltip =
		"Anamorphic squeeze factor, affects\n"
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
	ui_label = "Natural vignette";
	ui_tooltip = "Apply projection-correct natural vignetting effect.";
> = true;

// Border

uniform float CroppingFactor
<
	ui_type = "slider";
	ui_text =
		">   0 | circular       <\n"
		"> 0.5 | cropped-circle <\n"
		">   1 | full-frame     <";
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
	ui_min = 0f; ui_max = 1f; ui_step = 0.005;
> = 0.5;

uniform float4 BorderColor
<
	ui_type = "color";
	ui_category = "Border appearance";
	ui_label = "Border color";
	ui_tooltip = "Use alpha to change border transparency.";
> = float4(0.027, 0.027, 0.027, 0.96);

// Cosmetics

uniform float BorderCorner
<
	ui_type = "slider";
	ui_category = "Cosmetics";
	ui_category_closed = true;
	ui_label = "Corner roundness";
	ui_tooltip = "Value of 0 gives sharp corners.";
	ui_min = 0f; ui_max = 1f; ui_step = 0.01;
> = 0.062;

uniform uint BorderGContinuity
<
	ui_type = "slider";
	ui_category = "Cosmetics";
	hidden = !ADVANCED_MENU;
	ui_units = "G";
	ui_label = "Corner profile";
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

uniform float VignetteOffset
<
	ui_type = "slider";
	ui_category = "Cosmetics";
	hidden = !ADVANCED_MENU;
	ui_units = "+";
	ui_label = "Vignette exposure";
	ui_tooltip = "Brighten the image with vignette enabled.";
	ui_min = 0f; ui_max = 0.2; ui_step = 0.01;
> = 0.05;

uniform bool MirrorBorder
<
	ui_type = "input";
	ui_category = "Cosmetics";
	ui_label = "Mirror on border";
	ui_tooltip = "Choose mirrored or original image on the border.";
> = false;

// Calibration Options

uniform bool CalibrationModeView
<
	ui_type = "input";
	ui_category = "Calibration mode";
	ui_category_closed = true;
	nosave = true;
	ui_label = "Enable calibration grid";
	ui_tooltip = "Display calibration grid for lens-matching.";
> = false;

uniform float GridSize
<
	ui_type = "slider";
	ui_text = "\n";
	ui_category = "Calibration mode";
	hidden = !ADVANCED_MENU;
	ui_label = "Size";
	ui_tooltip = "Adjust calibration grid size.";
	ui_min = 2f; ui_max = 32f; ui_step = 0.01;
> = 16f;

uniform float GridWidth
<
	ui_type = "slider";
	ui_category = "Calibration mode";
	hidden = !ADVANCED_MENU;
	ui_units = " pixels";
	ui_label = "Width";
	ui_tooltip = "Adjust calibration grid bar width in pixels.";
	ui_min = 2f; ui_max = 16f; ui_step = 0.01;
> = 4f;

uniform float GridTilt
<
	ui_type = "slider";
	ui_category = "Calibration mode";
	hidden = !ADVANCED_MENU;
	ui_units = "°";
	ui_label = "Tilt";
	ui_tooltip = "Adjust calibration grid tilt in degrees.";
	ui_min = -1f; ui_max = 1f; ui_step = 0.01;
> = 0f;

uniform float BackgroundDim
<
	ui_type = "slider";
	ui_category = "Calibration mode";
	hidden = !ADVANCED_MENU;
	ui_label = "Background dimming";
	ui_tooltip = "Choose the calibration background dimming.";
	ui_min = 0f; ui_max = 1f; ui_step = 0.01;
> = 0.5;

/* >> Textures << */

#if MIPMAPPING_LEVEL
// Buffer texture target with mipmapping
texture2D BackBufferMipTarget_Tex
< pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

	// Storing linear gamma picture in higher bit depth
#if (BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_SRGB) || (BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_BT2020_PQ)
	Format = RGB10A2;
#else // BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_SCRGB // Fall back on a higher quality in any other case, for future compatibility
	Format = RGBA16F;
#endif

	// Maximum MIP map level
	#if MIPMAPPING_LEVEL>0 && MIPMAPPING_LEVEL<=4
	MipLevels = MIPMAPPING_LEVEL+1;
	#else
	MipLevels = 5; // maximum MIP level
	#endif
};
#endif

// Define screen texture with mirror tiles and anisotropic filtering
sampler2D BackBuffer
{
#if MIPMAPPING_LEVEL
	Texture = BackBufferMipTarget_Tex; // back buffer texture target with additional MIP levels
#else
	Texture = ReShade::BackBufferTex; // back buffer texture target
#endif

	// Border style
	AddressU = MIRROR;
	AddressV = MIRROR;

	// Filtering
	MagFilter = ANISOTROPIC;
	MinFilter = ANISOTROPIC;
	MipFilter = ANISOTROPIC;
};

/* >> Functions << */

// Get reciprocal screen aspect ratio (1/x)
#define BUFFER_RCP_ASPECT_RATIO (BUFFER_HEIGHT*BUFFER_RCP_WIDTH)

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
	pos = exp(log(abs(pos))*(++G)); // position to the power of G+1
	return exp(log(pos.x+pos.y)/G); // position to the power of G+1 root
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
	if      (k>0f)  return tan(abs(k)*theta)/rcp_f/abs(k); // stereographic, rectilinear projections
	else if (k<0f)  return sin(abs(k)*theta)/rcp_f/abs(k); // equisolid, orthographic projections
	else  /*k==0f*/ return            theta /rcp_f;        // equidistant projection
}
#define get_rcp_focal(halfOmega, radiusOfOmega, k) get_radius(halfOmega, radiusOfOmega, k) // get reciprocal focal length
float get_theta(float radius, float rcp_f, float k) // get spherical θ angle
{
	if      (k>0f)  return atan(abs(k)*radius*rcp_f)/abs(k); // stereographic, rectilinear projections
	else if (k<0f)  return asin(abs(k)*radius*rcp_f)/abs(k); // equisolid, orthographic projections
	else  /*k==0f*/ return             radius*rcp_f;         // equidistant projection
}
float get_vignette(float theta, float r, float rcp_f) // get vignetting mask in linear color space
{ return sin(theta)/r/rcp_f; }
float2 get_phi_weights(float2 viewCoord) // get aximorphic interpolation weights
{
	viewCoord *= viewCoord; // squared vector coordinates
	return viewCoord/(viewCoord.x+viewCoord.y); // [cos²φ sin²φ] vector
}

// Get radius at Ω for a given FOV type
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

#if AXIMORPHIC_MODE==1
// Search for corner point radius at diagonal Ω in Aximorphic perspective
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
#elif AXIMORPHIC_MODE>=2
// Search for corner point radius at diagonal Ω in Aximorphic asymmetrical perspective
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
	float2 texCoord
)
{
	// Sample background without distortion
#if MIPMAPPING_LEVEL
	float3 display = tex2Dfetch(BackBuffer, pixelCoord).rgb;
#else // manual gamma linearization
	float3 display = GammaConvert::to_linear(tex2Dfetch(BackBuffer, pixelCoord).rgb);
#endif

	// Dim calibration background
	display *= clamp(1f-BackgroundDim, 0f, 1f);

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
	// Apply calibration grid colors
	display = lerp(float3(1f, 1f, 0f), display, (1f-texCoord.x)*(1f-texCoord.y));

	return display; // background picture with grid superimposed over it
}

#if MIPMAPPING_LEVEL
void BackBufferMipTarget_VS(
	in  uint   vertexId : SV_VertexID,
	out float4 position : SV_Position // no texture mapping
)
{
	// Generate vertex position for triangle ABC covering whole screen
	position.x = vertexId==2? 3f :-1f;
	position.y = vertexId==1?-3f : 1f;

	// Initialize other values
	position.z = 0f; // not used
	position.w = 1f; // not used
}

void BackBufferMipTarget_PS(
	in  float4 pos     : SV_Position,
	out float4 display : SV_Target
)
{
	// Generating MIP maps in linear gamma color space
	display.rgb = GammaConvert::to_linear(
		tex2Dfetch(
			ReShade::BackBuffer, // standard back-buffer
			uint2(pos.xy)        // pixel position without resampling
		).rgb
	);
	display.a = 1f;
}
#endif

// Vertex shader generating a triangle covering the entire screen
void PerfectPerspective_VS(
	in  uint   vertexId  : SV_VertexID,
	out float4 position  : SV_Position,
	out float2 texCoord  : TEXCOORD0,
	out float2 viewCoord : TEXCOORD1
)
{
	// Generate vertex position for triangle ABC covering whole screen
	position.x = vertexId==2? 3f :-1f;
	position.y = vertexId==1?-3f : 1f;
	// Initialize other values
	position.z = 0f; // not used
	position.w = 1f; // not used

	// Export screen centered texture coordinates
	texCoord.x = viewCoord.x =  position.x;
	texCoord.y = viewCoord.y = -position.y;
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
	// Get radius at Ω for a given FOV type
	const static float radiusOfOmega = getRadiusOfOmega(viewProportions);
	// Reciprocal focal length
	const static float rcp_focal = get_rcp_focal(halfOmega, radiusOfOmega, K);

	// Horizontal point radius
	const static float croppingHorizontal = get_radius(
			atan(tan(halfOmega)/radiusOfOmega*viewProportions.x),
		rcp_focal, K)/viewProportions.x;
#if AXIMORPHIC_MODE==1
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
#elif AXIMORPHIC_MODE>=2
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
float3 PerfectPerspective_PS(
	float4 pixelPos  : SV_Position,
	float2 texCoord  : TEXCOORD0,
	float2 viewCoord : TEXCOORD1
) : SV_Target
{

//----------------------------------------------
// begin distortion mapping bypass

#if AXIMORPHIC_MODE==1 // take vertical k factor into account
	if (FovAngle==0u || (K==1f && Ky==1f && !UseVignette))
#elif AXIMORPHIC_MODE>=2 // take both vertical k factors into account
	if (FovAngle==0u || (K==1f && Ky==1f && KyA==1f && !UseVignette))
#else // consider only global k
	if (FovAngle==0u || (K==1f && !UseVignette))
#endif
	// Bypass perspective mapping
	{
		float3 display;

		if (CalibrationModeView) // draw calibration grid
			display = GridModeViewPass(uint2(pixelPos.xy), texCoord);
		else // sample the background
#if MIPMAPPING_LEVEL
			display = tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb;
#else // manual gamma linearization
			display = GammaConvert::to_linear(tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb);
#endif

		if (UseVignette && VignetteOffset!=0f) // maintain constant brightness across all FOV values
		{
			display *= 1f+VignetteOffset;
			// Manually correct gamma
			display = GammaConvert::to_display(display);
#if BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_UNKNOWN || BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_SRGB
			// Dither final 8/10-bit result
			display = BlueNoise::dither(display, uint2(pixelPos.xy));
#endif
		}
		else display = GammaConvert::to_display(display);

		return display;
	}

// end of distortion mapping bypass
//----------------------------------------------

//----------------------------------------------
// begin of perspective mapping

	// Aspect ratio transformation vector
	const static float2 viewProportions = normalize(BUFFER_SCREEN_SIZE);
	// Half field of view angle in radians
	const static float halfOmega = radians(FovAngle*0.5);
	// Get radius at Ω for a given FOV type
	const static float radiusOfOmega = getRadiusOfOmega(viewProportions);
	// Reciprocal focal length
	const static float rcp_focal = get_rcp_focal(halfOmega, radiusOfOmega, K);

	// Image radius
#if AXIMORPHIC_MODE // simple length function for radius
	float radius = length(viewCoord);
#else // derive radius from anamorphic coordinates
	float radius = S==1f
		? dot(viewCoord, viewCoord) // spherical
		: viewCoord.y*viewCoord.y/S+viewCoord.x*viewCoord.x; // anamorphic
	float rcp_radius = rsqrt(radius); radius = sqrt(radius);
#endif

#if AXIMORPHIC_MODE // derive θ angle from two distinct projections
	// Aximorphic interpolation weights
	float2 phiMtx = get_phi_weights(viewCoord);
	// Horizontal and vertical incident angle
	float2 theta2 = float2(
		get_theta(radius, rcp_focal, K),
	#if AXIMORPHIC_MODE==1
		get_theta(radius, rcp_focal, Ky)
	#elif AXIMORPHIC_MODE>=2
		get_theta(radius, rcp_focal, viewCoord.y>=0f ? KyA : Ky)
	#endif
	);
	float vignette = UseVignette
		? dot(phiMtx, float2(
			get_vignette(theta2.x, radius, rcp_focal),
			get_vignette(theta2.y, radius, rcp_focal)))+VignetteOffset
		: 1f;
	float theta = dot(phiMtx, theta2); // aximorphic incident
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
#if AXIMORPHIC_MODE // simple rectilinear transformation
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
	float3 display;

	if (CalibrationModeView) // display calibration grid
		display = GridModeViewPass(uint2(pixelPos.xy), texCoord);
	else
	{
		display =
			K!=1f
#if AXIMORPHIC_MODE==1 // take vertical k factor into account
			|| Ky!=1f
#elif AXIMORPHIC_MODE>=2 // take both vertical k factors into account
			|| Ky!=1f || KyA!=1f
#endif // consider only global k
			? tex2Dgrad(BackBuffer, texCoord, ddx(texCoord), ddy(texCoord)).rgb // perspective projection lookup with mip-mapping and anisotropic filtering
			: tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb; // no perspective change

#if !MIPMAPPING_LEVEL
		display = GammaConvert::to_linear(display); // manual gamma linearization
#endif
	}

	// Display border
	if (
#if AXIMORPHIC_MODE==1 // take vertical k factor into account
		(K!=1f || Ky!=1f)
#elif AXIMORPHIC_MODE>=2 // take both vertical k factors into account
		(K!=1f || Ky!=1f || KyA!=1f)
#else // consider only global k
		K!=1f
#endif
		&& CroppingFactor<1f) // visible borders
	{
		// Get border image
		float3 border = lerp(
			// Sample distorted or undistorted picture at the border
#if MIPMAPPING_LEVEL
			MirrorBorder ? display : tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb, // border background
#else // manual gamma linearization
			MirrorBorder ? display : GammaConvert::to_linear(tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb), // border background
#endif
			// Linear workflow
			GammaConvert::to_linear(BorderColor.rgb), // border color
			GammaConvert::to_linear(BorderColor.a)    // border alpha
		);

		// Outside border mask with anti-aliasing
		float borderMask = GetBorderMask(viewCoord);
		// Apply vignette with border
		display = MirrorBorder
			? vignette*lerp(display, border, borderMask)  // vignette on border
			: lerp(vignette*display, border, borderMask); // vignette only inside
	}
	else if (UseVignette) // apply vignette
		display *= vignette;

	// Manually correct gamma
	display = GammaConvert::to_display(display);

#if BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_UNKNOWN || BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_SRGB
	// Dither final 8/10-bit result in SDR
	return BlueNoise::dither(display, uint2(pixelPos.xy));
#else
	// Don't dither in HDR modes, it shouldn't be necessary due to the higher quality of input, and the display
    return display;
#endif
}

/* >> Output << */

technique PerfectPerspective
<
	ui_label = "Perfect Perspective (fisheye)";
	ui_tooltip =
		"Adjust picture perspective for perfect distortion:\n"
		"\n"
		"      Fish-eye | AXIMORPHIC_MODE 0\n"
		"    Anamorphic | AXIMORPHIC_MODE 0\n"
		"        * Distortion aspect ratio.\n"
		"    Aximorphic | AXIMORPHIC_MODE 1\n"
		"        * Separate distortion for X/Y.\n"
		"  Asymmetrical | AXIMORPHIC_MODE 2\n"
		"        * Separate distortion for X/top/bottom.\n"
		"\n"
		"\n"
		"Instruction:\n"
		"\n"
		"	1. Select proper FOV angle and type matching game settings.\n"
		"	   If FOV type is unknown:\n"
		"\n"
		"	 a. Find a round object within the game.\n"
		"	 b. Stand upfront.\n"
		"	 c. Rotate the camera putting the object at the corner.\n"
#if AXIMORPHIC_MODE
		"	 d. Make sure all 'k' parameters are equal to 0.5.\n"
#else
		"	 d. Set 'k' to 0.5, change squeeze factor to 1x.\n"
#endif
		"	 e. Switch FOV type until object has a round shape, not an egg.\n"
		"\n"
		"	2. Adjust distortion according to a game-play style.\n"
		"\n"
		"	 + for other distortion profiles set AXIMORPHIC_MODE to 0, 1, 2.\n"
		"\n"
		"	3. Adjust visible borders. You can change the cropping, such that\n"
		"	   no borders will be visible, or that no image area get lost.\n"
		"\n"
		"	 + use '4lex4nder/ReshadeEffectShaderToggler' add-on,\n"
		"	   to undistort the UI (user interface).\n"
		"\n"
		"	 + use sharpening, or run the game at Super-Resolution.\n"
		"\n"
		"	 + for more adjustable parameters set ADVANCED_MENU to 1.\n"
		"\n"
		"\n"
		"The algorithm is part of a scientific article:\n"
		"	arXiv:2003.10558 [cs.GR] (2020)\n"
		"	arXiv:2010.04077 [cs.GR] (2020)\n"
		"	arXiv:2102.12682 [cs.GR] (2021)\n"
		"\n"
		"This effect © 2018-2025 Jakub Maksymilian Fober\n"
		"Licensed under CC+ BY-SA 3.0\n"
		"for additional permissions under the CC+ protocol, see the source code.";
>
{
#if MIPMAPPING_LEVEL
	pass CreateMipMaps
	{
		VertexShader = BackBufferMipTarget_VS;
		PixelShader  = BackBufferMipTarget_PS;
		RenderTarget = BackBufferMipTarget_Tex;
	}
#endif
	pass PerspectiveDistortion
	{
		VertexShader = PerfectPerspective_VS;
		PixelShader  = PerfectPerspective_PS;
	}
}
