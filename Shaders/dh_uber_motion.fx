////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_UBER_MOTION 0.2.0
//
// This shader is free, if you paid for it, you have been ripped and should ask for a refund.
//
// This shader is developed by AlucardDH (Damien Hembert)
//
// Get more here : https://github.com/AlucardDH/dh-reshade-shaders
//
// License: GNU GPL-2.0
//
////////////////////////////////////////////////////////////////////////////////////////////////
#include "ReShade.fxh"


// MACROS /////////////////////////////////////////////////////////////////
// Don't touch this
#define getColor(c) tex2Dlod(ReShade::BackBuffer,float4(c,0,0))
#define getColorSamplerLod(s,c,l) tex2Dlod(s,float4((c).xy,0,l))
#define getColorSampler(s,c) tex2Dlod(s,float4((c).xy,0,0))
#define maxOf3(a) max(max(a.x,a.y),a.z)
#define BUFFER_SIZE int2(BUFFER_WIDTH,BUFFER_HEIGHT)
#define BUFFER_SIZE3 int3(BUFFER_WIDTH,BUFFER_HEIGHT,BUFFER_WIDTH*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE/1024.0)

//////////////////////////////////////////////////////////////////////////////

texture texMotionVectors { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG16F; };
sampler sTexMotionVectorsSampler { Texture = texMotionVectors; AddressU = Clamp; AddressV = Clamp; MipFilter = Point; MinFilter = Point; MagFilter = Point; };

namespace DH_UBER_MOTION_020 {

// Textures

    // Common textures
    texture halfMotionTex { Width = BUFFER_WIDTH>>1; Height = BUFFER_HEIGHT>>1; Format = RG16F; };
    sampler halfMotionSampler { Texture = halfMotionTex; };
    //MipFilter = Point; MinFilter = Point; MagFilter = Point;
    
    texture colorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler colorSampler { Texture = colorTex; MinLOD = 0.0f; MaxLOD = 5.0f;};

    texture previousColorTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; MipLevels = 6;  };
    sampler previousColorSampler { Texture = previousColorTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
    
    
    texture depthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };
    sampler depthSampler { Texture = depthTex; };

    texture previousDepthTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F; };
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
    
    uniform bool bUnjitterDepth <
        ui_category = "Motion Detection";
        ui_label = "Unjitter Depth";
        ui_tooltip = "Improve motion detection in case of upscaling (TAA/DLSS/FSR)";
    > = true;
    
/*
    uniform float fTest <
        ui_type = "slider";
        ui_min = 0.0; ui_max = 10.0;
        ui_step = 0.001;
    > = 0.001;
    uniform bool bTest = true;
    uniform bool bTest2 = true;
    uniform bool bTest3 = true;
    uniform bool bTest4 = true;
*/

// PS

    float getDepth(float2 coords) {
        return getColorSampler(depthSampler,coords).x;
    }

    float3 getFirst(sampler sourceSampler, float2 coords) {
        return getColorSampler(sourceSampler,coords).rgb;
    }
    
    float3 getSecond(sampler sourceSampler, float2 coords) {
        return getColorSamplerLod(sourceSampler,(coords-ReShade::PixelSize*8),2.5).rgb;
    }
    
    float motionDistance(float2 refCoords, float3 refColor,float3 refAltColor,float refDepth, float2 currentCoords) {
        float currentDepth = getColorSampler(previousDepthSampler,currentCoords).x;
        float diffDepth = abs(refDepth-currentDepth);
        
        float3 currentColor = getFirst(previousColorSampler,currentCoords);
        float3 currentAltColor = getSecond(previousColorSampler,currentCoords);

        float3 diffColor = abs(currentColor-refColor);
        float3 diffAltColor = abs(currentAltColor-refAltColor);
        
        float dist = distance(refCoords,currentCoords)*0.5;
        dist += maxOf3(diffColor);
        dist += maxOf3(diffAltColor);
        dist *= 0.01+diffDepth;
        
        return dist;     
    }
    
    void PS_MotionPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float2 outMotion : SV_Target0) {

        float2 refCoords = coords;
        
        float2 pixelSize = ReShade::PixelSize;
        float3 refColor = getFirst(colorSampler,coords);
        float3 refAltColor = getSecond(colorSampler,coords);
        float refDepth = getDepth(coords);

        int2 delta = 0;
        float deltaStep = 1;
        
        float2 currentCoords = refCoords;
        float dist = motionDistance(coords,refColor,refAltColor,refDepth,currentCoords);
                
        float bestDist = dist;
        
        float2 bestMotion = currentCoords;
        
        [loop]     
        //for(int radius=1;radius<=iMotionRadius;radius++) {
        for(int radius=iMotionRadius;radius>=1;radius--) {
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
    
    float2 offsetCoords(float2 coords,float dx,float dy) {
        return coords+float2(dx,dy);
    }
    
    float2 offsetCoordsPixels(float2 coords,float dx,float dy) {
        return coords+float2(dx,dy)*ReShade::PixelSize*2;
    }
        
    void PS_InputPass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0, out float4 outDepth : SV_Target1) {
        outColor = getColor(coords);
        float depth = ReShade::GetLinearizedDepth(coords);
        if(bUnjitterDepth) {
            float2 previousCoords = coords + getColorSampler(sTexMotionVectorsSampler,coords).xy;
            float previousDepth = getColorSampler(previousDepthSampler,previousCoords).x;
            depth = lerp(previousDepth,depth,0.333);
        }
        outDepth = float4(depth,0,0,1);
    }

    void PS_SavePass(float4 vpos : SV_Position, float2 coords : TexCoord, out float4 outColor : SV_Target0, out float4 outDepth : SV_Target1, out float2 outMotion : SV_Target2) {
        outColor = getColorSampler(colorSampler,coords);
        outDepth = getColorSampler(depthSampler,coords);
        outMotion = getColorSampler(halfMotionSampler,coords).xy;
    }


// TEHCNIQUES 
    
    technique DH_UBER_MOTION_020 <
            ui_label = "DH_UBER_Motion 0.2.0";
            ui_tooltip = 
                "_____________ DH_UBER_Motion _____________\n"
                "\n"
                "         version 0.2.0 by AlucardDH\n"
                "\n"
                "_____________________________________________";
        > {
        pass {
            VertexShader = PostProcessVS;
            PixelShader = PS_InputPass;
            RenderTarget = colorTex;
            RenderTarget1 = depthTex;
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