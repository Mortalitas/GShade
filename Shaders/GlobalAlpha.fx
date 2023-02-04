// Made by Marot Satil for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
// Follow @GPOSERS_FFXIV on Twitter and join us on Discord (https://discord.gg/39WpvU2)
// for the latest GShade package updates!
//
// This shader alters the alpha level of the current frame.
//
// Copyright (c) 2023, Marot Satil
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

#include "ReShade.fxh"

uniform bool bIgnore <
	ui_label = "Ignore Fully Transparent Pixels";
	ui_tooltip = "If this setting is enabled, pixels with a alpha value of 0 will not be modified and remain fully transparent.";
	ui_bind = "GLOBAL_ALPHA_IGNORE";
> = true;

#ifndef GLOBAL_ALPHA_IGNORE
	#define GLOBAL_ALPHA_IGNORE 1
#endif

uniform float fOpacity <
	ui_label = "Alpha";
	ui_tooltip = "If this setting is above 0.0 (fully transparent), you will mainly be able to see its impact in screenshots.\n\nA value of 0.5 is 50\% transparent.";
	ui_type = "slider";
> = 1.0;

float4 GlobalAlphaPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float4 back = tex2D(ReShade::BackBuffer, texcoord);

#if GLOBAL_ALPHA_IGNORE
	return float4(back.rgb, back.a <= 0.0 ? back.a : fOpacity);
#else
	return float4(back.rgb, fOpacity);
#endif
}

technique GlobalAlpha
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = GlobalAlphaPS;
	}
}
