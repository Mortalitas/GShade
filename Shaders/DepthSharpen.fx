/**
 * DepthSharpen v1.11
 * by OVNI
 *
 * Based on :
 * LumaSharpen version 1.5.0
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 *
 * It blurs the original pixel with the surrounding pixels and then subtracts this blur to sharpen the image.
 * It does this in luma to avoid color artifacts and allows limiting the maximum sharpning to avoid or lessen halo artifacts.
 * This is similar to using Unsharp Mask in Photoshop.
 *
 * OVNI modifications :
 * - depth test for sharpening so it doesn't generate too much aliasing
 */
 // Lightly optimized by Marot Satil for the GShade project.

uniform float sharp_strength <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 10.0;
	ui_tooltip = "Strength of the sharpening";
> = 3.0;

uniform float sharp_clamp <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.005;
	ui_tooltip = "Limits maximum amount of sharpening a pixel receives";
> = 0.035;

uniform int pattern <
	ui_type = "combo";
	ui_items = "Fast\0Normal\0Wider\0Pyramid shaped\0";
	ui_tooltip = "Choose a sample pattern";
> = 2;

uniform float offset_bias <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 6.0;
	ui_tooltip = "Offset bias adjusts the radius of the sampling pattern. I designed the pattern for offset_bias 1.0, but feel free to experiment.";
> = 1.0;

uniform bool debug <
	ui_tooltip = "Debug view.";
> = false;

uniform float sharpenEndDepth <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Max depth for sharpening";
> = 0.3;

uniform float sharpenMaxDeltaDepth <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_tooltip = "Max depth difference between 2 samples to apply sharpen filter.";
> = 0.0025;

#include "ReShade.fxh"

   /*-----------------------------------------------------------.
  /                      Developer settings                     /
  '-----------------------------------------------------------*/
#define CoefLuma float3(0.2126, 0.7152, 0.0722)      // BT.709 & sRBG luma coefficient (Monitors and HD Television)
//#define CoefLuma float3(0.299, 0.587, 0.114)       // BT.601 luma coefficient (SD Television)
//#define CoefLuma float3(1.0/3.0, 1.0/3.0, 1.0/3.0) // Equal weight coefficient

   /*-----------------------------------------------------------.
  /                          Main code                          /
  '-----------------------------------------------------------*/

float3 DepthSharpenPass(float4 position : SV_Position, float2 tex : TEXCOORD) : SV_Target
{
	// -- Get the original pixel --
	const float3 ori = tex2D(ReShade::BackBuffer, tex).rgb;

	/*-----------------------------------------------------------.
	/      Determine if we should sharpen / blur
	'-----------------------------------------------------------*/

	const float depth = ReShade::GetLinearizedDepth(tex).r;

	// -- Combining the strength and luma multipliers --
	float3 sharp_strength_luma = (CoefLuma * sharp_strength); //I'll be combining even more multipliers with it later on

	/*-----------------------------------------------------------.
	/                       Sampling patterns                     /
	'-----------------------------------------------------------*/

	float3 blur_ori;

	//   [ NW,   , NE ] Each texture lookup (except ori)
	//   [   ,ori,    ] samples 4 pixels
	//   [ SW,   , SE ]

	// -- Pattern 1 -- A (fast) 7 tap gaussian using only 2+1 texture fetches.
	if (pattern == 0)
	{
		// -- Gaussian filter --
		//   [ 1/9, 2/9,    ]     [ 1 , 2 ,   ]
		//   [ 2/9, 8/9, 2/9]  =  [ 2 , 8 , 2 ]
		//   [    , 2/9, 1/9]     [   , 2 , 1 ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + (BUFFER_PIXEL_SIZE / 3.0) * offset_bias).rgb;  // North West
		blur_ori += tex2D(ReShade::BackBuffer, tex + (-BUFFER_PIXEL_SIZE / 3.0) * offset_bias).rgb; // South East

		blur_ori /= 2;  //Divide by the number of texture fetches

		sharp_strength_luma *= 1.5; // Adjust strength to aproximate the strength of pattern 2
	}

	// -- Pattern 2 -- A 9 tap gaussian using 4+1 texture fetches.
	if (pattern == 1)
	{
		// -- Gaussian filter --
		//   [ .25, .50, .25]     [ 1 , 2 , 1 ]
		//   [ .50,   1, .50]  =  [ 2 , 4 , 2 ]
		//   [ .25, .50, .25]     [ 1 , 2 , 1 ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + float2(BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y) * 0.5 * offset_bias).rgb; // South East
		blur_ori += tex2D(ReShade::BackBuffer, tex - BUFFER_PIXEL_SIZE * 0.5 * offset_bias).rgb;  // South West
		blur_ori += tex2D(ReShade::BackBuffer, tex + BUFFER_PIXEL_SIZE * 0.5 * offset_bias).rgb; // North East
		blur_ori += tex2D(ReShade::BackBuffer, tex - float2(BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y) * 0.5 * offset_bias).rgb; // North West

		blur_ori *= 0.25;  // ( /= 4) Divide by the number of texture fetches
	}

	// -- Pattern 3 -- An experimental 17 tap gaussian using 4+1 texture fetches.
	if (pattern == 2)
	{
		// -- Gaussian filter --
		//   [   , 4 , 6 ,   ,   ]
		//   [   ,16 ,24 ,16 , 4 ]
		//   [ 6 ,24 ,   ,24 , 6 ]
		//   [ 4 ,16 ,24 ,16 ,   ]
		//   [   ,   , 6 , 4 ,   ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + BUFFER_PIXEL_SIZE * float2(0.4, -1.2) * offset_bias).rgb;  // South South East
		blur_ori += tex2D(ReShade::BackBuffer, tex - BUFFER_PIXEL_SIZE * float2(1.2, 0.4) * offset_bias).rgb; // West South West
		blur_ori += tex2D(ReShade::BackBuffer, tex + BUFFER_PIXEL_SIZE * float2(1.2, 0.4) * offset_bias).rgb; // East North East
		blur_ori += tex2D(ReShade::BackBuffer, tex - BUFFER_PIXEL_SIZE * float2(0.4, -1.2) * offset_bias).rgb; // North North West

		blur_ori *= 0.25;  // ( /= 4) Divide by the number of texture fetches

		sharp_strength_luma *= 0.51;
	}

	// -- Pattern 4 -- A 9 tap high pass (pyramid filter) using 4+1 texture fetches.
	if (pattern == 3)
	{
		// -- Gaussian filter --
		//   [ .50, .50, .50]     [ 1 , 1 , 1 ]
		//   [ .50,    , .50]  =  [ 1 ,   , 1 ]
		//   [ .50, .50, .50]     [ 1 , 1 , 1 ]

		blur_ori  = tex2D(ReShade::BackBuffer, tex + float2(0.5 * BUFFER_PIXEL_SIZE.x, -BUFFER_PIXEL_SIZE.y * offset_bias)).rgb;  // South South East
		blur_ori += tex2D(ReShade::BackBuffer, tex + float2(offset_bias * -BUFFER_PIXEL_SIZE.x, 0.5 * -BUFFER_PIXEL_SIZE.y)).rgb; // West South West
		blur_ori += tex2D(ReShade::BackBuffer, tex + float2(offset_bias * BUFFER_PIXEL_SIZE.x, 0.5 * BUFFER_PIXEL_SIZE.y)).rgb; // East North East
		blur_ori += tex2D(ReShade::BackBuffer, tex + float2(0.5 * -BUFFER_PIXEL_SIZE.x, BUFFER_PIXEL_SIZE.y * offset_bias)).rgb; // North North West

		blur_ori /= 4.0;  //Divide by the number of texture fetches

		sharp_strength_luma *= 0.666; // Adjust strength to aproximate the strength of pattern 2
	}

	/*-----------------------------------------------------------.
	/
	'-----------------------------------------------------------*/

	// Modify sharping Strength depending of depth
	if( sharpenEndDepth < 1.0 )
		sharp_strength_luma *= 1.0 - depth/sharpenEndDepth; // depth reranged in [0,sharpenEndDepth]

	/*-----------------------------------------------------------.
	/                            Sharpen                          /
	'-----------------------------------------------------------*/

	// -- Calculate the sharpening --
	const float3 sharp = ori - blur_ori;  //Subtracting the blurred image from the original image

	// -- Adjust strength of the sharpening and clamp it--
	const float4 sharp_strength_luma_clamp = float4(sharp_strength_luma * (0.5 / sharp_clamp),0.5); //Roll part of the clamp into the dot

	float sharp_luma = saturate(dot(float4(sharp,1.0), sharp_strength_luma_clamp)); //Calculate the luma, adjust the strength, scale up and clamp
	sharp_luma = (sharp_clamp * 2.0) * sharp_luma - sharp_clamp; //scale down

	/*-----------------------------------------------------------.
	/                     Returning the output                    /
	'-----------------------------------------------------------*/

	if (debug)
		return saturate(0.5 + (sharp_luma * 4.0)).rrr;

	// -- Combining the values to get the final sharpened pixel	--
	return ori + sharp_luma;    // Add the sharpening to the the original.
}

technique DepthSharpen
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DepthSharpenPass;
	}
}
