/*
This shader makes use of the scatter capabilities of a compute shader to perform an adaptive IIR filter rather than
the traditional FIR filters normally used in image processing.

BilateralCS
*/

#define COMPUTE 1
#define DIVIDE_ROUNDING_UP(n, d) uint(((n) + (d) - 1) / (d))
#define FILTER_WIDTH 32
#define PIXELS_PER_THREAD 128
#define H_GROUPS uint2((DIVIDE_ROUNDING_UP(BUFFER_WIDTH, PIXELS_PER_THREAD) * 2), DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, 64))
#define V_GROUPS uint2(DIVIDE_ROUNDING_UP(BUFFER_WIDTH, 64), (DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, PIXELS_PER_THREAD) * 2))
#define H_GROUP_SIZE uint2(1, 64)
#define V_GROUP_SIZE uint2(64, 1)
#define PI 3.1415962

#if __RESHADE__ >= 50000
	#define POOLED true
#else
	#define POOLED false
#endif

#if __RENDERER__ < 0xb000
	#warning "DX9 and DX10 APIs are unsupported by compute"
	#undef COMPUTE
	#define COMPUTE 0
#endif

#if __RESHADE__ < 50000 && __RENDERER__ == 0xc000
	#warning "Due to a bug in the current version of ReShade, this shader is disabled in DX12 until the release of ReShade 5.0."
	#undef COMPUTE
	#define COMPUTE 0
#endif

#if COMPUTE != 0
namespace Spatial_IIR_Bilateral
{
	texture BackBuffer:COLOR;
	texture Temp0 <Pooled = POOLED;>{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGB10A2;};
	texture Temp1 <Pooled = POOLED;>{Width = BUFFER_WIDTH * 2; Height = BUFFER_HEIGHT; Format = RGB10A2;};

	sampler sBackBuffer{Texture = BackBuffer;};
	sampler sTemp0 {Texture = Temp0;};
	sampler sTemp1{Texture = Temp1;};
	
	
	storage wTemp0{Texture = Temp0;};
	storage wTemp1{Texture = Temp1;};
	
	uniform float Strength<
		ui_type = "slider";
		ui_label = "Strength";
		ui_min = 0; ui_max = 2;
		ui_step = 0.001;
	> = 1;
	
	uniform bool Sharpen = false;
	
	uniform float WeightExponent<
		ui_type = "slider";
		ui_label = "Bilateral Width";
		ui_tooltip = "Use this slider to adjust the width of the bilateral";
		ui_min = 10; ui_max = 50;
	> = 30;
	
	// Vertex shader generating a triangle covering the entire screen
	void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

	void Temp0PS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float Temp0 : SV_Target0)
	{
		Temp0 = dot(tex2D(sBackBuffer, texcoord).rgb, float3(0.299, 0.587, 0.114));
	}
	
	void CombinePS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 output : SV_Target0)
	{
		texcoord.x /= 2;
		output = (tex2D(sTemp1, texcoord) + tex2D(sTemp1, float2(texcoord.x + 0.5, texcoord.y))) * 0.5;//dot(tex2D(sBackBuffer, texcoord).rgb, float3(0.299, 0.587, 0.114));
		output.w = 1;
	}
	
	void HorizontalFilterCS0(uint3 id : SV_DispatchThreadID)
	{
		if(id.x < (H_GROUPS.x / 2))
		{
			float2 coord = float2(id.x * PIXELS_PER_THREAD, id.y);
			float3 curr;
			float3 prev;
			float3 weight;
			prev = tex2Dfetch(sBackBuffer, float2(coord.x - FILTER_WIDTH, coord.y)).xyz;
			for(int i = -FILTER_WIDTH + 1; i < PIXELS_PER_THREAD; i++)
			{
				curr = tex2Dfetch(sBackBuffer, float2(coord.x + i, coord.y)).xyz;
				weight = 1 - abs(curr - prev);
				weight = pow(abs(weight), WeightExponent);
				prev = lerp(curr, prev, weight);
				if(i >= 0  && (coord.x + i) < BUFFER_WIDTH)
				{
					tex2Dstore(wTemp1, int2(coord.x + i, coord.y), prev.xyzx);
				}
			}
		}
		else
		{
			float2 coord = float2((id.x - (H_GROUPS.x / 2)) * PIXELS_PER_THREAD + PIXELS_PER_THREAD, id.y);
			float3 curr;
			float3 prev;
			float3 weight;
			prev = tex2Dfetch(sBackBuffer, float2(coord.x + FILTER_WIDTH, coord.y)).xyz;
			for(int i = FILTER_WIDTH - 1; i > -PIXELS_PER_THREAD; i--)
			{
				curr = tex2Dfetch(sBackBuffer, float2(coord.x + i, coord.y)).xyz;
				weight = 1 - abs(curr - prev);
				weight = pow(abs(weight), WeightExponent);
				prev = lerp(curr, prev, weight);
				if(i <= 0)
				{
					tex2Dstore(wTemp1, int2(BUFFER_WIDTH + coord.x + i, coord.y), prev.xyzx);
				}
			}
		}
	}
	
	void VerticalFilterCS0(uint3 id : SV_DispatchThreadID, uint3 tid : SV_GroupThreadID)
	{
		if(id.y < (V_GROUPS.y / 2))
		{
			float2 coord = float2(id.x, id.y * PIXELS_PER_THREAD);
			float3 curr;
			float3 prev;
			float3 weight;
			prev = tex2Dfetch(sTemp0, float2(coord.x, coord.y - FILTER_WIDTH)).xyz;
			if(coord.x < BUFFER_WIDTH)
			{
				for(int i = -FILTER_WIDTH + 1; i < PIXELS_PER_THREAD; i++)
				{
					curr = tex2Dfetch(sTemp0, float2(coord.x, coord.y + i)).xyz;
					weight = 1 - abs(curr - prev);
					weight = pow(abs(weight), WeightExponent);
					prev = lerp(curr, prev, weight);
					if(i >= 0)
					{
						tex2Dstore(wTemp1, int2(coord.x, coord.y + i), float4(prev.xyz, 1));
					}
				}
			}
		}
		else
		{
			float2 coord = float2(id.x, (id.y - (V_GROUPS.y / 2)) * PIXELS_PER_THREAD + PIXELS_PER_THREAD);
			float3 curr;
			float3 prev;
			float3 weight;
			prev = tex2Dfetch(sTemp0, float2(coord.x, coord.y + FILTER_WIDTH)).xyz;
			for(int i = FILTER_WIDTH - 1; i > -PIXELS_PER_THREAD; i--)
			{
				curr = tex2Dfetch(sTemp0, float2(coord.x, coord.y + i)).xyz;
				weight = 1 - abs(curr - prev);
				weight = pow(abs(weight), WeightExponent);
				prev = lerp(curr, prev, weight);
				if(i <= 0)
				{
					tex2Dstore(wTemp1, int2(BUFFER_WIDTH + coord.x, coord.y + i), float4(prev.xyz, 1));
				}
			}
		}
	}
	
	void OutputPS(float4 vpos : SV_POSITION, float2 texcoord : TEXCOORD, out float4 output : SV_TARGET0)
	{	
		float3 color = tex2D(sBackBuffer, texcoord).rgb;
		texcoord.x /= 2;
		float3 blur = (tex2D(sTemp1, texcoord).rgb + tex2D(sTemp1, float2(texcoord.x + 0.5, texcoord.y)).rgb) * 0.5;
		float alpha = (Sharpen) ? -Strength : Strength;
		output.rgb = lerp(color, blur, alpha);
		output.a = 1;
	}
	
	technique BilateralCS <ui_tooltip = "A bilateral filter which can be used to soften or sharpen the texture components of an image.\n\n"
										 "Part of Insane Shaders\n"
										 "By: Lord of Lunacy";>
	{	
		
		pass
		{
			ComputeShader = HorizontalFilterCS0<H_GROUP_SIZE.x, H_GROUP_SIZE.y>;
			DispatchSizeX = H_GROUPS.x;
			DispatchSizeY = H_GROUPS.y;
		}
		
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = CombinePS;
			RenderTarget0 = Temp0;
		}
		
		pass
		{
			ComputeShader = VerticalFilterCS0<V_GROUP_SIZE.x, V_GROUP_SIZE.y>;
			DispatchSizeX = V_GROUPS.x;
			DispatchSizeY = V_GROUPS.y;
		}
		
		
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = OutputPS;
		}
	}
}
#endif
