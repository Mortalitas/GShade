/*-----------------------------------------------------------------------------------------------------*/
/* Tiny Planet Shader v2.0 - by Radegast Stravinsky of Ultros.                                         */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/*-----------------------------------------------------------------------------------------------------*/

#define PI 3.141592358

uniform float center_x <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 360.0;
> = 0;

uniform float center_y <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 360.0;
> =0;

uniform float offset_x <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0;

uniform float offset_y <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = .5;
> = 0;

uniform float scale <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 10.0;
> = 10.0;

uniform float z_rotation <
    ui_type = "slider";
    ui_min = 0.0; 
    ui_max = 360.0;
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
float4 TinyPlanet(float4 pos : SV_Position, float2 texcoord : TEXCOORD0) : SV_TARGET
{
    const float ar = 1.0 * (float)BUFFER_HEIGHT / (float)BUFFER_WIDTH;
    
    const float3x3 rot = getrot(float3(center_x,center_y, z_rotation));

    const float2 rads = float2(PI * 2.0 , PI);
    const float2 offset=float2(offset_x, offset_y);
    const float2 pnt = (texcoord - 0.5 - offset).xy * float2(scale, scale*ar);

    // Project to Sphere
    const float x2y2 = pnt.x * pnt.x + pnt.y * pnt.y;
    float3 sphere_pnt = float3(2.0 * pnt, x2y2 - 1.0) / (x2y2 + 1.0);
    
    sphere_pnt = mul(sphere_pnt, rot);

    // Convert to Spherical Coordinates
    const float r = length(sphere_pnt);
    const float lon = atan2(sphere_pnt.y, sphere_pnt.x);
    const float lat = acos(sphere_pnt.z / r);

    return tex2D(samplerColor, float2(lon, lat) / rads);
}

// Technique
technique TinyPlanet<ui_label="Tiny Planet";>
{
    pass p0
    {
        VertexShader = FullScreenVS;
        PixelShader = TinyPlanet;
    }
};