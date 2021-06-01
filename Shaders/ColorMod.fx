/*
	Full credits to the ReShade team
	Ported by Insomnia
*/

//-----------------------------
uniform float ColormodChroma <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Saturation";
	ui_tooltip = "Amount of saturation";
> = 0.780;
//-----------------------------
uniform float ColormodGammaR <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Gamma for Red";
	ui_tooltip = "Gamma for Red";
> = 1.0;
uniform float ColormodGammaG <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Gamma for Green";
	ui_tooltip = "Gamma for Green";
> = 1.0;
uniform float ColormodGammaB <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Gamma for Blue";
	ui_tooltip = "Gamma for Blue";
> = 1.0;
//-----------------------------
uniform float ColormodContrastR <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Contrast for Red";
	ui_tooltip = "Contrast for Red";
> = 0.50;
uniform float ColormodContrastG <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Contrast for Green";
	ui_tooltip = "Contrast for Green";
> = 0.50;
uniform float ColormodContrastB <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Contrast for Blue";
	ui_tooltip = "Contrast for Blue";
> = 0.50;
//-----------------------------
uniform float ColormodBrightnessR <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Brightness for Red";
	ui_tooltip = "Brightness for Red";
> = -0.08;
uniform float ColormodBrightnessG <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Brightness for Green";
	ui_tooltip = "Brightness for Green";
> = -0.08;
uniform float ColormodBrightnessB <
	ui_type = "slider";
	ui_min = -1.0; ui_max = 2.0;
	ui_label = "Brightness for Blue";
	ui_tooltip = "Brightness for Blue";
> = -0.08;

//-----------------------------
//-----------------------------
//-----------------------------


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 ColorModPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
		
	color.xyz = (color.xyz - dot(color.xyz, 0.333)) * ColormodChroma + dot(color.xyz, 0.333);
	color.xyz = saturate(color.xyz);
	color.x = (pow(color.x, ColormodGammaR) - 0.5) * ColormodContrastR + 0.5 + ColormodBrightnessR;
	color.y = (pow(color.y, ColormodGammaG) - 0.5) * ColormodContrastG + 0.5 + ColormodBrightnessB;
	color.z = (pow(color.z, ColormodGammaB) - 0.5) * ColormodContrastB + 0.5 + ColormodBrightnessB;
#if GSHADE_DITHER
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return color;
#endif
}


technique ColorMod
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ColorModPass;
	}
}
