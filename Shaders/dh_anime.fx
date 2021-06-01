#include "ReShade.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#define getColor_DHa(c) tex2Dlod(ReShade::BackBuffer,float4(c,0.0,0.0))
#define getBlur_DHa(c) tex2Dlod(blurSampler,float4(c,0.0,0.0))
#define getDepth_DHa(c) ReShade::GetLinearizedDepth(c)*RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
#define diff3t_DHa(v1,v2,t) (abs(v1.x-v2.x)>t || abs(v1.y-v2.y)>t || abs(v1.z-v2.z)>t)

namespace DHAnime {

//// uniform

	uniform int iBlackLineThickness <
	    ui_category = "Black lines";
		ui_label = "Thickness";
		ui_type = "slider";
	    ui_min = 0;
	    ui_max = 16;
	    ui_step = 1;
	> = 3;
	uniform float fBlackLineThreshold <
	    ui_category = "Black lines";
		ui_label = "Threshold";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.995;

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
	> = 2.5;

	uniform float iShadingSteps <
		ui_category = "Colors";
		ui_label = "Shading steps";
		ui_type = "slider";
	    ui_min = 1;
	    ui_max = 255;
	    ui_step = 1;
	> = 16;

//// textures

	texture normalTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
	sampler normalSampler { Texture = normalTex; };

	texture blurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
	sampler blurSampler { Texture = blurTex; };

//// Functions

	// Normals

	float3 normal(float2 texcoord)
	{
		const float3 offset = float3(BUFFER_PIXEL_SIZE.xy, 0.0);
		const float2 posCenter = texcoord.xy;
		const float2 posNorth  = posCenter - offset.zy;
		const float2 posEast   = posCenter + offset.xz;

		const float3 vertCenter = float3(posCenter - 0.5, 1) * getDepth_DHa(posCenter);

		return normalize(cross(vertCenter - float3(posNorth - 0.5,  1) * getDepth_DHa(posNorth), vertCenter - float3(posEast - 0.5,   1) * getDepth_DHa(posEast)));
	}

	
	void saveNormal(in float3 normal, out float4 outNormal) 
	{
		outNormal = float4(normal*0.5+0.5,1.0);
	}
	
	float3 loadNormal(in float2 coords) {
		return (tex2Dlod(normalSampler,float4(coords,0,0)).xyz-0.5)*2.0;
	}

	// Color space

	float RGBCVtoHUE(in float3 RGB, in float C, in float V) {
	      float3 Delta = (V - RGB) / C;
	      Delta.rgb -= Delta.brg;
	      Delta.rgb += float3(2,4,6);
	      Delta.brg = step(V, RGB) * Delta.brg;
	      return frac(max(Delta.r, max(Delta.g, Delta.b)) / 6);
	}

	float3 RGBtoHSL(in float3 RGB) {
	    float3 HSL = 0;
	    const float U = -min(RGB.r, min(RGB.g, RGB.b));
	    const float V = max(RGB.r, max(RGB.g, RGB.b));
	    HSL.z = ((V - U) * 0.5);
	    const float C = V + U;
	    if (C != 0)
	    {
	    	HSL.x = RGBCVtoHUE(RGB, C, V);
	    	HSL.y = C / (1 - abs(2 * HSL.z - 1));
	    }
	    return HSL;
	}

	float3 HUEtoRGB(in float H) 
	{
	    return saturate(float3(abs(H * 6 - 3) - 1, 2 - abs(H * 6 - 2), 2 - abs(H * 6 - 4)));
	}

	float3 HSLtoRGB(in float3 HSL)
	{
	    return (HUEtoRGB(HSL.x) - 0.5) * ((1 - abs(2 * HSL.z - 1)) * HSL.y) + HSL.z;
	}


//// PS

	void PS_Input(float4 vpos : SV_Position, in float2 coords : TEXCOORD, out float4 outNormal : SV_Target, out float4 outBlur : SV_Target1)
	{
		saveNormal(normal(coords),outNormal);

		if(iSurfaceBlur>0) {
			float4 sum;
			int count;

			int2 delta;
			for(delta.x=-iSurfaceBlur;delta.x<=iSurfaceBlur;delta.x++) {
				for(delta.y=-iSurfaceBlur;delta.y<=iSurfaceBlur;delta.y++) {
					int d = dot(delta,delta);
					if(d<=iSurfaceBlur*iSurfaceBlur) {
						const float2 searchCoords = coords+BUFFER_PIXEL_SIZE*delta;
						const float searchDepth = getDepth_DHa(searchCoords);
						const float dRatio = getDepth_DHa(coords)/searchDepth;
						
						if(dRatio>=0.95 && dRatio<=1.05) {
							sum += getColor_DHa(searchCoords);
							count++;
						}
					}
				}
			}
			outBlur = sum/count;
		} else {
			outBlur = getColor_DHa(coords);
		}
	}

	void PS_Manga(float4 vpos : SV_Position, in float2 coords : TEXCOORD, out float4 outPixel : SV_Target)
	{
		// black line
		if(iBlackLineThickness>0) {
			int2 delta;
			for(delta.x=-iBlackLineThickness;delta.x<=iBlackLineThickness;delta.x++) {
				for(delta.y=-iBlackLineThickness;delta.y<=iBlackLineThickness;delta.y++) {
					if(dot(delta,delta)<=iBlackLineThickness*iBlackLineThickness) {
						const float2 searchCoords = coords+BUFFER_PIXEL_SIZE*delta;
						const float searchDepth = getDepth_DHa(searchCoords);
						const float3 searchNormal = loadNormal(searchCoords);

						if(getDepth_DHa(coords)/searchDepth<=fBlackLineThreshold && diff3t_DHa(loadNormal(coords),searchNormal,0.1)) {
							outPixel = float4(0.0,0.0,0.0,1.0);
							return;
						}
					}
				}
			}
		}

		float3 color = getBlur_DHa(coords).rgb;
		float3 hsl = RGBtoHSL(color);
		
		// shading steps
		float stepSize = 1.0/iShadingSteps;
		hsl.z = round(hsl.z/stepSize)/iShadingSteps;

		// saturation
		hsl.y = clamp(hsl.y*fSaturation,0,1);

		color = HSLtoRGB(hsl);

#if GSHADE_DITHER
		outPixel = float4(color.rgb + TriDither(color.rgb, coords, BUFFER_COLOR_BIT_DEPTH),1.0);
#else
		outPixel = float4(color,1.0);
#endif
	}

//// Techniques

	technique DH_Anime <
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
			PixelShader = PS_Manga;
		}
	}

}