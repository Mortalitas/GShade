/*-----------------------------------------------------------------------------------------------------*/
/* Wave Shader v4.0 - by Radegast Stravinsky of Ultros.                                                */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"

uniform int wave_type <
    ui_type = "combo";
    ui_label = "Wave Type";
    ui_items = "X/X\0X/Y\0";
    ui_tooltip = "Which axis the distortion should be performed against.";
> = 1;

uniform float angle <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_min = -360.0; ui_max = 360.0; ui_step = 1.0;
> = 180.0;

uniform float period <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_min = 0.1; ui_max = 10.0;
    ui_tooltip = "The wavelength of the distortion. Smaller values make for a longer wavelength.";
> = 0.5;

uniform float amplitude <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_min = -1.0; ui_max = 1.0;
    ui_tooltip = "The amplitude of the distortion in each direction.";
> = 0.0;

uniform float phase <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_min = -5.0; ui_max = 5.0;
    ui_tooltip = "The offset being applied to the distortion's waves. Smaller is longer.";
> = 0.0;

uniform float min_depth <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else 
        ui_type = "slider";
    #endif
    ui_label="Minimum Depth";
    ui_min=0.0;
    ui_max=1.0;
> = 0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Amplitude\0Phase\0Angle\0";
    ui_tooltip = "Enable or disable the animation. Animates the wave effect by phase, amplitude, or angle.";
> = 0;

uniform float anim_rate <
    source = "timer";
>;

uniform int render_type <
    ui_type = "combo";
    ui_label = "Render Type";
    ui_items = "Normal\0Add\0Multiply\0Subtract\0Divide\0Darker\0Lighter\0";
    ui_tooltip = "Applies different rendering modes to the output.";
> = 0;

texture texColorBuffer : COLOR;

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
    const float s =  sin(theta);
    const float _s = sin(-theta);
    const float c =  cos(theta);
    const float _c = cos(-theta);

    tc = float2(dot(tc - center, float2(c, -s)), dot(tc - center, float2(s, c)));
    if(depth >= min_depth){
        if(wave_type == 0)
        {
            switch(animate)
            {
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
        }
        else
        {
            switch(animate)
            {
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
        tc = float2(dot(tc, float2(_c, -_s)), dot(tc, float2(_s, _c))) + center;

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
                if(length(color.rgb) < length( base.rgb))
                    color = base;
                break;
        }

    return color;
}

technique Wave
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = Wave;
    }
}