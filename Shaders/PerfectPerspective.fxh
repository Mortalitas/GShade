/* Perfect Perspective Function Library (version 6.0.0)
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
Visit GitHub repository at https://github.com/Fubaxiusz/fubax-shaders

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

#pragma once

/* >> Commons << */

// ReShade specific
#include "ReShade.fxh"
// Color management cross-FX functions
#include "LinearWorkflow.fxh"

/* >> Macros << */

/* High quality sampling.
   0 disables mipmapping.
   1 gives level 2 mipmap.
   ...
   4 maximum mipmapping lvl, equivalent of x16 anisotropic filtering. */
#ifndef PP_MIPMAPPING_LEVEL
	#define PP_MIPMAPPING_LEVEL 0
#endif

// Get reciprocal screen aspect ratio (1/x)
#define BUFFER_RCP_ASPECT_RATIO (BUFFER_HEIGHT * BUFFER_RCP_WIDTH)

/* >> Functions << */

/* Azimuthal spherical perspective projection equations
© 2022 Jakub Maksymilian Fober
These algorithms are part of the following scientific papers:
· arXiv:2003.10558 [cs.GR] (2020)
· arXiv:2010.04077 [cs.GR] (2020)
*/
float getRadius( // get image radius
	float theta, // visual sphere theta angle
	float focal, // focal length
	float kFactor) // projection distortion parameter
{
	[branch]
	if (kFactor < 0.f) // rectilinear, stereographic projections
		return tan(abs(kFactor) * theta) * focal / abs(kFactor);
	else [branch] if (kFactor > 0.f) // equisolid, orthographic projections
		return sin(abs(kFactor) * theta) * focal / abs(kFactor);
	else // equidistant projection
		return theta * focal;
}

float getTheta( // get spherical Theta angle
	float radius, // projection space image radius
	float focal, // focal length
	float kFactor) // projection distortion parameter
{
	[branch]
	if (kFactor < 0.f) // rectilinear, stereographic projections
		return atan(abs(kFactor) * radius / focal) / abs(kFactor);
	else [branch] if (kFactor > 0.f) // equisolid, orthographic projections
		return asin(abs(kFactor) * radius / focal) / abs(kFactor);
	else // equidistant projection
		return radius / focal;
}

float getFocal( // get focal length
	float halfOmega, // half field of view value in radians
	float radiusAtOmega, // radius value at the FOV (horizontal, vertical, diagonal)
	float kFactor) // projection distortion parameter
{
	[branch]
	if (kFactor < 0.f) // rectilinear, stereographic projections
		return abs(kFactor) / (tan(abs(kFactor) * halfOmega) * radiusAtOmega);
	else [branch] if (kFactor > 0.f) // equisolid, orthographic projections
		return abs(kFactor) / (sin(abs(kFactor) * halfOmega) * radiusAtOmega);
	else // equidistant projection
		return 1.f / (halfOmega * radiusAtOmega);
}

float getVignette( // get vignetting mask in linear color space
	float theta, // visual sphere theta angle
	float radius, // projection space image radius
	float focal) // focal length
{
	float vignette = sin(theta) * focal / radius;
	return isnan(vignette) ? 1.f : vignette; // here `0 / 0 = 1`
}

/* Table of anamorphic squeeze values
Value | Lens Type
------+--------------------
  1   | spherical lens
 1.25 | Ultra Panavision 70
 1.33 | 16x9 TV
 1.5  | Technirama
 1.6  | digital anamorphic
 1.8  | 4x3 full-frame
  2   | golden-standard
*/
float getAnamorphicRadius( // get anamorphic projection radius value
	float2 viewCoord, // centered coordinates with correct aspect
	float squeezeFactor) // anamorphic image squeeze factor 1.xx
{
	// Apply image squeeze factor
	viewCoord.y /= squeezeFactor;
	return length(viewCoord); // calculate radius
}

float2 getPhiLerp(float2 viewCoord) // get aximorphic interpolation weights
{
	[flatten]
	if (all(viewCoord == 0.f)) // fix issues at the center
		return float2(0.5, 0.5);
	else
	{
		viewCoord *= viewCoord; // squared vector coordinates
		return viewCoord / (viewCoord.x + viewCoord.y); // [cos²Phi sin²Phi] vector
	}
}

// Get radius at Omega for a given FOV type
float getRadiusOfOmega(
	float2 viewProportions, // normalized buffer-size vector
	uint fovType) // FOV-type input
{
	// This returns a valid value for a coordinates normalized to the screen corner
	[branch]
	switch (fovType) // uniform index input
	{
		default: // horizontal FOV type (0)
			return viewProportions.x;
		case 1u: // diagonal FOV type (1)
			return 1.f;
		case 2u: // vertical FOV type (2)
			return viewProportions.y;
		case 3u: // 4x3 FOV type (3)
			return viewProportions.y * 4.f / 3.f;
		case 4u: // 16x9 FOV type (4)
			return viewProportions.y * 16.f / 9.f;
	}
}

/* Linear pixel step function for anti-aliasing by Jakub Max Fober.
   This algorithm is part of scientific paper:
   · arXiv:2010.04077 [cs.GR] (2020) */
float aastep(float gradient)
{
	// Differential vector
	float2 Del = float2(ddx(gradient), ddy(gradient));
	// Gradient normalization to pixel size, centered at the step edge
	return saturate(mad(rsqrt(dot(Del, Del)), gradient, 0.5)); // half-pixel offset
}

/* G continuity distance function by Jakub Max Fober.
   Represents derivative level continuity. (G from 0, to 3)
   Continuity | Corner
   -----------+----------
           G0 | sharp
           G1 | round
           G2 | smooth
           G3 | luxurious */
float glength(uint continuityG, float2 position)
{
	// Sharp corner
	[branch]
	if (continuityG == 0u) // G0 sharp corner
		return max(abs(position.x), abs(position.y));
	else // higher-power length function
	{
		position = exp(log(abs(position)) * ++continuityG); // position to the power of G+1
		return exp(log(position.x + position.y) / continuityG); // position dot-product to the root-power of G+1
	}
}

/* >> Textures << */

#if PP_MIPMAPPING_LEVEL
// Buffer texture target with mipmapping
texture2D t_backBufferMipTarget
< pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
	// Storing linear gamma picture in higher bit depth
	#if (BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_UNKNOWN) || (BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_SRGB)
	Format = RGB10A2;
	#else // BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_SCRGB // Fall back on a higher quality in any other case, for future compatibility
	Format = RGBA16F;
	#endif
	// Maximum MIP map level
	#if PP_MIPMAPPING_LEVEL>0 && PP_MIPMAPPING_LEVEL <= 4
	MipLevels = PP_MIPMAPPING_LEVEL + 1;
	#else
	MipLevels = 5; // maximum MIP level
	#endif
};
#endif

// Define screen texture with mirror tiles and anisotropic filtering
sampler2D s_backBuffer
{
	#if PP_MIPMAPPING_LEVEL
	Texture = t_backBufferMipTarget; // back buffer texture target with additional MIP levels
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

/* >> Shaders << */

#if PP_MIPMAPPING_LEVEL
// Vertex shader for mipmapping back-buffer write
[shader("vertex")]
void v_backBufferMipGen(
	in uint vertexId : SV_VertexID,
	noperspective out float4 position : SV_Position) // no texture mapping
{
	// Generate vertex position for triangle ABC covering whole screen
	position.x = (vertexId == 2u) ?  3.f : -1.f;
	position.y = (vertexId == 1u) ? -3.f :  1.f;

	// Initialize other values
	position.z = 0.f; // not used
	position.w = 1.f; // not used
}

// Pixel shader for linear-gamma mipmapping back-buffer write
[shader("pixel")]
void p_backBufferMipGen(
	noperspective in float4 pixelPos : SV_Position,
	out float4 display : SV_Target)
{
	// Generating MIP maps in linear gamma color space
	display.rgb = LinearWorkflow::toLinearGamma(
		tex2Dfetch(
			ReShade::BackBuffer, // standard back-buffer
			uint2(pixelPos.xy)   // pixel position without resampling
		).rgb
	);
	display.a = 1.f; // ignore transparency alpha
}
#endif
