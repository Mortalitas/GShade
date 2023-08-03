/*------------------.
| :: Description :: |
'-------------------/

Chromakey PS (version 1.6.1)

Copyright:
This code © 2018-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/4.0/
*/

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

uniform float Threshold
<
	ui_type = "slider";
	ui_min = 0f; ui_max = 0.999; ui_step = 0.001;
	ui_category = "Distance adjustment";
> = 0.5;

uniform bool RadialX <
	ui_label = "Horizontally radial depth";
	ui_category = "Radial distance";
	ui_category_closed = true;
> = false;
uniform bool RadialY <
	ui_label = "Vertically radial depth";
	ui_category = "Radial distance";
> = false;

uniform int FOV
<
	ui_type = "slider";
	ui_units = "°";
	ui_label = "FOV (horizontal)";
	ui_tooltip = "Field of view in degrees";
	ui_step = .01;
	ui_min = 0; ui_max = 200;
	ui_category = "Radial distance";
> = 90;

uniform int CKPass
<
	ui_type = "combo";
	ui_label = "Keying type";
	ui_items = "Background key\0Foreground key\0";
	ui_category = "Direction adjustment";
> = 0;

uniform bool Floor <
	ui_label = "Mask floor";
	ui_category = "Floor masking (experimental)";
	ui_category_closed = true;
> = false;

uniform float FloorAngle
<
	ui_type = "slider";
	ui_units = "°";
	ui_label = "Floor angle";
	ui_type = "slider";
	ui_category = "Floor masking (experimental)";
	ui_min = 0f; ui_max = 1f;
> = 1f;

uniform int Precision
<
	ui_type = "slider";
	ui_label = "Floor precision";
	ui_category = "Floor masking (experimental)";
	ui_min = 2; ui_max = 9216;
> = 4;

uniform int Color
<
	ui_type = "radio";
	ui_label = "Keying color";
	ui_tooltip = "Ultimatte(tm) Super Blue and Green are industry standard colors for chromakey.\n"
				 "Ensure that you have the \"Clear Alpha Channel\" option disabled on GShade\'s \"Settings\" tab if you are using \"Alpha Transparency\".";
	ui_items = "Pure Green (RGB 0,255,0)\0Pure Red (RGB 255,0,255)\0Pure Blue (RGB 0,255,0)\0Super Blue Ultimatte(tm) (RGB 18,46,184)\0Green Ultimatte(tm) (RGB 74,214,92)\0Custom\0Alpha Transparency\0";
	ui_category = "Color settings";
	ui_category_closed = false;
> = 6;

uniform float3 CustomColor
<
	ui_type = "color";
	ui_label = "Custom color";
	ui_category = "Color settings";
> = float3(0.0, 1.0, 0.0);

uniform bool AntiAliased <
	ui_label = "Anti-aliased mask";
	ui_tooltip = "Disabling this option will reduce masking gaps";
	ui_category = "Additional settings";
	ui_category_closed = true;
> = false;

uniform bool InvertDepth
<
	ui_label = "Invert Depth";
	ui_tooltip = "Inverts the depth buffer so that the color is applied to the foreground instead.";
	ui_category = "Additional settings";
> = false;

/*----------------.
| :: Functions :: |
'----------------*/

float MaskAA(float2 texcoord)
{
	// Sample depth image
	float Depth;
	if (InvertDepth)
		Depth = 1 - ReShade::GetLinearizedDepth(texcoord);
	else
		Depth = ReShade::GetLinearizedDepth(texcoord);

	// Convert to radial depth
	float2 Size;
	Size.x = tan(radians(FOV*0.5));
	Size.y = Size.x / BUFFER_ASPECT_RATIO;
	if(RadialX) Depth *= length(float2((texcoord.x-0.5)*Size.x, 1.0));
	if(RadialY) Depth *= length(float2((texcoord.y-0.5)*Size.y, 1.0));

	// Return jagged mask
	if (!AntiAliased) return step(Threshold, Depth);

	// Get half-pixel size in depth value
	float hPixel = fwidth(Depth)*0.5;

	return smoothstep(Threshold-hPixel, Threshold+hPixel, Depth);
}

float3 GetPosition(float2 texcoord)
{
	// Get view angle for trigonometric functions
	const float theta = radians(FOV*0.5);

	float3 position = float3( texcoord*2.0-1.0, ReShade::GetLinearizedDepth(texcoord) );
	// Reverse perspective
	position.xy *= position.z;

	return position;
}

// Normal map (OpenGL oriented) generator from DisplayDepth.fx
float3 GetNormal(float2 texcoord)
{
	const float3 offset = float3(BUFFER_PIXEL_SIZE.xy, 0.0);
	const float2 posCenter = texcoord.xy;
	const float2 posNorth  = posCenter - offset.zy;
	const float2 posEast   = posCenter + offset.xz;

	const float3 vertCenter = float3(posCenter - 0.5, 1.0) * ReShade::GetLinearizedDepth(posCenter);
	const float3 vertNorth  = float3(posNorth - 0.5,  1.0) * ReShade::GetLinearizedDepth(posNorth);
	const float3 vertEast   = float3(posEast - 0.5,   1.0) * ReShade::GetLinearizedDepth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

/*--------------.
| :: Shaders :: |
'--------------*/

float4 ChromakeyPS(
	float4 pos		: SV_Position,
	float2 texcoord : TEXCOORD
) : SV_Target
{
	// Define chromakey color, Ultimatte™ Super Blue, Ultimatte™ Green, or user color
	float3 Screen;
	switch(Color)
	{
		case 0:{ Screen = float3(0.0, 1.0, 0.0); break; }    // Green
		case 1:{ Screen = float3(1.0, 0.0, 0.0); break; }    // Red
		case 2:{ Screen = float3(0.0, 0.0, 1.0); break; }    // Blue
		case 3:{ Screen = float3(0.07, 0.18, 0.72); break; } // Ultimatte(tm) Super Blue
		case 4:{ Screen = float3(0.29, 0.84, 0.36); break; } // Ultimatte(tm) Green
		case 5:{ Screen = CustomColor;              break; } // User defined color
		case 6:{ Screen = float3(0.0, 0.0, 0.0); break; } // Transparency needs to use black because of some thumbnail limitations in specific software.
	}

	// Generate depth mask
	float DepthMask = MaskAA(texcoord);

	if (Floor)
	{

		bool FloorMask = (float)round( GetNormal(texcoord).y*Precision )/Precision==(float)round( FloorAngle*Precision )/Precision;

		if (FloorMask)
			DepthMask = 1.0;
	}

	if(bool(CKPass)) DepthMask = 1.0-DepthMask;

	return float4(lerp(tex2D(ReShade::BackBuffer, texcoord).rgb, Screen, DepthMask), DepthMask > Threshold && Color == 6 ? 0.0 : 1.0);
}

/*-------------.
| :: Output :: |
'-------------*/

technique Chromakey
<
	ui_tooltip =
		"Generate green-screen wall based on depth\n"
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 4.0";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ChromakeyPS;
	}
}
