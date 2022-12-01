/*-----------------------------------------------------------------------------------------------------*/
/* Swirl Shader - by Radegast Stravinsky of Ultros.                                               */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"
#include "Blending.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

uniform float radius <
    ui_label= "Radius";
    ui_tooltip = "The size of the distortion.";
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float inner_radius <
    ui_type = "slider";
    ui_label = "Inner Radius";
    ui_tooltip = "Sets the inner radius at which the maximum angle is automatically set.";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0;

uniform float angle <
    ui_type = "slider";
    ui_label = "Angle";
    ui_min = -1800.0; 
    ui_max = 1800.0; 
    ui_tooltip = "Controls the angle of the twist.";
    ui_step = 1.0;
> = 180.0;

uniform float tension <
    ui_type = "slider";
    ui_label = "Tension";
    ui_min = 0; 
    ui_max = 10; 
    ui_step = 0.001;
    ui_tooltip="Determines how rapidly the swirl reaches the maximum angle.";
> = 1.0;

uniform float2 coordinates <
    ui_type = "slider";
    ui_label="Coordinates"; 
    ui_tooltip="(Use Offset Coordinates Disabled) The X and Y position of the center of the effect.\n(Use Offset Coordinates Enabled) Determines the coordinates of the output distortion on the undistorted source.";
    ui_min = 0.0; 
    ui_max = 1.0;
> = float2(0.5, 0.5);

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
    ui_min=0.0;
    ui_max=1.0;
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
    float2 center = coordinates / 2.0;
    float2 offset_center = offset_coords / 2.0;
    
    if (use_mouse_point) 
        center = float2(mouse_coordinates.x * BUFFER_RCP_WIDTH / 2.0, mouse_coordinates.y * BUFFER_RCP_HEIGHT / 2.0);

    float2 tc = texcoord - center;
    float4 color;

    center.x /= ar;
    offset_center.x /= ar;
    tc.x /= ar;

    
    const float dist = distance(tc, center);
    const float dist_radius = radius-dist;
    const float tension_radius = lerp(radius-dist, radius, tension);
    float percent; 
    float theta; 
       
    percent = max(dist_radius, 0) / tension_radius;   
    if(inverse && dist < radius)
        percent = 1 - percent;     
        
    if(dist_radius > radius-inner_radius)
        percent = 1;
        
    theta = percent * percent * radians(angle * (animate == 1 ? sin(anim_rate * 0.0005) : 1.0));
    tc = mul(swirlTransform(theta), tc-center);
    
    if(use_offset_coords) 
        tc += (2 * offset_center);
    else 
        tc += (2 * center);

    tc.x *= ar;
      
    float out_depth = ReShade::GetLinearizedDepth(tc).r;
    bool inDepthBounds = out_depth >= depth_bounds.x && out_depth <= depth_bounds.y;
     
    if (inDepthBounds)
    {
        if(use_offset_coords)
        {
            if(percent)
                color = tex2D(samplerColor, tc);
            else
                color = tex2D(samplerColor, texcoord);
        } else
            color = tex2D(samplerColor, tc);

        float blending_factor;
        
        if(render_type)
            blending_factor = min(lerp(0,  dist_radius / dist, blending_amount), 1.0);
        else
            blending_factor = blending_amount;
        
        if(percent)
            color.rgb = ComHeaders::Blending::Blend(render_type, base.rgb, color.rgb, blending_factor);
            
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
   
    return color;  
}

// Technique
technique Swirl<ui_label="Swirl"; ui_tooltip="Twists pixels around a given point.";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = Swirl;
    }
};
