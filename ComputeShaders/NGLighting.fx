#define NGL_HYBRID_MODE 0
#include "NGLighting-Shader.fxh"

technique NGLighting<
	ui_label = "NiceGuy Lighting (GI/Reflection)";
	ui_tooltip = "||           NiceGuy Lighting ||Version 1.0.0              ||\n"
				 "||                       By NiceGuy                        ||\n"
				 "||A free and  lightweight  ray traced GI shader for ReShade||\n"
				 "IMPORTANT NOTICE: Read the Hints before modifying the shader!";
>
{
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = GBuffer1;
		RenderTarget0 = SSSR_NormTex;
		RenderTarget1 = SSSR_RoughTex;
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
#endif //DX9 compatibility
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = RayMarch;
		RenderTarget0 = SSSR_ReflectionTex;
	}
	pass
	{
		VertexShader  = PostProcessVS;
		PixelShader   = TemporalFilter;
		RenderTarget0 = SSSR_FilterTex0;
		RenderTarget1 = SSSR_HLTex0;
	}
	pass{VertexShader = PostProcessVS; PixelShader = SpatialFilter0; RenderTarget0 = SSSR_FilterTex1;}
	pass{VertexShader = PostProcessVS; PixelShader = SpatialFilter1; RenderTarget0 = SSSR_FilterTex0;}
	pass{VertexShader = PostProcessVS; PixelShader = SpatialFilter2; RenderTarget0 = SSSR_FilterTex1;
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
