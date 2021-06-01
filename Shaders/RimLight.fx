/*
Rim Light PS (c) 2018 Jacob Maximilian Fober
(based on DisplayDepth port (c) 2018 CeeJay)

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// Rim Light PS v0.1.6 a
// Lightly optimized by Marot Satil for the GShade project.

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif


	  ////////////
	 /// MENU ///
	////////////

uniform float3 Color <
	ui_label = "Rim Light Color";
	ui_tooltip = "Adjust rim light tint";
	ui_type = "color";
> = float3(1, 1, 1);

uniform bool Debug <
	ui_label = "Display Normal Map Pass";
	ui_tooltip = "Surface vector angle color map";
	ui_category = "Debug Tools";
	ui_category_closed = true;
> = false;

uniform bool CustomFarPlane <
	ui_label = "Custom Far Plane";
	ui_tooltip = "Enable custom far plane display outside debug view";
	ui_category = "Debug Tools";
> = true;

uniform float FarPlane <
	ui_label = "Depth Far Plane Preview";
	ui_tooltip = "Adjust this option for proper normal map display\n"
	"and change preprocessor definitions, so that\n"
	"RESHADE_DEPTH_LINEARIZATION_FAR_PLANE = Your_Value";
	ui_type = "slider";
	ui_min = 0; ui_max = 1000; ui_step = 1;
	ui_category = "Debug Tools";
> = 1000.0;


	  /////////////////
	 /// FUNCTIONS ///
	/////////////////

// Overlay blending mode
float Overlay(float Layer)
{
	const float MinLayer = min(Layer, 0.5);
	const float MaxLayer = max(Layer, 0.5);
	return 2 * (MinLayer * MinLayer + 2 * MaxLayer - MaxLayer * MaxLayer) - 1.5;
}

// Get depth pass function
float GetDepth(float2 TexCoord)
{
	float depth;
	if(Debug || CustomFarPlane)
	{
		#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		TexCoord.y = 1.0 - TexCoord.y;
		#endif

		depth = tex2Dlod(ReShade::DepthBuffer, float4(TexCoord, 0, 0)).x;

		#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		depth = (exp(depth * log(C + 1.0)) - 1.0) / C;
		#endif
		#if RESHADE_DEPTH_INPUT_IS_REVERSED
		depth = 1.0 - depth;
		#endif

		depth /= FarPlane - depth * (FarPlane - 1.0);
	}
	else 
	{
		depth = ReShade::GetLinearizedDepth(TexCoord);
	}
	return depth;
}

// Normal pass from depth function
float3 NormalVector(float2 TexCoord)
{
	const float3 offset = float3(BUFFER_PIXEL_SIZE.xy, 0.0);
	const float2 posCenter = TexCoord.xy;
	const float2 posNorth = posCenter - offset.zy;
	const float2 posEast = posCenter + offset.xz;

	const float3 vertCenter = float3(posCenter - 0.5, 1) * GetDepth(posCenter);
	const float3 vertNorth = float3(posNorth - 0.5, 1) * GetDepth(posNorth);
	const float3 vertEast = float3(posEast - 0.5, 1) * GetDepth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}


	  //////////////
	 /// SHADER ///
	//////////////

void RimLightPS(in float4 position : SV_Position, in float2 TexCoord : TEXCOORD, out float3 color : SV_Target)
{
	const float3 NormalPass = NormalVector(TexCoord);

	if(Debug) color = NormalPass;
	else
	{
		color = cross(NormalPass, float3(0.5, 0.5, 1.0));
		const float rim = max(max(color.x, color.y), color.z);
		color = tex2D(ReShade::BackBuffer, TexCoord).rgb;
		color += Color * Overlay(rim);
	}

#if GSHADE_DITHER
	color.rgb += TriDither(color.rgb, TexCoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}


	  //////////////
	 /// OUTPUT ///
	//////////////

technique RimLight < ui_label = "Rim Light"; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = RimLightPS;
	}
}
