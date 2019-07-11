#include "ReShade.fxh"
#include "Macros.fxh"

UI_FLOAT_S(SHARPNESS, "Sharpness", "Adjust sharpness (0 = default, 1 = max)", 0.0, 1.0, 0.0)

// hack to make ffx_a.h compile, not actually used
uint f32tof16(in float value) { return 0; }
float f16tof32(in uint value) { return 0; }

float3 CasLoad(float2 pos)  {
    return tex2Dfetch(ReShade::BackBuffer, int4(pos, 0, 0)).rgb;
}

void CasInput(inout float r, inout float g, inout float b) {}

#define A_GPU 1
#define A_HLSL 1
#include "ffx_a.h"
#include "ffx_cas.h"

float4 MainPS(float4 pos: SV_Position, float2 tex: TexCoord): SV_Target {
    float4 const0;
    float4 const1;
    CasSetup(const0, const1, SHARPNESS, BUFFER_WIDTH, BUFFER_HEIGHT, BUFFER_WIDTH, BUFFER_HEIGHT);

    float4 color = float4(0.0, 0.0, 0.0, 0.0);
    CasFilter(color.r, color.g, color.b, pos.xy, const0, const1, true);

    return color;
}

technique FidelityFX_CAS {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = MainPS;
    }
}