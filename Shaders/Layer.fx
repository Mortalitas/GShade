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

uniform int Layer_Select <
    ui_label = "Layer Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "Angelite Layer.png | ReShade 3/4 LensDB.png\0LensDB.png (Angelite)\0Dirt.png (Angelite)\0Dirt.png (ReShade 4)\0Dirt.jpg (ReShade 3)\0";
> = 0;

uniform float Layer_Blend <
    ui_label = "Opacity";
    ui_tooltip = "The transparency of the layer.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float Layer_Scale <
  ui_type = "slider";
	ui_label = "Scale";
	ui_min = 0.01; ui_max = 5.0;
	ui_step = 0.001;
> = 1.001;

uniform float Layer_PosX <
  ui_type = "slider";
	ui_label = "Position X";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

uniform float Layer_PosY <
  ui_type = "slider";
	ui_label = "Position Y";
	ui_min = -2.0; ui_max = 2.0;
	ui_step = 0.001;
> = 0.5;

texture Layer_texture <source="LayerA.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Layer_sampler { Texture = Layer_texture; };

texture LensDB_angel_texture <source="LensDBA.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler LensDB_angel_sampler { Texture = LensDB_angel_texture; };

texture Dirt_png_texture <source="DirtA.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Dirt_png_sampler { Texture = Dirt_png_texture; };

texture Dirt_four_texture <source="Dirt4.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Dirt_four_sampler { Texture = Dirt_four_texture; };

texture Dirt_jpg_texture <source="Dirt3.jpg";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Dirt_jpg_sampler { Texture = Dirt_jpg_texture; };

void PS_Layer(in float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target) {
    const float4 backbuffer = tex2D(ReShade::BackBuffer, texcoord);
    const float2 Layer_Pos = float2(Layer_PosX, Layer_PosY);
    if (Layer_Select == 0)
    {
      const float2 scale = 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT) / ReShade::ScreenSize * Layer_Scale);
      const float4 Layer  = tex2D(Layer_sampler, texcoord * scale + (1.0 - scale) * Layer_Pos);
  	  color = lerp(backbuffer, Layer, Layer.a * Layer_Blend);
    }
    else if (Layer_Select == 1)
    {
      const float2 scale = 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT) / ReShade::ScreenSize * Layer_Scale);
      const float4 Layer  = tex2D(LensDB_angel_sampler, texcoord * scale + (1.0 - scale) * Layer_Pos);
  	  color = lerp(backbuffer, Layer, Layer.a * Layer_Blend);
    }
    else if (Layer_Select == 2)
    {
      const float2 scale = 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT) / ReShade::ScreenSize * Layer_Scale);
      const float4 Layer  = tex2D(Dirt_png_sampler, texcoord * scale + (1.0 - scale) * Layer_Pos);
  	  color = lerp(backbuffer, Layer, Layer.a * Layer_Blend);
    }
    else if (Layer_Select == 3)
    {
      const float2 scale = 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT) / ReShade::ScreenSize * Layer_Scale);
      const float4 Layer  = tex2D(Dirt_four_sampler, texcoord * scale + (1.0 - scale) * Layer_Pos);
  	  color = lerp(backbuffer, Layer, Layer.a * Layer_Blend);
    }
    else
    {
      const float2 scale = 1.0 / (float2(BUFFER_WIDTH, BUFFER_HEIGHT) / ReShade::ScreenSize * Layer_Scale);
      const float4 Layer  = tex2D(Dirt_jpg_sampler, texcoord * scale + (1.0 - scale) * Layer_Pos);
  	  color = lerp(backbuffer, Layer, Layer.a * Layer_Blend);
    }
    color.a = backbuffer.a;
}

technique Layer {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer;
    }
}