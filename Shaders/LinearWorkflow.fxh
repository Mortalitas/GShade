/* Linear Workflow Library (version 2.0.0)
.____    .__                              __________      __
|    |   |__| ____   ____ _____ _______  /  _____/  \    /  \
|    |   |  |/    \_/ __ \\__  \\_  __ \/   \  __\   \/\/   /
|    |___|  |   |  \  ___/ / __ \|  | \/\    \_\  \        /
|_______ \__|___|  /\___  >____  /__|    \______  /\__/\  /
        \/       \/     \/     \/               \/      \/
Author: Jakub Maksymilian Fober
First publication: 2022-2026
Copyright: This work is free of known copyright restrictions.
https://creativecommons.org/publicdomain/mark/1.0/
*/

#pragma once

/* >> Functions << */

namespace LinearWorkflow
{
	/* >> Macros << */

// The numbers are from the "color_space" enum in ReShade.
// They can be compared against BUFFER_COLOR_SPACE, which is defined by ReShade.
#define _RESHADE_COLOR_SPACE_UNKNOWN 0
#define _RESHADE_COLOR_SPACE_SRGB 1
#define _RESHADE_COLOR_SPACE_SCRGB 2
#define _RESHADE_COLOR_SPACE_ST2084 3
#define _RESHADE_COLOR_SPACE_HLG 4

#if BUFFER_COLOR_SPACE == _RESHADE_COLOR_SPACE_UNKNOWN || BUFFER_COLOR_SPACE == _RESHADE_COLOR_SPACE_SRGB // transfer from and to sRGB gamma in SDR (and fall back to it in the unknown color space case)
	#define _TO_DISPLAY_GAMMA exp(log(E) / 2.4) * 1.055 - 0.055
	#define _TO_LINEAR_GAMMA exp(log((E + 0.055) / 1.055) * 2.4)

	// Gamma transfer function: linear --> display
	float toDisplayGamma(float E)
	{ return E <= 0.0031308 ? E * 12.92 : _TO_DISPLAY_GAMMA; }
	// Gamma transfer function: linear --> display
	float2 toDisplayGamma(float2 E)
	{ return bool2(E <= 0.0031308) ? E * 12.92 : _TO_DISPLAY_GAMMA; }
	// Gamma transfer function: linear --> display
	float3 toDisplayGamma(float3 E)
	{ return bool3(E <= 0.0031308) ? E * 12.92 : _TO_DISPLAY_GAMMA; }
	// Gamma transfer function: linear --> display
	float4 toDisplayGamma(float4 E)
	{ return bool4(E <= 0.0031308) ? E * 12.92 : _TO_DISPLAY_GAMMA; }

// Inverse transfer function ___________________________________________________

	// Gamma transfer function: display --> linear
	float  toLinearGamma(float E)
	{ return E <= 0.04049936 ? E / 12.92 : _TO_LINEAR_GAMMA; }
	// Gamma transfer function: display --> linear
	float2 toLinearGamma(float2 E)
	{ return bool2(E <= 0.04049936) ? E / 12.92 : _TO_LINEAR_GAMMA; }
	// Gamma transfer function: display --> linear
	float3 toLinearGamma(float3 E)
	{ return bool3(E <= 0.04049936) ? E / 12.92 : _TO_LINEAR_GAMMA; }
	// Gamma transfer function: display --> linear
	float4 toLinearGamma(float4 E)
	{ return bool4(E <= 0.04049936) ? E / 12.92 : _TO_LINEAR_GAMMA; }

#elif BUFFER_COLOR_SPACE == _RESHADE_COLOR_SPACE_ST2084 // transfer from and to HDR10 ST 2084
	#define _TO_DISPLAY_GAMMA exp(log((0.8359375 + 18.8515625 * exp(logE * 0.1593017578125)) / (18.6875 * exp(logE * 0.1593017578125) + 1.f)) * 78.84375)
	#define _TO_LINEAR_GAMMA exp(log(max(exp(logE / 78.84375) - 0.8359375, 0.f) / (18.8515625 - 18.6875 * exp(logE / 78.84375))) / 0.1593017578125)

	// Gamma transfer function: linear --> display
	float toDisplayGamma(float E)
	{
		float logE = log(E);
		return _TO_DISPLAY_GAMMA;
	}
	// Gamma transfer function: linear --> display
	float2 toDisplayGamma(float2 E)
	{
		float2 logE = log(E);
		return _TO_DISPLAY_GAMMA;
	}
	// Gamma transfer function: linear --> display
	float3 toDisplayGamma(float3 E)
	{
		float3 logE = log(E);
		return _TO_DISPLAY_GAMMA;
	}
	// Gamma transfer function: linear --> display
	float4 toDisplayGamma(float4 E)
	{
		float4 logE = log(E);
		return _TO_DISPLAY_GAMMA;
	}

// Inverse transfer function ___________________________________________________

	// Gamma transfer function: display --> linear
	float toLinearGamma(float E)
	{
		float logE = log(E);
		return _TO_LINEAR_GAMMA;
	}
	// Gamma transfer function: display --> linear
	float2 toLinearGamma(float2 E)
	{
		float2 logE = log(E);
		return _TO_LINEAR_GAMMA;
	}
	// Gamma transfer function: display --> linear
	float3 toLinearGamma(float3 E)
	{
		float3 logE = log(E);
		return _TO_LINEAR_GAMMA;
	}
	// Gamma transfer function: display --> linear
	float4 toLinearGamma(float4 E)
	{
		float4 logE = log(E);
		return _TO_LINEAR_GAMMA;
	}

#elif BUFFER_COLOR_SPACE == _RESHADE_COLOR_SPACE_HLG // transfer from and to HDR10 HLG
	#define _TO_DISPLAY_GAMMA 0.17883277 * log(12.f * E - 0.28466892) + 0.55991073
	#define _TO_LINEAR_GAMMA (exp((E - 0.55991073) / 0.17883277) + 0.28466892) / 12.f

	// Gamma transfer function: linear --> display
	float toDisplayGamma(float E)
	{
		return E <= 1.f/12.f ?
			sqrt(E * 3.f) :
			_TO_DISPLAY_GAMMA;
	}
	// Gamma transfer function: linear --> display
	float2 toDisplayGamma(float2 E)
	{
		return bool2(E <= 1.f/12.f) ?
			sqrt(E * 3.f) :
			_TO_DISPLAY_GAMMA;
	}
	// Gamma transfer function: linear --> display
	float3 toDisplayGamma(float3 E)
	{
		return bool3(E <= 1.f/12.f) ?
			sqrt(E * 3.f) :
			_TO_DISPLAY_GAMMA;
	}
	// Gamma transfer function: linear --> display
	float4 toDisplayGamma(float4 E)
	{
		return bool4(E <= 1.f/12.f) ?
			sqrt(E * 3.f) :
			_TO_DISPLAY_GAMMA;
	}

// Inverse transfer function ___________________________________________________

	// Gamma transfer function: display --> linear
	float toLinearGamma(float E)
	{
		return E <= 0.5 ?
			E * E / 3.f :
			_TO_LINEAR_GAMMA;
	}
	// Gamma transfer function: display --> linear
	float2 toLinearGamma(float2 E)
	{
		return bool2(E <= 0.5) ?
			E * E / 3.f :
			_TO_LINEAR_GAMMA;
	}
	// Gamma transfer function: display --> linear
	float3 toLinearGamma(float3 E)
	{
		return bool3(E <= 0.5) ?
			E * E / 3.f :
			_TO_LINEAR_GAMMA;
	}
	// Gamma transfer function: display --> linear
	float4 toLinearGamma(float4 E)
	{
		return bool4(E <= 0.5) ?
			E * E / 3.f :
			_TO_LINEAR_GAMMA;
	}

#else // bypass transfer (e.g. BUFFER_COLOR_SPACE == _RESHADE_COLOR_SPACE_SCRGB which is linear in/out)

	// Gamma transfer function: linear --> display
	float toDisplayGamma(float E) { return E; }
	float2 toDisplayGamma(float2 E) { return E; }
	float3 toDisplayGamma(float3 E) { return E; }
	float4 toDisplayGamma(float4 E) { return E; }

	// Gamma transfer function: display --> linear
	float toLinearGamma(float E) { return E; }
	float2 toLinearGamma(float2 E) { return E; }
	float3 toLinearGamma(float3 E) { return E; }
	float4 toLinearGamma(float4 E) { return E; }

#endif
}
