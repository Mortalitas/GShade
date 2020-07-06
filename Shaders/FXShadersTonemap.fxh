#pragma once

namespace FXShaders
{

/**
 * Standard Reinhard tonemapping formula.
 *
 * @param color The color to apply tonemapping to.
 */
float3 Reinhard(float3 color)
{
	return color / (1.0 + color);
}

/**
 * Inverse of the standard Reinhard tonemapping formula.
 *
 * @param color The color to apply inverse tonemapping to.
 * @param inv_max The inverse/reciprocal of the maximum brightness to be
 *                generated.
 *                Sample parameter: rcp(100.0)
 */
float3 ReinhardInv(float3 color, float inv_max)
{
	return (color / max(1.0 - color, inv_max));
}

/**
 * Modified inverse of the Reinhard tonemapping formula that only applies to
 * the luma.
 *
 * @param color The color to apply inverse tonemapping to.
 * @param inv_max The inverse/reciprocal of the maximum brightness to be
 *                generated.
 *                Sample parameter: rcp(100.0)
 */
float3 ReinhardInvLum(float3 color, float inv_max)
{
	float lum = max(color.r, max(color.g, color.b));
	return color * (lum / max(1.0 - lum, inv_max));
}

/**
 * The standard, copy/paste Uncharted 2 filmic tonemapping formula.
 *
 * @param color The color to apply tonemapping to.
 * @param exposure The amount of exposure to be applied to the color during
 *                 tonemapping.
 */
float3 Uncharted2Tonemap(float3 color) {
    // Shoulder strength.
	static const float A = 0.15;

	// Linear strength.
    static const float B = 0.50;

	// Linear angle.
	static const float C = 0.10;

	// Toe strength.
	static const float D = 0.20;

	// Toe numerator.
	static const float E = 0.02;

	// Toe denominator.
	static const float F = 0.30;

	// Linear white point value.
	static const float W = 11.2;

    static const float White =
		1.0 / ((
			(W * (A * W + C * B) + D * E) /
			(W * (A * W + B) + D * F)
		) - E / F);

    color = (
		(color * (A * color + C * B) + D * E) /
		(color * (A * color + B) + D * F)
	) - E / F;

	return color * White;
}

namespace BakingLabACES
{
	// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
	static const float3x3 ACESInputMat = float3x3
	(
		0.59719, 0.35458, 0.04823,
		0.07600, 0.90834, 0.01566,
		0.02840, 0.13383, 0.83777
	);

	// ODT_SAT => XYZ => D60_2_D65 => sRGB
	static const float3x3 ACESOutputMat = float3x3
	(
		1.60475, -0.53108, -0.07367,
		-0.10208,  1.10813, -0.00605,
		-0.00327, -0.07276,  1.07602
	);

	float3 RRTAndODTFit(float3 v)
	{
		return (v * (v + 0.0245786f) - 0.000090537f) / (v * (0.983729f * v + 0.4329510f) + 0.238081f);
	}

	float3 ACESFitted(float3 color)
	{
		color = mul(ACESInputMat, color);

		// Apply RRT and ODT
		color = RRTAndODTFit(color);

		color = mul(ACESOutputMat, color);

		// Clamp to [0, 1]
		color = saturate(color);

		return color;
	}
}

float3 BakingLabACESTonemap(float3 color)
{
	return BakingLabACES::ACESFitted(color);
}

} // Namespace.
