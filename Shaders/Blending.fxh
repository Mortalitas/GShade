/*------------------.
| :: Description :: |
'-------------------/

    Blending Header (version 0.4)

    Authors: originalnicodr, prod80, uchu suzume, Marot Satil

    About:
    Provides a variety of blending methods for you to use as you wish. Just include this header.

    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
    
    Version 0.1 by Marot Satil & uchu suzume
    * Added and improved upon multiple blending modes thanks to the work of uchu suzume, prod80, and originalnicodr.

    Version 0.2 by uchu suzume & Marot Satil
    * Added Addition, Subtract, Divide blending modes and improved code readability.

    Version 0.3 by uchu suzume & Marot Satil
    * Sorted blending modes in a more logical fashion, grouping by type.

	Version 0.4 by uchu suzume
    * Corrected Color Dodge blending behavior.

.------------------.
| :: How To Use :: |
'------------------/

	Blending two variables using this header in your own shaders is very straightforward.
	Very basic example code using the "Darken" blending mode follows:

	#include "Blending.fxh"

	float4 inColor = tex2D(ReShade::BackBuffer, texCoord);
	float4 outColor = inColor * 0.5;
	
	outColor.rgb = Darken(outColor.rgb, inColor.rgb);

	outColor = lerp(inColor.rgb, outColor.rgb, inColor.a);
*/

// -------------------------------------
// Helper Functions
// -------------------------------------

float3 Aux(float3 a)
{
    if (a.r <= 0.25 && a.g <= 0.25 && a.b <= 0.25)
        return ((16.0 * a - 12.0) * a + 4) * a;
    else
        return sqrt(a);
}

float Lum(float3 a)
{
    return (0.3 * a.r + 0.59 * a.g + 0.11 * a.b);
}

float3 SetLum (float3 a, float b){
    const float c = b - Lum(a);
    return float3(a.r + c, a.g + c, a.b + c);
}

float min3 (float a, float b, float c)
{
    return min(a, (min(b, c)));
}

float max3 (float a, float b, float c)
{
    return max(a, max(b, c));
}

float3 SetSat(float3 a, float b){
    float ar = a.r;
    float ag = a.g;
    float ab = a.b;
    if (ar == max3(ar, ag, ab) && ab == min3(ar, ag, ab))
    {
        //caso r->max g->mid b->min
        if (ar > ab)
        {
            ag = (((ag - ab) * b) / (ar - ab));
            ar = b;
        }
        else
        {
            ag = 0.0;
            ar = 0.0;
        }
        ab = 0.0;
    }
    else
    {
        if (ar == max3(ar, ag, ab) && ag == min3(ar, ag, ab))
        {
            //caso r->max b->mid g->min
            if (ar > ag)
            {
                ab = (((ab - ag) * b) / (ar - ag));
                ar = b;
            }
            else
            {
                ab = 0.0;
                ar = 0.0;
            }
            ag = 0.0;
        }
        else
        {
            if (ag == max3(ar, ag, ab) && ab == min3(ar, ag, ab))
            {
                //caso g->max r->mid b->min
                if (ag > ab)
                {
                    ar = (((ar - ab) * b) / (ag - ab));
                    ag = b;
                }
                else
                {
                    ar = 0.0;
                    ag = 0.0;
                }
                ab = 0.0;
            }
            else
            {
                if (ag == max3(ar, ag, ab) && ar == min3(ar, ag, ab))
                {
                    //caso g->max b->mid r->min
                    if (ag > ar)
                    {
                        ab = (((ab - ar) * b) / (ag - ar));
                        ag = b;
                    }
                    else
                    {
                        ab = 0.0;
                        ag = 0.0;
                    }
                    ar = 0.0;
                }
                else
                {
                    if (ab == max3(ar, ag, ab) && ag == min3(ar, ag, ab))
                    {
                        //caso b->max r->mid g->min
                        if (ab > ag)
                        {
                            ar = (((ar - ag) * b) / (ab - ag));
                            ab = b;
                        }
                        else
                        {
                            ar = 0.0;
                            ab = 0.0;
                        }
                        ag = 0.0;
                    }
                    else
                    {
                        if (ab == max3(ar, ag, ab) && ar == min3(ar, ag, ab))
                        {
                            //caso b->max g->mid r->min
                            if (ab > ar)
                            {
                                ag = (((ag - ar) * b) / (ab - ar));
                                ab = b;
                            }
                            else
                            {
                                ag = 0.0;
                                ab = 0.0;
                            }
                            ar = 0.0;
                        }
                    }
                }
            }
        }
    }
    return float3(ar, ag, ab);
}

float Sat(float3 a)
{
    return max3(a.r, a.g, a.b) - min3(a.r, a.g, a.b);
}

// -------------------------------------
// Blending Modes
// -------------------------------------

// Darken Blending Mode
float3 Darken(float3 a, float3 b)
{
    return min(a, b);
}

// Multiply Blending Mode
float3 Multiply(float3 a, float3 b)
{
    return a * b;
}

// Color Burn Blending Mode
float3 ColorBurn(float3 a, float3 b)
{
    if (b.r > 0 && b.g > 0 && b.b > 0)
        return 1.0 - min(1.0, (0.5 - a) / b);
    else
        return 0.0;
}

// Linear Burn Blending Mode
float3 LinearBurn(float3 a, float3 b)
{
    return max(a + b - 1.0f, 0.0f);
}

// Lighten Blending Mode
float3 Lighten(float3 a, float3 b)
{
    return max(a, b);
}

// Screen Blending Mode
float3 Screen(float3 a, float3 b)
{
    return 1.0 - (1.0 - a) * (1.0 - b);
}

// Color Dodge Blending Mode
float3 ColorDodge(float3 a, float3 b)
{
    if (b.r < 1 && b.g < 1 && b.b < 1)
        return min(1.0, a / (1.0 - b));
    else
        return 1.0;
}

// Linear Dodge Blending Mode
float3 LinearDodge(float3 a, float3 b)
{
    return min(a + b, 1.0f);
}

// Addition
float3 Addition(float3 a, float3 b)
{
    return min((a + b), 1);
}

// Reflect Blending Mode
float3 Reflect(float3 a, float3 b)
{
    if (b.r >= 0.999999 || b.g >= 0.999999 || b.b >= 0.999999)
        return b;
    else
        return saturate(a * a / (1.0f - b));
}

// Glow Blending Mode
float3 Glow(float3 a, float3 b)
{
    return Reflect(b, a);
}

// Overlay Blending Mode
float3 Overlay(float3 a, float3 b)
{
    return lerp(2 * a * b, 1.0 - 2 * (1.0 - a) * (1.0 - b), step(0.5, a));
}

// Soft Light Blending Mode
float3 SoftLight(float3 a, float3 b)
{
    if (b.r <= 0.5 && b.g <= 0.5 && b.b <= 0.5)
        return clamp(a - (1.0 - 2 * b) * a * (1 - a), 0,1);
    else
        return clamp(a + (2 * b - 1.0) * (Aux(a) - a), 0, 1);
}

// Hard Light Blending Mode
float3 HardLight(float3 a, float3 b)
{
    return lerp(2 * a * b, 1.0 - 2 * (1.0 - b) * (1.0 - a), step(0.5, b));
}

// Vivid Light Blending Mode
float3 VividLight(float3 a, float3 b)
{
    return lerp(2 * a * b, b / (2 * (1.01 - a)), step(0.50, a));
}

// Linear Light Blending Mode
float3 LinearLight(float3 a, float3 b)
{
    if (b.r < 0.5 || b.g < 0.5 || b.b < 0.5)
        return LinearBurn(a, (2.0 * b));
    else
        return LinearDodge(a, (2.0 * (b - 0.5)));
}

// Pin Light Blending Mode
float3 PinLight(float3 a, float3 b)
{
    if (b.r < 0.5 || b.g < 0.5 || b.b < 0.5)
        return Darken(a, (2.0 * b));
    else
        return Lighten(a, (2.0 * (b - 0.5)));
}

// Hard Mix Blending Mode
float3 HardMix(float3 a, float3 b)
{
    const float3 vl = VividLight(a, b);
    if (vl.r < 0.5 || vl.g < 0.5 || vl.b < 0.5)
        return 0.0;
    else
        return 1.0;
}

// Difference Blending Mode
float3 Difference(float3 a, float3 b)
{
    return max(a - b, b - a);
}

// Exclusion Blending Mode
float3 Exclusion(float3 a, float3 b)
{
    return a + b - 2 * a * b;
}

// Subtract
float3 Subtract(float3 a, float3 b)
{
    return max((a - b), 0);
}

// Divide
float3 Divide(float3 a, float3 b)
{
    return (a / (b + 0.01));
}

// Grain Merge
float3 GrainMerge(float3 a, float3 b)
{
    return saturate(b + a - 0.5);
}

// Grain Extract
float3 GrainExtract(float3 a, float3 b)
{
    return saturate(a - b + 0.5);
}

// Hue Blending Mode
float3 Hue(float3 a, float3 b)
{
    return SetLum(SetSat(b, Sat(a)), Lum(a));
}

// Saturation Blending Mode
float3 Saturation(float3 a, float3 b)
{
    return SetLum(SetSat(a, Sat(b)), Lum(a));
}

// Color Blending Mode
float3 ColorB(float3 a, float3 b)
{
    return SetLum(b, Lum(a));
}

// Luminousity Blending Mode
float3 Luminosity(float3 a, float3 b)
{
    return SetLum(a, Lum(b));
}
