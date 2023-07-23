/*------------------.
| :: Description :: |
'-------------------/

Tilt-Shift PS (version 2.1.0)

Copyright:
This code © 2018-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons,
Attribution 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by/3.0/
*/

/*-------------.
| :: Macros :: |
'-------------*/

// Maximum number of samples for blur
#ifndef TILT_SHIFT_MAX_SAMPLES
	#define TILT_SHIFT_MAX_SAMPLES 128u
#endif

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"
#include "ColorConversion.fxh"
#include "LinearGammaWorkflow.fxh"
#include "BlueNoiseDither.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

// :: Blur amount :: //

uniform float4 K
<
	ui_type = "drag";
	ui_min = -0.2; ui_max = 0.2;
	ui_label = "Distortion profile 'k'";
	ui_tooltip = "Distortion coefficients K1, K2, K3, K4";
	ui_category = "Tilt-shift blur";
> = float4(0.025, 0f, 0f, 0f);

uniform int BlurAngle
<
	ui_type = "slider";
	ui_min = -90; ui_max = 90;
	ui_units = "°";
	ui_label = "Tilt angle";
	ui_tooltip = "Tilt the blur line.";
	ui_category = "Tilt-shift blur";
> = 0;

uniform float BlurOffset
<
	ui_type = "slider";
	ui_min = -1f; ui_max = 1f; ui_step = 0.01;
	ui_label = "Line offset";
	ui_tooltip = "Offset the blur center line.";
	ui_category = "Tilt-shift blur";
> = 0f;

// :: Blur line :: //

uniform bool VisibleLine
<
	ui_type = "input";
	ui_label = "Visualize center line";
	ui_tooltip = "Visualize blur center line.";
	ui_category = "Blur line";
	ui_category_closed = true;
> = false;

uniform uint BlurLineWidth
<
	ui_type = "slider";
	ui_min = 2u; ui_max = 64u;
	ui_units = " pixels";
	ui_label = "Visualized line width";
	ui_tooltip = "Tilt-shift line thickness in pixels.";
	ui_category = "Blur line";
> = 15u;

/*---------------.
| :: Textures :: |
'---------------*/

// Define screen texture with mirror tiles
sampler BackBuffer
{
	Texture = ReShade::BackBufferTex;
	// Border style
	AddressU = MIRROR;
	AddressV = MIRROR;
};

/*----------------.
| :: Functions :: |
'----------------*/

/* Exponential bell weight falloff by JMF
   Generates smooth bell falloff for blur, with perfect weights
   distribution for a given number of samples.
   Input: position ∈ [-1, 1] */
float bellWeight(float position)
{
	// Get deviation for minimum value for a given step size
#if BUFFER_COLOR_BIT_DEPTH==10
	const float deviation = log(rcp(1024u)); // Logarithm of base e
#else
	const float deviation = log(rcp(256u)); // Logarithm of base e
#endif
	// Get smooth bell falloff without aliasing or zero value at the last sample
	return exp(position*position*deviation); // Gaussian bell falloff
}

// Get coordinates rotation matrix
float2x2 get2dRotationMatrix(int angle)
{
	// Convert angle to radians
	float angleRad = radians(angle);
	// Get rotation components
	float rotSin = sin(angleRad), rotCos = cos(angleRad);
	// Generate rotated 2D axis as a 2x2 matrix
	return float2x2(
		 rotCos, rotSin, // Rotated space X axis
		-rotSin, rotCos  // Rotated space Y axis
	);
}
// Get blur radius
float getBlurRadius(float2 viewCoord)
{
	// Get rotation axis matrix
	const float2x2 rotationMtx = get2dRotationMatrix(BlurAngle);
	// Get offset vector
	static float2 offsetDir = mul(rotationMtx, float2(0f, BlurOffset)); // Get rotated offset
	offsetDir.x *= -BUFFER_ASPECT_RATIO; // Scale offset to horizontal bounds
	// Offset and rotate coordinates
	viewCoord = mul(rotationMtx, viewCoord+offsetDir);
	// Get anisotropic radius
	float4 radius;
	radius[0] = viewCoord.y*viewCoord.y; // r²
	radius[1] = radius[0]*radius[0]; // r⁴
	radius[2] = radius[1]*radius[0]; // r⁶
	radius[3] = radius[2]*radius[0]; // r⁸
	// Get blur strength in Brown-Conrady lens distortion division model
	return abs(1f-rcp(dot(radius, K)+1f));
}

/*--------------.
| :: Shaders :: |
'--------------*/

// Vertex shader generating a triangle covering the entire screen
void TiltShiftVS(
	in  uint   vertexId  : SV_VertexID,
	out float4 vertexPos : SV_Position,
	out float2 texCoord  : TEXCOORD0,
	out float2 viewCoord : TEXCOORD1)
{
	// Define vertex position
	const float2 vertexPosList[3] =
	{
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	// Export screen centered texture coordinates and vertex position,
	// correct aspect ratio of texture coordinates, normalize vertically
	viewCoord.x = (texCoord.x =   vertexPos.x = vertexPosList[vertexId].x)*BUFFER_ASPECT_RATIO;
	viewCoord.y =  texCoord.y = -(vertexPos.y = vertexPosList[vertexId].y);
	vertexPos.zw = float2(0f, 1f); // Export vertex position
	texCoord = texCoord*0.5+0.5; // Map to corner
}

// Horizontal dynamic blur pass
void TiltShiftPassHorizontalPS(
	in  float4 pixCoord  : SV_Position,
	in  float2 texCoord  : TEXCOORD0,
	in  float2 viewCoord : TEXCOORD1,
	out float3 color     : SV_Target)
{
	// Get blur radius
	float blurRadius = getBlurRadius(viewCoord);
	// Get blur pixel scale
	uint blurPixelCount = uint(ceil(blurRadius*BUFFER_HEIGHT));
	// Blur the background image
	if (blurPixelCount!=0u && any(K!=0f))
	{
		// Convert to even number and clamp to maximum sample count
		blurPixelCount = min(
			blurPixelCount+blurPixelCount%2u, // Convert to even
			abs(TILT_SHIFT_MAX_SAMPLES)-abs(TILT_SHIFT_MAX_SAMPLES)%2u // Convert to even
		);
		// Map blur horizontal radius to texture coordinates
		blurRadius *= BUFFER_HEIGHT*BUFFER_RCP_WIDTH; // Divide by aspect ratio
		float rcpWeightStep = rcp(blurPixelCount);
		float rcpOffsetStep = rcp(blurPixelCount*2u-1u);
		color = 0f; float cumulativeWeight = 0f; // Initialize
		for (uint i=1u; i<blurPixelCount*2u; i+=2u)
		{
			// Get step weight
			float weight = bellWeight(mad(i, rcpWeightStep, -1f));
			// Get step offset
			float offset = (i-1u)*rcpOffsetStep-0.5;
			color += GammaConvert::to_linear(tex2Dlod(
					BackBuffer,
					float4(blurRadius*offset+texCoord.x, texCoord.y, 0f, 0f) // Offset coordinates
				).rgb)*weight;
			cumulativeWeight += weight;
		}
		// Restore brightness
		color /= cumulativeWeight;
	}
	// Bypass blur
	else color = GammaConvert::to_linear(tex2Dfetch(BackBuffer, uint2(pixCoord.xy)).rgb);
	color = saturate(color); // Clamp values

	color = GammaConvert::to_display(color); // manual gamma
	// Dither output to increase perceivable picture bit-depth
	color = BlueNoise::dither(color, uint2(pixCoord.xy));
}

// Vertical dynamic blur pass
void TiltShiftPassVerticalPS(
	in  float4 pixCoord  : SV_Position,
	in  float2 texCoord  : TEXCOORD0,
	in  float2 viewCoord : TEXCOORD1,
	out float3 color     : SV_Target)
{
	// Get blur radius
	float blurRadius = getBlurRadius(viewCoord);
	// Get blur pixel scale
	uint blurPixelCount = uint(ceil(blurRadius*BUFFER_HEIGHT));
	// Blur the background image
	if (blurPixelCount!=0u && any(K!=0f))
	{
		// Convert to even number and clamp to maximum sample count
		blurPixelCount = min(
			blurPixelCount+blurPixelCount%2u, // Convert to even
			abs(TILT_SHIFT_MAX_SAMPLES)-abs(TILT_SHIFT_MAX_SAMPLES)%2u // Convert to even
		);
		float rcpWeightStep = rcp(blurPixelCount);
		float rcpOffsetStep = rcp(blurPixelCount*2u-1u);
		color = 0f; float cumulativeWeight = 0f; // Initialize
		for (uint i=1u; i<blurPixelCount*2u; i+=2u)
		{
			// Get step weight
			float weight = bellWeight(mad(i, rcpWeightStep, -1f));
			// Get step offset
			float offset = (i-1u)*rcpOffsetStep-0.5;
			color += GammaConvert::to_linear(
				tex2Dlod(
					BackBuffer,
					float4(texCoord.x, blurRadius*offset+texCoord.y, 0f, 0f) // Offset coordinates
				).rgb)*weight;
			cumulativeWeight += weight;
		}
		// Restore brightness
		color /= cumulativeWeight;
	}
	else // Bypass blur
		color = GammaConvert::to_linear(tex2Dfetch(BackBuffer, uint2(pixCoord.xy)).rgb);

	// Clamp values
	color = saturate(color);

	// Draw tilt-shift line
	if (VisibleLine)
	{
		const float2x2 rotationMtx = get2dRotationMatrix(BlurAngle);
		// Get offset vector
		const float2 offsetDir = mul(
			float2x2(-rotationMtx[0]*BUFFER_ASPECT_RATIO, rotationMtx[1]), // Scale offset to horizontal bounds
			float2(0f, BlurOffset) // Blur offset as vertical vector
		);
		// Scale rotation matrix to pixel size
		const float2x2 pixelRoationMtx = rotationMtx*BUFFER_HEIGHT*0.5; // Since coordinates are normalized vertically

		// Offset and rotate coordinates
		viewCoord = mul(pixelRoationMtx, viewCoord+offsetDir);
		// Generate line mask
		float lineHorizontal = saturate(
			 BlurLineWidth*0.5 // Line thickness from center
			-abs(viewCoord.y)  // Horizontal line
		);

		// Add center line to the image with offset color by 180°
		float lineColor = abs(ColorConvert::RGB_to_Luma(color)*2f-1f);
		color = lerp(
			color,
			GammaConvert::to_linear(lineColor), // manual gamma
			lineHorizontal
		);
	}

	// Manual gamma
	color = GammaConvert::to_display(color);
	// Dither output to increase perceivable picture bit-depth
	color = BlueNoise::dither(color, uint2(pixCoord.xy));
}

/*--------------.
| :: Output :: |
'--------------*/

technique TiltShift
<
	ui_label = "Tilt Shift";
	ui_tooltip =
		"Tilt shift blur effect.\n"
		"\n"
		"	· dynamic per-pixel sampling.\n"
		"	· minimal sample count.\n"
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY 3.0";
>
{
	pass GaussianBlurHorizontal
	{
		VertexShader = TiltShiftVS;
		PixelShader  = TiltShiftPassHorizontalPS;
	}
	pass GaussianBlurVerticalWithLine
	{
		VertexShader = TiltShiftVS;
		PixelShader  = TiltShiftPassVerticalPS;
	}
}
