/*-----------------------------------------------------------------------------------------------------*/
/* Swirl Shader - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "SplicedRadials.fxh"
#include "ReShade.fxh"

texture texColorBuffer : COLOR;

sampler samplerColor
{
    Texture = texColorBuffer;

    AddressU = MIRROR;
    AddressV = MIRROR;
    AddressW = MIRROR;


};

// Vertex Shader
void FullScreenVS(uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    if (id == 2)
        texcoord.x = 2.0;
    else
        texcoord.x = 0.0;

    if (id == 1)
        texcoord.y  = 2.0;
    else
        texcoord.y = 0.0;

    position = float4( texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
}

// Pixel Shaders (in order of appearance in the technique)
float4 SplicedRadialsPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    float4 color;
    float2 tc = texcoord;

    float4 base = tex2D(samplerColor, texcoord);
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);

    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float2 center = float2(x_coord, y_coord);
    float2 offset_center = float2(offset_x, offset_y);

    if (use_mouse_point)
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH, mouse_coordinates.y * BUFFER_RCP_HEIGHT);

    if(aspect_ratio_angle) {
        center = mul(swirlTransform(radians(aspect_ratio_angle)), center);

        tc = mul(swirlTransform(radians(aspect_ratio_angle)), tc - center);
        tc += mul(swirlTransform(radians(aspect_ratio_angle)), center);
    }

    center.x /= ar;
    offset_center.x /= ar;

    tc.x /= ar;

    const float dist = distance(tc, center);
    const float dist_radius = radius-dist;
    const float tension_radius = lerp(radius-dist, radius, tension);
    const float tension_dist = lerp(dist_radius, tension_radius, tension);
    float percent;
    float theta;

    float splice_width = (tension_radius-inner_radius) / number_splices;
    splice_width = frac(splice_width);
    float cur_splice = max(dist_radius,0)/splice_width;
    cur_splice = cur_splice - frac(cur_splice);
    float splice_angle = (angle / number_splices) * cur_splice;
    if(dist_radius > tension_radius-inner_radius)
        splice_angle = angle;
    theta = radians(splice_angle * (animate == 1 ? sin(anim_rate * 0.0005) : 1.0));


    tc = mul(swirlTransform(theta), tc-center);
    if(use_offset_coords) {
        tc += offset_center;
    }
    else
        tc += center;
    tc.x *= ar;

    if(aspect_ratio_angle) {
        center.x *= ar;
        center = mul(swirlTransform(radians(-aspect_ratio_angle)), center);

        tc = mul(swirlTransform(radians(-aspect_ratio_angle)), tc - center);
        tc += mul(swirlTransform(radians(-aspect_ratio_angle)), center);
    }

    float out_depth = ReShade::GetLinearizedDepth(tc).r;
    bool inDepthBounds = out_depth >= depth_bounds.x && out_depth <= depth_bounds.y;

    if (inDepthBounds)
    {
        if(use_offset_coords)
        {
            if(theta)
                color = tex2D(samplerColor, tc);
            else
                color = tex2D(samplerColor, texcoord);
        } else
            color = tex2D(samplerColor, tc);

        if(dist <= radius)
            color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_amount);
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
technique SplicedRadials <ui_label="Spliced Radials";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = SplicedRadialsPS;
    }
};