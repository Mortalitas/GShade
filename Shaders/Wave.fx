/*-----------------------------------------------------------------------------------------------------*/
/* Wave Shader v3.0 - by Radegast Stravinsky of Ultros.                                                */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/

uniform int wave_type <
    ui_type = "combo";
    ui_label = "Wave Type";
    ui_items = "X/X\0X/Y\0";
    ui_tooltip = "Which axis the distortion should be performed against.";
> = 1;

uniform float angle <
    ui_type = "slider";
    ui_min = -360.0; ui_max = 360.0; ui_step = 1.0;
> = 180.0;

uniform float period <
    ui_type = "slider";
    ui_min = 0.1; ui_max = 10.0;
    ui_tooltip = "The wavelength of the distortion. Smaller values make for a longer wavelength.";
> = 0.5;

uniform float amplitude <
    ui_type = "slider";
    ui_min = -1.0; ui_max = 1.0;
    ui_tooltip = "The amplitude of the distortion in each direction.";
> = 0.0;

uniform float phase <
    ui_type = "slider";
    ui_min = -5.0; ui_max = 5.0;
    ui_tooltip = "The offset being applied to the distortion's waves. Smaller is longer.";
> = 0.0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Amplitude\0Phase\0Angle\0";
    ui_tooltip = "Enable or disable the animation. Animates the wave effect by phase, amplitude, or angle.";
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
    Texture = waveTarget;
};


// Vertex Shader
void FullScreenVS(uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    
    position = float4( texcoord * float2(2, -2) + float2(-1, 1), 0, 1);

}

void DoNothingPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD0, out float4 color : SV_TARGET)
{
    color = tex2D(samplerColor, texcoord);
}

float4 Wave(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET 
{
    
    float ar = 1. * BUFFER_HEIGHT/BUFFER_WIDTH;
    float2 center = float2(0.5f, 0.5f);

    center.x /= ar;
    texcoord.x /= ar;

    float theta = radians(animate == 3 ? (anim_rate * 0.01 % 360.0) : angle);
    float s =  sin(theta);
    float _s = sin(-theta);
    float c =  cos(theta);
    float _c = cos(-theta);

    texcoord = float2(dot(texcoord-center, float2(c,-s)), dot(texcoord-center, float2(s,c)));
    if(wave_type == 0)
        texcoord.x += (animate == 1 ? sin(anim_rate * 0.001) * amplitude : amplitude) * sin(( texcoord.x * period * 10)  + (animate == 2 ?  anim_rate * 0.001 : phase));
    else
        texcoord.x += (animate == 1 ? sin(anim_rate * 0.001) * amplitude : amplitude) * sin(( texcoord.y * period * 10)  + (animate == 2 ?  anim_rate * 0.001 : phase));
    texcoord = float2(dot(texcoord, float2(_c,-_s)), dot(texcoord, float2(_s,_c)));
    
    texcoord += center;
    texcoord.x *= ar;

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


technique Wave
{
    pass p0
    {
       
        VertexShader = FullScreenVS;
        PixelShader = DoNothingPS;

        RenderTarget = waveTarget;
    }

    pass p1
    {
        VertexShader = FullScreenVS;
        PixelShader = Wave;

        RenderTarget = waveTarget;
    }

    pass p2 
    {
        VertexShader = FullScreenVS;
        PixelShader = ResultPS;
    }
}