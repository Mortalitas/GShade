/*-----------------------------------------------------------------------------------------------------*/
/* ZigZag Shader v5.0 - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform int mode <
    ui_type = "combo";
    ui_label = "Mode";
    ui_items = "Around center\0Out from center\0";
    ui_tooltip = "Selects the mode the distortion should be processed through.";
> = 0;

uniform float radius <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float angle <
    ui_type = "slider";
    ui_tooltip = "Adjusts the ripple angle. Positive and negative values affect the animation direction.";
    ui_min = -999.0; 
    ui_max = 999.0; 
    ui_step = 1.0;
> = 180.0;

uniform float period <
    ui_type = "slider";
    ui_min = 0.1; 
    ui_max = 10.0;
> = 0.25;

uniform float amplitude <
    ui_type = "slider";
    ui_min = -10.0; 
    ui_max = 10.0;
> = 3.0;

uniform float2 coordinates <
    ui_type = "slider";
    ui_label="Coordinates";
    ui_tooltip="The X and Y position of the center of the effect.";
    ui_min = 0.0; 
    ui_max = 1.0;
> = float2(0.25, 0.25);

uniform bool use_mouse_point <
    ui_label="Use Mouse Coordinates";
    ui_tooltip="When enabled, uses the mouse's current coordinates instead of those defined by the Coordinates sliders";
> = false;

uniform float aspect_ratio <
    ui_type = "slider";
    ui_label="Aspect Ratio"; 
    ui_min = -100.0; 
    ui_max = 100.0;
> = 0;

uniform float min_depth <
    ui_type = "slider";
    ui_label="Minimum Depth";
    ui_min=0.0;
    ui_max=1.0;
> = 0;

uniform float tension <
    ui_type = "slider";
    ui_label = "Tension";
    ui_min = 0; 
    ui_max = 10;
    ui_step = 0.001;
> = 1.0;

uniform float phase <
    ui_type = "slider";
    ui_min = -5.0; 
    ui_max = 5.0;
> = 0.0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Amplitude\0Phase\0";
    ui_tooltip = "Enable or disable the animation. Animates the zigzag effect by phase or by amplitude.";
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
texture texDepthBuffer : DEPTH;

sampler samplerColor
{
    Texture = texColorBuffer;

    AddressU = MIRROR;
    AddressV = MIRROR;
    AddressW = MIRROR;

};

float2x2 swirlTransform(float theta) {
    const float c = cos(theta);
    const float s = sin(theta);

    const float m1 = c;
    const float m2 = -s;
    const float m3 = s;
    const float m4 = c;

    return float2x2(
        m1, m2,
        m3, m4
    );
}

float2x2 zigzagTransform(float dist) {
    const float c = cos(dist);
    return float2x2(
        c, 0,
        0, c
    );
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

// Pixel Shaders (in order of appearance in the technique)
float4 ZigZag(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float4 color;
    const float4 base = tex2D(samplerColor, texcoord);
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);
    
    float2 center = coordinates;
    if (use_mouse_point) 
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH / 2.0, mouse_coordinates.y * BUFFER_RCP_HEIGHT / 2.0);

    float2 tc = texcoord - center;

    center.x /= ar;
    tc.x /= ar;


    if (depth >= min_depth)
    {
        const float dist = distance(tc, center);
        const float tension_radius = lerp(radius-dist, radius, tension);
        const float percent = max(radius-dist, 0) / tension_radius;
        const float percentSquared = percent * percent;
        const float theta = percentSquared * (animate == 1 ? amplitude * sin(anim_rate * 0.0005) : amplitude) * sin(percentSquared / period * radians(angle) + (phase + (animate == 2 ? 0.00075 * anim_rate : 0)));

        if(!mode) 
        {
            tc = mul(swirlTransform(theta), tc-center);
        }
        else
        {
            tc = mul(zigzagTransform(theta), tc-center);
        }


        tc += (2.0 * center);
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

// Technique
technique ZigZag
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = ZigZag;
    }
};
