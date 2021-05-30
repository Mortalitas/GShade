
//Gaussian Blur by Ioxa
//Version 1.1 for ReShade 3.0

//Settings
uniform int halationRadius <
	ui_type = "slider";
	ui_min = 0; ui_max = 4;
	ui_label = "Radius";
	ui_tooltip = "[0|1|2|3|4] Adjusts the radius of the effect. Higher values increase the radius.";
> = 0;

uniform float halationOffset <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Offset";
	ui_tooltip = "Additional adjustment for the radius. Values less than 1.00 will reduce the radius.";
> = 1.0;

#include "ReShade.fxh"

texture HalationTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler HalationSamp { Texture = HalationTex; };

texture GaussianBlurHalTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler GaussianBlurHalSampler { Texture = GaussianBlurHalTex; };

float3 red(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	const float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb;

	return saturate(min(((orig.r + orig.g + orig.b) / 3) * float3(1.0, 0.0, 0.0), orig));
}

float3 GaussianBlurH(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float3 color = tex2D(HalationSamp, texcoord).rgb;
	float offset[18];
	float weight[18];

	switch (halationRadius)
	{
		case 0:
			offset = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			weight = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			color *= weight[0];
			[unroll]
			for(int i = 1; i < 4; ++i)
			{
				color += tex2Dlod(HalationSamp, float4(texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(HalationSamp, float4(texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
		case 1:
			offset = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			weight = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			color *= weight[0];
			[unroll]
			for(int i = 1; i < 6; ++i)
			{
				color += tex2Dlod(HalationSamp, float4(texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(HalationSamp, float4(texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
		case 2:
			[unroll]
			offset = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			weight = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			color *= weight[0];
			for(int i = 1; i < 11; ++i)
			{
				color += tex2Dlod(HalationSamp, float4(texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(HalationSamp, float4(texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
		case 3:
			[unroll]
			offset = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386, 0.0, 0.0, 0.0 };
			weight = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913, 0.0, 0.0, 0.0 };
			color *= weight[0];
			[unroll]
			for(int i = 1; i < 15; ++i)
			{
				color += tex2Dlod(HalationSamp, float4(texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(HalationSamp, float4(texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
		case 4:
			offset = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
			weight = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
			color *= weight[0];
			[unroll]
			for(int i = 1; i < 18; ++i)
			{
				color += tex2Dlod(HalationSamp, float4(texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(HalationSamp, float4(texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
	}

	return saturate(color);
}

float3 GaussianBlurV(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float3 color = tex2D(GaussianBlurHalSampler, texcoord).rgb;
	float offset[18];
	float weight[18];

	switch (halationRadius)
	{
		case 0:
			offset = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			weight = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			color *= weight[0];
			[unroll]
			for(int i = 1; i < 4; ++i)
			{
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
		case 1:
			offset = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			weight = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			color *= weight[0];
			[unroll]
			for(int i = 1; i < 6; ++i)
			{
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
		case 2:
			offset = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			weight = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
			color *= weight[0];
			[unroll]
			for(int i = 1; i < 11; ++i)
			{
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
		case 3:
			offset = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386, 0.0, 0.0, 0.0 };
			weight = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913, 0.0, 0.0, 0.0 };
			color *= weight[0];
			[unroll]
			for(int i = 1; i < 15; ++i)
			{
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
		case 4:
			offset = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
			weight = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
			color *= weight[0];
			[unroll]
			for(int i = 1; i < 18; ++i)
			{
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
				color += tex2Dlod(GaussianBlurHalSampler, float4(texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * halationOffset, 0.0, 0.0)).rgb * weight[i];
			}
			break;
	}

	return saturate(max(color, tex2D(ReShade::BackBuffer, texcoord).rgb));
}

technique Halation
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = red;
		RenderTarget = HalationTex;
	}
	pass pass1
	{
		VertexShader = PostProcessVS;
		PixelShader = GaussianBlurH;
		RenderTarget = GaussianBlurHalTex;
	}
	pass pass2
	{
		VertexShader = PostProcessVS;
		PixelShader = GaussianBlurV;
	}
}
