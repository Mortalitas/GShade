////////////////////////////////////////////////////////////////////////////////////////////////////////
// Droste.fx by SirCobra
// Version 0.3
// You can find info and my repository here: https://github.com/LordKobra/CobraFX
// This effect warps space inside itself.
////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////
//***************************************                  *******************************************//
//***************************************   UI & Defines   *******************************************//
//***************************************                  *******************************************//
////////////////////////////////////////////////////////////////////////////////////////////////////////

// Shader Start
#include "Reshade.fxh"

// Namespace everything
namespace Droste
{

//defines
#define MASKING_M   "General Options\n"

#ifndef M_PI
	#define M_PI 3.1415927
#endif
#ifndef M_E
	#define M_E 2.71828183
#endif

	//ui
	uniform int Buffer1 <
		ui_type = "radio"; ui_label = " ";
	>;	
	uniform int EffectType <
		ui_type = "radio";
		ui_items = "Hyperdroste\0Droste\0";
		ui_label = "Effect Type";
		ui_category = MASKING_M;
	> = 1;
	uniform bool Spiral <
		ui_tooltip = "Warp space into a spiral.";
		ui_category = MASKING_M;
	> = true;
	uniform float InnerRing <
		ui_type = "slider";
		ui_min = 0.00; ui_max = 1;
		ui_step = 0.01;
		ui_tooltip = "The inner ring defines the texture border towards the center of the screen.";
		ui_category = MASKING_M;
	> = 0.3;
    uniform float OuterRing <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 1;
		ui_step = 0.01;
		ui_tooltip = "The outer ring defines the texture border towards the edge of the screen.";
		ui_category = MASKING_M;
	> = 1.0;
	uniform float Zoom <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 9.9;
		ui_step = 0.01;
		ui_tooltip = "Zoom in the output.";
		ui_category = MASKING_M;
	> = 1.0;
		uniform float Frequency <
		ui_type = "slider";
		ui_min = 0.1; ui_max = 10;
		ui_step = 0.01;
		ui_tooltip = "Defines the frequency of the intervals.";
		ui_category = MASKING_M;
	> = 1.0;
	uniform float X_Offset <
		ui_type = "slider";
		ui_min = -0.5; ui_max = 0.5;
		ui_step = 0.01;
		ui_tooltip = "Change the X position of the center..";
		ui_category = MASKING_M;
	> = 1.0;
	uniform float Y_Offset <
		ui_type = "slider";
		ui_min = -0.5; ui_max = 0.5;
		ui_step = 0.01;
		ui_tooltip = "Change the Y position of the center..";
		ui_category = MASKING_M;
	> = 1.0;
	uniform int Buffer4 <
		ui_type = "radio"; ui_label = " ";
	>;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //***************************************                  *******************************************//
    //*************************************** Helper Functions *******************************************//
    //***************************************                  *******************************************//
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

	//vector mod and normal fmod
	float mod(float x, float y) 
	{
		return x - y * floor(x / y);
	}
    float atan2_approx(float y, float x)
    {
        return acos(x*rsqrt(y*y+x*x))*(y<0 ? -1:1);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //***************************************                  *******************************************//
    //***************************************      Effect      *******************************************//
    //***************************************                  *******************************************//
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

	void droste(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 fragment : SV_Target)
	{
        //transform coordinate system
        const float ar = float(BUFFER_WIDTH) / BUFFER_HEIGHT;
        float new_x = (texcoord.x-0.5+X_Offset)*(EffectType == 0 ? ar:1);
        float new_y = (texcoord.y-0.5+Y_Offset);
		//calculate and normalize angle
		float val = atan2_approx(new_x,new_y)+M_PI;
        val /= 2*M_PI;
		val = Spiral ? val : 0; 
		//calculate distance from center
		float hyperdroste = val + log(sqrt(new_x*new_x+new_y*new_y)*(10-Zoom))*Frequency;
		float droste = val + log(max(abs(new_x),abs(new_y))*(10-Zoom))*Frequency;
        val =  EffectType == 0 ? hyperdroste : droste;
        val = (exp(mod(val, 1))-1)/(M_E-1);

		//fix distortion
		const float y_top = 0.5;// 0.5+Y_Offset;
		const float y_bottom = -0.5;//-0.5+Y_Offset;
		const float x_right = 0.5;//0.5+X_Offset;
		const float x_left = -0.5;//-0.5+X_Offset;
		float nnx = (new_x < 0) ? x_left/new_x : x_right/new_x;
		float nny = (new_y < 0) ? y_bottom/new_y : y_top/new_y;
		float nnc = min(nnx,nny);
		float normalized_x = new_x*nnc+X_Offset;
		float normalized_y = new_y*nnc+Y_Offset;
		//nnc = max(abs(normalized_x), abs(normalized_y))/0.5;
		//rounding
		float d_left = abs(x_left);
		float d_right = abs(x_right);
		float d_top = abs(y_top);
		float d_bottom = abs(y_bottom);
		float d_x = (new_x < 0) ? d_left : d_right;
		float d_y = (new_y < 0) ? d_bottom : d_top;
		float d_final = (abs(new_x)*d_x+abs(new_y)*d_y)/(abs(new_x)+abs(new_y));
		float d_normal = sqrt((normalized_x-X_Offset)*(normalized_x-X_Offset)+(normalized_y-Y_Offset)*(normalized_y-Y_Offset));
		normalized_x = EffectType == 0 ? (normalized_x-X_Offset)*d_final/d_normal+X_Offset : normalized_x;
		normalized_y = EffectType == 0 ? (normalized_y-Y_Offset)*d_final/d_normal+Y_Offset : normalized_y;

		//calculate relative position towards outer and inner ring and interpolate
        const float current_scale = 0.5;// EffectType == 0 ? sqrt(new_x*new_x+new_y*new_y) : max(abs(new_x),abs(new_y));
        float lower_scale = InnerRing*0.5/current_scale;
        float upper_scale = OuterRing*0.5/current_scale;
        float real_scale = (1-val)*lower_scale+val*upper_scale;
        float adjusted_x = EffectType == 0 ? normalized_x/ar*real_scale+0.5-X_Offset : normalized_x*real_scale+0.5-X_Offset;//EffectType == 0 ? new_x/ar*real_scale+0.5-X_Offset : new_x*real_scale+0.5-X_Offset;
        float adjusted_y = normalized_y*real_scale+0.5-Y_Offset;//new_y*real_scale+0.5-Y_Offset;
        fragment = tex2D(ReShade::BackBuffer, float2(adjusted_x, adjusted_y));
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////
	//***************************************                  *******************************************//
	//***************************************     Pipeline     *******************************************//
	//***************************************                  *******************************************//
	////////////////////////////////////////////////////////////////////////////////////////////////////////

	technique Droste < ui_tooltip = "Warp space inside a spiral."; >
	{
		pass spiral_step { VertexShader = PostProcessVS; PixelShader = droste; }
	}

} // Namespace End
