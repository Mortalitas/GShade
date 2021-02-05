// Only run blur calc within downscaled image bounds (thanks for the help, kingeric1992)
#ifndef _BLUR_BOUNDS
    #define _LOWER_BOUND 1.0
    #define _UPPER_BOUND 0.0
    #define _LEFT_BOUND  0.0
    #define _RIGHT_BOUND 1.0
#endif

// 18 SIZE ///////////////////////////////////////
float Blur18H (float luma, sampler Samplerluma, float2 coord)
{
    float offset[18] =
    {
        0.0,            1.4953705027, 3.4891992113,
        5.4830312105,   7.4768683759, 9.4707125766,
        11.4645656736, 13.4584295168, 15.4523059431,
        17.4461967743, 19.4661974725, 21.4627427973,
        23.4592916956, 25.455844494,  27.4524015179,
        29.4489630909, 31.445529535,  33.4421011704
    };

    float kernel[18] =
    {
        0.033245,     0.0659162217, 0.0636705814,
        0.0598194658, 0.0546642566, 0.0485871646,
        0.0420045997, 0.0353207015, 0.0288880982,
        0.0229808311, 0.0177815511, 0.013382297,
        0.0097960001, 0.0069746748, 0.0048301008,
        0.0032534598, 0.0021315311, 0.0013582974
    };

    luma *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return luma;

    [loop]
    for(int i = 1; i < 18; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.x + i * BUFFER_PIXEL_SIZE.x) > _RIGHT_BOUND  ||
             (coord.x - i * BUFFER_PIXEL_SIZE.x) < _LEFT_BOUND)) continue;

        luma += tex2Dlod(Samplerluma, float4(coord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).x * kernel[i];
        luma += tex2Dlod(Samplerluma, float4(coord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).x * kernel[i];
    }

    return luma;
}

float Blur18V (float luma, sampler Samplerluma, float2 coord)
{
    float offset[18] =
    {
        0.0,            1.4953705027, 3.4891992113,
        5.4830312105,   7.4768683759, 9.4707125766,
        11.4645656736, 13.4584295168, 15.4523059431,
        17.4461967743, 19.4661974725, 21.4627427973,
        23.4592916956, 25.455844494,  27.4524015179,
        29.4489630909, 31.445529535,  33.4421011704
    };

    float kernel[18] =
    {
        0.033245,     0.0659162217, 0.0636705814,
        0.0598194658, 0.0546642566, 0.0485871646,
        0.0420045997, 0.0353207015, 0.0288880982,
        0.0229808311, 0.0177815511, 0.013382297,
        0.0097960001, 0.0069746748, 0.0048301008,
        0.0032534598, 0.0021315311, 0.0013582974
    };

    luma *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return luma;

    [loop]
    for(int i = 1; i < 18; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.y + i * BUFFER_PIXEL_SIZE.y) > _LOWER_BOUND   ||
             (coord.y - i * BUFFER_PIXEL_SIZE.y) < _UPPER_BOUND)) continue;

        luma += tex2Dlod(Samplerluma, float4(coord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).x * kernel[i];
        luma += tex2Dlod(Samplerluma, float4(coord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).x * kernel[i];
    }

    return luma;
}

float3 Blur18H (float3 color, sampler SamplerColor, float2 coord)
{
    float offset[18] =
    {
        0.0,            1.4953705027, 3.4891992113,
        5.4830312105,   7.4768683759, 9.4707125766,
        11.4645656736, 13.4584295168, 15.4523059431,
        17.4461967743, 19.4661974725, 21.4627427973,
        23.4592916956, 25.455844494,  27.4524015179,
        29.4489630909, 31.445529535,  33.4421011704
    };

    float kernel[18] =
    {
        0.033245,     0.0659162217, 0.0636705814,
        0.0598194658, 0.0546642566, 0.0485871646,
        0.0420045997, 0.0353207015, 0.0288880982,
        0.0229808311, 0.0177815511, 0.013382297,
        0.0097960001, 0.0069746748, 0.0048301008,
        0.0032534598, 0.0021315311, 0.0013582974
    };

    color *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return color;

    [loop]
    for(int i = 1; i < 18; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.x + i * BUFFER_PIXEL_SIZE.x) > _RIGHT_BOUND  ||
             (coord.x - i * BUFFER_PIXEL_SIZE.x) < _LEFT_BOUND)) continue;

        color += tex2Dlod(SamplerColor, float4(coord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).rgb * kernel[i];
        color += tex2Dlod(SamplerColor, float4(coord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).rgb * kernel[i];
    }

    return color;
}

float3 Blur18V (float3 color, sampler SamplerColor, float2 coord)
{
    float offset[18] =
    {
        0.0,            1.4953705027, 3.4891992113,
        5.4830312105,   7.4768683759, 9.4707125766,
        11.4645656736, 13.4584295168, 15.4523059431,
        17.4461967743, 19.4661974725, 21.4627427973,
        23.4592916956, 25.455844494,  27.4524015179,
        29.4489630909, 31.445529535,  33.4421011704
    };

    float kernel[18] =
    {
        0.033245,     0.0659162217, 0.0636705814,
        0.0598194658, 0.0546642566, 0.0485871646,
        0.0420045997, 0.0353207015, 0.0288880982,
        0.0229808311, 0.0177815511, 0.013382297,
        0.0097960001, 0.0069746748, 0.0048301008,
        0.0032534598, 0.0021315311, 0.0013582974
    };

    color *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return color;

    [loop]
    for(int i = 1; i < 18; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.y + i * BUFFER_PIXEL_SIZE.y) > _LOWER_BOUND  ||
             (coord.y - i * BUFFER_PIXEL_SIZE.y) < _UPPER_BOUND)) continue;

        color += tex2Dlod(SamplerColor, float4(coord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).rgb * kernel[i];
        color += tex2Dlod(SamplerColor, float4(coord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).rgb * kernel[i];
    }

    return color;
}


// 11 SIZE ///////////////////////////////////////
float Blur11H (float luma, sampler Samplerluma, float2 coord)
{
    float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float kernel[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };

    luma *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return luma;

    [loop]
    for(int i = 1; i < 11; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.x + i * BUFFER_PIXEL_SIZE.x) > _RIGHT_BOUND  ||
             (coord.x - i * BUFFER_PIXEL_SIZE.x) < _LEFT_BOUND)) continue;

        luma += tex2Dlod(Samplerluma, float4(coord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).x * kernel[i];
        luma += tex2Dlod(Samplerluma, float4(coord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).x * kernel[i];
    }

    return luma;
}

float Blur11V (float luma, sampler Samplerluma, float2 coord)
{
    float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float kernel[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };

    luma *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return luma;

    [loop]
    for(int i = 1; i < 11; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.y + i * BUFFER_PIXEL_SIZE.y) > _LOWER_BOUND   ||
             (coord.y - i * BUFFER_PIXEL_SIZE.y) < _UPPER_BOUND)) continue;

        luma += tex2Dlod(Samplerluma, float4(coord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).x * kernel[i];
        luma += tex2Dlod(Samplerluma, float4(coord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).x * kernel[i];
    }

    return luma;
}

float3 Blur11H (float3 color, sampler SamplerColor, float2 coord)
{
    float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float kernel[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };

    color *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return color;

    [loop]
    for(int i = 1; i < 11; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.x + i * BUFFER_PIXEL_SIZE.x) > _RIGHT_BOUND  ||
             (coord.x - i * BUFFER_PIXEL_SIZE.x) < _LEFT_BOUND)) continue;

        color += tex2Dlod(SamplerColor, float4(coord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).rgb * kernel[i];
        color += tex2Dlod(SamplerColor, float4(coord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).rgb * kernel[i];
    }

    return color;
}

float3 Blur11V (float3 color, sampler SamplerColor, float2 coord)
{
    float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float kernel[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };

    color *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return color;

    [loop]
    for(int i = 1; i < 11; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.y + i * BUFFER_PIXEL_SIZE.y) > _LOWER_BOUND  ||
             (coord.y - i * BUFFER_PIXEL_SIZE.y) < _UPPER_BOUND)) continue;

        color += tex2Dlod(SamplerColor, float4(coord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).rgb * kernel[i];
        color += tex2Dlod(SamplerColor, float4(coord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).rgb * kernel[i];
    }

    return color;
}


// 6 SIZE ///////////////////////////////////////
float Blur6H (float luma, sampler Samplerluma, float2 coord)
{
    float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float kernel[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };

    luma *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return luma;

    [loop]
    for(int i = 1; i < 11; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.x + i * BUFFER_PIXEL_SIZE.x) > _RIGHT_BOUND  ||
             (coord.x - i * BUFFER_PIXEL_SIZE.x) < _LEFT_BOUND)) continue;

        luma += tex2Dlod(Samplerluma, float4(coord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).x * kernel[i];
        luma += tex2Dlod(Samplerluma, float4(coord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).x * kernel[i];
    }

    return luma;
}

float Blur6V (float luma, sampler Samplerluma, float2 coord)
{
    float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float kernel[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };

    luma *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return luma;

    [loop]
    for(int i = 1; i < 6; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.y + i * BUFFER_PIXEL_SIZE.y) > _LOWER_BOUND   ||
             (coord.y - i * BUFFER_PIXEL_SIZE.y) < _UPPER_BOUND)) continue;

        luma += tex2Dlod(Samplerluma, float4(coord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).x * kernel[i];
        luma += tex2Dlod(Samplerluma, float4(coord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).x * kernel[i];
    }

    return luma;
}

float3 Blur6H (float3 color, sampler SamplerColor, float2 coord)
{
    float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float kernel[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };

    color *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return color;

    [loop]
    for(int i = 1; i < 6; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.x + i * BUFFER_PIXEL_SIZE.x) > _RIGHT_BOUND  ||
             (coord.x - i * BUFFER_PIXEL_SIZE.x) < _LEFT_BOUND)) continue;

        color += tex2Dlod(SamplerColor, float4(coord + float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).rgb * kernel[i];
        color += tex2Dlod(SamplerColor, float4(coord - float2(offset[i] * BUFFER_PIXEL_SIZE.x, 0.0), 0.0, 0.0)).rgb * kernel[i];
    }

    return color;
}

float3 Blur6V (float3 color, sampler SamplerColor, float2 coord)
{
    float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float kernel[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };

    color *= kernel[0];

    [branch]
    // Only run blur calc within downscaled image bounds
    if ((coord.x > _RIGHT_BOUND || coord.x < _LEFT_BOUND   ||
         coord.y > _LOWER_BOUND || coord.y < _UPPER_BOUND))
         return color;

    [loop]
    for(int i = 1; i < 6; ++i)
    {
        // Only run blur calc within downscaled image bounds
        if (((coord.y + i * BUFFER_PIXEL_SIZE.y) > _LOWER_BOUND  ||
             (coord.y - i * BUFFER_PIXEL_SIZE.y) < _UPPER_BOUND)) continue;

        color += tex2Dlod(SamplerColor, float4(coord + float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).rgb * kernel[i];
        color += tex2Dlod(SamplerColor, float4(coord - float2(0.0, offset[i] * BUFFER_PIXEL_SIZE.y), 0.0, 0.0)).rgb * kernel[i];
    }

    return color;
}
