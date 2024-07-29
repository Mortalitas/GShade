/*------------------.
| :: Description :: |
'-------------------/

	DropShadow

	Authors: CeeJay.dk, seri14, Marot Satil, Uchu Suzume, prod80, originalnicodr
	License: MIT

	Based off of Layer.fx, this shader uses depth to create a simple, solid-color adjustable drop shadow.


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

#include "ReShade.fxh"
#include "DropShadow.fxh"

uniform int DropShadowQuantity <
	ui_type = "combo";
	ui_label = "Number of Drop Shadows";
	ui_tooltip = "The number of DropShadow techniques to generate. Enabling too many of these in a DirectX 9 game or on lower end hardware is a very, very bad idea.";
	ui_items =  "1\0"
				"2\0"
				"3\0"
				"4\0"
				"5\0";
	ui_bind = "DROPSHADOW_QUANTITY";
> = 0;

#ifndef DROPSHADOW_QUANTITY
	#define DROPSHADOW_QUANTITY 0
#endif

DROPSHADOW_SUMMONING(DropShadow_Texture, DropShadow_Sampler, "DropShadow", fTargetDepth, fColor, fPosX, fPosY, fPosXY, fScaleX, fScaleY, fCutoffMaxX, fCutoffMinX, fCutoffMaxY, fCutoffMinY, iSnapRotate, iRotate, PS_DropShadowBack, PS_DropShadow, DropShadow)

#if DROPSHADOW_QUANTITY > 0
	DROPSHADOW_SUMMONING(DropShadow2_Texture, DropShadow2_Sampler, "DropShadow2", fTargetDepth2, fColor2, fPosX2, fPosY2, fPosXY2, fScaleX2, fScaleY2, fCutoffMaxX2, fCutoffMinX2, fCutoffMaxY2, fCutoffMinY2, iSnapRotate2, iRotate2, PS_DropShadowBack2, PS_DropShadow2, DropShadow2)
#endif

#if DROPSHADOW_QUANTITY > 1
	DROPSHADOW_SUMMONING(DropShadow3_Texture, DropShadow3_Sampler, "DropShadow3", fTargetDepth3, fColor3, fPosX3, fPosY3, fPosXY3, fScaleX3, fScaleY3, fCutoffMaxX3, fCutoffMinX3, fCutoffMaxY3, fCutoffMinY3, iSnapRotate3, iRotate3, PS_DropShadowBack3, PS_DropShadow3, DropShadow3)
#endif

#if DROPSHADOW_QUANTITY > 2
	DROPSHADOW_SUMMONING(DropShadow4_Texture, DropShadow4_Sampler, "DropShadow4", fTargetDepth4, fColor4, fPosX4, fPosY4, fPosXY4, fScaleX4, fScaleY4, fCutoffMaxX4, fCutoffMinX4, fCutoffMaxY4, fCutoffMinY4, iSnapRotate4, iRotate4, PS_DropShadowBack4, PS_DropShadow4, DropShadow4)
#endif

#if DROPSHADOW_QUANTITY > 3
	DROPSHADOW_SUMMONING(DropShadow5_Texture, DropShadow5_Sampler, "DropShadow5", fTargetDepth5, fColor5, fPosX5, fPosY5, fPosXY5, fScaleX5, fScaleY5, fCutoffMaxX5, fCutoffMinX5, fCutoffMaxY5, fCutoffMinY5, iSnapRotate5, iRotate5, PS_DropShadowBack5, PS_DropShadow5, DropShadow5)
#endif