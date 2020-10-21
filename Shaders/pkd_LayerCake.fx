/*
    LayerCake - v1.2
    by Packetdancer

    This shader allows you to slice apart an image and save it into separate texture buffers
    to be restored later. In practical terms, this lets you apply different shader combinations
    to different layers of the image all in a single preset.
*/


#include "ReShade.fxh"
#include "Blending.fxh"
#include "pkd_Color.fxh"

#define LAYERCAKE_LAYER_CONFIG(label, textureName, sampleName, depthVar, blendVar, opacityVar, shouldMaskVar, colorMaskVar, colorMaskBlendVar, alphaBlendVar, alphaBlendDepthVar) \
		uniform float2 depthVar < \
			ui_type = "slider"; \
			ui_category = label; \
			ui_label = "Depth Range"; \
			ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; \
		> = float2(0.0, 1.0); \
\
		uniform int blendVar < \
			ui_type = "combo"; \
			ui_category = label; \
			ui_label = "Blend Operation"; \
			ui_items = "Atop\0Darken\0Multiply\0Color Burn\0Linear Burn\0Lighten\0Screen\0Color Dodge\0Linear Dodge\0Addition\0Reflect\0Glow\0Overlay\0Soft Light\0Hard Light\0Vivid Light\0Linear Light\0Pin Light\0Hard Mix\0Difference\0Exclusion\0Subtract\0Divide\0Grain Merge\0Grain Extract\0Hue\0Saturation\0Color Blend\0Luminosity\0"; \
		> = 0; \
\
		uniform float opacityVar < \
			ui_type = "slider"; \
			ui_category = label; \
			ui_label = "Opacity"; \
			ui_min = 0.0; ui_max = 1.0; ui_step = 0.001; \
		> = 1.0; \
\
		uniform bool shouldMaskVar < \
			ui_category = label; \
			ui_label = "Treat a Color as Transparent?"; \
		> = false; \
\
		uniform float3 colorMaskVar < \
			ui_type = "color"; \
			ui_category = label; \
			ui_label = "Color to Mask"; \
		> = float3(0.0, 0.0, 0.0); \
\
		uniform float colorMaskBlendVar < \
			ui_type = "slider"; \
			ui_category = label; \
			ui_label = "Mask Color Tolerance"; \
			ui_tooltip = "How much can the color vary from the specified and still be masked? Specified in CIE DeltaE."; \
			ui_min = 0.0; ui_max = 64.0; ui_step = 0.1; \
		> = 1.0; \
\
		uniform bool alphaBlendVar < \
			ui_category = label; \
			ui_label = "Alpha Blend Layer Edges"; \
			ui_tooltip = "Should the edges of the layer be alpha-blended rather than a sharp falloff?"; \
		> = true; \
\
		uniform float2 alphaBlendDepthVar < \
			ui_type = "slider"; \
			ui_category = label; \
			ui_label = "Alpha Blend Depth Range"; \
			ui_tooltip = "Mark the start and end point of of the alpha blending within the depth range of the mask. Note that this is RELATIVE depth; 1.0 means 'the farthest point of the layer', not of the overall screenshot."; \
		> = float2(0.05, 0.95); \
\
		texture textureName { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; }; \
		sampler sampleName { Texture = textureName; };	 

#define LAYERCAKE_LAYER_SHADER(copyShader, pasteShader, depthVar, blendVar, opacityVar, maskVar, maskColorVar, maskBlendVar, alphaBlendVar, alphaBlendDepthVar, sampleLayer) \
		void copyShader(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float4 layerColor : SV_Target) \
        { \
        	layerColor = CopyLayer(texcoord, ReShade::BackBuffer, depthVar, maskVar, maskColorVar, maskBlendVar, alphaBlendVar, alphaBlendDepthVar); \
        } \
\
		void pasteShader(in float4 position : SV_Position, in float2 texcoord : TEXCOORD, out float4 screenColor : SV_Target) \
		{ \
			screenColor = PasteLayer(texcoord, sampleLayer, ReShade::BackBuffer, blendVar, opacityVar); \
		}

#define LAYERCAKE_LAYER_TECHNIQUES(copyName, copyShader, pasteName, pasteShader, renderTexture) \
		technique copyName \
		{ \
			pass { \
				VertexShader = PostProcessVS; \
				PixelShader = copyShader; \
				RenderTarget = renderTexture; \
			} \
		} \
\
		technique pasteName \
		{ \
			pass { \
				VertexShader = PostProcessVS; \
				PixelShader = pasteShader; \
			} \
		}

namespace pkd 
{
	namespace LayerCake
	{
		#define LAYERCAKE_BLEND_ATOP 0
		#define LAYERCAKE_BLEND_DARKEN 1
		#define LAYERCAKE_BLEND_MULTIPLY 2
		#define LAYERCAKE_BLEND_COLORBURN 3
		#define LAYERCAKE_BLEND_LINEARBURN 4
		#define LAYERCAKE_BLEND_LIGHTEN 5
		#define LAYERCAKE_BLEND_SCREEN 6
		#define LAYERCAKE_BLEND_COLORDODGE 7
		#define LAYERCAKE_BLEND_LINEARDODGE 8
		#define LAYERCAKE_BLEND_ADDITION 9
		#define LAYERCAKE_BLEND_REFLECT 10
		#define LAYERCAKE_BLEND_GLOW 11
		#define LAYERCAKE_BLEND_OVERLAY 12
		#define LAYERCAKE_BLEND_SOFTLIGHT 13
		#define LAYERCAKE_BLEND_HARDLIGHT 14
		#define LAYERCAKE_BLEND_VIVIDLIGHT 15
		#define LAYERCAKE_BLEND_LINEARLIGHT 16
		#define LAYERCAKE_BLEND_PINLIGHT 17
		#define LAYERCAKE_BLEND_HARDMIX 18
		#define LAYERCAKE_BLEND_DIFFERENCE 19
		#define LAYERCAKE_BLEND_EXCLUSION 20
		#define LAYERCAKE_BLEND_SUBTRACT 21
		#define LAYERCAKE_BLEND_DIVIDE 22
		#define LAYERCAKE_BLEND_GRAINMERGE 23
		#define LAYERCAKE_BLEND_GRAINEXTRACT 24
		#define LAYERCAKE_BLEND_HUE 25
		#define LAYERCAKE_BLEND_SATURATION 26
		#define LAYERCAKE_BLEND_COLORBLEND 27
		#define LAYERCAKE_BLEND_LUMINOSITY 28

		// Layer1
		LAYERCAKE_LAYER_CONFIG("Layer 1", Tex_Layer1, Samp_Layer1, CFG_LAYERCAKE_DEPTH_Layer1, CFG_LAYERCAKE_BLEND_Layer1, CFG_LAYERCAKE_OPACITY_Layer1, CFG_LAYERCAKE_MASKENABLE_Layer1, CFG_LAYERCAKE_MASKCOLOR_Layer1, CFG_LAYERCAKE_MASKBLEND_Layer1, CFG_LAYERCAKE_ALPHABLEND_Layer1, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer1)

		// Layer2
		LAYERCAKE_LAYER_CONFIG("Layer 2", Tex_Layer2, Samp_Layer2, CFG_LAYERCAKE_DEPTH_Layer2, CFG_LAYERCAKE_BLEND_Layer2, CFG_LAYERCAKE_OPACITY_Layer2, CFG_LAYERCAKE_MASKENABLE_Layer2, CFG_LAYERCAKE_MASKCOLOR_Layer2, CFG_LAYERCAKE_MASKBLEND_Layer2, CFG_LAYERCAKE_ALPHABLEND_Layer2, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer2)

		// Layer3
		LAYERCAKE_LAYER_CONFIG("Layer 3", Tex_Layer3, Samp_Layer3, CFG_LAYERCAKE_DEPTH_Layer3, CFG_LAYERCAKE_BLEND_Layer3, CFG_LAYERCAKE_OPACITY_Layer3, CFG_LAYERCAKE_MASKENABLE_Layer3, CFG_LAYERCAKE_MASKCOLOR_Layer3, CFG_LAYERCAKE_MASKBLEND_Layer3, CFG_LAYERCAKE_ALPHABLEND_Layer3, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer3)

		// Layer4
		LAYERCAKE_LAYER_CONFIG("Layer 4", Tex_Layer4, Samp_Layer4, CFG_LAYERCAKE_DEPTH_Layer4, CFG_LAYERCAKE_BLEND_Layer4, CFG_LAYERCAKE_OPACITY_Layer4, CFG_LAYERCAKE_MASKENABLE_Layer4, CFG_LAYERCAKE_MASKCOLOR_Layer4, CFG_LAYERCAKE_MASKBLEND_Layer4, CFG_LAYERCAKE_ALPHABLEND_Layer4, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer4)

		float4 CopyLayer(float2 texcoord, sampler sourceSamp, float2 depthRange, bool maskEnable, float3 maskColor, float maskTolerance, bool alphaBlend, float2 alphaBlendDepth) 
		{
			// Get our base data
			const float depth = ReShade::GetLinearizedDepth(texcoord);
			float4 color = float4(tex2D(ReShade::BackBuffer, texcoord).rgb, 1.0);

			// Handle the color masking logic.
			const float smoothDelta = maskEnable ? smoothstep(0.0, maskTolerance, pkd::Color::DeltaRGB(color.rgb, maskColor)) : 1.0;
			if (alphaBlend) {
				color.a = smoothDelta;
			}
			else {
				if (smoothDelta >= 1.0) {
					color.a = 1.0;
				}
				else {
					color.a = 0.0;
				}
			}

			// Handle the depth blending logic
			const float relativeDepth = smoothstep(depthRange.x, depthRange.y, depth);
			if (alphaBlend) {
				color.a *= smoothstep(0.0, alphaBlendDepth.x, relativeDepth) * (1.0 - smoothstep(alphaBlendDepth.y, 1.0, relativeDepth));
			}

			// Handle removing anything outside of our depth range
			if (depth < depthRange.x || depth > depthRange.y) {
				color.a *= 0.0;
			}

			return color;			
		}

		float3 PasteLayer(float2 texcoord, sampler sourceSamp, sampler destSamp, int operation, float opacity)
		{
			const float4 source = tex2D(sourceSamp, texcoord);
			const float4 destination = tex2D(destSamp, texcoord);
			if (source.a == 0.0) {
				return destination.rgb;
			}

			float3 result = destination.rgb;

			switch (operation)
			{
				case LAYERCAKE_BLEND_ATOP:
					result = lerp(destination.rgb, source.rgb, source.a * opacity);
					break;
				case LAYERCAKE_BLEND_DARKEN:
					result = lerp(destination.rgb, Darken(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_MULTIPLY:
					result = lerp(destination.rgb, Multiply(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_COLORBURN:
					result = lerp(destination.rgb, ColorBurn(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_LINEARBURN:
					result = lerp(destination.rgb, LinearBurn(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_LIGHTEN:
					result = lerp(destination.rgb, Lighten(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_SCREEN:
					result = lerp(destination.rgb, Screen(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_COLORDODGE:
					result = lerp(destination.rgb, ColorDodge(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_LINEARDODGE:
					result = lerp(destination.rgb, LinearDodge(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_ADDITION:
					result = lerp(destination.rgb, Addition(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_GLOW:
					result = lerp(destination.rgb, Glow(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_OVERLAY:
					result = lerp(destination.rgb, Overlay(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_SOFTLIGHT:
					result = lerp(destination.rgb, SoftLight(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_HARDLIGHT:
					result = lerp(destination.rgb, HardLight(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_VIVIDLIGHT:
					result = lerp(destination.rgb, VividLight(destination.rgb, source.rgb), source.a * opacity);
					break;
				case LAYERCAKE_BLEND_LINEARLIGHT:
					result = lerp(destination.rgb, LinearLight(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_PINLIGHT:
					result = lerp(destination.rgb, PinLight(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_HARDMIX:
					result = lerp(destination.rgb, HardMix(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_DIFFERENCE:
					result = lerp(destination.rgb, Difference(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_EXCLUSION:
					result = lerp(destination.rgb, Exclusion(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_SUBTRACT:
					result = lerp(destination.rgb, Subtract(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_DIVIDE:
					result = lerp(destination.rgb, Divide(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_REFLECT:
					result = lerp(destination.rgb, Reflect(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_GRAINMERGE:
					result = lerp(destination.rgb, GrainMerge(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_GRAINEXTRACT:
					result = lerp(destination.rgb, GrainExtract(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_HUE:
					result = lerp(destination.rgb, Hue(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_SATURATION:
					result = lerp(destination.rgb, Saturation(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_COLORBLEND:
					result = lerp(destination.rgb, ColorB(destination.rgb, source.rgb), source.a * opacity);
					break;				
				case LAYERCAKE_BLEND_LUMINOSITY:
					result = lerp(destination.rgb, Luminosity(destination.rgb, source.rgb), source.a * opacity);
					break;				
			}

			return result;
		}

		// Layer 1
		LAYERCAKE_LAYER_SHADER(PS_Copy_Layer1, PS_Paste_Layer1, CFG_LAYERCAKE_DEPTH_Layer1, CFG_LAYERCAKE_BLEND_Layer1, CFG_LAYERCAKE_OPACITY_Layer1, CFG_LAYERCAKE_MASKENABLE_Layer1, CFG_LAYERCAKE_MASKCOLOR_Layer1, CFG_LAYERCAKE_MASKBLEND_Layer1, CFG_LAYERCAKE_ALPHABLEND_Layer1, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer1, Samp_Layer1)
		LAYERCAKE_LAYER_TECHNIQUES(LayerCake_Layer1_Copy, PS_Copy_Layer1, LayerCake_Layer1_Paste, PS_Paste_Layer1, Tex_Layer1)

		// Layer 2
		LAYERCAKE_LAYER_SHADER(PS_Copy_Layer2, PS_Paste_Layer2, CFG_LAYERCAKE_DEPTH_Layer2, CFG_LAYERCAKE_BLEND_Layer2, CFG_LAYERCAKE_OPACITY_Layer2, CFG_LAYERCAKE_MASKENABLE_Layer2, CFG_LAYERCAKE_MASKCOLOR_Layer2, CFG_LAYERCAKE_MASKBLEND_Layer2, CFG_LAYERCAKE_ALPHABLEND_Layer2, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer2, Samp_Layer2)
		LAYERCAKE_LAYER_TECHNIQUES(LayerCake_Layer2_Copy, PS_Copy_Layer2, LayerCake_Layer2_Paste, PS_Paste_Layer2, Tex_Layer2)

		// Layer 3
		LAYERCAKE_LAYER_SHADER(PS_Copy_Layer3, PS_Paste_Layer3, CFG_LAYERCAKE_DEPTH_Layer3, CFG_LAYERCAKE_BLEND_Layer3, CFG_LAYERCAKE_OPACITY_Layer3, CFG_LAYERCAKE_MASKENABLE_Layer3, CFG_LAYERCAKE_MASKCOLOR_Layer3, CFG_LAYERCAKE_MASKBLEND_Layer3, CFG_LAYERCAKE_ALPHABLEND_Layer3, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer3, Samp_Layer3)
		LAYERCAKE_LAYER_TECHNIQUES(LayerCake_Layer3_Copy, PS_Copy_Layer3, LayerCake_Layer3_Paste, PS_Paste_Layer3, Tex_Layer3)

		// Layer 4
		LAYERCAKE_LAYER_SHADER(PS_Copy_Layer4, PS_Paste_Layer4, CFG_LAYERCAKE_DEPTH_Layer4, CFG_LAYERCAKE_BLEND_Layer4, CFG_LAYERCAKE_OPACITY_Layer4, CFG_LAYERCAKE_MASKENABLE_Layer4, CFG_LAYERCAKE_MASKCOLOR_Layer4, CFG_LAYERCAKE_MASKBLEND_Layer4, CFG_LAYERCAKE_ALPHABLEND_Layer4, CFG_LAYERCAKE_ALPHABLEND_DEPTH_Layer4, Samp_Layer4)
		LAYERCAKE_LAYER_TECHNIQUES(LayerCake_Layer4_Copy, PS_Copy_Layer4, LayerCake_Layer4_Paste, PS_Paste_Layer4, Tex_Layer4)
	}
}