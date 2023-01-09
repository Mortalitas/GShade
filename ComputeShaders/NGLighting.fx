//#ifndef NGL_HYBRID_MODE
 #define NGL_HYBRID_MODE 0
//#endif

#include "NGLighting-Shader.fxh"

technique NGLighting<
	ui_label = "NiceGuy Lighting (GI/Reflection)";
	ui_tooltip = "             NiceGuy Lighting 0.9alpha             \n"
				 "                  ||By Ehsan2077||                 \n"
				 "|Optional: Use with qUINT_MotionVectors above this technique in the load order at quarter detail.|\n"
				 "|And    don't   forget    to   read   the   hints.|";
>
{
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = GBuffer1;
		RenderTarget0 = SSSR_NormTex;
		RenderTarget1 = SSSR_MaskRoughTex;
		ColorWriteMask1 = 0x2;
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
#if __RENDERER__ >= 0xa000 // If DX10 or higher
	pass LowResGBuffer
	{
		VertexShader = PostProcessVS;
		PixelShader = CopyGBufferLowRes;
		RenderTarget0 = SSSR_LowResNormTex;
		RenderTarget1 = SSSR_LowResDepthTex;
	}
#endif //RESOLUTION_SCALE
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
		RenderTarget0 = SSSR_MaskRoughTex;
		ColorWriteMask0 = 0x1;
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
		PixelShader   = SpatialFilter0;
		RenderTarget0 = SSSR_FilterTex1;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter1;
		RenderTarget0 = SSSR_FilterTex0;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = SpatialFilter2;
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
		PixelShader   = Output;
	}
}
