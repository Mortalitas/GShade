/*-----------------------------------------------------------------------------------------------------*/
/* Bulge/Pinch Shader - by Radegast Stravinsky of Ultros.                                              */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"
#include "BulgePinch.fxh"

texture texColorBuffer : COLOR;

sampler samplerColor
{
    Texture = texColorBuffer;

    AddressU = MIRROR;
    AddressV = MIRROR;
    AddressW = MIRROR;

    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;

    MinLOD = 0.0f;
    MaxLOD = 1000.0f;

    MipLODBias = 0.0f;

    SRGBTexture = false;
};

// Vertex Shader
void FullScreenVS(uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;

    position = float4( texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
    //position /= BUFFER_HEIGHT/BUFFER_WIDTH;

}

// Pixel Shaders (in order of appearance in the technique)
float4 PBDistort(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    float2 tc = texcoord;
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);

    float2 center = float2(x_coord, y_coord);
    float2 offset_center = float2(offset_x, offset_y);
    if (use_mouse_point)
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH, mouse_coordinates.y * BUFFER_RCP_HEIGHT);

    center = mul(swirlTransform(radians(aspect_ratio_angle)), center);

    tc = mul(swirlTransform(radians(aspect_ratio_angle)), tc - center);
    tc += mul(swirlTransform(radians(aspect_ratio_angle)), center);

    float4 color;
    const float4 base = tex2D(samplerColor, texcoord);
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;

    center.x /= ar;
    offset_center.x /= ar;
    tc.x /= ar;

    float dist = distance(tc, center);

    float anim_mag = (animate == 1 ? magnitude * sin(radians(anim_rate * 0.05)) : magnitude);
    float tension_radius = lerp(dist, radius, tension);
    float percent = (dist)/tension_radius;
    if(anim_mag > 0)
        tc = (tc-center) * lerp(1.0, smoothstep(0.0, tension_radius/dist, percent), anim_mag * 0.75);
    else
        tc = (tc-center) * lerp(1.0, pow(abs(percent), 1.0 + anim_mag * 0.75) * tension_radius/dist, 1.0 - percent);

    if(use_offset_coords) {
        tc += offset_center;
    }
    else
        tc += center;
    tc.x *= ar;
    center.x *= ar;

    center = mul(swirlTransform(radians(-aspect_ratio_angle)), center);

    tc = mul(swirlTransform(radians(-aspect_ratio_angle)), tc - center);
    tc += mul(swirlTransform(radians(-aspect_ratio_angle)), center);

    float out_depth = ReShade::GetLinearizedDepth(tc).r;
    bool inDepthBounds = out_depth >= depth_bounds.x && out_depth <= depth_bounds.y;

    float blending_factor;
    if(render_type)
        blending_factor = lerp(0, 1 - percent, blending_amount);
    else
        blending_factor = blending_amount;

    if (tension_radius >= dist && inDepthBounds)
    {
        if(use_offset_coords){
            if(dist <= tension_radius)
                color = tex2D(samplerColor, tc);
            else
                color = tex2D(samplerColor, texcoord);
        } else
            color = tex2D(samplerColor, tc);

        color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
    }
    else {
        color = tex2D(samplerColor, texcoord);
    }

    if(depth < min_depth)
        color = tex2D(samplerColor, texcoord);

    return color;
}

// Technique
technique BulgePinch <ui_label="Bulge/Pinch";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = PBDistort;
    }
};