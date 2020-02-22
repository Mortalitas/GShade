/*------------------.
| :: Description :: |
'-------------------/

    Blending Header (version 0.1)

    Authors: originalnicodr, prod80, Uchu Suzume, Marot Satil

    About:
    Provides a variety of blending methods for you to use as you wish. Just include this header.

    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
    
    Version 0.1 by Marot Satil & Uchu Suzume
    * Added and improved upon multiple blending modes thanks to the work of Uchu Suzume, prod80, and originalnicodr.
*/

// -------------------------------------
// Blending Modes
// -------------------------------------

// Screen Blending Mode
float3 Screen(float3 a, float3 b)
{
    return 1.0 - (1.0 - a) * (1.0 - b);
}

// Multiply Blending Mode
float3 Multiply(float3 a, float3 b)
{
    return a * b;
}

// Darken Blending Mode
float3 Darken(float3 a, float3 b)
{
    return min(a,b);
}

// Lighten Blending Mode
float3 Lighten(float3 a, float3 b)
{
    return max(a,b);
}

// Color Dodge Blending Mode
float3 ColorDodge(float3 a, float3 b)
{
    if (b.r < 1 && b.g < 1 && b.b < 1)
        return min(1.0,a/(1.0-b));
    else
        return 1.0;
}

// Color Burn Blending Mode
float3 ColorBurn(float3 a, float3 b)
{
    if (b.r > 0 && b.g > 0 && b.b > 0)
        return 1.0-min(1.0,(1.0-a)/b);
    else
        return 0.0;
}

// Hard Light Blending Mode
float3 HardLight(float3 a, float3 b)
{
    return lerp(2 * a * b, 1.0 - 2 * (1.0 - a) * (1.0 - b), step(0.5, a));
}

float3 Aux(float3 a)
{
    if (a.r<=0.25 && a.g<=0.25 && a.b<=0.25)
        return ((16.0*a-12.0)*a+4)*a;
    else
        return sqrt(a);
}

// Soft Light Blending Mode
float3 SoftLight(float3 a, float3 b)
{
    if (b.r <= 0.5 && b.g <=0.5 && b.b <= 0.5)
        return clamp(a-(1.0-2*b)*a*(1-a),0,1);
    else
        return clamp(a+(2*b-1.0)*(Aux(a)-a),0,1);
}

// Difference Blending Mode
float3 Difference(float3 a, float3 b)
{
    return a-b;
}

// Exclusion Blending Mode
float3 Exclusion(float3 a, float3 b)
{
    return a+b-2*a*b;
}

// Overlay Blending Mode
float3 Overlay(float3 a, float3 b)
{
    return lerp(2 * a * b, 1.0 - 2 * (1.0 - a) * (1.0 - b), step(0.5, a));
}

float Lum(float3 c)
{
    return (0.3*c.r+0.59*c.g+0.11*c.b);
}

float min3 (float a, float b, float c)
{
    return min(a,(min(b,c)));
}

float max3 (float a, float b, float c)
{
    return max(a,(max(b,c)));
}

float Sat(float3 c)
{
    return max3(c.r,c.g,c.b)-min3(c.r,c.g,c.b);
}

float3 ClipColor(float3 c)
{
    const float l = Lum(c);
    const float n = min3(c.r,c.g,c.b);
    const float x = max3(c.r,c.g,c.b);
    float cr = c.r;
    float cg = c.g;
    float cb = c.b;
    if (n<0)
    {
        cr = l+(((cr-l)*l)/(l-n));
        cg = l+(((cg-l)*l)/(l-n));
        cb = l+(((cb-l)*l)/(l-n));
    }
    if (x>1)
    {
        cr = l+(((cr-l)*(1-l))/(x-l));
        cg = l+(((cg-l)*(1-l))/(x-l));
        cb = l+(((cb-l)*(1-l))/(x-l));
    }
    return float3(cr,cg,cb);
}

float3 SetLum (float3 c, float l){
    const float d = l-Lum(c);
    return float3(c.r+d,c.g+d,c.b+d);
}

float3 SetSat(float3 c, float s){
    float cr = c.r;
    float cg = c.g;
    float cb = c.b;
    if (cr==max3(cr,cg,cb) && cb==min3(cr,cg,cb))
    {
        //caso r->max g->mid b->min
        if (cr>cb)
        {
            cg = (((cg-cb)*s)/(cr-cb));
            cr = s;
        }
        else
        {
            cg = 0.0;
            cr = 0.0;
        }
        cb = 0.0;
    }
    else
    {
        if (cr==max3(cr,cg,cb) && cg==min3(cr,cg,cb))
        {
            //caso r->max b->mid g->min
            if (cr>cg)
            {
                cb = (((cb-cg)*s)/(cr-cg));
                cr = s;
            }
            else
            {
                cb = 0.0;
                cr = 0.0;
            }
            cg = 0.0;
        }
        else
        {
            if (cg==max3(cr,cg,cb) && cb==min3(cr,cg,cb))
            {
                //caso g->max r->mid b->min
                if (cg>cb)
                {
                    cr = (((cr-cb)*s)/(cg-cb));
                    cg = s;
                }
                else
                {
                    cr = 0.0;
                    cg = 0.0;
                }
                cb = 0.0;
            }
            else
            {
                if (cg==max3(cr,cg,cb) && cr==min3(cr,cg,cb))
                {
                    //caso g->max b->mid r->min
                    if (cg>cr)
                    {
                        cb=(((cb-cr)*s)/(cg-cr));
                        cg=s;
                    }
                    else
                    {
                        cb = 0.0;
                        cg = 0.0;
                    }
                    cr = 0.0;
                }
                else
                {
                    if (cb==max3(cr,cg,cb) && cg==min3(cr,cg,cb))
                    {
                        //caso b->max r->mid g->min
                        if (cb>cg)
                        {
                            cr = (((cr-cg)*s)/(cb-cg));
                            cb = s;
                        }
                        else
                        {
                            cr = 0.0;
                            cb = 0.0;
                        }
                        cg = 0.0;
                    }
                    else
                    {
                        if (cb==max3(cr,cg,cb) && cr==min3(cr,cg,cb))
                        {
                            //caso b->max g->mid r->min
                            if (cb>cr)
                            {
                                cg = (((cg-cr)*s)/(cb-cr));
                                cb = s;
                            }
                            else
                            {
                                cg = 0.0;
                                cb = 0.0;
                            }
                            cr = 0.0;
                        }
                    }
                }
            }
        }
    }
    return float3(cr,cg,cb);
}

// Hue Blending Mode
float3 Hue(float3 a, float3 b)
{
    return SetLum(SetSat(b,Sat(a)),Lum(a));
}

// Saturation Blending Mode
float3 Saturation(float3 a, float3 b)
{
    return SetLum(SetSat(a,Sat(b)),Lum(a));
}

// Color Blending Mode
float3 ColorB(float3 a, float3 b)
{
    return SetLum(b,Lum(a));
}

// Luminousity Blending Mode
float3 Luminosity(float3 a, float3 b)
{
    return SetLum(a,Lum(b));
}

// Linear Burn Blending Mode
float3 LinearBurn(float3 a, float3 b)
{
    return max(a+b-1.0f, 0.0f);
}

// Linear Dodge Blending Mode
float3 LinearDodge(float3 c, float3 b)
{
    return min(c+b, 1.0f);
}

// Vivid Light Blending Mode
float3 VividLight(float3 a, float3 b)
{
    return lerp(2 * a * b, b / (2 * (1.01 - a)), step(0.50, a));
}

// Linear Light Blending Mode
float3 LinearLight(float3 a, float3 b)
{
    if (b.r<0.5f||b.g<0.5f||b.b<0.5f)
        return LinearBurn(a, (2.0f*b));
    else
        return LinearDodge(a, (2.0f*(b-0.5f)));
}

// Pin Light Blending Mode
float3 PinLight(float3 a, float3 b)
{
    if (b.r<0.5f||b.g<0.5f||b.b<0.5f)
        return Darken(a, (2.0f*b));
    else
        return Lighten(a, (2.0f*(b-0.5f)));
}

// Hard Mix Blending Mode
float3 HardMix(float3 a, float3 b)
{
    const float3 vl = VividLight(a,b);
    if (vl.r<0.5f||vl.g<0.5f||vl.b<0.5f)
        return 0.0;
    else
        return 1.0;
}

// Reflect Blending Mode
float3 Reflect(float3 a, float3 b)
{
    if (b.r>=0.999999f||b.g>=0.999999f||b.b>=0.999999f)
        return b;
    else
        return saturate(a*a/(1.0f-b));
}

// Glow Blending Mode
float3 Glow(float3 a, float3 b)
{
    return Reflect(b, a);
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