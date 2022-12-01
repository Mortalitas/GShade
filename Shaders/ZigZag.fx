/*-----------------------------------------------------------------------------------------------------*/
/* ZigZag Shader - by Radegast Stravinsky of Ultros.                                               */
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
    ui_label = "Radius";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float angle <
    ui_type = "slider";
    ui_label = "Angle";
    ui_tooltip = "Serves as a multiplier for the phase and amplitude. Also affects the motion of the animation by phase based on whether the value is negative or positive.";
    ui_tooltip = "Adjusts the ripple angle. Positive and negative values affect the animation direction.";
    ui_min = -999.0; 
    ui_max = 999.0; 
    ui_step = 1.0;
> = 180.0;

uniform float period <
    ui_type = "slider";
    ui_type = "Phase";
    ui_tooltip = "Adjusts the rate of distortion.";
    ui_min = 0.1; 
    ui_max = 10.0;
> = 0.25;

uniform float amplitude <
    ui_type = "slider";
    ui_label = "Amplitude";
    ui_tooltip = "Increases how extreme the picture twists back and forth.";
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

uniform bool use_offset_coords <
    ui_label = "Use Offset Coordinates";
    ui_category = "Offset";
    ui_tooltip = "Display the distortion in any location besides its original coordinates.";
> = 0;

uniform float2 offset_coords <
    ui_label = "Offset Coordinates";
    ui_tooltip = "(Use Offset Coordinates Enabled) Determines the source coordinates to be distorted when passed along to the output coordinates.";
    ui_type = "slider";
    ui_category = "Offset";
    ui_min = 0.0;
    ui_max = 1.0;
> = float2(0.5, 0.5);

uniform float2 depth_bounds <
    ui_type = "slider";
    ui_label = "Depth Bounds";
    ui_category = "Depth";
    ui_tooltip = "The depth bounds where the effect is calculated.\nThe left value is the \"near\" value and the right value is the \"far\" value.";
    min = 0.0;
    max = 1.0;
> = float2(0.0, 1.0);

uniform float min_depth <
    ui_type = "slider";
    ui_label="Minimum Depth";
    ui_tooltip="Unmasks anything before a set depth.";
    ui_category = "Depth";
    ui_min=0.0;
    ui_max=1.0;
> = 0;

uniform float tension <
    ui_type = "slider";
    ui_label = "Tension";
    ui_tooltip = "Adjusts the rate at which the distortion reaches its maximum value";
    ui_min = 0; 
    ui_max = 10;
    ui_step = 0.001;
> = 1.0;

uniform float phase <
    ui_type = "slider";
    ui_label = "Phase";
    ui_tooltip = "The offset at which the pixels twist back and forth from the center.";
    ui_min = -5.0; 
    ui_max = 5.0;
> = 0.0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Amplitude\0Phase\0";
    ui_tooltip = "Enable or disable the animation. Animates the zigzag effect by phase or by amplitude.";
> = 0;

BLENDING_COMBO(
    render_type, 
    "Blending Mode", 
    "Blends the effect with the previous layers.",
    "Blending",
    false,
    0,
    0
);

uniform float blending_amount <
    ui_type = "slider";
    ui_label = "Opacity";
    ui_category = "Blending";
    ui_tooltip = "Adjusts the blending amount.";
    ui_min = 0.0;
    ui_max = 1.0;
> = 1.0;

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
    
    float2 center = coordinates / 2.0;
    float2 offset_center = offset_coords / 2.0;

    if (use_mouse_point) 
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH / 2.0, mouse_coordinates.y * BUFFER_RCP_HEIGHT / 2.0);

    float2 tc = texcoord - center;

    center.x /= ar;
    offset_center.x /= ar;
    tc.x /= ar;


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


    if(use_offset_coords)
        tc += (2 * offset_center);
    else 
        tc += (2 * center);

    tc.x *= ar;

    float out_depth = ReShade::GetLinearizedDepth(tc).r;
    bool inDepthBounds = out_depth >= depth_bounds.x && out_depth <= depth_bounds.y;

    float blending_factor;
    if(render_type) 
        blending_factor = min(lerp(0, percentSquared * 10, blending_amount), 1.0);
    else
        blending_factor = blending_amount;
    if (inDepthBounds)
    {
        if(use_offset_coords){
            float2 offset_coords_adjust = offset_coords;
            offset_coords_adjust.x *= ar;
            if(dist <= tension_radius)
            {
                color = tex2D(samplerColor, tc);
                color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
            }
            else
                color = tex2D(samplerColor, texcoord);
        } else
        {
            color = tex2D(samplerColor, tc);
            color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
        } 

        #if GSHADE_DITHER
            color.rgb += TriDither(color.rgb, tc, BUFFER_COLOR_BIT_DEPTH);
        #endif
    }
    else
    {
        color = base;
    }

    if(depth < min_depth)
        color = tex2D(samplerColor, texcoord);

#if GSHADE_DITHER
	return float4(color.rgb + TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
    return color;
#endif
}

// Technique
technique ZigZag<ui_label="Zigzag"; ui_tooltip="Around Center: Bends the pixels back and forth around a point.\nOut From Center: Creates a pond ripple effect.";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = ZigZag;
    }
};
