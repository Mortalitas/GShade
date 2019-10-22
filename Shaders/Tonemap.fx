/**
 * Tonemap version 1.1
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 */
 // Lightly optimized by Marot Satil for the GShade project.

uniform float Gamma <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Adjust midtones. 1.0 is neutral. This setting does exactly the same as the one in Lift Gamma Gain, only with less control.";
> = 1.0;
uniform float Exposure <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Adjust exposure";
> = 0.0;
uniform float Saturation <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Adjust saturation";
> = 0.0;

uniform float Bleach <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Brightens the shadows and fades the colors";
> = 0.0;

uniform float Defog <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "How much of the color tint to remove";
> = 0.0;
uniform float3 FogColor <
	ui_type = "color";
	ui_label = "Defog Color";
	ui_tooltip = "Which color tint to remove";
> = float3(0.0, 0.0, 1.0);


#include "ReShade.fxh"

float3 TonemapPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	color = saturate(color - Defog * FogColor * 2.55); // Defog
	color *= pow(2.0f, Exposure); // Exposure
	color = pow(color, Gamma); // Gamma

	const float3 coefLuma = float3(0.2126, 0.7152, 0.0722);
	float lum = dot(coefLuma, color);
	
	const float L = saturate(10.0 * (lum - 0.45));
	const float3 A2 = Bleach * color;

	const float3 result1 = 2.0f * color * lum;
	const float3 result2 = 1.0f - 2.0f * (1.0f - lum) * (1.0f - color);
	
	const float3 newColor = lerp(result1, result2, L);
	const float3 mixRGB = A2 * newColor;
	color += ((1.0f - A2) * mixRGB);
	
	const float3 middlegray = dot(color, (1.0 / 3.0));
	const float3 diffcolor = color - middlegray;
	
	return (color + diffcolor * Saturation) / (1 + (diffcolor * Saturation)); // Saturation
}

technique Tonemap
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = TonemapPass;
	}
}
