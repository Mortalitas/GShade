/**
 * FilmicPass
 *
 * Applies some common color adjustments to mimic a more cinema-like look.
 */
 // Lightly optimized by Marot Satil for the GShade project.

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.05; ui_max = 1.5;
	ui_toolip = "Strength of the color curve altering";
> = 0.85;

uniform float Fade <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.6;
	ui_tooltip = "Decreases contrast to imitate faded image";
> = 0.4;
uniform float Contrast <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0;
> = 1.0;
uniform float Linearization <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.0;
> = 0.5;
uniform float Bleach <
	ui_type = "slider";
	ui_min = -0.5; ui_max = 1.0;
	ui_tooltip = "More bleach means more contrasted and less colorful image";
> = 0.0;
uniform float Saturation <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
> = -0.15;

uniform float RedCurve <
	ui_type = "slider";
	ui_min = 0.001; ui_max = 2.0;
> = 1.0;
uniform float GreenCurve <
	ui_type = "slider";
	ui_min = 0.001; ui_max = 2.0;
> = 1.0;
uniform float BlueCurve <
	ui_type = "slider";
	ui_min = 0.001; ui_max = 2.0;
> = 1.0;
uniform float BaseCurve <
	ui_type = "slider";
	ui_min = 0.001; ui_max = 2.0;
> = 1.5;

uniform float BaseGamma <
	ui_type = "slider";
	ui_min = 0.7; ui_max = 2.0;
	ui_tooltip = "Gamma Curve";
> = 1.0;
uniform float EffectGamma <
	ui_type = "slider";
	ui_min = 0.001; ui_max = 2.0;
> = 0.65;
uniform float EffectGammaR <
	ui_type = "slider";
	ui_min = 0.001; ui_max = 2.0;
> = 1.0;
uniform float EffectGammaG <
	ui_type = "slider";
	ui_min = 0.001; ui_max = 2.0;
> = 1.0;
uniform float EffectGammaB <
	ui_type = "slider";
	ui_min = 0.001; ui_max = 2.0;
> = 1.0;

uniform float3 LumCoeff <
> = float3(0.212656, 0.715158, 0.072186);

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 FilmPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 B = lerp(0.01, pow(saturate(tex2D(ReShade::BackBuffer, texcoord).rgb), Linearization), Contrast);

	float3 D = dot(B.rgb, LumCoeff);

	B = pow(abs(B), 1.0 / BaseGamma);

	const float y = 1.0 / (1.0 + exp(RedCurve / 2.0));
	const float z = 1.0 / (1.0 + exp(GreenCurve / 2.0));
	const float w = 1.0 / (1.0 + exp(BlueCurve / 2.0));
	const float v = 1.0 / (1.0 + exp(BaseCurve / 2.0));

	float3 C = B;

	D.r = (1.0 / (1.0 + exp(-RedCurve * (D.r - 0.5))) - y) / (1.0 - 2.0 * y);
	D.g = (1.0 / (1.0 + exp(-GreenCurve * (D.g - 0.5))) - z) / (1.0 - 2.0 * z);
	D.b = (1.0 / (1.0 + exp(-BlueCurve * (D.b - 0.5))) - w) / (1.0 - 2.0 * w);

	D = pow(abs(D), 1.0 / EffectGamma);
 
	D = lerp(D, 1.0 - D, Bleach);
 
	D.r = pow(abs(D.r), 1.0 / EffectGammaR);
	D.g = pow(abs(D.g), 1.0 / EffectGammaG);
	D.b = pow(abs(D.b), 1.0 / EffectGammaB);
 
	if (D.r < 0.5)
		C.r = (2.0 * D.r - 1.0) * (B.r - B.r * B.r) + B.r;
	else
		C.r = (2.0 * D.r - 1.0) * (sqrt(B.r) - B.r) + B.r;
 
	if (D.g < 0.5)
		C.g = (2.0 * D.g - 1.0) * (B.g - B.g * B.g) + B.g;
	else
		C.g = (2.0 * D.g - 1.0) * (sqrt(B.g) - B.g) + B.g;

	if (D.b < 0.5)
		C.b = (2.0 * D.b - 1.0) * (B.b - B.b * B.b) + B.b;
	else
		C.b = (2.0 * D.b - 1.0) * (sqrt(B.b) - B.b) + B.b;
 
	float3 F = (1.0 / (1.0 + exp(-BaseCurve * (lerp(B, C, Strength) - 0.5))) - v) / (1.0 - 2.0 * v);

	const float3 iF = F;

	F.r = (iF.r * (1.0 - Saturation) + iF.g * (0.0 + Saturation) + iF.b * Saturation);
	F.g = (iF.r * Saturation + iF.g * ((1.0 - Fade) - Saturation) + iF.b * (Fade + Saturation));
	F.b = (iF.r * Saturation + iF.g * (Fade + Saturation) + iF.b * ((1.0 - Fade) - Saturation));

	const float N = dot(F.rgb, LumCoeff);

	float3 Cn;
	if (N < 0.5)
		Cn = (2.0 * N - 1.0) * (F - F * F) + F;
	else
		Cn = (2.0 * N - 1.0) * (sqrt(F) - F) + F;

#if GSHADE_DITHER
	Cn = lerp(B, pow(max(Cn,0), 1.0 / Linearization), Strength);
	return Cn + TriDither(Cn, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp(B, pow(max(Cn,0), 1.0 / Linearization), Strength);
#endif
}

technique FilmicPass
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FilmPass;
	}
}
