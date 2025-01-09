#include "Reshade.fxh"

#define TEX_SIZE 800
#define BUFFER_SIZE int2(BUFFER_WIDTH,BUFFER_HEIGHT)
#define getColorSampler(s,c) tex2Dlod(s,float4((c).xy,0,0))
#define getColor(c) tex2Dlod(ReShade::BackBuffer,float4((c).xy,0,0))
#define TREP AddressU=REPEAT;AddressV=REPEAT;AddressW=REPEAT;

namespace DH_Canvas_010 {

// Textures
	// R = height map, more to come maybe... 
    texture canvasPBRTex < source = "dh_canvas2.png" ; > { Width = TEX_SIZE; Height = TEX_SIZE; MipLevels = 1; Format = RGBA8; };
    sampler canvasPBRSampler { Texture = canvasPBRTex;TREP};

	texture canvasNormalTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
	sampler canvasNormalSampler { Texture = canvasNormalTex; };

// Uniforms
uniform int framecount < source = "framecount"; >;

// CANVAS
	uniform float fCanvasHeight <
	    ui_category = "Canvas";
		ui_label = "Height";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 10.0;
	    ui_step = 0.01;
	> = 1.5;
	
	uniform float fCanvasScale <
	    ui_category = "Canvas";
		ui_label = "Scale";
		ui_type = "slider";
	    ui_min = 0.01;
	    ui_max = 2.0;
	    ui_step = 0.01;
	> = 1.0;

// LIGHT
	uniform float2 fLightPositionXY <
	    ui_category = "Light";
		ui_label = "Position X,Y";
		ui_type = "slider";
	    ui_min = -1.0;
	    ui_max = 2.0;
	    ui_step = 0.001;
	> = float2(0.5,-0.25);
	
	uniform float fLightPositionZ <
	    ui_category = "Light";
		ui_label = "Position Z";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 16.0;
	    ui_step = 0.001;
	> = 6.0;
	
	uniform float fLightMinBrightness <
	    ui_category = "Light";
		ui_label = "Min brightness";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.2;
	
	uniform float fLightReflexion <
	    ui_category = "Light";
		ui_label = "Reflexion";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.2;





// Functions

	float4 getPBR(float2 coords) {
		return tex2D(canvasPBRSampler,(coords/fCanvasScale)*float2(BUFFER_SIZE)/TEX_SIZE);
	}

	float3 getWorldPosition(float2 coords) {
		float4 pbr = getPBR(coords);
		float depth = (1.0-pbr.x)*fCanvasHeight;
		return float3(coords*BUFFER_SIZE,depth);
	}

	float4 computeNormal(float3 wpCenter,float3 wpNorth,float3 wpEast) {
        return float4(normalize(cross(wpCenter - wpNorth, wpCenter - wpEast)),1.0);
    }
    
    float4 computeNormal(float2 coords) {
    	float3 offset = float3(ReShade::PixelSize,0);
        float3 posCenter = getWorldPosition(coords);
        float3 posNorth  = getWorldPosition(coords - offset.zy);
        float3 posEast   = getWorldPosition(coords + offset.xz);
        
        return (computeNormal(posCenter,posNorth,posEast)+1.0)*0.5;
    }
    
    float3 getNormal(float2 coords) {
    	return getColorSampler(canvasNormalSampler,coords).xyz*2.0-1.0;
    }


// Pixel shaders
	void PS_Normal(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outPixel : SV_Target) {
		outPixel = computeNormal(coords);
	}

	void PS_result(in float4 position : SV_Position, in float2 coords : TEXCOORD, out float4 outPixel : SV_Target) {
		float4 color = tex2D(ReShade::BackBuffer,coords);
		
		float3 wp = getWorldPosition(coords);
		float3 normal = getNormal(coords);
		
		float3 lightPosition = float3(fLightPositionXY*BUFFER_SIZE,-fLightPositionZ*100);
		float3 lightVector = normalize(wp - lightPosition);
		float direction = dot(lightVector,normal);
		
		float3 result = color.rgb * saturate(direction+fLightMinBrightness);
		
		if(fLightReflexion>0) {
			float3 reflected = reflect(lightVector,normal);
			float directionReflection = dot(reflected,float3(0,0,-1));
			result = saturate(result + fLightReflexion*saturate(directionReflection));
		}
		
		outPixel = float4(result,1.0);
	}
	
// Techniques

	technique DH_Canvas < ui_label = "DH_Canvas 0.1.0"; > {
		pass {
			VertexShader = PostProcessVS;
			PixelShader = PS_Normal;
			RenderTarget = canvasNormalTex;
		}
		pass {
			VertexShader = PostProcessVS;
			PixelShader = PS_result;
		}
	}

}