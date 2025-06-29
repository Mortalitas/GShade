/*------------------.
| :: Description :: |
'-------------------/

	Compare (version 1.0)

	Author: CeeJay.dk
	License: MIT

	About:
	Compares the output of two effects against each other using difference blending.
	Place this effect between two other effects to see their differences.
	
	Usage:
	1. Enable Capture [Compare.fx]
	2. Enable effect A
	3. Enable Restore [Compare.fx]
	4. Enable effect B
	5. Enable Compare [Compare.fx]

	Ideas for future improvement:
	* Separator lines
	* More blend modes?
	* Moving separator
	* Mouse-set separator
	* Alpha comparison?

	History:
	(*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
	
	Version 1.0 (Based on Splitscreen by CeeJay.dk)
	* Initial version for comparing two effects
	* Added difference blending with user scaling
	* Three-technique workflow: Capture -> Restore -> Compare

	The MIT License (MIT)

	Copyright (c) 2014 CeeJayDK

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/

/*------------------.
| :: UI Settings :: |
'------------------*/

uniform int ui_instructions 
<
	ui_category = "Instructions";
	ui_type = "radio";
	ui_label = " ";
	ui_text =
		"1. Enable 'Capture' technique first\n"
		"2. Enable Effect A\n"
		"3. Enable 'Restore' technique\n"
		"4. Enable Effect B\n"
		"5. Enable 'Compare' technique\n\n"
		"The Compare technique will show the differences between Effect A and Effect B using various visualization modes.";
>;

uniform int compare_mode 
<
	ui_type = "combo";
	ui_label = "Mode";
	ui_tooltip = "Choose a comparison mode";
	ui_spacing = 2;
	ui_items = 
	"Vertical 50/50 split\0"
	"Vertical 25/50/25 split\0"
	"Angled 50/50 split\0"
	"Angled 25/50/25 split\0"
	"Horizontal 50/50 split\0"
	"Horizontal 25/50/25 split\0"
	"Diagonal split\0"
	"Difference blend (absolute)\0"
	"Difference blend (signed)\0"
	;
> = 7;

uniform float difference_scale 
<
	ui_type = "slider";
	ui_label = "Difference Scale";
	ui_tooltip = "Multiplier for difference visibility";
	ui_min = 1.0;
	ui_max = 20.0;
	ui_step = 0.1;
> = 5.0;

/*---------------.
| :: Includes :: |
'---------------*/

#include "ReShade.fxh"

/*-------------------------.
| :: Texture and sampler:: |
'-------------------------*/

texture OriginalBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler OriginalSampler { Texture = OriginalBuffer; };

texture EffectABuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler EffectASampler { Texture = EffectABuffer; };

/*-------------.
| :: Effect :: |
'-------------*/

// Capture: Store the original unprocessed buffer
float3 PS_Capture(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(ReShade::BackBuffer, texcoord).rgb;
}

// Restore: Display original image
float3 PS_Restore(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(OriginalSampler, texcoord).rgb;
}

// Compare: Compare the original and two effects
float3 PS_Compare(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	const float3 original = tex2D(OriginalSampler, texcoord).rgb;  // Original unprocessed
	const float3 effectA = tex2D(EffectASampler, texcoord).rgb;  // Effect A 
	const float3 effectB = tex2D(ReShade::BackBuffer, texcoord).rgb;  // Effect B (current)
	float3 color;

	// -- Vertical 50/50 split --
	[branch] if (compare_mode == 0)
		color = (texcoord.x < 0.5) ? effectA : effectB;

	// -- Vertical 25/50/25 split: effectA | original | effectB --
	[branch] if (compare_mode == 1)
	{
		if (texcoord.x < 0.333)
			color = effectA;
		else if (texcoord.x < 0.666)
			color = original;
		else
			color = effectB;
	}

	// -- Angled 50/50 split --
	[branch] if (compare_mode == 2)
	{
		float dist = ((texcoord.x - 3.0/8.0) + (texcoord.y * 0.25));
		dist = saturate(dist - 0.25);
		color = dist ? effectB : effectA;
	}

	// -- Angled 25/50/25 split: effectA | original | effectB --
	[branch] if (compare_mode == 3)
	{
		float angle = texcoord.x + texcoord.y * 0.5;
		if (angle < 0.5)
			color = effectA;
		else if (angle < 1.0)
			color = original;
		else
			color = effectB;
	}

	// -- Horizontal 50/50 split --
	[branch] if (compare_mode == 4)
		color = (texcoord.y < 0.5) ? effectA : effectB;

	// -- Horizontal 25/50/25 split: effectA | original | effectB --
	[branch] if (compare_mode == 5)
	{
		if (texcoord.y < 0.333)
			color = effectA;
		else if (texcoord.y < 0.666)
			color = original;
		else
			color = effectB;
	}

	// -- Diagonal split --
	[branch] if (compare_mode == 6)
	{
		const float dist = (texcoord.x + texcoord.y);
		color = (dist < 1.0) ? effectA : effectB;
	}

	// -- Difference blend (absolute) --
	[branch] if (compare_mode == 7)
	{
		const float3 difference = abs(effectB - effectA);
		color = difference * difference_scale;
	}

	// -- Difference blend (signed) --
	[branch] if (compare_mode == 8)
	{
		const float3 difference = effectB - effectA;
		color = (difference * difference_scale) + 0.5;
	}

	return color;
}

/*-----------------.
| :: Techniques :: |
'-----------------*/

technique Capture 
<
	ui_tooltip = "Step 1: Capture original image before any effects.";
>
{
	pass Capture_Original
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Capture;
		RenderTarget = OriginalBuffer;
	}
}

technique Restore 
<
	ui_tooltip = "Step 2: Capture Effect A and restore original image.";
>
{
	pass Capture_EffectA
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Capture;
		RenderTarget = EffectABuffer;
	}
	
	pass Restore
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Restore;
	}
}

technique Compare 
<
	ui_tooltip = "Step 3: Compare Effect A and Effect B with various visualization modes.";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Compare;
	}
}
