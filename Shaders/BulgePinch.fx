/*-----------------------------------------------------------------------------------------------------*/
/* PBDistort Shader v5.0 - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"

uniform float radius <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float magnitude <
    ui_type = "slider";
    ui_min = -1.0; 
    ui_max = 1.0;
> = -0.5;

uniform float tension <
    ui_type = "slider";
    ui_min = 0.; 
    ui_max = 10.; 
    ui_step = 0.001;
> = 1.0;

uniform float2 coordinates <
    ui_type = "slider";
    ui_label="Coordinates";
    ui_tooltip="The X and Y position of the center of the effect.";
    ui_min = 0.0; ui_max = 1.0;
> = 0.25;

uniform float min_depth <
    ui_type = "slider";
    ui_label="Minimum Depth";
    ui_min=0.0;
    ui_max=1.0;
> = 0;

uniform float aspect_ratio <
    ui_type = "slider";
    ui_label="Aspect Ratio"; 
    ui_min = -100.0; 
    ui_max = 100.0;
> = 0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Animates the effect.";
> = 0;

uniform float anim_rate <
    source = "timer";
>;

uniform int render_type <
    ui_type = "combo";
    ui_label = "Blending Mode";
    ui_items = "Normal\0Add\0Multiply\0Subtract\0Divide\0Darker\0Lighter\0";
    ui_tooltip = "Choose a blending mode.";
> = 0;


texture texColorBuffer : COLOR;

texture pbDistortTarget
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

    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;

    MinLOD = 0.0f;
    MaxLOD = 1000.0f;

    MipLODBias = 0.0f;

    SRGBTexture = false;
};

sampler result 
{
    Texture = pbDistortTarget;
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
void DoNothingPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_TARGET)
{
    color = tex2D(samplerColor, texcoord);
}

float4 PBDistort(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);

    float2 center = coordinates;
    float2 tc = texcoord - center;

    float4 color;
    const float4 base = tex2D(samplerColor, texcoord);
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;

    center.x /= ar;
    tc.x /= ar;

    float dist = distance(tc, center);
    if (dist < radius && depth >= min_depth)
    {
        float anim_mag = (animate == 1 ? magnitude * sin(radians(anim_rate * 0.05)) : magnitude);
        float tension_radius = lerp(dist, radius, tension);
        float percent = (dist)/tension_radius;
        if(anim_mag > 0)
            tc = (tc-center) * lerp(1.0, smoothstep(0.0, radius/dist, percent), anim_mag * 0.75);
        else
            tc = (tc-center) * lerp(1.0, pow(percent, 1.0 + anim_mag * 0.75) * radius/dist, 1.0 - percent);

        tc += (2*center);
        tc.x *= ar;

        color = tex2D(samplerColor, tc);
    }
    else {
        color = tex2D(samplerColor, texcoord);
    }

    if(depth >= min_depth)
        switch(render_type)
        {
            case 1: // Add
                color += base;
                break;
            case 2: // Multiply
                color *= base;
                break;
            case 3: // Subtract
                color -= base;
                break;
            case 4: // Divide
                color /= base;
                break;
            case 5: // Darker
                if(length(color.rgb) > length(base.rgb))
                    color = base;
                break;
            case 6: // Lighter
                if(length(color.rgb) < length(base.rgb))
                    color = base;
                break;
        }  

    return color;
}

// Technique
technique BulgePinch < ui_label="Bulge/Pinch";>
{
    pass p0
    {
       
        VertexShader = FullScreenVS;
        PixelShader = DoNothingPS;

        RenderTarget = pbDistortTarget;
    }

    pass p1
    {
        VertexShader = FullScreenVS;
        PixelShader = PBDistort;
    }
};