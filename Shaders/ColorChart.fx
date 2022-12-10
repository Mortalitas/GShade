/*------------------.
| :: Description :: |
'-------------------/

    Color Chart (version 0.1)

    Authors: CeeJay.dk, seri14, Marot Satil, uchu suzume, prod80, originalnicodr
    License: MIT

    About:
    Display a color chart like used for color grading work in video/cinema production.
    Can be useful to see how presets and shaders affect to colors.
    Placing it at the top of the preset will show you the color changes of entire preset,
    placing it in the middle will show you what each shader does to the color,
    placing it at the bottom will show your screen's color property by simply.
    
    Color values refer to the following link to X-Rite L*a*b* D50 (formulations AFTER Nov. 2014).
    https://www.babelcolor.com/colorchecker-2.htm


    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
    
    Version 0.1 uchu suzume & Marot Satil
    * Created by uchu suzume, with code optimization by Marot Satil.
	+ Added second technique for hiding effect in screenshots.
*/

#include "ReShade.fxh"

#ifndef cLayerCCTex
#define cLayerCCTex "cLayerCCA.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif
#ifndef cLayerCC_SIZE_X
#endif
#ifndef cLayerCC_SIZE_Y
#endif

#define TEXFORMAT RGBA8


uniform int cLayerCC_Mode <
    ui_type = "combo";
    ui_label = "Mode";
    ui_items =
               "Standard\0"
               "with Gray Chart\0"
               "Simple\0";
> = false;

uniform float cLayerCC_Scale <
  ui_type = "slider";
  ui_spacing = 1;
    ui_label = "Scale";
    ui_min = 0.5; ui_max = 1.0;
    ui_step = 0.001;
> = 0.770;


uniform float cLayerCC_PosX <
  ui_type = "slider";
    ui_label = "Position X";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
> = 0.100;

uniform float cLayerCC_PosY <
  ui_type = "slider";
    ui_label = "Position Y";
    ui_min = 0.0; ui_max = 1.0;
    ui_step = 0.001;
> = 0.500;

uniform float Color_Chart_Brightness <
  ui_type = "slider";
    ui_label = "Brightness";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.00;

uniform float Color_Chart_Saturation <
  ui_type = "slider";
    ui_label = "Saturation";
    ui_min = -1.0; ui_max = 1.0;
    ui_step = 0.001;
> = 0.00;


#define _SOURCE_Color_Chart_FILE "color_chart_afternov2014_d50_srgb.png"
#define _SOURCE_Color_Chart_SIZE 600.0, 400.0
#define _SOURCE_Color_Chart_BG_FILE "color_chart_afternov2014_d50_srgb_bg.png"
#define _SOURCE_Color_Chart_BG_SIZE 600.0, 400.0
#define _SOURCE_Gray_Chart_FILE "color_chart_gray_chart_2_line.png"
#define _SOURCE_Gray_Chart_SIZE 600.0, 400.0
#define _SOURCE_Color_Chart_BG_S_FILE "color_chart_afternov2014_d50_srgb_bg_s.png"
#define _SOURCE_Color_Chart_BG_S_SIZE 600.0, 400.0


texture Color_Chart_Texture <
    source = _SOURCE_Color_Chart_FILE;
> {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
 };

texture Color_Chart_BG_S_Texture <
    source = _SOURCE_Color_Chart_BG_S_FILE;
> {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
 };

texture Gray_Chart_Texture <
    source = _SOURCE_Gray_Chart_FILE;
> {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
};

texture Color_Chart_BG_Texture <
    source = _SOURCE_Color_Chart_BG_FILE;
> {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
 };


sampler Color_Chart_Sampler { 
    Texture = Color_Chart_Texture;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

sampler Color_Chart_BG_Sampler { 
    Texture = Color_Chart_BG_Texture;
    AddressU = CLAMP;
    AddressV = CLAMP;
};


sampler Gray_Chart_Sampler { 
    Texture = Gray_Chart_Texture;
    AddressU = CLAMP;
    AddressV = CLAMP;
};


sampler Color_Chart_BG_S_Sampler { 
    Texture = Color_Chart_BG_S_Texture;
    AddressU = CLAMP;
    AddressV = CLAMP;
};


// -------------------------------------
// Entrypoints
// -------------------------------------

    float getLum( in float3 x )
    {
        return dot( x, float3( 0.212656, 0.715158, 0.072186 ));
    }

    float3 bri(float3 Tex1, float x)
    {
        //screen
        const float3 c = 1.0f - ( 1.0f - Tex1.rgb ) * ( 1.0f - Tex1.rgb );
        if (x < 0.0f) {
            x = x * 0.5f;
        }
        return saturate( lerp( Tex1.rgb, c.rgb, x ));   
    }

    float3 sat( float3 Tex1, float x )
    {
        return saturate(lerp(getLum(Tex1.rgb), Tex1.rgb, x + 1.0 ));
    }



void PS_cLayerCC(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
    const float3 pivot = float3(0.5, 0.5, 0.0);
    const float3 mulUV = float3(texCoord.x, texCoord.y, 1);
    const float2 ScaleSize = (float2(_SOURCE_Color_Chart_SIZE) * cLayerCC_Scale / BUFFER_SCREEN_SIZE);
    const float ScaleX =  ScaleSize.x *  cLayerCC_Scale;
    const float ScaleY =  ScaleSize.y *  cLayerCC_Scale;


    const float3x3 positionMatrix = float3x3 (
        1, 0, 0,
        0, 1, 0,
        -cLayerCC_PosX, -cLayerCC_PosY, 1
    );


    const float3x3 scaleMatrix = float3x3 (
        1/ScaleX, 0, 0,
        0,  1/ScaleY, 0,
        0, 0, 1
    );


    const float3 SumUV = mul (mul (mulUV, positionMatrix), scaleMatrix);
    const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);
    float4 Tex1 = tex2D(Color_Chart_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));
    if (Color_Chart_Brightness != 0.0f) {
        Tex1.rgb = bri(Tex1.rgb, Color_Chart_Brightness);
    }
    if (Color_Chart_Saturation != 0.0f) {
        Tex1.rgb = sat(Tex1.rgb, Color_Chart_Saturation);
    }
    const float4 Tex2 = tex2D(Color_Chart_BG_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));
    switch(cLayerCC_Mode)
    {
        default:
            const float4 Tex3 = tex2D(Color_Chart_BG_S_Sampler, SumUV.rg + pivot.rg).r * all(SumUV + pivot == saturate(SumUV + pivot));
            passColor = lerp(backColor.rgb, Tex3.rgb, Tex3.a);
            passColor = lerp(passColor.rgb, Tex1.rgb, Tex1.a);
            break;
        case 1:
            passColor = lerp(backColor.rgb, Tex2.rgb, Tex2.a);
            passColor = lerp(passColor.rgb, Tex1.rgb, Tex1.a);
            const float4 Tex4 = tex2D(Gray_Chart_Sampler, SumUV.rg + pivot.rg) * all(SumUV + pivot == saturate(SumUV + pivot));
            passColor = lerp(passColor.rgb, Tex4.rgb, Tex4.a);
            break;
        case 2:
            passColor = lerp(backColor.rgb, Tex1.rgb, Tex1.a);
            break;
    }
    passColor = float4(lerp(backColor.rgb, passColor.rgb, Tex2.a).rgb, backColor.a);
}

// -------------------------------------
// Techniques
// -------------------------------------

technique Color_Chart < ui_label = "Color Chart (Hidden In Screenshots)";
                        ui_tooltip = "     Display a color chart like used for\n"
                                     "     color grading work in video/cinema production.\n"
                                     "     Can be useful to see effect that\n"
                                     "     presets and shaders affect on to colors.\n\n"
                                     "     This technique WILL NOT be shown in screenshots.";
                        enabled_in_screenshot = false; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_cLayerCC;
    }
}

technique Color_Chart_S < ui_label = "Color Chart (Visible In Screenshots)";
                          ui_tooltip = "     Display a color chart like used for\n"
                                       "     color grading work in video/cinema production.\n"
                                       "     Can be useful to see effect that\n"
                                       "     presets and shaders affect on to colors.\n\n"
                                       "     This technique WILL be shown in screenshots.";
                          enabled_in_screenshot = true; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_cLayerCC;
    }
}
