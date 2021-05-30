/////////////////////////////////////////////////////////
// Delirium.fx by SirCobra
// Version 0.1
// You can find descriptions and my other shaders here: https://github.com/LordKobra/CobraFX
// --------Description---------
// Cast yourself into delirium.
/////////////////////////////////////////////////////////

//
// UI
//

uniform uint DeliriumIntensity <
    ui_type = "drag";
ui_min = 1; ui_max = 100;
ui_step = 1;
ui_tooltip = "Delirium Intensity.";
> = 1;


#include "Reshade.fxh"
#ifndef M_PI
#define M_PI 3.1415927
#endif

uniform float timer < source = "timer"; > ;

namespace Delirium {

    //
    // TEXTURE + SAMPLER
    //

    // nothing

    //
    // CODE
    //

    void delirium(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
    {
        //distortion
        // -(x-0.5)*(x-0.5)+0.25
        float offset = sin(timer/500+texcoord.x*M_PI*4); // wave
        offset = offset*((-(texcoord.y-0.5))*(texcoord.y-0.5)+0.25)/6; // strength
        float offset2 = sin((timer+500)/750+texcoord.x*M_PI*4); // wave
        offset2 = offset2*((-(texcoord.y-0.5))*(texcoord.y-0.5)+0.25)/4; // strength
        float2 new_point = float2(texcoord.x, saturate(texcoord.y+offset));
        float2 new_point_fade = float2(texcoord.x, saturate(texcoord.y+offset2)); 
        fragment = tex2D(ReShade::BackBuffer, new_point);
        float4 fragment_2 = tex2D(ReShade::BackBuffer, new_point_fade);
        if(fragment_2.r+fragment_2.g+fragment_2.b < fragment.r+fragment.g+fragment.b)
        {
            fragment = 0.85*fragment+0.15*fragment_2;
        }

        //eyes;
        float eye_offset = 1-saturate(sin(timer/555) +sin(0.25*timer/555)-0.65);
        fragment *= eye_offset;
    }
    technique Delirium
    {
        pass Delirium { VertexShader = PostProcessVS; PixelShader = delirium; }
    }
}
