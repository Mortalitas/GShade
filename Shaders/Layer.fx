/*------------------.
| :: Description :: |
'-------------------/

	Layer (version 1.0)

	Authors: CeeJay.dk, seri14, Marot Satil, Uchu Suzume, prod80, originalnicodr
	License: MIT

	About:
	Blends an image with the game.
	The idea is to give users with graphics skills the ability to create effects using a layer just like in an image editor.
	Maybe they could use this to create custom CRT effects, custom vignettes, logos, custom hud elements, toggable help screens and crafting tables or something I haven't thought of.

	History:
	(*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
	
	Version 0.2 by seri14 & Marot Satil
	* Added the ability to scale and move the layer around on an x, y axis.

	Version 0.3 by seri14
	* Reduced the problem of layer color is blending with border color

	Version 0.4 by seri14 & Marot Satil
	* Added support for the additional seri14 DLL preprocessor options to minimize loaded textures.

	Version 0.5 by Uchu Suzume & Marot Satil
	* Rotation added.

	Version 0.6 by Uchu Suzume & Marot Satil
	* Added multiple blending modes thanks to the work of Uchu Suzume, prod80, and originalnicodr.

	Version 0.7 by Uchu Suzume & Marot Satil
	* Added Addition, Subtract, Divide blending modes.

	Version 0.8 by Uchu Suzume & Marot Satil
	* Sorted blending modes in a more logical fashion, grouping by type.

	Version 0.9 by Uchu Suzume & Marot Satil
	+ Implemented new Blending.fxh preprocessor macros.
	
	Version 1.0 by  Marot Satil
	* We summon the clones of the layers with our spells.
*/

#include "ReShade.fxh"
#include "Blending.fxh"
#include "Layer.fxh"

#ifndef LayerTex
	#define LayerTex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
#endif
#ifndef LAYER_SIZE_X
	#define LAYER_SIZE_X BUFFER_WIDTH
#endif
#ifndef LAYER_SIZE_Y
	#define LAYER_SIZE_Y BUFFER_HEIGHT
#endif
#ifndef LAYER_TEXFORMAT
	#define LAYER_TEXFORMAT RGBA8
#endif

uniform int Layer_Quantity <
	ui_type = "combo";
	ui_label = "Number of Layers";
	ui_tooltip = "The number of Layer techniques to generate. Enabling too many of these in a DirectX 9 game or on lower end hardware is a very, very bad idea.";
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
	ui_bind = "LAYER_QUANTITY";
> = 0;

#ifndef LAYER_QUANTITY
	#define LAYER_QUANTITY 0
#endif

LAYER_SUMMONING(Layer_Texture, LayerTex, LAYER_SIZE_X, LAYER_SIZE_Y, LAYER_TEXFORMAT, Layer_Sampler, "Layer 1", Layer_BlendMode, Layer_Blend, Layer_Scale, Layer_ScaleX, Layer_ScaleY, Layer_PosX, Layer_PosY, Layer_SnapRotate, Layer_Rotate, PS_Layer, Layer)

#if LAYER_QUANTITY > 0
	#ifndef Layer2Tex
		#define Layer2Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER2_SIZE_X
		#define LAYER2_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER2_SIZE_Y
		#define LAYER2_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER2_TEXFORMAT
		#define LAYER2_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer2_Texture, Layer2Tex, LAYER2_SIZE_X, LAYER2_SIZE_Y, LAYER2_TEXFORMAT, Layer2_Sampler, "Layer 2", Layer2_BlendMode, Layer2_Blend, Layer2_Scale, Layer2_ScaleX, Layer2_ScaleY, Layer2_PosX, Layer2_PosY, Layer2_SnapRotate, Layer2_Rotate, PS_Layer2, Layer2)
#endif

#if LAYER_QUANTITY > 1
	#ifndef Layer3Tex
		#define Layer3Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER3_SIZE_X
		#define LAYER3_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER3_SIZE_Y
		#define LAYER3_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER3_TEXFORMAT
		#define LAYER3_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer3_Texture, Layer3Tex, LAYER3_SIZE_X, LAYER3_SIZE_Y, LAYER3_TEXFORMAT, Layer3_Sampler, "Layer 3", Layer3_BlendMode, Layer3_Blend, Layer3_Scale, Layer3_ScaleX, Layer3_ScaleY, Layer3_PosX, Layer3_PosY, Layer3_SnapRotate, Layer3_Rotate, PS_Layer3, Layer3)
#endif

#if LAYER_QUANTITY > 2
	#ifndef Layer4Tex
		#define Layer4Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER4_SIZE_X
		#define LAYER4_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER4_SIZE_Y
		#define LAYER4_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER4_TEXFORMAT
		#define LAYER4_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer4_Texture, Layer4Tex, LAYER4_SIZE_X, LAYER4_SIZE_Y, LAYER4_TEXFORMAT, Layer4_Sampler, "Layer 4", Layer4_BlendMode, Layer4_Blend, Layer4_Scale, Layer4_ScaleX, Layer4_ScaleY, Layer4_PosX, Layer4_PosY, Layer4_SnapRotate, Layer4_Rotate, PS_Layer4, Layer4)
#endif

#if LAYER_QUANTITY > 3
	#ifndef Layer5Tex
		#define Layer5Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER5_SIZE_X
		#define LAYER5_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER5_SIZE_Y
		#define LAYER5_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER5_TEXFORMAT
		#define LAYER5_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer5_Texture, Layer5Tex, LAYER5_SIZE_X, LAYER5_SIZE_Y, LAYER5_TEXFORMAT, Layer5_Sampler, "Layer 5", Layer5_BlendMode, Layer5_Blend, Layer5_Scale, Layer5_ScaleX, Layer5_ScaleY, Layer5_PosX, Layer5_PosY, Layer5_SnapRotate, Layer5_Rotate, PS_Layer5, Layer5)
#endif

#if LAYER_QUANTITY > 4
	#ifndef Layer6Tex
		#define Layer6Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER6_SIZE_X
		#define LAYER6_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER6_SIZE_Y
		#define LAYER6_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER6_TEXFORMAT
		#define LAYER6_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer6_Texture, Layer6Tex, LAYER6_SIZE_X, LAYER6_SIZE_Y, LAYER6_TEXFORMAT, Layer6_Sampler, "Layer 6", Layer6_BlendMode, Layer6_Blend, Layer6_Scale, Layer6_ScaleX, Layer6_ScaleY, Layer6_PosX, Layer6_PosY, Layer6_SnapRotate, Layer6_Rotate, PS_Layer6, Layer6)
#endif

#if LAYER_QUANTITY > 5
	#ifndef Layer7Tex
		#define Layer7Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER7_SIZE_X
		#define LAYER7_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER7_SIZE_Y
		#define LAYER7_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER7_TEXFORMAT
		#define LAYER7_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer7_Texture, Layer7Tex, LAYER7_SIZE_X, LAYER7_SIZE_Y, LAYER7_TEXFORMAT, Layer7_Sampler, "Layer 7", Layer7_BlendMode, Layer7_Blend, Layer7_Scale, Layer7_ScaleX, Layer7_ScaleY, Layer7_PosX, Layer7_PosY, Layer7_SnapRotate, Layer7_Rotate, PS_Layer7, Layer7)
#endif

#if LAYER_QUANTITY > 6
	#ifndef Layer8Tex
		#define Layer8Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER8_SIZE_X
		#define LAYER8_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER8_SIZE_Y
		#define LAYER8_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER8_TEXFORMAT
		#define LAYER8_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer8_Texture, Layer8Tex, LAYER8_SIZE_X, LAYER8_SIZE_Y, LAYER8_TEXFORMAT, Layer8_Sampler, "Layer 8", Layer8_BlendMode, Layer8_Blend, Layer8_Scale, Layer8_ScaleX, Layer8_ScaleY, Layer8_PosX, Layer8_PosY, Layer8_SnapRotate, Layer8_Rotate, PS_Layer8, Layer8)
#endif

#if LAYER_QUANTITY > 7
	#ifndef Layer9Tex
		#define Layer9Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER9_SIZE_X
		#define LAYER9_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER9_SIZE_Y
		#define LAYER9_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER9_TEXFORMAT
		#define LAYER9_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer9_Texture, Layer9Tex, LAYER9_SIZE_X, LAYER9_SIZE_Y, LAYER9_TEXFORMAT, Layer9_Sampler, "Layer 9", Layer9_BlendMode, Layer9_Blend, Layer9_Scale, Layer9_ScaleX, Layer9_ScaleY, Layer9_PosX, Layer9_PosY, Layer9_SnapRotate, Layer9_Rotate, PS_Layer9, Layer9)
#endif

#if LAYER_QUANTITY > 8
	#ifndef Layer10Tex
		#define Layer10Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER10_SIZE_X
		#define LAYER10_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER10_SIZE_Y
		#define LAYER10_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER10_TEXFORMAT
		#define LAYER10_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer10_Texture, Layer10Tex, LAYER10_SIZE_X, LAYER10_SIZE_Y, LAYER10_TEXFORMAT, Layer10_Sampler, "Layer 10", Layer10_BlendMode, Layer10_Blend, Layer10_Scale, Layer10_ScaleX, Layer10_ScaleY, Layer10_PosX, Layer10_PosY, Layer10_SnapRotate, Layer10_Rotate, PS_Layer10, Layer10)
#endif

#if LAYER_QUANTITY > 9
	#ifndef Layer11Tex
		#define Layer11Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER11_SIZE_X
		#define LAYER11_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER11_SIZE_Y
		#define LAYER11_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER11_TEXFORMAT
		#define LAYER11_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer11_Texture, Layer11Tex, LAYER11_SIZE_X, LAYER11_SIZE_Y, LAYER11_TEXFORMAT, Layer11_Sampler, "Layer 11", Layer11_BlendMode, Layer11_Blend, Layer11_Scale, Layer11_ScaleX, Layer11_ScaleY, Layer11_PosX, Layer11_PosY, Layer11_SnapRotate, Layer11_Rotate, PS_Layer11, Layer11)
#endif

#if LAYER_QUANTITY > 10
	#ifndef Layer12Tex
		#define Layer12Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER12_SIZE_X
		#define LAYER12_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER12_SIZE_Y
		#define LAYER12_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER12_TEXFORMAT
		#define LAYER12_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer12_Texture, Layer12Tex, LAYER12_SIZE_X, LAYER12_SIZE_Y, LAYER12_TEXFORMAT, Layer12_Sampler, "Layer 12", Layer12_BlendMode, Layer12_Blend, Layer12_Scale, Layer12_ScaleX, Layer12_ScaleY, Layer12_PosX, Layer12_PosY, Layer12_SnapRotate, Layer12_Rotate, PS_Layer12, Layer12)
#endif

#if LAYER_QUANTITY > 11
	#ifndef Layer13Tex
		#define Layer13Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER13_SIZE_X
		#define LAYER13_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER13_SIZE_Y
		#define LAYER13_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER13_TEXFORMAT
		#define LAYER13_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer13_Texture, Layer13Tex, LAYER13_SIZE_X, LAYER13_SIZE_Y, LAYER13_TEXFORMAT, Layer13_Sampler, "Layer 13", Layer13_BlendMode, Layer13_Blend, Layer13_Scale, Layer13_ScaleX, Layer13_ScaleY, Layer13_PosX, Layer13_PosY, Layer13_SnapRotate, Layer13_Rotate, PS_Layer13, Layer13)
#endif

#if LAYER_QUANTITY > 12
	#ifndef Layer14Tex
		#define Layer14Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER14_SIZE_X
		#define LAYER14_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER14_SIZE_Y
		#define LAYER14_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER14_TEXFORMAT
		#define LAYER14_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer14_Texture, Layer14Tex, LAYER14_SIZE_X, LAYER14_SIZE_Y, LAYER14_TEXFORMAT, Layer14_Sampler, "Layer 14", Layer14_BlendMode, Layer14_Blend, Layer14_Scale, Layer14_ScaleX, Layer14_ScaleY, Layer14_PosX, Layer14_PosY, Layer14_SnapRotate, Layer14_Rotate, PS_Layer14, Layer14)
#endif

#if LAYER_QUANTITY > 13
	#ifndef Layer15Tex
		#define Layer15Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER15_SIZE_X
		#define LAYER15_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER15_SIZE_Y
		#define LAYER15_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER15_TEXFORMAT
		#define LAYER15_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer15_Texture, Layer15Tex, LAYER15_SIZE_X, LAYER15_SIZE_Y, LAYER15_TEXFORMAT, Layer15_Sampler, "Layer 15", Layer15_BlendMode, Layer15_Blend, Layer15_Scale, Layer15_ScaleX, Layer15_ScaleY, Layer15_PosX, Layer15_PosY, Layer15_SnapRotate, Layer15_Rotate, PS_Layer15, Layer15)
#endif

#if LAYER_QUANTITY > 14
	#ifndef Layer16Tex
		#define Layer16Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER16_SIZE_X
		#define LAYER16_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER16_SIZE_Y
		#define LAYER16_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER16_TEXFORMAT
		#define LAYER16_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer16_Texture, Layer16Tex, LAYER16_SIZE_X, LAYER16_SIZE_Y, LAYER16_TEXFORMAT, Layer16_Sampler, "Layer 16", Layer16_BlendMode, Layer16_Blend, Layer16_Scale, Layer16_ScaleX, Layer16_ScaleY, Layer16_PosX, Layer16_PosY, Layer16_SnapRotate, Layer16_Rotate, PS_Layer16, Layer16)
#endif

#if LAYER_QUANTITY > 15
	#ifndef Layer17Tex
		#define Layer17Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER17_SIZE_X
		#define LAYER17_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER17_SIZE_Y
		#define LAYER17_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER17_TEXFORMAT
		#define LAYER17_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer17_Texture, Layer17Tex, LAYER17_SIZE_X, LAYER17_SIZE_Y, LAYER17_TEXFORMAT, Layer17_Sampler, "Layer 17", Layer17_BlendMode, Layer17_Blend, Layer17_Scale, Layer17_ScaleX, Layer17_ScaleY, Layer17_PosX, Layer17_PosY, Layer17_SnapRotate, Layer17_Rotate, PS_Layer17, Layer17)
#endif

#if LAYER_QUANTITY > 16
	#ifndef Layer18Tex
		#define Layer18Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER18_SIZE_X
		#define LAYER18_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER18_SIZE_Y
		#define LAYER18_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER18_TEXFORMAT
		#define LAYER18_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer18_Texture, Layer18Tex, LAYER18_SIZE_X, LAYER18_SIZE_Y, LAYER18_TEXFORMAT, Layer18_Sampler, "Layer 18", Layer18_BlendMode, Layer18_Blend, Layer18_Scale, Layer18_ScaleX, Layer18_ScaleY, Layer18_PosX, Layer18_PosY, Layer18_SnapRotate, Layer18_Rotate, PS_Layer18, Layer18)
#endif

#if LAYER_QUANTITY > 17
	#ifndef Layer19Tex
		#define Layer19Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER19_SIZE_X
		#define LAYER19_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER19_SIZE_Y
		#define LAYER19_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER19_TEXFORMAT
		#define LAYER19_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer19_Texture, Layer19Tex, LAYER19_SIZE_X, LAYER19_SIZE_Y, LAYER19_TEXFORMAT, Layer19_Sampler, "Layer 19", Layer19_BlendMode, Layer19_Blend, Layer19_Scale, Layer19_ScaleX, Layer19_ScaleY, Layer19_PosX, Layer19_PosY, Layer19_SnapRotate, Layer19_Rotate, PS_Layer19, Layer19)
#endif

#if LAYER_QUANTITY > 18
	#ifndef Layer20Tex
		#define Layer20Tex "LayerStage.png" // Add your own image file with a unique file name to ?:\Users\Public\GShade Custom Shaders\Textures\ and provide the new file name in quotes in the Preprocessor Definitions under the shader's normal settings on the Home tab to change the image displayed!
	#endif
	#ifndef LAYER20_SIZE_X
		#define LAYER20_SIZE_X BUFFER_WIDTH
	#endif
	#ifndef LAYER20_SIZE_Y
		#define LAYER20_SIZE_Y BUFFER_HEIGHT
	#endif
	#ifndef LAYER20_TEXFORMAT
		#define LAYER20_TEXFORMAT RGBA8
	#endif

	LAYER_SUMMONING(Layer20_Texture, Layer20Tex, LAYER19_SIZE_X, LAYER19_SIZE_Y, LAYER19_TEXFORMAT, Layer20_Sampler, "Layer 20", Layer20_BlendMode, Layer20_Blend, Layer20_Scale, Layer20_ScaleX, Layer20_ScaleY, Layer20_PosX, Layer20_PosY, Layer20_SnapRotate, Layer20_Rotate, PS_Layer20, Layer20)
#endif