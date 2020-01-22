/*------------------.
| :: Description :: |
'-------------------/

	Copyright based on Layer (version 0.3)

	Authors: CeeJay.dk, seri14, Marot Satil
	License: MIT

	History:
	(*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
	
	Version 0.2 by seri14 & Marot Satil
    * Added the ability to scale and move the layer around on an x, y axis.
	
	Version 0.3
	* Added a number of copyright textures for Phantasty Star Online 2 created by Uchu Suzume.
*/

#include "ReShade.fxh"

uniform int cLayer_Select <
    ui_label = "Layer Selection";
    ui_tooltip = "The image/texture you'd like to use.";
    ui_type = "combo";
    ui_items= "FFXIV Horizontal\0FFXIV Vertical\0FFXIV Nalukai Horizontal\0FFXIV Yomi Black Horizontal\0FFXIV Yomi White Horizontal\0PSO2 Horizontal\0PSO2 Vertical\0PSO2 with GShade Black Horizontal\0PSO2 with GShade Black Vertical\0PSO2 with GShade White Horizontal\0PSO2 with GShade White Vertical\0PSO2 with GShade Horizontal\0PSO2 Eurostyle Left Horizontal\0PSO2 Eurostyle Left Vertical\0PSO2 Eurostyle Right Horizontal\0PSO2 Eurostyle Right Vertical\0PSO2 Futura Center Horizontal\0PSO2 Futura Center Vertical\0PSO2 Futura Tri Black Horizontal\0PSO2 Futura Tri Black Vertical\0PSO2 Futura Tri White Horizontal\0PSO2 Futura Tri White Vertical\0PSO2 Rockwell Nova Black Horizontal\0PSO2 Rockwell Nova Black Vertical\0PSO2 Rockwell Nova White Horizontal\0PSO2 Rockwell Nova White Vertical\0PSO2 Swis721 Square Black Horizontal\0PSO2 Swis721 Square Black Vertical\0PSO2 Swis721 Square White Horizontal\0PSO2 Swis721 Square White Vertical\0PSO2 Swiss911 Horizontal\0PSO2 Swiss911 Vertical\0";
> = 0;

uniform float cLayer_Blend <
    ui_label = "Opacity";
    ui_tooltip = "The transparency of the copyright notice.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float cLayer_Scale <
    ui_type = "slider";
  	ui_label = "Scale";
	  ui_min = 0.01; ui_max = 3.0;
	  ui_step = 0.001;
> = 1.001;

uniform float cLayer_PosX <
    ui_type = "slider";
  	ui_label = "Position X";
  	ui_min = -4.0; ui_max = 4.0;
  	ui_step = 0.001;
> = 0.5;

uniform float cLayer_PosY <
    ui_type = "slider";
  	ui_label = "Position Y";
  	ui_min = -4.0; ui_max = 4.0;
	  ui_step = 0.001;
> = 0.5;

texture Horiz_xiv_fourk_texture <source="Copyright4kH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_WIDTH; Format=RGBA8; };
sampler Horiz_xiv_fourk_sampler { Texture = Horiz_xiv_fourk_texture; };

texture Verti_xiv_fourk_texture <source="Copyright4kV.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_xiv_fourk_sampler { Texture = Verti_xiv_fourk_texture; };

texture Horiz_xiv_fancy_fourk_texture <source="CopyrightF4kH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_xiv_fancy_fourk_sampler { Texture = Horiz_xiv_fancy_fourk_texture; };

texture Horiz_xiv_yomi_b_texture <source="CopyrightYBlH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_xiv_yomi_b_sampler { Texture = Horiz_xiv_yomi_b_texture; };

texture Horiz_xiv_yomi_w_texture <source="CopyrightYWhH.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_xiv_yomi_w_sampler { Texture = Horiz_xiv_yomi_w_texture; };

texture Horiz_pso2_texture <source="copyright_pso2.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_sampler { Texture = Horiz_pso2_texture; };

texture Verti_pso2_texture <source="copyright_pso2_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_sampler { Texture = Verti_pso2_texture; };

texture Horiz_pso2_gs_b_texture <source="copyright_pso2_by_gshade.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_gs_b_sampler { Texture = Horiz_pso2_gs_b_texture; };

texture Verti_pso2_gs_b_texture <source="copyright_pso2_by_gshade_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_gs_b_sampler { Texture = Verti_pso2_gs_b_texture; };

texture Horiz_pso2_gs_w_texture <source="copyright_pso2_by_gshade_w.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_gs_w_sampler { Texture = Horiz_pso2_gs_w_texture; };

texture Verti_pso2_gs_w_texture <source="copyright_pso2_by_gshade_w_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_gs_w_sampler { Texture = Verti_pso2_gs_w_texture; };

texture Horiz_pso2_gs_texture <source="copyright_pso2_by_GShade_r.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_gs_sampler { Texture = Horiz_pso2_gs_texture; };

texture Horiz_pso2_eu_l_texture <source="copyright_pso2_Eurostyle_left.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_eu_l_sampler { Texture = Horiz_pso2_eu_l_texture; };

texture Verti_pso2_eu_l_texture <source="copyright_pso2_Eurostyle_left_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_eu_l_sampler { Texture = Verti_pso2_eu_l_texture; };

texture Horiz_pso2_eu_r_texture <source="copyright_pso2_Eurostyle_right.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_eu_r_sampler { Texture = Horiz_pso2_eu_r_texture; };

texture Verti_pso2_eu_r_texture <source="copyright_pso2_Eurostyle_right_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_eu_r_sampler { Texture = Verti_pso2_eu_r_texture; };

texture Horiz_pso2_fu_c_texture <source="copyright_pso2_futura_center.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_fu_c_sampler { Texture = Horiz_pso2_fu_c_texture; };

texture Verti_pso2_fu_c_texture <source="copyright_pso2_futura_center_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_fu_c_sampler { Texture = Verti_pso2_fu_c_texture; };

texture Horiz_pso2_fu_t_b_texture <source="copyright_pso2_futura_tri_b.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_fu_t_b_sampler { Texture = Horiz_pso2_fu_t_b_texture; };

texture Verti_pso2_fu_t_b_texture <source="copyright_pso2_futura_tri_b_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_fu_t_b_sampler { Texture = Verti_pso2_fu_t_b_texture; };

texture Horiz_pso2_fu_t_w_texture <source="copyright_pso2_futura_tri_w.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_fu_t_w_sampler { Texture = Horiz_pso2_fu_t_w_texture; };

texture Verti_pso2_fu_t_w_texture <source="copyright_pso2_futura_tri_w_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_fu_t_w_sampler { Texture = Verti_pso2_fu_t_w_texture; };

texture Horiz_pso2_ron_b_texture <source="copyright_pso2_Rockwell_nova_b.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_ron_b_sampler { Texture = Horiz_pso2_ron_b_texture; };

texture Verti_pso2_ron_b_texture <source="copyright_pso2_Rockwell_nova_b_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_ron_b_sampler { Texture = Verti_pso2_ron_b_texture; };

texture Horiz_pso2_ron_w_texture <source="copyright_pso2_Rockwell_nova_w.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_ron_w_sampler { Texture = Horiz_pso2_ron_w_texture; };

texture Verti_pso2_ron_w_texture <source="copyright_pso2_Rockwell_nova_w_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_ron_w_sampler { Texture = Verti_pso2_ron_w_texture; };

texture Horiz_pso2_swis_s_b_texture <source="copyright_pso2_Swis721_square_b.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_swis_s_b_sampler { Texture = Horiz_pso2_swis_s_b_texture; };

texture Verti_pso2_swis_s_b_texture <source="copyright_pso2_Swis721_square_b_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_swis_s_b_sampler { Texture = Verti_pso2_swis_s_b_texture; };

texture Horiz_pso2_swis_s_w_texture <source="copyright_pso2_Swis721_square_w.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_swis_s_w_sampler { Texture = Horiz_pso2_swis_s_w_texture; };

texture Verti_pso2_swis_s_w_texture <source="copyright_pso2_Swis721_square_w_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_swis_s_w_sampler { Texture = Verti_pso2_swis_s_w_texture; };

texture Horiz_pso2_swiss_texture <source="copyright_pso2_Swiss911_UCm_BT_Cn.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Horiz_pso2_swiss_sampler { Texture = Horiz_pso2_swiss_texture; };

texture Verti_pso2_swiss_texture <source="copyright_pso2_Swiss911_UCm_BT_Cn_v.png";> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Verti_pso2_swiss_sampler { Texture = Verti_pso2_swiss_texture; };

void PS_cLayer(in float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target) {
    const float4 backbuffer = tex2D(ReShade::BackBuffer, texcoord);
    const float2 cLayer_Pos = float2(cLayer_PosX, cLayer_PosY);

    float2 scale;
    float4 cLayer;

    switch(cLayer_Select)
    {
        // FFXIV Horizontal Vanilla
        default: 
            scale = 1.0 / (float2(411.0, 22.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_xiv_fourk_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // FFXIV Vertical Vanilla
        case 1:
            scale = 1.0 / (float2(22.0, 412.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_xiv_fourk_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // FFXIV Nalukai Horizontal
        case 2:
            scale = 1.0 / (float2(1162.0, 135.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_xiv_fancy_fourk_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // FFXIV Yomi Black Horizontal
        case 3:
            scale = 1.0 / (float2(1162.0, 135.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_xiv_yomi_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // FFXIV Yomi White Horizontal
        case 4:
            scale = 1.0 / (float2(1162.0, 135.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_xiv_yomi_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Horizontal
        case 5:
            scale = 1.0 / (float2(435.0, 31.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Vertical
        case 6:
            scale = 1.0 / (float2(31.0, 435.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 with GShade Black Horizontal
        case 7:
            scale = 1.0 / (float2(1280.0, 66.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_gs_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 with GShade Black Vertical
        case 8:
            scale = 1.0 / (float2(66.0, 1280.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_gs_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 with GShade White Horizontal
        case 9:
            scale = 1.0 / (float2(1280.0, 66.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_gs_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 with GShade White Vertical
        case 10:
            scale = 1.0 / (float2(66.0, 1280.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_gs_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 with GShade
        case 11:
            scale = 1.0 / (float2(300.0, 128.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_gs_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Eurostyle Left Horizontal
        case 12:
            scale = 1.0 / (float2(800.0, 183.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_eu_l_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Eurostyle Left Vertical
        case 13:
            scale = 1.0 / (float2(183.0, 800.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_eu_l_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Eurostyle Right Horizontal
        case 14:
            scale = 1.0 / (float2(800.0, 183.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_eu_r_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Eurostyle Right Vertical
        case 15:
            scale = 1.0 / (float2(183.0, 800.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_eu_r_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Futura Center Horizontal
        case 16:
            scale = 1.0 / (float2(535.0, 134.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_fu_c_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Futura Center Vertical
        case 17:
            scale = 1.0 / (float2(134.0, 535.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_fu_c_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Futura Tri Black Horizontal
        case 18:
            scale = 1.0 / (float2(319.0, 432.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_fu_t_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Futura Tri Black Vertical
        case 19:
            scale = 1.0 / (float2(432.0, 319.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_fu_t_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Futura Tri White Horizontal
        case 20:
            scale = 1.0 / (float2(319.0, 432.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_fu_t_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Futura Tri White Vertical
        case 21:
            scale = 1.0 / (float2(432.0, 319.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_fu_t_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Rockwell Nova Black Horizontal
        case 22:
            scale = 1.0 / (float2(471.0, 122.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_ron_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Rockwell Nova Black Vertical
        case 23:
            scale = 1.0 / (float2(122.0, 471.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_ron_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Rockwell Nova White Horizontal
        case 24:
            scale = 1.0 / (float2(471.0, 122.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_ron_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Rockwell Nova White Vertical
        case 25:
            scale = 1.0 / (float2(122.0, 471.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_ron_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Swis721 Square Black Horizontal
        case 26:
            scale = 1.0 / (float2(261.0, 285.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_swis_s_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Swis721 Square Black Vertical
        case 27:
            scale = 1.0 / (float2(285.0, 261.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_swis_s_b_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Swis721 Square White Horizontal
        case 28:
            scale = 1.0 / (float2(261.0, 285.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_swis_s_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Swis721 Square White Vertical
        case 29:
            scale = 1.0 / (float2(285.0, 261.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_swis_s_w_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Swiss911 Horizontal
        case 30:
            scale = 1.0 / (float2(540.0, 54.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Horiz_pso2_swiss_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
        // PSO2 Swiss911 Vertical
        case 31:
            scale = 1.0 / (float2(54.0, 540.0) / BUFFER_SCREEN_SIZE * cLayer_Scale);
            cLayer  = tex2D(Verti_pso2_swiss_sampler, texcoord * scale + (1.0 - scale) * cLayer_Pos);
  	        color = lerp(backbuffer, cLayer, cLayer.a * cLayer_Blend);
            break;
    }
    color.a = backbuffer.a;
}

technique Copyright {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_cLayer;
    }
}