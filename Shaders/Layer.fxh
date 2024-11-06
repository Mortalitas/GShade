/*------------------.
| :: Description :: |
'-------------------/

	Layer

	Authors: CeeJay.dk, seri14, Marot Satil, Uchu Suzume, prod80, originalnicodr
	License: MIT
	
	See Layer.fx for more information and a changelog.


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

#define LAYER_SUMMONING(Layer_Texture, LayerTex, Layer_Size_X, Layer_Size_Y, Layer_Texformat, Layer_Sampler, Layer_Category, Layer_Saturation, Layer_Brightness, LAYER_BLEND_MODE, Layer_Blend, LAYER_SCALE, Layer_ScaleX, Layer_ScaleY, Layer_PosX, Layer_PosY, Layer_SnapRotate, Layer_Rotate, PS_Layer, LAYER_NAME) \
texture Layer_Texture <source = LayerTex;> { Width = Layer_Size_X; Height = Layer_Size_Y; Format=Layer_Texformat; }; \
sampler Layer_Sampler { \
	Texture = Layer_Texture; \
	AddressU = CLAMP; \
	AddressV = CLAMP; \
}; \
\
\
uniform float Layer_Saturation < \
	ui_category = Layer_Category; \
	ui_type = "slider"; \
	ui_label = "Saturation"; \
	ui_tooltip = "The amount of saturation applied to the layer."; \
	ui_min = 0.0; \
	ui_max = 2.0; \
> = 1.0; \
\
uniform float Layer_Brightness < \
	ui_category = Layer_Category; \
	ui_type = "slider"; \
	ui_label = "Brightness"; \
	ui_tooltip = "The amount of brightness applied to the layer."; \
	ui_min = -2.0; \
	ui_max = 2.0; \
> = 0.0; \
\
BLENDING_COMBO(LAYER_BLEND_MODE, "Blending Mode", "Select the blending mode applied to the layer.", Layer_Category, true, 0, 0) \
\
uniform float Layer_Blend < \
	ui_category = Layer_Category; \
	ui_label = "Blending Amount"; \
	ui_tooltip = "The amount of blending applied to the layer."; \
	ui_type = "slider"; \
	ui_min = 0.0; \
	ui_max = 1.0; \
	ui_step = 0.001; \
> = 1.0; \
\
uniform float LAYER_SCALE < \
	ui_category = Layer_Category; \
	ui_type = "slider"; \
	ui_label = "Scale X & Y"; \
	ui_min = 0.001; ui_max = 5.0; \
	ui_step = 0.001; \
> = 1.001; \
\
uniform float Layer_ScaleX < \
	ui_category = Layer_Category; \
	ui_type = "slider"; \
	ui_label = "Scale X"; \
	ui_min = 0.001; ui_max = 5.0; \
	ui_step = 0.001; \
> = 1.0; \
\
uniform float Layer_ScaleY < \
	ui_category = Layer_Category; \
	ui_type = "slider"; \
	ui_label = "Scale Y"; \
	ui_min = 0.001; ui_max = 5.0; \
	ui_step = 0.001; \
> = 1.0; \
\
uniform float Layer_PosX < \
	ui_category = Layer_Category; \
	ui_type = "slider"; \
	ui_label = "Position X"; \
	ui_min = -2.0; ui_max = 2.0; \
	ui_step = 0.001; \
> = 0.5; \
\
uniform float Layer_PosY < \
	ui_category = Layer_Category; \
	ui_type = "slider"; \
	ui_label = "Position Y"; \
	ui_min = -2.0; ui_max = 2.0; \
	ui_step = 0.001; \
> = 0.5; \
\
uniform int Layer_SnapRotate < \
	ui_category = Layer_Category; \
	ui_type = "combo"; \
	ui_label = "Snap Rotation"; \
	ui_items = "None\0" \
			   "90 Degrees\0" \
			   "-90 Degrees\0" \
			   "180 Degrees\0" \
			   "-180 Degrees\0"; \
	ui_tooltip = "Snap rotation to a specific angle."; \
> = false; \
\
uniform float Layer_Rotate < \
	ui_category = Layer_Category; \
	ui_label = "Rotate"; \
	ui_type = "slider"; \
	ui_min = -180.0; \
	ui_max = 180.0; \
	ui_step = 0.01; \
> = 0; \
\
\
void PS_Layer(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) { \
	const float4 backColor = tex2D(ReShade::BackBuffer, texCoord); \
	const float3 pivot = float3(0.5, 0.5, 0.0); \
	const float3 mulUV = float3(texCoord.x, texCoord.y, 1); \
	const float2 ScaleSize = (float2(Layer_Size_X, Layer_Size_Y) * LAYER_SCALE); \
	const float ScaleX =  ScaleSize.x * Layer_ScaleX; \
	const float ScaleY =  ScaleSize.y * Layer_ScaleY; \
	float Rotate = Layer_Rotate * (3.1415926 / 180.0); \
\
	switch(Layer_SnapRotate) \
	{ \
		default: \
			break; \
		case 1: \
			Rotate = -90.0 * (3.1415926 / 180.0); \
			break; \
		case 2: \
			Rotate = 90.0 * (3.1415926 / 180.0); \
			break; \
		case 3: \
			Rotate = 0.0; \
			break; \
		case 4: \
			Rotate = 180.0 * (3.1415926 / 180.0); \
			break; \
	} \
\
	const float3x3 positionMatrix = float3x3 ( \
		1, 0, 0, \
		0, 1, 0, \
		-Layer_PosX, -Layer_PosY, 1 \
	); \
	const float3x3 scaleMatrix = float3x3 ( \
		1/ScaleX, 0, 0, \
		0,  1/ScaleY, 0, \
		0, 0, 1 \
	); \
	const float3x3 rotateMatrix = float3x3 ( \
		cos (Rotate), sin(Rotate), 0, \
		-sin(Rotate), cos(Rotate), 0, \
		0, 0, 1 \
	); \
	const float3 SumUV = mul (mul (mul (mulUV, positionMatrix) * float3(BUFFER_SCREEN_SIZE, 1.0), rotateMatrix), scaleMatrix); \
	passColor = tex2D(Layer_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot)); \
\
	passColor.rgb = (passColor.rgb - dot(passColor.rgb, 0.333)) * Layer_Saturation + dot(passColor.rgb, 0.333); \
\
	passColor.rgb = passColor.rgb + Layer_Brightness; \
\
	passColor = float4(ComHeaders::Blending::Blend(LAYER_BLEND_MODE, backColor.rgb, passColor.rgb, passColor.a * Layer_Blend), backColor.a); \
} \
\
\
technique LAYER_NAME { \
	pass \
	{ \
		VertexShader = PostProcessVS; \
		PixelShader  = PS_Layer; \
	} \
} \