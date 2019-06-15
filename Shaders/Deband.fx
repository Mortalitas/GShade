/**
 * Deband shader by haasn
 * https://github.com/haasn/gentoo-conf/blob/xor/home/nand/.mpv/shaders/deband-pre.glsl
 *
 * Copyright (c) 2015 Niklas Haas
 *
 * mpv is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * mpv is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with mpv.  If not, see <http://www.gnu.org/licenses/>.
 *
 * You can alternatively redistribute this file and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * Modified and optimized for ReShade by JPulowski
 * http://reshade.me/forum/shader-presentation/768-deband
 *
 * Do not distribute without giving credit to the original author(s).
 *
 * 1.0  - Initial release
 * 1.1  - Replaced the algorithm with the one from MPV
 * 1.1a - Minor optimizations
 *        Removed unnecessary lines and replaced them with ReShadeFX intrinsic counterparts
 * 1.1b - Further minor optimizations by Marot Satil for the GShade project.
 * 2.0  - Replaced "grain" with CeeJay.dk's ordered dithering algorithm and enabled it by default
 *        The configuration is now more simpler and straightforward
 *        Some minor code changes and optimizations
 *        Improved the algorithm and made it more robust by adding some of the madshi's
 *        improvements to flash3kyuu_deband which should cause an increase in quality. Higher
 *        iterations/ranges should now yield higher quality debanding without too much decrease
 *        in quality.
 *        Changed licensing text and original source code URL
 */

#include "ReShade.fxh"

uniform int threshold_preset <
	ui_type = "combo";
    ui_label = "Debanding strength";
    ui_items = "Low\0Medium\0High\0Custom\0";
    ui_tooltip = "Debanding presets. Use Custom to be able to use custom thresholds in the advanced section.";
> = 3;

uniform float Range <
	ui_type = "slider";
    ui_min = 1.0;
    ui_max = 128.0;
    ui_step = 1.0;
    ui_label = "Initial radius";
    ui_tooltip = "The radius increases linearly for each iteration. A higher radius will find more gradients, but a lower radius will smooth more aggressively.";
> = 128.0;

uniform int Iterations <
	ui_type = "slider";
    ui_min = 1;
    ui_max = 16;
    ui_label = "Iterations";
    ui_tooltip = "The number of debanding steps to perform per sample. Each step reduces a bit more banding, but takes time to compute.";
> = 1;

uniform float custom_avgdiff <
	ui_type = "slider";
    ui_min = 0.0;
    ui_max = 255.0;
    ui_step = 0.1;
    ui_label = "Average threshold";
    ui_tooltip = "Threshold for the difference between the average of reference pixel values and the original pixel value. Higher numbers increase the debanding strength but progressively diminish image details. In pixel shaders a 8-bit color step equals to 1.0/255.0";
    ui_category = "Advanced";
> = 255.0;

uniform float custom_maxdiff <
	ui_type = "slider";
    ui_min = 0.0;
    ui_max = 255.0;
    ui_step = 0.1;
    ui_label = "Maximum threshold";
    ui_tooltip = "Threshold for the difference between the maximum difference of one of the reference pixel values and the original pixel value. Higher numbers increase the debanding strength but progressively diminish image details. In pixel shaders a 8-bit color step equals to 1.0/255.0";
    ui_category = "Advanced";
> = 10.0;

uniform float custom_middiff <
	ui_type = "slider";
    ui_min = 0.0;
    ui_max = 255.0;
    ui_step = 0.1;
    ui_label = "Middle threshold";
    ui_tooltip = "Threshold for the difference between the average of diagonal reference pixel values and the original pixel value. Higher numbers increase the debanding strength but progressively diminish image details. In pixel shaders a 8-bit color step equals to 1.0/255.0";
    ui_category = "Advanced";
> = 255.0;

uniform bool debug_output <
    ui_label = "Debug view";
    ui_tooltip = "Shows the low-pass filtered (blurred) output. Could be useful when making sure that range and iterations capture all of the banding in the picture.";
    ui_category = "Advanced";
> = false;

// Reshade uses C rand for random, max cannot be larger than 2^15-1
uniform float drandom < source = "random"; min = 0; max = 32767.0; >;

float rand(float x)
{
    return frac(x / 41.0);
}

float permute(float x)
{
    return ((34.0 * x + 1.0) * x) % 289.0;
}

void analyze_pixels(float3 ori, sampler2D tex, float2 texcoord, float2 _range, float2 dir, out float3 ref_avg, out float3 ref_avg_diff, out float3 ref_max_diff, out float3 ref_mid_diff1, out float3 ref_mid_diff2)
{
    // Sample at quarter-turn intervals around the source pixel

    // South-east
    float3 ref = tex2Dlod(tex, float4(texcoord + _range * dir, 0.0, 0.0)).rgb;
    float3 diff = abs(ori - ref);
    ref_max_diff = diff;
    ref_avg = ref;
    ref_mid_diff1 = ref;

    // North-west
    ref = tex2Dlod(tex, float4(texcoord + _range * -dir, 0.0, 0.0)).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    ref_mid_diff1 = abs(((ref_mid_diff1 + ref) * 0.5) - ori);

    // North-east
    ref = tex2Dlod(tex, float4(texcoord + _range * float2(-dir.y, dir.x), 0.0, 0.0)).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    ref_mid_diff2 = ref;

    // South-west
    ref = tex2Dlod(tex, float4(texcoord + _range * float2( dir.y, -dir.x), 0.0, 0.0)).rgb;
    diff = abs(ori - ref);
    ref_max_diff = max(ref_max_diff, diff);
    ref_avg += ref;
    ref_mid_diff2 = abs(((ref_mid_diff2 + ref) * 0.5) - ori);

    ref_avg *= 0.25; // Normalize avg
    ref_avg_diff = abs(ori - ref_avg);
}

float3 PS_Deband(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    // Settings

    float avgdiff;
    float maxdiff;
    float middiff;

    if (threshold_preset == 0) {
        avgdiff = 0.6;
        maxdiff = 1.9;
        middiff = 1.2;
    }
    else if (threshold_preset == 1) {
        avgdiff = 1.8;
        maxdiff = 4.0;
        middiff = 2.0;
    }
    else if (threshold_preset == 2) {
        avgdiff = 3.4;
        maxdiff = 6.8;
        middiff = 3.3;
    }
    else if (threshold_preset == 3) {
        avgdiff = custom_avgdiff;
        maxdiff = custom_maxdiff;
        middiff = custom_middiff;
    }

    // Normalize
    avgdiff /= 255.0;
    maxdiff /= 255.0;
    middiff /= 255.0;

    // Initialize the PRNG by hashing the position + a random uniform
    float h = permute(permute(permute(texcoord.x) + texcoord.y) + drandom / 32767.0);

    float3 ref_avg; // Average of 4 reference pixels
    float3 ref_avg_diff; // The difference between the average of 4 reference pixels and the original pixel
    float3 ref_max_diff; // The maximum difference between one of the 4 reference pixels and the original pixel
    float3 ref_mid_diff1; // The difference between the average of SE and NW reference pixels and the original pixel
    float3 ref_mid_diff2; // The difference between the average of NE and SW reference pixels and the original pixel

    const float3 ori = tex2Dlod(ReShade::BackBuffer, float4(texcoord, 0.0, 0.0)).rgb; // Original pixel
    float3 res; // Final pixel

    // Compute a random angle
    const float dir  = rand(permute(h)) * 6.2831853;
    const float2 o = float2(cos(dir), sin(dir));

    for (int i = 1; i <= Iterations; ++i) {
        // Compute a random distance
        const float dist = rand(h) * Range * i;
        const float2 pt = dist * ReShade::PixelSize;

        analyze_pixels(ori, ReShade::BackBuffer, texcoord, pt, o,
                       ref_avg,
                       ref_avg_diff,
                       ref_max_diff,
                       ref_mid_diff1,
                       ref_mid_diff2);

        const float3 ref_avg_diff_threshold = avgdiff * i;
        const float3 ref_max_diff_threshold = maxdiff * i;
        const float3 ref_mid_diff_threshold = middiff * i;

        // Fuzzy logic based pixel selection
        const float3 factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / ref_avg_diff_threshold)) *
                            saturate(3.0 * (1.0 - ref_max_diff  / ref_max_diff_threshold)) *
                            saturate(3.0 * (1.0 - ref_mid_diff1 / ref_mid_diff_threshold)) *
                            saturate(3.0 * (1.0 - ref_mid_diff2 / ref_mid_diff_threshold)), 0.1);

        if (debug_output)
            res = ref_avg;
        else
            res = lerp(ori, ref_avg, factor);

        h = permute(h);
    }

	const float dither_bit = 8.0; //Number of bits per channel. Should be 8 for most monitors.

	/*------------------------.
	| :: Ordered Dithering :: |
	'------------------------*/
	//Calculate grid position
	const float grid_position = frac(dot(texcoord, (ReShade::ScreenSize * float2(1.0 / 16.0, 10.0 / 36.0)) + 0.25));

	//Calculate how big the shift should be
	const float dither_shift = 0.25 * (1.0 / (pow(2, dither_bit) - 1.0));

	//Shift the individual colors differently, thus making it even harder to see the dithering pattern
	float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift); //subpixel dithering

	//modify shift acording to grid position.
	dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.

	//shift the color by dither_shift
	res += dither_shift_RGB;

    return res;
}

technique Deband <
ui_tooltip = "Alleviates color banding by trying to approximate original color values.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_Deband;
    }
}