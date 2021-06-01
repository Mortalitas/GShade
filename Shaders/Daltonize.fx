/**
 * Daltonization algorithm by daltonize.org
 * http://www.daltonize.org/2010/05/lms-daltonization-algorithm.html
 * Originally ported to ReShade by IDDQD, modified for ReShade 3.0 by crosire
 */
 // Lightly optimized by Marot Satil for the GShade project alongside some additional hue adjustment options.

uniform int Type <
	ui_type = "combo";
	ui_items = "Protanopia\0Deuteranopia\0Tritanopia\0";
> = 0;

uniform float RedAdjust <
	ui_label = "Base Red Adjustment";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0.001;
	ui_max = 2.0;
> = 1.0;

uniform float GreenAdjust <
	ui_label = "Base Green Adjustment";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0.001;
	ui_max = 2.0;
> = 1.0;

uniform float BlueAdjust <
	ui_label = "Base Blue Adjustment";
	ui_type = "slider";
	ui_step = 0.001;
	ui_min = 0.001;
	ui_max = 2.0;
> = 1.0;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 PS_DaltonizeFXmain(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 input = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
	input.r = input.r * RedAdjust;
	
	input.g = input.g * GreenAdjust;
	
	input.b = input.b * BlueAdjust;

	// RGB to LMS matrix conversion
	const float OnizeL = (17.8824f * input.r) + (43.5161f * input.g) + (4.11935f * input.b);
	const float OnizeM = (3.45565f * input.r) + (27.1554f * input.g) + (3.86714f * input.b);
	const float OnizeS = (0.0299566f * input.r) + (0.184309f * input.g) + (1.46709f * input.b);
	
	// Simulate color blindness
	float Daltl, Daltm, Dalts;

	if (Type == 0) // Protanopia - reds are greatly reduced (1% men)
	{
		Daltl = 0.0f * OnizeL + 2.02344f * OnizeM + -2.52581f * OnizeS;
		Daltm = 0.0f * OnizeL + 1.0f * OnizeM + 0.0f * OnizeS;
		Dalts = 0.0f * OnizeL + 0.0f * OnizeM + 1.0f * OnizeS;
	}
	else if (Type == 1) // Deuteranopia - greens are greatly reduced (1% men)
	{
		Daltl = 1.0f * OnizeL + 0.0f * OnizeM + 0.0f * OnizeS;
		Daltm = 0.494207f * OnizeL + 0.0f * OnizeM + 1.24827f * OnizeS;
		Dalts = 0.0f * OnizeL + 0.0f * OnizeM + 1.0f * OnizeS;
	}
	else if (Type == 2) // Tritanopia - blues are greatly reduced (0.003% population)
	{
		Daltl = 1.0f * OnizeL + 0.0f * OnizeM + 0.0f * OnizeS;
		Daltm = 0.0f * OnizeL + 1.0f * OnizeM + 0.0f * OnizeS;
		Dalts = -0.395913f * OnizeL + 0.801109f * OnizeM + 0.0f * OnizeS;
	}
	
	// LMS to RGB matrix conversion
	// Isolate invisible colors to color vision deficiency (calculate error matrix)
	const float3 error = input - float3((0.0809444479f * Daltl) + (-0.130504409f * Daltm) + (0.116721066f * Dalts), (-0.0102485335f * Daltl) + (0.0540193266f * Daltm) + (-0.113614708f * Dalts), (-0.000365296938f * Daltl) + (-0.00412161469f * Daltm) + (0.693511405f * Dalts));
	
	// Shift colors towards visible spectrum (apply error modifications) & add compensation to original values
#if GSHADE_DITHER
	input = input + float3(0, (error.r * 0.7) + (error.g * 1.0), (error.r * 0.7) + (error.b * 1.0));
	return input + TriDither(input, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return input + float3(0, (error.r * 0.7) + (error.g * 1.0), (error.r * 0.7) + (error.b * 1.0));
#endif
}

technique Daltonize
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_DaltonizeFXmain;
	}
}
