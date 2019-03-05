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

//TODO blend by alpha
uniform float PopArtLayer_Blend <
    ui_label = "Layer Blend";
    ui_tooltip = "How much to blend layer with the original image.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.002;
> = 1.0;

texture PopArtLayer_texture <source="PopArt.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=TEXFORMAT; };

sampler PopArtLayer_sampler { Texture = PopArtLayer_texture; };

float3 PopArtPS_Layer(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float4 PopArtlayer = tex2D(PopArtLayer_sampler, texcoord).rgba;
    
    color = lerp(color, PopArtlayer.rgb, PopArtlayer.a * PopArtLayer_Blend);

    return color;    
    //return PopArtlayer.aaa;
}

technique PopArtLayer {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PopArtPS_Layer;
    }
}