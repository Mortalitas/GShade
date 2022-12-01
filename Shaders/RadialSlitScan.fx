#include "Reshade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

/*-----------------------------------------------------------------------------------------------------*/
/* Radial Slit Scan Shader - by Radegast Stravinsky of Ultros.                                         */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
uniform float2 coordinates <
    ui_type = "slider";
    ui_label="Coordinates";
    ui_tooltip="The X and Y position of the center of the effect.";
    ui_min = 0.0; 
    ui_max = 1.0;
> = float2(0.5, 0.5);

uniform float frame_rate <
    source = "framecount";
>;

uniform float2 anim_rate <
    source = "pingpong";
    min = 0.0;
    max = 1.0;
    step = 0.001;
    smoothing = 0.0;
>;

uniform float min_depth <
    ui_type     = "slider";
    ui_label    = "Minimum Depth";
    ui_tooltip  = "Unmasks anything before a set depth.";
    ui_category = "Depth";
    ui_min=0.0;
    ui_max=1.0;
> = 0;

uniform float3 border_color <
    ui_type = "color";
    ui_label = "Border Color";
    ui_category = "Color Settings";
> = float3(1.0, 0.0, 0.0);

uniform float opacity <
    ui_type = "slider";
    ui_label = "Opacity";
    ui_category = "Color Settings";
> = 1.0;

uniform float blending_amount <
    ui_type = "slider";
    ui_label = "Opacity";
    ui_category = "Blending";
    ui_tooltip = "Adjusts the blending amount.";
    ui_min = 0.0;
    ui_max = 1.0;
> = 1.0;

BLENDING_COMBO(
    render_type, 
    "Blending Mode", 
    "Blends the effect with the previous layers.",
    "Blending",
    false,
    0,
    0
);

texture texColorBuffer: COLOR;

texture ssTexture {
    Height = BUFFER_HEIGHT;
    Width = BUFFER_WIDTH;
};

sampler samplerColor {
    Texture = texColorBuffer;
            
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;
    
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16;
    
};

sampler ssTarget {
    Texture = ssTexture;
        
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;

    Height = BUFFER_HEIGHT;
    Width = BUFFER_WIDTH;
    Format = RGBA16;
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
    float2 center = coordinates/2.0;
    float2 tc = texcoord - center;;
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    tc.x /= ar_raw;
    center.x /= ar_raw;
    
    float4 base = tex2D(samplerColor, texcoord);
    color = base;
    float max_radius = get_longest_distance(coordinates);
    
    float dist = distance(tc, center);

    float slice_to_fill = (anim_rate.x * max_radius);
     

    float4 cols = tex2Dfetch(ssTarget, texcoord);
    float4 col_to_write = tex2Dfetch(ssTarget, texcoord);

   
    if (dist >= slice_to_fill)
        color = float4(ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_amount), 1.0);
    else
        discard;
};

void SlitScanPost(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float3 color : SV_TARGET)
{
    color = tex2D(samplerColor, texcoord).rgb;
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;

    if (depth > min_depth){
        float2 center = coordinates/2.0;
        float2 tc = texcoord - center;

        const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;

        center.x /= ar_raw;
        tc.x /= ar_raw;
        const float max_radius = get_longest_distance(coordinates);
        const float dist = distance(tc, center);

        const float slice_to_fill = anim_rate.x * max_radius;
        tc.x *= ar_raw;

        if (dist < slice_to_fill){
            const float3 scanned_color = tex2D(ssTarget, texcoord).rgb;
            color = ComHeaders::Blending::Blend(render_type, color, scanned_color, blending_amount);
        }
        else if (dist > slice_to_fill && dist <= slice_to_fill + 0.0025){
            color = lerp(color, border_color, opacity);
        }
    }

#if GSHADE_DITHER
    color.rgb += TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif

#if GSHADE_DITHER
	color.rgb += TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH);
#endif

}


technique SlitScan <
ui_label="Radial Slit Scan";
ui_tooltip="Scans and freezes pixels in an outward expanding circle. Resets after a few seconds.\nThe border color can be changed or hidden.";
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