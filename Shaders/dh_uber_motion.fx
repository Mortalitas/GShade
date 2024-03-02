////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_UBER_RT
//
// This shader is free, if you paid for it, you have been ripped and should ask for a refund.
//
// This shader is developed by AlucardDH (Damien Hembert)
//
// Get more here : https://github.com/AlucardDH/dh-reshade-shaders
//
////////////////////////////////////////////////////////////////////////////////////////////////
#include "ReShade.fxh"


// MACROS /////////////////////////////////////////////////////////////////
// Don't touch this
#define getColor(c) tex2Dlod(ReShade::BackBuffer,float4(c,0,0))
#define getColorSamplerLod(s,c,l) tex2Dlod(s,float4(c.xy,0,l))
#define getColorSampler(s,c) tex2Dlod(s,float4(c.xy,0,0))
#define maxOf3(a) max(max(a.x,a.y),a.z)
//////////////////////////////////////////////////////////////////////////////

texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler sTexMotionVectorsSampler { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

namespace DH_UBER_MOTION {

// Textures

    // Common textures
    texture halfMotionTex { Width = BUFFER_WIDTH>>1; Height = BUFFER_HEIGHT>>1; Format = RG16F;};
    sampler halfMotionSampler { Texture = halfMotionTex; MipFilter = Point; MinFilter = Point; MagFilter = Point;};

    texture colorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler colorSampler { Texture = colorTex; MinLOD = 0.0f; MaxLOD = 5.0f;};

    texture previousColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler previousColorSampler { Texture = previousColorTex; MinLOD = 0.0f; MaxLOD = 5.0f;};

    texture previousDepthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8; };
    sampler previousDepthSampler { Texture = previousDepthTex; };

// Parameters

    uniform int iMotionRadius <
        ui_type = "slider";
        ui_category = "Motion Detection";
        ui_label = "Radius";
        ui_min = 1; ui_max = 8;
        ui_step = 1;
        ui_tooltip = "Define the max distance of motion detection.\n"
                    "Lower=better performance, less precise detection in fast motion\n"
                    "Higher=better motion detection, less performance\n"
                    "/!\\ HAS A BIG INPACT ON PERFORMANCES";
    > = 4;
    
    /*
    uniform float fTest <
        ui_type = "slider";
        ui_min = 0.0; ui_max = 10.0;
        ui_step = 0.001;
    > = 0.001;
    uniform bool bTest = true;
    uniform bool bTest2 = true;
    uniform bool bTest3 = true;
    */

// PS

    float3 getFirst(sampler sourceSampler, float2 coords) {
        return getColorSampler(sourceSampler,coords).rgb;
    }
    
    float3 getSecond(sampler sourceSampler, float2 coords) {
        return getColorSamplerLod(sourceSampler,(coords-ReShade::PixelSize*8),2.5).rgb;
    }
    
    float motionDistance(float2 refCoords, float3 refColor,float3 refAltColor,float refDepth, float2 currentCoords) {
        float2 pixelSize = ReShade::PixelSize;
        
        float currentDepth = getColorSampler(previousDepthSampler,currentCoords).x;
        float diffDepth = abs(refDepth-currentDepth);
        
        float3 currentColor = getFirst(previousColorSampler,currentCoords);
        float3 currentAltColor = getSecond(previousColorSampler,currentCoords);

        float3 diffColor = abs(currentColor-refColor);
        float3 diffAltColor = abs(currentAltColor-refAltColor);
        
        float dist = distance(refCoords,currentCoords);
        dist += maxOf3(diffColor);
        dist += maxOf3(diffAltColor);
      dist *= 0.01+diffDepth;
        
        return dist;     
    }
    
    void PS_MotionPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float2 outMotion : SV_Target0) {
    
        float2 refCoords = coords + 0.75*getColorSamplerLod(sTexMotionVectorsSampler,coords,2).xy;
        float2 pixelSize = ReShade::PixelSize;
        float3 refColor = getFirst(colorSampler,coords);
        float3 refAltColor = getSecond(colorSampler,coords);
        float refDepth = ReShade::GetLinearizedDepth(coords);

        int2 delta = 0;
        float deltaStep = 1;
        
        float2 currentCoords = refCoords;
        float dist = motionDistance(coords,refColor,refAltColor,refDepth,currentCoords);
                
        float bestDist = dist;
        
        float2 bestMotion = currentCoords;
        
        [loop]     
        for(int radius=1;radius<=iMotionRadius;radius++) {
            deltaStep = 4*radius;
            [loop]
            for(int dx=0;dx<=radius;dx++) {
                
                delta.x = dx;
                delta.y = radius-dx;
                
                currentCoords = refCoords+pixelSize*delta*deltaStep;
                dist = motionDistance(coords,refColor,refAltColor,refDepth,currentCoords);
                if(dist<bestDist) {
                    bestDist = dist;
                    bestMotion = currentCoords;
                }
                
                if(dx!=0) {
                    delta.x = -dx;
                    
                    currentCoords = refCoords+pixelSize*delta*deltaStep;
                    dist = motionDistance(coords,refColor,refAltColor,refDepth,currentCoords);
                    if(dist<bestDist) {
                        bestDist = dist;
                        bestMotion = currentCoords;
                    }
                }
                
                if(delta.y!=0) {
                    delta.x = dx;
                    delta.y = -(delta.y);
                    
                    currentCoords = refCoords+pixelSize*delta*deltaStep;
                    dist = motionDistance(coords,refColor,refAltColor,refDepth,currentCoords);
                    if(dist<bestDist) {
                        bestDist = dist;
                        bestMotion = currentCoords;
                    }
                }
                
                if(dx!=0) {
                    delta.x = -dx;
                    
                    currentCoords = refCoords+pixelSize*delta*deltaStep;
                    dist = motionDistance(coords,refColor,refAltColor,refDepth,currentCoords);
                    if(dist<bestDist) {
                        bestDist = dist;
                        bestMotion = currentCoords;
                    }
                }
            }
        }
        
        outMotion = bestMotion-coords;
    }
    
    void PS_InputPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0) {
        outColor = getColor(coords);
    }

    void PS_SavePass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0, out float outDepth : SV_Target1, out float2 outMotion : SV_Target2) {
        outColor = getColor(coords);
        outDepth = ReShade::GetLinearizedDepth(coords);
        outMotion = getColorSampler(halfMotionSampler,coords).xy;
    }


// TEHCNIQUES 
    
    technique DH_UBER_MOTION {
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_InputPass;
            RenderTarget = colorTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_MotionPass;
            RenderTarget = halfMotionTex;
        }
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_SavePass;
            RenderTarget = previousColorTex;
            RenderTarget1 = previousDepthTex;
            RenderTarget2 = texMotionVectors;
        }
    }
}