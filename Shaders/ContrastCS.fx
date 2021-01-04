/*
ContrastCS
By: Lord Of Lunacy

A histogram based contrast stretching shader that adaptively adjusts the contrast of the image
based on its contents.

Srinivasan, S & Balram, Nikhil. (2006). Adaptive contrast enhancement using local region stretching.
http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.526.5037&rep=rep1&type=pdf
*/

#ifndef LARGE_CONTRAST_LUT
	#define LARGE_CONTRAST_LUT 1
#endif

#define DIVIDE_ROUNDING_UP(numerator, denominator) (int(numerator + denominator - 1) / int(denominator))

#define TILES_SAMPLES_PER_THREAD uint2(2, 2)
#define COLUMN_SAMPLES_PER_THREAD 4
#define LOCAL_ARRAY_SIZE (TILES_SAMPLES_PER_THREAD.x * TILES_SAMPLES_PER_THREAD.y)
#if LARGE_CONTRAST_LUT != 0
	#define BIN_COUNT 1024
#else
	#define BIN_COUNT 256
#endif
#define GROUP_SIZE uint2(32, 32)
#undef RESOLUTION_MULTIPLIER
#define RESOLUTION_MULTIPLIER 1
#define DISPATCH_SIZE uint2(DIVIDE_ROUNDING_UP(BUFFER_WIDTH, TILES_SAMPLES_PER_THREAD.x * GROUP_SIZE.x * RESOLUTION_MULTIPLIER), \
					  DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, TILES_SAMPLES_PER_THREAD.y * GROUP_SIZE.y * RESOLUTION_MULTIPLIER))

#if (((__RENDERER__ >= 0xb000 && __RENDERER__ < 0x10000) || (__RENDERER__ >= 0x14300)) && __RESHADE__ >=40800)
	#define CONTRAST_COMPUTE 1
#else
	#define CONTRAST_COMPUTE 0
#endif

#if CONTRAST_COMPUTE != 0
namespace Contrast 
{
	texture BackBuffer : COLOR;
	texture LocalTiles {Width = BIN_COUNT; Height = DISPATCH_SIZE.x * DISPATCH_SIZE.y; Format = R32f;};
	texture Histogram {Width = BIN_COUNT; Height = 1; Format = R32f;};
	texture HistogramLUT {Width = BIN_COUNT; Height = 1; Format = R16f;};
	texture RegionVariances {Width = 1; Height = 1; Format = RGBA32f;};

	sampler sBackBuffer {Texture = BackBuffer;};
	sampler sLocalTiles {Texture = LocalTiles;};
	sampler sHistogram {Texture = Histogram;};
	sampler sHistogramLUT {Texture = HistogramLUT;};
	sampler sRegionVariances {Texture = RegionVariances;};

	storage wLocalTiles {Texture = LocalTiles;};
	storage wHistogram {Texture = Histogram;};
	storage wHistogramLUT {Texture = HistogramLUT;};
	storage wRegionVariances {Texture = RegionVariances;};

	uniform float Minimum<
		ui_type = "slider";
		ui_label = "Minimum";
		ui_category = "Thresholds";
		ui_min = 0; ui_max = 1;
	> = 0;

	uniform float DarkThreshold<
		ui_type = "slider";
		ui_label = "Dark Threshold";
		ui_category = "Thresholds";
		ui_min = 0; ui_max = 1;
	> = 0.333;

	uniform float LightThreshold<
		ui_type = "slider";
		ui_label = "LightThreshold";
		ui_category = "Thresholds";
		ui_min = 0; ui_max = 1;
	> = 0.667;

	uniform float Maximum<
		ui_type = "slider";
		ui_label = "Maximum";
		ui_category = "Thresholds";
		ui_min = 0; ui_max = 1;
	> = 1;

	uniform float DarkPeak<
		ui_type = "slider";
		ui_label = "Dark Blending Curve";
		ui_category = "Dark Settings";
		ui_min = 0; ui_max = 1;
	> = 0.05;
	
	uniform float DarkMax<
		ui_type = "slider";
		ui_label = "Dark Maximum Blending";
		ui_category = "Dark Settings";
		ui_min = 0; ui_max = 1;
	> = 0.15;

	uniform float MidPeak<
		ui_type = "slider";
		ui_label = "Mid Blending Curve";
		ui_category = "Mid Settings";
		ui_min = 0; ui_max = 1;
	> = 0.5;
	
	uniform float MidMax<
		ui_type = "slider";
		ui_label = "Mid Maximum Blending";
		ui_category = "Mid Settings";
		ui_min = 0; ui_max = 1;
	> = 0.4;

	uniform float LightPeak<
		ui_type = "slider";
		ui_label = "Light Blending Curve";
		ui_category = "Light Settings";
		ui_min = 0; ui_max = 1;
	> = 0.7;
	
	uniform float LightMax<
		ui_type = "slider";
		ui_label = "Light Maximum Blending";
		ui_category = "Light Settings";
		ui_min = 0; ui_max = 1;
	> = 0.3;
	
	uniform uint Debug<
		ui_type = "combo";
		ui_label = "Debug";
		ui_category = "Debug Views";
		ui_items = "None \0Histogram \0Dark Curve Input \0Mid Curve Input \0Light Curve Input \0";
	> = 0;

	groupshared uint HistogramBins[BIN_COUNT];
	void HistogramTilesCS(uint3 id : SV_DispatchThreadID, uint3 gid : SV_GroupID, uint3 gtid : SV_GroupThreadID)
	{
		uint threadIndex = gtid.x + gtid.y * GROUP_SIZE.x;
		uint groupIndex = gid.x + gid.y * DISPATCH_SIZE.x;
		
		
		if(threadIndex < BIN_COUNT)
		{
			HistogramBins[threadIndex] = 0;
		}
		barrier();
		
		
		uint localValue[LOCAL_ARRAY_SIZE];
		[unroll]
		for(int i = 0; i < TILES_SAMPLES_PER_THREAD.x; i++)
		{
			[unroll]
			for(int j = 0; j < TILES_SAMPLES_PER_THREAD.y; j++)
			{
				uint2 coord = (id.xy * TILES_SAMPLES_PER_THREAD + float2(i, j)) * RESOLUTION_MULTIPLIER;
				uint arrayIndex = i + TILES_SAMPLES_PER_THREAD.x * j;
				if(any(coord >= uint2(BUFFER_WIDTH, BUFFER_HEIGHT)))
				{
					localValue[arrayIndex] = BIN_COUNT;
				}
				else
				{
					localValue[arrayIndex] = uint(round(dot(tex2Dfetch(sBackBuffer, float2(coord)).rgb, float3(0.299, 0.587, 0.114)) * (BIN_COUNT - 1)));
				}
			}
		}
		
		
		[unroll]
		for(int i = 0; i < LOCAL_ARRAY_SIZE; i++)
		{
			if(localValue[i] < BIN_COUNT)
			{
				atomicAdd(HistogramBins[localValue[i]], 1);
			}
		}
		barrier();
		
		if(threadIndex < BIN_COUNT)
		{
			tex2Dstore(wLocalTiles, int2(threadIndex, groupIndex), float4(HistogramBins[threadIndex], 1, 1, 1));
		}
	}

	groupshared uint columnSum;
	void ColumnSumCS(uint3 id : SV_DispatchThreadID)
	{
		if(id.y == 0)
		{
			columnSum = 0;
		}
		barrier();
		uint localSum = 0;
		[unroll]
		for(int i = 0; i < COLUMN_SAMPLES_PER_THREAD; i++)
		{
			localSum += tex2Dfetch(sLocalTiles, int2(id.x, id.y * COLUMN_SAMPLES_PER_THREAD + i)).x;
		}
		
		atomicAdd(columnSum, localSum);
		barrier();
		
		if(id.y == 0)
		{
			tex2Dstore(wHistogram, id.xy, columnSum);
		}
	}

	groupshared float prefixSums[BIN_COUNT * 2];
	groupshared float valuePrefixSums[BIN_COUNT * 2];
	groupshared float3 regionSums;
	groupshared float3 regionMeans;
	groupshared uint3 regionVariances;

	void ContrastLUTCS(uint3 id : SV_DispatchThreadID)
	{
		float localBin = tex2Dfetch(sHistogram, id.xy).r;
		float localPrefixSum = localBin;
		float luma = (float(id.x) / float(BIN_COUNT - 1));
		float localValuePrefixSum = localBin * luma;
		prefixSums[id.x] = localPrefixSum;
		valuePrefixSums[id.x] = localValuePrefixSum;
		barrier();
		
		uint2 prefixSumOffset = uint2(0, BIN_COUNT);
		
		bool enabled = true;
		
		[unroll]
		for(int i = 0; i < log2(BIN_COUNT - 1) + 1; i++)
		{
			int access = id.x - exp2(i);
			if(access >= 0)
			{
				localPrefixSum += prefixSums[access + prefixSumOffset.x];
				localValuePrefixSum += valuePrefixSums[access + prefixSumOffset.x];
				prefixSums[id.x + prefixSumOffset.y] = localPrefixSum;
				valuePrefixSums[id.x + prefixSumOffset.y] = localValuePrefixSum;
			}
			else if (enabled)
			{
				prefixSums[id.x + prefixSumOffset.y] = localPrefixSum;
				valuePrefixSums[id.x + prefixSumOffset.y] = localValuePrefixSum;
				enabled = false;
			}
			
			prefixSumOffset.xy = prefixSumOffset.yx;
			barrier();
		}
		
		float3 localRegionSums;
		float3 localRegionMeans;
		uint darkThresholdUint = DarkThreshold * (BIN_COUNT - 1);
		uint lightThresholdUint = LightThreshold * (BIN_COUNT - 1);
		
		if(id.x == 0)
		{
			localRegionSums.x = prefixSums[darkThresholdUint + prefixSumOffset.x];
			localRegionSums.y = prefixSums[lightThresholdUint + prefixSumOffset.x];
			localRegionSums.z = prefixSums[BIN_COUNT - 1 + prefixSumOffset.x];
			
			localRegionMeans.x = valuePrefixSums[darkThresholdUint + prefixSumOffset.x];
			localRegionMeans.y = valuePrefixSums[lightThresholdUint + prefixSumOffset.x];
			localRegionMeans.z = valuePrefixSums[BIN_COUNT - 1 + prefixSumOffset.x];
			localRegionMeans /= localRegionSums;
			regionMeans = localRegionMeans;
			
			localRegionSums.z -= localRegionSums.y;
			localRegionSums.y -= localRegionSums.x;
			regionSums = localRegionSums;
			regionVariances = 0;
		}
		barrier();
		
		localRegionSums = regionSums;
		localRegionMeans = regionMeans;
		float lutValue;
		
		if(id.x <= darkThresholdUint)
		{
			float offset = Minimum;
			float multiplier = float(DarkThreshold - Minimum);
			lutValue = (localPrefixSum / localRegionSums.x) * multiplier + offset;
			uint varianceComponent = uint(float(abs(luma - localRegionMeans.x)) * float(localBin * (255)));
			atomicAdd(regionVariances[0], varianceComponent);
		}
		else if(id.x <= lightThresholdUint)
		{
			float offset = DarkThreshold;
			float multiplier = float(LightThreshold - DarkThreshold);
			localPrefixSum -= localRegionSums.x;
			lutValue = ((localPrefixSum) / localRegionSums.y) * multiplier + offset;
			uint varianceComponent = uint(float(abs(luma - localRegionMeans.y)) * float(localBin * (255)));
			atomicAdd(regionVariances[1], varianceComponent);
		}
		else
		{
			float offset = LightThreshold;
			float multiplier = float(LightThreshold - DarkThreshold);
			localPrefixSum -= localRegionSums.x + localRegionSums.y;
			lutValue = ((localPrefixSum) / localRegionSums.z) * multiplier + offset;
			uint varianceComponent = uint(float(abs(luma - localRegionMeans.z)) * float(localBin * (255)));
			atomicAdd(regionVariances[2], varianceComponent);
		}
		barrier();
		
		if(id.x == 0)
		{
			float3 localRegionVariances = float3(regionVariances) / ((255) * float3(localRegionSums));
			//localRegionVariances = 0.95 * previousRegionVariances + 0.05 * localRegionVariances;
			tex2Dstore(wRegionVariances, int2(0, 0), float4(localRegionVariances.xyz, 1));
		}
			
		tex2Dstore(wHistogramLUT, id.xy, lutValue);
	}

	// Vertex shader generating a triangle covering the entire screen
	void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
	{
		texcoord.x = (id == 2) ? 2.0 : 0.0;
		texcoord.y = (id == 1) ? 2.0 : 0.0;
		position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	}

	float WeightingCurve(float peak, float variance, float maximumBlending)
	{
		float output;
		if(variance <= peak)
		{
			return lerp(0, maximumBlending, abs(variance) / peak);
		}
		else
		{
			return lerp(maximumBlending, 0, abs(variance - peak) / (1 - peak));
		}
	}

	void OutputPS(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float3 color : SV_Target0)
	{
		color = tex2D(sBackBuffer, texcoord).rgb;
		float3 variances = tex2Dfetch(sRegionVariances, float2(0, 0)).rgb;
		float yOld = dot(color, float3(0.299, 0.587, 0.114));
		float yNew = tex2D(sHistogramLUT, float2(yOld, 0.5)).x;
		float alpha;
		
		
		if(yOld <= DarkThreshold)
		{
			alpha = WeightingCurve(DarkPeak, variances.x, DarkMax);
			//alpha = variances.x;
		}
		else if(yOld <= LightThreshold)
		{
			alpha = WeightingCurve(MidPeak, variances.y, MidMax);
			//alpha = variances.y;
		}
		else
		{
			alpha = WeightingCurve(LightPeak, variances.z, LightMax);
			//alpha = variances.z;
		}
		float y = lerp(yOld, yNew, (alpha));
		
		float cb = -0.168736 * color.r - 0.331264 * color.g + 0.500000 * color.b;
		float cr = +0.500000 * color.r - 0.418688 * color.g - 0.081312 * color.b;
		
		color = float3(
				y + 1.402 * cr,
				y - 0.344136 * cb - 0.714136 * cr,
				y + 1.772 * cb);
		
		if(Debug == 1)
		{
			texcoord = float2(3 * texcoord.x - 2, 1 - texcoord.y);
			uint2 coord = uint2(round(texcoord * float2((BIN_COUNT - 1), BUFFER_HEIGHT * (65536 / BIN_COUNT))));
			if(texcoord.x >= 0)
			{
				uint histogramBin = tex2Dfetch(sHistogram, float2(coord.x, 0)).x;
				if(coord.y <= histogramBin)
				{
					color = lerp(color, 1 - color, 0.7);
				}
			}
		}
		else if(Debug == 2)
		{
			texcoord = float2(1 - texcoord.x, texcoord.y * (float(BUFFER_HEIGHT) / float(BUFFER_WIDTH)));
			if(all(texcoord <= 0.125))
			{
				color = variances.xxx;
			}
		}
		else if(Debug == 3)
		{
			texcoord = float2(1 - texcoord.x, texcoord.y * (float(BUFFER_HEIGHT) / float(BUFFER_WIDTH)));
			if(all(texcoord <= 0.125))
			{
				color = variances.yyy;
			}
		}
		else if(Debug == 4)
		{
			texcoord = float2(1 - texcoord.x, texcoord.y * (float(BUFFER_HEIGHT) / float(BUFFER_WIDTH)));
			if(all(texcoord <= 0.125))
			{
				color = variances.zzz;
			}
		}
			
	}

	technique ContrastCS
	{
		pass
		{
			ComputeShader = HistogramTilesCS<GROUP_SIZE.x, GROUP_SIZE.y>;
			DispatchSizeX = DISPATCH_SIZE.x;
			DispatchSizeY = DISPATCH_SIZE.y;
		}
		
		pass
		{
			ComputeShader = ColumnSumCS<1, DIVIDE_ROUNDING_UP(DISPATCH_SIZE.x * DISPATCH_SIZE.y, 4)>;
			DispatchSizeX = BIN_COUNT;
			DispatchSizeY = 1;
		}
		
		pass
		{
			ComputeShader = ContrastLUTCS<(BIN_COUNT), 1>;
			DispatchSizeX = 1;
			DispatchSizeY = 1;
		}
		
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader = OutputPS;
		}
	}
}
#endif //CONTRAST_COMPUTE != 0