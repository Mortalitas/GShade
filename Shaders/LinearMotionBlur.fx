/** 
 - Reshade Linear Motion Blur 
 - First published 2022 - Copyright, Jakob Wapenhensch

# This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) License
- https://creativecommons.org/licenses/by-nc/4.0/
- https://creativecommons.org/licenses/by-nc/4.0/legalcode

# Human-readable summary of the License and not a substitute for https://creativecommons.org/licenses/by-nc/4.0/legalcode:
You are free to:
- Share — copy and redistribute the material in any medium or format
- Adapt — remix, transform, and build upon the material
- The licensor cannot revoke these freedoms as long as you follow the license terms.

Under the following terms:
- Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- NonCommercial — You may not use the material for commercial purposes.
- No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

Notices:
- You do not have to comply with the license for elements of the material in the public domain or where your use is permitted by an applicable exception or limitation.
- No warranties are given. The license may not give you all of the permissions necessary for your intended use. For example, other rights such as publicity, privacy, or moral rights may limit how you use the material.

 */


//  Includes
#include "ReShade.fxh"


//  Defines
uniform float frametime < source = "frametime"; >;


// UI
uniform float  UI_BLUR_LENGTH <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 1.0; ui_step = 0.01;
	ui_tooltip = "";
	ui_label = "Blur Length";
	ui_category = "Motion Blur";
> = 0.25;

uniform int  UI_BLUR_SAMPLES_MAX <
	ui_type = "slider";
	ui_min = 3; ui_max = 16; ui_step = 1;
	ui_tooltip = "";
	ui_label = "Samples";
	ui_category = "Motion Blur";
> = 5;

uniform bool UI_HQ_SAMPLING <
	ui_label = "High Quality Resampling";	
	ui_category = "Motion Blur";
> = false;


//  Textures & Samplers
texture2D texColor : COLOR;
sampler samplerColor { Texture = texColor; AddressU = Clamp; AddressV = Clamp; MipFilter = Linear; MinFilter = Linear; MagFilter = Linear; };

texture texMotionVectors          { Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RG16F; };
sampler SamplerMotionVectors2 { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };


// Passes
float4 BlurPS(float4 position : SV_Position, float2 texcoord : TEXCOORD ) : SV_Target
{	 
    float2 velocity = tex2D(SamplerMotionVectors2, texcoord).xy;
    float2 velocityTimed = velocity / frametime;
    float2 blurDist = velocityTimed * 50 * UI_BLUR_LENGTH;
    float2 sampleDist = blurDist / float(UI_BLUR_SAMPLES_MAX);
    int halfSamples = float(UI_BLUR_SAMPLES_MAX) / 2.0;

    float4 summedSamples = 0.0;
	[loop]
    for(int s = 0; s < UI_BLUR_SAMPLES_MAX; s++)
        summedSamples += tex2Dlod(samplerColor, float4(texcoord - sampleDist * (s - halfSamples), 0.0, 0.0)) / UI_BLUR_SAMPLES_MAX;

    return summedSamples;
}

technique LinearMotionBlur < ui_tooltip = "This technique requires qUINT_MotionVectors to be enabled and placed before (above) it in the load order."; >
{
    pass PassBlurThatShit
    {
        VertexShader = PostProcessVS;
        PixelShader = BlurPS;
    }
}