/*-----------------------------------------------------------------------------------------------------*/
/* Swirl Shader v5.0 - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"

uniform float radius <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float angle <
    ui_type = "slider";
    ui_min = -1800.0; 
    ui_max = 1800.0; 
    ui_step = 1.0;
> = 180.0;

uniform float tension <
    ui_type = "slider";
    ui_min = 0; 
    ui_max = 10; 
    ui_step = 0.001;
    ui_tooltip="Determines how rapidly the swirl reaches the maximum angle.";
> = 1.0;

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
    ui_tooltip = "Changes the distortion's aspect ratio in regards to the display aspect ratio.";
> = 0;

uniform float min_depth <
    ui_type = "slider";
    ui_label="Minimum Depth";
    ui_min=0.0;
    ui_max=1.0;
    ui_tooltip="The minimum depth to distort.\nAnything closer than the threshold will appear normally. (0 = Near, 1 = Far)";
> = 0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Animates the swirl, moving it clockwise and counterclockwise.";
> = 0;

uniform float anim_rate <
    source = "timer";
>;

uniform int inverse <
    ui_type = "combo";
    ui_label = "Inverse Angle";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Inverts the angle of the swirl, making the edges the most distorted.";
> = 0;

uniform int render_type <
    ui_type = "combo";
    ui_label = "Render Type";
    ui_items = "Normal\0Add\0Multiply\0Subtract\0Divide\0Darker\0Lighter\0";
    ui_tooltip = "Additively render the effect.";
> = 0;

texture texColorBuffer : COLOR;

texture swirlTarget
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;

    
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;

    Format = RGBA16;
};

sampler samplerColor
{
    Texture = texColorBuffer;
    
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;

    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16;
    
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

float4 Swirl(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);
    const float4 base = tex2D(samplerColor, texcoord);
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float2 center = coordinates;
    float2 tc = texcoord - center;
    float4 color;

    center.x /= ar;
    tc.x /= ar;

    const float dist = distance(tc, center);
    if (dist < radius && depth >= min_depth)
    {
        const float tension_radius = lerp(radius-dist, radius, tension);
        float percent = (radius-dist) / tension_radius;
        if (inverse != 0)
            percent = 1 - percent;
        const float theta = percent * percent * radians(angle * (animate == 1 ? sin(anim_rate * 0.0005) : 1.0));
        const float s =  sin(theta);
        const float c =  cos(theta);
        tc = float2(dot(tc - center, float2(c, -s)), dot(tc - center, float2(s,c)));

        tc += (2 * center);
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
technique Swirl< ui_label="Swirl";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = DoNothingPS;

        RenderTarget = swirlTarget;
    }

    pass p1
    {
        VertexShader = FullScreenVS;
        PixelShader = Swirl;
    }
};