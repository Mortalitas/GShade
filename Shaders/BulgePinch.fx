/*-----------------------------------------------------------------------------------------------------*/
/* PBDistort Shader v5.0 - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"
#include "Blending.fxh"

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

uniform bool use_mouse_point <
    ui_label="Use Mouse Coordinates";
    ui_tooltip="When enabled, uses the mouse's current coordinates instead of those defined by the Coordinates sliders";
> = false;

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

uniform int render_type <
    ui_type = "combo";
    ui_label = "Blending Mode";
    ui_items = "Normal\0Darken\0Multiply\0Color Burn\0Linear Burn\0Lighten\0Screen\0Color Dodge\0Linear Dodge\0Addition\0Reflect\0Glow\0Overlay\0Soft Light\0Hard Light\0Vivid Light\0Linear Light\0Pin Light\0Hard Mix\0Difference\0Exclusion\0Subtract\0Divide\0Grain Merge\0Grain Extract\0Hue\0Saturation\0ColorB\0Luminosity\0";
    ui_tooltip = "Additively render the effect.";
> = 0;

uniform float anim_rate <
    source = "timer";
>;

uniform float2 mouse_coordinates < 
source= "mousepoint";
>;

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
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    
    position = float4( texcoord * float2(2, -2) + float2(-1, 1), 0, 1);
    //position /= BUFFER_HEIGHT/BUFFER_WIDTH;

}

// Pixel Shaders (in order of appearance in the technique)
float4 PBDistort(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);

    float2 center = coordinates;
    if (use_mouse_point) 
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH / 2.0, mouse_coordinates.y * BUFFER_RCP_HEIGHT / 2.0);

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
            tc = (tc-center) * lerp(1.0, pow(abs(percent), 1.0 + anim_mag * 0.75) * radius/dist, 1.0 - percent);

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

    return color;
}

// Technique
technique BulgePinch < ui_label="Bulge/Pinch";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = PBDistort;
    }
};