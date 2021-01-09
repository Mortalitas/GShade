#pragma once

#include "FXShadersAspectRatio.fxh"

namespace FXShaders { namespace Transform
{

float2 FisheyeLens(
	int aspectRatioScaleType,
	float2 uv,
	float amount,
	float zoom)
{
	uv = uv * 2.0 - 1.0;

	const float2 fishUv = uv * AspectRatio::ApplyScale(aspectRatioScaleType, uv);

	uv = ((uv * lerp(1.0, sqrt(1.0 - fishUv.x * fishUv.x - fishUv.y * fishUv.y) * zoom, amount)) + 1.0) * 0.5;

	return uv;
}

}
}
