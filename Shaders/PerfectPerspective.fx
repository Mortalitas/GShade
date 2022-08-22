/** Perfect Perspective PS, version 4.2.0

This code © 2022 Jakub Maksymilian Fober

This work is licensed under the Creative Commons
Attribution-NonCommercial-NoDerivs 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-nc-nd/3.0/.

Copyright owner further grants permission for commercial reuse of
image recordings derived from the Work (e.g. let's play video,
gameplay stream with ReShade filters, screenshots with ReShade
filters) provided that any use is accompanied by the name of the
shader used and a link to ReShade website https://reshade.me

For updates visit GitHub repository at
https://github.com/Fubaxiusz/fubax-shaders

If you want to use this shader code in your commercial game/project,
contact me at
jakub.m.fober@protonmail.com

This shader version is based upon research papers
by Fober, J. M.
	Perspective picture from Visual Sphere:
	a new approach to image rasterization
	arXiv: 2003.10558 [cs.GR] (2020)
	https://arxiv.org/abs/2003.10558
and
	Temporally-smooth Antialiasing and Lens Distortion
	with Rasterization Map
	arXiv: 2010.04077 [cs.GR] (2020)
	https://arxiv.org/abs/2010.04077
*/

	/* MACROS */

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

uniform uint FOV <
	ui_type = "slider";
	ui_category = "Game";
	ui_text = "(Match game settings)";
	ui_label = "field of view (FOV)";
	ui_tooltip = "This setting should match your in-game FOV value.";
	#if __RESHADE__ < 40000
		ui_step = 0.2;
	#endif
	ui_max = 170u;
> = 90u;

uniform uint FovType <
	ui_type = "combo";
	ui_category = "Game";
	ui_label = "field of view type";
	ui_tooltip =
		"This setting should match game-specific FOV type.\n"
		"\n"
		"Adjust so that round objects are still round when at the corner, and not oblong.\n"
		"Tilt head to see better.\n"
		"\n"
		"Tip:\n"
		"\n"
		"	If image bulges in movement, change it to 'diagonal'.\n"
		"	When proportions are distorted at the periphery, choose 'vertical' or '4:3'.\n"
		"	For ultra-wide display you may want '16:9' instead.\n"
		"\n"
		"* This method only works with k = 0.5 and s = 1.0";
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
	ui_label = "'k' projection coefficient";
	ui_tooltip =
		"Value of 'k' represents projection type:\n"
		"\n"
		"k value  projection        perception of \n"
		"   1 .... Rectilinear ..... straight path \n"
		" 0.5 .... Stereographic ... shape         \n"
		"   0 .... Equidistant ..... distance      \n"
		"-0.5 .... Equisolid ....... depth         \n"
		"  -1 .... Orthographic .... illumination  \n"
		"\n"
		"* [Ctrl+click] to type value";
	ui_min = -1f; ui_max = 1f; ui_step = 0.05;
> = 0.5;

uniform float S <
	ui_type = "slider";
	ui_category = "Distortion";
	ui_label = "'s' anamorphic factor";
	ui_tooltip =
		"Anamorphic squeeze factor:\n"
		"\n"
		"   1x .... spherical lens\n"
		"1.25x .... Ultra Panavision 70\n"
		"1.33x .... 16x9 TV\n"
		" 1.5x .... Technirama\n"
		" 1.6x .... digital anamorphic\n"
		" 1.8x .... 4x3 full-frame\n"
		"   2x .... golden-standard\n";
	ui_min = 1f; ui_max = 4f; ui_step = 0.05;
> = 1f;

uniform bool UseVignette <
	ui_type = "input";
	ui_category = "Distortion";
	ui_label = "apply vignette";
	ui_tooltip = "Apply lens-correct natural vignetting effect.";
> = true;

// BORDER

uniform float CroppingFactor <
	ui_type = "slider";
	ui_category = "Border settings";
	ui_category_closed = true;
	ui_label = "zooming";
	ui_tooltip =
		"Adjusts image scale and cropped area size:\n"
		"\n"
		"  0 .... circular\n"
		"0.5 .... cropped-circle\n"
		"  1 .... full-frame";
	ui_min = 0f; ui_max = 1f;
> = 0.5;

uniform bool MirrorBorder <
	ui_type = "input";
	ui_category = "Border settings";
	ui_label = "border mirror";
	ui_tooltip = "Choose mirrored or original image on the border.";
> = true;

uniform bool BorderVignette <
	ui_type = "input";
	ui_category = "Border settings";
	ui_label = "border vignette";
	ui_tooltip = "Apply vignetting effect to border.";
> = false;

uniform float4 BorderColor <
	ui_type = "color";
	ui_category = "Border settings";
	ui_label = "border color";
	ui_tooltip = "Use alpha to change border transparency.";
> = float4(0.027, 0.027, 0.027, 0.96);

uniform float BorderCorner <
	ui_type = "slider";
	ui_category = "Border settings";
	ui_label = "corner size";
	ui_tooltip = "Value of 0.0 gives sharp corners.";
	ui_min = 0f; ui_max = 1f;
> = 0.062;

uniform uint BorderGContinuity <
	ui_type = "slider";
	ui_category = "Border settings";
	ui_label = "corner roundness";
	ui_tooltip =
		"G-surfacing continuity level for the corners:\n"
		"\n"
		"G0 .... sharp\n"
		"G1 .... circular\n"
		"G2 .... smooth\n"
		"G3 .... very smooth";
	ui_min = 1u; ui_max = 3u;
> = 3u;

// DEBUG OPTIONS

uniform bool DebugPreview <
	ui_type = "input";
	ui_text = "Get optimal value for super-resolution.";
	ui_category = "Debugging tools";
	ui_category_closed = true;
	ui_label = "Debug mode";
	ui_tooltip =
		"Display color map of the resolution scale:\n"
		"\n"
		"  red .... under-sampling\n"
		"green .... oversampling\n"
		" blue .... 1:1";
> = false;

uniform uint ResScaleScreen <
	ui_type = "input";
	ui_category = "Debugging tools";
	ui_label = "screen (native) resolution";
	ui_tooltip = "Set it to default screen resolution";
> = 1920u;

uniform uint ResScaleVirtual <
	ui_type = "drag";
	ui_category = "Debugging tools";
	ui_label = "virtual resolution";
	ui_tooltip =
		"Simulates application running beyond native\n"
		"screen resolution (using VSR or DSR)";
	ui_step = 0.2;
	ui_min = 16u; ui_max = 16384u;
> = 1920u;


	/* TEXTURES */

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;

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
	· arXiv: 20104077 [cs.GR] (2020)
*/
float aastep(float grad)
{
	// Differential vector
	float2 Del = float2(ddx(grad), ddy(grad));
	// Gradient normalization to pixel size, centered at the step edge
	return saturate(rsqrt(dot(Del, Del))*grad+0.5); // half-pixel offset
}


/** Azimuthal spherical perspective projection equations © 2022 Jakub Maksymilian Fober
	These algorithms are part of the following scientific papers:
	· arXiv:2003.10558 [cs.GR] (2020)
	· arXiv:2010.04077 [cs.GR] (2020)
*/
float get_r(float theta, float hlfOmega, float k) // Get image radius
{
	if (k>0f) // Stereographic, rectilinear projections
		return tan(theta*k)/tan(hlfOmega*k);
	else if (k<0f) // Equisolid, orthographic projections
		return sin(theta*k)/sin(hlfOmega*k);
	else // if (k==0f) // Equidistant projection
		return theta/hlfOmega;
}
float get_theta(float r, float hlfOmega, float k) // Get spherical θ angle
{
	if (k>0f) // Stereographic, rectilinear projections
		return atan(tan(hlfOmega*k)*r)/k;
	else if (k<0f) // Equisolid, orthographic projections
		return asin(sin(hlfOmega*k)*r)/k;
	else // if (k==0f) // Equidistant projection
		return r*hlfOmega;
}
float get_vignette(float theta, float k) // Get vignetting mask in linear color space
{
	// Create spherical vignette
	// |cos(max(|k|,½)θ)|^(3k/4)
	float spherical_vignette = cos(max(abs(k), 0.5)*theta); // Limit FOV span, |k| ∈ [0.5, 1] range
	// Mix cosine-law of illumination and inverse-square law
	return pow(abs(spherical_vignette), k*0.5+1.5);
}

/** Universal perspective model © 2022 Jakub Maksymilian Fober
	Gnomonic to custom perspective variant.
*/
float UniversalPerspective_vignette(inout float2 viewCoord) // Returns vignette
{
	// Get half field of view
	const float hlfOmega = radians(FOV*0.5);

	// Get radius
	float R = S==1f ?
			dot(viewCoord, viewCoord) : // Spherical
			(viewCoord.x*viewCoord.x)+(viewCoord.y*viewCoord.y)/S // Anamorphic
		;
	float rcpR = rsqrt(R); R = sqrt(R);

	// Get incident angle
	float theta = get_theta(R, hlfOmega, K);

	// Generate vignette
	bool vignetteIsVisible = UseVignette && !DebugPreview;
	float vignetteMask = vignetteIsVisible ? get_vignette(theta, K) : 1f;
	// Anamorphic vignette correction
	if (vignetteIsVisible && S!=1f)
	{
		// Get anamorphic-incident 3D vector
		float3 perspVec = float3((sin(theta)*rcpR)*viewCoord, cos(theta));
		vignetteMask /= dot(perspVec, perspVec); // Inverse square law
	}

	// Radius for gnomonic projection wrapping
	const float rcpTanHlfOmega = rcp(tan(hlfOmega));
	// Transform screen coordinates and normalize to FOV
	viewCoord *= tan(theta)*rcpR*rcpTanHlfOmega;

	// Return vignette
	return vignetteMask;
}

// Inverse transformation of universal perspective algorithm
float UniversalPerspective_inverse(float2 viewCoord) // Returns reciprocal radius
{
	// Get half field of view
	const float hlfOmega = radians(FOV*0.5);
	// Get reciprocal radius
	const float rcp_r = S==1f ?
			rsqrt(dot(viewCoord, viewCoord)) :
			rsqrt((viewCoord.y*viewCoord.y)/S+(viewCoord.x*viewCoord.x))
		;

	// Get incident vector
	float3 incident;
	incident.xy = viewCoord;
	incident.z = rcp(tan(hlfOmega));

	// Get theta angle
	float theta = (S==1f)?
		acos(normalize(incident).z) : // Spherical
		acos(incident.z*rsqrt((incident.y*incident.y)/S+dot(incident.xz, incident.xz))); // Anamorphic

	// Calculate transformed position reciprocal radius
	return rcp_r*get_r(theta, hlfOmega, K);
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
			borderCoord.x = borderCoord.x*BUFFER_ASPECT_RATIO+(1f-BUFFER_ASPECT_RATIO);
		else if (BUFFER_ASPECT_RATIO<1f) // If in portrait mode
			borderCoord.y = borderCoord.y*BUFFER_RCP_ASPECT_RATIO+(1f-BUFFER_RCP_ASPECT_RATIO);
		// Generate scaled coordinates
		borderCoord = max(borderCoord+(BorderCorner-1f), 0f)/BorderCorner;

		// Round corner
		return aastep(glength(BorderGContinuity, borderCoord)-1f); // ...with G1 to G3 continuity
	}
	else // Just sharp corner, G0
		return aastep(glength(0u, borderCoord)-1f);
}

// Debug view mode shader
void DebugModeViewPass(inout float3 display, float2 sphCoord)
{
	// Define Mapping color
	const float3   underSmpl = TO_LINEAR_GAMMA_HQ(float3(1f, 0f, 0.2)); // Red
	const float3   superSmpl = TO_LINEAR_GAMMA_HQ(float3(0f, 1f, 0.5)); // Green
	const float3 neutralSmpl = TO_LINEAR_GAMMA_HQ(float3(0f, 0.5, 1f)); // Blue

	// Calculate Pixel Size difference
	float pixelScaleMap;
	// and simulate Dynamic Super Resolution (DSR) scalar
	pixelScaleMap  = ResScaleScreen*BUFFER_PIXEL_SIZE.x*BUFFER_PIXEL_SIZE.y;
	pixelScaleMap /= ResScaleVirtual*ddx(sphCoord.x)*ddy(sphCoord.y);
	pixelScaleMap -= 1f;

	// Generate super-sampled/under-sampled color map
	float3 resMap = lerp(
		superSmpl,
		underSmpl,
		step(0f, pixelScaleMap)
	);

	// Create black-white gradient mask of scale-neutral pixels
	pixelScaleMap = saturate(1f-4f*abs(pixelScaleMap)); // Clamp to more representative values

	// Color neutral scale pixels
	resMap = lerp(resMap, neutralSmpl, pixelScaleMap);

	// Blend color map with display image
	display = (0.8*dot(LumaMtx, display)+0.2)*resMap;
}

// Main perspective shader pass
float3 PerfectPerspectivePS(float4 pixelPos : SV_Position, float2 sphCoord : TEXCOORD0) : SV_Target
{
	// Bypass
	if (FOV==0u || (K==1f && !UseVignette))
		return tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb;

#if SIDE_BY_SIDE_3D // Side-by-side 3D content
	float SBS3D = sphCoord.x*2f;
	sphCoord.x = frac(SBS3D);
	SBS3D = floor(SBS3D);
#endif

	// Convert UV to centered coordinates
	sphCoord = sphCoord*2f-1f;
	// Correct aspect ratio
	sphCoord.y *= BUFFER_RCP_ASPECT_RATIO;

	// Get FOV type scalar
	static float FovScalar;
	switch(FovType)
	{
		// Horizontal
		default: FovScalar = 1f; break;
		// Diagonal
		case 1: FovScalar = sqrt(BUFFER_RCP_ASPECT_RATIO*BUFFER_RCP_ASPECT_RATIO+1f); break;
		// Vertical
		case 2: FovScalar = BUFFER_RCP_ASPECT_RATIO; break;
		// Horizontal 4:3
		case 3: FovScalar = (4f/3f)*BUFFER_RCP_ASPECT_RATIO; break;
		// Horizontal 16:9
		case 4: FovScalar = (16f/9f)*BUFFER_RCP_ASPECT_RATIO; break;
	}

	// Adjust FOV type
	sphCoord /= FovScalar; // pass 1 of 2

	// Scale picture to cropping point
	{
		// Get cropping positions: vertical, horizontal, diagonal
		float2 normalizationPos[3u];
		// Mode 1
		normalizationPos[0u].x =     // Vertical crop
			normalizationPos[1u].y = // Horizontal crop
			0f;
		// Mode 2
		normalizationPos[2u].x =     // Diagonal crop
			normalizationPos[1u].x = // Horizontal crop
			rcp(FovScalar);
		// Mode 3
		normalizationPos[2u].y =     // Diagonal crop
			normalizationPos[0u].y = // Vertical crop
			normalizationPos[2u].x*BUFFER_RCP_ASPECT_RATIO;

		// Get cropping option scalar
		float crop = CroppingFactor*2f;
		// Interpolate between cropping states
		const float croppingScalar = lerp(
			UniversalPerspective_inverse(normalizationPos[uint(floor(crop))]),
			UniversalPerspective_inverse(normalizationPos[uint( ceil(crop))]),
			frac(crop) // Weight interpolation
		);

		// Apply cropping zoom
		sphCoord *= croppingScalar;
	}

	// Perspective transform and create vignette
	float vignetteMask = UniversalPerspective_vignette(sphCoord);

	// Adjust FOV type
	sphCoord *= FovScalar; // pass 2 of 2

	// Aspect Ratio back to square
	sphCoord.y *= BUFFER_ASPECT_RATIO;

	// Outside border mask with anti-aliasing
	float borderMask = GetBorderMask(sphCoord);

	// Back to UV Coordinates
	sphCoord = sphCoord*0.5+0.5;

#if SIDE_BY_SIDE_3D // Side-by-side 3D content
	sphCoord.x = (sphCoord.x+SBS3D)*0.5;
#endif

	// Sample display image
	float3 display = K==1f ?
		tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb : // No perspective change
		tex2D(BackBuffer, sphCoord).rgb; // Spherical perspective

#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
	// Manually correct gamma
	display = TO_LINEAR_GAMMA_HQ(display);
#endif

	if (K!=1f && CroppingFactor!=1f) // Visible borders
	{
		// Get border
		float3 border = lerp(
			// Border background
			MirrorBorder? display : tex2Dfetch(BackBuffer, uint2(pixelPos.xy)).rgb,
			// Border color
			TO_LINEAR_GAMMA_HQ(BorderColor.rgb),
			// Border alpha
			TO_LINEAR_GAMMA_HQ(BorderColor.a)
		);

		// Apply vignette with border
		display = BorderVignette?
			vignetteMask*lerp(display, border, borderMask) : // Vignette on border
			lerp(vignetteMask*display, border, borderMask);  // Vignette only inside
	}
	else display *= vignetteMask; // Apply vignette

	// Output type choice
	if (DebugPreview) DebugModeViewPass(display, sphCoord);

#if BUFFER_COLOR_SPACE <= 2 // Linear workflow
	// Manually correct gamma
	display = TO_DISPLAY_GAMMA_HQ(display);
	// Dither final 8-bit result
	return BlueNoise::dither(uint2(pixelPos.xy), display);
#else
	return display;
#endif
}


	/* OUTPUT */

technique PerfectPerspective <
	ui_label = "Perfect Perspective";
	ui_tooltip =
		"Adjust perspective for distortion-free picture:\n"
		"\n"
		"	· Fish-eye\n"
		"	· Panini\n"
		"	· Anamorphic\n"
		"	· Vignetting, natural\n"
		"\n"
		"Instruction:\n"
		"\n"
		"	1# select proper FOV angle and type. If FOV type is unknown,\n"
		"	   find a round object within the game and look at it upfront,\n"
		"	   then rotate the camera so that the object is in the corner.\n"
		"	   Change squeeze factor to 1x and adjust FOV type such that\n"
		"	   the object does not have an egg shape, but a perfect round shape.\n"
		"\n"
		"	2# adjust perspective type according to game-play style.\n"
		"	   If you look mostly at the horizon, anamorphic squeeze can be\n"
		"	   increased. For curved-display correction, set it higher.\n"
		"\n"
		"	3# adjust visible borders. You can change the zoom factor,\n"
		"	   such that no borders are visible, or that no image area is lost.\n"
		"\n"
		"	4# additionally for sharp image, use sharpening FX or run game at a\n"
		"	   Super-Resolution. Debug options can help you find the proper value.\n"
		"\n"
		"The algorithm is part of a scientific paper:\n"
		// "\n"
		"	arXiv: 2003.10558 [cs.GR] (2020)\n"
		"	arXiv: 2010.04077 [cs.GR] (2020)\n"
		"\n"
		"This effect © 2018 Jakub Maksymilian Fober";
>
{
	pass PerspectiveDistortion
	{
		VertexShader = PostProcessVS;
		PixelShader = PerfectPerspectivePS;
	}
}
