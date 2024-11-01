////////////////////////////////////////////////////////
// CMAA 2.0
// Author: Lord of Lunacy
// License: Apache License 2.0
// Repository: https://github.com/LordOfLunacy/Insane-Shaders
////////////////////////////////////////////////////////

/*
This is an implementation of Intel's CMAA 2.0 ported to ReShade. This port while keeping the underlying AA the same
uses a significantly different codebase to achieve the effect due to ReShade's lack of support for atomic texture
writes and in order to add support for DX9.

To resolve race conditions and to be able to support DX9 without atomic texture writes, rather than performing
scatter operations on UAVs, instead, this implementations relies on vertex shader dispatches of linelists to perform
the AA on Z shapes.

5/25/2023: Converted the ProcessEdges pass in supported APIs to a compute shader, and implemented thread reordering
similar to the method employed by Pascal Gilcher in his rewrite of SMAA found here:
	https://github.com/martymcmodding/iMMERSE/blob/main/Shaders/MartysMods_SMAA.fx
As well as the removal of stenciling which totals to roughly a 70% performance uplift in APIs that support compute,
and a minuscule uplift to performance in DX9.

Ported to ReShade by: Lord Of Lunacy
*/


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, Intel Corporation
//
// Licensed under the Apache License, Version 2.0 ( the "License" );
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Conservative Morphological Anti-Aliasing, version: 2.3
//
// Author(s):       Filip Strugar (filip.strugar@intel.com)
//
// More info:       https://github.com/GameTechDev/CMAA2
//
// Please see https://github.com/GameTechDev/CMAA2/README.md for additional information and a basic integration guide.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define COMPUTE 1
#define SUPPORTED 1
#if __RENDERER__ < 0xb000
	#undef COMPUTE
	#define COMPUTE 0
#endif

#if (__RESHADE__ >= 50000 && __RESHADE__ < 50100) && __RENDERER__ < 0xA000
	#warning "Due to ReShade 5.0 limiting DX9 to 100 vertices per pass, CMAA2 is not supported in DX9 while using 5.0"
	#undef SUPPORTED
	#define SUPPORTED 0
#endif

#if __RENDERER__ < 0xA000
	#define D3D9 1
#else
	#define D3D9 0
#endif

//Not currently supported by the code, as it did not improve performance, but kept incase this functionality is added back
//in the future
#define CMAA_PACK_SINGLE_SAMPLE_EDGE_TO_HALF_WIDTH  0   // adds more ALU but reduces memory use for edges by half by packing two 4 bit edge info into one R8_UINT texel - helps on all HW except at really low res


#define DIVIDE_ROUNDING_UP(a, b) (((a) + (b) - 1) / (b))

#if SUPPORTED

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VARIOUS QUALITY SETTINGS
//
// Longest line search distance; must be even number; for high perf low quality start from ~32 - the bigger the number, 
// the nicer the gradients but more costly. Max supported is 128!
static const uint c_maxLineLength = 128;
//
#ifndef CMAA2_EXTRA_SHARPNESS
	#define CMAA2_EXTRA_SHARPNESS                   0     // Set to 1 to preserve even more text and shape clarity at the expense of less AA
#endif
//
// It makes sense to slightly drop edge detection thresholds with increase in MSAA sample count, as with the higher
// MSAA level the overall impact of CMAA2 alone is reduced but the cost increases.
#define CMAA2_SCALE_QUALITY_WITH_MSAA               0
//
//
#ifndef CMAA2_STATIC_QUALITY_PRESET
	#define CMAA2_STATIC_QUALITY_PRESET 2  // 0 - LOW, 1 - MEDIUM, 2 - HIGH, 3 - ULTRA, 4 - SUFFER
#endif

#if COMPUTE == 0
	#ifndef CMAA2_PERFORMANCE_HACK
		#define CMAA2_PERFORMANCE_HACK 1
	#endif
#endif

// presets (for HDR color buffer maybe use higher values)
//The VERTEX_COUNT_DENOMINATOR is actually set somewhat conservatively so performance could likely be improved by increasing this setting
#if CMAA2_STATIC_QUALITY_PRESET == 0   // LOW
	#define g_CMAA2_EdgeThreshold                   float(0.15)
	#define VERTEX_COUNT_DENOMINATOR 100
#elif CMAA2_STATIC_QUALITY_PRESET == 1 // MEDIUM
	#define g_CMAA2_EdgeThreshold                   float(0.10)
	#define VERTEX_COUNT_DENOMINATOR 64
#elif CMAA2_STATIC_QUALITY_PRESET == 2 // HIGH (default)
	#define g_CMAA2_EdgeThreshold                   float(0.07)
	#define VERTEX_COUNT_DENOMINATOR 48
#elif CMAA2_STATIC_QUALITY_PRESET == 3 // ULTRA
	#define g_CMAA2_EdgeThreshold                   float(0.05)
	#define VERTEX_COUNT_DENOMINATOR 32
#else
	#define g_CMAA2_EdgeThreshold                   float(0.03)
	#define VERTEX_COUNT_DENOMINATOR 16
    //#error CMAA2_STATIC_QUALITY_PRESET not set?
#endif
//

#if CMAA2_EXTRA_SHARPNESS
#define g_CMAA2_LocalContrastAdaptationAmount       float(0.15)
#define g_CMAA2_SimpleShapeBlurinessAmount          float(0.07)
#else
#define g_CMAA2_LocalContrastAdaptationAmount       float(0.10)
#define g_CMAA2_SimpleShapeBlurinessAmount          float(0.10)
#endif

// these are blendZ settings, determined empirically :)
static const float c_symmetryCorrectionOffset = float( 0.22 );
#if CMAA2_EXTRA_SHARPNESS
static const float c_dampeningEffect          = float( 0.11 );
#else
static const float c_dampeningEffect          = float( 0.15 );
#endif


#if COMPUTE
uniform int UIHELP <
	ui_type = "radio";
	ui_category = "Help";
	ui_label = "    ";
	ui_text =  "CMAA2_EXTRA_SHARPNESS - This settings makes the effect of the AA more sharp overall \n"
			   "Can be either 0 or 1. (0 (off) by default) \n\n"
			   "CMAA2_STATIC_QUALITY_PRESET - This setting ranges from 0 to 4, and adjusts the strength "
		   	   "of the edge detection, higher settings come at a performance cost \n"
			   "0 - LOW, 1 - MEDIUM, 2 - HIGH, 3 - ULTRA, 4 - SUFFER (default of 2)";
>;
#else
uniform int UIHELP <
	ui_type = "radio";
	ui_category = "Help";
	ui_label = "    ";
	ui_text =  "CMAA2_EXTRA_SHARPNESS - This settings makes the effect of the AA more sharp overall \n"
			   "Can be either 0 or 1. (0 (off) by default) \n\n"
			   "CMAA2_PERFORMANCE_HACK - This setting enables a performance hack that greatly improves "
			   "the performance of the AA at a slight quality cost.\n"
			   "Can be either 0 or 1. (1 (on) by default) \n\n"
			   "CMAA2_STATIC_QUALITY_PRESET - This setting ranges from 0 to 4, and adjusts the strength "
		   	   "of the edge detection, higher settings come at a performance cost \n"
			   "0 - LOW, 1 - MEDIUM, 2 - HIGH, 3 - ULTRA, 4 - SUFFER (default of 2)";
>;
#endif

uniform bool bSharp <
    ui_label = "Extra Sharpness";
    ui_category = "General Settings";
    ui_tooltip = "This settings makes the effect of the AA more sharp overall.";
	ui_bind = "CMAA2_EXTRA_SHARPNESS";
> = 0;

uniform int iPreset <
    ui_type = "slider";
    ui_min = 0;
    ui_max = 4;
    ui_label = "Strength";
    ui_category = "General Settings";
    ui_tooltip = "This setting adjusts the strength of the edge detection, higher "
                 "settings come at a performance cost. \n"
                 "0 - LOW, 1 - MEDIUM, 2 - HIGH, 3 - ULTRA, 4 - SUFFER (default of 2)";
	ui_bind = "CMAA2_STATIC_QUALITY_PRESET";
> = 2;

#if !COMPUTE
uniform bool bPerfHack <
    ui_label = "Extra Sharpness";
    ui_category = "General Settings";
    ui_tooltip = "This setting enables a performance hack that greatly improves "
                 "the performance of the AA at a slight quality cost.";
	ui_bind = "CMAA2_PERFORMANCE_HACK";
> = 1;
#endif

uniform bool bDebugEdges <
    ui_label = "Debug Edges";
    ui_category = "Debugging";
    ui_tooltip = "This setting enables an overlay showing the edges detected "
                 "by the shader.";
    ui_bind = "g_CMAA2_DebugEdges";
> = false;

#ifndef g_CMAA2_DebugEdges
    #define g_CMAA2_DebugEdges 0
#endif

namespace CMAA_2
{
texture2D ZShapes <pooled = true;>{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8;};
texture2D BackBuffer : COLOR;
texture2D Edges <pooled = true;>{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
texture2D ProcessedCandidates <pooled = true;>{Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f;};

sampler2D sZShapes {Texture = ZShapes;};
sampler2D sBackBuffer {Texture = BackBuffer;};
sampler2D sEdges {Texture = Edges;};
sampler2D sProcessedCandidates{Texture = ProcessedCandidates;};

#if COMPUTE
#define EDGE_GROUP_SIZE uint2(16, 16)
#define EDGE_PIXELS_PER_THREAD uint2(1, 2)
#define EDGE_PIXELS_PER_GROUP uint2(EDGE_GROUP_SIZE.x * EDGE_PIXELS_PER_THREAD.x, EDGE_GROUP_SIZE.y * EDGE_PIXELS_PER_THREAD.y)
#define EDGE_DISPATCH_SIZE uint2(DIVIDE_ROUNDING_UP(BUFFER_WIDTH, EDGE_PIXELS_PER_GROUP.x), DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, EDGE_PIXELS_PER_GROUP.y))
#define GROUP_SIZE uint2(32, 32)
#define PIXELS_PER_THREAD uint2(2, 2)
#define PIXELS_PER_GROUP uint2(GROUP_SIZE.x * PIXELS_PER_THREAD.x, GROUP_SIZE.y * PIXELS_PER_THREAD.y)
#define DISPATCH_SIZE uint2(DIVIDE_ROUNDING_UP(BUFFER_WIDTH, PIXELS_PER_GROUP.x), DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, PIXELS_PER_GROUP.y))
#define STACK_ALLOC_THREADS (1024)
#define STACK_ALLOC_PIXELS_PER_THREAD (DIVIDE_ROUNDING_UP((DISPATCH_SIZE.x * DISPATCH_SIZE.y), STACK_ALLOC_THREADS))


texture Sum {Width = DISPATCH_SIZE.x; Height = DISPATCH_SIZE.y; Format = RG8;};
texture StackAlloc {Width = DISPATCH_SIZE.x; Height = DISPATCH_SIZE.y; Format = R32f;};
texture ZShapeCoords {Width = BUFFER_WIDTH; Height = DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, VERTEX_COUNT_DENOMINATOR); Format = R32f;};

sampler sSum {Texture = Sum;};
sampler sStackAlloc {Texture = StackAlloc;};
sampler sZShapeCoords {Texture = ZShapeCoords;};

storage wSum {Texture = Sum;};
storage wStackAlloc {Texture = StackAlloc;};
storage wZShapeCoords {Texture = ZShapeCoords;};
storage wZShapes {Texture = ZShapes;};
storage wProcessedCandidates {Texture = ProcessedCandidates;};

#endif



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// encoding/decoding of various data such as edges
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// how .rgba channels from the edge texture maps to pixel edges:
//
//                   A - 0x08               (A - there's an edge between us and a pixel above us)
//              |---------|                 (R - there's an edge between us and a pixel to the right)
//              |         |                 (G - there's an edge between us and a pixel at the bottom)
//     0x04 - B |  pixel  | R - 0x01        (B - there's an edge between us and a pixel to the left)
//              |         |
//              |_________|
//                   G - 0x02

//Due to reshade only supporting unorms, the return type is a float
//Also add an isCandidate check to support performing the histogram style formation of the linked list of candidates
//Hopefully this won't always be neccessary and ReShade will get support for atomic operations on textures to do it properly
float PackEdges( float4 edges, bool isCandidate )   // input edges are binary 0 or 1
{
	return (dot( edges, float4( 1, 2, 4, 8 )) + 16 * isCandidate)  / 255;
}

uint4 UnpackEdges( uint value )
{
	uint4 ret;
#if D3D9
	ret.x = value % 2;
	ret.y = value / 2 % 2;
	ret.z = value / 4 % 2;
	ret.w = value / 8 % 2;
#else
	ret.x = (value & 0x1) != 0;
	ret.y = (value & 0x2) != 0;
	ret.z = (value & 0x4) != 0;
	ret.w = (value & 0x8) != 0;
#endif
	return ret;
}

float4 UnpackEdgesFlt( uint value )
{
	return float4(UnpackEdges(value));
}

float4 packZ(bool horizontal, bool invertedZ, float shapeQualityScore, float lineLengthLeft, float lineLengthRight)
{
	//return //(uint(horizontal) << 19) | (uint(invertedZ) << 18) | (uint(shapeQualityScore) << 16) | (uint(lineLengthLeft) << 8) | (uint(lineLengthRight));
	float4 temp = float4(
		lineLengthLeft,
		lineLengthRight,
		shapeQualityScore,
		horizontal * 2 + invertedZ + 4);//The plus 4 helps with the compute
	return temp / 255;
}

void unpackZ(float4 packedZ, out bool horizontal, out bool invertedZ, out float shapeQualityScore, out float lineLengthLeft, out float lineLengthRight)
{
	uint4 temp = packedZ * 255.5;
	horizontal = temp.w / 2 % 2;
	invertedZ = temp.w % 2;
	shapeQualityScore = temp.z;
	lineLengthLeft = temp.x;
	lineLengthRight = temp.y;
}

#if COMPUTE
float2 packSum(uint value)
{
	float2 temp;
	temp.x = (value & 0xFF00) >> 8;
	temp.y = (value & 0xFF);
	return (temp) / 255;
}

uint unpackSum(float2 value)
{
	uint2 temp = value * 255.5;
	return ((temp.x << 8) | temp.y);
}
#endif

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// source color & color conversion helpers
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float3 LoadSourceColor( uint2 pixelPos, int2 offset )
{
	float3 color = tex2Dfetch(sBackBuffer, (pixelPos + offset)).rgb;
	return color;
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Edge detection and local contrast adaptation helpers
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
float EdgeDetectColorCalcDiff( float3 colorA, float3 colorB )
{
	const float3 LumWeights = float3( 0.299, 0.587, 0.114 );
	float3 diff = abs( (colorA.rgb - colorB.rgb) );
	return dot( diff.rgb, LumWeights.rgb );
}

//In the pixel shader all 4 edges need to be computed locally
float4 PSComputeEdge(float3 pixelColor,float3 pixelColorRight,float3 pixelColorBottom, float3 pixelColorLeft, float3 pixelColorTop)
{
	float4 temp = float4(
		EdgeDetectColorCalcDiff(pixelColor, pixelColorRight),
		EdgeDetectColorCalcDiff(pixelColor, pixelColorBottom),
		EdgeDetectColorCalcDiff(pixelColor, pixelColorLeft),
		EdgeDetectColorCalcDiff(pixelColor, pixelColorTop));
	return temp;    // for HDR edge detection it might be good to premultiply both of these by some factor - otherwise clamping to 1 might prevent some local contrast adaptation. It's a very minor nitpick though, unlikely to significantly affect things.
}

//Same function can be used for both vertical and horizontal in the pixel shader
float PSComputeLocalContrast(float leftTop, float rightTop, float leftBottom, float rightBottom)
{
	return max(max(max(rightTop, rightBottom), leftTop), leftBottom) * float(g_CMAA2_LocalContrastAdaptationAmount);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float4 ComputeSimpleShapeBlendValues( float4 edges, float4 edgesLeft, float4 edgesRight, float4 edgesTop, float4 edgesBottom, const bool dontTestShapeValidity )
{
	// a 3x3 kernel for higher quality handling of L-based shapes (still rather basic and conservative)

	float fromRight = edges.r;
	float fromBelow = edges.g;
	float fromLeft  = edges.b;
	float fromAbove = edges.a;

	float blurCoeff = float( g_CMAA2_SimpleShapeBlurinessAmount );

	float numberOfEdges = dot( edges, float4( 1, 1, 1, 1 ) );

	float numberOfEdgesAllAround = dot(edgesLeft.bga + edgesRight.rga + edgesTop.rba + edgesBottom.rgb, float3( 1, 1, 1 ) );

	// skip if already tested for before calling this function
	if( !dontTestShapeValidity )
	{
		// No blur for straight edge
		if( numberOfEdges == 1 )
			blurCoeff = 0;

		// L-like step shape ( only blur if it's a corner, not if it's two parallel edges)
		if( numberOfEdges == 2 )
			blurCoeff *= ( ( float(1.0) - fromBelow * fromAbove ) * ( float(1.0) - fromRight * fromLeft ) );
	}

	// L-like step shape
	//[branch]
	if( numberOfEdges == 2 )
	{
		blurCoeff *= 0.75;

		float k = 0.9f;
		fromRight += k * (edges.g * edgesTop.r     * (1.0-edgesLeft.g)   + edges.a * edgesBottom.r * (1.0-edgesLeft.a)  );
		fromBelow += k * (edges.b * edgesRight.g   * (1.0-edgesTop.b)    + edges.r * edgesLeft.g   * (1.0-edgesTop.r)   );
		fromLeft  += k * (edges.a * edgesBottom.b  * (1.0-edgesRight.a)  + edges.g * edgesTop.b    * (1.0-edgesRight.g) );
		fromAbove += k * (edges.r * edgesLeft.a    * (1.0-edgesBottom.r) + edges.b * edgesRight.a  * (1.0-edgesBottom.b));
	}

	// if( numberOfEdges == 3 )
	//	blurCoeff *= 0.95;

	// Dampen the blurring effect when lots of neighbouring edges - additionally preserves text and texture detail
#if CMAA2_EXTRA_SHARPNESS
	blurCoeff *= saturate( 1.15 - numberOfEdgesAllAround / 8.0 );
#else
	blurCoeff *= saturate( 1.30 - numberOfEdgesAllAround / 10.0 );
#endif

	return float4( fromLeft, fromAbove, fromRight, fromBelow ) * blurCoeff;
}

uint LoadEdge( int2 pixelPos, int2 offset)
{
	uint edge   = (uint)(tex2Dfetch(sEdges, pixelPos + offset).x * 255.5);
	return edge;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////






// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

void EdgesPS(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float output : SV_TARGET0)
{
	int2 coord = position.xy;
	float4 a = tex2Dfetch(sBackBuffer, coord + int2(-1, -1));
	float4 b = tex2Dfetch(sBackBuffer, coord + int2( 0, -1));
	float4 c = tex2Dfetch(sBackBuffer, coord + int2( 1, -1));
	float4 d = tex2Dfetch(sBackBuffer, coord + int2(-1,  0));
	float4 e = tex2Dfetch(sBackBuffer, coord + int2( 0,  0));
	float4 f = tex2Dfetch(sBackBuffer, coord + int2( 1,  0));
	float4 g = tex2Dfetch(sBackBuffer, coord + int2(-1,  1));
	float4 h = tex2Dfetch(sBackBuffer, coord + int2( 0,  1));
	float4 i = tex2Dfetch(sBackBuffer, coord + int2( 1,  1));

	float4 edges = PSComputeEdge(e, f, h, d, b);

	//Calculate vertical edges for local contrast adaptation
	float ab = EdgeDetectColorCalcDiff(a, b);
	float bc = EdgeDetectColorCalcDiff(b, c);
	float de = EdgeDetectColorCalcDiff(d, e);
	float gh = EdgeDetectColorCalcDiff(g, h);
	float hi = EdgeDetectColorCalcDiff(h, i);

	float4 localContrast;
	localContrast.x = PSComputeLocalContrast(de, edges.y, gh, hi);
	localContrast.z = PSComputeLocalContrast(ab, bc, de, edges.y);

	//Calculate horizontal edges for local contrast adaptation
	float ad = EdgeDetectColorCalcDiff(a, d);
	float be = EdgeDetectColorCalcDiff(b, e);
	float dg = EdgeDetectColorCalcDiff(d, g);
	float cf = EdgeDetectColorCalcDiff(c, f);
	float fi = EdgeDetectColorCalcDiff(f, i);

	localContrast.y = PSComputeLocalContrast(be, cf, edges.x, fi);
	localContrast.w = PSComputeLocalContrast(ad, be, dg, edges.x);
	edges -= localContrast;

	//Use a ternary operator to evaluate each vector component individually
	edges = (edges > g_CMAA2_EdgeThreshold) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);

	// if there's at least one two edge corner, this is a candidate for simple or complex shape processing...
	bool isCandidate = ( edges.x * edges.y + edges.y * edges.z + edges.z * edges.w + edges.w * edges.x ) != 0;

	output = PackEdges(edges, isCandidate);
	//if(output < 1/256) discard;
}

void FindZLineLengths( out float lineLengthLeft, out float lineLengthRight, uint2 screenPos, bool horizontal, bool invertedZShape, const float2 stepRight)
{
// this enables additional conservativeness test but is pretty detrimental to the final effect so left disabled by default even when CMAA2_EXTRA_SHARPNESS is enabled
#define CMAA2_EXTRA_CONSERVATIVENESS2 0
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// TODO: a cleaner and faster way to get to these - a precalculated array indexing maybe?
	uint maskLeft, bitsContinueLeft, maskRight, bitsContinueRight;
	{
		// Horizontal (vertical is the same, just rotated 90- counter-clockwise)
		// Inverted Z case:              // Normal Z case:
		//   __                          // __
		//  X|                           //  X|
		// --                            //   --
		uint maskTraceLeft, maskTraceRight;
#if CMAA2_EXTRA_CONSERVATIVENESS2
		uint maskStopLeft, maskStopRight;
#endif
		if( horizontal )
		{
			maskTraceLeft = 0x08; // tracing top edge
			maskTraceRight = 0x02; // tracing bottom edge
#if CMAA2_EXTRA_CONSERVATIVENESS2
			maskStopLeft = 0x01; // stop on right edge
			maskStopRight = 0x04; // stop on left edge
#endif
		}
		else
		{
			maskTraceLeft = 0x04; // tracing left edge
			maskTraceRight = 0x01; // tracing right edge
#if CMAA2_EXTRA_CONSERVATIVENESS2
			maskStopLeft = 0x08; // stop on top edge
			maskStopRight = 0x02; // stop on bottom edge
#endif
		}
		if( invertedZShape )
		{
			uint temp = maskTraceLeft;
			maskTraceLeft = maskTraceRight;
			maskTraceRight = temp;
		}
		maskLeft = maskTraceLeft;
		bitsContinueLeft = maskTraceLeft;
		maskRight = maskTraceRight;
#if CMAA2_EXTRA_CONSERVATIVENESS2
		maskLeft |= maskStopLeft;
		maskRight |= maskStopRight;
#endif
		bitsContinueRight = maskTraceRight;
	}
	/////////////////////////////////////////////////////////////////////////////////////////////////////////

	bool continueLeft = true;
	bool continueRight = true;
	float maxLR;
	lineLengthLeft = 1;
	lineLengthRight = 1;
	[loop]
	while(true)
	{
		uint edgeLeft   = LoadEdge( screenPos.xy - stepRight * float(lineLengthLeft)          , int2( 0, 0 ));
		uint edgeRight  = LoadEdge( screenPos.xy + stepRight * ( float(lineLengthRight) + 1 ) , int2( 0, 0 ));

		// stop on encountering 'stopping' edge (as defined by masks)
#if D3D9
		continueLeft   *= (edgeLeft / maskLeft % 2);
		continueRight  *= (edgeRight / maskRight % 2);
#else
		continueLeft    = continueLeft  && ( edgeLeft & maskLeft );
		continueRight   = continueRight && ( edgeRight & maskRight );
#endif

		lineLengthLeft  += continueLeft;
		lineLengthRight += continueRight;

		// both stopped? cause the search end by setting maxLR to max length.
		maxLR = ( !continueLeft && !continueRight ) ?
			(float)c_maxLineLength : max( lineLengthRight, lineLengthLeft );

		// either the longer one is ahead of the smaller (already stopped) one by more than a factor of x, or both
		// are stopped - end the search.
#if CMAA2_EXTRA_SHARPNESS
		if( maxLR >= min( (float)c_maxLineLength, (1.20 * min( lineLengthRight, lineLengthLeft ) - 0.20) ) )
#else
		if( maxLR >= min( (float)c_maxLineLength, (1.25 * min( lineLengthRight, lineLengthLeft ) - 0.25) ) )
#endif
			break;
	}
}

void DetectZsHorizontal( in float4 edges, in float4 edgesM1P0, in float4 edgesP1P0, in float4 edgesP2P0, out float invertedZScore, out float normalZScore )
{
	// Inverted Z case:
	//   __
	//  X|
	// --
	{
		invertedZScore  = edges.r * edges.g *                edgesP1P0.a;
		invertedZScore  *= 2.0 + (edgesM1P0.g + edgesP2P0.a) - (edges.a + edgesP1P0.g) - 0.7 * (edgesP2P0.g + edgesM1P0.a + edges.b + edgesP1P0.r);
	}

	// Normal Z case:
	// __
	//  X|
	//   --
	{
		normalZScore    = edges.r * edges.a *                edgesP1P0.g;
		normalZScore    *= 2.0 + (edgesM1P0.a + edgesP2P0.g) - (edges.g + edgesP1P0.a) - 0.7 * (edgesP2P0.a + edgesM1P0.g + edges.b + edgesP1P0.r);
	}
}

float4 BlendSimpleShape(uint2 coord, float4 edges, float4 edgesLeft, float4 edgesRight, float4 edgesBottom, float4 edgesTop)
{
	float4 blendVal = ComputeSimpleShapeBlendValues(edges, edgesLeft, edgesRight, edgesTop, edgesBottom, true);
		
	const float fourWeightSum = dot(blendVal, 1);
	const float centerWeight = 1 - fourWeightSum;

	float3 outColor = LoadSourceColor(coord, int2(0, 0)).rgb * centerWeight;

	float3 pixel;

	//left
	pixel = LoadSourceColor(coord, int2(-1, 0)).rgb;
	outColor.rgb += (blendVal.x > 0) ? blendVal.x * pixel : 0;

	//above
	pixel = LoadSourceColor(coord, int2(0, -1)).rgb;
	outColor.rgb += (blendVal.y > 0) ? blendVal.y * pixel : 0;

	//right
	pixel = LoadSourceColor(coord, int2(1, 0)).rgb;
	outColor.rgb += (blendVal.z > 0) ? blendVal.z * pixel : 0;

	//below
	pixel = LoadSourceColor(coord, int2(0, 1)).rgb;
	outColor.rgb += (blendVal.w > 0) ? blendVal.w * pixel : 0;

	return float4(outColor.rgb, 1);
}

float4 DetectComplexShapes(uint2 coord, float4 edges, float4 edgesLeft, float4 edgesRight, float4 edgesBottom, float4 edgesTop)
{
	float invertedZScore = 0;
	float normalZScore = 0;
	float maxScore = 0;
	bool horizontal = true;
	bool invertedZ = false;
	// float shapeQualityScore;    // 0 - best quality, 1 - some edges missing but ok, 2 & 3 - dubious but better than nothing

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// horizontal
	{
		float4 edgesM1P0 = edgesLeft;
		float4 edgesP1P0 = edgesRight;
		float4 edgesP2P0 = UnpackEdgesFlt( tex2Dfetch(sEdges, coord + int2(  2, 0 )).x * 255.5 );

		DetectZsHorizontal( edges, edgesM1P0, edgesP1P0, edgesP2P0, invertedZScore, normalZScore );
		maxScore = max( invertedZScore, normalZScore );

		if( maxScore > 0 )
		{
			invertedZ = invertedZScore > normalZScore;
		}
	}
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// vertical
	{
		// Reuse the same code for vertical (used for horizontal above), but rotate input data 90 degrees counter-clockwise, so that:
		// left     becomes     bottom
		// top      becomes     left
		// right    becomes     top
		// bottom   becomes     right

		// we also have to rotate edges, thus .argb
		float4 edgesM1P0 = edgesBottom;
		float4 edgesP1P0 = edgesTop;
		float4 edgesP2P0 =  UnpackEdgesFlt( tex2Dfetch(sEdges, coord + int2( 0, -2 )).x * 255.5 );

		DetectZsHorizontal( edges.argb, edgesM1P0.argb, edgesP1P0.argb, edgesP2P0.argb, invertedZScore, normalZScore );
		float vertScore = max( invertedZScore, normalZScore );

		if( vertScore > maxScore )
		{
			maxScore = vertScore;
			horizontal = false;
			invertedZ = invertedZScore > normalZScore;
		}
	}
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	if( maxScore > 0 )
	{
#if CMAA2_EXTRA_SHARPNESS
		float shapeQualityScore = round( clamp(4.0 - maxScore, 0.0, 3.0) );    // 0 - best quality, 1 - some edges missing but ok, 2 & 3 - dubious but better than nothing
#else
		float shapeQualityScore = floor( clamp(4.0 - maxScore, 0.0, 3.0) );    // 0 - best quality, 1 - some edges missing but ok, 2 & 3 - dubious but better than nothing
#endif

		const float2 stepRight = ( horizontal ) ? ( float2( 1, 0 ) ) : ( float2( 0, -1 ) );
		float lineLengthLeft, lineLengthRight;
		FindZLineLengths( lineLengthLeft, lineLengthRight, coord, horizontal, invertedZ, stepRight);

		lineLengthLeft  -= shapeQualityScore;
		lineLengthRight -= shapeQualityScore;
		if( ( lineLengthLeft + lineLengthRight ) >= (5.0) )
		{
			return packZ(horizontal, invertedZ, shapeQualityScore, lineLengthLeft, lineLengthRight);//((uint(horizontal) << 19) | (uint(invertedZ) << 18) | (uint(shapeQualityScore) << 16) | (uint(lineLengthLeft) << 8) | (uint(lineLengthRight)));
		}
	}
	return float4(0.0, 0.0, 0.0, 0.0);

}

void ProcessEdgesPS(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 output : SV_TARGET0, out float4 ZShapes : SV_TARGET1)
{
	float2 coord = position.xy;
	uint center = LoadEdge(coord, int2(0, 0));
	output = 0;
	ZShapes = 0;
	if(center > 16)
	{	
		float4 edges = UnpackEdgesFlt(center);
		float4 edgesLeft = UnpackEdgesFlt(LoadEdge(coord, int2(-1, 0)));
		float4 edgesRight = UnpackEdgesFlt(LoadEdge(coord, int2(1, 0)));
		float4 edgesBottom = UnpackEdgesFlt(LoadEdge(coord, int2(0, 1)));
		float4 edgesTop = UnpackEdgesFlt(LoadEdge(coord, int2(0, -1)));
		output = BlendSimpleShape(coord, edges, edgesLeft, edgesRight, edgesBottom, edgesTop);

		ZShapes = DetectComplexShapes(coord, edges, edgesLeft, edgesRight, edgesBottom, edgesTop);
	}
	else
		discard;
}

#if COMPUTE
	groupshared uint g_count;
	groupshared uint g_work[EDGE_PIXELS_PER_GROUP.x * EDGE_PIXELS_PER_GROUP.y];
	groupshared uint count;
	void ProcessEdgesCS(uint3 id : SV_DispatchThreadID, uint gIndex : SV_GroupIndex, uint3 gid : SV_GroupID, uint3 gtid : SV_GroupThreadID)
	{
		uint2 coord = id.xy * EDGE_PIXELS_PER_THREAD;
		if(gIndex == 0) g_count = 0;
		barrier();
		[unroll]
		for(uint i = 0; i < EDGE_PIXELS_PER_THREAD.x; i++)
		{
			[unroll]
			for(uint j = 0; j < EDGE_PIXELS_PER_THREAD.y; j++)
			{
				uint center = LoadEdge(coord, int2(i, j));
				//Add edge to queue if it requires more processing
				//This reorders the threads by compacting work items within warps
				if(center > 16)
				{
					uint workerId = atomicAdd(g_count, 1u);
					g_work[workerId] =  (coord.x + i) << 18 | (coord.y + j) << 4 | (center & 0xF);// - (1u << 4);
				}
			}
		}
		barrier();

		uint threadIndex = gIndex;
		uint count = g_count;
		//Operate on all the items in the queue, until exhausted
		while(threadIndex < count)
		{
			uint center = g_work[threadIndex];
			coord = float2(uint(center >> 18), uint((center >> 4) & 0x3FFF));
			center = center;
			float4 edges = UnpackEdgesFlt(center);
			float4 edgesLeft = UnpackEdgesFlt(LoadEdge(coord, int2(-1, 0)));
			float4 edgesRight = UnpackEdgesFlt(LoadEdge(coord, int2(1, 0)));
			float4 edgesBottom = UnpackEdgesFlt(LoadEdge(coord, int2(0, 1)));
			float4 edgesTop = UnpackEdgesFlt(LoadEdge(coord, int2(0, -1)));

			tex2Dstore(wProcessedCandidates, coord, BlendSimpleShape(coord, edges, edgesLeft, edgesRight, edgesBottom, edgesTop));//float4(outColor.rgb, 1));

			float4 complexShape = DetectComplexShapes(coord, edges, edgesLeft, edgesRight, edgesBottom, edgesTop);
			if(any(complexShape > 0))
				tex2Dstore(wZShapes, coord, complexShape);

			threadIndex += EDGE_GROUP_SIZE.x * EDGE_GROUP_SIZE.y;
		}
	}

	void SumCS(uint3 id : SV_DispatchThreadID, uint3 gid : SV_GroupID, uint3 gtid : SV_GroupThreadID)
	{
		if(all(gtid.xy == 0))
			count = 0;
		barrier();

		uint2 coord = id.xy * 2;
		float4 values = tex2DgatherA(sZShapes, float2(coord + 1) / float2(BUFFER_WIDTH, BUFFER_HEIGHT));
		float4 candidates = (values > (3.9f / 255.0f)) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
		uint localSum = dot(candidates, 1);
		atomicAdd(count, localSum);
		barrier();

		if(all(gtid.xy == 0))
		{
			tex2Dstore(wSum, gid.xy, packSum(count).xyxx);
		}
	}

	void StackAllocCS(uint3 id : SV_DispatchThreadID, uint3 gid : SV_GroupID, uint3 gtid : SV_GroupThreadID)
	{
		if(all(gtid.xy == 0))
			count = 0;
		barrier();
		uint index = id.x * STACK_ALLOC_PIXELS_PER_THREAD;
		uint localPrefixSum[STACK_ALLOC_PIXELS_PER_THREAD];
		localPrefixSum[0] = unpackSum(tex2Dfetch(sSum, uint2(index % DISPATCH_SIZE.x, index / DISPATCH_SIZE.x)).xy);
		[unroll]
		for(int i = 1; i < STACK_ALLOC_PIXELS_PER_THREAD; i++)
		{
			uint2 sampleCoord = uint2((index + i) % DISPATCH_SIZE.x, (index + i) / DISPATCH_SIZE.x);
			localPrefixSum[i] = unpackSum(tex2Dfetch(sSum, sampleCoord).xy) + localPrefixSum[i - 1];
		}

		uint baseCount = atomicAdd(count, localPrefixSum[STACK_ALLOC_PIXELS_PER_THREAD - 1]);

		tex2Dstore(wStackAlloc, uint2(index % DISPATCH_SIZE.x, index / DISPATCH_SIZE.x), asfloat(baseCount).xxxx);
		[unroll]
		for(int i = 1; i < STACK_ALLOC_PIXELS_PER_THREAD; i++)
		{
			uint2 sampleCoord = uint2((index + i) % DISPATCH_SIZE.x, (index + i) / DISPATCH_SIZE.x);
			tex2Dstore(wStackAlloc, sampleCoord, asfloat(baseCount + localPrefixSum[i - 1]).xxxx);
		}
	}

	void StackInsertionCS(uint3 id : SV_DispatchThreadID, uint3 gid : SV_GroupID, uint3 gtid : SV_GroupThreadID)
	{
		if(all(gtid.xy == 0))
			count = 0;
		barrier();

		uint writeAddress = asuint(tex2Dfetch(sStackAlloc, gid.xy).x);

		uint2 coord = id.xy * 2;
		float4 values = tex2DgatherA(sZShapes, float2(coord + 1) / float2(BUFFER_WIDTH, BUFFER_HEIGHT));
		float4 candidates = (values > (3.9f / 255.0f)) ? float4(1, 1, 1, 1) : float4(0, 0, 0, 0);
		uint localSum = dot(candidates, 1);
		uint localOffset = atomicAdd(count, localSum);
		uint j = 0;
		[unroll]
		for(int i = 0; i < 4; i++)
		{
			if(bool(candidates[i]))
			{
				uint address = writeAddress + localOffset + j;
				uint2 currCoord = (i == 0) ? uint2(coord.x, coord.y + 1) :
				   (i == 1) ? uint2(coord.x + 1, coord.y + 1) :
				   (i == 2) ? uint2(coord.x + 1, coord.y) : coord;
				uint packedCoord = (currCoord.x << 16 | currCoord.y);
				tex2Dstore(wZShapeCoords, uint2(address % BUFFER_WIDTH, address / BUFFER_WIDTH), asfloat(packedCoord).xxxx);
				j++;
			}
		}
	}
#endif

void LongEdgeVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD0, out float4 data : TANGENT0)
{
#if COMPUTE
	uint packedCoord = asuint(tex2Dfetch(sZShapeCoords, uint2((id / 2) % BUFFER_WIDTH, (id / 2) / BUFFER_WIDTH))).x;
	uint2 coord = uint2((packedCoord >> 16), (packedCoord & 0xFFFF));
#else
	uint2 coord = uint2((id / 2) % BUFFER_WIDTH, (id / 2) / BUFFER_WIDTH);
#endif
#if CMAA2_PERFORMANCE_HACK
	coord = uint2((id / 2) % (BUFFER_WIDTH / 2), (id / 2) / (BUFFER_WIDTH / 2)) * 2;
	float4 sampA = tex2Dfetch(sZShapes, coord + int2(0, 0));
	float4 sampB = tex2Dfetch(sZShapes, coord + int2(1, 0));
	float4 sampC = tex2Dfetch(sZShapes, coord + int2(0, 1));
	float4 sampD = tex2Dfetch(sZShapes, coord + int2(1, 1));

	sampA.z = (sampA.w > (3.9f / 255.0f)) ? sampA.z : 1;
	sampB.z = (sampB.w > (3.9f / 255.0f)) ? sampB.z : 1;
	sampC.z = (sampC.w > (3.9f / 255.0f)) ? sampC.z : 1;
	sampD.z = (sampD.w > (3.9f / 255.0f)) ? sampD.z : 1;

	float q = min(min(sampA.z, sampB.z), min(sampC.z, sampD.z));

	data = (sampA.z == q) ? sampA :
	       (sampB.z == q) ? sampB :
	       (sampC.z == q) ? sampC : sampD;

	coord += (sampA.z == q) ? int2(0, 0) :
	         (sampB.z == q) ? int2(1, 0) :
	         (sampC.z == q) ? int2(0, 1) : int2(1, 1);
#else
	data = tex2Dfetch(sZShapes, coord);
#endif

	if(!(data.w > (3.9f / 255.0f)))
	{
		position = -10;
		texcoord = -10;
	}
	else
	{
		bool horizontal;
		bool invertedZ;
		float shapeQualityScore;
		float lineLengthLeft;
		float lineLengthRight;
		unpackZ(data, horizontal, invertedZ, shapeQualityScore, lineLengthLeft, lineLengthRight);
		float loopFrom = -floor( ( lineLengthLeft + 1 ) / 2 ) + 1.0;
		float loopTo = floor( ( lineLengthRight + 1 ) / 2 );
		const float2 stepRight = ( horizontal ) ? float2( 1, 0 ) : float2( 0, -1 );
		float2 offset = (id % 2) ? stepRight * loopTo : stepRight * loopFrom;
		texcoord = (float2(coord + offset) + 0.5) / float2(BUFFER_WIDTH, BUFFER_HEIGHT);
		position = float4(texcoord.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
		texcoord = (id % 2) ? loopTo : loopFrom;
	}
}


void LongEdgePS(float4 position : SV_Position, float2 texcoord : TEXCOORD0, float4 info : TANGENT0, out float4 output : SV_TARGET0)
{
	output = 1;
	bool horizontal;// = floor(info.w / 2);
	bool invertedZShape;// = floor(info.w % 2);
	float shapeQualityScore;// = info.z;
	float lineLengthLeft;// = info.x;
	float lineLengthRight;// = info.y;
	unpackZ(info, horizontal, invertedZShape, shapeQualityScore, lineLengthLeft, lineLengthRight);
	float2 blendDir = ( horizontal ) ? float2( 0, -1 ) : float2( -1, 0 );
	float i = ( horizontal ) ? texcoord.x : texcoord.y;
	if( invertedZShape )
		blendDir = -blendDir;

	float leftOdd = c_symmetryCorrectionOffset * float( lineLengthLeft % 2 );
	float rightOdd = c_symmetryCorrectionOffset * float( lineLengthRight % 2 );

	float dampenEffect = saturate( float(lineLengthLeft + lineLengthRight - shapeQualityScore) * c_dampeningEffect ) ;

	float loopFrom = -floor( ( lineLengthLeft + 1 ) / 2 ) + 1.0;
	float loopTo = floor( ( lineLengthRight + 1 ) / 2 );

	float totalLength = float(loopTo - loopFrom) + 1 - leftOdd - rightOdd;
	float lerpStep = float(1.0) / totalLength;

	float lerpFromK = (0.5 - leftOdd - loopFrom) * lerpStep;

	float lerpVal = mad(lerpStep, i, lerpFromK);

	bool  secondPart = (i > 0);
	float srcOffset = 1.0 - (secondPart * 2.0);

	float lerpK = lerpVal * srcOffset + secondPart;
	lerpK *= dampenEffect;

	output.rgb = tex2D(sBackBuffer, ((position.xy + blendDir * float(srcOffset).xx * lerpK) + .5) * float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)).rgb;
	output = output * 2.25;
}


void ApplyPS(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 output : SV_TARGET)
{
	float2 coord = position.xy;
	output = tex2Dfetch(sProcessedCandidates, coord);

#if g_CMAA2_DebugEdges
	float4 edges = UnpackEdges(tex2Dfetch(sEdges, coord).x * 255.5);
	output = float4( lerp( edges.xyz, 0.5.xxx, edges.a * 0.2 ), saturate(edges.x + edges.y + edges.z + edges.w) );
#endif

	//output =  tex2Dfetch(sBackBuffer, coord);
	if(output.a <= 0.5)
		discard;

	output.rgb /= output.a;
}


void ClearVS(in uint id : SV_VertexID, out float4 position : SV_Position)
{
	position = -3;
}

void ClearPS(float4 position : SV_Position, out float4 output0 : SV_TARGET0)
{
	output0 = 0;
	discard;
}



technique CMAA_2 < ui_tooltip = "A port of Intel's CMAA 2.0 (Conservative Morphological Anti-Aliasing) to ReShade\n\n"
                                "Ported to ReShade by: Lord Of Lunacy";>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = EdgesPS;
		RenderTarget0 = Edges;
	}
#if !COMPUTE
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ProcessEdgesPS;
		RenderTarget0 = ProcessedCandidates;
		RenderTarget1 = ZShapes;
		ClearRenderTargets = true;
	}
#else
	pass
	{
		VertexShader = ClearVS;
		PixelShader = ClearPS;
		RenderTarget0 = ZShapeCoords;
		ClearRenderTargets = true;
		PrimitiveTopology = POINTLIST;
		VertexCount = 1;
	}

	pass
	{
		VertexShader = ClearVS;
		PixelShader = ClearPS;
		RenderTarget0 = ProcessedCandidates;
		RenderTarget1 = ZShapes;
		ClearRenderTargets = true;
		PrimitiveTopology = POINTLIST;
		VertexCount = 1;
	}

	pass
	{
		ComputeShader = ProcessEdgesCS<EDGE_GROUP_SIZE.x, EDGE_GROUP_SIZE.y>;
		DispatchSizeX = EDGE_DISPATCH_SIZE.x;
		DispatchSizeY = EDGE_DISPATCH_SIZE.y;
	}

	pass
	{
		ComputeShader = SumCS<GROUP_SIZE.x, GROUP_SIZE.y>;
		DispatchSizeX = DISPATCH_SIZE.x;
		DispatchSizeY = DISPATCH_SIZE.y;
	}

	pass
	{
		ComputeShader = StackAllocCS<STACK_ALLOC_THREADS, 1>;
		DispatchSizeX = 1;
		DispatchSizeY = 1;
	}

	pass
	{
		ComputeShader = StackInsertionCS<GROUP_SIZE.x, GROUP_SIZE.y>;
		DispatchSizeX = DISPATCH_SIZE.x;
		DispatchSizeY = DISPATCH_SIZE.y;
	}
#endif

	pass
	{
		VertexShader = LongEdgeVS;
		PixelShader = LongEdgePS;
		PrimitiveTopology = LINELIST;
#if COMPUTE
		VertexCount = (BUFFER_WIDTH * DIVIDE_ROUNDING_UP(BUFFER_HEIGHT, VERTEX_COUNT_DENOMINATOR) * 2);
#elif CMAA2_PERFORMANCE_HACK
		VertexCount = (BUFFER_WIDTH * BUFFER_HEIGHT) / 2;
#else
		VertexCount = (BUFFER_WIDTH * BUFFER_HEIGHT * 2);
#endif
		ClearRenderTargets = false;

		BlendEnable = true;

		BlendOp = ADD;
		BlendOpAlpha = ADD;

		SrcBlend = ONE;
		SrcBlendAlpha = ONE;
		DestBlend = ONE;
		DestBlendAlpha = ONE;

		RenderTarget = ProcessedCandidates;
	}

	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ApplyPS;

		BlendEnable = true;

		BlendOp = ADD;
		BlendOpAlpha = ADD;
		
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
	}
}
}

#endif //SUPPORTED
