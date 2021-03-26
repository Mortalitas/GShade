/*-----------------------------------------------------------------------------------------------------*/
/* PBDistort Shader v4.0 - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/

uniform float radius <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
> = 0.5;

uniform float magnitude <
    ui_type = "slider";
    ui_min = -1.0; ui_max = 1.0;
> = -0.5;

uniform float tension <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 10.0; ui_step = 0.001;
> = 1.0;

uniform float center_x <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
> = 0.25;

uniform float center_y <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
> = 0.25;


uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Animates the effect.";
> = 0;

uniform float anim_rate <
    source = "timer";
>;

uniform int additiveRender <
    ui_type = "combo";
    ui_label = "Additively Render";
    ui_items = "No\0Base -> Result\0Result -> Base\0";
    ui_tooltip = "Additively render the effect.";
> = 0;

texture texColorBuffer : COLOR;
texture texDepthBuffer : DEPTH;

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

sampler samplerDepth
{
    Texture = texDepthBuffer;
};

sampler result 
{
    Texture = pbDistortTarget;
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
    //position /= BUFFER_HEIGHT/BUFFER_WIDTH;

}

// Pixel Shaders (in order of appearance in the technique)
void DoNothingPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_TARGET)
{
    color = tex2D(samplerColor, texcoord);
}

float4 PBDistort(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float2 center = float2(center_x, center_y);
    float2 tc = texcoord - center;

    center.x /= ar;
    tc.x /= ar;

    const float dist = distance(tc, center);
    if (dist < radius)
    {
        const float anim_mag = (animate == 1 ? magnitude * sin(radians(anim_rate * 0.05)) : magnitude);
        const float tension_radius = lerp(dist, radius, tension);
        const float percent = (dist) / tension_radius;
        if(anim_mag > 0)
            tc = (tc - center) * lerp(1.0, smoothstep(0.0, radius / dist, percent), anim_mag * 0.75);
        else
            tc = (tc - center) * lerp(1.0, pow(max(percent, 0.0), 1.0 + anim_mag * 0.75) * radius / dist, 1.0 - percent);

        tc += (2 * center);
        tc.x *= ar;

        return tex2D(samplerColor, tc);
    }

        
     return tex2D(samplerColor, texcoord);
        
}

float4 ResultPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float4 color = tex2D(result, texcoord);
    
    switch(additiveRender)
    {
        case 0:
            return color;
        case 1:
            return lerp(tex2D(samplerColor, texcoord), color, color.a);
        default:
            return lerp(color, tex2D(samplerColor, texcoord), color.a);
    }
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
    
        RenderTarget = pbDistortTarget;
    }

    pass p2
    {
        VertexShader = FullScreenVS;
        PixelShader = ResultPS;
    }
};