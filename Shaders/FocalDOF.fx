////////////////////////////////////////////////////////
// Focal DOF
// Author: luluco250
// License: MIT
// Repository: https://github.com/luluco250/FXShaders
////////////////////////////////////////////////////////
/*
MIT License

Copyright (c) 2017 Lucas Melo

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

//#region Includes

#include "ReShade.fxh"

#ifndef FOCAL_DOF_USE_TEX2D_IN_VS
#define FOCAL_DOF_USE_TEX2D_IN_VS 0
#endif

#ifndef FOCAL_DOF_USE_SRGB
#define FOCAL_DOF_USE_SRGB 0
#endif

//#endregion

//#region Uniforms

uniform float DofScale
<
	ui_type = "slider";
	ui_label = "Scale";
	ui_tooltip =
		"If this is empty, nag @luluco250 in the ReShade Discord channel.\n"
		"\nDefault: 3.0";
	ui_category = "Appearance";
	ui_min = 1.0;
	ui_max = 10.0;
	ui_step = 0.001;
> = 3.0;

uniform float FocusTime
<
	ui_type = "slider";
	ui_label = "Time";
	ui_tooltip =
		"If this is empty, nag @luluco250 in the ReShade Discord channel.\n"
		"\nDefault: 350.0";
	ui_category = "Focus";
	ui_min = 0.0;
	ui_max = 2000.0;
	ui_step = 10.0;
> = 350.0;

uniform float2 FocusPoint
<
	ui_type = "slider";
	ui_label = "Point";
	ui_tooltip =
		"If this is empty, nag @luluco250 in the ReShade Discord channel.\n"
		"\nDefault: 0.5 0.5";
	ui_category = "Focus";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = float2(0.5, 0.5);

uniform float FrameTime <source = "frametime";>;

//#endregion

//#region Textures

#if FOCAL_DOF_USE_SRGB
	sampler BackBuffer
	{
		Texture = ReShade::BackBufferTex;
		SRGBTexture = true;
	};

	#define BACKBUFFER BackBuffer
#else
	#define BACKBUFFER ReShade::BackBuffer
#endif

texture FocalDOF_Focus { Format = R32F; };
sampler Focus { Texture = FocalDOF_Focus; };

texture FocalDOF_LastFocus { Format = R32F; };
sampler LastFocus { Texture = FocalDOF_LastFocus; };

//#endregion

//#region Shaders

void GetFocusVS(
	uint id : SV_VERTEXID,
	out float4 p : SV_POSITION,
	out float2 uv : TEXCOORD0,
	out float focus : TEXCOORD1)
{
	PostProcessVS(id, p, uv);
	
	#if FOCAL_DOF_USE_TEX2D_IN_VS
		focus = saturate(lerp(tex2Dfetch(LastFocus, float4(0, 0, 0, 0)).x, ReShade::GetLinearizedDepth(FocusPoint), FrameTime / FocusTime));
	#else
		focus = 0.0;
	#endif
}

void ReadFocusVS(
	uint id : SV_VERTEXID,
	out float4 p : SV_POSITION,
	out float2 uv : TEXCOORD0,
	out float focus : TEXCOORD1)
{
	PostProcessVS(id, p, uv);

	#if FOCAL_DOF_USE_TEX2D_IN_VS
		focus = tex2Dfetch(Focus, float4(0, 0, 0, 0)).x;
	#else
		focus = 0.0;
	#endif
}

float4 GetFocusPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD0,
	float focus : TEXCOORD1) : SV_TARGET
{
	#if !FOCAL_DOF_USE_TEX2D_IN_VS
		return saturate(lerp(tex2Dfetch(LastFocus, float2(0, 0), 0).x, ReShade::GetLinearizedDepth(FocusPoint), FrameTime / FocusTime));
	#else
		return focus;
	#endif
}

float4 SaveFocusPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD0,
	float focus : TEXCOORD1) : SV_TARGET
{
	#if !FOCAL_DOF_USE_TEX2D_IN_VS
		return tex2Dfetch(Focus, float2(0, 0), 0).x;
	#else
		return focus;
	#endif
}

float4 MainPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD0,
	float focus : TEXCOORD1) : SV_TARGET
{
	#define FOCAL_DOF_FETCH(off) exp(\
		tex2D(BACKBUFFER, uv + ReShade::PixelSize * off * (abs(ReShade::GetLinearizedDepth(uv) - focus) * DofScale)))

	static const float2 offsets[] =
	{
		float2(0.0, 1.0),
		float2(0.75, 0.75),
		float2(1.0, 0.0),
		float2(0.75, -0.75),
		float2(0.0, -1.0),
		float2(-0.75, -0.75),
		float2(-1.0, 0.0),
		float2(-0.75, 0.75)
	};

	float4 color = FOCAL_DOF_FETCH(0.0);

	[unroll]
	for (int i = 0; i < 8; ++i)
		color += FOCAL_DOF_FETCH(offsets[i]);
	color /= 9;

	#undef FOCAL_DOF_FETCH

	return log(color);
}

//#endregion

//#region Technique

technique FocalDOF
{
	pass GetFocus
	{
		VertexShader = GetFocusVS;
		PixelShader = GetFocusPS;
		RenderTarget = FocalDOF_Focus;
	}
	pass SaveFocus
	{
		VertexShader = ReadFocusVS;
		PixelShader = SaveFocusPS;
		RenderTarget = FocalDOF_LastFocus;
	}
	pass Main
	{
		VertexShader = ReadFocusVS;
		PixelShader = MainPS;
		
		#if FOCAL_DOF_USE_SRGB
			SRGBWriteEnable = true;
		#endif
	}
}

//#endregion