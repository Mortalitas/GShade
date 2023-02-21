// Made by Marot Satil, seri14, & Uchu Suzume using code from sYNTHwAVE88's Pixelate.fx 1.0 for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
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
#include "Censor.fxh"

uniform int Censor_Quantity <
	ui_type = "combo";
	ui_label = "Number of Censors";
	ui_tooltip = "The number of Censor techniques to generate. Enabling too many of these in a DirectX 9 game or on lower end hardware is a very, very bad idea.";
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
	ui_bind = "CENSOR_QUANTITY";
> = 0;

#ifndef CENSOR_QUANTITY
	#define CENSOR_QUANTITY 0
#endif

CENSOR_SUMMONING("Censor 1", Censor_Opacity, Censor_Depth, Censor_Cell_Size, Censor_Smoothness_Average, Censor_Scale, Censor_ScaleX, Censor_ScaleY, Censor_PosX, Censor_PosY, Censor_SnapRotate, Censor_Rotate, Censor_InvertDepth, PS_Censor, Censor)

#if CENSOR_QUANTITY > 0
	CENSOR_SUMMONING("Censor 2", Censor2_Opacity, Censor2_Depth, Censor2_Cell_Size, Censor2_Smoothness_Average, Censor2_Scale, Censor2_ScaleX, Censor2_ScaleY, Censor2_PosX, Censor2_PosY, Censor2_SnapRotate, Censor2_Rotate, Censor2_InvertDepth, PS_Censor2, Censor2)
#endif

#if CENSOR_QUANTITY > 1
	CENSOR_SUMMONING("Censor 3", Censor3_Opacity, Censor3_Depth, Censor3_Cell_Size, Censor3_Smoothness_Average, Censor3_Scale, Censor3_ScaleX, Censor3_ScaleY, Censor3_PosX, Censor3_PosY, Censor3_SnapRotate, Censor3_Rotate, Censor3_InvertDepth, PS_Censor3, Censor3)
#endif

#if CENSOR_QUANTITY > 2
	CENSOR_SUMMONING("Censor 4", Censor4_Opacity, Censor4_Depth, Censor4_Cell_Size, Censor4_Smoothness_Average, Censor4_Scale, Censor4_ScaleX, Censor4_ScaleY, Censor4_PosX, Censor4_PosY, Censor4_SnapRotate, Censor4_Rotate, Censor4_InvertDepth, PS_Censor4, Censor4)
#endif

#if CENSOR_QUANTITY > 3
	CENSOR_SUMMONING("Censor 5", Censor5_Opacity, Censor5_Depth, Censor5_Cell_Size, Censor5_Smoothness_Average, Censor5_Scale, Censor5_ScaleX, Censor5_ScaleY, Censor5_PosX, Censor5_PosY, Censor5_SnapRotate, Censor5_Rotate, Censor5_InvertDepth, PS_Censor5, Censor5)
#endif

#if CENSOR_QUANTITY > 4
	CENSOR_SUMMONING("Censor 6", Censor6_Opacity, Censor6_Depth, Censor6_Cell_Size, Censor6_Smoothness_Average, Censor6_Scale, Censor6_ScaleX, Censor6_ScaleY, Censor6_PosX, Censor6_PosY, Censor6_SnapRotate, Censor6_Rotate, Censor6_InvertDepth, PS_Censor6, Censor6)
#endif

#if CENSOR_QUANTITY > 5
	CENSOR_SUMMONING("Censor 7", Censor7_Opacity, Censor7_Depth, Censor7_Cell_Size, Censor7_Smoothness_Average, Censor7_Scale, Censor7_ScaleX, Censor7_ScaleY, Censor7_PosX, Censor7_PosY, Censor7_SnapRotate, Censor7_Rotate, Censor7_InvertDepth, PS_Censor7, Censor7)
#endif

#if CENSOR_QUANTITY > 6
	CENSOR_SUMMONING("Censor 8", Censor8_Opacity, Censor8_Depth, Censor8_Cell_Size, Censor8_Smoothness_Average, Censor8_Scale, Censor8_ScaleX, Censor8_ScaleY, Censor8_PosX, Censor8_PosY, Censor8_SnapRotate, Censor8_Rotate, Censor8_InvertDepth, PS_Censor8, Censor8)
#endif

#if CENSOR_QUANTITY > 7
	CENSOR_SUMMONING("Censor 9", Censor9_Opacity, Censor9_Depth, Censor9_Cell_Size, Censor9_Smoothness_Average, Censor9_Scale, Censor9_ScaleX, Censor9_ScaleY, Censor9_PosX, Censor9_PosY, Censor9_SnapRotate, Censor9_Rotate, Censor9_InvertDepth, PS_Censor9, Censor9)
#endif

#if CENSOR_QUANTITY > 8
	CENSOR_SUMMONING("Censor 10", Censor10_Opacity, Censor10_Depth, Censor10_Cell_Size, Censor10_Smoothness_Average, Censor10_Scale, Censor10_ScaleX, Censor10_ScaleY, Censor10_PosX, Censor10_PosY, Censor10_SnapRotate, Censor10_Rotate, Censor10_InvertDepth, PS_Censor10, Censor10)
#endif

#if CENSOR_QUANTITY > 9
	CENSOR_SUMMONING("Censor 11", Censor11_Opacity, Censor11_Depth, Censor11_Cell_Size, Censor11_Smoothness_Average, Censor11_Scale, Censor11_ScaleX, Censor11_ScaleY, Censor11_PosX, Censor11_PosY, Censor11_SnapRotate, Censor11_Rotate, Censor11_InvertDepth, PS_Censor11, Censor11)
#endif

#if CENSOR_QUANTITY > 10
	CENSOR_SUMMONING("Censor 12", Censor12_Opacity, Censor12_Depth, Censor12_Cell_Size, Censor12_Smoothness_Average, Censor12_Scale, Censor12_ScaleX, Censor12_ScaleY, Censor12_PosX, Censor12_PosY, Censor12_SnapRotate, Censor12_Rotate, Censor12_InvertDepth, PS_Censor12, Censor12)
#endif

#if CENSOR_QUANTITY > 11
	CENSOR_SUMMONING("Censor 13", Censor13_Opacity, Censor13_Depth, Censor13_Cell_Size, Censor13_Smoothness_Average, Censor13_Scale, Censor13_ScaleX, Censor13_ScaleY, Censor13_PosX, Censor13_PosY, Censor13_SnapRotate, Censor13_Rotate, Censor13_InvertDepth, PS_Censor13, Censor13)
#endif

#if CENSOR_QUANTITY > 114
	CENSOR_SUMMONING("Censor 14", Censor14_Opacity, Censor14_Depth, Censor14_Cell_Size, Censor14_Smoothness_Average, Censor14_Scale, Censor14_ScaleX, Censor14_ScaleY, Censor14_PosX, Censor14_PosY, Censor14_SnapRotate, Censor14_Rotate, Censor14_InvertDepth, PS_Censor14, Censor14)
#endif

#if CENSOR_QUANTITY > 13
	CENSOR_SUMMONING("Censor 15", Censor15_Opacity, Censor15_Depth, Censor15_Cell_Size, Censor15_Smoothness_Average, Censor15_Scale, Censor15_ScaleX, Censor15_ScaleY, Censor15_PosX, Censor15_PosY, Censor15_SnapRotate, Censor15_Rotate, Censor15_InvertDepth, PS_Censor15, Censor15)
#endif

#if CENSOR_QUANTITY > 14
	CENSOR_SUMMONING("Censor 16", Censor16_Opacity, Censor16_Depth, Censor16_Cell_Size, Censor16_Smoothness_Average, Censor16_Scale, Censor16_ScaleX, Censor16_ScaleY, Censor16_PosX, Censor16_PosY, Censor16_SnapRotate, Censor16_Rotate, Censor16_InvertDepth, PS_Censor16, Censor16)
#endif

#if CENSOR_QUANTITY > 15
	CENSOR_SUMMONING("Censor 17", Censor17_Opacity, Censor17_Depth, Censor17_Cell_Size, Censor17_Smoothness_Average, Censor17_Scale, Censor17_ScaleX, Censor17_ScaleY, Censor17_PosX, Censor17_PosY, Censor17_SnapRotate, Censor17_Rotate, Censor17_InvertDepth, PS_Censor17, Censor17)
#endif

#if CENSOR_QUANTITY > 16
	CENSOR_SUMMONING("Censor 18", Censor18_Opacity, Censor18_Depth, Censor18_Cell_Size, Censor18_Smoothness_Average, Censor18_Scale, Censor18_ScaleX, Censor18_ScaleY, Censor18_PosX, Censor18_PosY, Censor18_SnapRotate, Censor18_Rotate, Censor18_InvertDepth, PS_Censor18, Censor18)
#endif

#if CENSOR_QUANTITY > 17
	CENSOR_SUMMONING("Censor 19", Censor19_Opacity, Censor19_Depth, Censor19_Cell_Size, Censor19_Smoothness_Average, Censor19_Scale, Censor19_ScaleX, Censor19_ScaleY, Censor19_PosX, Censor19_PosY, Censor19_SnapRotate, Censor19_Rotate, Censor19_InvertDepth, PS_Censor19, Censor19)
#endif

#if CENSOR_QUANTITY > 18
	CENSOR_SUMMONING("Censor 20", Censor20_Opacity, Censor20_Depth, Censor20_Cell_Size, Censor20_Smoothness_Average, Censor20_Scale, Censor20_ScaleX, Censor20_ScaleY, Censor20_PosX, Censor20_PosY, Censor20_SnapRotate, Censor20_Rotate, Censor20_InvertDepth, PS_Censor20, Censor20)
#endif