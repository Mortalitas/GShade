// Made by Marot Satil for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
// Follow @GPOSERS_FFXIV on Twitter and join us on Discord (https://discord.gg/39WpvU2)
// for the latest GShade package updates!
//
// This shader does exactly what it says it does.
//
// Copyright (c) 2019, Marot Satil
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
