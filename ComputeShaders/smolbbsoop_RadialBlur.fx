/* ===================================================================================
Copyright © Violet Cleathero - 2024

Permission is hereby granted, free of charge, to any person obtaining a copy of this 
software and associated documentation files (the "Software"), to deal in the Software 
without restriction, including without limitation the rights to use, copy, modify, 
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to the following 
conditions:

The above copyright notice and this permission notice shall be included in all copies 
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE,ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=================================================================================== */
#if(__RENDERER__ != 0x9000)
	
//============================================================================================
// UI
//============================================================================================
	
//==============================================================
// Blur Parameters
//==============================================================
	
	uniform float2 BlurCenter <
	    ui_type = "slider";
	    ui_label = "Center of Image";
	    ui_category = "Blur Adjustments";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    > = float2(0.5, 0.5);
	
	uniform float BlurStrength <
	    ui_type = "slider";
	    ui_label = "Intensity";
	    ui_category = "Blur Adjustments";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    > = 0.75;
	
	uniform float Falloff <
	    ui_type = "slider";
	    ui_label = "Falloff Distance";
	    ui_category = "Blur Adjustments";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    > = 0.6;
	    
//============================================================================================
// Defines / Textures / Samplers
//============================================================================================

	#include "ReShade.fxh"
	#include "smolbbsoop_Global.fxh"
	    
	sampler BackBuffer { Texture = ReShade::BackBufferTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; AddressW = CLAMP; };
	
	#define RES float2(BUFFER_WIDTH, BUFFER_HEIGHT)

//============================================================================================
// Functions
//============================================================================================
	
	float2 Rotate(float2 uv, float2 pivot, float angle)
	{
	    const float s = sin(angle);
	    const float c = cos(angle);
	
	    uv -= pivot;
	    const float2 rotatedUV = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
	    return rotatedUV + pivot;
	}
	
//============================================================================================
// Main Function
//============================================================================================
	
	float4 RadialBlur(float2 texCoords, float2 center, float strength, int quality, float falloff, float taperStrength)
	{
		float4 Colour = float4(0.0, 0.0, 0.0, 1.0);
	
		// there was probably a better way to make it AR agnostic, but this does the trick mostly :)
	    const float aspectRatio = RES.x / RES.y;
		const float2 adjustedCoords = float2(texCoords.x, texCoords.y / aspectRatio);
	    const float2 adjustedCenter = float2(center.x, center.y / aspectRatio);
		
	    const float distance = length(adjustedCoords - adjustedCenter);
	    const float falloffFactor = pow(max(distance, 0.0), falloff);
	
	    const float taperBase = 1.0 - taperStrength;
	    const float taperCompensation = lerp(2.0, 1.0, taperStrength);
	
	    for (int i = 0; i < quality; i++)
	    {
	        float angle = (0.1 + float(i) * 0.5) * strength * falloffFactor;
	        float taperWeight = taperBase + taperStrength * (1.0 - abs(float(i) / quality));
	
//==============================================================
// Positive Rotation
//==============================================================

	        float2 rotatedCoords = Rotate(adjustedCoords, adjustedCenter, angle);
	        rotatedCoords.y *= aspectRatio;
	        
	        float3 sampleColour;
	        
	        #if _SOOP_COLOUR_SPACE == 1 // srgb
	    		sampleColour = sRGBToLinear(tex2D(ReShade::BackBuffer, rotatedCoords).rgb);
	        #elif _SOOP_COLOUR_SPACE == 2 // scrgb
	    		sampleColour = tex2D(ReShade::BackBuffer, rotatedCoords).rgb;
	        #elif _SOOP_COLOUR_SPACE == 3 // hdr10 
				sampleColour = PQToLinear(tex2D(ReShade::BackBuffer, rotatedCoords).rgb);
	        #endif
	        
	        Colour.rgb += sampleColour * taperWeight;
	
//==============================================================
// Negative Rotation
//==============================================================

	        rotatedCoords = Rotate(adjustedCoords, adjustedCenter, -angle);
	        rotatedCoords.y *= aspectRatio;
	        
	        #if _SOOP_COLOUR_SPACE == 1 // srgb
	        	sampleColour = sRGBToLinear(tex2D(ReShade::BackBuffer, rotatedCoords).rgb);
	        #elif _SOOP_COLOUR_SPACE == 2 // scrgb
	        	sampleColour = tex2D(ReShade::BackBuffer, rotatedCoords).rgb;
	        #elif _SOOP_COLOUR_SPACE == 3 // hdr10
	        	sampleColour = PQToLinear(tex2D(ReShade::BackBuffer, rotatedCoords).rgb);
	        #endif
	        
	        Colour.rgb += sampleColour * taperWeight;
	    }
	
	    // normalise and convert back
	    Colour.rgb /= (quality * taperCompensation);
	    
	    #if _SOOP_COLOUR_SPACE == 1
	    	Colour.rgb = LinearTosRGB(Colour.rgb);
	    #elif _SOOP_COLOUR_SPACE == 2
	    	Colour.rgb = Colour.rgb;
	    #elif _SOOP_COLOUR_SPACE == 3
	    	Colour.rgb = LinearToPQ(Colour.rgb);
		#endif
		
	    return Colour;
	}
	
//============================================================================================
// Shader
//============================================================================================
	
	float4 ApplyBlur(float4 pos : SV_Position, float2 texCoords : TexCoord) : SV_Target
	{
		// this might waste a few 0.00001ms but it makes it neater for me :3
		// it was initially controllable but my god the blur looks horrendous without the taper
		const float TaperStrength = 1.0;
		
		// adjusted controls (keeps all sliders 0-1 with adapted controls to ensure useable results :3)
		const float adjustedBlurStrength = clamp(lerp(0.0, 0.02, BlurStrength), 0.0, 0.02);
		const float adjustedFalloff = clamp(lerp(1.0, 5.0, Falloff), 1.0, 5.0);
	    
	    // i cant figure out how to separate quality from blur strength so this will do as a mediocre compromise
	    // also has the benefit that the shader can be more performant with reasonable blurs i guess \o/
	    float dynamicQuality = lerp(5, 100, (adjustedBlurStrength * 50)) * (1.0 / max(adjustedFalloff, 0.001));
	    dynamicQuality = clamp(dynamicQuality, 5.0, 300);
	    
	    return RadialBlur(texCoords, BlurCenter, adjustedBlurStrength, dynamicQuality, adjustedFalloff, TaperStrength);
	}
	
//============================================================================================
// Techniques / Passes
//============================================================================================
	
	technique RadialBlur < ui_label = "Symmetrical Radial Blur"; ui_tooltip = "An unoptimised and lazily made radial blur shader that warps the edges of the frame in a radial pattern"; >
	{
	    pass
	    {
	        VertexShader = PostProcessVS;
	        PixelShader  = ApplyBlur;
	    }
	}
#else	
	uniform int DX9Failsafe <
		ui_type = "radio";
		ui_text = "Sorry! This shader is incompatible with DX9. \nPlease consider using an API wrapper, such as DXVK or DGVoodoo2.";
		ui_label = " ";
		> = 0;
		
	technique RadialBlur < ui_label = "Symmetrical Radial Blur"; ui_tooltip = "An unoptimised and lazily made radial blur shader that warps the edges of the frame in a radial pattern"; >
	{ }
#endif