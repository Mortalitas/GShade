/*-----------------------------------------------------------------------------------------------------*/
/* ZigZag Shader - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"
#include "ZigZag.fxh"

texture texColorBuffer : COLOR;

texture zzTarget
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
};


sampler samplerColor
{
    Texture = texColorBuffer;

    AddressU = MIRROR;
    AddressV = MIRROR;
    AddressW = MIRROR;

};

// Pixel Shaders (in order of appearance in the technique)
float4 ZigZag(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float4 color;
    const float4 base = tex2D(samplerColor, texcoord);
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);

    float2 center = float2(x_coord, y_coord) / 2.0;
    if (use_mouse_point)
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH / 2.0, mouse_coordinates.y * BUFFER_RCP_HEIGHT / 2.0);

    float2 offset_center = float2(offset_x, offset_y) / 2.0;

    float2 tc = texcoord - center;

    center.x /= ar;
    offset_center.x /= ar;
    tc.x /= ar;

    const float dist = distance(tc, center);
    const float tension_radius = lerp(radius-dist, radius, tension);
    const float percent = max(radius-dist, 0) / tension_radius;
    const float percentSquared = percent * percent;
    const float theta = percentSquared * (animate == 1 ? amplitude * sin(anim_rate * 0.0005) : amplitude) * sin(percentSquared / period * radians(angle) + (phase + (animate == 2 ? 0.00075 * anim_rate : 0)));

    if(!mode) {
        tc = mul(swirlTransform(theta), tc-center);
    } else {
        tc = mul(zigzagTransform(theta), tc-center);
    }

    if(use_offset_coords)
        tc += (2 * offset_center);
    else
        tc += (2 * center);

    tc.x *= ar;

    float out_depth = ReShade::GetLinearizedDepth(tc).r;
    bool inDepthBounds = out_depth >= depth_bounds.x && out_depth <= depth_bounds.y;

    float blending_factor;
    if(render_type)
        blending_factor = lerp(0, percentSquared, blending_amount);
    else
        blending_factor = blending_amount;
    if (inDepthBounds)
    {
        if(use_offset_coords){
            float2 offset_coords_adjust = float2(offset_x, offset_y);
            offset_coords_adjust.x *= ar;
            if(dist <= tension_radius)
            {
                color = tex2D(samplerColor, tc);
                color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
            }
            else
                color = tex2D(samplerColor, texcoord);
        } else
        {
            color = tex2D(samplerColor, tc);
            color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
        }


    }
    else
    {
        color = base;
    }

    if(depth < min_depth)
        color = tex2D(samplerColor, texcoord);

    return color;
}

// Technique
technique ZigZag <ui_label="Zigzag";>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = ZigZag;
    }

};