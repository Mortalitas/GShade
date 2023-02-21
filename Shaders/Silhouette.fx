// Made by Marot Satil for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
//
// A bit of an accidental discovery when playing with StageDepth.fx, this
// shader allows you to do a depth-based silhouette with any two images.
//
// PNG transparency is fully supported just like with StageDepth.fx!
//
// Textures Papyrus2.png through Papyrus6.png were provided by the ever-resouceful Lufreine.
// You can follow her via @Lufreine on Twitter!
//
// Shader & Code Copyright (c) 2023, Marot Satil
// All rights reserved.
//
// Textures & Images Copyright (c) 2023, Lufreine
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

#ifndef SilhouetteForegroundName
#define SilhouetteForegroundName "Papyrus2.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif

#ifndef SilhouetteBackgroundName
#define SilhouetteBackgroundName "Papyrus6.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif

#ifndef SILHOUETTE_TEXFORMAT
#define SILHOUETTE_TEXFORMAT RGBA8
#endif

uniform bool SEnable_Foreground_Color <
    ui_label = "Enable Foreground Color";
    ui_tooltip = "Enable this to use a color instead of a texture for the foreground!";   
> = false;

uniform float3 SForeground_Color <
    ui_type = "color";
    ui_label = "Foreground Color (If Enabled)";
    ui_tooltip = "If you enabled foreground color, use this to select the color.";
    ui_min = 0;
    ui_max = 255;
> = float3(0, 0, 0);

uniform float SForeground_Stage_Opacity <
    ui_label = "Foreground Opacity";
    ui_tooltip = "Set the transparency of the image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform int SForeground_Tex_Select <
    ui_label = "Foreground Texture";
    ui_tooltip = "The image to use in the foreground.";
    ui_type = "combo";
    ui_items = "Papyrus2.png\0Papyrus6.png\0Metal1.jpg\0Ice1.jpg\0Silhouette1.png\0Silhouette2.png\0";
    ui_bind = "SilhouetteTexture_Source";
> = 0;
#ifndef SilhouetteTexture_Source
#define SilhouetteTexture_Source 0
#endif

uniform bool SDisable_Background_Processing <
    ui_label = "Disable Background Processing";
    ui_tooltip = "Enable this to only modify the foreground!";   
> = false;

uniform bool SEnable_Background_Color <
    ui_label = "Enable Background Color";
    ui_tooltip = "Enable this to use a color instead of a texture for the background!";   
> = false;

uniform float3 SBackground_Color <
    ui_type = "color";
    ui_label = "Background Color (If Enabled)";
    ui_tooltip = "If you enabled background color, use this to select the color.";
    ui_min = 0;
    ui_max = 255;
> = float3(0, 0, 0);

uniform float SBackground_Stage_Opacity <
    ui_label = "Background Opacity";
    ui_tooltip = "Set the transparency of the image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform float SBackground_Stage_depth <
    ui_type = "slider";
    ui_min = 0.001;
    ui_max = 1.0;
    ui_label = "Background Depth";
> = 0.500;

uniform int SBackground_Tex_Select <
    ui_label = "Background Texture";
    ui_tooltip = "The image to use in the background.";
    ui_type = "combo";
    ui_items = "Papyrus2.png\0Papyrus6.png\0Metal1.jpg\0Ice1.jpg\0Silhouette1.png\0Silhouette2.png\0";
    ui_bind = "SilhouetteTexture2_Source";
> = 1;
#ifndef SilhouetteTexture2_Source
#define SilhouetteTexture2_Source 1
#endif

#if   SilhouetteTexture_Source == 0 // Papyrus2.png
#define _SOURCE_SILHOUETTE_FILE SilhouetteForegroundName
#elif SilhouetteTexture_Source == 1 // Papyrus6.png
#define _SOURCE_SILHOUETTE_FILE SilhouetteBackgroundName
#elif SilhouetteTexture_Source == 2 // Metal1.jpg
#define _SOURCE_SILHOUETTE_FILE "Metal1.jpg"
#elif SilhouetteTexture_Source == 3 // Ice1.jpg
#define _SOURCE_SILHOUETTE_FILE "Ice1.jpg"
#elif SilhouetteTexture_Source == 4 // Silhouette1.png
#define _SOURCE_SILHOUETTE_FILE "Silhouette1.png"
#elif SilhouetteTexture_Source == 5 // Silhouette2.png
#define _SOURCE_SILHOUETTE_FILE "Silhouette2.png"
#endif

#if   SilhouetteTexture2_Source == 0 // Papyrus2.png
#define _SOURCE_SILHOUETTE_FILE2 SilhouetteForegroundName
#elif SilhouetteTexture2_Source == 1 // Papyrus6.png
#define _SOURCE_SILHOUETTE_FILE2 SilhouetteBackgroundName
#elif SilhouetteTexture2_Source == 2 // Metal1.jpg
#define _SOURCE_SILHOUETTE_FILE2 "Metal1.jpg"
#elif SilhouetteTexture2_Source == 3 // Ice1.jpg
#define _SOURCE_SILHOUETTE_FILE2 "Ice1.jpg"
#elif SilhouetteTexture2_Source == 4 // Silhouette1.png
#define _SOURCE_SILHOUETTE_FILE2 "LayerStage.png"
#elif SilhouetteTexture2_Source == 5 // Silhouette2.png
#define _SOURCE_SILHOUETTE_FILE2 "LayerStage.png"
#endif

texture Silhouette_Back_Texture { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = SILHOUETTE_TEXFORMAT; };
sampler Silhouette_Back_Sampler { Texture = Silhouette_Back_Texture; };

texture Silhouette_Texture <source = _SOURCE_SILHOUETTE_FILE;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=SILHOUETTE_TEXFORMAT; };
sampler Silhouette_Sampler { Texture = Silhouette_Texture; };

texture Silhouette2_Texture < source = _SOURCE_SILHOUETTE_FILE2; > { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = SILHOUETTE_TEXFORMAT; };
sampler Silhouette2_Sampler { Texture = Silhouette2_Texture; };

void PS_SilhouetteBackbufffer(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float3 color : SV_Target)
{
    color = tex2D(ReShade::BackBuffer, texcoord).rgb;
}

void PS_SilhouetteForeground(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float3 color : SV_Target)
{
    const float4 Silhouette_Stage = tex2D(Silhouette_Sampler, texcoord);
    color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    if (SEnable_Foreground_Color == true)
    {
        color = lerp(color, SForeground_Color.rgb, SForeground_Stage_Opacity);
    }
    else
    {
        color = lerp(color, Silhouette_Stage.rgb, Silhouette_Stage.a * SForeground_Stage_Opacity);
    }
}

void PS_SilhouetteBackground(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float3 color : SV_Target)
{
    const float4 Silhouette2_Stage = tex2D(Silhouette2_Sampler, texcoord);
    const float depth = 1 - ReShade::GetLinearizedDepth(texcoord).r;
    color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    if (SEnable_Background_Color && depth < SBackground_Stage_depth)
    {
        color = lerp(color, SBackground_Color.rgb, SBackground_Stage_Opacity);
    }
    else if (SDisable_Background_Processing && depth < SBackground_Stage_depth)
    {
        color = lerp(color, tex2D(Silhouette_Back_Sampler, texcoord).rgb, SBackground_Stage_Opacity);
    }
    else if (depth < SBackground_Stage_depth)	
    {
        color = lerp(color, Silhouette2_Stage.rgb, Silhouette2_Stage.a * SBackground_Stage_Opacity);
    }
}

technique Silhouette
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SilhouetteBackbufffer;
		RenderTarget = Silhouette_Back_Texture;
    }
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SilhouetteForeground;
    }
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SilhouetteBackground;
    }
}