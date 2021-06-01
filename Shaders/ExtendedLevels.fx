/**
 * Levels version 1.8
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
 * Added independent RGB channel levels that allow to fix impropely balanced console specific color space.
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
 * 
 * -- Version 1.7 --
 * Removed ACES and added linear Z-curve to avoid clipping. Optional Alt calculation added.
 *
 * -- Version 1.8
 * Previous version features was broken when i was sleepy, than i did not touch this shader for months and forgot what i did there.
 * So, i commented messed up code in hope to fix it later, and reintroduced ACES in useful way.
 */
 // Lightly optimized by Marot Satil for the GShade project.


#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

static const float PI = 3.141592653589793238462643383279f;


// Settings


uniform bool EnableLevels <
	ui_tooltip = "Enable or Disable Levels for TV <> PC or custome color range";
> = true;

uniform float3 InputBlackPoint <
	ui_type = "color";
	ui_tooltip = "The black point is the new black - literally. Everything darker than this will become completely black.";
> = float3(16/255.0f, 18/255.0f, 20/255.0f);

uniform float3 InputWhitePoint <
	ui_type = "color";
	ui_tooltip = "The new white point. Everything brighter than this becomes completely white";
> = float3(233/255.0f, 222/255.0f, 211/255.0f);

uniform float3 InputGamma <
	ui_type = "slider";
	ui_min = 0.001f; ui_max = 10.00f; step = 0.001f;
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

// Anti clipping measures

/*
uniform float3 MinBlackPoint <
	ui_type = "color";
	ui_min = 0.0f; ui_max = 0.5f;
	ui_tooltip = "If avoid clipping enabled this is the percentage break point relative to Output black. Anything lower than this will be compressed to fit into output range.";
> = float3(16/255.0f, 18/255.0f, 20/255.0f);

uniform float3 MinWhitePoint <
	ui_type = "color";
	ui_min = 0.5f; ui_max = 1.0f;
	ui_tooltip = "If avoid clipping enabled this is the percentage white point relative to Output white. Anything higher than this will be compressed to fit into output range.";
> = float3(233/255.0f/1.1f, 222/255.0f/1.1f, 211/255.0f/1.1f);
*/

uniform float3 ColorRangeShift <
	ui_type = "color";
	ui_tooltip = "Some games like Watch Dogs 2 has color range 16-235 downshifted to 0-219, so this option was added to upshift color range before expanding it. RGB value entered here will be just added to default color value. Negative values impossible at the moment in game, but can be added, in shader if downshifting needed. 0 disables shifting.";
> = float3(0/255.0f, 0/255.0f, 0/255.0f);

uniform int ColorRangeShiftSwitch <
	ui_type = "slider";
	ui_min = -1; ui_max = 1;
	ui_tooltip = "Workaround for lack of negative color values in Reshade UI: -1 to downshift, 1 to upshift, 0 to disable";
> = 0;

/*
uniform bool AvoidClipping <
	ui_tooltip = "Avoid pixels clip.";
> = false;

uniform bool AvoidClippingWhite <
	ui_tooltip = "Avoid white pixels clip.";
> = false;

uniform bool AvoidClippingBlack <
	ui_tooltip = "Avoid black pixels clip.";
> = false;

uniform bool SmoothCurve <
	ui_tooltip = "Improves contrast";
> = true;
*/

uniform bool ACEScurve <
	ui_tooltip = "Enable or Disable ACES for improved contrast and luminance";
> = false;

uniform int3 ACESLuminancePercentage <
	ui_type = "slider";
	ui_min = 75; ui_max = 175; step = 1;
	ui_tooltip = "Percentage of ACES Luminance. Can be used to avoid some color clipping.";
> = int3(100,100,100);


uniform bool HighlightClipping <
	ui_tooltip = "Colors between the two points will stretched, which increases contrast, but details above and below the points are lost (this is called clipping).\n0 Highlight the pixels that clip. Red = Some details are lost in the highlights, Yellow = All details are lost in the highlights, Blue = Some details are lost in the shadows, Cyan = All details are lost in the shadows.";
> = false;



// Helper functions

float3 ACESFilmRec2020( float3 x )
{
    x = x * ACESLuminancePercentage * 0.005f; // Restores luminance
    return ( x * ( 15.8f * x + 2.12f ) ) / ( x * ( 1.2f * x + 5.92f ) + 1.9f );
}

/*
float3 Smooth(float3 color, float3 inputwhitepoint, float3 inputblackpoint)
{
    //color = 
    return clamp((color - inputblackpoint)/(inputwhitepoint - inputblackpoint), 0.0, 1.0);
    //return pow(sin(PI * 0.5 * color),2);
}
*/

/*
float Curve(float x, float centerX, float centerY)
{
    if (centerX > 0  && centerX < 1 && centerY > 0  && centerY < 1) 
    {
      if (x < 0.5) 
      {
        return 0-pow(sin(PI * ((0-x)/4*(0-centerX))),2)*2*(0-centerY);
      } else if (x > 0.5) 
      {
        return 1-pow(sin(PI * ((1-x)/4*(1-centerX))),2)*2*(1-centerY);      
      } else 
      {
        return x;       
      }
    } else 
    {
      return x;
    }
}
*/

//RGB input levels
float3 InputLevels(float3 color, float3 inputwhitepoint, float3 inputblackpoint)
{
  return color = (color - inputblackpoint)/(inputwhitepoint - inputblackpoint);
  //return pow(sin(PI * 0.5 * color),2);
}

//RGB output levels
float3  Outputlevels(float3 color, float3 outputwhitepoint, float3 outputblackpoint)
{
  return color * (outputwhitepoint - outputblackpoint) + outputblackpoint;
}

//1 channel input level
float  InputLevel(float color, float inputwhitepoint, float inputblackpoint)
{
  return (color - inputblackpoint)/(inputwhitepoint - inputblackpoint);
}

//1 channel output level
float  Outputlevel(float color, float outputwhitepoint, float outputblackpoint)
{
  return color * (outputwhitepoint - outputblackpoint) + outputblackpoint;
}


// Main function

float3 LevelsPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
  const float3 InputColor = tex2D(ReShade::BackBuffer, texcoord).rgb;
  float3 OutputColor = InputColor;

  // outPixel = (pow(((inPixel * 255.0) - inBlack) / (inWhite - inBlack), inGamma) * (outWhite - outBlack) + outBlack) / 255.0; // Nvidia reference formula
  
  
	/*
	if (EnableLevels == true)
	{
		OutputColor = Outputlevels(pow(InputLevels(OutputColor + (ColorRangeShift * ColorRangeShiftSwitch), InputWhitePoint, InputBlackPoint), InputGamma), OutputWhitePoint, OutputBlackPoint);
  
		/*
		if (AvoidClipping == true)
		{
			if (AvoidClippingWhite == true)
			{
				//White
				// doest not give smooth gradient :-(
				const float3 OutputMaxWhitePoint = Outputlevels(pow(InputLevels(OutputWhitePoint + (ColorRangeShift * ColorRangeShiftSwitch), InputWhitePoint, InputBlackPoint), InputGamma), OutputWhitePoint, OutputBlackPoint);
				const float3 OutputMinWhitePoint = Outputlevels(pow(InputLevels(InputWhitePoint + (ColorRangeShift * ColorRangeShiftSwitch), InputWhitePoint, InputBlackPoint), InputGamma), OutputWhitePoint, OutputBlackPoint);

				if (OutputColor.r >= OutputMinWhitePoint.r)
					OutPutColor.r = Curve( InputColor.r, MinWhitePoint.r, OutputMinWhitePoint.r);

				if (OutputColor.g >= OutputMinWhitePoint.g)
					OutputColor.g = Curve( InputColor.g, MinWhitePoint.g, OutputMinWhitePoint.g);
      
				if (OutputColor.b >= OutputMinWhitePoint.b)
					OutputColor.b = Curve( InputColor.b, MinWhitePoint.b, OutputMinWhitePoint.b);
			}
    
			if (AvoidClippingBlack == true)
			{  
				//Black
				const float3 OutputMaxBlackPoint = pow(((0 + (ColorRangeShift * ColorRangeShiftSwitch)) - InputBlackPoint)/(InputWhitePoint - InputBlackPoint) , InputGamma) * (OutputWhitePoint - OutputBlackPoint) + OutputBlackPoint;  
				const float3 OutputMinBlackPoint = MinBlackPoint;
				const float3 OutputMinBlackPointY = pow(((OutputMinBlackPoint + (ColorRangeShift * ColorRangeShiftSwitch)) - InputBlackPoint)/(InputWhitePoint - InputBlackPoint) , InputGamma) * (OutputWhitePoint - OutputBlackPoint) + OutputBlackPoint;  

				if (OutputColor.r <= OutputMinBlackPoint.r)
					OutputColor.r = Curve(OutputMinBlackPoint.r,OutputMinBlackPointY.r,((OutputColor.r - OutputMaxBlackPoint.r)/(OutputMinBlackPoint.r - OutputMaxBlackPoint.r)) * (OutputMinBlackPoint.r - OutputBlackPoint.r) + OutputBlackPoint.r);

				if (OutputColor.g <= OutputMinBlackPoint.g)
					OutputColor.g = Curve(OutputMinBlackPoint.g,OutputMinBlackPointY.g,((OutputColor.g - OutputMaxBlackPoint.g)/(OutputMinBlackPoint.g - OutputMaxBlackPoint.g)) * (OutputMinBlackPoint.g - OutputBlackPoint.g) + OutputBlackPoint.g);

				if (OutputColor.b <= OutputMinBlackPoint.b)
					OutputColor.b = Curve(OutputMinBlackPoint.b,OutputMinBlackPointY.b,((OutputColor.b - OutputMaxBlackPoint.b)/(OutputMinBlackPoint.b - OutputMaxBlackPoint.b)) * (OutputMinBlackPoint.b - OutputBlackPoint.b) + OutputBlackPoint.b);
			}
		}
		//
	}
	*/
	
	if (EnableLevels == true)
	{
		OutputColor = pow(abs(((InputColor + (ColorRangeShift * ColorRangeShiftSwitch)) - InputBlackPoint)/(InputWhitePoint - InputBlackPoint)), InputGamma) * (OutputWhitePoint - OutputBlackPoint) + OutputBlackPoint;
	} else {
		OutputColor = InputColor;
	}
  
	if (ACEScurve == true)
	{
		OutputColor = ACESFilmRec2020(OutputColor);
	}  
  	 
	if (HighlightClipping == true)
	{
		float3 ClippedColor;

		// any colors whiter than white?
		if (any(OutputColor > saturate(OutputColor)))
			ClippedColor = float3(1.0, 1.0, 0.0);
		else
			ClippedColor = OutputColor;

		// all colors whiter than white?
		if (any(OutputColor > saturate(OutputColor)))
			ClippedColor = float3(1.0, 0.0, 0.0);
		else
			ClippedColor = OutputColor;

		// any colors blacker than black?
		if (any(OutputColor < saturate(OutputColor)))
			ClippedColor = float3(0.0, 1.0, 1.0);
		else
			ClippedColor = OutputColor;

		// all colors blacker than black?
		if (any(OutputColor < saturate(OutputColor)))
			ClippedColor = float3(0.0, 0.0, 1.0);
		else
			ClippedColor = OutputColor;

		OutputColor = ClippedColor;
	}

#if GSHADE_DITHER
	return OutputColor + TriDither(OutputColor, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return OutputColor;
#endif
}

technique ExtendedLevels
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = LevelsPass;
	} 
}


/*
for visualisation
https://www.desmos.com/calculator
\frac{\left(x-\frac{16}{255}\right)}{\left(\frac{233}{255}-\frac{16}{255}\ \right)}\cdot \left(\frac{255}{255}-0\right)+0

\left(\frac{\left(\left(\frac{\left(x-\frac{16}{255}\right)}{\left(\frac{233}{255}-\frac{16}{255}\ \right)}\cdot \left(\frac{255}{255}-0\right)+0\right)-\frac{250}{255}\right)}{\left(\left(\frac{\left(1-\frac{16}{255}\right)}{\left(\frac{233}{255}-\frac{16}{255}\ \right)}\cdot \left(\frac{255}{255}-0\right)+0\right)-\frac{250}{255}\ \right)}\cdot \left(\frac{255}{255}-\frac{250}{255}\right)+\frac{250}{255}\right)

\left(\frac{\left(\left(\frac{\left(x-\frac{16}{255}\right)}{\left(\frac{233}{255}-\frac{16}{255}\ \right)}\cdot \left(\frac{255}{255}-0\right)+0\right)-\left(\frac{\left(0-\frac{16}{255}\right)}{\left(\frac{233}{255}-\frac{16}{255}\ \right)}\cdot \left(\frac{255}{255}-0\right)+0\right)\right)}{\left(\frac{5}{255}-\left(\frac{\left(0-\frac{16}{255}\right)}{\left(\frac{233}{255}-\frac{16}{255}\ \right)}\cdot \left(\frac{255}{255}-0\right)+0\right)\right)}\cdot \left(\frac{5}{255}-\frac{0}{255}\right)+0\right)

// 
//this is for x,y<0.5
\left(\sin (\pi *\left(-\frac{x}{4\cdot 0.1352}\right))^2\right)\cdot 2\cdot 0.0782

\left(\sin (\pi *\left(-\frac{x}{4\cdot [black point curve break\center] x}\right))^2\right)\cdot 2\cdot [black point curve break\center] y

//this is for x,y>0.5

1-\left(\sin (\pi *\left(-\frac{1-x}{4\cdot \left(1-0.8528\right)}\right))^2\right)\cdot 2\cdot \left(1-0.9137\right)

1-\left(\sin (\pi *\left(-\frac{1-x}{4\cdot \left(1-[white point curve break\center] x\right)}\right))^2\right)\cdot 2\cdot \left(1-[white point curve break\center] y\right)

*/