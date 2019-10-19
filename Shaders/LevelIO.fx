////-----------//
///**LevelIO**///
//-----------////
// Created by 2b3, ported to ReShade 3 by Insomnia, and lightly optimized by Marot Satil.

uniform float lin_bp <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 255.0;
	ui_step = 1.0;
	ui_label = "input black point";
	ui_tooltip = "black point for input";
> = 0.0;
uniform float lin_wp <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 255.0;
	ui_step = 1.0;
	ui_label = "input white point";
	ui_tooltip = "white point for input";
> = 255.0;
uniform float lin_g <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 10.0;
	ui_step = 0.10;
	ui_label = "gamma";
> = 1.00;
uniform float lio_s <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_step = 1.0;
	ui_label = "saturation";
	ui_tooltip = "0 - zero sat / 1 - real / 2 - x2 sat";
> = 1.00;
uniform float lout_bp <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 255.0;
	ui_step = 1.0;
	ui_label = "output black point";
	ui_tooltip = "black point for output";
> = 0.0;
uniform float lout_wp <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 255.0;
	ui_step = 1.0;
	ui_label = "output white point";
	ui_tooltip = "white point for output";
> = 255.0;

#include "ReShade.fxh"

float3 LIOPass(float4 position : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	const float ib = lin_bp/255.0;
	const float iw = lin_wp/255.0;
	const float ob = lout_bp/255.0;
	const float ow = lout_wp/255.0;
	
	color.rgb=min(max(color.rgb-ib, 0)/(iw-ib), 1);
	//if(lin_g != 1) color.rgb=saturate(pow(abs(color.rgb), 1/lin_g));
	if(lin_g != 1) color.rgb=pow(abs(color.rgb), 1/lin_g);
	color.rgb=min( max(color.rgb*(ow-ob)+ob, ob), ow);	//output levels (needed min, max for sure :S)
	if (lio_s != 1)
	{
		const float cm=(color.r+color.g+color.b)/3;
		color.rgb=cm-(cm-color.rgb)*lio_s;
	}
	
	return color;
}


technique LevelIO
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LIOPass;
	}
}