// Made by Marot Satil for GShade, a fork of ReShade.
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much and if you message me directly it's very likely to get flagged as spam.
// If you have questions about this shader or need to contact me for any other reason, reaching out to me via the username Marot on Discord is likely a better bet.
//
// This shader does exactly what it says it does.
//
// Copyright © 2023 Marot Satil
// This work is free. You can redistribute it and/or modify it under the
// terms of the Do What The Fuck You Want To Public License, Version 2,
// as published by Sam Hocevar.
//
//            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                    Version 2, December 2004
//
// Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
//
// Everyone is permitted to copy and distribute verbatim or modified
// copies of this license document, and changing it is allowed as long
// as the name is changed.
//
//            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
//  0. You just DO WHAT THE FUCK YOU WANT TO.

uniform int nInversionSelector <
  ui_type = "combo";
  ui_items = "All\0Red\0Green\0Blue\0Red & Green\0Red & Blue\0Green & Blue\0None\0";
  ui_label = "The color(s) to invert.";
> = 0;

uniform float nInversionRed <
  ui_type = "slider";
  ui_label = "Red";
  ui_min = 0.0;
  ui_max = 1.0;
  ui_step = 0.001;
> = 1.0;

uniform float nInversionGreen <
  ui_type = "slider";
  ui_label = "Green";
  ui_min = 0.0;
  ui_max = 1.0;
  ui_step = 0.001;
> = 1.0;

uniform float nInversionBlue <
  ui_type = "slider";
  ui_label = "Blue";
  ui_min = 0.0;
  ui_max = 1.0;
  ui_step = 0.001;
> = 1.0;

#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

float3 SV_ColorInversion(float4 pos : SV_Position, float2 col : TEXCOORD) : SV_TARGET
{
  float3 inversion = tex2D(ReShade::BackBuffer, col).rgb;

  inversion.r = inversion.r * nInversionRed;
  inversion.g = inversion.g * nInversionGreen;
  inversion.b = inversion.b * nInversionBlue;

  if (nInversionSelector == 0)
  {
    inversion.r = 1.0f - inversion.r;
	inversion.g = 1.0f - inversion.g;
	inversion.b = 1.0f - inversion.b;
  }
  else if (nInversionSelector == 1)
  {
    inversion.r = 1.0f - inversion.r;
  }
  else if (nInversionSelector == 2)
  {
    inversion.g = 1.0f - inversion.g;
  }
  else if (nInversionSelector == 3)
  {
    inversion.b = 1.0f - inversion.b;
  }
  else if (nInversionSelector == 4)
  {
    inversion.r = 1.0f - inversion.r;
    inversion.g = 1.0f - inversion.g;
  }
  else if (nInversionSelector == 5)
  {
    inversion.r = 1.0f - inversion.r;
    inversion.b = 1.0f - inversion.b;
  }
  else if (nInversionSelector == 6)
  {
    inversion.g = 1.0f - inversion.g;
    inversion.b = 1.0f - inversion.b;
  }

#if GSHADE_DITHER
  return inversion + TriDither(inversion, col, BUFFER_COLOR_BIT_DEPTH);
#else
  return inversion;
#endif
}

technique ColorInversion
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = SV_ColorInversion;
	}
}
