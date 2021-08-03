/*-----------------------------------------------------------------------------------------------------*/
/* Swirl Shader v5.0 - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform int swirl_mode <
    ui_type="combo";
    ui_label="Mode";
    ui_items="Normal\0Spliced Radial\0";
    ui_tooltip="Selects which swirl mode to display.\nNormal Mode -- Contiguously twists pixels around a point.\nSpliced Radials -- Creates incrementally rotated circular splices.";
> = 0;

uniform float radius <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float inner_radius <
    ui_type = "slider";
    ui_label = "Inner Radius";
    ui_tooltip = "Normal Mode -- Sets the inner radius at which the maximum angle is automatically set.\nSpliced Radial mode -- defines the innermost spliced circle's size.";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0;

uniform int number_splices <
    ui_type = "slider";
    ui_label = "Number of Splices";
    ui_tooltip = "(Spliced Radial Mode Only) Sets the number of splices. A higher value makes the effect look closer to Normal mode by increasing the number of splices.";
    ui_min = 1;
    ui_max = 50;
> = 10;

uniform float angle <
    ui_type = "slider";
    ui_min = -1800.0; 
    ui_max = 1800.0; 
    ui_tooltip = "Controls the angle of the twist.";
    ui_step = 1.0;
> = 180.0;

uniform float tension <
    ui_type = "slider";
    ui_min = 0; 
    ui_max = 10; 
    ui_step = 0.001;
    ui_tooltip="Determines how rapidly the swirl reaches the maximum angle.";
> = 1.0;

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
    ui_tooltip = "Changes the distortion's aspect ratio in regards to the display aspect ratio.";
> = 0;

uniform float min_depth <
    ui_type = "slider";
    ui_label="Minimum Depth";
    ui_min=0.0;
    ui_max=1.0;
    ui_tooltip="The minimum depth to distort.\nAnything closer than the threshold will appear normally. (0 = Near, 1 = Far)";
> = 0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Animates the swirl, moving it clockwise and counterclockwise.";
> = 0;

uniform int inverse <
    ui_type = "combo";
    ui_label = "Inverse Angle";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Inverts the angle of the swirl, making the edges the most distorted.";
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

    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16;
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
float4 Swirl(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar_raw = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    float ar = lerp(ar_raw, 1, aspect_ratio * 0.01);
    const float4 base = tex2D(samplerColor, texcoord);
    const float depth = ReShade::GetLinearizedDepth(texcoord).r;
    float2 center = coordinates;
    
    if (use_mouse_point) 
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH / 2.0, mouse_coordinates.y * BUFFER_RCP_HEIGHT / 2.0);

    float2 tc = texcoord - center;
    float4 color;

    center.x /= ar;
    tc.x /= ar;

    if (depth >= min_depth)
    {
        const float dist = distance(tc, center);
        const float dist_radius = radius-dist;
        const float tension_radius = lerp(radius-dist, radius, tension);
        float percent; 
        float theta; 
       
        if(swirl_mode == 0){
            percent = max(dist_radius, 0) / tension_radius;   
            if(inverse && dist < radius)
                percent = 1 - percent;     
        
            if(dist_radius > radius-inner_radius)
                percent = 1;
            theta = percent * percent * radians(angle * (animate == 1 ? sin(anim_rate * 0.0005) : 1.0));
        }
        else
        {
            float splice_width = (tension_radius-inner_radius) / number_splices;
            splice_width = frac(splice_width);
            float cur_splice = max(dist_radius,0)/splice_width;
            cur_splice = cur_splice - frac(cur_splice);
            float splice_angle = (angle / number_splices) * cur_splice;
            if(dist_radius > radius-inner_radius)
                splice_angle = angle;
            theta = radians(splice_angle * (animate == 1 ? sin(anim_rate * 0.0005) : 1.0));
        }

        tc = mul(swirlTransform(theta), tc-center);
        tc += (2 * center);
        tc.x *= ar;
      
        color = tex2D(samplerColor, tc);
    }
    else
    {
        color = tex2D(samplerColor, texcoord);
    }

    if(depth >= min_depth){

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
    }

#if GSHADE_DITHER
    return float4(color.rgb + TriDither(color.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), color.a);
#else
    return color;
#endif
}

// Technique
technique Swirl< ui_label="Swirl";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = Swirl;
    }
};
