////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_Ambient_Remove 0.2.0
//
// This shader is free, if you paid for it, you have been ripped and should ask for a refund.
//
// This shader is developed by AlucardDH (Damien Hembert)
//
// Get more here : https://alucarddh.github.io
// Join my Discord server for news, request, bug reports or help : https://discord.gg/V9HgyBRgMW
//
// License: GNU GPL-2.0
//
////////////////////////////////////////////////////////////////////////////////////////////////
#include "ReShade.fxh"

// CONSTANTS ///////////////////////////////////////////////////////////////

#define DEBUG_OFF 0
#define DEBUG_COLOR 1

#define BUFFER_SIZE int2(BUFFER_WIDTH,BUFFER_HEIGHT)


// MACROS /////////////////////////////////////////////////////////////////
// Don't touch this
#define getColor(c) tex2Dlod(ReShade::BackBuffer,float4((c).xy,0,0))
#define getColorSamplerLod(s,c,l) tex2Dlod(s,float4((c).xy,0,l))
#define getColorSampler(s,c) tex2Dlod(s,float4((c).xy,0,0))
#define maxOf3(a) max(max(a.x,a.y),a.z)
#define minOf3(a) min(min(a.x,a.y),a.z)
#define avgOf3(a) (((a).x+(a).y+(a).z)/3.0)
#define getBrightness(color) maxOf3((color))
#define getPureness(color) (maxOf3((color))-minOf3((color)))
#define RANDOM_RANGE 1024
#define CENTER float2(0.5,0.5)
//////////////////////////////////////////////////////////////////////////////

namespace DH_Ambient_Remove {

// Textures  
    
    texture ambientTex { Width = 1; Height = 1; Format = RGBA16F; };
    sampler ambientSampler { Texture = ambientTex; };   

    texture previousAmbientTex { Width = 1; Height = 1; Format = RGBA16F; };
    sampler previousAmbientSampler { Texture = previousAmbientTex; };    

// Internal Uniforms
    uniform int framecount < source = "framecount"; >;
    uniform int random < source = "random"; min = 0; max = RANDOM_RANGE; >;

// Parameters

/// DEBUG
    uniform int iDebug <
        ui_category = "Debug";
        ui_type = "combo";
        ui_label = "Display";
        ui_items = "Output\0Ambient Color\0";
        ui_tooltip = "Debug the intermediate steps of the shader";
    > = 0;
    
/// REMOVE
    uniform bool bRemoveAmbientAuto <
        ui_category = "Remove ambient light";
        ui_label = "Auto ambient color";
    > = true;

    uniform float3 cSourceAmbientLightColor <
        ui_type = "color";
        ui_category = "Remove ambient light";
        ui_label = "Source Ambient light color";
    > = float3(31.0,44.0,42.0)/255.0;
    
    uniform float fSourceAmbientIntensity <
        ui_type = "slider";
        ui_category = "Remove ambient light";
        ui_label = "Strength";
        ui_min = 0; ui_max = 1.0;
        ui_step = 0.001;
    > = 1.0;
    
    
    uniform bool bRemoveAmbientPreserveBrightness <
        ui_category = "Remove ambient light";
        ui_label = "Preserve brighthness";
    > = false;
    
/// ADD
    uniform bool bAddAmbient <
        ui_category = "Add ambient light";
        ui_label = "Add Ambient light";
    > = false;

    uniform float3 cTargetAmbientLightColor <
        ui_type = "color";
        ui_category = "Add ambient light";
        ui_label = "Target Ambient light color";
    > = float3(13.0,13.0,13.0)/255.0;

/// PROTECT
    
    uniform bool bIgnoreSky <
        ui_category = "Sky";
        ui_label = "Ignore sky";
    > = false;

    uniform float fSkyDepth <
        ui_type = "slider";
        ui_category = "Sky";
        ui_label = "Sky Depth";
        ui_min = 0.0; ui_max = 1.0;
        ui_step = 0.001;
        ui_tooltip = "Define where the sky starts to prevent if to be affected by the shader";
    > = 0.999;
    

// FUCNTIONS ////////////////////////////////////////////////////////////////////////

    float safePow(float value, float power) {
        return pow(abs(value),power);
    }

// Colors
    float3 RGBtoHSV(float3 c) {
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    
        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return float3(float(abs(q.z + (q.w - q.y) / (6.0 * d + e))), d / (q.x + e), q.x);
    }
    
    float3 HSVtoRGB(float3 c) {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    float frameRand() {
        return float(random)/RANDOM_RANGE;
    }

// PS ///////////////////////////////////////////////////////////////////////////////
    void PS_SavePreviousPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outAmbient : SV_Target0) {
        outAmbient = getColorSampler(ambientSampler,CENTER);
    }
    
    void PS_AmbientPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outAmbient : SV_Target0) {
        if(!bRemoveAmbientAuto) discard;

        float3 previous = getColorSampler(previousAmbientSampler,CENTER).rgb;
        float3 result = previous;
        float b = getBrightness(result);
        bool first = false;
        if(b==0) {
            result = 1.0;
            first = true;
        }
        if(framecount%60==0) {
            result = 1.0;
        }
        
        float bestB = b;
        
        
        
        float2 currentCoords = 0;
        float2 bestCoords = CENTER;
        float2 rand = frameRand()-0.5;
        
        float2 size = BUFFER_SIZE;
        float stepSize = BUFFER_WIDTH/16.0;
        float2 numSteps = size/(stepSize+1);
        
            
        //float2 rand = randomCouple(currentCoords);
        for(int it=0;it<=4 && stepSize>=1;it++) {
            float2 stepDim = stepSize/BUFFER_SIZE;
        
            for(currentCoords.x=bestCoords.x-stepDim.x*(numSteps.x/2);currentCoords.x<=bestCoords.x+stepDim.x*(numSteps.x/2);currentCoords.x+=stepDim.x) {
                for(currentCoords.y=bestCoords.y-stepDim.y*(numSteps.y/2);currentCoords.y<=bestCoords.y+stepDim.y*(numSteps.y/2);currentCoords.y+=stepDim.y) {
                    float3 color = getColor(currentCoords+rand*stepDim).rgb;
                    b = getBrightness(color);
                    if(b>0.1 && b<bestB) {
                        result = min(result,color);
                        bestB = b;
                    }
                }
            }
            size = stepSize;
            numSteps = 8;
            stepSize = size.x/8;
        }
        
        float opacity = b==1 ? 0 : (0.01+getPureness(result))*0.5;
        outAmbient = float4(result,first ? 1 : opacity);
        
    }
    
    float3 getRemovedAmbiantColor() {
        if(bRemoveAmbientAuto) {
            float3 color = getColorSampler(ambientSampler,float2(0.5,0.5)).rgb;
            color += getBrightness(color);
            return color;
        } else {
            return cSourceAmbientLightColor;
        }
    }
    
    float3 filterAmbiantLight(float3 sourceColor) {
        float3 color = sourceColor;
        float3 colorHSV = RGBtoHSV(color);
        float3 ral = getRemovedAmbiantColor();
        float3 removedTint = ral - minOf3(ral); 
        float3 sourceTint = color - minOf3(color);
        
        float hueDist = maxOf3(abs(removedTint-sourceTint));
        
        float removal = saturate(1.0-hueDist*saturate(colorHSV.y+colorHSV.z));
     color -= removedTint*removal;
        color = saturate(color);
        
        if(bRemoveAmbientPreserveBrightness) {
            float sB = getBrightness(sourceColor);
            float nB = getBrightness(color);
            
            color += sB-nB;
        }
        
        color = lerp(sourceColor,color,fSourceAmbientIntensity);
        
        if(bAddAmbient) {
            float b = getBrightness(color);
            color = saturate(color+pow(1.0-b,4.0)*cTargetAmbientLightColor);
        }
        
        return color;
    }
    

    void PS_Filter(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outColor : SV_Target) {
        if(iDebug==DEBUG_OFF) {
            float depth = ReShade::GetLinearizedDepth(coords);
            float4 color = getColor(coords);

            bool filter = true;
            if(bIgnoreSky) {
                float depth = ReShade::GetLinearizedDepth(coords);
                filter = depth<=fSkyDepth;
            }

            if(filter) {
                color.rgb = filterAmbiantLight(color.rgb);
            }
            
            outColor = color;
        } else if(iDebug==DEBUG_COLOR) {
            outColor = float4(getRemovedAmbiantColor(),1.0);
        } else {
            outColor = float4(0.0,0.0,0.0,1.0);
        }        
    }

// TEHCNIQUES 
    
    technique DH_Ambient_Remove <
        ui_label = "DH_Ambient_Remove 0.2.0";
        ui_tooltip = 
            "_____________ DH_Ambient_Remove _____________\n"
            "\n"
            "         version 0.2.0 by AlucardDH\n"
            "\n"
            "_____________________________________________";
    > {
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_SavePreviousPass;
            RenderTarget = previousAmbientTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_AmbientPass;
            RenderTarget = ambientTex;
            
            ClearRenderTargets = false;
                        
            BlendEnable = true;
            BlendOp = ADD;
            SrcBlend = SRCALPHA;
            SrcBlendAlpha = ONE;
            DestBlend = INVSRCALPHA;
            DestBlendAlpha = ONE;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_Filter;
        }
    }
}