/*-----------------------------------------------------------------------------------------------------*/
/* Wave Shader v4.0 - by Radegast Stravinsky of Ultros.                                                */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform int wave_type <
    ui_type = "combo";
    ui_label = "Wave Type";
    ui_tooltip = "Selects the type of distortion to apply.";
    ui_items = "X/X\0X/Y\0";
    ui_tooltip = "Which axis the distortion should be performed against.";
> = 1;

uniform float angle <
    ui_type = "slider";
    ui_label = "Angle";
    ui_tooltip = "The angle at which the distortion occurs.";
    ui_min = -360.0; 
    ui_max = 360.0; 
    ui_step = 1.0;
> = 0.0;

uniform float period <
    ui_type = "slider";
    ui_label = "Frequency";
    ui_min = 0.1; 
    ui_max = 10.0;
    ui_tooltip = "The wavelength of the distortion. Smaller values make for a longer wavelength.";
> = 3.0;

uniform float amplitude <
    ui_type = "slider";
    ui_label = "Amplitude";
    ui_min = -1.0; 
    ui_max = 1.0;
    ui_tooltip = "The amplitude of the distortion in each direction.";
> = 0.075;

uniform float phase <
    ui_type = "slider";
    ui_label = "Phase";
    ui_min = -5.0; 
    ui_max = 5.0;
    ui_tooltip = "The offset being applied to the distortion's waves.";
> = 0.0;

uniform float min_depth <
    ui_type = "slider";
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
    ui_label = "Blending Mode";
    ui_items = "Normal\0Darken\0Multiply\0Color Burn\0Linear Burn\0Lighten\0Screen\0Color Dodge\0Linear Dodge\0Addition\0Reflect\0Glow\0Overlay\0Soft Light\0Hard Light\0Vivid Light\0Linear Light\0Pin Light\0Hard Mix\0Difference\0Exclusion\0Subtract\0Divide\0Grain Merge\0Grain Extract\0Hue\0Saturation\0ColorB\0Luminosity\0";
    ui_tooltip = "Additively render the effect.";
> = 0;

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

float3 BlendWithBase (const float3 base,const float3 color, const float percent)
{
    switch(render_type) {
        // Darken
        case 1:
            return lerp(base, Darken(base, color), percent);
        // Multiply
        case 2:
            return lerp(base, Multiply(base, color), percent);
        // Color Burn
        case 3:
            return lerp(base, ColorBurn(base, color), percent);
        // Linear Burn
        case 4:
            return lerp(base, LinearBurn(base, color), percent);
        // Lighten
        case 5:
            return lerp(base, Lighten(base, color), percent);
        // Screen
        case 6:
            return lerp(base, Screen(base, color), percent);
        // Color Dodge
        case 7:
            return lerp(base, ColorDodge(base, color), percent);
        // Linear Dodge
        case 8:
            return lerp(base, LinearDodge(base, color), percent);
        // Addition
        case 9:
            return lerp(base, Addition(base, color), percent);
        // Reflect
        case 10:
            return lerp(base, Reflect(base, color), percent);
        // Glow
        case 11:
            return lerp(base, Glow(base, color), percent);
        // Overlay
        case 12:
            return lerp(base, Overlay(base, color), percent);
        // Soft Light
        case 13:
            return lerp(base, SoftLight(base, color), percent);
        // Hard Light
        case 14:
            return lerp(base, HardLight(base, color), percent);
        // Vivid Light
        case 15:
            return lerp(base, VividLight(base, color), percent);
        // Linear Light
        case 16:
            return lerp(base, LinearLight(base, color), percent);
        // Pin Light
        case 17:
            return lerp(base, PinLight(base, color), percent);
        // Hard Mix
        case 18:
            return lerp(base, HardMix(base, color), percent);
        // Difference
        case 19:
            return lerp(base, Difference(base, color), percent);
        // Exclusion
        case 20:
            return lerp(base, Exclusion(base, color), percent);
        // Subtract
        case 21:
            return lerp(base, Subtract(base, color), percent);
        // Divide
        case 22:
            return lerp(base, Divide(base, color), percent);
        // Grain Merge
        case 23:
            return lerp(base, GrainMerge(base, color), percent);
        // Grain Extract
        case 24:
            return lerp(base, GrainExtract(base, color), percent);
        // Hue
        case 25:
            return lerp(base, Hue(base, color), percent);
        // Saturation
        case 26:
            return lerp(base, Saturation(base, color), percent);
        // ColorB
        case 27:
            return lerp(base, ColorB(base, color), percent);
        // Luminosity
        case 28:
            return lerp(base, Luminosity(base, color), percent);
    }
    return color;
}

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
        color.rgb = BlendWithBase(base.rgb, color.rgb, 1-amplitude);
    }
    else
    {
        color = tex2D(samplerColor, texcoord);
    }

#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
    return color;
#endif
}

technique Wave
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = Wave;
    }
}