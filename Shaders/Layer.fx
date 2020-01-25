/*------------------.
| :: Description :: |
'-------------------/

    Layer (version 0.4)

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

    Version 0.4 by seri14 & Marot Satil
    * Added support for the additional seri14 DLL preprocessor functions.
*/

#include "ReShade.fxh"

#ifndef LayerTex
#define LayerTex "LayerA.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif
#ifndef LAYER_SIZE_X
#define LAYER_SIZE_X BUFFER_WIDTH
#endif
#ifndef LAYER_SIZE_Y
#define LAYER_SIZE_Y BUFFER_HEIGHT
#endif

#if LAYER_SINGLECHANNEL
#define TEXFORMAT R8
#else
#define TEXFORMAT RGBA8
#endif

uniform int Layer_Select <
    ui_label = "Layer Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "Angelite Layer.png | ReShade 3/4\0LensDB.png (Angelite)\0LensDB.png\0Dirt.png (Angelite)\0Dirt.png (ReShade 4)\0Dirt.jpg (ReShade 3)\0";
    ui_bind = "LayerTexture_Source";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef LayerTexture_Source
#define LayerTexture_Source 0
#endif

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

#if   LayerTexture_Source == 0 // Angelite Layer.png | ReShade 3/4
#define _SOURCE_LAYER_FILE LayerTex
#elif LayerTexture_Source == 1 // LensDB.png (Angelite)
#define _SOURCE_LAYER_FILE "LensDBA.png"
#elif LayerTexture_Source == 2 // LensDB.png
#define _SOURCE_LAYER_FILE "LensDB2.png"
#elif LayerTexture_Source == 3 // Dirt.png (Angelite)
#define _SOURCE_LAYER_FILE "DirtA.png"
#elif LayerTexture_Source == 4 // Dirt.png (ReShade 4)
#define _SOURCE_LAYER_FILE "Dirt4.png"
#elif LayerTexture_Source == 5 // Dirt.jpg (ReShade 3)
#define _SOURCE_LAYER_FILE "Dirt3.jpg"
#endif

texture Layer_Tex <source = _SOURCE_LAYER_FILE;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Layer_Sampler {
    Texture = Layer_Tex;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

#define _layerCoord(_) (_ / (float2(LAYER_SIZE_X, LAYER_SIZE_Y) * Layer_Scale / BUFFER_SCREEN_SIZE))

void PS_Layer(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
    const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);
    const float2 pickCoord = _layerCoord(texCoord) + float2(Layer_PosX, Layer_PosY) * (1.0 - _layerCoord(1.0));
    
    passColor = tex2D(Layer_Sampler, pickCoord) * all(pickCoord == saturate(pickCoord));
    passColor = lerp(backColor, passColor, passColor.a * Layer_Blend);
    passColor.a = backColor.a;
}

technique Layer {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer;
    }
}
