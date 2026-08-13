/* Perfect Perspective - Fisheye PS (version 6.0.0)
__________               _______________
\______   \ ____________/ ____\______   \ ___________  ____________
 |     ___// __ \_  __ \   __\ |     ___// __ \_  __ \/  ___/\____ \
 |    |   \  ___/|  | \/|  |   |    |   \  ___/|  | \/\___ \ |  |_> >
 |____|    \___  >__|   |__|   |____|    \___  >__|  /____  >|   __/  2026
               \/                            \/           \/ |__|
> Copyright notice:
© 2018-2026 Jakub Maksymilian Fober

> Licensing:
Licensed under the Open Community License v1.1 + Software Attribution v1
(OCL v1.1 + SWAtt v1). To view the authoritative license text visit these links:
https://github.com/OpenCommunityLicence/OpenCommunityLicence/blob/main/LICENSE
https://github.com/OpenCommunityLicence/OpenCommunityLicence/blob/main/addons/SWAtt-v1.md
For a summary visit this link:
https://github.com/OpenCommunityLicence/OpenCommunityLicence

> Contact info:
For inquiries, please contact the designer and copyright owner at:
jakub.m.fober@protonmail.com
________________________________________________________________________________

> Updates:
Visit GitHub repo at https://github.com/Fubaxiusz/fubax-shaders

> Sources:
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
________________________________________________________________________________

Please respect the license */

/* >> Macros << */

/* Special hidden menu options.
0 disables advanced options.
1 enables advanced options. */
#ifndef PP_MORE_COSMETICS
	#define PP_MORE_COSMETICS 0
#endif

/* >> Commons << */

// ReShade specific
#include "ReShade.fxh"

// Perspective mapping functions
#include "PerfectPerspective.fxh"

// Color management cross-FX functions
#include "LinearWorkflow.fxh"
#include "BlueNoiseDither.fxh"

/* >> Menu << */

// Field of View

uniform uint u_fovAngle
<
	ui_type = "slider";
	ui_category = "In game";
	ui_category_closed = true;
	ui_text = "> Match game settings <";
	ui_units = "°";
	ui_label = "Field of view (FOV)";
	ui_tooltip =
		"Must match in-game FOV view value.\n"
		"\n"
		"fSpy software can help you find the number.\n"
		"Get it at https://fspy.io/";
	ui_max = 140u;
> = 90u;

uniform uint u_fovType
<
	ui_type = "combo";
	ui_category = "In game";
	ui_label = "Field of view type";
	ui_tooltip =
		"Must match game-specific FOV type.\n"
		"\n"
		"Adjust so that objects are still round, when placed\n"
		"at the corner, when all 'k' = -0.5, and FOV angle\n"
		"is correct.\n"
		"\n"
		"Instruction:\n"
		"	* If image bulges in movement, change it to 'diagonal'.\n"
		"	* When proportions near screen border are distorted,\n"
		"	  choose 'vertical' or '4:3'.\n"
		"	* For ultra-wide display, try '16:9' instead.\n"
		"	* Do it with all 'k' at -0.5 (stereographic).";
	ui_items =
		"horizontal\0"
		"diagonal\0"
		"vertical\0"
		"horizontal 4:3\0"
		"horizontal 16:9\0";
> = 0u;

// Perspective

// K indicates horizontal axis or whole picture projection type
uniform float3 u_kFactor
<
	ui_type = "slider";
	ui_category = "Distortion";
	ui_category_closed = true;
	ui_units = " k";
	ui_text =
		"> -0.5 | shape    <\n"
		">    0 | speed    <\n"
		">  0.5 | distance <";
	ui_label = "Fisheye profile";
	ui_tooltip =
		"Azimuthal projection type coefficient,\n"
		"affects distortion strength:\n"
		"\n"
		" Preserves | Type | Projection\n"
		"-----------+------+--------------\n"
		"  straight |   -1 | Rectilinear\n"
		"     shape | -0.5 | Stereographic\n"
		"     speed |    0 | Equidistant\n"
		"  distance |  0.5 | Equisolid\n"
		"brightness |    1 | Orthographic\n"
		"\n"
		"[ Ctrl + click ] to type in the value.";
	ui_min = -1.f; ui_max = 1.f; ui_step = 0.01;
> = float3(-0.5, -0.5, -0.5);

// Vignetting

uniform float u_vignetteIntensity
<
	ui_type = "slider";
	ui_category = "Vignetting";
	ui_category_closed = true;
	ui_label = "Vignetting falloff";
	ui_tooltip =
		"Projection specific natural-vignetting falloff.\n"
		"\n"
		"Value | Vignetting Type\n"
		"------+-------------------------------------\n"
		"    0 | no vignetting\n"
		"    1 | cosine law of illumination\n"
		"    2 | inverse-square law of illumination\n"
		"    3 | visual sphere stretching (no cosine)\n"
		"    4 | radiometric law of illumination";
	ui_min = 0.f; ui_max = 4.f; ui_step = 0.5;
> = 1.f;

uniform float u_vignetteOffset
<
	ui_type = "slider";
	ui_category = "Vignetting";
	ui_units = " R";
	ui_label = "Brightness balance radius";
	ui_tooltip =
		"Brightens the image, the\n"
		"vignetting neutral point.";
	ui_min = 0.f; ui_max = 1.f; ui_step = 0.01;
> = 0.25;

// Border

uniform float u_croppingFactor
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
		"Value | Cropping\n"
		"------+---------------\n"
		"    0 | circular\n"
		"  0.5 | cropped-circle\n"
		"    1 | full-frame\n"
		"\n"
		"'Circular' will snap to vertical bounds, 'cropped-\n"
		"circle' to horizontal bounds, and 'full-frame' to\n"
		"corners, for a horizontal (panorama) display.";
	ui_min = 0.f; ui_max = 1.f; ui_step = 0.005;
> = 0.5;

uniform float4 u_borderColor
<
	ui_type = "color";
	ui_category = "Border appearance";
	ui_label = "Border color";
	ui_tooltip = "Change border transparency with 'A' (alpha).";
> = float4(0.027, 0.027, 0.027, 0.96);

// Cosmetics

uniform float u_borderCorner
<
	ui_type = "slider";
	ui_category = "Cosmetics";
	ui_category_closed = true;
	ui_label = "Corner roundness";
	ui_tooltip = "Get sharp corners with value of '0'.";
	ui_min = 0.f; ui_max = 1.f; ui_step = 0.01;
> = 0.062;

uniform uint u_borderContinuity
<
	ui_type = "slider";
	ui_text = "> Border cosmetics - extra <";
	ui_category = "Cosmetics";
	hidden = !PP_MORE_COSMETICS;
	ui_units = "G";
	ui_label = "Corner continuity";
	ui_tooltip =
		"G-surfacing continuity level for the corners:\n"
		"\n"
		"Continuity | Result\n"
		"-----------+------------\n"
		"        G0 | sharp\n"
		"        G1 | circular\n"
		"        G2 | smooth\n"
		"        G3 | very smooth\n"
		"\n"
		"G is a commonly used indicator for industrial design,\n"
		"where G1 is reserved for heavy-duty, G2 for common items,\n"
		"and G3 for luxurious items.";
	ui_min = 1u; ui_max = 3u;
> = 3u;

uniform bool u_borderMirror
<
	ui_type = "input";
	ui_category = "Cosmetics";
	hidden = !PP_MORE_COSMETICS;
	ui_label = "Mirror on border";
	ui_tooltip = "Choose mirrored or original image on the border.";
> = false;

// Calibration Options

uniform bool u_calibrationModeView
<
	ui_type = "input";
	ui_category = "Calibration mode";
	ui_category_closed = true;
	nosave = true;
	ui_label = "Enable calibration grid";
	ui_tooltip = "Display calibration grid for lens-matching.";
> = false;

uniform float u_gridSize
<
	ui_type = "slider";
	ui_text = "> Grid cosmetics - extra <";
	ui_category = "Calibration mode";
	hidden = !PP_MORE_COSMETICS;
	ui_label = "Size";
	ui_tooltip = "Adjust calibration grid size.";
	ui_min = 2.f; ui_max = 32.f; ui_step = 0.01;
> = 16.f;

uniform float u_gridWidth
<
	ui_type = "slider";
	ui_category = "Calibration mode";
	hidden = !PP_MORE_COSMETICS;
	ui_units = " pixels";
	ui_label = "Width";
	ui_tooltip = "Adjust calibration grid bar width in pixels.";
	ui_min = 2.f; ui_max = 16.f; ui_step = 0.01;
> = 3.f;

uniform float u_gridTilt
<
	ui_type = "slider";
	ui_category = "Calibration mode";
	hidden = !PP_MORE_COSMETICS;
	ui_units = "°";
	ui_label = "Tilt";
	ui_tooltip = "Adjust calibration grid tilt in degrees.";
	ui_min = -1.f; ui_max = 1.f; ui_step = 0.01;
> = 0.f;

uniform float u_backgroundDim
<
	ui_type = "slider";
	ui_category = "Calibration mode";
	hidden = !PP_MORE_COSMETICS;
	ui_label = "Background dimming";
	ui_tooltip = "Choose the calibration background dimming.";
	ui_min = 0.f; ui_max = 1.f; ui_step = 0.01;
> = 0.5;

/* >> Functions << */

// Search for corner point radius at diagonal Omega in Aximorphic asymmetrical perspective for automated cropping functionality
float2 binarySearchCorner(float halfOmega, float radiusOfOmega, float focal)
{
	// Initialize search start position
	float2 croppingDigonal = 0.5;
	// Diagonal point Phi weight
	static const float2 diagonalPhi = getPhiLerp(BUFFER_SCREEN_SIZE);
	// Diagonal half-Omega angle
	static const float diagonalHalfOmega = atan(tan(halfOmega) / radiusOfOmega);
	// Search resolution
	const uint searchResolution = ceil(length(BUFFER_SCREEN_SIZE) * 2u); // sub-pixel
	// Find diagonal point top radius with pixel resolution
	[fastopt]
	for (uint d = 2u; d <= searchResolution; d *= 2u) // log2 complexity
	{
		// Get Theta angle at current homing radius value
		float diagonalTheta = dot(
			diagonalPhi, // aximorphic interpolation weight for diagonal vector
			float2( // aximorphic theta angles for horizontal and vertical (up) axis
				getTheta(croppingDigonal.s, focal, u_kFactor.x),
				getTheta(croppingDigonal.s, focal, u_kFactor.y)
			)
		);
		// Perform value homing, if the cropping point is before the corner point,
		// add half-step, if behind, subtract half-step
		croppingDigonal.s += diagonalTheta > diagonalHalfOmega ? -rcp(d) : rcp(d); // move forward or backward
	}
	// Find diagonal point bottom radius with pixel resolution
	[branch]
	if (u_kFactor.y == u_kFactor.z) croppingDigonal.t = croppingDigonal.s;
	else
		[fastopt]
		for (uint d = 2u; d <= searchResolution; d *= 2u) // log2 complexity
		{
			// Get Theta angle at current homing radius value
			float diagonalTheta = dot(
				diagonalPhi, // aximorphic interpolation weight for diagonal vector
				float2( // aximorphic theta angles for horizontal and vertical (down) axis
					getTheta(croppingDigonal.t, focal, u_kFactor.x),
					getTheta(croppingDigonal.t, focal, u_kFactor.z)
				)
			);
			// Perform value homing, if the cropping point is before the corner point,
			// add half-step, if behind, subtract half-step
			croppingDigonal.t += diagonalTheta > diagonalHalfOmega ? -rcp(d) : rcp(d); // move forward or backward
		}

	return croppingDigonal;
}

/* >> Shaders << */

// Border mask shader with rounded corners
float GetBorderMask(float2 borderCoord)
{
	// Get the same coordinates at each corner
	borderCoord = abs(borderCoord);

	#if __RENDERER__ > 0x9000 // fix DirectX9 error
	[branch]
	#endif
	if (u_borderContinuity != 0u && u_borderCorner != 0.f) // if round corners
	{
		// Correct corner aspect ratio
		[branch]
		if (BUFFER_ASPECT_RATIO > 1.f) // if in landscape mode
			borderCoord.x = mad(borderCoord.x, BUFFER_ASPECT_RATIO, 1.f - BUFFER_ASPECT_RATIO);
		else [branch] if (BUFFER_ASPECT_RATIO < 1.f) // if in portrait mode
			borderCoord.y = mad(borderCoord.y, BUFFER_RCP_ASPECT_RATIO, 1.f - BUFFER_RCP_ASPECT_RATIO);

		// Generate scaled coordinates
		borderCoord = max(borderCoord + (u_borderCorner - 1.f), 0.f) / u_borderCorner;
		// Round corner
		return aastep(glength(u_borderContinuity, borderCoord) - 1.f); // ...with G1 to G3 continuity
	}
	else return aastep(glength(0u, borderCoord) - 1.f); // just sharp corner, G0
}

// Generate lens-match grid
float3 GridModeViewPass(
	uint2  texelCoord, // texel pixel coordinates
	float2 texCoord) // texture coordinates
{
	// Sample background without distortion
	#if PP_MIPMAPPING_LEVEL
	// Sample linearized back-buffer
	float3 display = tex2Dfetch(s_backBuffer, texelCoord).rgb;
	#else // manual gamma linearization
	float3 display = LinearWorkflow::toLinearGamma(tex2Dfetch(s_backBuffer, texelCoord).rgb);
	#endif
	// Dim calibration background
	display *= saturate(1.f - u_backgroundDim);

	// Get view coordinates, normalized to the corner
	texCoord = mad(texCoord, 2.f, -1.f) * normalize(BUFFER_SCREEN_SIZE);

	[branch]
	if (u_gridTilt != 0.f) // tilt view coordinates
	{
		// Convert angle to radians
		float tiltRad = radians(u_gridTilt);
		// Get rotation matrix components
		static const float tiltSin = sin(tiltRad);
		static const float tiltCos = cos(tiltRad);
		// Rotate coordinates
		texCoord = mul(
			float2x2( // get rotation matrix
				 tiltCos, tiltSin, // X axis
				-tiltSin, tiltCos // Y axis
			), texCoord // vector coordinates to rotate
		);
	}

	// Get pixel size of the coordinates
	float2x2 Del = float2x2(
		ddx(texCoord.x), ddy(texCoord.x), // X axis
		ddx(texCoord.y), ddy(texCoord.y) // Y axis
	);
	// Scale coordinates to grid size and center
	texCoord = frac(texCoord * u_gridSize) - 0.5;
	/* Scale coordinates to pixel size for anti-aliasing of grid
	   using anti-aliasing step function from research paper
	   arXiv:2010.04077 [cs.GR] (2020) */
	texCoord *= float2(
		rsqrt(dot(Del[0], Del[0])),
		rsqrt(dot(Del[1], Del[1]))
	) / u_gridSize; // pixel density
	// Set grid with
	texCoord = saturate(u_gridWidth * 0.5 - abs(texCoord)); // clamp values
	// Apply calibration grid colors
	display = lerp(
		float3(1.f, 1.f, 0.f), // 100% yellow
		display, // dimmed background
		(1.f - texCoord.x) * (1.f - texCoord.y) // grid lines combined
	);

	return display; // background picture with grid superimposed over it
}

// Vertex shader generating a triangle covering the entire screen
[shader("vertex")]
void v_perfectPerspective(
	in  uint   vertexId : SV_VertexID,
	out float4 position : SV_Position,
	out float2 texCoord : TEXCOORD0,
	out float2 viewCoord : TEXCOORD1)
{
	// Generate vertex position for triangle ABC covering whole screen
	position.x = (vertexId == 2) ?  3.f : -1.f;
	position.y = (vertexId == 1) ? -3.f :  1.f;
	// Initialize other values
	position.z = 0.f; // not used
	position.w = 1.f; // not used

	// Export screen centered texture coordinates
	texCoord.x = viewCoord.x =  position.x;
	texCoord.y = viewCoord.y = -position.y;
	// Map to corner and normalize texture coordinates
	texCoord = mad(viewCoord, 0.5, 0.5);
	// Get aspect ratio transformation vector
	static const float2 viewProportions = normalize(BUFFER_SCREEN_SIZE);
	// Correct aspect ratio, normalized to the corner
	viewCoord *= viewProportions;

// BEGIN CROPPING OF IMAGE BOUNDS ______________________________________________

	// Half field of view angle in radians
	static const float halfOmega = radians(u_fovAngle * 0.5);
	// Get radius at Omega for a given FOV type
	static const float radiusOfOmega = getRadiusOfOmega(viewProportions, u_fovType);
	// Get focal length
	static const float focal = getFocal(halfOmega, radiusOfOmega, u_kFactor.x);

	// Initialize theta values for cropping radius points
	static const float2 theta = atan(tan(halfOmega) / radiusOfOmega * viewProportions);
	// Get cropping radius points...
	static const float croppingHorizontal = getRadius(theta.x, focal, u_kFactor.x) / viewProportions.x;
	// ...for vertical axis
	static float2 croppingVertical;
	croppingVertical.s = getRadius(theta.y, focal, u_kFactor.y);
	// Bypass calculation, if K top and bottom are the same
	[branch]
	if (u_kFactor.y == u_kFactor.z) croppingVertical.t = croppingVertical.s;
	else croppingVertical.t = getRadius(theta.y, focal, u_kFactor.z);
	croppingVertical /= viewProportions.y;
	// ...for diagonal axis
	static float2 croppingDigonal;
	[branch]
	if (all(u_kFactor.x == u_kFactor.yz)) // get fisheye diagonal radius point
		croppingDigonal = getRadius(atan(tan(halfOmega) / radiusOfOmega), focal, u_kFactor.x);
	else // search for aximorphic diagonal radius point
		croppingDigonal = binarySearchCorner(halfOmega, radiusOfOmega, focal);

	// Get cropping type points
	static const float circularFishEye = max(max(croppingHorizontal, croppingVertical.s), croppingVertical.t);
	static const float croppedCircle   = min(min(croppingHorizontal, croppingVertical.s), croppingVertical.t);
	static const float fullFrame = min(croppingDigonal.s, croppingDigonal.t);

	// Get radius scaling for bounds alignment
	static float croppingScalar;
	[branch]
	if (u_croppingFactor < 0.5) // circular fish-eye <--> cropped circle
		croppingScalar = lerp(
			circularFishEye, // circular fish-eye
			croppedCircle, // cropped circle
			saturate(u_croppingFactor * 2.f) // [0, 0.5] range
		);
	else croppingScalar = lerp( // cropped circle <--> full-frame
		croppedCircle, // cropped circle
		fullFrame, // full-frame
		saturate(mad(u_croppingFactor, 2.f, -1.f)) // [0.5, 1] range
	);

	// Scale view coordinates to cropping bounds
	viewCoord *= croppingScalar;
}

// Main perspective shader pass
[shader("pixel")]
float3 p_perfectPerspective(
	float4 pixelPos : SV_Position,
	float2 texCoord : TEXCOORD0,
	float2 viewCoord : TEXCOORD1) : SV_Target
{
// BEGIN DISTORTION MAPPING BYPASS _____________________________________________

	// Check if it's valid to apply distortion mapping or vignetting
	#if __RENDERER__ > 0x9000 // fix DirectX9 error
	[branch]
	#endif
	if (u_fovAngle == 0u || (all(u_kFactor == -1.f) && u_vignetteIntensity == 0.f))
	{
		// Initialize RGB color output
		float3 display;

		#if __RENDERER__ > 0x9000 // fix DirectX9 error
		[branch]
		#endif
		if (u_calibrationModeView) // draw calibration grid
		{
			display = GridModeViewPass(uint2(pixelPos.xy), texCoord);
			display = LinearWorkflow::toDisplayGamma(display); // output gamma manually
			display = BlueNoise::dither(display, pixelPos.xy); // dither final gradients
		}
		else // just sample the background
		#if PP_MIPMAPPING_LEVEL
		{
			// Fetch pixels of mip-texture, with no sampling
			display = tex2Dfetch(s_backBuffer, uint2(pixelPos.xy)).rgb;
			display = LinearWorkflow::toDisplayGamma(display);  // output gamma manually
		}
		#else // no gamma linearization
			// Fetch pixels of back-buffer texture, with no sampling
			display = tex2Dfetch(s_backBuffer, uint2(pixelPos.xy)).rgb;
		#endif

		return display; // bypassing rest of the code
	}

// END OF DISTORTION MAPPING BYPASS ____________________________________________

// BEGIN OF PERSPECTIVE MAPPING ________________________________________________

	// Aspect ratio transformation vector
	static const float2 viewProportions = normalize(BUFFER_SCREEN_SIZE);
	// Half field of view angle in radians
	static const float halfOmega = radians(u_fovAngle * 0.5);
	// Get radius at Omega for a given FOV type
	static const float radiusOfOmega = getRadiusOfOmega(viewProportions, u_fovType);
	// Reciprocal focal length
	static const float focal = getFocal(halfOmega, radiusOfOmega, u_kFactor.x);

	// Image radius
	float radius = length(viewCoord);

	// Aximorphic interpolation weights
	float2 phiMtx = getPhiLerp(viewCoord);

	// Get aximorphic incident Theta angle
	float theta = dot(phiMtx, float2(
		getTheta(radius, focal, u_kFactor.x), // horizontal incident angle
		getTheta(radius, focal, viewCoord.y >= 0.f ? u_kFactor.z : u_kFactor.y)) // vertical incident angle
	);

	// Vignetting falloff gradient
	float vignette;
	[branch]
	if (u_vignetteIntensity == 0.f) // no vignetting
		vignette = 1.f;
	else // calculate vignetting falloff
	{
		vignette = getVignette(theta, radius, focal);
		// Adjust vignette intensity with power function
		float vignetteIntensity = clamp(u_vignetteIntensity, -4.f, 4.f); // limit to valid values
		vignette = exp(log(vignette) * vignetteIntensity); // same as pow(vignette, u_vignetteIntensity)

		// Normalize vignette brightness to a point at radius
		static const float vignetteOffset = u_vignetteOffset == 0.f ? // bypass offset
			0.f : // no offset
			1.f - exp(log( // get difference to 1 (no vignette)
				getVignette( // get vignette at a radius point
					getTheta(u_vignetteOffset, focal, u_kFactor.x), // theta angle at radius point
					u_vignetteOffset, // radius point
					focal) // focal length
				) * vignetteIntensity); // same as `pow(vignette, vignetteIntensity)`
		// Apply vignette normalization at the radius point
		vignette += vignetteOffset;
	}

	// Rectilinear perspective transformation
	viewCoord = tan(theta) * normalize(viewCoord);

	// Back to normalized, centered coordinates
	static const float2 toUvCoord = radiusOfOmega / (tan(halfOmega) * viewProportions);
	viewCoord *= toUvCoord;

// END OF PERSPECTIVE MAPPING __________________________________________________

	// Back to UV Coordinates
	texCoord = mad(viewCoord, 0.5, 0.5);

	// Sample display image
	float3 display;
	#if __RENDERER__ > 0x9000 // fix DirectX9 error
	[branch]
	#endif
	if (u_calibrationModeView) // display calibration grid
		display = GridModeViewPass(uint2(pixelPos.xy), texCoord);
	else
	{
		display = all(u_kFactor == -1.f) ? // bypass projection mapping
			tex2Dfetch(s_backBuffer, uint2(pixelPos.xy)).rgb : // no perspective change
			tex2Dgrad(s_backBuffer, texCoord, ddx(texCoord), ddy(texCoord)).rgb; // perspective projection lookup with mip-mapping and anisotropic filtering
		#if !PP_MIPMAPPING_LEVEL
		display = LinearWorkflow::toLinearGamma(display); // manual gamma linearization
		#endif
	}

	// Display border
	#if __RENDERER__ > 0x9000 // fix DirectX9 error
	[branch]
	#endif
	if (any(u_kFactor != -1.f) && u_croppingFactor < 1.f) // visible borders
	{
		// Get border image
		float3 border = lerp(
			// Sample distorted or undistorted picture at the border
			#if PP_MIPMAPPING_LEVEL
			u_borderMirror ? display : tex2Dfetch(s_backBuffer, uint2(pixelPos.xy)).rgb, // border background
			#else // manual gamma linearization
			u_borderMirror ? display : LinearWorkflow::toLinearGamma(tex2Dfetch(s_backBuffer, uint2(pixelPos.xy)).rgb), // border background
			#endif
			// Linear workflow
			LinearWorkflow::toLinearGamma(u_borderColor.rgb), // border color
			LinearWorkflow::toLinearGamma(u_borderColor.a)    // border alpha
		);

		// Outside border mask with anti-aliasing
		float borderMask = GetBorderMask(viewCoord);
		// Apply vignette with border
		display = u_borderMirror ?
			vignette * lerp(display, border, borderMask) :  // vignette on border
			lerp(vignette * display, border, borderMask); // vignette only inside
	}
	else [branch] if (u_vignetteIntensity != 0.f) // apply vignette
		display *= vignette;

	// Manually correct gamma
	display = LinearWorkflow::toDisplayGamma(display);

	// Dither final 8/10-bit result in SDR
	#if BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_UNKNOWN || BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_SRGB
	return BlueNoise::dither(display, uint2(pixelPos.xy));
	#else // don't dither in HDR modes, it shouldn't be necessary due to the higher quality of input, and the display
	return display;
	#endif
}

/* >> Output << */

technique PerfectPerspectiveDual
<
	ui_label = "LENS: Dual Distortion";
	ui_tooltip =
		"GET BI-FUNCTIONAL, DUAL DISTORTION LENS\n"
		"\n"
		" __________               _______________\n"
		" \\______   \\ ____________/ ____\\______   \\ ___________  ____________\n"
		"  |     ___// __ \\_  __ \\   __\\ |     ___// __ \\_  __ \\/  ___/\\____ \\\n"
		"  |    |   \\  ___/|  | \\/|  |   |    |   \\  ___/|  | \\/\\___ \\ |  |_> >\n"
		"  |____|    \\___  >__|   |__|   |____|    \\___  >__|  /____  >|   __/\n"
		"                \\/                            \\/           \\/ |__|\n"
		"Instructions:\n"
		"\n"
		"	1. Select proper FOV angle/type matching game/settings.\n"
		"	   If a type of FOV is a mystery:\n"
		"\n"
		"	 * Find perfectly round object in the game and look at it.\n"
		"	 * Rotate to see the object in screen corner.\n"
		"	 * Set all k = -0.5 for analysis.\n"
		"	 * Toggle 'FOV type' until the object is not an egg-shaped,\n"
		"	   but perfectly round circle.\n"
		"\n"
		"	2. Adjust 'k' distortion profile for your game-play liking.\n"
		"\n"
		"	3. Minimize visible borders with 'cropping':\n"
		"	   1 - no borders, 0.5 - compromise, 0 - no cropping.\n"
		"\n"
		"	 + use '4lex4nder/ReshadeEffectShaderToggler' add-on for the UI.\n"
		"	 + use sharpening, or run game at Super-Resolution.\n"
		"	 + for more adjustments set preprocessor def. 'PP_MORE_COSMETICS 1'.\n"
		"\n"
		"\n"
		"The algorithm is part of a scientific article:\n"
		"	arXiv:2003.10558 [cs.GR] (2020)\n"
		"	arXiv:2010.04077 [cs.GR] (2020)\n"
		"	arXiv:2102.12682 [cs.GR] (2021)\n"
		"\n"
		"© 2018-2026 Jakub Maksymilian Fober\n"
		"Licensed under the Open Community License v1.1 + Software Attribution v1\n"
		"(OCL v1.1 + SWAtt v1) | please respect the license.";
>
{
	#if PP_MIPMAPPING_LEVEL
	pass CreateMipMaps
	{
		VertexShader = v_backBufferMipGen;
		PixelShader  = p_backBufferMipGen;
		RenderTarget = t_backBufferMipTarget;
	}
	#endif
	pass PerspectiveDistortion
	{
		VertexShader = v_perfectPerspective;
		PixelShader  = p_perfectPerspective;
	}
}
