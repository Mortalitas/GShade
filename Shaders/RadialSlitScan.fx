/*-----------------------------------------------------------------------------------------------------*/
/* Radial Slit Scan Shader - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"
#include "RadialSlitScan.fxh"

texture texColorBuffer: COLOR;

texture ssTexture {
    Height = BUFFER_HEIGHT;
    Width = BUFFER_WIDTH;
    Format = RGBA16;
};

sampler samplerColor {
    Texture = texColorBuffer;
            
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;
};

sampler ssTarget {
    Texture = ssTexture;
        
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;
};

float get_longest_distance(float2 texcoord) {
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    const float2 TOP_LEFT = float2(0, 0);
    const float2 TOP_RIGHT = float2(1, 0);
    const float2 BOTTOM_LEFT = float2(0, 1);
    const float2 BOTTOM_RIGHT = float2(1, 1);

    const float dist_TL = distance(texcoord, TOP_LEFT);
    const float dist_TR = distance(texcoord, TOP_RIGHT);
    const float dist_BL = distance(texcoord, BOTTOM_LEFT);
    const float dist_BR = distance(texcoord, BOTTOM_RIGHT);

    return  max(max(dist_TL, dist_TR), max(dist_BL, dist_BR)) / ar_raw;

}

// Pixel Shaders
void SlitScan(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_TARGET)
{
    float2 center = float2(x_coord, y_coord)/2.0;
    float2 tc = texcoord - center;
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    tc.x /= ar_raw;
    center.x /= ar_raw;
    
    float4 base = tex2D(samplerColor, texcoord);
    color = base;
    float max_radius = get_longest_distance(center);
    
    float dist = distance(tc, center);

    float slice_to_fill = (anim_rate.x * max_radius);
     

    float4 cols = tex2Dfetch(ssTarget, texcoord);
    float4 col_to_write = tex2Dfetch(ssTarget, texcoord);


    if (dist > slice_to_fill)
        color = base;

    else
        discard;
};

void SlitScanPost(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_TARGET)
{
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float4 base = tex2D(samplerColor, texcoord);
    color = base;
    float2 uv = texcoord;
    float2 center = float2(x_coord, y_coord)/2.0;
    float2 tc = texcoord - center;

    float4 screen = tex2D(samplerColor, texcoord);
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;

    center.x /= ar_raw;
    tc.x /= ar_raw;
    float max_radius = get_longest_distance(center);
    float dist = distance(tc, center);

    float slice_to_fill = (anim_rate.x * max_radius);
    float4 scanned;
    tc.x *= ar_raw;

    if(dist < slice_to_fill){
        float4 scanned_color = tex2D(ssTarget, texcoord);
        color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, scanned_color.rgb, blending_amount);
    }
    else if (dist > slice_to_fill && dist <= slice_to_fill + 0.0025){
        color = tex2D(samplerColor, texcoord);
        color.rgba = lerp( screen.rgba, float4(border_color, 1.0), opacity);
    }
    else
        color = tex2D(samplerColor, texcoord);

    if(depth < min_depth)
        color = tex2D(samplerColor, texcoord);
}

technique RadialSlitScan <
    ui_label="Radial Slit Scan";
> {
    pass p0 {

        VertexShader = PostProcessVS;
        PixelShader = SlitScan;
        
        RenderTarget = ssTexture;
    }

    pass p1 {
        VertexShader = PostProcessVS;
        PixelShader = SlitScanPost;
    }

   
}