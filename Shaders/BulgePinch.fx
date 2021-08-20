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
        color.rgb = BlendWithBase(base.rgb, color.rgb, percent);
    }
    else {
        color = tex2D(samplerColor, texcoord);
    }



#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
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