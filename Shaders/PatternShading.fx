////////////////////////////////////////////////////////
// PatternShading
// Author: EDCVBNM
// Repository: https://github.com/EDCVBNM/ED-shaders
////////////////////////////////////////////////////////

#include "ReShade.fxh"

uniform float threshold <
	ui_type = "slider";
	ui_label = "Brightness";
	ui_min = 0.0; ui_max = 1.0;
> = 0.1;

uniform int steps <
    ui_label = "Amount of Shades";
    ui_type  = "combo";
    ui_items = " 2\0 3\0 4\0 5\0";
> = 3;

uniform bool test <
> = false;

float3 patternShading(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : COLOR
{
	int pattern, pattern1, pattern2, pattern3;
	float luma = dot(tex2D(ReShade::BackBuffer, texcoord).rgb, 1.0 / 3.0);

	if(test)
	{
		luma = lerp(0.0, 1.0, texcoord.x);
	}
	
	if(pos.x % 2 <= 1 && pos.y % 2 <= 1)
	{
		pattern = 0;
	}
	else
	{
		pattern = 1;
	}

	if((pos.x + 1) % 2 <= 1 && (pos.y - 1) % 2 <= 1)
	{
		pattern1 = 1;
	}
	else
	{
		pattern1 = 0;
	}

	if(pos.x % 2 <= 1 && (pos.y - 1) % 2 <= 1)
	{
		pattern2 = 1;
	}
	else
	{
		pattern2 = 0;
	}

	if(pos.x % 2 <= 1 && pos.y % 2 <= 1 || (pos.x + 1) % 2 <= 1 && (pos.y + 1) % 2 <= 1)
	{
		pattern3 = 0;
	}
	else
	{
		pattern3 = 1;
	}

	if(steps == 0)
	{
		pattern = ceil(1.0 - step(luma, threshold));
	}
	else if(steps == 1)
	{
		if(luma <= threshold)
		{
			pattern = 0;
		}
		else if(luma <= threshold * 2)
		{
			pattern = pattern3;
		}
		else if(luma > threshold * 2)
		{
			pattern = 1;
		}
	}
	else if(steps == 2)
	{
		if(luma <= threshold)
		{
			pattern = 0;
		}
		else if(luma <= threshold * 2)
		{
			pattern = pattern1;
		}
		else if(luma > threshold * 3)
		{
			pattern = 1;
		}
	}
	else
	{
		if(luma <= threshold)
		{
			pattern = 0;
		}
		else if(luma <= threshold * 2)
		{
			pattern = pattern2;
		}
		else if(luma <= threshold * 3)
		{
			pattern = pattern3;
		}
		else if(luma > threshold * 4)
		{
			pattern = 1;
		}
	}

	return pattern;
}

technique PatternShading
{
	pass pass0
	{
		VertexShader = PostProcessVS;
		PixelShader = patternShading;
	}
}
