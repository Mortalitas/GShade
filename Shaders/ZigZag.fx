/*-----------------------------------------------------------------------------------------------------*/
/* ZigZag Shader v5.0 - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"

uniform float radius <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.0;

uniform float angle <
    ui_type = "slider";
    ui_min = -999.0; 
    ui_max = 999.0; 
    ui_step = 1.0;
> = 180.0;

uniform float period <
    ui_type = "slider";
    ui_min = 0.1; 
    ui_max = 10.0;
> = 0.5;

uniform float amplitude <
    ui_type = "slider";
    ui_min = -10.0; 
    ui_max = 10.0;
> = 0.0;

uniform float2 coordinates <
    ui_type = "slider";
    ui_label="Coordinates";
    ui_tooltip="The X and Y position of the center of the effect.";
    ui_min = 0.0; 
    ui_max = 1.0;
> = float2(0.25, 0.25);

uniform float aspect_ratio <
    ui_type = "slider";
    ui_label="Aspect Ratio"; 
    ui_min = -100.0; 
    ui_max = 100.0;
> = 0;

uniform float min_depth <
    ui_type = "slider";
    ui_label="Minimum Depth";
    ui_min=0.0;
    ui_max=1.0;
> = 0;

uniform float tension <
    ui_type = "slider";
    ui_label = "Tension";
    ui_min = 0; 
    ui_max = 10;
    ui_step = 0.001;
> = 1.0;

uniform float phase <
    ui_type = "slider";
    ui_min = -5.0; 
    ui_max = 5.0;
> = 0.0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Amplitude\0Phase\0";
    ui_tooltip = "Enable or disable the animation. Animates the zigzag effect by phase or by amplitude.";
> = 0;

uniform float anim_rate <
    source = "timer";
>;

uniform int render_type <
    ui_type = "combo";
    ui_label = "Render Type";
    ui_items = "Normal\0Add\0Multiply\0Subtract\0Divide\0";
    ui_tooltip = "Applies different rendering modes to the output.";
> = 0;

texture texColorBuffer : COLOR;
texture texDepthBuffer : DEPTH;

texture zzTarget
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA8;
};


sampler samplerColor
{
    Texture = texColorBuffer;

    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;

};

sampler samplerDepth
{
    Texture = texDepthBuffer;
};

sampler result
{
    Texture = zzTarget;
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
void DoNothingPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_TARGET)
{
    color = tex2D(samplerColor, texcoord);
}

float4 ZigZag(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float4 color;
    const float4 base = tex2D(samplerColor, texcoord);
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);
    float2 center = coordinates;
    float2 tc = texcoord - center;

    center.x /= ar;
    tc.x /= ar;


    const float dist = distance(tc, center);
    if (dist < radius && depth >= min_depth)
    {
        const float tension_radius = lerp(radius-dist, radius, tension);
        const float percent = (radius-dist) / tension_radius;
        
        const float theta = percent * percent * (animate == 1 ? amplitude * sin(anim_rate * 0.0005) : amplitude) * sin(percent * percent / period * radians(angle) + (phase + (animate == 2 ? 0.00075 * anim_rate : 0)));

        const float s =  sin(theta);
        const float c = cos(theta);
        tc = float2(dot(tc - center, float2(c, -s)), dot(tc - center, float2(s, c)));

        tc += (2.0 * center);
        tc.x *= ar;

        color = tex2D(samplerColor, tc);
    }
    else
    {
        color = tex2D(samplerColor, texcoord);
    }
    
    if(depth >= min_depth)
        switch(render_type)
        {
            case 1:
                color += base;
                break;
            case 2:
                color *= base;
                break;
            case 3:
                color -= base;
                break;
            case 4:
                color /= base;
                break;
        }  
    
    return color;
}

// Technique
technique ZigZag
{
    pass p0
    { 
        VertexShader = FullScreenVS;
        PixelShader = DoNothingPS;

        RenderTarget = zzTarget;
    }

    pass p1
    {
        VertexShader = FullScreenVS;
        PixelShader = ZigZag;
    }
};