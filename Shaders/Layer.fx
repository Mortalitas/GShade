/*------------------.
| :: Description :: |
'-------------------/

	Layer (version 0.1)

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
	
	Version 0.1
    *
*/

#include "ReShade.fxh"

#if LAYER_SINGLECHANNEL //I plan to have some option to let users set this for performance sake.
    #define TEXFORMAT R8
#else
    #define TEXFORMAT RGBA8
#endif

uniform int Layer_Select <
    ui_label = "Layer Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "Angelite Layer.png | ReShade 3/4 LensDB.png\0LensDB.png (Angelite)\0Dirt.png (Angelite)\0Dirt.png (ReShade 4)\0Dirt.jpg (ReShade 3)\0";
> = 0;

//TODO blend by alpha
uniform float Layer_Blend <
    ui_label = "Layer Blend";
    ui_tooltip = "How much to blend layer with the original image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;



texture Layer_texture <source="LayerA.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Layer_sampler { Texture = Layer_texture; };

texture LensDB_angel_texture <source="LensDBA.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler LensDB_angel_sampler { Texture = LensDB_angel_texture; };

texture Dirt_png_texture <source="DirtA.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Dirt_png_sampler { Texture = Dirt_png_texture; };

texture Dirt_four_texture <source="Dirt4.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Dirt_four_sampler { Texture = Dirt_four_texture; };

texture Dirt_jpg_texture <source="Dirt3.jpg";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Dirt_jpg_sampler { Texture = Dirt_jpg_texture; };

float3 PS_Layer(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    if (Layer_Select == 0)
    {
      float4 layer = tex2D(Layer_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * Layer_Blend);
      return color;
      //return layer.aaa;
    }
    else if (Layer_Select == 1)
    {
      float4 layer = tex2D(LensDB_angel_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * Layer_Blend);
      return color;
    }
    else if (Layer_Select == 2)
    {
      float4 layer = tex2D(Dirt_png_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * Layer_Blend);
      return color;
    }
    else if (Layer_Select == 3)
    {
      float4 layer = tex2D(Dirt_four_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * Layer_Blend);
      return color;
    }
    else
    {
      float4 layer = tex2D(Dirt_jpg_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * Layer_Blend);
      return color;
    }
}

technique Layer {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer;
    }
}