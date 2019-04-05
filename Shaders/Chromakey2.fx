/*
Chromakey PS v1.4.0 (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

#include "ReShade.fxh"

	  ////////////
	 /// MENU ///
	////////////

uniform float Threshold2 <
	ui_label = "Threshold";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.999; ui_step = 0.001;
	ui_category = "Distance adjustment";
> = 0.1;

uniform bool RadialX2 <
	ui_label = "Horizontally radial depth";
	ui_category = "Radial distance";
> = false;
uniform bool RadialY2 <
	ui_label = "Vertically radial depth";
	ui_category = "Radial distance";
> = false;

uniform float FOV2 <
	ui_label = "FOV (horizontal)";
  ui_type = "slider";
	ui_tooltip = "Field of view in degrees";
	ui_step = .01;
	ui_min = 0.0; ui_max = 300.0;
	ui_category = "Radial distance";
> = 90;

uniform int Pass2 <
	ui_label = "Keying type";
	ui_type = "combo";
	ui_items = "Background key\0Foreground key\0";
	ui_category = "Direction adjustment";
> = 0;

uniform int Color2 <
	ui_label = "Keying color";
	ui_tooltip = "Ultimatte(tm) Super Blue and Green are industry standard colors for chromakey";
	ui_type = "combo";
	ui_items = "Super Blue Ultimatte(tm)\0Green Ultimatte(tm)\0Custom\0";
	ui_category = "Color settings";
> = 0;

uniform float3 CustomColor2 <
	ui_type = "color";
	ui_label = "Custom color";
	ui_category = "Color settings";
> = float3(1.0, 0.0, 0.0);

uniform bool AntiAliased2 <
	ui_label = "Anti-aliased mask";
	ui_tooltip = "Disabling this option will reduce masking gaps";
	ui_category = "Color settings";
> = false;


	  /////////////////
	 /// FUNCTIONS ///
	/////////////////

float MaskAA(float2 texcoord)
{
	// Sample depth image
	float Depth = ReShade::GetLinearizedDepth(texcoord);

	// Convert to radial depth
	float2 Size;
	Size.x = tan(radians(FOV2*0.5));
	Size.y = Size.x / ReShade::AspectRatio;
	if(RadialX2) Depth *= length(float2((texcoord.x-0.5)*Size.x, 1.0));
	if(RadialY2) Depth *= length(float2((texcoord.y-0.5)*Size.y, 1.0));

	// Return jagged mask
	if(!AntiAliased2) return step(Threshold2, Depth);

	// Get half-pixel size in depth value
	float hPixel = fwidth(Depth)*0.5;

	return smoothstep(Threshold2-hPixel, Threshold2+hPixel, Depth);
}


	  //////////////
	 /// SHADER ///
	//////////////

float3 Chromakey2PS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Define chromakey color, Ultimatte(tm) Super Blue, Ultimatte(tm) Green, or user color
	float3 Screen;
	switch(Color2)
	{
		case 0:{ Screen = float3(0.07, 0.18, 0.72); break; } // Ultimatte(tm) Super Blue
		case 1:{ Screen = float3(0.29, 0.84, 0.36); break; } // Ultimatte(tm) Green
		case 2:{ Screen = CustomColor2;              break; } // User defined color
	}

	// Generate depth mask
	float DepthMask = MaskAA(texcoord);
	if(bool(Pass2)) DepthMask = 1.0-DepthMask;

	return lerp(tex2D(ReShade::BackBuffer, texcoord).rgb, Screen, DepthMask);
}


	  //////////////
	 /// OUTPUT ///
	//////////////

technique Chromakey2 < ui_tooltip = "Generate green-screen wall based of depth"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = Chromakey2PS;
	}
}
