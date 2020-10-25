#include "Reshade.fxh"

/*
ReVeil for Reshade
By: Lord of Lunacy


This shader attempts to remove fog using a dark channel prior technique that has been
refined using 2 passes over an iterative guided Wiener filter ran on the image dark channel.

The purpose of the Wiener filters is to minimize the root mean square error between
the given dark channel, and the true dark channel, making the removal more accurate.

The airlight of the image is estimated by using the max values that appears in the each
window of the dark channel. This window is then averaged together with every mip level
that is larger than the current window size.

Koschmeider's airlight equation is then used to remove the veil from the image, and the inverse
is applied to reverse this affect, blending any new image components with the fog.


This method was adapted from the following paper:
Gibson, Kristofor & Nguyen, Truong. (2013). Fast single image fog removal using the adaptive Wiener filter.
2013 IEEE International Conference on Image Processing, ICIP 2013 - Proceedings. 714-718. 10.1109/ICIP.2013.6738147. 
*/

#ifndef WINDOW_SIZE
	#define WINDOW_SIZE 15
#endif

#if WINDOW_SIZE > 1023
	#undef WINDOW_SIZE
	#define WINDOW_SIZE 1023
#endif

#ifndef SECOND_PASS
	#define SECOND_PASS 0
#endif

#define WINDOW_SIZE_SQUARED (WINDOW_SIZE * WINDOW_SIZE)


#define CONST_LOG2(x) (\
    (uint((x) & 0xAAAAAAAA) != 0) | \
    (uint(((x) & 0xFFFF0000) != 0) << 4) | \
    (uint(((x) & 0xFF00FF00) != 0) << 3) | \
    (uint(((x) & 0xF0F0F0F0) != 0) << 2) | \
    (uint(((x) & 0xCCCCCCCC) != 0) << 1))
	
#define BIT2_LOG2(x) ( (x) | (x) >> 1)
#define BIT4_LOG2(x) ( BIT2_LOG2(x) | BIT2_LOG2(x) >> 2)
#define BIT8_LOG2(x) ( BIT4_LOG2(x) | BIT4_LOG2(x) >> 4)
#define BIT16_LOG2(x) ( BIT8_LOG2(x) | BIT8_LOG2(x) >> 8)

#define FOGREMOVAL_LOG2(x) (CONST_LOG2( (BIT16_LOG2(x) >> 1) + 1))
	    
	

#define FOGREMOVAL_MAX(a, b) (int((a) > (b)) * (a) + int((b) > (a)) * (b))

#define FOGREMOVAL_GET_MAX_MIP(w, h) \
(FOGREMOVAL_LOG2((FOGREMOVAL_MAX((w), (h))) + 1))

#define MAX_MIP (FOGREMOVAL_GET_MAX_MIP(BUFFER_WIDTH * 2 - 1, BUFFER_HEIGHT * 2 - 1))

texture BackBuffer : COLOR;

texture DarkChannel <Pooled = true;> {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};
texture MeanAndVariance <Pooled = true;>{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RG32f;};
texture Mean <Pooled = true;>{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; MipLevels = MAX_MIP;};
texture Variance <Pooled = true;>{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; MipLevels = MAX_MIP;};
texture Airlight {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};
texture Transmission {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};
texture FogRemoved {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f;};
texture TruncatedPrecision {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f;};
texture Maximum0 <Pooled = true;>{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};
texture Maximum1 <Pooled = true;>{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f; MipLevels = MAX_MIP;};

sampler sBackBuffer {Texture = BackBuffer;};
sampler sDarkChannel {Texture = DarkChannel;};
sampler sMeanAndVariance {Texture = MeanAndVariance;};
sampler sMean {Texture = Mean;};
sampler sVariance {Texture = Variance;};
sampler sTransmission {Texture = Transmission;};
sampler sAirlight {Texture = Airlight;};
sampler sTruncatedPrecision {Texture = TruncatedPrecision;};
sampler sFogRemoved {Texture = FogRemoved;};
sampler sMaximum0 {Texture = Maximum0;};
sampler sMaximum1 {Texture = Maximum1;};

uniform float TransmissionMultiplier<
	ui_type = "slider";
	ui_label = "Strength";
	ui_tooltip = "The overall strength of the removal, negative values correspond to more removal,\n"
				"and positive values correspond to less.";
	ui_min = -1; ui_max = 1;
	ui_step = 0.001;
> = -0.125;

uniform float DepthMultiplier<
	ui_type = "slider";
	ui_label = "Depth Sensitivity";
	ui_tooltip = "This setting is for adjusting how much of the removal is depth based, or if\n"
				"positive values are set, it will actually add fog to the scene. 0 means it is\n"
				"unaffected by depth.";
	ui_min = -1; ui_max = 1;
	ui_step = 0.001;
> = -0.075;

uniform float SkyAlpha<
	ui_type = "slider";
	ui_label = "Sky Alpha";
	ui_min = 0; ui_max = 1;
	ui_step = 0.001;
> = 1;


void DarkChannelPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float darkChannel : SV_TARGET0)
{
	float3 color = tex2D(sBackBuffer, texcoord).rgb;
	color = (color);
	
	darkChannel = min(min(color.r, color.g), color.b);
}

void DarkChannelPS1(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float darkChannel : SV_TARGET0)
{
	float3 color = tex2D(sFogRemoved, texcoord).rgb;
	darkChannel = min(min(color.r, color.g), color.b);
}

void MeanAndVariancePS0(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float2 meanAndVariance : SV_TARGET0, out float maximum : SV_TARGET1)
{
	float darkChannel;
	float sum = 0;
	float squaredSum = 0;
	maximum = 0;
	for(int i = -(WINDOW_SIZE / 2); i < ((WINDOW_SIZE + 1) / 2); i++)
	{
			float2 offset = float2(i * BUFFER_RCP_WIDTH, 0);
			darkChannel = tex2D(sDarkChannel, texcoord + offset).r;
			float darkChannelSquared = darkChannel * darkChannel;
			float darkChannelCubed = darkChannelSquared * darkChannel;
			sum += darkChannel;
			squaredSum += darkChannelSquared;
			maximum = max(maximum, darkChannel);
			
	}
	meanAndVariance = float2(sum, squaredSum);
}


void MeanAndVariancePS1(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float mean : SV_TARGET0, out float variance : SV_TARGET1, out float maximum : SV_TARGET2)
{
	float2 meanAndVariance;
	float sum = 0;
	float squaredSum = 0;
	float cubedSum = 0;
	float quadSum = 0;
	maximum = 0;
	for(int i = -(WINDOW_SIZE / 2); i < ((WINDOW_SIZE + 1) / 2); i++)
	{
			float2 offset = float2(0, i * BUFFER_RCP_HEIGHT);
			meanAndVariance = tex2D(sMeanAndVariance, texcoord + offset).rg;
			sum += meanAndVariance.r;
			squaredSum += meanAndVariance.g;
			maximum = max(maximum, tex2D(sMaximum0, texcoord + offset).r);
	}
	float sumSquared = sum * sum;
	
	mean = sum / WINDOW_SIZE_SQUARED;
	variance = (squaredSum - ((sumSquared) / WINDOW_SIZE_SQUARED));
	variance /= WINDOW_SIZE_SQUARED;
}

void MeanAndVariancePS2(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float variance : SV_TARGET0, out float maximum : SV_TARGET1)
{
	float2 meanAndVariance;
	float sum = 0;
	float squaredSum = 0;
	maximum = 0;
	
	for(int i = -(WINDOW_SIZE / 2); i < ((WINDOW_SIZE + 1) / 2); i++)
	{
			float2 offset = float2(0, i * BUFFER_RCP_HEIGHT);
			meanAndVariance = tex2D(sMeanAndVariance, texcoord + offset).rg;
			sum += meanAndVariance.r;
			squaredSum += meanAndVariance.g;
			maximum = max(maximum, tex2D(sMaximum0, texcoord + offset).r);
	}
	float sumSquared = sum * sum;
	
	float mean = sum / WINDOW_SIZE_SQUARED;
	variance = (squaredSum - ((sumSquared) / WINDOW_SIZE_SQUARED));
	variance /= WINDOW_SIZE_SQUARED;
}

void WienerFilterPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float transmission : SV_TARGET0, out float airlight : SV_TARGET1)
{
	float mean = tex2D(sMean, texcoord).r;
	float variance = tex2D(sVariance, texcoord).r;
	float noise = tex2Dlod(sVariance, float4(texcoord, 0, MAX_MIP - 1)).r;
	float darkChannel = tex2D(sDarkChannel, texcoord).r;
	float maximum = 0;
	for(int i = log2(WINDOW_SIZE); i < MAX_MIP; i++)
	{
		maximum += tex2Dlod(sMaximum1, float4(texcoord, 0, i)).r;
	}
	maximum /= MAX_MIP - log2(WINDOW_SIZE);
	
	float filter = saturate((max((variance - noise), 0) / variance) * (darkChannel - mean));
	float veil = saturate(mean + filter);
	//filter = ((variance - noise) / variance) * (darkChannel - mean);
	//mean += filter;
	float usedVariance = variance;
	
	airlight = clamp(maximum, 0.05, 1);//max(saturate(mean + sqrt(usedVariance) * StandardDeviations), 0.05);
	transmission = (1 - ((veil * darkChannel) / airlight));
	transmission *= (exp(DepthMultiplier * ReShade::GetLinearizedDepth(texcoord)));
	transmission *= exp(TransmissionMultiplier);

}

void WienerFilterPS1(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float transmission : SV_TARGET0, out float airlight : SV_TARGET1)
{
	float mean = tex2D(sMean, texcoord).r;
	float variance = tex2D(sVariance, texcoord).r;
	float noise = tex2Dlod(sVariance, float4(texcoord, 0, MAX_MIP - 1)).r;
	float darkChannel = tex2D(sDarkChannel, texcoord).r;
	float maximum = 0;
	for(int i = log2(WINDOW_SIZE); i < MAX_MIP; i++)
	{
		maximum += tex2Dlod(sMaximum1, float4(texcoord, 0, i)).r;
	}
	maximum /= MAX_MIP - log2(WINDOW_SIZE);	
	float filter = saturate((max((variance - noise), 0) / variance) * (darkChannel - mean));
	float veil = saturate(mean + filter);
	//filter = ((variance - noise) / variance) * (darkChannel - mean);
	//mean += filter;
	float usedVariance = variance;
	
	airlight = clamp(maximum, 0.05, 1);//max(saturate(mean + sqrt(usedVariance) * StandardDeviations), 0.05);
	transmission = (1 - ((veil * veil) / airlight));

}

void FogRemovalPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 fogRemoved : SV_TARGET0)
{
	float airlight = tex2D(sAirlight, texcoord).r;
	float transmission = max((tex2D(sTransmission, texcoord).r), 0.05);
	float3 RVBB = tex2D(sBackBuffer, texcoord).rgb; //extracting the BackBuffer Here.
	float y = dot(RVBB, float3(0.299, 0.587, 0.114));
	y = ((y - airlight) / transmission) + airlight;
	float cb = -0.168736 * RVBB.r - 0.331264 * RVBB.g + 0.500000 * RVBB.b;
	float cr = +0.500000 * RVBB.r - 0.418688 * RVBB.g - 0.081312 * RVBB.b;
    float3 color = float3(
        y + 1.402 * cr,
        y - 0.344136 * cb - 0.714136 * cr,
        y + 1.772 * cb);
        
	fogRemoved = float4(color, 1);

}

void OutputToBackbufferPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 fogRemoved : SV_TARGET0)
{
	fogRemoved = float4(tex2D(sFogRemoved, texcoord).rgb, 1);
	if(ReShade::GetLinearizedDepth(texcoord) >= 1)
	{
		fogRemoved = lerp(float4(tex2D(sBackBuffer, texcoord).rgb, 0), fogRemoved, SkyAlpha);
	}
	
	//fogRemoved =  (1 - log( 3 * (tex2D(sTransmission, texcoord).rrrr)));
}

void TruncatedPrecisionPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 truncatedPrecision : SV_TARGET0)
{
	float3 color = tex2D(sBackBuffer, texcoord).rgb;
	float3 fogRemoved = tex2D(sFogRemoved, texcoord).rgb;
	truncatedPrecision = float4(fogRemoved - color, 1);
}
	

void FogReintroductionPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 fogReintroduced : SV_TARGET0)
{
	float airlight = tex2D(sAirlight, texcoord).r;
	float transmission = max((tex2D(sTransmission, texcoord).r), 0.05);
	float3 i = (tex2D(sBackBuffer, texcoord).rgb);
	float3 fogRemoved = tex2D(sFogRemoved, texcoord).rgb;
	
	
	

	i += tex2D(sTruncatedPrecision, texcoord).rgb;
	
	float y = dot(i, float3(0.299, 0.587, 0.114));
	float3 color;
	if(tex2D(sBackBuffer, texcoord).a == 1)
	{
		//i = fogRemoved;
		y = ((y - airlight) * transmission) + airlight;

	
	float cb = -0.168736 * i.r - 0.331264 * i.g + 0.500000 * i.b;
	float cr = +0.500000 * i.r - 0.418688 * i.g - 0.081312 * i.b;
    color = float3(
        y + 1.402 * cr,
        y - 0.344136 * cb - 0.714136 * cr,
        y + 1.772 * cb);
	}
	else color = i;
		
		
	float alpha = 1;
	fogReintroduced = float4(color, 1);
	
}

technique Veil_B_Gone<ui_tooltip = "Place this shader technique before any effects you wish to be placed behind the image veil.\n\n"
									"Veil_B_Back needs to be ran after this technique to reintroduce the image veil. The default\n"
									"WINDOW_SIZE is 15, a smaller size means more performance, but also lower quality. Another \n"
									"important thing to note when changing window sizes is that due to the way mipmaps are used in\n"
									"this shader, whenever the WINDOW_SIZE surpasses a power of 2 (2, 4, 8, 16, 32, etc.), it \n"
									"results in the shader having a massive shift in color and brightness. For this reason its \n"
									"recommended these values be avoided.";>
{
	pass DarkChannel
	{
		VertexShader = PostProcessVS;
		PixelShader = DarkChannelPS;
		RenderTarget0 = DarkChannel;
	}
	
	pass MeanAndVariance
	{
		VertexShader = PostProcessVS;
		PixelShader = MeanAndVariancePS0;
		RenderTarget0 = MeanAndVariance;
		RenderTarget1 = Maximum0;
	}
	
	pass MeanAndVariance
	{
		VertexShader = PostProcessVS;
		PixelShader = MeanAndVariancePS1;
		RenderTarget0 = Mean;
		RenderTarget1 = Variance;
		RenderTarget2 = Maximum1;
	}
	
	pass WienerFilter
	{
		VertexShader = PostProcessVS;
#if SECOND_PASS == 0
		PixelShader = WienerFilterPS;
#else
		PixelShader = WienerFilterPS1;
#endif
		RenderTarget0 = Transmission;
		RenderTarget1 = Airlight;
	}
	
	pass FogRemoval
	{
		VertexShader = PostProcessVS;
		PixelShader = FogRemovalPS;
		RenderTarget0 = FogRemoved;
	}
	
#if SECOND_PASS != 0
	
	pass DarkChannel
	{
		VertexShader = PostProcessVS;
		PixelShader = DarkChannelPS;
		RenderTarget0 = DarkChannel;
	}
	
	pass MeanAndVariance
	{
		VertexShader = PostProcessVS;
		PixelShader = MeanAndVariancePS0;
		RenderTarget0 = MeanAndVariance;
		RenderTarget1 = Maximum0;
	}
	
	pass MeanAndVariance
	{
		VertexShader = PostProcessVS;
		PixelShader = MeanAndVariancePS2;
		RenderTarget0 = Variance;
		RenderTarget1 = Maximum1;
	}
	
	pass WienerFilter
	{
		VertexShader = PostProcessVS;
		PixelShader = WienerFilterPS;
		RenderTarget0 = Transmission;
		RenderTarget1 = Airlight;
	}
	
	pass FogRemoval
	{
		VertexShader = PostProcessVS;
		PixelShader = FogRemovalPS;
		RenderTarget0 = FogRemoved;
	}
#endif
	
	pass BackBuffer
	{
		VertexShader = PostProcessVS;
		PixelShader = OutputToBackbufferPS;
	}
	
	pass TruncatedPrecision
	{
		VertexShader = PostProcessVS;
		PixelShader = TruncatedPrecisionPS;
		RenderTarget = TruncatedPrecision;
	}
}

technique Veil_B_Back<ui_tooltip = "Place this shader technique after Veil_B_Gone and any shaders you want to be veiled.";>
{
	pass FogReintroduction
	{
		VertexShader = PostProcessVS;
		PixelShader = FogReintroductionPS;
	}
}
