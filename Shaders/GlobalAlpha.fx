// Made by Marot Satil for GShade, a fork of ReShade.
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much and if you message me directly it's very likely to get flagged as spam.
// If you have questions about this shader or need to contact me for any other reason, reaching out to me via the username Marot on Discord is likely a better bet.
//
// This shader alters the alpha level of the current frame.
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
