/*------------------.
| :: Description :: |
'-------------------/

	Monochrome (version 1.1)

	Author: CeeJay.dk
	License: MIT

	About:
	Removes color making everything monochrome.

	Ideas for future improvement:
	* Tinting
	* Select a hue to keep its color, thus making it stand out against a monochrome background
	* Try Lab colorspace
	* Apply color gradient
	* Add an option to normalize the coefficients
	* Publish best-selling book titled "256 shades of grey"

	History:
	(*) Feature (+) Improvement	(x) Bugfix (-) Information (!) Compatibility
	
	Version 1.0
	* Converts image to monochrome
	* Allows users to add saturation back in.

	Version 1.1 
	* Added many presets based on B/W camera films
	+ Improved settings UI
	! Made settings backwards compatible with SweetFX


	The MIT License (MIT)

	Copyright (c) 2014 CeeJayDK

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/
// Lightly optimized by Marot Satil for the GShade project.


/*---------------.
| :: Includes :: |
'---------------*/

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform int Monochrome_preset <
	ui_type = "combo";
	ui_label = "Preset";
	ui_tooltip = "Choose a preset";
	//ui_category = "";
	ui_items = "Custom\0"
	"Monitor or modern TV\0"
	"Equal weight\0"
	"Agfa 200X\0"
	"Agfapan 25\0"
	"Agfapan 100\0"
	"Agfapan 400\0"
	"Ilford Delta 100\0"
	"Ilford Delta 400\0"
	"Ilford Delta 400 Pro & 3200\0"
	"Ilford FP4\0"
	"Ilford HP5\0"
	"Ilford Pan F\0"
	"Ilford SFX\0"
	"Ilford XP2 Super\0"
	"Kodak Tmax 100\0"
	"Kodak Tmax 400\0"
	"Kodak Tri-X\0";
> = 0;

uniform float3 Monochrome_conversion_values <
	ui_type = "color";
	ui_label = "Custom Conversion values";
> = float3(0.21, 0.72, 0.07);

/*
uniform bool Normalize <
	ui_label = "Normalize";
	ui_tooltip = "Normalize the coefficients?";
> = false;
*/

uniform float Monochrome_color_saturation <
	ui_label = "Saturation";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
> = 0.0;

float3 MonochromePass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	float3 Coefficients = float3(0.21, 0.72, 0.07);

	const float3 Coefficients_array[18] = 
	{
		Monochrome_conversion_values, //Custom
		float3(0.21, 0.72, 0.07), //sRGB monitor
		float3(0.3333333, 0.3333334, 0.3333333), //Equal weight
		float3(0.18, 0.41, 0.41), //Agfa 200X
		float3(0.25, 0.39, 0.36), //Agfapan 25
		float3(0.21, 0.40, 0.39), //Agfapan 100
		float3(0.20, 0.41, 0.39), //Agfapan 400 
		float3(0.21, 0.42, 0.37), //Ilford Delta 100
		float3(0.22, 0.42, 0.36), //Ilford Delta 400
		float3(0.31, 0.36, 0.33), //Ilford Delta 400 Pro & 3200
		float3(0.28, 0.41, 0.31), //Ilford FP4
		float3(0.23, 0.37, 0.40), //Ilford HP5
		float3(0.33, 0.36, 0.31), //Ilford Pan F
		float3(0.36, 0.31, 0.33), //Ilford SFX
		float3(0.21, 0.42, 0.37), //Ilford XP2 Super
		float3(0.24, 0.37, 0.39), //Kodak Tmax 100
		float3(0.27, 0.36, 0.37), //Kodak Tmax 400
		float3(0.25, 0.35, 0.40) //Kodak Tri-X
	};

	Coefficients = Coefficients_array[Monochrome_preset];

	// Calculate monochrome
	const float3 grey = dot(Coefficients, color);

	// Adjust the remaining saturation & return the result
#if GSHADE_DITHER
	Coefficients = saturate(lerp(grey, color, Monochrome_color_saturation));
	return Coefficients + TriDither(Coefficients, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return saturate(lerp(grey, color, Monochrome_color_saturation));
#endif
}

technique Monochrome
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MonochromePass;
	}
}
