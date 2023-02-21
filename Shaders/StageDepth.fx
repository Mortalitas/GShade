// Made by Marot Satil, seri14, & Uchu Suzume for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
//
// This shader was designed in the same vein as GreenScreenDepth.fx, but instead of applying a
// green screen with adjustable distance, it applies a PNG texture with adjustable opacity.
//
// PNG transparency is fully supported, so you could for example add another moon to the sky
// just as readily as create a "green screen" stage like in real life.
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
#include "Blending.fxh"
#include "StageDepth.fxh"

#ifndef StageTex
	#define StageTex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
#endif
#ifndef STAGE_SIZE_X
	#define STAGE_SIZE_X BUFFER_WIDTH
#endif
#ifndef STAGE_SIZE_Y
	#define STAGE_SIZE_Y BUFFER_HEIGHT
#endif
#ifndef STAGE_TEXFORMAT
	#define STAGE_TEXFORMAT RGBA8
#endif

uniform int StageDepth_Quantity <
	ui_type = "combo";
	ui_label = "Number of StageDepths";
	ui_tooltip = "The number of StageDepth techniques to generate. Enabling too many of these in a DirectX 9 game or on lower end hardware is a very, very bad idea.";
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
	ui_bind = "STAGEDEPTH_QUANTITY";
> = 0;

#ifndef STAGEDEPTH_QUANTITY
	#define STAGEDEPTH_QUANTITY 0
#endif

STAGEDEPTH_SUMMONING(StageDepth_Texture, StageTex, STAGE_SIZE_X, STAGE_SIZE_Y, STAGE_TEXFORMAT, StageDepth_Sampler, Stage_BlendMode, "StageDepth 1", Stage_Opacity, Stage_depth, Stage_Scale, Stage_ScaleX, Stage_ScaleY, Stage_PosX, Stage_PosY, Stage_SnapRotate, Stage_Rotate, Stage_InvertDepth, PS_StageDepth, StageDepth)

#if STAGEDEPTH_QUANTITY > 0
	#ifndef Stage2Tex
		#define Stage2Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE2_SIZE_X
		#define STAGE2_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE2_SIZE_Y
		#define STAGE2_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE2_TEXFORMAT
		#define STAGE2_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage2Depth_Texture, Stage2Tex, STAGE2_SIZE_X, STAGE2_SIZE_Y, STAGE2_TEXFORMAT, Stage2Depth_Sampler, Stage2_BlendMode, "StageDepth 2", Stage2_Opacity, Stage2_depth, Stage2_Scale, Stage2_ScaleX, Stage2_ScaleY, Stage2_PosX, Stage2_PosY, Stage2_SnapRotate, Stage2_Rotate, Stage2_InvertDepth, PS_Stage2Depth, StageDepth2)
#endif

#if STAGEDEPTH_QUANTITY > 1
	#ifndef Stage3Tex
		#define Stage3Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE3_SIZE_X
		#define STAGE3_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE3_SIZE_Y
		#define STAGE3_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE3_TEXFORMAT
		#define STAGE3_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage3Depth_Texture, Stage3Tex, STAGE3_SIZE_X, STAGE3_SIZE_Y, STAGE3_TEXFORMAT, Stage3Depth_Sampler, Stage3_BlendMode, "StageDepth 3", Stage3_Opacity, Stage3_depth, Stage3_Scale, Stage3_ScaleX, Stage3_ScaleY, Stage3_PosX, Stage3_PosY, Stage3_SnapRotate, Stage3_Rotate, Stage3_InvertDepth, PS_Stage3Depth, StageDepth3)
#endif

#if STAGEDEPTH_QUANTITY > 2
	#ifndef Stage4Tex
		#define Stage4Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE4_SIZE_X
		#define STAGE4_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE4_SIZE_Y
		#define STAGE4_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE4_TEXFORMAT
		#define STAGE4_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage4Depth_Texture, Stage4Tex, STAGE4_SIZE_X, STAGE4_SIZE_Y, STAGE4_TEXFORMAT, Stage4Depth_Sampler, Stage4_BlendMode, "StageDepth 4", Stage4_Opacity, Stage4_depth, Stage4_Scale, Stage4_ScaleX, Stage4_ScaleY, Stage4_PosX, Stage4_PosY, Stage4_SnapRotate, Stage4_Rotate, Stage4_InvertDepth, PS_Stage4Depth, StageDepth4)
#endif

#if STAGEDEPTH_QUANTITY > 3
	#ifndef Stage5Tex
		#define Stage5Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE5_SIZE_X
		#define STAGE5_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE5_SIZE_Y
		#define STAGE5_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE5_TEXFORMAT
		#define STAGE5_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage5Depth_Texture, Stage5Tex, STAGE5_SIZE_X, STAGE5_SIZE_Y, STAGE5_TEXFORMAT, Stage5Depth_Sampler, Stage5_BlendMode, "StageDepth 5", Stage5_Opacity, Stage5_depth, Stage5_Scale, Stage5_ScaleX, Stage5_ScaleY, Stage5_PosX, Stage5_PosY, Stage5_SnapRotate, Stage5_Rotate, Stage5_InvertDepth, PS_Stage5Depth, StageDepth5)
#endif

#if STAGEDEPTH_QUANTITY > 4
	#ifndef Stage6Tex
		#define Stage6Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE6_SIZE_X
		#define STAGE6_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE6_SIZE_Y
		#define STAGE6_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE6_TEXFORMAT
		#define STAGE6_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage6Depth_Texture, Stage6Tex, STAGE6_SIZE_X, STAGE6_SIZE_Y, STAGE6_TEXFORMAT, Stage6Depth_Sampler, Stage6_BlendMode, "StageDepth 6", Stage6_Opacity, Stage6_depth, Stage6_Scale, Stage6_ScaleX, Stage6_ScaleY, Stage6_PosX, Stage6_PosY, Stage6_SnapRotate, Stage6_Rotate, Stage6_InvertDepth, PS_Stage6Depth, StageDepth6)
#endif

#if STAGEDEPTH_QUANTITY > 5
	#ifndef Stage7Tex
		#define Stage7Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE7_SIZE_X
		#define STAGE7_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE7_SIZE_Y
		#define STAGE7_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE7_TEXFORMAT
		#define STAGE7_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage7Depth_Texture, Stage7Tex, STAGE7_SIZE_X, STAGE7_SIZE_Y, STAGE7_TEXFORMAT, Stage7Depth_Sampler, Stage7_BlendMode, "StageDepth 7", Stage7_Opacity, Stage7_depth, Stage7_Scale, Stage7_ScaleX, Stage7_ScaleY, Stage7_PosX, Stage7_PosY, Stage7_SnapRotate, Stage7_Rotate, Stage7_InvertDepth, PS_Stage7Depth, StageDepth7)
#endif

#if STAGEDEPTH_QUANTITY > 6
	#ifndef Stage8Tex
		#define Stage8Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE8_SIZE_X
		#define STAGE8_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE8_SIZE_Y
		#define STAGE8_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE8_TEXFORMAT
		#define STAGE8_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage8Depth_Texture, Stage8Tex, STAGE8_SIZE_X, STAGE8_SIZE_Y, STAGE8_TEXFORMAT, Stage8Depth_Sampler, Stage8_BlendMode, "StageDepth 8", Stage8_Opacity, Stage8_depth, Stage8_Scale, Stage8_ScaleX, Stage8_ScaleY, Stage8_PosX, Stage8_PosY, Stage8_SnapRotate, Stage8_Rotate, Stage8_InvertDepth, PS_Stage8Depth, StageDepth8)
#endif

#if STAGEDEPTH_QUANTITY > 7
	#ifndef Stage9Tex
		#define Stage9Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE9_SIZE_X
		#define STAGE9_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE9_SIZE_Y
		#define STAGE9_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE9_TEXFORMAT
		#define STAGE9_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage9Depth_Texture, Stage9Tex, STAGE9_SIZE_X, STAGE9_SIZE_Y, STAGE9_TEXFORMAT, Stage9Depth_Sampler, Stage9_BlendMode, "StageDepth 9", Stage9_Opacity, Stage9_depth, Stage9_Scale, Stage9_ScaleX, Stage9_ScaleY, Stage9_PosX, Stage9_PosY, Stage9_SnapRotate, Stage9_Rotate, Stage9_InvertDepth, PS_Stage9Depth, StageDepth9)
#endif

#if STAGEDEPTH_QUANTITY > 8
	#ifndef Stage10Tex
		#define Stage10Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE10_SIZE_X
		#define STAGE10_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE10_SIZE_Y
		#define STAGE10_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE10_TEXFORMAT
		#define STAGE10_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage10Depth_Texture, Stage10Tex, STAGE10_SIZE_X, STAGE10_SIZE_Y, STAGE10_TEXFORMAT, Stage10Depth_Sampler, Stage10_BlendMode, "StageDepth 10", Stage10_Opacity, Stage10_depth, Stage10_Scale, Stage10_ScaleX, Stage10_ScaleY, Stage10_PosX, Stage10_PosY, Stage10_SnapRotate, Stage10_Rotate, Stage10_InvertDepth, PS_Stage10Depth, StageDepth10)
#endif

#if STAGEDEPTH_QUANTITY > 9
	#ifndef Stage11Tex
		#define Stage11Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE11_SIZE_X
		#define STAGE11_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE11_SIZE_Y
		#define STAGE11_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE11_TEXFORMAT
		#define STAGE11_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage11Depth_Texture, Stage11Tex, STAGE11_SIZE_X, STAGE11_SIZE_Y, STAGE11_TEXFORMAT, Stage11Depth_Sampler, Stage11_BlendMode, "StageDepth 11", Stage11_Opacity, Stage11_depth, Stage11_Scale, Stage11_ScaleX, Stage11_ScaleY, Stage11_PosX, Stage11_PosY, Stage11_SnapRotate, Stage11_Rotate, Stage11_InvertDepth, PS_Stage11Depth, StageDepth11)
#endif

#if STAGEDEPTH_QUANTITY > 10
	#ifndef Stage12Tex
		#define Stage12Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE12_SIZE_X
		#define STAGE12_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE12_SIZE_Y
		#define STAGE12_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE12_TEXFORMAT
		#define STAGE12_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage12Depth_Texture, Stage12Tex, STAGE12_SIZE_X, STAGE12_SIZE_Y, STAGE12_TEXFORMAT, Stage12Depth_Sampler, Stage12_BlendMode, "StageDepth 12", Stage12_Opacity, Stage12_depth, Stage12_Scale, Stage12_ScaleX, Stage12_ScaleY, Stage12_PosX, Stage12_PosY, Stage12_SnapRotate, Stage12_Rotate, Stage12_InvertDepth, PS_Stage12Depth, StageDepth12)
#endif

#if STAGEDEPTH_QUANTITY > 11
	#ifndef Stage13Tex
		#define Stage13Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE13_SIZE_X
		#define STAGE13_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE13_SIZE_Y
		#define STAGE13_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE13_TEXFORMAT
		#define STAGE13_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage13Depth_Texture, Stage13Tex, STAGE13_SIZE_X, STAGE13_SIZE_Y, STAGE13_TEXFORMAT, Stage13Depth_Sampler, Stage13_BlendMode, "StageDepth 13", Stage13_Opacity, Stage13_depth, Stage13_Scale, Stage13_ScaleX, Stage13_ScaleY, Stage13_PosX, Stage13_PosY, Stage13_SnapRotate, Stage13_Rotate, Stage13_InvertDepth, PS_Stage13Depth, StageDepth13)
#endif

#if STAGEDEPTH_QUANTITY > 12
	#ifndef Stage14Tex
		#define Stage14Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE14_SIZE_X
		#define STAGE14_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE14_SIZE_Y
		#define STAGE14_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE14_TEXFORMAT
		#define STAGE14_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage14Depth_Texture, Stage14Tex, STAGE14_SIZE_X, STAGE14_SIZE_Y, STAGE14_TEXFORMAT, Stage14Depth_Sampler, Stage14_BlendMode, "StageDepth 14", Stage14_Opacity, Stage14_depth, Stage14_Scale, Stage14_ScaleX, Stage14_ScaleY, Stage14_PosX, Stage14_PosY, Stage14_SnapRotate, Stage14_Rotate, Stage14_InvertDepth, PS_Stage14Depth, StageDepth14)
#endif

#if STAGEDEPTH_QUANTITY > 13
	#ifndef Stage15Tex
		#define Stage15Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE15_SIZE_X
		#define STAGE15_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE15_SIZE_Y
		#define STAGE15_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE15_TEXFORMAT
		#define STAGE15_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage15Depth_Texture, Stage15Tex, STAGE15_SIZE_X, STAGE15_SIZE_Y, STAGE15_TEXFORMAT, Stage15Depth_Sampler, Stage15_BlendMode, "StageDepth 15", Stage15_Opacity, Stage15_depth, Stage15_Scale, Stage15_ScaleX, Stage15_ScaleY, Stage15_PosX, Stage15_PosY, Stage15_SnapRotate, Stage15_Rotate, Stage15_InvertDepth, PS_Stage15Depth, StageDepth15)
#endif

#if STAGEDEPTH_QUANTITY > 14
	#ifndef Stage16Tex
		#define Stage16Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE16_SIZE_X
		#define STAGE16_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE16_SIZE_Y
		#define STAGE16_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE16_TEXFORMAT
		#define STAGE16_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage16Depth_Texture, Stage16Tex, STAGE16_SIZE_X, STAGE16_SIZE_Y, STAGE16_TEXFORMAT, Stage16Depth_Sampler, Stage16_BlendMode, "StageDepth 16", Stage16_Opacity, Stage16_depth, Stage16_Scale, Stage16_ScaleX, Stage16_ScaleY, Stage16_PosX, Stage16_PosY, Stage16_SnapRotate, Stage16_Rotate, Stage16_InvertDepth, PS_Stage16Depth, StageDepth16)
#endif

#if STAGEDEPTH_QUANTITY > 15
	#ifndef Stage17Tex
		#define Stage17Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE17_SIZE_X
		#define STAGE17_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE17_SIZE_Y
		#define STAGE17_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE17_TEXFORMAT
		#define STAGE17_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage17Depth_Texture, Stage17Tex, STAGE17_SIZE_X, STAGE17_SIZE_Y, STAGE17_TEXFORMAT, Stage17Depth_Sampler, Stage17_BlendMode, "StageDepth 17", Stage17_Opacity, Stage17_depth, Stage17_Scale, Stage17_ScaleX, Stage17_ScaleY, Stage17_PosX, Stage17_PosY, Stage17_SnapRotate, Stage17_Rotate, Stage17_InvertDepth, PS_Stage17Depth, StageDepth17)
#endif

#if STAGEDEPTH_QUANTITY > 16
	#ifndef Stage18Tex
		#define Stage18Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE18_SIZE_X
		#define STAGE18_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE18_SIZE_Y
		#define STAGE18_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE18_TEXFORMAT
		#define STAGE18_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage18Depth_Texture, Stage18Tex, STAGE18_SIZE_X, STAGE18_SIZE_Y, STAGE18_TEXFORMAT, Stage18Depth_Sampler, Stage18_BlendMode, "StageDepth 18", Stage18_Opacity, Stage18_depth, Stage18_Scale, Stage18_ScaleX, Stage18_ScaleY, Stage18_PosX, Stage18_PosY, Stage18_SnapRotate, Stage18_Rotate, Stage18_InvertDepth, PS_Stage18Depth, StageDepth18)
#endif

#if STAGEDEPTH_QUANTITY > 17
	#ifndef Stage19Tex
		#define Stage19Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE19_SIZE_X
		#define STAGE19_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE19_SIZE_Y
		#define STAGE19_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE19_TEXFORMAT
		#define STAGE19_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage19Depth_Texture, Stage19Tex, STAGE19_SIZE_X, STAGE19_SIZE_Y, STAGE19_TEXFORMAT, Stage19Depth_Sampler, Stage19_BlendMode, "StageDepth 19", Stage19_Opacity, Stage19_depth, Stage19_Scale, Stage19_ScaleX, Stage19_ScaleY, Stage19_PosX, Stage19_PosY, Stage19_SnapRotate, Stage19_Rotate, Stage19_InvertDepth, PS_Stage19Depth, StageDepth19)
#endif

#if STAGEDEPTH_QUANTITY > 18
	#ifndef Stage20Tex
		#define Stage20Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef STAGE20_SIZE_X
		#define STAGE20_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef STAGE20_SIZE_Y
		#define STAGE20_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef STAGE20_TEXFORMAT
		#define STAGE20_TEXFORMAT RGBA8
	#endif

	STAGEDEPTH_SUMMONING(Stage20Depth_Texture, Stage20Tex, STAGE20_SIZE_X, STAGE20_SIZE_Y, STAGE20_TEXFORMAT, Stage20Depth_Sampler, Stage20_BlendMode, "StageDepth 20", Stage20_Opacity, Stage20_depth, Stage20_Scale, Stage20_ScaleX, Stage20_ScaleY, Stage20_PosX, Stage20_PosY, Stage20_SnapRotate, Stage20_Rotate, Stage20_InvertDepth, PS_Stage20Depth, StageDepth20)
#endif