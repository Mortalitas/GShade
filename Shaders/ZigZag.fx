/*-----------------------------------------------------------------------------------------------------*/
/* ZigZag Shader v3.0 - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/

uniform float radius <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
> = 0.0;

uniform float angle <
    ui_type = "slider";
    ui_min = -999.0; ui_max = 999.0; ui_step = 1.0;
> = 180.0;

uniform float period <
    ui_type = "slider";
    ui_min = 0.1; ui_max = 10.0;
> = 0.5;

uniform float amplitude <
    ui_type = "slider";
    ui_min = -10.0; ui_max = 10.0;
> = 0.0;

uniform float center_x <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
> = 0.5;

uniform float center_y <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
> = 0.5;

uniform float tension <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 10.0; ui_step = 0.001;
> = 1.0;

uniform float phase <
    ui_type = "slider";
    ui_min = -5.0; ui_max = 5.0;
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

uniform int additiveRender <
    ui_type = "combo";
    ui_label = "Additively Render";
    ui_items = "No\0Base -> Result\0Result -> Base\0";
    ui_tooltip = "Additively render the effect.";
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
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    
    position = float4( texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
}

// Pixel Shaders (in order of appearance in the technique)
void DoNothingPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_TARGET)
{
    color = tex2D(samplerColor, texcoord);
}

float4 ZigZag(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    float ar = 1. * BUFFER_HEIGHT/BUFFER_WIDTH;
    float2 center = float2(center_x, center_y);
    float2 tc = texcoord - center;

    center.x /= ar;
    tc.x /= ar;


    float dist = distance(tc, center);
    if (dist < radius)
    {
        float tension_radius = lerp(radius-dist, radius, tension);
        float percent = (radius-dist)/tension_radius;
        
        float theta = percent * percent * (animate == 1 ? amplitude * sin(anim_rate * 0.0005) : amplitude) * sin(percent * percent / period * radians(angle) + (phase + (animate == 2 ? 0.00075 * anim_rate : 0)));

        float s =  sin(theta);
        float c = cos(theta);
        tc = float2(dot(tc-center, float2(c,-s)), dot(tc-center, float2(s,c)));

        tc += (2.0*center);
        tc.x *= ar;

        return tex2D(samplerColor, tc);
    }

    return tex2D(samplerColor, texcoord);
   
}

float4 ResultPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    float4 color = tex2D(result, texcoord);
    float4 base = tex2D(samplerColor, texcoord);
    
    if(!additiveRender)
        return color;

    return additiveRender == 1 ? lerp(base, color, color.a) : lerp(color, base, color.a);
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

        RenderTarget = zzTarget;
    }

    pass p2 
    {
        VertexShader = FullScreenVS;
        PixelShader = ResultPS;
    }
};