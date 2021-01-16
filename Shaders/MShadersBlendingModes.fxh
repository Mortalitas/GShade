////////////////////////////////////////////////////
// Photoshop Blending & Functions                 //
// File written by TreyM                          //
// <> from various internet sources               //
////////////////////////////////////////////////////

// OVERLAY FLOAT /////////////////////////////////
float BlendOverlay(float base, float blend)
{
    return lerp((2.0 * base * blend),
                (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)),
                step(blend, 0.5));
}
// OVERLAY FLOAT3 ////////////////////////////////
float3 BlendOverlay(float3 base, float3 blend)
{
    return lerp((2.0 * base * blend),
                (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)),
                step(blend, 0.5));
}



// SOFT LIGHT FLOAT //////////////////////////////
float BlendSoftLight(float base, float blend)
{
    return lerp((2.0 * base * blend + base * base * (1.0 - 2.0 * blend)),
                (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend)),
                 step(blend, 0.5));
}
// SOFT LIGHT FLOAT3 /////////////////////////////
float3 BlendSoftLight(float3 base, float3 blend)
{
    return lerp((2.0 * base * blend + base * base * (1.0 - 2.0 * blend)),
                (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend)),
                 step(blend, 0.5));
}



// HARD LIGHT FLOAT //////////////////////////////
float BlendHardLight(float base, float blend)
{
    return BlendOverlay(blend, base);
}
// HARD LIGHT FLOAT3 /////////////////////////////
float3 BlendHardLight(float3 base, float3 blend)
{
    return BlendOverlay(blend, base);
}



// ADD FLOAT /////////////////////////////////////
float BlendAdd(float base, float blend)
{
    return min(base + blend, 1.0);
}
// ADD FLOAT3 ////////////////////////////////////
float3 BlendAdd(float3 base, float3 blend)
{
    return min(base + blend, 1.0);
}



// SUBTRACT FLOAT ////////////////////////////////
float BlendSubtract(float base, float blend)
{
    return max(base + blend - 1.0, 0.0);
}
// SUBTRACT FLOAT3 ///////////////////////////////
float3 BlendSubtract(float3 base, float3 blend)
{
    return max(base + blend - 1.0, 0.0);
}



// LINEAR DODGE FLOAT ////////////////////////////
float BlendLinearDodge(float base, float blend)
{
    return BlendAdd(base, blend);
}
// LINEAR DODGE FLOAT3 ///////////////////////////
float3 BlendLinearDodge(float3 base, float3 blend)
{
    return BlendAdd(base, blend);
}



// LINEAR BURN FLOAT /////////////////////////////
float BlendLinearBurn(float base, float blend)
{
    return BlendSubtract(base, blend);
}
// LINEAR BURN FLOAT3 ////////////////////////////
float3 BlendLinearBurn(float3 base, float3 blend)
{
    return BlendSubtract(base, blend);
}



// LIGHTEN FLOAT /////////////////////////////////
float BlendLighten(float base, float blend)
{
    return max(blend, base);
}
// LIGHTEN FLOAT3 ////////////////////////////////
float3 BlendLighten(float3 base, float3 blend)
{
    return max(blend, base);
}



// DARKEN FLOAT //////////////////////////////////
float BlendDarken(float base, float blend)
{
    return min(blend, base);
}
// DARKEN FLOAT3 /////////////////////////////////
float3 BlendDarken(float3 base, float3 blend)
{
    return min(blend, base);
}



// LINEAR LIGHT FLOAT ////////////////////////////
float BlendLinearLight(float base, float blend)
{
    return lerp(BlendLinearBurn(base, (2.0 *  blend)),
                BlendLinearDodge(base, (2.0 * (blend - 0.5))),
                step(blend, 0.5));
}
// LINEAR LIGHT FLOAT3 ///////////////////////////
float3 BlendLinearLight(float3 base, float3 blend)
{
    return lerp(BlendLinearBurn(base, (2.0 *  blend)),
                BlendLinearDodge(base, (2.0 * (blend - 0.5))),
                step(blend, 0.5));
}



// SCREEN FLOAT //////////////////////////////////
float BlendScreen(float base, float blend)
{
    return 1.0 - ((1.0 - base) * (1.0 - blend));
}
// SCREEN FLOAT3 /////////////////////////////////
float3 BlendScreen(float3 base, float3 blend)
{
    return 1.0 - ((1.0 - base) * (1.0 - blend));
}



// SCREEN FLOAT HDR //////////////////////////////
float BlendScreenHDR(float base, float blend)
{
    return base + (blend / (1 + base));
}
// SCREEN FLOAT3 HDR /////////////////////////////
float3 BlendScreenHDR(float3 base, float3 blend)
{
    return base + (blend / (1 + base));
}



// COLOR DODGE FLOAT /////////////////////////////
float BlendColorDodge(float base, float blend)
{
    return lerp(blend, min(base / (1.0 - blend), 1.0), (blend == 1.0));
}
// COLOR DODGE FLOAT3 ////////////////////////////
float3 BlendColorDodge(float3 base, float3 blend)
{
    return lerp(blend, min(base / (1.0 - blend), 1.0), (blend == 1.0));
}



// COLOR BURN FLOAT //////////////////////////////
float BlendColorBurn(float base, float blend)
{
    return lerp(blend, max((1.0 - ((1.0 - base) / blend)), 0.0), (blend == 0.0));
}
// COLOR BURN FLOAT3 /////////////////////////////
float3 BlendColorBurn(float3 base, float3 blend)
{
    return lerp(blend, max((1.0 - ((1.0 - base) / blend)), 0.0), (blend == 0.0));
}



// VIVID LIGHT FLOAT /////////////////////////////
float BlendVividLight(float base, float blend)
{
    return lerp(BlendColorBurn (base, (2.0 *  blend)),
                BlendColorDodge(base, (2.0 * (blend - 0.5))),
                step(blend, 0.5));
}
// VIVID LIGHT FLOAT3 ////////////////////////////
float3 BlendVividLight(float3 base, float3 blend)
{
    return lerp(BlendColorBurn (base, (2.0 *  blend)),
                BlendColorDodge(base, (2.0 * (blend - 0.5))),
                step(blend, 0.5));
}



// PIN LIGHT FLOAT ///////////////////////////////
float BlendPinLight(float base, float blend)
{
    return lerp(BlendDarken (base, (2.0 *  blend)),
                BlendLighten(base, (2.0 * (blend - 0.5))),
                step(blend, 0.5));
}
// PIN LIGHT FLOAT3 //////////////////////////////
float3 BlendPinLight(float3 base, float3 blend)
{
    return lerp(BlendDarken (base, (2.0 *  blend)),
                BlendLighten(base, (2.0 * (blend - 0.5))),
                step(blend, 0.5));
}



// HARD MIX FLOAT ////////////////////////////////
float BlendHardMix(float base, float blend)
{
    return lerp(0.0, 1.0, step(BlendVividLight(base, blend), 0.5));
}
// HARD MIX FLOAT3 ///////////////////////////////
float3 BlendHardMix(float3 base, float3 blend)
{
    return lerp(0.0, 1.0, step(BlendVividLight(base, blend), 0.5));
}



// REFLECT FLOAT /////////////////////////////////
float BlendReflect(float base, float blend)
{
    return lerp(blend, min(base * base / (1.0 - blend), 1.0), (blend == 1.0));
}
// REFLECT FLOAT3 ////////////////////////////////
float3 BlendReflect(float3 base, float3 blend)
{
    return lerp(blend, min(base * base / (1.0 - blend), 1.0), (blend == 1.0));
}



// AVERAGE FLOAT /////////////////////////////////
float BlendAverage(float base, float blend)
{
    return (base + blend) / 2.0;
}
// AVERAGE FLOAT3 ////////////////////////////////
float3 BlendAverage(float3 base, float3 blend)
{
    return (base + blend) / 2.0;
}



// DIFFERENCE FLOAT //////////////////////////////
float BlendDifference(float base, float blend)
{
    return abs(base - blend);
}
// DIFFERENCE FLOAT3 /////////////////////////////
float3 BlendDifference(float3 base, float3 blend)
{
    return abs(base - blend);
}



// NEGATION FLOAT ////////////////////////////////
float BlendNegation(float base, float blend)
{
    return 1.0 - abs(1.0 - base - blend);
}
// NEGATION FLOAT3 ///////////////////////////////
float3 BlendNegation(float3 base, float3 blend)
{
    return 1.0 - abs(1.0 - base - blend);
}



// EXCLUSION FLOAT ///////////////////////////////
float BlendExclusion(float base, float blend)
{
    return base + blend - 2.0 * base * blend;
}
// EXCLUSION FLOAT3 //////////////////////////////
float3 BlendExclusion(float3 base, float3 blend)
{
    return base + blend - 2.0 * base * blend;
}



// GLOW FLOAT ////////////////////////////////////
float BlendGlow(float base, float blend)
{
    return BlendReflect(blend, base);
}
// GLOW FLOAT3 ///////////////////////////////////
float3 BlendGlow(float3 base, float3 blend)
{
    return BlendReflect(blend, base);
}



// PHOENIX FLOAT /////////////////////////////////
float BlendPhoenix(float base, float blend)
{
    return min(base, blend) - max(base, blend) + 1.0;
}
// PHOENIX FLOAT3 ////////////////////////////////
float3 BlendPhoenix(float3 base, float3 blend)
{
    return min(base, blend) - max(base, blend) + 1.0;
}
