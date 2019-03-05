
//Clarity by Ioxa
//Version 1.5 for ReShade 3.0

//>Clarity Settings<\\
uniform int ClarityRadiusTwo
<
	ui_type = "slider";
	ui_min = 0; ui_max = 4;
	ui_tooltip = "[0|1|2|3|4] Higher values will increase the radius of the effect.";
	ui_step = 1.00;
> = 3;

uniform float ClarityOffsetTwo
<
	ui_type = "slider";
	ui_min = 1.00; ui_max = 5.00;
	ui_tooltip = "Additional adjustment for the blur radius. Increasing the value will increase the radius.";
	ui_step = 1.00;
> = 2.00;

uniform int ClarityBlendModeTwo
<
	ui_type = "combo";
	ui_items = "\Soft Light\0Overlay\0Hard Light\0Multiply\0Vivid Light\0Linear Light\0Addition";
	ui_tooltip = "Blend modes determine how the clarity mask is applied to the original image";
> = 2;

uniform int ClarityBlendIfDarkTwo
<
	ui_type = "slider";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "Any pixels below this value will be excluded from the effect. Set to 50 to target mid-tones.";
	ui_step = 5;
> = 50;

uniform int ClarityBlendIfLightTwo
<
	ui_type = "slider";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "Any pixels above this value will be excluded from the effect. Set to 205 to target mid-tones.";
	ui_step = 5;
> = 205;

uniform bool ClarityViewBlendIfMaskTwo
<
	ui_tooltip = "The mask used for BlendIf settings. The effect will not be applied to areas covered in black";
> = false;

uniform float ClarityStrengthTwo
<
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Adjusts the strength of the effect";
> = 0.400;

uniform float ClarityDarkIntensityTwo
<
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Adjusts the strength of dark halos.";
> = 0.400;

uniform float ClarityLightIntensityTwo
<
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Adjusts the strength of light halos.";
> = 0.000;

uniform bool ClarityViewMaskTwo
<
	ui_tooltip = "The mask is what creates the effect. View it when making adjustments to get a better idea of how your changes will affect the image.";
> = false;

#include "ReShade.fxh"

texture ClarityTexTwo{ Width = BUFFER_WIDTH*0.5; Height = BUFFER_HEIGHT*0.5; Format = R8; };
texture ClarityTexTwo2{ Width = BUFFER_WIDTH*0.5; Height = BUFFER_HEIGHT*0.5; Format = R8; };
texture ClarityTexTwo3{ Width = BUFFER_WIDTH*0.25; Height = BUFFER_HEIGHT*0.25; Format = R8; };

sampler ClaritySamplerTwo { Texture = ClarityTexTwo;};
sampler ClaritySamplerTwo2 { Texture = ClarityTexTwo2;};
sampler ClaritySamplerTwo3 { Texture = ClarityTexTwo3;};

float3 ClarityFinalTwo(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{

	float color = tex2D(ClaritySamplerTwo3, texcoord).r;
	
if(ClarityRadiusTwo == 0)	
{
	float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2D(ClaritySamplerTwo3, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
		color += tex2D(ClaritySamplerTwo3, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
	}
}	

if(ClarityRadiusTwo == 1)	
{
	float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2D(ClaritySamplerTwo3, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
		color += tex2D(ClaritySamplerTwo3, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
	}
}	

if(ClarityRadiusTwo == 2)	
{
	float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2D(ClaritySamplerTwo3, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
		color += tex2D(ClaritySamplerTwo3, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
	}
}	

if(ClarityRadiusTwo == 3)	
{
	float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
	float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2D(ClaritySamplerTwo3, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
		color += tex2D(ClaritySamplerTwo3, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
	}
}

if(ClarityRadiusTwo == 4)	
{
	float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(ClaritySamplerTwo3, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
		color += tex2D(ClaritySamplerTwo3, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r * weight[i];
	}
}	
	
	float3 orig = tex2D(ReShade::BackBuffer, texcoord).rgb; //Original Image
	float luma = dot(orig.rgb,float3(0.32786885,0.655737705,0.0163934436));
	float3 chroma = orig.rgb/luma;
	
	float sharp = 1-color;
	sharp = (luma+sharp)*0.5;
	
	float sharpMin = lerp(0.0,1.0,smoothstep(0.0,1.0,sharp));
	float sharpMax = sharpMin;
	sharpMin = lerp(sharp,sharpMin,ClarityDarkIntensityTwo);
	sharpMax = lerp(sharp,sharpMax,ClarityLightIntensityTwo);
	sharp = lerp(sharpMin,sharpMax,step(0.5,sharp));

	if(ClarityViewMaskTwo)
	{
		orig.rgb = sharp;
		luma = sharp;
		chroma = 1.0;
	}
	else
	{
		if(ClarityBlendModeTwo == 0)
		{
			//softlight
			sharp = lerp(2*luma*sharp + luma*luma*(1.0-2*sharp), 2*luma*(1.0-sharp)+pow(luma,0.5)*(2*sharp-1.0), step(0.49,sharp));
		}
		
		if(ClarityBlendModeTwo == 1)
		{
			//overlay
			sharp = lerp(2*luma*sharp, 1.0 - 2*(1.0-luma)*(1.0-sharp), step(0.50,luma));
		}
		
		if(ClarityBlendModeTwo == 2)
		{
			//Hardlight
			sharp = lerp(2*luma*sharp, 1.0 - 2*(1.0-luma)*(1.0-sharp), step(0.50,sharp));
		}
		
		if(ClarityBlendModeTwo == 3)
		{
			//Multiply
			sharp = saturate(2 * luma * sharp);
		}
		
		if(ClarityBlendModeTwo == 4)
		{
			//vivid light
			sharp = lerp(2*luma*sharp, luma/(2*(1-sharp)), step(0.5,sharp));
		}
		
		if(ClarityBlendModeTwo == 5)
		{
			//Linear Light
			sharp = luma + 2.0*sharp-1.0;
		}
		
		if(ClarityBlendModeTwo == 6)
		{
			//Addition
			sharp = saturate(luma + (sharp - 0.5));
		}
	}
	
	if( ClarityBlendIfDarkTwo > 0 || ClarityBlendIfLightTwo < 255 || ClarityViewBlendIfMaskTwo)
	{
		float ClarityBlendIfD = (ClarityBlendIfDarkTwo/255.0)+0.0001;
		float ClarityBlendIfL = (ClarityBlendIfLightTwo/255.0)-0.0001;
		float mix = dot(orig.rgb, 0.333333);
		float mask = 1.0;
		
		if(ClarityBlendIfDarkTwo > 0)
		{
			mask = lerp(0.0,1.0,smoothstep(ClarityBlendIfD-(ClarityBlendIfD*0.2),ClarityBlendIfD+(ClarityBlendIfD*0.2),mix));
		}
						
		if(ClarityBlendIfLightTwo < 255)
		{
			mask = lerp(mask,0.0,smoothstep(ClarityBlendIfL-(ClarityBlendIfL*0.2),ClarityBlendIfL+(ClarityBlendIfL*0.2),mix));
		}
			
		sharp = lerp(luma,sharp,mask);
		
		if (ClarityViewBlendIfMaskTwo)
		{
			sharp = mask;
			luma = mask;
			chroma = 1.0;
		}
	}
					
	orig.rgb = lerp(luma, sharp, ClarityStrengthTwo);
	orig.rgb *= chroma;
		
	return saturate(orig);
}	

float Clarity1Two(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	
if(ClarityRadiusTwo == 0)	
{
	float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
	}
}	

if(ClarityRadiusTwo == 1)	
{
	float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
	}
}	

if(ClarityRadiusTwo == 2)	
{
	float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
	}
}	

if(ClarityRadiusTwo == 3)	
{
	float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
	float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
	}
}	

if(ClarityRadiusTwo == 4)	
{
	float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).rgb * weight[i];
	}
}	
	
	return dot(color.rgb,float3(0.32786885,0.655737705,0.0163934436));
}

float Clarity2Two(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float color = tex2D(ClaritySamplerTwo, texcoord).r;
	
if(ClarityRadiusTwo == 0)	
{
	float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2D(ClaritySamplerTwo, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
	}
}	

if(ClarityRadiusTwo == 1)	
{
	float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2D(ClaritySamplerTwo, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
	}
}	

if(ClarityRadiusTwo == 2)	
{
	float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2D(ClaritySamplerTwo, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
	}
}	

if(ClarityRadiusTwo == 3)	
{
	float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
	float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2D(ClaritySamplerTwo, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
	}
}

if(ClarityRadiusTwo == 4)	
{
	float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(ClaritySamplerTwo, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * ClarityOffsetTwo).r* weight[i];
	}
}	

	return color;
}

float Clarity3Two(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	float color = tex2D(ClaritySamplerTwo2, texcoord).r;
	
if(ClarityRadiusTwo == 0)	
{
	float offset[4] = { 0.0, 1.1824255238, 3.0293122308, 5.0040701377 };
	float weight[4] = { 0.39894, 0.2959599993, 0.0045656525, 0.00000149278686458842 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 4; ++i)
	{
		color += tex2D(ClaritySamplerTwo2, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo2, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
	}
}	

if(ClarityRadiusTwo == 1)	
{
	float offset[6] = { 0.0, 1.4584295168, 3.40398480678, 5.3518057801, 7.302940716, 9.2581597095 };
	float weight[6] = { 0.13298, 0.23227575, 0.1353261595, 0.0511557427, 0.01253922, 0.0019913644 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 6; ++i)
	{
		color += tex2D(ClaritySamplerTwo2, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo2, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
	}
}	

if(ClarityRadiusTwo == 2)	
{
	float offset[11] = { 0.0, 1.4895848401, 3.4757135714, 5.4618796741, 7.4481042327, 9.4344079746, 11.420811147, 13.4073334, 15.3939936778, 17.3808101174, 19.3677999584 };
	float weight[11] = { 0.06649, 0.1284697563, 0.111918249, 0.0873132676, 0.0610011113, 0.0381655709, 0.0213835661, 0.0107290241, 0.0048206869, 0.0019396469, 0.0006988718 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 11; ++i)
	{
		color += tex2D(ClaritySamplerTwo2, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo2, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
	}
}	

if(ClarityRadiusTwo == 3)	
{
	float offset[15] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4401038149, 21.43402885, 23.4279736431, 25.4219399344, 27.4159294386 };
	float weight[15] = { 0.0443266667, 0.0872994708, 0.0820892038, 0.0734818355, 0.0626171681, 0.0507956191, 0.0392263968, 0.0288369812, 0.0201808877, 0.0134446557, 0.0085266392, 0.0051478359, 0.0029586248, 0.0016187257, 0.0008430913 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 15; ++i)
	{
		color += tex2D(ClaritySamplerTwo2, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo2, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
	}
}	

if(ClarityRadiusTwo == 4)	
{
	float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(ClaritySamplerTwo2, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
		color += tex2D(ClaritySamplerTwo2, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * ClarityOffsetTwo).r* weight[i];
	}
}	
	
	return color;
}

technique Clarity2
{
	pass Clarity1Two
	{
		VertexShader = PostProcessVS;
		PixelShader = Clarity1Two;
		RenderTarget = ClarityTexTwo;
	}
	
	pass Clarity2Two
	{
		VertexShader = PostProcessVS;
		PixelShader = Clarity2Two;
		RenderTarget = ClarityTexTwo2;
	}
	
	pass Clarity3Two
	{
		VertexShader = PostProcessVS;
		PixelShader = Clarity3Two;
		RenderTarget = ClarityTexTwo3;
	}
	
	pass ClarityFinalTwo
	{
		VertexShader = PostProcessVS;
		PixelShader = ClarityFinalTwo;
	}
}
