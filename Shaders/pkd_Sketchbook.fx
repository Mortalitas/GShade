/*
    UIMask (base for SketchMask techniques) Copyright (c) 2017 Lucas Melo
    Layer (base for Layer techniques) by CeeJay.dk, seri14, and Merot Satil
    
    Modified into pkd_Sketchbook.fx by Packetdancer to avoid conflicts with
    existing textures. (Yes, I could've just done preprocessor for Layer, 
    but not for UIMask without modification; I might as well just bundle
    them all.)

    MIT Licensed:

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

#ifndef SKETCHMASK_MULTICHANNEL
    #define SketchMask_MULTICHANNEL 0
#endif

#ifndef SKETCHMASK_TOGGLEKEY_RED
    #define SketchMask_TOGGLEKEY_RED 0x67 //Numpad 7
#endif

#ifndef SKETCHMASK_TOGGLEKEY_GREEN
    #define SKETCHMASK_TOGGLEKEY_GREEN 0x68 //Numpad 8
#endif

#ifndef SKETCHMASK_TOGGLEKEY_BLUE
    #define SKETCHMASK_TOGGLEKEY_BLUE 0x69 //Numpad 9
#endif

#if !SKETCHMASK_MULTICHANNEL
    #define TEXFORMAT R8
#else
    #define TEXFORMAT RGBA8
#endif

uniform float fMask_Intensity <
    ui_type = "slider";
    ui_label = "Mask Intensity";
    ui_tooltip = "How much should the paper obscure the pencil drawing.";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform bool bDisplayMask <
    ui_label = "Display Mask";
    ui_tooltip = 
        "Display the mask texture.\n"
        "Useful for checking if you replace the mask image.";
> = false;

uniform int iMask_Select <
    ui_label = "Mask Style";
    ui_tooltip = "What should the edges of this sketch look like?";
    ui_type = "combo";
    ui_items = "Rough\0Smooth";
> = 0;

#if SKETCHMASK_MULTICHANNEL
uniform bool toggle_red <source="key"; keycode=SKETCHMASK_TOGGLEKEY_RED; toggle=true;>;
uniform bool toggle_green <source="key"; keycode=SKETCHMASK_TOGGLEKEY_GREEN; toggle=true;>;
uniform bool toggle_blue <source="key"; keycode=SKETCHMASK_TOGGLEKEY_BLUE; toggle=true;>;
#endif

texture tSketchMask_Backup { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };

texture tSketchMask_Mask <source="SketchMask.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
texture tSketchMask_Mask2 <source="SketchMask2.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };

sampler sSketchMask_Mask { Texture = tSketchMask_Mask; };
sampler sSketchMask_Mask2 { Texture = tSketchMask_Mask2; };
sampler sSketchMask_Backup { Texture = tSketchMask_Backup; };

float4 PS_Backup(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    return tex2D(ReShade::BackBuffer, uv);
}

float CalculateMask(sampler maskSampler, float2 uv)
{
    #if !SketchMask_MULTICHANNEL
    return tex2D(maskSampler, uv).r;
    #else
    //This just works, it basically adds masking with each channel that has been toggled.
    //'toggle_red' is inverted so it defaults to 'true' upon start.
    return mask = saturate(1.0 - dot(1.0 - tex2D(maskSampler, uv).rgb, float3(!toggle_red, toggle_green, toggle_blue)));
    #endif
}

float4 PS_ApplyMask(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {

    float mask = 0.0;

    if (iMask_Select == 0) 
    {
        mask = CalculateMask(sSketchMask_Mask, uv);
    }
    else if (iMask_Select == 1)
    {
        mask = CalculateMask(sSketchMask_Mask2, uv);
    }

    mask = lerp(1.0, mask, fMask_Intensity);
    float3 col = lerp(tex2D(sSketchMask_Backup, uv).rgb, tex2D(ReShade::BackBuffer, uv).rgb, mask);
	if (bDisplayMask)
		col = mask;
    
    return float4(col, 1.0);
}

technique pkd_Sketch_MaskCopy {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Backup;
        RenderTarget = tSketchMask_Backup;
    }
}

technique pkd_Sketch_MaskApply {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_ApplyMask;
    }
}

/*
Layer-blending techniques are from CeeJay.dk's original MIT-licensed Layer#.fx template,
and, again, modified by Packetdancer and included in Sketchbook.fx to avoid conflict with
existing Layer textures people are using.
*/

uniform float Layer_PencilHatch_Blend <
    ui_label = "Pencil Hatch Opacity";
    ui_tooltip = "The transparency of the pencil hatching layer.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float Layer_PencilHatch_Scale <
  ui_type = "slider";
	ui_label = "Pencil Hatch Scale";
	ui_min = 0.01; ui_max = 5.0;
	ui_step = 0.001;
> = 1.001;

uniform float Layer_PencilHatch_PosX <
  ui_type = "slider";
	ui_label = "Pencil Hatch Position X";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

uniform float Layer_PencilHatch_PosY <
  ui_type = "slider";
	ui_label = "Pencil Hatch Position Y";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

texture Layer_PencilHatch_texture <source="SketchPencil.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Layer_PencilHatch_sampler { Texture = Layer_PencilHatch_texture; };

void PS_Layer_PencilHatch(in float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target) {
    const float4 backbuffer = tex2D(ReShade::BackBuffer, texcoord);
    const float2 Layer_Pos = float2(Layer_PencilHatch_PosX, Layer_PencilHatch_PosY);
    const float2 scale = 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT) / BUFFER_SCREEN_SIZE * Layer_PencilHatch_Scale);
    const float4 Layer  = tex2D(Layer_PencilHatch_sampler, texcoord * scale + (1.0 - scale) * Layer_Pos);
  	color = lerp(backbuffer, Layer, Layer.a * Layer_PencilHatch_Blend);
  	color.a = backbuffer.a;
}

technique pkd_Sketch_Pencil {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer_PencilHatch;
    }
}

uniform float Layer_PaperBase_Blend <
    ui_label = "Paper Base Opacity";
    ui_tooltip = "The transparency of the paper base layer.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float Layer_PaperBase_Scale <
  ui_type = "slider";
	ui_label = "Paper Base Scale";
	ui_min = 0.01; ui_max = 5.0;
	ui_step = 0.001;
> = 1.001;

uniform float Layer_PaperBase_PosX <
  ui_type = "slider";
	ui_label = "Paper Base Position X";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

uniform float Layer_PaperBase_PosY <
  ui_type = "slider";
	ui_label = "Paper Base Position Y";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

texture Layer_PaperBase_texture <source="SketchPaperBase.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Layer_PaperBase_sampler { Texture = Layer_PaperBase_texture; };

void PS_Layer_PaperBase(in float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target) {
    const float4 backbuffer = tex2D(ReShade::BackBuffer, texcoord);
    const float2 Layer_Pos = float2(Layer_PaperBase_PosX, Layer_PaperBase_PosY);
    const float2 scale = 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT) / BUFFER_SCREEN_SIZE * Layer_PaperBase_Scale);
    const float4 Layer  = tex2D(Layer_PaperBase_sampler, texcoord * scale + (1.0 - scale) * Layer_Pos);
  	color = lerp(backbuffer, Layer, Layer.a * Layer_PaperBase_Blend);
  	color.a = backbuffer.a;
}

technique pkd_Sketch_PaperBase {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer_PaperBase;
    }
}

uniform float Layer_PaperOverlay_Blend <
    ui_label = "Paper Texture Opacity";
    ui_tooltip = "The transparency of the paper texture layer.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float Layer_PaperOverlay_Scale <
  ui_type = "slider";
	ui_label = "Paper Texture Scale";
	ui_min = 0.01; ui_max = 5.0;
	ui_step = 0.001;
> = 1.001;

uniform float Layer_PaperOverlay_PosX <
  ui_type = "slider";
	ui_label = "Paper Texture Position X";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

uniform float Layer_PaperOverlay_PosY <
  ui_type = "slider";
	ui_label = "Paper Texture Position Y";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

texture Layer_PaperOverlay_texture <source="SketchPaperOverlay.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Layer_PaperOverlay_sampler { Texture = Layer_PaperOverlay_texture; };

void PS_Layer_PaperOverlay(in float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target) {
    const float4 backbuffer = tex2D(ReShade::BackBuffer, texcoord);
    const float2 Layer_Pos = float2(Layer_PaperOverlay_PosX, Layer_PaperOverlay_PosY);
    const float2 scale = 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT) / BUFFER_SCREEN_SIZE * Layer_PaperOverlay_Scale);
    const float4 Layer  = tex2D(Layer_PaperOverlay_sampler, texcoord * scale + (1.0 - scale) * Layer_Pos);
  	color = lerp(backbuffer, Layer, Layer.a * Layer_PaperOverlay_Blend);
  	color.a = backbuffer.a;
}

technique pkd_Sketch_PaperOverlay {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer_PaperOverlay;
    }
}

