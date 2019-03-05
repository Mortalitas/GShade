/**
 * Levels version 1.6
 * by Christian Cann Schuldt Jensen ~ CeeJay.dk
 * updated to 1.3+ by Kirill Yarovoy ~ v00d00m4n
 *
 * Allows you to set a new black and a white level.
 * This increases contrast, but clips any colors outside the new range to either black or white
 * and so some details in the shadows or highlights can be lost.
 *
 * The shader is very useful for expanding the 16-235 TV range to 0-255 PC range.
 * You might need it if you're playing a game meant to display on a TV with an emulator that does not do this.
 * But it's also a quick and easy way to uniformly increase the contrast of an image.
 *
 * -- Version 1.0 --
 * First release
 * -- Version 1.1 --
 * Optimized to only use 1 instruction (down from 2 - a 100% performance increase :) )
 * -- Version 1.2 --
 * Added the ability to highlight clipping regions of the image with #define HighlightClipping 1
 * 
 * -- Version 1.3 --
 * Added inddependant RGB channel levels that allow to fix impropely balanced console specific color space.
 * 
 * Most of modern Xbox One \ PS4 ports has white point around 233 222 211 instead of TV 235 235 235
 * which can be seen and aproximated by analyzing histograms of hundreds of hudless screenshots of modern games
 * including big titles such as GTAV, Witcher 3, Watch_Dogs, most of UE4 based titles and so on.
 * 
 * Most of these games lacking true balanced white and black colors and looks like if you play on very old and dusty display.
 * This problem could be related to improper usage and settings of popular FILMIC shader, introduced in Uncharted 2.
 *
 * I used to prebake static luts to restore color balance, but doing so in image editors was slow, so once i discovered
 * that Reshade 3 has RGB UI settings i decided that dynamic in-game correction would be more productive, so i updated this
 * old shader to correct color mess in game. I can spot white oddities wiht my naked eyes, but i suggest to combine this shader
 * with Ganossa Histogram shader, loaded after levels for this, but you need to update it for Rehade 3 and get it here:
 * https://github.com/crosire/reshade-shaders/blob/382b28f33034809e52513332ca36398e72563e10/ReShade/Shaders/Ganossa/Histogram.fx
 *
 * -- Version 1.4 --
 * Added ability to upshift color range before expanding it. Needed to fix stupid Ubisoft mistake in Watch Dogs 2 where they
 * somehow downshifted color range.
 * 
 * -- Version 1.5 --
 * Changed formulas to allow gamma and output range controls.
 * 
 * -- Version 1.6 --
 * Added ACES curve, to avoid clipping.
 */


// Settings

uniform float3 InputBlackPoint <
	ui_type = "color";
	ui_tooltip = "The black point is the new black - literally. Everything darker than this will become completely black.";
> = float3(16/255.0f, 18/255.0f, 20/255.0f);

uniform float3 InputWhitePoint <
	ui_type = "color";
	ui_tooltip = "The new white point. Everything brighter than this becomes completely white";
> = float3(233/255.0f, 222/255.0f, 211/255.0f);

uniform float3 InputGamma <
	ui_type = "drag";
	ui_min = 0.33f; ui_max = 3.00f;
	ui_label = "RGB Gamma";
	ui_tooltip = "Adjust midtones for Red, Green and Blue.";
> = float3(1.00f,1.00f,1.00f);

uniform float3 OutputBlackPoint <
	ui_type = "color";
	ui_tooltip = "The black point is the new black - literally. Everything darker than this will become completely black.";
> = float3(0/255.0f, 0/255.0f, 0/255.0f);

uniform float3 OutputWhitePoint <
	ui_type = "color";
	ui_tooltip = "The new white point. Everything brighter than this becomes completely white";
> = float3(255/255.0f, 255/255.0f, 255/255.0f);

uniform float3 ColorRangeShift <
	ui_type = "color";
	ui_tooltip = "Some games like Watch Dogs 2 has color range 16-235 downshifted to 0-219, so this option was added to upshift color range before expanding it. RGB value entered here will be just added to default color value. Negative values impossible at the moment in game, but can be added, in shader if downshifting needed. 0 disables shifting.";
> = float3(0/255.0f, 0/255.0f, 0/255.0f);

uniform int ColorRangeShiftSwitch <
	ui_type = "drag";
	ui_min = -1; ui_max = 1;
	ui_tooltip = "Workaround for lack of negative color values in Reshade UI: -1 to downshift, 1 to upshift, 0 to disable";
> = 0;

uniform bool AvoidClipping <
	ui_tooltip = "Avoids the pixels that clip.";
> = false;

uniform bool HighlightClipping <
	ui_tooltip = "Colors between the two points will be stretched, which increases contrast, but details above and below the points are lost (this is called clipping). Highlight the pixels that clip. Yellow = Some details lost in the highlights, Red = All details lost in the highlights, Cyan = Some details lost in the shadows, Blue = All details lost in the shadows.";
> = false;

// Helper functions

#include "ReShade.fxh"
 
float3 ACESFilmRec2020( float3 x )
{
    float a = 15.8f;
    float b = 2.12f;
    float c = 1.2f;
    float d = 5.92f;
    float e = 1.9f;
    x = x * 0.49f; // Restores luminance
    return ( x * ( a * x + b ) ) / ( x * ( c * x + d ) + e );
}

// Main function

float3 LevelsPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
 
	float3 InputColor = tex2D(ReShade::BackBuffer, texcoord).rgb;

  float3 OutputColor = pow(abs(((InputColor + (ColorRangeShift * ColorRangeShiftSwitch)) - InputBlackPoint))/(abs(InputWhitePoint - InputBlackPoint)) , InputGamma) * (OutputWhitePoint - OutputBlackPoint) + OutputBlackPoint;

  if (AvoidClipping == true)
	{
   OutputColor = ACESFilmRec2020(OutputColor);
  }  
  
  
	if (HighlightClipping == true)
	{
		float3 ClippedColor;

		ClippedColor = any(OutputColor > saturate(OutputColor)) // any colors whiter than white?
			? float3(1.0, 1.0, 0.0)
			: OutputColor;
		ClippedColor = all(OutputColor > saturate(OutputColor)) // all colors whiter than white?
			? float3(1.0, 0.0, 0.0)
			: ClippedColor;
		ClippedColor = any(OutputColor < saturate(OutputColor)) // any colors blacker than black?
			? float3(0.0, 1.0, 1.0)
			: ClippedColor;
		ClippedColor = all(OutputColor < saturate(OutputColor)) // all colors blacker than black?
			? float3(0.0, 0.0, 1.0)
			: ClippedColor;

		OutputColor = ClippedColor;
	}


	return OutputColor;
}

technique ExtendedLevels
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LevelsPass;
	}
}