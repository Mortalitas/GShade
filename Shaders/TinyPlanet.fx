/*-----------------------------------------------------------------------------------------------------*/
/* Tiny Planet Shader v4.0 - by Radegast Stravinsky of Ultros.                                         */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/
#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#define PI 3.141592358

uniform float center_x <
    ui_type = "slider";
    ui_label = "X Projection Position";
    ui_tooltip = "Adjusts the X coordinate projection of the sphere onto the display. The value is in degrees.";
    ui_min = 0.0; 
    ui_max = 360.0;
> = 0;

uniform float center_y <
    ui_type = "slider";
    ui_label = "Y Projection Position";
    ui_tooltip = "Adjusts the Y coordinate projection of the sphere onto the display. The value is in degrees.";
    ui_min = 0.0; 
    ui_max = 360.0;
> =0;

uniform float2 offset <
    ui_type = "slider";
    ui_label = "Offset";
    ui_tooltip = "Horizontally/Vertically offsets the center of the display by a certain amount.";
    ui_min = -.5; 
    ui_max = .5;
> = 0;

uniform float scale <
    ui_type = "slider";
    ui_label = "Scale";
    ui_tooltip = "Determine's the display's Z-position on the projected sphere. Use this to zoom into or zoom out of the planet if it's too small or big respectively.";
    ui_min = 0.0; 
    ui_max = 10.0;
> = 10.0;

uniform float z_rotation <
    ui_type = "slider";
    ui_label = "Z-Rotation";
    ui_tooltip = "Rotates the display along the z-axis. This can help you orient characters or features on your display the way you want.";
    ui_min = 0.0; 
    ui_max = 360.0;
> = 0.5;

uniform float seam_scale <
    ui_type = "slider";
    ui_min = 0.5;
    ui_max = 1.0;
    ui_label = "Seam Blending";
    ui_tooltip = "Blends the ends of the screen so that the seam is somewhat reasonably hidden.";
> = 0.5;

float3x3 getrot(float3 r)
{
    const float cx = cos(radians(r.x));
    const float sx = sin(radians(r.x));
    const float cy = cos(radians(r.y));
    const float sy = sin(radians(r.y));
    const float cz = cos(radians(r.z));
    const float sz = sin(radians(r.z));

    const float m1 = cy * cz;
    const float m2= cx * sz + sx * sy * cz;
    const float m3= sx * sz - cx * sy * cz;
    const float m4= -cy * sz;
    const float m5= cx * cz - sx * sy * sz;
    const float m6= sx * cz + cx * sy * sz;
    const float m7= sy;
    const float m8= -sx * cy;
    const float m9= cx * cy;

    return float3x3
    (
        m1,m2,m3,
        m4,m5,m6,
        m7,m8,m9
    );
};

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

// Vertex Shaders
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
float4 PreTP(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float inv_seam = 1 - seam_scale;
    float4 tc1 =  tex2D(samplerColor, texcoord + float2(inv_seam, 0.0));
    float4 tc = tex2D(samplerColor, texcoord * float2(seam_scale, 1.0));
    
    if(texcoord.x < inv_seam){ 
        tc.rgb = lerp(tc1.rgb, tc.rgb, 1- clamp((inv_seam-texcoord.x) * 10., 0, 1));
    }
    if(texcoord.x > seam_scale) tc.rgb = lerp(tc.rgb, tc1.rgb, clamp((texcoord.x-seam_scale) * 10., 0, 1));
    return tc;
}

float4 TinyPlanet(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    
    const float3x3 rot = getrot(float3(center_x,center_y, z_rotation));

    const float2 rads = float2(PI * 2.0 , PI);
    const float2 pnt = (texcoord - 0.5 - offset).xy * float2(scale, scale*ar);

    // Project to Sphere
    const float x2y2 = pnt.x * pnt.x + pnt.y * pnt.y;
    float3 sphere_pnt = float3(2.0 * pnt, x2y2 - 1.0) / (x2y2 + 1.0);
    
    sphere_pnt = mul(sphere_pnt, rot);

    // Convert to Spherical Coordinates
    const float r = length(sphere_pnt);
    const float lon = atan2(sphere_pnt.y, sphere_pnt.x);
    const float lat = acos(sphere_pnt.z / r);

#if GSHADE_DITHER
	const float4 outcolor = tex2D(samplerColor, float2(lon, lat) / rads);
	return float4(outcolor.rgb + TriDither(outcolor.rgb, texcoord, BUFFER_COLOR_BIT_DEPTH), outcolor.a);
#else
    return tex2D(samplerColor, float2(lon, lat) / rads);
#endif
}

// Technique
technique TinyPlanet<
    ui_label="Tiny Planet"; 
    ui_tooltip="Projects the image onto a sphere. Can be used to make planets.";
>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = PreTP;
    }
    pass p1
    {
        VertexShader = FullScreenVS;
        PixelShader = TinyPlanet;
    }
};