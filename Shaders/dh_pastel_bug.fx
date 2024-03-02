////////////////////////////////////////////////////////////////////////////////////////////////
//
// DH_Pastel_Bug (2023-07-09)
//
// The purpoose is to reproduce a cool effect caused by a bug I encountered while working on another shader.
//
// This shader is free, if you paid for it, you have been ripped and should ask for a refund.
//
// This shader is developed by AlucardDH (Damien Hembert)
//
// Get more here : https://github.com/AlucardDH/dh-reshade-shaders
//
////////////////////////////////////////////////////////////////////////////////////////////////
#include "ReShade.fxh"

#define MODE_DARK 0
#define MODE_LIGHT 1

namespace DH_Pastel_Bug {

//// uniform

    uniform int iMode <
        ui_label = "Mode";
        ui_type = "combo";
        ui_items = "Dark\0Light\0";
    > = 0;
	
	uniform float fDarkValue <
		ui_category = "Dark mode";
		ui_label = "Value 1";
        ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 1.0;
	
	uniform float fDarkWhiteLevel <
		ui_category = "Dark mode";
		ui_label = "Value 2";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.9;
	
	uniform float fLightValue <
		ui_category = "Light mode";
		ui_label = "Value 1";
        ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 0.5;
	
	uniform float fLightWhiteLevel <
		ui_category = "Light mode";
		ui_label = "Value 2";
		ui_type = "slider";
	    ui_min = 0.0;
	    ui_max = 1.0;
	    ui_step = 0.001;
	> = 1.0;



//// textures


//// Functions


//// PS

	void PS_PastelBug(float4 vpos : SV_Position, in float2 coords : TEXCOORD0, out float4 outPixel : SV_Target)
	{
		float3 color = tex2D(ReShade::BackBuffer,coords).rgb;
		float brightness = max(color.r,max(color.g,color.b));
		color += (1.0-brightness);

		float whiteLevel;
		float blackLevel;

		if(iMode==MODE_DARK) {
			whiteLevel = min(fDarkWhiteLevel,0.999);
			blackLevel = whiteLevel+max(0.001,fDarkValue)*(1.0-whiteLevel);
		} else if(iMode==MODE_LIGHT) {
			whiteLevel = fLightValue+min(fLightWhiteLevel,0.999)*(1.0-fLightValue);
			blackLevel = min(fLightValue,0.999);
		}

        color = saturate((color-blackLevel)/(whiteLevel-blackLevel));
                
		outPixel = float4(color,1.0);
	}

//// Techniques

	technique DH_Pastel_Bug <
	>
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = PS_PastelBug;
		}
	}

}