#pragma once

#include "FXShadersMath.fxh"

namespace FXShaders
{

/**
 * Standard normal distribution formula.
 * Adapted from: https://en.wikipedia.org/wiki/Normal_distribution#General_normal_distribution
 *
 * @param x The value to distribute.
 * @param u The distribution mean.
 * @param o The distribution sigma.
 *          This value is squared in this function, so there's no need to square
 *          it beforehand, unlike the standard formula.
 */
float NormalDistribution(float x, float u, float o)
{
	o *= o;

	const float b = ((x - u) * (x - u)) / 2.0 * o;

	return (1.0 / sqrt(2.0 * Pi * o)) * exp(-(b));
}

/**
 * One dimensional gaussian distribution formula.
 *
 * @param x The value to distribute.
 * @param o The distribution sigma.
 *          This parameter is squared in this function, so there's no need to
 *          square it beforehand.
 */
float Gaussian1D(float x, float o)
{
	o *= o;
	const float b = (x * x) / (2.0 * o);
	return  (1.0 / sqrt(2.0 * Pi * o)) * exp(-b);
}

/**
 * One dimensional alternative gaussian distribution formula with less
 * instructions.
 *
 * @param x The value to distribute.
 * @param o The distribution sigma.
 *          This parameter is squared in this function, so there's no need to
 *          square it beforehand.
 */
float Gaussian1DFast(float x, float o)
{
	// NOTE: It does not seem to actually make the code noticeably faster.

	return exp(-(x * x) / (2.0 * o * o));
}

/**
 * Two dimensional gaussian distribution formula.
 *
 * @param i The x and y values to distribute.
 * @param o The distribution sigma.
 *          This parameter is squared in this function, so there's no need to
 *          square it beforehand.
 */
float Gaussian2D(float2 i, float o)
{
	o *= o;
	const float b = (i.x * i.x + i.y * i.y) / (2.0 * o);
	return (1.0 / (2.0 * Pi * o)) * exp(-b);
}

/**
 * One dimensional gaussian blur.
 *
 * @param sp The sampler to read from.
 * @param uv The normalized screen coordinates used for reading from the
 *           sampler.
 * @param dir The 2D direction and scale of the blur.
 *            Remember to pass the pixel/texel size here.
 * @param sigma The sigma value used for the gaussian distribution.
 *              This does not need to be squared.
 * @param samples The amount of blur samples to perform.
 *                This value must be constant.
 */
float4 GaussianBlur1D(
	sampler sp,
	float2 uv,
	float2 dir,
	float sigma,
	int samples)
{
	static const float half_samples = samples * 0.5;

	float4 color = 0.0;
	float accum = 0.0;

	uv -= half_samples * dir;

	[unroll]
	for (int i = 0; i < samples; ++i)
	{
		float weight = Gaussian1DFast(i - half_samples, sigma);

		color += tex2D(sp, uv) * weight;
		accum += weight;

		uv += dir;
	}

	return color / accum;
}

/**
 * Two dimensional gaussian blur.
 *
 * @param sp The sampler to read from.
 * @param uv The normalized screen coordinates used for reading from the
 *           sampler.
 * @param scale The scale of the blur.
 *              Remember to pass the pixel/texel size here.
 * @param sigma The sigma value used for the gaussian distribution.
 *              This does not need to be squared.
 * @param samples The amount of blur samples to perform.
 *                This value must be constant.
 */
float4 GaussianBlur2D(
	sampler sp,
	float2 uv,
	float2 scale,
	float sigma,
	int2 samples)
{
	static const float2 half_samples = samples * 0.5;

	float4 color = 0.0;
	float accum = 0.0;

	uv -= half_samples * scale;

	[unroll]
	for (int x = 0; x < samples.x; ++x)
	{
		float init_x = uv.x;

		[unroll]
		for (int y = 0; y < samples.y; ++y)
		{
			float2 pos = float2(x, y);
			float weight = Gaussian2D(abs(pos - half_samples), sigma);

			color += tex2D(sp, uv) * weight;
			accum += weight;

			uv.x += scale.x;
		}

		uv.x = init_x;
		uv.y += scale.y;
	}

	return color / accum;
}

}
