/*-----------------------------------------------------------------------------------------------------*/
/* Wave Shader - by Radegast Stravinsky of Ultros.                                                */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"
#include "Wave.fxh"

texture texColorBuffer : COLOR;

texture waveTarget
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    MipLevels = LINEAR;
    Format = RGBA8;
};

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

float4 Wave(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    const float2 center = float2(0.5 / ar, 0.5);
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float2 tc = texcoord;
    const float4 base = tex2D(samplerColor, texcoord);
    float4 color;

    tc.x /= ar;

    const float theta = radians(animate == 3 ? (anim_rate * 0.01 % 360.0) : angle);
    float2 sc;
    float2 _sc;
    sincos(theta, sc.y, sc.x);
    sincos(-theta, _sc.y, _sc.x);

    tc = float2(dot(tc - center, float2(sc.x, -sc.y )), dot(tc - center, float2(sc.y, sc.x)));
    if(wave_type == 0) {
        switch(animate) {
            default:
                tc.x += amplitude * sin((tc.x * period * 10) + phase);
                break;
            case 1:
                tc.x += (sin(anim_rate * 0.001) * amplitude) * sin((tc.x * period * 10) + phase);
                break;
            case 2:
                tc.x += amplitude * sin((tc.x * period * 10) + (anim_rate * 0.001));
                break;
        }
    } else {
        switch(animate) {
            default:
                tc.x +=  amplitude * sin((tc.y * period * 10) + phase);
                break;
            case 1:
                tc.x += (sin(anim_rate * 0.001) * amplitude) * sin((tc.y * period * 10) + phase);
                break;
            case 2:
                tc.x += amplitude * sin((tc.y * period * 10) + (anim_rate * 0.001));
                break;
        }
    }
    tc = float2(dot(tc, float2(_sc.x, -_sc.y)), dot(tc, float2(_sc.y, _sc.x))) + center;

    tc.x *= ar;

    float blending_factor;
    if(render_type)
        blending_factor = lerp(0, abs(amplitude)* lerp(10, 1, abs(amplitude)), blending_amount);
    else
        blending_factor = blending_amount;

    color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);


    float out_depth = ReShade::GetLinearizedDepth(tc).r;
    bool inDepthBounds = out_depth >= depth_bounds.x && out_depth <= depth_bounds.y;

    if(inDepthBounds){
        color = tex2D(samplerColor, tc);

        color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
    }
    else
    {
        color = tex2D(samplerColor, texcoord);
    }

    if(depth < min_depth)
        color = tex2D(samplerColor, texcoord);

    return color;
}

technique Wave <ui_label="Wave";>
{
    pass p0
    {
        VertexShader = PostProcessVS;
        PixelShader = Wave;
    }
}