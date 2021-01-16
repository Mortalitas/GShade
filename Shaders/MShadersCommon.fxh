////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////                                                    ////
////          MMMMMMMM               MMMMMMMM           ////
////          M:::::::M             M:::::::M           ////
////          M::::::::M           M::::::::M           ////
////          M:::::::::M         M:::::::::M           ////
////          M::::::::::M       M::::::::::M           ////
////          M:::::::::::M     M:::::::::::M           ////
////          M:::::::M::::M   M::::M:::::::M           ////
////          M::::::M M::::M M::::M M::::::M           ////
////          M::::::M  M::::M::::M  M::::::M           ////
////          M::::::M   M:::::::M   M::::::M           ////
////          M::::::M    M:::::M    M::::::M           ////
////          M::::::M     MMMMM     M::::::M           ////
////          M::::::M               M::::::M           ////
////          M::::::M               M::::::M           ////
////          M::::::M               M::::::M           ////
////          MMMMMMMM               MMMMMMMM           ////
////                                                    ////
////                MShaders <> by TreyM                ////
////                                                    ////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
//// DO NOT REDISTRIBUTE WITHOUT PERMISSION             ////
////////////////////////////////////////////////////////////


// GLOBAL VALUES /////////////////////////////////
//////////////////////////////////////////////////
#ifdef _TIMER
    uniform float  Timer      < source = "timer"; >;
#endif

#ifdef _FPS
    uniform float  Frametime  < source = "frametime"; >;
    #define        Framerate   (1000.0 /  Frametime)
    uniform int    Framecount < source = "framecount"; >;
#endif

#ifdef _DATE
uniform float4 Date           < source = "date"; >;
#endif

#ifdef _DEPTH_CHECK
uniform bool   HasDepth      < source = "bufready_depth"; >;
#endif

#ifdef _OVERLAY_CHECK
uniform bool   OverlayOpen   < source = "overlay_open"; >;
#endif


// GLOBAL TEXTURES ///////////////////////////////
//////////////////////////////////////////////////
texture TexColor : COLOR;
texture TexDepth : DEPTH;

#define BitDepth           BUFFER_COLOR_BIT_DEPTH

#if (BitDepth < 10)
    TEXTURE_FULL (TexCopy, BUFFER_WIDTH, BUFFER_HEIGHT, RGBA8)
#else
    TEXTURE_FULL (TexCopy, BUFFER_WIDTH, BUFFER_HEIGHT, RGB10A2)
#endif

TEXTURE_FULL (Tex16,       BUFFER_WIDTH, BUFFER_HEIGHT, RGBA16)
TEXTURE_FULL (TexBlur1,    BUFFER_WIDTH, BUFFER_HEIGHT, RGBA16)
TEXTURE_FULL (TexBlur2,    BUFFER_WIDTH, BUFFER_HEIGHT, RGBA16)


// SAMPLERS //////////////////////////////////////
//////////////////////////////////////////////////
SAMPLER_UV  (TextureColor, TexColor, MIRROR)
SAMPLER_UV  (Texture16,    Tex16,    MIRROR)
SAMPLER_UV  (TextureLuma,  TexCopy,  MIRROR)
SAMPLER_LIN (TextureLin,   TexColor, MIRROR)
SAMPLER_UV  (TextureDepth, TexDepth, BORDER)
SAMPLER_UV  (TextureCopy,  TexCopy,  MIRROR)
SAMPLER_UV  (TextureBlur1, TexBlur1, MIRROR)
SAMPLER_UV  (TextureBlur2, TexBlur2, MIRROR)


// VERTEX SHADER /////////////////////////////////
//////////////////////////////////////////////////
void VS_Tri(in uint id : SV_VertexID, out float4 vpos : SV_Position, out float2 coord : TEXCOORD)
{
	coord.x = (id == 2) ? 2.0 : 0.0;
	coord.y = (id == 1) ? 2.0 : 0.0;
	vpos = float4(coord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}


// GLOBAL FUNCTIONS //////////////////////////////
//////////////////////////////////////////////////
float3 SRGBToLin(float3 SRGBColor)
{
    // Fast convert sRGB to linear
    return saturate((SRGBColor * SRGBColor) - 0.00575);
}

float3 LinToSRGB(float3 LinearColor)
{
    // Fast convert linear to sRGB
    return saturate(sqrt(LinearColor + 0.00575));
}

#ifdef _DITHER
    #define        remap(v, a, b) (((v) - (a)) / ((b) - (a)))

    float rand21(float2 uv)
    {
        float2 noise = frac(sin(dot(uv, float2(12.9898, 78.233) * 2.0)) * 43758.5453);
        return (noise.x + noise.y) * 0.5;
    }

    float rand11(float x)
    {
        return frac(x * 0.024390243);
    }

    float permute(float x)
    {
        return ((34.0 * x + 1.0) * x) % 289.0;
    }

    ////////////////////////////////////////////////////
    // Triangular Dither                              //
    // <> by The Sandvich Maker                       //
    ////////////////////////////////////////////////////
    float3 Dither(float3 color, float2 uv, int bits)
    {
        float bitstep = exp2(bits) - 1.0;
        float lsb = 1.0 / bitstep;
        float lobit = 0.5 / bitstep;
        float hibit = (bitstep - 0.5) / bitstep;

        float3 m = float3(uv, rand21(uv + Timer)) + 1.0;
        float h = permute(permute(permute(m.x) + m.y) + m.z);

        float3 noise1, noise2;
        noise1.x = rand11(h); h = permute(h);
        noise2.x = rand11(h); h = permute(h);
        noise1.y = rand11(h); h = permute(h);
        noise2.y = rand11(h); h = permute(h);
        noise1.z = rand11(h); h = permute(h);
        noise2.z = rand11(h);

        float3 lo = saturate(remap(color.xyz, 0.0, lobit));
        float3 hi = saturate(remap(color.xyz, 1.0, hibit));
        float3 uni = noise1 - 0.5;
        float3 tri = noise1 - noise2;
    	 return lerp(uni, tri, min(lo, hi)) * lsb;
    }
#endif

// Bicubic function written by kingeric1992
float3 tex2Dbicub(sampler texSampler, float2 coord)
{
    float2 texsize = float2(BUFFER_WIDTH, BUFFER_HEIGHT);

    float4 uv;
    uv.xy = coord * texsize;

    // distant to nearest center
    float2 center  = floor(uv.xy - 0.5) + 0.5;
    float2 dist1st = uv.xy - center;
    float2 dist2nd = dist1st * dist1st;
    float2 dist3rd = dist2nd * dist1st;

    // B-Spline weights
    float2 weight0 =     -dist3rd + 3 * dist2nd - 3 * dist1st + 1;
    float2 weight1 =  3 * dist3rd - 6 * dist2nd               + 4;
    float2 weight2 = -3 * dist3rd + 3 * dist2nd + 3 * dist1st + 1;
    float2 weight3 =      dist3rd;

    weight0 += weight1;
    weight2 += weight3;

    // sample point to utilize bilinear filtering interpolation
    uv.xy  = center - 1 + weight1 / weight0;
    uv.zw  = center + 1 + weight3 / weight2;
    uv    /= texsize.xyxy;

    // Sample and blend
    return (weight0.y * (tex2D(texSampler, uv.xy).rgb * weight0.x + tex2D(texSampler, uv.zy).rgb * weight2.x) +
            weight2.y * (tex2D(texSampler, uv.xw).rgb * weight0.x + tex2D(texSampler, uv.zw).rgb * weight2.x)) / 36;
}
