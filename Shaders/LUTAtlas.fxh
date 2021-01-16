// MULTI-LUT FUNCTION ////////////////////////////
// Based on Marty McFly's original shader       //
// Copyright © 2008-2016 Marty McFly            //
// LUT Atlas functionality added by OtisInf     //
//////////////////////////////////////////////////

float3 LUTAtlas(float3 color, sampler SamplerLUT, int INDEX, float2 coord)
{
    float3 lutcoord;
    float2 texel;
    float  lookup;

	texel       = 1.0 / LUT_SIZE;
	texel.x    /= LUT_SIZE;

	lutcoord    = float3((color.xy* LUT_SIZE - color.xy + 0.5) * texel.xy, color.z * LUT_SIZE - color.z);
	lutcoord.y /= LUT_COUNT;
	lutcoord.y += (float(INDEX) / LUT_COUNT);
	lookup      = frac(lutcoord.z);
	lutcoord.x += (lutcoord.z-lookup)*texel.y;

	return lerp(tex2D(SamplerLUT, lutcoord.xy).xyz, tex2D(SamplerLUT, float2(lutcoord.x + texel.y, lutcoord.y)).xyz, lookup);
}
