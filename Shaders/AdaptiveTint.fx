/*******************************************************
	ReShade Shader: Adaptive Tint
	https://github.com/Daodan317081/reshade-shaders
	License: BSD 3-Clause
	Modified by Marot for ReShade 4.0 compatibility and optimized for the GShade project.

	BSD 3-Clause License

	Copyright (c) 2018-2019, Alexander Federwisch
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this
	list of conditions and the following disclaimer.

	* Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.

	* Neither the name of the copyright holder nor the names of its
	contributors may be used to endorse or promote products derived from
	this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
	OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************/

#include "ReShade.fxh"
#include "Dao_Stats.fxh"
#include "Dao_Tools.fxh"

#if GSHADE_DITHER
    #include "TriDither.fxh"
#endif

#define UI_CATEGORY_CURVES "Curves"
#define UI_CATEGORY_COLOR "Color"
#define UI_CATEGORY_GENERAL "General"

uniform int iUIInfo<
	ui_type = "combo";
	ui_label = "Info";
	ui_items = "Info\0";
	ui_tooltip = "Enable Technique 'CalculateStats_MoveToTop'";
> = 0;

uniform int iUIWhiteLevelFormula <
	ui_type = "combo";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "White Level Curve (red)";
	ui_items = "Linear: x * (value - y) + z\0Square: x * (value - y)^2 + z\0Cube: x * (value - y)^3 + z\0";
> = 1;

uniform float3 f3UICurveWhiteParam <
	ui_type = "slider";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "Curve Parameters";
	ui_min = -10.0; ui_max = 10.0;
	ui_step = 0.01;
> = float3(-0.5, 1.0, 1.0);

uniform int iUIBlackLevelFormula <
	ui_type = "combo";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "Black Level Curve (cyan)";
	ui_items = "Linear: x * (value - y) + z\0Square: x * (value - y)^2 + z\0Cube: x * (value - y)^3 + z\0";
> = 1;

uniform float3 f3UICurveBlackParam <
	ui_type = "slider";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "Curve Parameters";
	ui_min = -10.0; ui_max = 10.0;
	ui_step = 0.01;
> = float3(0.5, 0.0, 0.0);

uniform float fUIColorTempScaling <
	ui_type = "slider";
	ui_category = UI_CATEGORY_CURVES;
	ui_label = "Color Temperature Scaling";
	ui_min = 1.0; ui_max = 10.0;
	ui_step = 0.01;
> = 2.0;

uniform float fUISaturation <
	ui_type = "slider";
	ui_label = "Saturation";
	ui_category = UI_CATEGORY_COLOR;
	ui_min = -1.0; ui_max = 1.0;
	ui_step = 0.001;
> = 0.0;

uniform float3 fUITintWarm <
	ui_type = "color";
	ui_category = UI_CATEGORY_COLOR;
    ui_label = "Warm Tint";
> = float3(0.04, 0.04, 0.02);

uniform float3 fUITintCold <
	ui_type = "color";
	ui_category = UI_CATEGORY_COLOR;
    ui_label = "Cold Tint";
> = float3(0.02, 0.04, 0.04);

uniform float fUIStrength <
	ui_type = "slider";
	ui_category = UI_CATEGORY_GENERAL;
	ui_label = "Strength";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;


/*******************************************************
	Functions
*******************************************************/
float2 CalculateLevels(float avgLuma) {
	float2 level = float2(0.0, 0.0);

	if(iUIBlackLevelFormula == 2)
		level.x = f3UICurveBlackParam.x * pow(avgLuma - f3UICurveBlackParam.y, 3) + f3UICurveBlackParam.z;
	else if(iUIBlackLevelFormula == 1)
		level.x = f3UICurveBlackParam.x * ((avgLuma - f3UICurveBlackParam.y) * 2) + f3UICurveBlackParam.z;
	else
		level.x = f3UICurveBlackParam.x * (avgLuma - f3UICurveBlackParam.y) + f3UICurveBlackParam.z;
	
	if(iUIWhiteLevelFormula == 2)
		level.y = f3UICurveWhiteParam.x * pow(avgLuma - f3UICurveWhiteParam.y, 3) + f3UICurveWhiteParam.z;
	else if(iUIWhiteLevelFormula == 1)
		level.y = f3UICurveWhiteParam.x * ((avgLuma - f3UICurveWhiteParam.y) * 2) + f3UICurveWhiteParam.z;
	else
		level.y = f3UICurveWhiteParam.x * (avgLuma - f3UICurveWhiteParam.y) + f3UICurveWhiteParam.z;

	return saturate(level);
}

float GetColorTemp(float2 texcoord) {
	const float colorTemp = Stats::AverageColorTemp();
	return Tools::Functions::Map(colorTemp * fUIColorTempScaling, YIQ_I_RANGE, FLOAT_RANGE);
}

/*******************************************************
	Main Shader
*******************************************************/
float3 AdaptiveTint_PS(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	/*******************************************************
		Get BackBuffer and both LUTs
	*******************************************************/
	const float3 backbuffer = tex2D(ReShade::BackBuffer, texcoord).rgb;
	const float3 lutWarm = fUITintWarm * backbuffer;
	const float3 lutCold = fUITintCold * backbuffer;

	/*******************************************************
		Interpolate between both LUTs
	*******************************************************/
	const float colorTemp = GetColorTemp(texcoord);
	const float3 tint = lerp(lutCold, lutWarm, colorTemp);

	/*******************************************************
		Apply black and white levels to luma, desaturate
	*******************************************************/
	const float3 luma   = dot(backbuffer, LumaCoeff).rrr;
	const float2 levels = CalculateLevels(Stats::AverageLuma());
	const float3 factor = Tools::Functions::Level(luma.r, levels.x, levels.y).rrr;
	const float3 result = lerp(tint, lerp(luma, backbuffer, fUISaturation + 1.0), factor);

#if GSHADE_DITHER
    const float3 color = lerp(backbuffer, result, fUIStrength);
	return color + TriDither(color, texcoord, BUFFER_COLOR_BIT_DEPTH);
#else
	return lerp(backbuffer, result, fUIStrength);
#endif
}

technique AdaptiveTint
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = AdaptiveTint_PS;
	}
}