///////////////////////////////////////////////////////////////////////////////////
// pColorNoise.fx by Gimle Larpes
// Generates gaussian chroma noise to simulate amplifier noise in digital cameras.
// License: MIT
// Repository: https://github.com/GimleLarpes/potatoFX
///////////////////////////////////////////////////////////////////////////////////

#define P_OKLAB_VERSION_REQUIRE 100
#include "ReShade.fxh"
#include "Oklab.fxh"

static const float PI = pUtils::PI;
static const float EPSILON = pUtils::EPSILON;
static const float INVNORM_FACTOR = Oklab::INVNORM_FACTOR;

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Noise strength";
	ui_category = "Settings";
> = 0.12;
uniform bool UseApproximateTransforms <
	ui_type = "bool";
	ui_label = "Fast colorspace transform";
	ui_tooltip = "Use less accurate approximations instead of the full transform functions";
	ui_category = "Performance";
> = false;


float3 ColorNoisePass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	color = (UseApproximateTransforms)
		? Oklab::Fast_DisplayFormat_to_Linear(color)
		: Oklab::DisplayFormat_to_Linear(color);
	
	static const float NOISE_CURVE = max(INVNORM_FACTOR * 0.025, 1.0);
	float luminance = dot(color, float3(0.2126, 0.7152, 0.0722));

	//White noise
	float noise1 = pUtils::wnoise(texcoord, float2(6.4949, 39.116));
	float noise2 = pUtils::wnoise(texcoord, float2(19.673, 5.5675));
	float noise3 = pUtils::wnoise(texcoord, float2(36.578, 26.118));
	
	//Box-Muller transform
	float r = sqrt(-2.0 * log(noise1 + EPSILON));
	float theta1 = 2.0 * PI * noise2;
	float theta2 = 2.0 * PI * noise3;
	
	//Sensor sensitivity to color channels: https://www.1stvision.com/cameras/AVT/dataman/ibis5_a_1300_8.pdf
	float3 gauss_noise = float3(r * cos(theta1) * 1.33, r * sin(theta1) * 1.25, r * cos(theta2) * 2.0);

	float weight = (Strength * Strength) * NOISE_CURVE / (luminance * (1.0 + rcp(INVNORM_FACTOR)) + 2.0); //Multiply luminance to simulate a wider dynamic range
	color.rgb = Oklab::Saturate_RGB(color.rgb + gauss_noise * weight);
	
	color = (UseApproximateTransforms)
		? Oklab::Fast_Linear_to_DisplayFormat(color)
		: Oklab::Linear_to_DisplayFormat(color);
	return color.rgb;
}

technique ColorNoise <ui_tooltip = 
"Generates gaussian chroma noise to simulate amplifier noise in digital cameras.\n\n"
"(HDR compatible)";>
{
	pass
	{
		VertexShader = PostProcessVS; PixelShader = ColorNoisePass;
	}
}
