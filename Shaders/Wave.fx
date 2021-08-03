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
> = 0.0;

uniform float period <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_min = 0.1; ui_max = 10.0;
    ui_tooltip = "The wavelength of the distortion. Smaller values make for a longer wavelength.";
> = 3.0;

uniform float amplitude <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_min = -1.0; ui_max = 1.0;
    ui_tooltip = "The amplitude of the distortion in each direction.";
> = 0.075;

uniform float phase <
    #if __RESHADE__ < 40000
        ui_type = "drag";
    #else
        ui_type = "slider";
    #endif
    ui_min = -5.0; ui_max = 5.0;
    ui_tooltip = "The offset being applied to the distortion's waves.";
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
            // Darken
            case 1:
                color.rgb = Darken(base.rgb, color.rgb);
                break;
            // Multiply
            case 2:
                color.rgb = Multiply(base.rgb, color.rgb);
                break;
            // Color Burn
            case 3:
                color.rgb = ColorBurn(base.rgb, color.rgb);
                break;
            // Linear Burn
            case 4:
                color.rgb = LinearBurn(base.rgb, color.rgb);
                break;
            // Lighten
            case 5:
                color.rgb = Lighten(base.rgb, color.rgb);
                break;
            // Screen
            case 6:
                color.rgb = Screen(base.rgb, color.rgb);
                break;
            // Color Dodge
            case 7:
                color.rgb = ColorDodge(base.rgb, color.rgb);
                break;
            // Linear Dodge
            case 8:
                color.rgb = LinearDodge(base.rgb, color.rgb);
                break;
            // Addition
            case 9:
                color.rgb = Addition(base.rgb, color.rgb);
                break;
            // Reflect
            case 10:
                color.rgb = Reflect(base.rgb, color.rgb);
                break;
            // Glow
            case 11:
                color.rgb = Glow(base.rgb, color.rgb);
                break;
            // Overlay
            case 12:
                color.rgb = Overlay(base.rgb, color.rgb);
                break;
            // Soft Light
            case 13:
                color.rgb = SoftLight(base.rgb, color.rgb);
                break;
            // Hard Light
            case 14:
                color.rgb = HardLight(base.rgb, color.rgb);
                break;
            // Vivid Light
            case 15:
                color.rgb = VividLight(base.rgb, color.rgb);
                break;
            // Linear Light
            case 16:
                color.rgb = LinearLight(base.rgb, color.rgb);
                break;
            // Pin Light
            case 17:
                color.rgb = PinLight(base.rgb, color.rgb);
                break;
            // Hard Mix
            case 18:
                color.rgb = HardMix(base.rgb, color.rgb);
                break;
            // Difference
            case 19:
                color.rgb = Difference(base.rgb, color.rgb);
                break;
            // Exclusion
            case 20:
                color.rgb = Exclusion(base.rgb, color.rgb);
                break;
            // Subtract
            case 21:
                color.rgb = Subtract(base.rgb, color.rgb);
                break;
            // Divide
            case 22:
                color.rgb = Divide(base.rgb, color.rgb);
                break;
            // Grain Merge
            case 23:
                color.rgb = GrainMerge(base.rgb, color.rgb);
                break;
            // Grain Extract
            case 24:
                color.rgb = GrainExtract(base.rgb, color.rgb);
                break;
            // Hue
            case 25:
                color.rgb = Hue(base.rgb, color.rgb);
                break;
            // Saturation
            case 26:
                color.rgb = Saturation(base.rgb, color.rgb);
                break;
            // ColorB
            case 27:
                color.rgb = ColorB(base.rgb, color.rgb);
                break;
            // Luminosity
            case 28:
                color.rgb = Luminosity(base.rgb, color.rgb);
                break;
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