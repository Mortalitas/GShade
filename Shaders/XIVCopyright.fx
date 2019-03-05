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

uniform int cLayer_Select <
    ui_label = "Layer Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "Horizontal 1080p\0Vertical 1080p\0Horizontal 1440p\0Vertical 1440p\0Horizontal 4k\0Vertical 4k\0";
> = 0;

//TODO blend by alpha
uniform float cLayer_Blend <
    ui_label = "Opacity";
    ui_tooltip = "The transparency of the copyright notice.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;


texture Horiz_texture <source="Copyright1080pH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Horiz_sampler { Texture = Horiz_texture; };
texture Verti_texture <source="Copyright1080pV.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Verti_sampler { Texture = Verti_texture; };

texture Horiz_four_texture <source="Copyright1440pH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Horiz_four_sampler { Texture = Horiz_four_texture; };
texture Verti_four_texture <source="Copyright1440pV.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Verti_four_sampler { Texture = Verti_four_texture; };

texture Horiz_fourk_texture <source="Copyright4kH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Horiz_fourk_sampler { Texture = Horiz_fourk_texture; };
texture Verti_fourk_texture <source="Copyright4kV.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };
sampler Verti_fourk_sampler { Texture = Verti_fourk_texture; };

float3 PS_cLayer(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    if (cLayer_Select == 0)
    {
      float4 layer = tex2D(Horiz_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * cLayer_Blend);
      return color;
      //return layer.aaa;
    }
    else if (cLayer_Select == 1)
    {
      float4 layer = tex2D(Verti_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * cLayer_Blend);
      return color;
    }
    else if (cLayer_Select == 2)
    {
      float4 layer = tex2D(Horiz_four_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * cLayer_Blend);
      return color;
    }
    else if (cLayer_Select == 3)
    {
      float4 layer = tex2D(Verti_four_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * cLayer_Blend);
      return color;
    }
    else if (cLayer_Select == 4)
    {
      float4 layer = tex2D(Horiz_fourk_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * cLayer_Blend);
      return color;
    }
    else
    {
      float4 layer = tex2D(Verti_fourk_sampler, texcoord).rgba;
      color = lerp(color, layer.rgb, layer.a * cLayer_Blend);
      return color;
    }
}

technique XIVCopyright {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_cLayer;
    }
}