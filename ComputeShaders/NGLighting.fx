//#ifndef NGL_HYBRID_MODE
 #define NGL_HYBRID_MODE 0
//#endif

#include "NGLighting-Shader.fxh"

technique NGLighting<
	ui_label = "NiceGuy Lighting (GI/Reflection)";
	ui_tooltip = "             NiceGuy Lighting 0.7alpha             \n"
				 "                  ||By Ehsan2077||                 \n"
				 "|Optional: Use with qUINT_MotionVectors above this technique in the load order at quarter detail.|\n"
				 "|And    don't   forget    to   read   the   hints.|";
>
{
#if NGL_HYBRID_MODE
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = GBuffer1;
		RenderTarget0 = SSSR_NormTex;
	}
#if SMOOTH_NORMALS > 0
	pass SmoothNormalHpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNH;
		RenderTarget = SSSR_NormTex1;
	}
	pass SmoothNormalVpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNV;
		RenderTarget = SSSR_NormTex;
	}
#endif
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = RayMarch;
		RenderTarget0 = SSSR_ReflectionTex;
		RenderTarget1 = SSSR_ReflectionTexD;
		RenderTarget2 = SSSR_HitDistTex;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = TemporalFilter0;
		RenderTarget0 = SSSR_MaskTex;
		RenderTarget1 = SSSR_FilterTex0;
		RenderTarget2 = SSSR_FilterTex0D;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = TemporalFilter1;
		RenderTarget0 = SSSR_FilterTex1;
		RenderTarget1 = SSSR_FilterTex1D;
		RenderTarget2 = SSSR_HLTex0;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter0;
		RenderTarget0 = SSSR_FilterTex0;
		RenderTarget1 = SSSR_FilterTex0D;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter1;
		RenderTarget0 = SSSR_FilterTex1;
		RenderTarget1 = SSSR_FilterTex1D;
		RenderTarget2 = SSSR_PNormalTex;
		RenderTarget3 = SSSR_POGColTex;
		RenderTarget4 = SSSR_HLTex1;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = output;
	}
#else //NGL_HYBRID_MODE
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = GBuffer1;
		RenderTarget0 = SSSR_NormTex;
	}
#if SMOOTH_NORMALS > 0
	pass SmoothNormalHpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNH;
		RenderTarget = SSSR_NormTex1;
	}
	pass SmoothNormalVpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNV;
		RenderTarget = SSSR_NormTex;
	}
#endif //SMOOTH_NORMALS
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = RayMarch;
		RenderTarget0 = SSSR_ReflectionTex;
		RenderTarget1 = SSSR_HitDistTex;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = TemporalFilter0;
		RenderTarget0 = SSSR_MaskTex;
		//RenderTarget1 = SSSR_FilterTex0;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = TemporalFilter1;
		RenderTarget0 = SSSR_FilterTex0;
		RenderTarget1 = SSSR_HLTex0;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter2;
		RenderTarget0 = SSSR_FilterTex1;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter0;
		RenderTarget0 = SSSR_FilterTex0;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter1;
		RenderTarget0 = SSSR_FilterTex1;
		RenderTarget1 = SSSR_PNormalTex;
		RenderTarget2 = SSSR_POGColTex;
		RenderTarget3 = SSSR_HLTex1;
		RenderTarget4 = SSSR_FilterTex2;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = TemporalStabilizer;
		RenderTarget0 = SSSR_FilterTex3;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = output;
	}
#endif //NGL_HYBRID_MODE
}
