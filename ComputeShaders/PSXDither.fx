//PS1 Hardware Dithering & Color Precision Truncation Function
//by ompu co | Sam Blye (c) 2020

uniform bool useDither <
    ui_label = "Use Dithering";
    ui_tooltip = "Leave unchecked to disable dithering and only truncate raw color input.";
> = false;

#include "ReShade.fxh"

//PS1 dither table from PSYDEV SDK documentation
static const float4x4 psx_dither_table = float4x4
        (
             0.0,     8.0,     2.0,    10.0,
            12.0,     4.0,    14.0,     6.0,
             3.0,    11.0,     1.0,     9.0,
            15.0,     7.0,    13.0,     5.0
        );
//if desired, this can also be stored as an int4x4

//col - your high-precision color input
float3 DitherCrunch(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
    float3 col = tex2D(ReShade::BackBuffer, texcoord).rgb * 255.0; //extrapolate 16bit color float to 16bit integer space
    if(useDither)
    {
        const float dither = psx_dither_table[uint(texcoord.x) % 4][uint(texcoord.y) % 4];
        col += (dither / 2.0 - 4.0); //dithering process as described in PSYDEV SDK documentation
    }
    col = lerp((uint3(col) & 0xf8), 0xf8, step(0xf8, col));
    //truncate to 5bpc precision via bitwise AND operator, and limit value max to prevent wrapping.
    //PS1 colors in default color mode have a maximum integer value of 248 (0xf8)
    return col / 255.0; //bring color back to floating point number space
}

//For best results, run DitherCrunch() during initial rasterization by adding this at the end of your
//material's fragment shader, & not in post processing.
//This allows for proper high quality dithering directly from the full-fidelity vertex gradients,
//more accurate behaviors, use with lower-precision rendertextures without perceived color loss,
//and setting per-object dithering by changing the definition of useDither from 1 to 0 when needed.


technique PSXDither
{
	pass ps1
	{
		VertexShader = PostProcessVS;
		PixelShader = DitherCrunch;
	}
}
