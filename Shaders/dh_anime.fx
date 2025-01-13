////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_Anime
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

#ifndef DH_ANIME_RENDER_SCALE
 #define DH_ANIME_RENDER_SCALE 2
#endif

#define NOISE_SIZE 512
#define BUFFER_SIZE int2(BUFFER_WIDTH,BUFFER_HEIGHT)
#define getColor(c) tex2Dlod(ReShade::BackBuffer,float4(c,0.0,0.0))
#define getColorSampler(s,c) tex2Dlod(s,float4((c).xy,0,0))
#define getColorSamplerLod(s,c,l) tex2Dlod(s,float4((c).xy,0,l))
#define getBlur(c) tex2Dlod(blurSampler,float4(c,0.0,0.0))
#define getDepth(c) ReShade::GetLinearizedDepth(c)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
#define diff3t(v1,v2,t) (abs(v1.x-v2.x)>t || abs(v1.y-v2.y)>t || abs(v1.z-v2.z)>t)
#define maxOf3(a) max(max(a.x,a.y),a.z)

namespace DHAnime13 {

//// uniform
    uniform int framecount < source = "framecount"; >;

/*
	uniform bool bTest = false;
	uniform bool bTest2 = false;
	uniform bool bTest3 = false;
	uniform bool bTest4 = false;
	uniform float fTest <
			ui_type = "slider";
		    ui_min = 0;
		    ui_max = 1.0;
		    ui_step = 0.001;
		> = 0.5;
	uniform float fTest2 <
			ui_type = "slider";
		    ui_min = 0;
		    ui_max = 1.0;
		    ui_step = 0.001;
		> = 0.5;
	uniform float fTest3 <
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.5;
*/
	

	uniform float3 cBlackLineColor <
	    ui_category = "Black lines";
		ui_label = "Color";
		ui_type = "color";
	> = 0;    
    uniform float fBlackLineMultiply <
        ui_category= "Black lines";
        ui_label = "Color intensity";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 1.0;
	
	uniform bool bDepthBlackLine <
	    ui_category = "Black lines";
		ui_label = "Depth based";
	> = true;
	uniform int iDepthBlackLineThickness <
	    ui_category = "Black lines";
		ui_label = "Thickness (depth)";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 16;
	    ui_step = 1;
	> = 2;
	uniform float fDepthBlackLineThreshold <
	    ui_category = "Black lines";
		ui_label = "Threshold (depth)";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.995;

	uniform bool bColorBlackLine <
	    ui_category = "Black lines";
		ui_label = "Color based";
	> = true;
	uniform int iColorBlackLineThickness <
	    ui_category = "Black lines";
		ui_label = "Thickness (color)";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 16;
	    ui_step = 1;
	> = 2;
	uniform float fColorBlackLineThreshold <
	    ui_category = "Black lines";
		ui_label = "Threshold (color)";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.935;
	
	uniform float iSurfaceBlur <
		ui_category = "Colors";
		ui_label = "Surface blur";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 16;
	    ui_step = 1;
	> = 3;
	
	uniform float fSaturation <
		ui_category = "Colors";
		ui_label = "Saturation multiplier";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 5.0;
	    ui_step = 0.01;
	> = 1.75;

	uniform float iShadingSteps <
		ui_category = "Colors";
		ui_label = "Shading steps";
		ui_type = "slider";
	    ui_min = 1;
	    ui_max = 255;
	    ui_step = 1;
	> = 16;
	
	uniform float fShadingRamp <
		ui_category = "Colors";
		ui_label = "Shading Ramp";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 6;
	    ui_step = 0.1;
	> = 1.0;
	
	uniform bool bDithering <
	    ui_category = "Colors";
		ui_label = "Dithering";
	> = false;
	
	uniform bool bHueFilter <
	    ui_category = "Hue filter";
		ui_label = "Enabled";
	> = false;
	uniform float fHueFilter <
	    ui_category = "Hue filter";
		ui_label = "Selected hue";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.0;
	uniform float fHueFilterRange <
	    ui_category = "Hue filter";
		ui_label = "Range";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.0;
    
    uniform int iToneMode <
        ui_category= "Half-tone";
        ui_type = "combo";
        ui_label = "Half-tone mode";
        ui_items = "Disable\0Greyscale\0Full color\0RGB dots (CRT Shadow mask)\0CMY dots (substractive print)\0";
    > = 0;
    
    uniform int iToneEffect <
        ui_category= "Half-tone";
        ui_type = "combo";
        ui_label = "Effect";
        ui_items = "Size\0Brightness\0";
    > = 0;
    
    uniform bool bToneRotateColors <
        ui_category= "Half-tone";
        ui_label = "RGB/CMY rotate colors (DLP rainbow effect)";
    > = false;
    
	uniform float fToneDotSpacing <
        ui_category = "Half-tone";
    	ui_label = "Dot spacing";
    	ui_type = "slider";
        ui_min = 1;
        ui_max = 32;
        ui_step = 1;
    > = 5;
    
	uniform float fToneDotRamp <
		ui_category = "Half-tone";
		ui_label = "Shading Ramp";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 6;
	    ui_step = 0.1;
	> = 1.5;

//// textures
	texture blueNoiseTex < source ="dh_rt_noise.png" ; > { Width = NOISE_SIZE; Height = NOISE_SIZE; MipLevels = 1; Format = RGBA8; };
    sampler blueNoiseSampler { Texture = blueNoiseTex;  AddressU = REPEAT;	AddressV = REPEAT;	AddressW = REPEAT;};

	texture normalTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
	sampler normalSampler { Texture = normalTex; };
	
	texture blurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
	sampler blurSampler { Texture = blurTex; };
	

	texture linesTex { Width = BUFFER_WIDTH*DH_ANIME_RENDER_SCALE; Height = BUFFER_HEIGHT*DH_ANIME_RENDER_SCALE; };
	sampler linesSampler { Texture = linesTex; };

	
	texture halftonesTex { Width = BUFFER_WIDTH*DH_ANIME_RENDER_SCALE; Height = BUFFER_HEIGHT*DH_ANIME_RENDER_SCALE; };
	sampler halftonesSampler { Texture = halftonesTex; };

    texture scaledTex { Width = BUFFER_WIDTH*DH_ANIME_RENDER_SCALE; Height = BUFFER_HEIGHT*DH_ANIME_RENDER_SCALE; Format = RGBA8; MipLevels = 6; };
    sampler scaledSampler { Texture = scaledTex; MinLOD = 0.0f; MaxLOD = 5.0f;};
	
//// Functions

	// Color space
	
    float3 RGBtoHSV(float3 c) {
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    
        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }
    
    float3 HSVtoRGB(float3 c) {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

	float RGBCVtoHUE(in float3 RGB, in float C, in float V) {
	      float3 Delta = (V - RGB) / C;
	      Delta.rgb -= Delta.brg;
	      Delta.rgb += float3(2,4,6);
	      Delta.brg = step(V, RGB) * Delta.brg;
	      float H;
	      H = max(Delta.r, max(Delta.g, Delta.b));
	      return frac(H / 6);
	}

	// Normals

	float3 normal(float2 texcoord)
	{
		float3 offset = float3(ReShade::PixelSize.xy, 0.0);
		float2 posCenter = texcoord.xy;
		float2 posNorth  = posCenter - offset.zy;
		float2 posEast   = posCenter + offset.xz;
	
		float3 vertCenter = float3(posCenter - 0.5, 1) * getDepth(posCenter);
		float3 vertNorth  = float3(posNorth - 0.5,  1) * getDepth(posNorth);
		float3 vertEast   = float3(posEast - 0.5,   1) * getDepth(posEast);
	
		return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast));
	}
	
	float mirrorSmoothstep(float v,float coef) {
		if(v<0.5) {
			return pow(v*2,1.0/coef)*0.5;
		} else {
			return pow((v-0.5)*2,coef)*0.5+0.5;
		}
	}
	
    bool inScreen(float2 coords) {
        return coords.x>=0.0 && coords.x<=1.0
            && coords.y>=0.0 && coords.y<=1.0;
    }

	
	void saveNormal(in float3 normal, out float4 outNormal) 
	{
		outNormal = float4(normal*0.5+0.5,1.0);
	}
	
	float3 loadNormal(in float2 coords) {
		return (getColorSampler(normalSampler,coords).xyz-0.5)*2.0;
	}


//// PS

	void PS_Input(float4 vpos : SV_Position, in float2 coords : TEXCOORD0, out float4 outNormal : SV_Target, out float4 outBlur : SV_Target1)
	{
		float3 normal = normal(coords);
		saveNormal(normal,outNormal);
		
		float3 color;
		
		if(iSurfaceBlur>0) {
			float3 sum;
			int count;
			
			int maxDistance = iSurfaceBlur*iSurfaceBlur;
			float depth = getDepth(coords);
			
			int2 delta;
			for(delta.x=-iSurfaceBlur;delta.x<=iSurfaceBlur;delta.x++) {
				for(delta.y=-iSurfaceBlur;delta.y<=iSurfaceBlur;delta.y++) {
					int d = dot(delta,delta);
					if(d<=maxDistance) {
						float2 searchCoords = coords+ReShade::PixelSize*delta;
						float searchDepth = getDepth(searchCoords);
						float dRatio = depth/searchDepth;
						
						if(dRatio>=0.95 && dRatio<=1.05) {
							float3 c = getColor(searchCoords).rgb;
							float3 cHsv = RGBtoHSV(c);
							cHsv.z = mirrorSmoothstep(cHsv.z,fShadingRamp);
							c = HSVtoRGB(cHsv);
							sum += c;
							count++;
						}
					}
				}
			}
			color = sum/count;
		} else {
			color = getColor(coords).rgb;
			float3 cHsv = RGBtoHSV(color);
			cHsv.z = mirrorSmoothstep(cHsv.z,fShadingRamp);
			color = HSVtoRGB(cHsv);
		}
		
		float3 hsv = RGBtoHSV(color);
		
		// shading steps
		float stepSize = 1.0/iShadingSteps;
		if(bDithering) {
			int2 coordsNoise = int2(coords*BUFFER_SIZE)%NOISE_SIZE;
			float noise = tex2Dfetch(blueNoiseSampler,coordsNoise).r;

			hsv.z = round((0.5*(noise-0.5)/iShadingSteps+hsv.z)/stepSize)/iShadingSteps;
		} else {
			hsv.z = round(hsv.z/stepSize)/iShadingSteps;
		}

		// saturation
		hsv.y = saturate(hsv.y*fSaturation);
		if(bHueFilter) {
			// fHueFilter
			float hueDist = (fHueFilter<hsv.x
				? min(hsv.x-fHueFilter,1+fHueFilter-hsv.x)
				: min(fHueFilter-hsv.x,1-fHueFilter+hsv.x)
				)*16;
			
			hueDist = smoothstep(0,1,saturate(hueDist));
			
			hsv.y *= 1.0-saturate(hueDist*(1.0-fHueFilterRange));
		} 
		

		color = HSVtoRGB(hsv);//HSLtoRGB(hsl);
		
		outBlur = float4(color,1);
	}
	
	void PS_LinePass(float4 vpos : SV_Position, in float2 coords : TEXCOORD0, out float4 outPixel : SV_Target) {
		if(!bColorBlackLine || iDepthBlackLineThickness<1) discard;
    
    	float refDepth = getDepth(coords);
        float3 refColor = getColor(coords).rgb;
        
        float roughness = 0.0;
        float ws = 0;
            
        float3 previousX = refColor;
        float3 previousY = refColor;
        
        float threshold = 1.0-saturate(fColorBlackLineThreshold);
        [loop]
        for(int d = 1;d<=iColorBlackLineThickness;d++) {
            float w = 1.0/pow(d,0.5);
            
            float3 color = getColor(float2(coords.x+ReShade::PixelSize.x*d,coords.y)).rgb;
            float3 diff = abs(previousX-color);
            roughness += maxOf3(diff)*w>threshold ? 1 : 0;
            ws += w;
            previousX = color;
            
            color = getColor(float2(coords.x,coords.y+ReShade::PixelSize.y*d)).rgb;
            diff = abs(previousY-color);
            roughness += maxOf3(diff)*w>threshold ? 1 : 0;
            ws += w;
            previousY = color;
        }
        
        previousX = refColor;
        previousY = refColor;
        
        [loop]
        for(int d = 1;d<=iColorBlackLineThickness;d++) {
            float w = 1.0/pow(d,0.5);
            
            float3 color = getColor(float2(coords.x-ReShade::PixelSize.x*d,coords.y)).rgb;
            float3 diff = abs(previousX-color);
            roughness += maxOf3(diff)*w>threshold ? 1 : 0;
            ws += w;
            previousX = color;
            
            color = getColor(float2(coords.x,coords.y-ReShade::PixelSize.y*d)).rgb;
            diff = abs(previousY-color);
            roughness += maxOf3(diff)*w>threshold ? 1 : 0;
            ws += w;
            previousY = color;
        }
        
        float refB = maxOf3(refColor);      
        roughness *= pow(refB,0.5);
        roughness *= pow(1.0-refB,2.0);
        
        //roughness *= 0.5+refDepth*2;
        float3 r = 1.0-roughness;
        outPixel = float4(r,1);
    }

    
    float getDotSpacing(float b) {
    	float result = fToneDotSpacing;
    	return ceil(result);
    }
    
    bool isEvenLine(float2 coordsInt,float toneDotSpacing) {
    	float lineHeight = toneDotSpacing-1;//*sqrt(3)/2;
    	float topLine = floor(coordsInt.y/lineHeight);
    	float bottomLine = ceil(coordsInt.y/lineHeight);

    	float dTop = coordsInt.y-topLine*lineHeight;
    	float dBottom = bottomLine*lineHeight-coordsInt.y;

    	return (dTop<=dBottom && topLine%2==0) || (dTop>=dBottom && bottomLine%2==0);    	
    }
    
    int2 getLineColumn(float2 coordsInt,float toneDotSpacing) {
    	float lineHeight = toneDotSpacing-1;//*sqrt(3)/2;
    	float topLine = floor(coordsInt.y/lineHeight);
    	float bottomLine = ceil(coordsInt.y/lineHeight);

    	float dTop = coordsInt.y-topLine*lineHeight;
    	float dBottom = bottomLine*lineHeight-coordsInt.y;

    	int2 result = 0;


		result.y = dTop<=dBottom ? topLine : bottomLine;
		
		float leftLine = floor(coordsInt.x/toneDotSpacing);
    	float rightLine = ceil(coordsInt.x/toneDotSpacing);
    	
    	float dLeft = abs(coordsInt.x-leftLine*toneDotSpacing);
	    float dRight = abs(coordsInt.x-rightLine*toneDotSpacing);
	    
	    result.x = dLeft<=dRight ? leftLine : rightLine;
	    
	    return result;
    }

    float2 getDotCenter(float2 coordsInt,float toneDotSpacing) {
    	float lineHeight = toneDotSpacing-1;//*sqrt(3)/2;
    	float topLine = floor(coordsInt.y/lineHeight);
    	float bottomLine = ceil(coordsInt.y/lineHeight);

    	float dTop = coordsInt.y-topLine*lineHeight;
    	float dBottom = bottomLine*lineHeight-coordsInt.y;

    	bool evenLine = (dTop<=dBottom && topLine%2==0) || (dTop>=dBottom && bottomLine%2==0);
    	
    	float leftLine = floor(coordsInt.x/toneDotSpacing);
    	float rightLine = ceil(coordsInt.x/toneDotSpacing);
    	
    	float2 result = 0;
    	result.y = (dTop<=dBottom ? topLine : bottomLine)*lineHeight;
    	
    	if(evenLine) {
    		float leftLine2 = leftLine-0.5;
    		float leftLine = leftLine+0.5;
    		float rightLine2 = rightLine-0.5;
    		float rightLine = rightLine+0.5;
    		
	    	float dLeft = abs(coordsInt.x-leftLine*toneDotSpacing);
	    	float dRight = abs(coordsInt.x-rightLine*toneDotSpacing);
	    	float dLeft2 = abs(coordsInt.x-leftLine2*toneDotSpacing);
	    	float dRight2 = abs(coordsInt.x-rightLine2*toneDotSpacing);
	    	
	    	float minD = min(min(dLeft,dLeft2),min(dRight,dRight2));
    		
    		if(minD==dLeft) {
    			result.x = leftLine*toneDotSpacing;
    		} else if(minD==dRight) {
    			result.x = rightLine*toneDotSpacing;
    		} else if(minD==dLeft2) {
    			result.x = leftLine2*toneDotSpacing;
    		} else if(minD==dRight2) {
    			result.x = rightLine2*toneDotSpacing;
    		}
    	} else {
	    	float dLeft = abs(coordsInt.x-leftLine*toneDotSpacing);
	    	float dRight = abs(coordsInt.x-rightLine*toneDotSpacing);
	    	result.x = (dLeft<=dRight ? leftLine : rightLine)*toneDotSpacing;
    	}

    	
    	return result;
    }
    
    bool isComponents() {
    	return iToneMode==3 || iToneMode==4;
    }
    
    float3 getDotBrightness(float brightness,float3 color, float2 coordsInt,float2 dotInt,float toneDotSpacing) {

		float dotMaxRadius = toneDotSpacing/2;
		
		float3 dotColor;
		
		if(iToneEffect==0) { // SIZE
			float3 dotRadius = (dotMaxRadius-1)*(iToneMode!=1 ? brightness : 1.0-brightness);
	
			float3 dotCenterDistance = distance(dotInt,coordsInt);
			
			dotColor = lerp(0,1,saturate(dotCenterDistance-dotRadius));
			
			if(iToneMode>1) {
				float3 hsv = RGBtoHSV(color);
				hsv.z = saturate(mirrorSmoothstep(hsv.z,fToneDotRamp)*2);
				color = HSVtoRGB(hsv);
				dotColor = (1.0-dotColor)*color;
			}
		} else if(iToneEffect==1) { // BRIGHTNESS
			float3 dotRadius = max(1,dotMaxRadius-1);
	
			float3 dotCenterDistance = distance(dotInt,coordsInt);

			dotColor = lerp(0,1,saturate(dotCenterDistance-dotRadius));
			
			float3 hsv = RGBtoHSV(color);
			hsv.z = saturate(mirrorSmoothstep(hsv.z,fToneDotRamp)*2);
			if(iToneMode==1) {
				color = hsv.z;
				dotColor = hsv.z+dotColor-0.5;//(1.0-dotColor)*color;
			} else {
				color = HSVtoRGB(hsv);
				dotColor = (1.0-dotColor)*color;
				dotColor *= hsv.z;
			} 
		}

		return dotColor;
    }


	void PS_Halftone(float4 vpos : SV_Position, in float2 coords : TEXCOORD0, out float4 outPixel : SV_Target) {
		if(iToneMode==0) discard;

    	float2 coordsInt = coords*BUFFER_SIZE;
    	float3 color = getColorSampler(blurSampler,coords).rgb;
		float brightness = mirrorSmoothstep(RGBtoHSV(color).z,fToneDotRamp);
		
		float depth = getDepth(coords);
    	float toneDotSpacing = getDotSpacing(brightness);
		float2 dotCenter = getDotCenter(coordsInt,toneDotSpacing);
		

		float3 finalColor = getDotBrightness(brightness,color,coordsInt,dotCenter,toneDotSpacing);
		
		for(int i=0;i<6;i++) {
			float2 delta = 0;
			if(i==0) {
				delta.x -= toneDotSpacing;
			} else if(i==1) {
				delta.x += toneDotSpacing;
			} else if(i==2 || i==3) {
				delta.x -= 0.5*toneDotSpacing;
			} else {
				delta.x += 0.5*toneDotSpacing;
			}
			if(i==0 || i==1) {
			} else if(i==2 || i==4) {
				delta.y -= toneDotSpacing-1;
			} else {
				delta.y += toneDotSpacing-1;
			}
			
			if(iToneMode>1) {
				finalColor = max(finalColor,getDotBrightness(brightness,color,coordsInt,dotCenter+delta,toneDotSpacing));
				
				int2 lc = getLineColumn(dotCenter,toneDotSpacing);
				int yOffset = isEvenLine(coordsInt,toneDotSpacing);
				int dotIndex = (lc.y*1.5+lc.x)%3;
				if(bToneRotateColors) dotIndex = (dotIndex+framecount%3)%3;
					
				if(iToneMode==3) {
					if(dotIndex==0) {
						finalColor *= float3(1,0,0);
					} else if(dotIndex==1) {
						finalColor *= float3(0,1,0);
					} else if(dotIndex==2) {
						finalColor *= float3(0,0,1);
					}
					
				} else if(iToneMode==4) {
					if(dotIndex==0) {
						finalColor *= float3(0,1,1);
					} else if(dotIndex==1) {
						finalColor *= float3(1,0,1);
					} else if(dotIndex==2) {
						finalColor *= float3(1,1,0);
					}
				}
						
				
			} else {
				finalColor = min(finalColor,getDotBrightness(brightness,color,coordsInt,dotCenter+delta,toneDotSpacing));
			}
			
		}
		
		outPixel = float4(saturate(finalColor),1);
	}

	void PS_Result(float4 vpos : SV_Position, in float2 coords : TEXCOORD0, out float4 outPixel : SV_Target)
	{
		float3 color = iToneMode>0 ? getColorSampler(halftonesSampler,coords).rgb : getBlur(coords).rgb;
		float3 refColor = color;
		// black lines depth
		if(bDepthBlackLine && iDepthBlackLineThickness>0) {
			float depthLineMul = 1;
			int maxDistance = iDepthBlackLineThickness*iDepthBlackLineThickness;
			float depth = getDepth(coords);
			float3 normal = loadNormal(coords);
			
			int2 delta;
			for(delta.x=-iDepthBlackLineThickness;depthLineMul>0 && delta.x<=iDepthBlackLineThickness;delta.x++) {
				for(delta.y=-iDepthBlackLineThickness;depthLineMul>0 && delta.y<=iDepthBlackLineThickness;delta.y++) {
					int d = dot(delta,delta);
					if(d<=maxDistance) {
						float2 searchCoords = coords+ReShade::PixelSize*delta;
						float searchDepth = getDepth(searchCoords);
						float3 searchNormal = loadNormal(searchCoords);

						if(depth/searchDepth<=fDepthBlackLineThreshold && diff3t(normal,searchNormal,0.1)) {
							depthLineMul = 0;
						}
					}
				}
			}
			color *= depthLineMul;
			color += (1.0-depthLineMul)*cBlackLineColor;
		}

		// black lines color
		if(bColorBlackLine && iDepthBlackLineThickness>0) { 
			float lines = tex2D(linesSampler,coords).r;
			color *= pow(lines,iDepthBlackLineThickness);
			color += (1.0-lines)*cBlackLineColor;
		}
		

		if(fBlackLineMultiply<1) {
			color = lerp(refColor,color,fBlackLineMultiply);
		}

		outPixel = float4(color,1.0);
		//outPixel = getColorSampler(halftonesSampler,coords);
	}
	
	void PS_Rescale(float4 vpos : SV_Position, in float2 coords : TEXCOORD0, out float4 outPixel : SV_Target)
	{
		if(DH_ANIME_RENDER_SCALE<=1) {
			outPixel = getColorSampler(scaledSampler,coords);
		} else {
			float2 delta;
			float radius = ceil(DH_ANIME_RENDER_SCALE*0.5);
			float2 pixelSize = ReShade::PixelSize/DH_ANIME_RENDER_SCALE;
			
			float3 sum = 0;
			float3 maxC = 0;
			float count = 0;
			
			for(delta.x=-DH_ANIME_RENDER_SCALE;delta.x<=DH_ANIME_RENDER_SCALE;delta.x++) {
				for(delta.x=-DH_ANIME_RENDER_SCALE;delta.x<=DH_ANIME_RENDER_SCALE;delta.x++) {
					float2 currentCoords = coords+delta*pixelSize;
					if(!inScreen(currentCoords)) continue;
					float3 c = getColorSampler(scaledSampler,currentCoords).rgb;
					count += 1;
					sum += c;
					maxC = max(maxC,c);
				}
			}
			outPixel = float4(sum/count,1.0);
		}
	}

//// Techniques

	technique DH_Anime_13 <
        ui_label = "DH_Anime 1.3";
	>
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_Input;
			RenderTarget = normalTex;
			RenderTarget1 = blurTex;
		}
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_LinePass;
			RenderTarget = linesTex;
		}
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_Halftone;
			RenderTarget = halftonesTex;
		}
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_Result;
			RenderTarget = scaledTex;
		}
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_Rescale;
		}
	}

}