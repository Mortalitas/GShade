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

uniform float PopArtLayer_Blend <
    ui_label = "Layer Blend";
    ui_tooltip = "How much to blend layer with the original image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

uniform float PopArtLayer_Scale <
  ui_type = "slider";
	ui_label = "Scale";
	ui_min = 0.01; ui_max = 5.0;
	ui_step = 0.001;
> = 1.001;

uniform float PopArtLayer_PosX <
  ui_type = "slider";
	ui_label = "Position X";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

uniform float PopArtLayer_PosY <
  ui_type = "slider";
	ui_label = "Position Y";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

texture PopArtLayer_texture <source="PopArt.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler PopArtLayer_sampler { Texture = PopArtLayer_texture; };

void PS_PopArtLayer(in float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target) {
    const float4 backbuffer = tex2D(ReShade::BackBuffer, texcoord);
    const float2 Layer_Pos = float2(PopArtLayer_PosX, PopArtLayer_PosY);
    const float2 scale = 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT) / ReShade::ScreenSize * PopArtLayer_Scale);
    const float4 Layer  = tex2D(PopArtLayer_sampler, texcoord * scale + (1.0 - scale) * Layer_Pos);
  	color = lerp(backbuffer, Layer, Layer.a * PopArtLayer_Blend);
  	color.a = backbuffer.a;
}

technique PopArtLayer {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_PopArtLayer;
    }
}