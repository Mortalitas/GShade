//
//  Flat Shader - v3.0
//  by Packetdancer
//
//  Outline logic heavily inspired by Alexander Federwisch's awesome Comic.fx,
//  and makes use of his excellent mesh detection logic. The original Comic.fx
//  can be found at https://github.com/Daodan317081/reshade-shaders
//
// 
//  As such, this file is explicitly under BSD license:
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  * Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#include "ReShade.fxh"
#include "pkd_Color.fxh"

#define PKD_FLATSHADE_LEVELMAX 64.0
#define PKD_DEPTHSAMPLES 3

#ifndef MAX2
#define MAX2(v) max(v.x, v.y)
#endif
#ifndef MIN2
#define MIN2(v) min(v.x, v.y)
#endif
#ifndef MAX3
#define MAX3(v) max(v.x, max(v.y, v.z))
#endif
#ifndef MIN3
#define MIN3(v) min(v.x, min(v.y, v.z))
#endif
#ifndef MAX4
#define MAX4(v) max(v.x, max(v.y, max(v.z, v.w)))
#endif
#ifndef MIN4
#define MIN4(v) min(v.x, min(v.y, min(v.z, v.w)))
#endif

namespace pkd {

	namespace FlatShade {

		uniform int CFG_QUANT_ADJUSTORDER <
			ui_type = "combo";
			ui_category = "Flat Shading";
			ui_items = "RGB then Luma\0Luma then RGB\0";
			ui_label = "Order of Operations";
		> = 0;

		uniform float CFG_QUANT_LUMALEVELS <
			ui_type = "slider";
			ui_category = "Flat Shading";
			ui_label = "Luma Steps";
			ui_tooltip = "The number of steps to use when quantizing the RGB values.";
			ui_min = 2.0; ui_max = PKD_FLATSHADE_LEVELMAX; ui_step = 1.0;
		> = 4.0;

		uniform float CFG_QUANT_RGBLEVELS <
			ui_type = "slider";
			ui_category = "Flat Shading";
			ui_label = "RGB Steps";
			ui_tooltip = "The number of steps to use when quantizing the RGB values.";
			ui_min = 2.0; ui_max = PKD_FLATSHADE_LEVELMAX; ui_step = 1.0;
		> = 10.0;

		uniform bool CFG_BACKGROUND_QUANT <
			ui_label = "Isolate Background";
			ui_category = "Flat Shading";
			ui_tooltip = "Should the background be quantized separately from the foreground?";
		> = false;

		uniform float CFG_FOREGROUND_LIMIT <
			ui_type = "slider";
			ui_category = "Flat Shading";
			ui_tooltip = "How far back should the 'foreground' extend?";
			ui_label = "Foreground Depth";
			ui_min = 0; ui_max = 1.0; ui_step = 0.01;
		> = 0.8;

		uniform float CFG_QUANT_LUMALEVELS_BACKGROUND <
			ui_type = "slider";
			ui_category = "Flat Shading";
			ui_label = "Background Luma Steps";
			ui_tooltip = "The number of steps to use when quantizing the RGB values.";
			ui_min = 2.0; ui_max = PKD_FLATSHADE_LEVELMAX; ui_step = 1.0;
		> = PKD_FLATSHADE_LEVELMAX;

		uniform float CFG_QUANT_RGBLEVELS_BACKGROUND <
			ui_type = "slider";
			ui_category = "Flat Shading";
			ui_label = "Background RGB Steps";
			ui_tooltip = "The number of steps to use when quantizing the RGB values of the background.";
			ui_min = 2.0; ui_max = PKD_FLATSHADE_LEVELMAX; ui_step = 1.0;
		> = PKD_FLATSHADE_LEVELMAX;

		uniform bool CFG_OUTLINE_ENABLED <
			ui_category = "Outlines";
			ui_label = "Draw outlines around objects.";
		> = true;

		uniform float3 CFG_OUTLINE_COLOR <
			ui_type = "color";
			ui_label = "Outline Color";
			ui_category = "Outlines";
		> = float3(0.0, 0.0, 0.0);        

		uniform float CFG_OUTLINE_OUTER_WIDTH <
			ui_type = "slider";
			ui_category = "Outlines";
			ui_label = "Angular Difference Line Width";
			ui_tooltip = "The width of the lines generally bordering the exterior of an object.";
			ui_min = 0.0; ui_max = 3.0; ui_step = 1.0;
		> = 3.0;

		uniform float CFG_OUTLINE_INNER_WIDTH <
			ui_type = "slider";
			ui_category = "Outlines";
			ui_label = "Mesh Boundary Width";
			ui_tooltip = "The width of the lines usually within an object's borders.";
			ui_min = 0.0; ui_max = 3.0; ui_step = 1.0;
		> = 1.0;

		uniform int CFG_OUTLINE_FALLOFF <
			ui_type = "combo";
			ui_category = "Outlines";
			ui_items = "No falloff.\0Fade out lines\0Thin lines\0Fadeout and thin lines\0";
			ui_label = "Outline Falloff Type";
		> = 0;

		uniform float CFG_OUTLINE_DEPTH_BOUNDARY_START <
			ui_type = "slider";
			ui_category = "Outlines";
			ui_label = "Boundary for where depth falloff begins.";
			ui_min = 0.1; ui_max = 1.0; ui_step = 0.01;
		> = 0.4;

		uniform float CFG_OUTLINE_DEPTH_BOUNDARY_END <
			ui_type = "slider";
			ui_category = "Outlines";
			ui_label = "Boundary for where depth falloff ends and outlines vanish entirely.";
			ui_min = 0.1; ui_max = 1.0; ui_step = 0.01;
		> = 0.9;

		float SegmentedValue(float v, float level)
		{
			const float stepval = (PKD_FLATSHADE_LEVELMAX / level);
			return (trunc((v * 100) / stepval) * stepval) / 100;
		}

		float3 QuantizeLuma(float3 originalRGB, float levels) 
		{
			const float3 hsl = pkd::Color::RGBToHSL(originalRGB);

			return pkd::Color::HSLToRGB(float3(hsl.x, hsl.y, SegmentedValue(hsl.z, levels)));
		}

		float3 QuantizeRGB(float3 orig, float levels)
		{
			const float grayscale = max(orig.r, max(orig.g, orig.b));

			const float lower = floor(grayscale * levels) / levels;

			float delta;
			if (abs(grayscale - lower))
				delta = lower;
			else
				delta = ceil(grayscale * levels) / levels;

			return orig.rgb * (delta / grayscale);
		}

		float3 PS_Quantize(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
		{
			const float4 orig = tex2D(ReShade::BackBuffer, texcoord);

			float rgblevels = CFG_QUANT_RGBLEVELS;
			float lumalevels = CFG_QUANT_LUMALEVELS;
			if (CFG_BACKGROUND_QUANT && (ReShade::GetLinearizedDepth(texcoord) >= CFG_FOREGROUND_LIMIT)) 
			{
				lumalevels = CFG_QUANT_LUMALEVELS_BACKGROUND;
				rgblevels = CFG_QUANT_RGBLEVELS_BACKGROUND;
			}

			float3 final;

			if (CFG_QUANT_ADJUSTORDER == 0) {
				final = QuantizeLuma(QuantizeRGB(orig.rgb, rgblevels), lumalevels);
			}
			else {
				final = QuantizeRGB(QuantizeLuma(orig.rgb, lumalevels), rgblevels);
			}

			return final;
		}

		// Function taken from Alexander Federwisch's Comic.fx, under BSD license.
		float MeshEdges(float depthC, float4 depth1, float4 depth2) {
			float depthCenter = depthC;
			float4 depthCardinal = float4(depth1.x, depth2.x, depth1.z, depth2.z);
			float4 depthInterCardinal = float4(depth1.y, depth2.y, depth1.w, depth2.w);
			//Calculate the min and max depths
			const float2 mind = float2(MIN4(depthCardinal), MIN4(depthInterCardinal));
			const float2 maxd = float2(MAX4(depthCardinal), MAX4(depthInterCardinal));
			const float span = MAX2(maxd) - MIN2(mind) + 0.00001;

			//Normalize values
			depthCenter /= span;
			depthCardinal /= span;
			depthInterCardinal /= span;
			//Calculate the (depth-wise) distance of the surrounding pixels to the center
			const float4 diffsCardinal = abs(depthCardinal - depthCenter);
			const float4 diffsInterCardinal = abs(depthInterCardinal - depthCenter);
			//Calculate the difference of the (opposing) distances
			const float2 meshEdge = float2(
				max(abs(diffsCardinal.x - diffsCardinal.y), abs(diffsCardinal.z - diffsCardinal.w)),
				max(abs(diffsInterCardinal.x - diffsInterCardinal.y), abs(diffsInterCardinal.z - diffsInterCardinal.w))
			);

			return MAX2(float2(
				max(abs(diffsCardinal.x - diffsCardinal.y), abs(diffsCardinal.z - diffsCardinal.w)),
				max(abs(diffsInterCardinal.x - diffsInterCardinal.y), abs(diffsInterCardinal.z - diffsInterCardinal.w)))
				);
		}

		// Function taken from Alexander Federwisch's Comic.fx, under BSD license.
		float StrengthCurve(float3 fade, float depth) {
			return smoothstep(0.0, 1.0 - fade.z, depth + (0.2 - 1.2 * fade.x)) * smoothstep(0.0, 1.0 - fade.z, 1.0 - depth + (1.2 * fade.y - 1.0));
		}


		float3 PS_Outline(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
		{
			const float2 pixelSize = ReShade::PixelSize;
			const float4 color = tex2D(ReShade::BackBuffer, texcoord);

			if (!CFG_OUTLINE_ENABLED) {
				return color.rgb;
			}

			float centerDepth = ReShade::GetLinearizedDepth(texcoord);
			float4 depth1[PKD_DEPTHSAMPLES];
			float4 depth2[PKD_DEPTHSAMPLES];
			float alpha = 1.0;

			float outerWidth = clamp(CFG_OUTLINE_OUTER_WIDTH, 1.0, PKD_DEPTHSAMPLES);
			float innerWidth = clamp(CFG_OUTLINE_INNER_WIDTH, 1.0, PKD_DEPTHSAMPLES);

			if (CFG_OUTLINE_FALLOFF == 1 || CFG_OUTLINE_FALLOFF == 3) 
			{
				alpha = 1.0 - smoothstep(CFG_OUTLINE_DEPTH_BOUNDARY_START, CFG_OUTLINE_DEPTH_BOUNDARY_END, centerDepth);
			}
			else if (CFG_OUTLINE_FALLOFF == 2 || CFG_OUTLINE_FALLOFF == 3)
			{
				if (centerDepth >= CFG_OUTLINE_DEPTH_BOUNDARY_START) {
					if (centerDepth <= CFG_OUTLINE_DEPTH_BOUNDARY_END) {
						outerWidth = 1.0;
						innerWidth = 0.0;
					}
					else {
						outerWidth = 0.0;
						innerWidth = 0.0;
					}
				}
			}

			bool drawLine = false;
			const int maxWidth = max(outerWidth, innerWidth);

			if (maxWidth > 0.0) {
				[unroll]
				for(int i = 0; i < maxWidth; i++)
				{
					depth1[i] = float4(
						ReShade::GetLinearizedDepth(texcoord+(i+1.0) * float2(0.0, -pixelSize.y)),
						ReShade::GetLinearizedDepth(texcoord+(i+1.0) * float2(pixelSize.x, -pixelSize.y)),
						ReShade::GetLinearizedDepth(texcoord+(i+1.0) * float2(pixelSize.x, 0.0)),
						ReShade::GetLinearizedDepth(texcoord+(i+1.0) * float2(pixelSize.x, pixelSize.y))
					);
					depth2[i]  = float4(
						ReShade::GetLinearizedDepth(texcoord+(i+1.0) * float2(0.0, pixelSize.y)),
						ReShade::GetLinearizedDepth(texcoord+(i+1.0) * float2(-pixelSize.x, pixelSize.y)),
						ReShade::GetLinearizedDepth(texcoord+(i+1.0) * float2(-pixelSize.x, 0.0)),
						ReShade::GetLinearizedDepth(texcoord+(i+1.0) * float2(-pixelSize.x, -pixelSize.y))
					);
				}

				const float threshhold = 22.0 / RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;

				[unroll]
				for (int i = 0; i < CFG_OUTLINE_OUTER_WIDTH; i++)
				{
					const float max1 = max(depth1[i].x, max(depth1[i].y, max(depth1[i].z, depth1[i].w)));
					const float min1 = min(depth1[i].x, min(depth1[i].y, min(depth1[i].z, depth1[i].w)));
					const float max2 = max(depth2[i].x, max(depth2[i].y, max(depth2[i].z, depth2[i].w)));
					const float min2 = min(depth2[i].x, min(depth2[i].y, min(depth2[i].z, depth2[i].w)));

					if (max(max1, max2) - min(min1, min2) >= threshhold )
					{
						drawLine = true;
					} 
				}

				[unroll]
				for (int i = 0; i < CFG_OUTLINE_INNER_WIDTH; i++)
				{
					if ((pow(abs(saturate(MeshEdges(centerDepth, depth1[i], depth2[i]))), 3.0) * 3.0) * StrengthCurve(float3(-1.0, 0.2, 0.8), centerDepth) >= 0.90) 
					{
						drawLine = true;
					}
				}
			}

			if (drawLine) 
			{
				return lerp(color.rgb, CFG_OUTLINE_COLOR, alpha);
			}
			else {
				return color.rgb;
			}
		}

		technique pkd_FlatShade < ui_tooltip = "Reduces the colors of an image in a manner suitable to make a 'flat-shaded' comic-style image."; >
		{
			pass Quantize
			{
				VertexShader = PostProcessVS;
				PixelShader = PS_Quantize;
			}

			pass Outline
			{
				VertexShader = PostProcessVS;
				PixelShader = PS_Outline;
			}
		}
	}
}