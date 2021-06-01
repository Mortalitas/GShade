/*
Tilt-Shift PS v1.2.0 (c) 2018 Jacob Maximilian Fober,
(based on TiltShift effect (c) 2016 kingeric1992)
Modified by Marot for ReShade 4.x compatibility.

This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/4.0/.
*/


	  ////////////
	 /// MENU ///
	////////////


uniform bool Line <
	ui_label = "Show Center Line";
> = false;

uniform int Axis <
	ui_label = "Angle";
	ui_type = "slider";
	ui_step = 1;
	ui_min = -89; ui_max = 90;
> = 0;

uniform float Offset <
	ui_type = "slider";
	ui_min = -1.41; ui_max = 1.41; ui_step = 0.01;
> = 0.05;

uniform float BlurCurve <
	ui_label = "Blur Curve";
	ui_type = "slider";
	ui_min = 1.0; ui_max = 5.0; ui_step = 0.01;
	ui_label = "Blur Curve";
> = 1.0;
uniform float BlurMultiplier <
	ui_label = "Blur Multiplier";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 100.0; ui_step = 0.2;
> = 6.0;

uniform int BlurSamples <
	ui_label = "Blur Samples";
	ui_type = "slider";
	ui_min = 2; ui_max = 32;
> = 11;

// First pass render target, to make sure Alpha channel exists
texture TiltShiftTarget < pooled = true; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler TiltShiftSampler { Texture = TiltShiftTarget; };


	  /////////////////
	 /// FUNCTIONS ///
	/////////////////

// Overlay filter by Fubax
// Generates smooth falloff for blur
// input is between 0-1
float get_weight(float t)
{
	const float bottom = min(t, 0.5);
	const float top = max(t, 0.5);
	return 2.0 *(bottom*bottom +top +top -top*top) -1.5;
}

	  //////////////
	 /// SHADER ///
	//////////////

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

void TiltShiftPass1PS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float4 Image : SV_Target)
{
	// Grab screen texture
	Image.rgb = tex2D(ReShade::BackBuffer, UvCoord).rgb;
	// Correct Aspect Ratio
	float2 UvCoordAspect = UvCoord;
	UvCoordAspect.y += ReShade::AspectRatio * 0.5 - 0.5;
	UvCoordAspect.y /= ReShade::AspectRatio;
	// Center coordinates
	UvCoordAspect = UvCoordAspect * 2.0 - 1.0;
	// Tilt vector
	const float Angle = radians(-Axis);
	const float2 TiltVector = float2(sin(Angle), cos(Angle));
	// Blur mask
	float BlurMask = abs(dot(TiltVector, UvCoordAspect) + Offset);
	BlurMask = max(0.0, min(1.0, BlurMask));
		// Set alpha channel
		Image.a = BlurMask;
	BlurMask = pow(Image.a, BlurCurve);

	// Horizontal blur
	if(BlurMask > 0)
	{
		// Get offset for this pixel
		const float UvOffset = ReShade::PixelSize.x *BlurMask *BlurMultiplier;
		// Set initial weight for first dry single sample
		float total_weight = 0.5;
		// Blur with dynamic samples
		for (int i=1; i<BlurSamples; i++)
		{
			// Get current sample
			const float current_sample = float(i)/float(BlurSamples);
			// Get current sample weight
			const float current_weight = get_weight(1.0-current_sample);
			// Add to total weight
			total_weight += current_weight;
			// Get current sample offset
			const float SampleOffset = current_sample*11.0 * UvOffset; // (*11.0) to maintain version compatibility
			// Add blur samples
			Image.rgb += (
				 tex2Dlod( ReShade::BackBuffer, float4(float2(UvCoord.x+SampleOffset, UvCoord.y), 0.0, 0.0) ).rgb
				+tex2Dlod( ReShade::BackBuffer, float4(float2(UvCoord.x-SampleOffset, UvCoord.y), 0.0, 0.0) ).rgb
			) *current_weight;
		}
		// Normalize
		Image.rgb /= total_weight*2.0;
	}
}

void TiltShiftPass2PS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD, out float4 Image : SV_Target)
{
	// Grab second pass screen texture
	Image = tex2D(TiltShiftSampler, UvCoord);
	// Blur mask
	float BlurMask = pow(abs(Image.a), BlurCurve);
	// Vertical blur
	if(BlurMask > 0)
	{
		// Get offset for this pixel
		const float UvOffset = ReShade::PixelSize.y *BlurMask *BlurMultiplier;
		// Set initial weight for first dry single sample
		float total_weight = 0.5;
		// Blur with dynamic samples
		for (int i=1; i<BlurSamples; i++)
		{
			// Get current sample
			const float current_sample = float(i)/float(BlurSamples);
			// Get current sample weight
			const float current_weight = get_weight(1.0-current_sample);
			// Add to total weight
			total_weight += current_weight;
			// Get current sample offset
			const float SampleOffset = current_sample*11.0 * UvOffset; // (*11.0) to maintain version compatibility
			// Add blur samples
			Image.rgb += (
				 tex2Dlod( TiltShiftSampler, float4(float2(UvCoord.x, UvCoord.y+SampleOffset), 0.0, 0.0) ).rgb
				+tex2Dlod( TiltShiftSampler, float4(float2(UvCoord.x, UvCoord.y-SampleOffset), 0.0, 0.0) ).rgb
			) *current_weight;
		}
		// Normalize
		Image.rgb /= total_weight*2.0;
	}
	// Draw red line
	// Image IS Red IF (Line IS True AND Image.a < 0.01), ELSE Image IS Image
	if (Line && Image.a < 0.01)
		Image.rgb = float3(1.0, 0.0, 0.0);

#if GSHADE_DITHER
	Image.rgb += TriDither(Image.rgb, UvCoord, BUFFER_COLOR_BIT_DEPTH);
#endif
}


	  //////////////
	 /// OUTPUT ///
	//////////////

technique TiltShift < ui_label = "Tilt Shift"; >
{
	pass AlphaAndHorizontalGaussianBlur
	{
		VertexShader = PostProcessVS;
		PixelShader = TiltShiftPass1PS;
		RenderTarget = TiltShiftTarget;
	}
	pass VerticalGaussianBlurAndRedLine
	{
		VertexShader = PostProcessVS;
		PixelShader = TiltShiftPass2PS;
	}
}
