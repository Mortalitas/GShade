/*------------------.
| :: Description :: |
'-------------------/

	Layer (version 0.2)

	Author: CeeJay.dk
	License: MIT

	About:
	Blends an image with the game.
    The idea is to give users with graphics skills the ability to create effects using a layer just like in an image editor.
    Maybe they could use this to create custom CRT effects, custom vignettes, logos, custom hud elements, toggable help screens and crafting tables or something I haven't thought of.

	Ideas for future improvement:
    * More blend modes
    * Texture size, placement and tiling control
    * A default Layer texture with something useful in it

	History:
	(*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
	
	Version 0.2 by Seri14 & Marot Satil
    * Added the ability to scale and move the layer around on an x, y axis. 
*/

#include "ReShade.fxh"

uniform int cLayer_Select <
    ui_label = "Layer Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "Horizontal Vanilla\0Vertical Vanilla\0Nalukai Horizontal\0Yomi Black Horizontal\0Yomi White Horizontal\0";
> = 0;

uniform float cLayer_Blend <
    ui_label = "Opacity";
    ui_tooltip = "The transparency of the copyright notice.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float cLayer_Scale <
    ui_type = "slider";
  	ui_label = "Scale";
	  ui_min = 0.01; ui_max = 3.0;
	  ui_step = 0.001;
> = 1.001;

uniform float cLayer_PosX <
    ui_type = "slider";
  	ui_label = "Position X";
  	ui_min = -4.0; ui_max = 4.0;
  	ui_step = 0.001;
> = 0.5;

uniform float cLayer_PosY <
    ui_type = "slider";
  	ui_label = "Position Y";
  	ui_min = -4.0; ui_max = 4.0;
	  ui_step = 0.001;
> = 0.5;

texture Horiz_fourk_texture <source="Copyright4kH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_WIDTH; Format=RGBA8; };
sampler Horiz_fourk_sampler { Texture = Horiz_fourk_texture; };
texture Verti_fourk_texture <source="Copyright4kV.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_fourk_sampler { Texture = Verti_fourk_texture; };

texture Horiz_fancy_fourk_texture <source="CopyrightF4kH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_fancy_fourk_sampler { Texture = Horiz_fancy_fourk_texture; };

texture Horiz_yomi_b_texture <source="CopyrightYBlH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_yomi_b_sampler { Texture = Horiz_yomi_b_texture; };

texture Horiz_yomi_w_texture <source="CopyrightYWhH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_yomi_w_sampler { Texture = Horiz_yomi_w_texture; };

void PS_cLayer(in float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target) {
    const float4 backbuffer = tex2D(ReShade::BackBuffer, texcoord);
    const float2 cLayer_Pos = float2(cLayer_PosX, cLayer_PosY);

    if (cLayer_Select == 0)
    {
      const float2 scale = 1.0 / (float2(411.0, 22.0) / ReShade::ScreenSize * cLayer_Scale);
      const float4 cLayer  = tex2D(Horiz_fourk_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	  color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
    }
    else if (cLayer_Select == 1)
    {
      const float2 scale = 1.0 / (float2(22.0, 412.0) / ReShade::ScreenSize * cLayer_Scale);
      const float4 cLayer  = tex2D(Verti_fourk_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	  color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
    }
    else if (cLayer_Select == 2)
    {
      const float2 scale = 1.0 / (float2(1162.0, 135.0) / ReShade::ScreenSize * cLayer_Scale);
      const float4 cLayer  = tex2D(Horiz_fancy_fourk_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	  color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
    }
    else if (cLayer_Select == 3)
    {
      const float2 scale = 1.0 / (float2(1162.0, 135.0) / ReShade::ScreenSize * cLayer_Scale);
      const float4 cLayer  = tex2D(Horiz_yomi_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	  color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
    }
    else
    {
      const float2 scale = 1.0 / (float2(1162.0, 135.0) / ReShade::ScreenSize * cLayer_Scale);
      const float4 cLayer  = tex2D(Horiz_yomi_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	  color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
    }
    color.a = backbuffer.a;
}

technique XIVCopyright {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_cLayer;
    }
}