/** Local Contrast PS, version 0.2.1
All rights (c) 2020 Jakub Maksymilian Fober (the Author).

The Author provides this shader (the Work)
under the Creative Commons CC BY-SA 3.0 license
available online at
http://creativecommons.org/licenses/by-sa/3.0/

For inquiries please contact jakub.m.fober@pm.me
*/


#include "ReShade.fxh"


  ////////////
 /// MENU ///
////////////

#if !defined(LC_BLOCK)
	#define LC_BLOCK 8
#endif

uniform bool CorrectGamma <
	ui_label = "Perform gamma correction";
	ui_tootlip = "Applies S-curve to the corrected luma channel";
> = true;

uniform int ContrastLimit <
	ui_type = "slider";
	ui_label = "Contrast limit";
	ui_min = 0; ui_max = 63;
> = 40;


  ///////////////
 /// TEXTURE ///
///////////////

// Local histogram values map
texture LocalContrastMapBuffer
{
	Width = BUFFER_WIDTH/LC_BLOCK;
	Height = BUFFER_HEIGHT/LC_BLOCK;
	Format = RG8;
	// R = histogram luma min
	// G = histogram luma max
};
sampler LocalContrastMap { Texture = LocalContrastMapBuffer; };

// Point mapping back-buffer sampler
sampler BackBuffer { Texture = ReShade::BackBufferTex; };

  /////////////////
 /// FUNCTIONS ///
/////////////////

// RGB to YUV709
static const float3x3 ToYUV709 =
float3x3(
	float3(0.2126, 0.7152, 0.0722),
	float3(-0.09991, -0.33609, 0.436),
	float3(0.615, -0.55861, -0.05639)
);
// RGB to YUV601
static const float3x3 ToYUV601 =
float3x3(
	float3(0.299, 0.587, 0.114),
	float3(-0.14713, -0.28886, 0.436),
	float3(0.615, -0.51499, -0.10001)
);
// YUV709 to RGB
static const float3x3 ToRGB709 =
float3x3(
	float3(1, 0, 1.28033),
	float3(1, -0.21482, -0.38059),
	float3(1, 2.12798, 0)
);
// YUV601 to RGB
static const float3x3 ToRGB601 =
float3x3(
	float3(1, 0, 1.13983),
	float3(1, -0.39465, -0.58060),
	float3(1, 2.03211, 0)
);

// Overlay filter by Fubax
// Generates smooth s-curve
// input is between 0-1
float weight(float gradient)
{
	float bottom = min(gradient, 0.5);
	float top = max(gradient, 0.5);
	return 2.0 *(bottom*bottom +top +top -top*top) -1.5;
}
// Convert map slider range
float getContrastLimit()
{ return 1.0-ContrastLimit/127.0; }


  //////////////
 /// SHADER ///
//////////////

// Analyze histogram per image block
void GetLocalHistogramPS(
	float4 pos : SV_Position,
	float2 texcoord : TEXCOORD,
	out float2 histogramStats : SV_Target // Contrast-limited adaptive histogram
){
	// Initial values of the histogram
	histogramStats.s = 1.0; // Min
	histogramStats.t = 0.0; // Max
	float histogramMean = 0.0; // Average
	// Loop through image block and get histogram min, max and average
	const int halfBlock = LC_BLOCK/2;
	for (int y=-halfBlock; y<halfBlock; y++)
	for (int x=-halfBlock; x<halfBlock; x++)
	{
		// Get luminosity of background picture pixel of a block
		float luma = dot(ToYUV709[0], tex2D(BackBuffer, BUFFER_PIXEL_SIZE*float2(x, y)+texcoord).rgb);
		// Save histogram data of the block
		histogramStats.s = min(luma, histogramStats.s); // Min
		histogramStats.t = max(luma, histogramStats.t); // Max
		histogramMean += luma; // Average
	}
	histogramMean /= LC_BLOCK*LC_BLOCK;
	// Contrast limiting
	const float contrastLimit = getContrastLimit();
	histogramStats.s = min(histogramStats.s, max(0.0, histogramMean-contrastLimit));
	histogramStats.t = max(histogramStats.t, min(1.0, histogramMean+contrastLimit));
}


// Apply local contrast to image
void LocalConstrastPS(
	float4 pos : SV_Position,
	float2 texcoord : TEXCOORD,
	out float3 result : SV_Target
){
	// Get background color in YUV
	result = mul(ToYUV709, tex2D(BackBuffer, texcoord).rgb);
	// Get local contrast map
	const float2 localContrast = tex2D(LocalContrastMap, texcoord).st;
	// Histogram normalization of luma channel
	result.s = (result.s-localContrast.s)/(localContrast.t-localContrast.s);
	// S-curve correction
	if (CorrectGamma)
	{
		float s_curve = 2.0-getContrastLimit()*2.0;
		s_curve *= s_curve*s_curve; // Power 3
		result.s = lerp(result.s, weight(result.s), s_curve);
	}
	// Convert to RGB
	result = mul(ToRGB709, result);
}


  //////////////
 /// OUTPUT ///
//////////////

technique LocalContrast <
	ui_label = "Local Contrast";
	ui_tooltip =
		"CLAHE (contrast-limited adaptive histogram normalization)\n"
		"\n"
		"To change block size, edit global preprocessor definition:\n"
		"\tLC_BLOCK\tdefault is 8"; >
{
	pass Local_Histogram
	{
		VertexShader = PostProcessVS;
		PixelShader = GetLocalHistogramPS;
		RenderTarget = LocalContrastMapBuffer;
	}
	pass Historgram_Normalization
	{
		VertexShader = PostProcessVS;
		PixelShader = LocalConstrastPS;
	}
}
