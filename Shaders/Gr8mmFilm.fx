/**
 * Copyright (C) 2015 Lucifer Hawk (mediehawk@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software with restriction, including without limitation the rights to
 * use and/or sell copies of the Software, and to permit persons to whom the Software 
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and below) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * Permission needs to be specifically granted by the author of the software to any
 * person obtaining a copy of this software and associated documentation files 
 * (the "Software"), to deal in the Software without restriction, including without 
 * limitation the rights to copy, modify, merge, publish, distribute, and/or 
 * sublicense the Software, and subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and above) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

//	++++	Gr8mm Film GUI Settings	++++	

uniform float Gr8mmFilmVignettePower <
	ui_type = "slider";
	ui_min = 0; ui_max = 2;
	ui_step = 0.01;
	ui_tooltip = "Strength of the effect at the edges";
	ui_label = "Vignette strength";
> = 1.0;

uniform float Gr8mmFilmPower <
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_step = 0.01;
	ui_tooltip = "Overall intensity of the effect";
	ui_label = "Overall strength";
> = 1.0;

uniform float Gr8mmFilmAlphaPower <
	ui_type = "slider";
	ui_min = 0; ui_max = 2;
	ui_step = 0.01;
	ui_tooltip = "Takes gradients into account (white => transparent)";
	ui_label = "Alpha";
> = 1.0;

#define Gr8mmFilmBlackFrameMix 1 //[0:1] //-0: Adds a black frame into the mix; 1: No black frame added
#define Gr8mmFilmScroll 0 //[0:1] //-0: Jumps from frame to frame; 1: Scrolls from frame to frame

#define Gr8mmFilmTileAmount 7.0 //[2.0:20.0] //-Amount of frames used in the Gr8mmFilm.png
#define Gr8mmFilmTextureSizeX 1280 //[undef] //-Size of the defined texture (Width)
#define Gr8mmFilmTextureSizeY 5040 //[undef] //-Size of the defined texture (Height)

#define CFX_Gr8mmFilm_TY Gr8mmFilmTextureSizeY/Gr8mmFilmTileAmount
#define CFX_Gr8mmFilm_VP Gr8mmFilmVignettePower*0.65f
#define CFX_Gr8mmFilm_AP Gr8mmFilmAlphaPower/3f

uniform float2 filmroll < source = "pingpong"; min = 0.0f; max = (Gr8mmFilmTileAmount-Gr8mmFilmBlackFrameMix)/**speed*/; step = float2(1.0f, 2.0f); >;


texture Gr8mmFilmTex < source = "CFX_Gr8mmFilm.png"; > { Width = Gr8mmFilmTextureSizeX; Height = Gr8mmFilmTextureSizeY; Format = RGBA8; };
sampler	Gr8mmFilmColor 	{ Texture = Gr8mmFilmTex; };

#include "ReShade.fxh"

float4 PS_Gr8mmFilm(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float4 singleGr8mmFilm = tex2D(Gr8mmFilmColor, float2(texcoord.x, texcoord.y/Gr8mmFilmTileAmount + (CFX_Gr8mmFilm_TY/Gr8mmFilmTextureSizeY)* 
#if Gr8mmFilmScroll
filmroll.x
#else
trunc(filmroll.x/* / speed*/) 
#endif
));
	const float alpha = saturate(saturate(max(abs(texcoord.x-0.5f),abs(texcoord.y-0.5f))*Gr8mmFilmVignettePower + 0.75f - (singleGr8mmFilm.x+singleGr8mmFilm.y+singleGr8mmFilm.z)*CFX_Gr8mmFilm_AP));
	return lerp(tex2D(ReShade::BackBuffer, texcoord), singleGr8mmFilm, Gr8mmFilmPower*(alpha*alpha));
}

technique Gr8mmFilm 
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Gr8mmFilm;
	}
}

