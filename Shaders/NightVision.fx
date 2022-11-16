// by Nikos Papadopoulos, 4rknova / 2013
// WTFPL

#include "ReShade.fxh"

uniform float iGlobalTime < source = "timer"; >;

float hash(in float n) { return frac(sin(max(n, 0.000001))*43758.5453123); }

float3 PS_Nightvision(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{	
	const float2 p = uv;
	
	const float2 u = p * 2. - 1.;
	const float2 n = u * float2(BUFFER_ASPECT_RATIO, 1.0);
	float3 c = tex2D(ReShade::BackBuffer, uv).xyz;

	// flicker, grain, vignette, fade in
	c += sin(hash(iGlobalTime*0.001)) * 0.01;
	c += hash((hash(n.x) + n.y) * iGlobalTime*0.001) * 0.5;
	c *= smoothstep(length(n * n * n * float2(0.0, 0.0)), 1.0, 0.4);
    c *= smoothstep(0.001, 3.5, iGlobalTime*0.001) * 1.5;
	
	return dot(c, float3(0.2126, 0.7152, 0.0722)) 
	  * float3(0.2, 1.5 - hash(iGlobalTime*0.001) * 0.1,0.4);
}

technique Nightvision {
	pass Nightvision {
		VertexShader=PostProcessVS;
		PixelShader=PS_Nightvision;
	}
}
