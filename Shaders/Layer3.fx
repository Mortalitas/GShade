/*------------------.
| :: Description :: |
'-------------------/

    Layer (version 0.3)

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
    
    Version 0.2 by seri14 & Marot Satil
    * Added the ability to scale and move the layer around on an x, y axis.

    Version 0.3 by seri14
    * Reduced the problem of layer color is blending with border color
*/

#include "ReShade.fxh"

#ifndef Layer3Tex
#define Layer3Tex "Layer3.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif
#ifndef LAYER3_SIZE_X
#define LAYER3_SIZE_X BUFFER_WIDTH
#endif
#ifndef LAYER3_SIZE_Y
#define LAYER3_SIZE_Y BUFFER_HEIGHT
#endif

#if LAYER3_SINGLECHANNEL
#define TEXFORMAT R8
#else
#define TEXFORMAT RGBA8
#endif

uniform float Layer3_Blend <
    ui_label = "Opacity";
    ui_tooltip = "The transparency of the layer.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float Layer3_Scale <
  ui_type = "slider";
    ui_label = "Scale";
    ui_min = 0.01; ui_max = 5.0;
    ui_step = 0.001;
> = 1.001;

uniform float Layer3_PosX <
  ui_type = "slider";
    ui_label = "Position X";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform float Layer3_PosY <
  ui_type = "slider";
    ui_label = "Position Y";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

texture Layer3_Texture <source=Layer3Tex;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Layer3_Sampler { Texture = Layer3_Texture; };

#define _layer3Coord(_) (_ / (float2(LAYER3_SIZE_X, LAYER3_SIZE_Y) * Layer3_Scale / BUFFER_SCREEN_SIZE))

void PS_Layer3(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
	const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);
	const float2 pickCoord = _layer3Coord(texCoord) + float2(Layer3_PosX, Layer3_PosY) * (1.0 - _layer3Coord(1.0));

	passColor = tex2D(Layer3_Sampler, pickCoord) * all(pickCoord == saturate(pickCoord));
	passColor = lerp(backColor, passColor, passColor.a * Layer3_Blend);
	passColor.a = backColor.a;
}

technique Layer3 {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer3;
    }
}