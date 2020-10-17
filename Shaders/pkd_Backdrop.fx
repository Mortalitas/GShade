/*
    Simple Bi-Color Backdrop - v1.0
    by Packetdancer
*/

#include "ReShade.fxh"

namespace pkd {

	namespace Backdrop {

		uniform float2 CFG_CHROMAEX_ORIGIN <
			ui_category = "Position";
			ui_label = "Origin Point";
			ui_type = "slider";
			ui_step = 0.001;
			ui_min = 0.000; ui_max = 1.000;
			ui_tooltip = "The X and Y coordinates of the origin point where the divider is based.";
		> = float2(0.5, 0.5);

		uniform float CFG_CHROMAEX_ROTATION <
			ui_category = "Position";
			ui_label = "Rotation Angle";
			ui_type = "slider";
			ui_step = 1;
			ui_min = 0; ui_max = 360;
			ui_tooltip = "What angle should the divider be rotated around the origin point?";
		> = 90;

        uniform float CFG_CHROMAEX_FOREGROUND_LIMIT <
            ui_type = "slider";
            ui_tooltip = "How far back should the 'foreground' extend?";
            ui_label = "Foreground Depth";
            ui_min = 0; ui_max = 1.0; ui_step = 0.01;
        > = 0.8;

		uniform float3 CFG_CHROMAEX_COLOR1 <
			ui_type = "color";
			ui_label = "Color 1";
			ui_category = "Color Settings";
		> = float3(0.0, 0.0, 0.0);

		uniform float3 CFG_CHROMAEX_COLOR2 <
			ui_type = "color";
			ui_label = "Color 2";
			ui_category = "Color Settings";
		> = float3(1.0, 1.0, 1.0);

		uniform bool CFG_CHROMAEX_SMOOTH_DIVIDER <
			ui_label = "Antialias Divider";
			ui_category = "Color Settings";
		> = true;

		float4 GetPosValues(float2 pos)
		{
            return float4(tex2D(ReShade::BackBuffer, pos).rgb, ReShade::GetLinearizedDepth(pos));
		}

	    float3 PS_ChromaEx(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
			if (ReShade::GetLinearizedDepth(texcoord) < CFG_CHROMAEX_FOREGROUND_LIMIT) {
				return tex2D(ReShade::BackBuffer, texcoord).rgb;
			}

			const float s = sin(radians(CFG_CHROMAEX_ROTATION));
			const float c = cos(radians(CFG_CHROMAEX_ROTATION));

			const float2 tempCoord = texcoord - CFG_CHROMAEX_ORIGIN;
			const float2 rotated = float2(tempCoord.x * c - tempCoord.y * s, tempCoord.x * s + tempCoord.y * c) + CFG_CHROMAEX_ORIGIN;

			if (CFG_CHROMAEX_SMOOTH_DIVIDER) {
				const float2 borderSize = ReShade::PixelSize * 0.5;
				if ((rotated.x >= 0.5 - borderSize.x) && (rotated.x <= 0.5 + borderSize.x)) {
					return lerp(CFG_CHROMAEX_COLOR1, CFG_CHROMAEX_COLOR2, (rotated.x - (0.5 - borderSize.x)) / (borderSize.x * 2));
				}
			}

			if (rotated.x <= 0.5) {
				return CFG_CHROMAEX_COLOR1;
			}
			else {
				return CFG_CHROMAEX_COLOR2;
			}
	    }

	    technique pkd_Backdrop
	    {
	    	pass Backdrop {
	    		VertexShader = PostProcessVS;
	    		PixelShader = PS_ChromaEx;
	    	}
	    }
	}

}