/*
	Spotlight shader based on the Flashlight shader by luluco250

	MIT Licensed.

  Modifications by ninjafada and Marot Satil
*/

#include "ReShade.fxh"
#include "Spotlight.fxh"

uniform int Spotlight_Quantity <
	ui_type = "combo";
	ui_label = "Number of Spotlights";
	ui_tooltip = "The number of Spotlight techniques to generate. Enabling too many of these in a DirectX 9 game or on lower end hardware is a very, very bad idea.";
	ui_items =  "1\0"
				"2\0"
				"3\0"
				"4\0"
				"5\0"
				"6\0"
				"7\0"
				"8\0"
				"9\0"
				"10\0"
				"11\0"
				"12\0"
				"13\0"
				"14\0"
				"15\0"
				"16\0"
				"17\0"
				"18\0"
				"19\0"
				"20\0";
	ui_bind = "SPOTLIGHT_QUANTITY";
> = 0;

#ifndef SPOTLIGHT_QUANTITY
	#define SPOTLIGHT_QUANTITY 0
#endif

SPOTLIGHT_SUMMONING("Spotlight 1", uXCenter, uYCenter, uBrightness, uSize, uColor, uInvertDepthCutoff, uDepthCutoff, uDistance, uBlendFix, uToggleTexture, uToggleDepth, uToggleDepthCutoff, PS_Spotlight, Spotlight)

#if SPOTLIGHT_QUANTITY > 0
	SPOTLIGHT_SUMMONING("Spotlight 2", u2XCenter, u2YCenter, u2Brightness, u2Size, u2Color, u2InvertDepthCutoff, u2DepthCutoff, u2Distance, u2BlendFix, u2ToggleTexture, u2ToggleDepth, u2ToggleDepthCutoff, PS_Spotlight2, Spotlight2)
#endif

#if SPOTLIGHT_QUANTITY > 1
	SPOTLIGHT_SUMMONING("Spotlight 3", u3XCenter, u3YCenter, u3Brightness, u3Size, u3Color, u3InvertDepthCutoff, u3DepthCutoff, u3Distance, u3BlendFix, u3ToggleTexture, u3ToggleDepth, u3ToggleDepthCutoff, PS_Spotlight3, Spotlight3)
#endif

#if SPOTLIGHT_QUANTITY > 2
	SPOTLIGHT_SUMMONING("Spotlight 4", u4XCenter, u4YCenter, u4Brightness, u4Size, u4Color, u4InvertDepthCutoff, u4DepthCutoff, u4Distance, u4BlendFix, u4ToggleTexture, u4ToggleDepth, u4ToggleDepthCutoff, PS_Spotlight4, Spotlight4)
#endif

#if SPOTLIGHT_QUANTITY > 3
	SPOTLIGHT_SUMMONING("Spotlight 5", u5XCenter, u5YCenter, u5Brightness, u5Size, u5Color, u5InvertDepthCutoff, u5DepthCutoff, u5Distance, u5BlendFix, u5ToggleTexture, u5ToggleDepth, u5ToggleDepthCutoff, PS_Spotlight5, Spotlight5)
#endif

#if SPOTLIGHT_QUANTITY > 4
	SPOTLIGHT_SUMMONING("Spotlight 6", u6XCenter, u6YCenter, u6Brightness, u6Size, u6Color, u6InvertDepthCutoff, u6DepthCutoff, u6Distance, u6BlendFix, u6ToggleTexture, u6ToggleDepth, u6ToggleDepthCutoff, PS_Spotlight6, Spotlight6)
#endif

#if SPOTLIGHT_QUANTITY > 5
	SPOTLIGHT_SUMMONING("Spotlight 7", u7XCenter, u7YCenter, u7Brightness, u7Size, u7Color, u7InvertDepthCutoff, u7DepthCutoff, u7Distance, u7BlendFix, u7ToggleTexture, u7ToggleDepth, u7ToggleDepthCutoff, PS_Spotlight7, Spotlight7)
#endif

#if SPOTLIGHT_QUANTITY > 6
	SPOTLIGHT_SUMMONING("Spotlight 8", u8XCenter, u8YCenter, u8Brightness, u8Size, u8Color, u8InvertDepthCutoff, u8DepthCutoff, u8Distance, u8BlendFix, u8ToggleTexture, u8ToggleDepth, u8ToggleDepthCutoff, PS_Spotlight8, Spotlight8)
#endif

#if SPOTLIGHT_QUANTITY > 7
	SPOTLIGHT_SUMMONING("Spotlight 9", u9XCenter, u9YCenter, u9Brightness, u9Size, u9Color, u9InvertDepthCutoff, u9DepthCutoff, u9Distance, u9BlendFix, u9ToggleTexture, u9ToggleDepth, u9ToggleDepthCutoff, PS_Spotlight9, Spotlight9)
#endif

#if SPOTLIGHT_QUANTITY > 8
	SPOTLIGHT_SUMMONING("Spotlight 10", u10XCenter, u10YCenter, u10Brightness, u10Size, u10Color, u10InvertDepthCutoff, u10DepthCutoff, u10Distance, u10BlendFix, u10ToggleTexture, u10ToggleDepth, u10ToggleDepthCutoff, PS_Spotlight10, Spotlight10)
#endif

#if SPOTLIGHT_QUANTITY > 9
	SPOTLIGHT_SUMMONING("Spotlight 11", u11XCenter, u11YCenter, u11Brightness, u11Size, u11Color, u11InvertDepthCutoff, u11DepthCutoff, u11Distance, u11BlendFix, u11ToggleTexture, u11ToggleDepth, u11ToggleDepthCutoff, PS_Spotlight11, Spotlight11)
#endif

#if SPOTLIGHT_QUANTITY > 10
	SPOTLIGHT_SUMMONING("Spotlight 12", u12XCenter, u12YCenter, u12Brightness, u12Size, u12Color, u12InvertDepthCutoff, u12DepthCutoff, u12Distance, u12BlendFix, u12ToggleTexture, u12ToggleDepth, u12ToggleDepthCutoff, PS_Spotlight12, Spotlight12)
#endif

#if SPOTLIGHT_QUANTITY > 11
	SPOTLIGHT_SUMMONING("Spotlight 13", u13XCenter, u13YCenter, u13Brightness, u13Size, u13Color, u13InvertDepthCutoff, u13DepthCutoff, u13Distance, u13BlendFix, u13ToggleTexture, u13ToggleDepth, u13ToggleDepthCutoff, PS_Spotlight13, Spotlight13)
#endif

#if SPOTLIGHT_QUANTITY > 12
	SPOTLIGHT_SUMMONING("Spotlight 14", u14XCenter, u14YCenter, u14Brightness, u14Size, u14Color, u14InvertDepthCutoff, u14DepthCutoff, u14Distance, u14BlendFix, u14ToggleTexture, u14ToggleDepth, u14ToggleDepthCutoff, PS_Spotlight14, Spotlight14)
#endif

#if SPOTLIGHT_QUANTITY > 13
	SPOTLIGHT_SUMMONING("Spotlight 15", u15XCenter, u15YCenter, u15Brightness, u15Size, u15Color, u15InvertDepthCutoff, u15DepthCutoff, u15Distance, u15BlendFix, u15ToggleTexture, u15ToggleDepth, u15ToggleDepthCutoff, PS_Spotlight15, Spotlight15)
#endif

#if SPOTLIGHT_QUANTITY > 14
	SPOTLIGHT_SUMMONING("Spotlight 16", u16XCenter, u16YCenter, u16Brightness, u16Size, u16Color, u16InvertDepthCutoff, u16DepthCutoff, u16Distance, u16BlendFix, u16ToggleTexture, u16ToggleDepth, u16ToggleDepthCutoff, PS_Spotlight16, Spotlight16)
#endif

#if SPOTLIGHT_QUANTITY > 15
	SPOTLIGHT_SUMMONING("Spotlight 17", u17XCenter, u17YCenter, u17Brightness, u17Size, u17Color, u17InvertDepthCutoff, u17DepthCutoff, u17Distance, u17BlendFix, u17ToggleTexture, u17ToggleDepth, u17ToggleDepthCutoff, PS_Spotlight17, Spotlight17)
#endif

#if SPOTLIGHT_QUANTITY > 16
	SPOTLIGHT_SUMMONING("Spotlight 18", u18XCenter, u18YCenter, u18Brightness, u18Size, u18Color, u18InvertDepthCutoff, u18DepthCutoff, u18Distance, u18BlendFix, u18ToggleTexture, u18ToggleDepth, u18ToggleDepthCutoff, PS_Spotlight18, Spotlight18)
#endif

#if SPOTLIGHT_QUANTITY > 17
	SPOTLIGHT_SUMMONING("Spotlight 19", u19XCenter, u19YCenter, u19Brightness, u19Size, u19Color, u19InvertDepthCutoff, u19DepthCutoff, u19Distance, u19BlendFix, u19ToggleTexture, u19ToggleDepth, u19ToggleDepthCutoff, PS_Spotlight19, Spotlight19)
#endif

#if SPOTLIGHT_QUANTITY > 18
	SPOTLIGHT_SUMMONING("Spotlight 20", u20XCenter, u20YCenter, u20Brightness, u20Size, u20Color, u20InvertDepthCutoff, u20DepthCutoff, u20Distance, u20BlendFix, u20ToggleTexture, u20ToggleDepth, u20ToggleDepthCutoff, PS_Spotlight20, Spotlight20)
#endif