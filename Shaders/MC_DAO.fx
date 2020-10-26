/*
 	Disk Ambient Occlusion by Constantine 'MadCake' Rudenko

 	License: https://creativecommons.org/licenses/by/4.0/
	CC BY 4.0
	
	You are free to:

	Share — copy and redistribute the material in any medium or format
		
	Adapt — remix, transform, and build upon the material
	for any purpose, even commercially.

	The licensor cannot revoke these freedoms as long as you follow the license terms.
		
	Under the following terms:

	Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. 
	You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

	No additional restrictions — You may not apply legal terms or technological measures 
	that legally restrict others from doing anything the license permits.
*/

uniform float Strength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 8.0; ui_step = 0.1;
	ui_tooltip = "Strength of the effect (recommended 0.6)";
	ui_label = "Strength";
> = 1.0;

uniform int SampleDistance <
	ui_type = "slider";
	ui_min = 1; ui_max = 64;
	ui_tooltip = "Sampling disk radius (in pixels)\nrecommended: 32";
	ui_label = "Sampling disk radius";
> = 32.0;

uniform int NumSamples <
	ui_type = "slider";
	ui_min = 1; ui_max = 32;
	ui_tooltip = "Number of samples (higher numbers give better quality at the cost of performance)\nrecommended: 8";
	ui_label = "Number of samples";
> = 8;

uniform float StartFade <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 3.0; ui_step = 0.1;
	ui_tooltip = "AO starts fading when Z difference is greater than this\nmust be bigger than \"Z difference end fade\"\nrecommended: 0.5";
	ui_label = "Z difference start fade";
> = 0.5;

uniform float EndFade <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 3.0; ui_step = 0.1;
	ui_tooltip = "AO completely fades when Z difference is greater than this\nmust be bigger than \"Z difference start fade\"\nrecommended: 0.6";
	ui_label = "Z difference end fade";
> = 0.6;

uniform float NormalBias <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.025;
	ui_tooltip = "prevents self occlusion (recommended 0.1)";
	ui_label = "Normal bias";
> = 0.1;

uniform int DebugEnabled <
    ui_type = "combo";
    ui_label = "Enable Debug View";
    ui_items = "Disabled\0Blurred\0Before Blur\0";
> = 0;

uniform int BlurRadius <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 32.0;
	ui_tooltip = "Blur radius (in pixels)\nrecommended: 4 to 8";
	ui_label = "Blur radius";
> = 4.0;

uniform float BlurQuality <
		ui_type = "slider";
		ui_min = 0.5; ui_max = 1.0; ui_step = 0.1;
		ui_label = "Blur Quality";
		ui_tooltip = "Blur quality (recommended 0.6)";
> = 0.6;

uniform float Gamma <
		ui_type = "slider";
		ui_min = 1.0; ui_max = 4.0; ui_step = 0.1;
		ui_label = "Gamma";
        ui_tooltip = "Recommended 2.2\n(assuming the texture is stored with gamma applied)";
> = 2.2;

uniform float NormalPower <
		ui_type = "slider";
		ui_min = 0.5; ui_max = 8.0; ui_step = 0.1;
		ui_label = "Normal power";
        ui_tooltip = "Acts like softer version of normal bias without a threshold\nrecommended: 1.4";
> = 1.4;

uniform int FOV <
		ui_type = "slider";
		ui_min = 40; ui_max = 180; ui_step = 1.0;
		ui_label = "FOV";
        ui_tooltip = "Leaving it at 90 regardless of your actual FOV provides accetable results";
> = 90;

uniform float DepthShrink <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
		ui_label = "Depth shrink";
        ui_tooltip = "Higher values cause AO to become finer on distant objects\nrecommended: 0.65";
> = 0.65;

#include "ReShade.fxh"

texture2D AOTex	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R16F; MipLevels = 1;};
texture2D AOTex2	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R16F; MipLevels = 1;};

sampler2D sAOTex { Texture = AOTex; };
sampler2D sAOTex2 { Texture = AOTex2; };

float GetTrueDepth(float2 coords)
{
	return ReShade::GetLinearizedDepth(coords) * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
}

float3 GetPosition(float2 coords)
{
	float2 fov;
	fov.x = FOV / 180.0 * 3.1415;
	fov.y = fov.x / BUFFER_ASPECT_RATIO; 
	float3 pos;
	pos.z = GetTrueDepth(coords.xy);
	coords.y = 1.0 - coords.y;
	pos.xy = coords.xy * 2.0 - 1.0;
	pos.xy /= float2(1.0 / tan(fov.x * 0.5), 1.0 / tan(fov.y * 0.5)) / pos.z;
	return pos;
}

float3 GetNormalFromDepth(float2 coords) 
{
	const float3 centerPos = GetPosition(coords);

	const float2 offx = float2(BUFFER_PIXEL_SIZE.x, 0);
	const float2 offy = float2(0, BUFFER_PIXEL_SIZE.y);

	return normalize(cross((GetPosition(coords + offx) - centerPos) + (centerPos - GetPosition(coords - offx)), (GetPosition(coords + offy) - centerPos) + (centerPos - GetPosition(coords - offy))));
}

float rand2D(float2 uv)
{
	uv = frac(uv);
	return frac(cos((frac(cos(uv.x*64)*256) + frac(cos(uv.y*137)*241)) * 107) * 269);
}

float3 BlurAOHorizontalPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float range = clamp(BlurRadius, 1, 32);

	const float tmp = 1.0 / (range * range);
	float gauss = 1.0;
	float helper = exp(tmp * 0.5);
	const float helper2 = exp(tmp);
	float sum = tex2Dlod(sAOTex, float4(texcoord, 0.0, 0.0)).r;
	float sumCoef = 1.0;

	range *= 3.0 * clamp(BlurQuality, 0.0, 1.0);

	float2 off = float2(BUFFER_PIXEL_SIZE.x, 0);

	[loop]
	for(int k = 1; k < range; k++){
		gauss = gauss / helper;
		helper = helper * helper2;
		sumCoef += gauss * 2.0;
		sum += (tex2Dlod(sAOTex, float4(texcoord + off * k, 0.0, 0.0)).r * gauss) + (tex2Dlod(sAOTex, float4(texcoord - off * k, 0.0, 0.0)).r * gauss);
	}

	return sum / sumCoef;
}


float3 BlurAOVerticalPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float range = clamp(BlurRadius, 1, 32);

	const float tmp = 1.0 / (range * range);
	float gauss = 1.0;
	float helper = exp(tmp * 0.5);
	const float helper2 = exp(tmp);
	float sum = tex2D(sAOTex2, texcoord).r;
	float sumCoef = 1.0;

	range *= 3.0 * clamp(BlurQuality, 0.0, 1.0);

	const float2 off = float2(0, BUFFER_PIXEL_SIZE.y);

	[loop]
	for(int k = 1; k < range; k++){
		gauss = gauss / helper;
		helper = helper * helper2;
		sumCoef += gauss * 2.0;
		sum += (tex2Dlod(sAOTex2, float4(texcoord + off * k, 0.0, 0.0)).r * gauss) + (tex2Dlod(sAOTex2, float4(texcoord - off * k, 0.0, 0.0)).r * gauss);
	}

	sum = sum / sumCoef;
	
	if (DebugEnabled == 2)
	{
		return tex2D(sAOTex, texcoord).r;
	}

	if (DebugEnabled == 1)
	{
		return sum;
	}

	return pow(abs(pow(abs(tex2D(ReShade::BackBuffer, texcoord).rgb), 1.0 / Gamma) * sum), Gamma);
}

float2 ensure_1px_offset(float2 ray)
{
	const float2 ray_in_pixels = ray / BUFFER_PIXEL_SIZE;
	const float coef = max(abs(ray_in_pixels.x), abs(ray_in_pixels.y));
	if (coef < 1.0)
	{
		ray /= coef;
	}
	return ray;
}

float3 MadCakeDiskAOPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	const float3 position = GetPosition(texcoord);
	const float3 normal = GetNormalFromDepth(texcoord);

	const int num_samples = clamp(NumSamples, 1, 64);
	const int sample_dist = clamp(SampleDistance, 1, 128);
	const float start_fade = clamp(StartFade, 0.0, 3.0);
	const float normal_bias = clamp(NormalBias, 0.0, 1.0);

	float occlusion = 0;
	const float fade_range = clamp(EndFade, 0.0, 3.0) - start_fade;

	const float angle_jitter_minor = rand2D(texcoord);
	const float angle_jitter_major = rand2D(texcoord + float2(-1, 0)) * 3.1415 * 2.0 * 0;

	[loop]
	for (int i = 0; i < num_samples; i++)
	{
		float angle = 3.1415 * 2.0 / num_samples * (i + angle_jitter_minor) + angle_jitter_major;
		float radius_jitter = rand2D(texcoord + float2(i, 1));
		float radius_coef = max((i + radius_jitter) / num_samples, 0.001);
		float3 v = GetPosition(texcoord + ensure_1px_offset((((float2(sin(angle), cos(angle)) * BUFFER_PIXEL_SIZE * sample_dist) / (1.0 + position.z * lerp(0, 0.05, pow(DepthShrink,4)))) * radius_coef))) - position;
		float ray_occlusion = saturate((pow(abs(dot(normal, normalize(v))), NormalPower) - normal_bias) / (1.0 - normal_bias));
		float zdiff = abs(v.z);
		if (zdiff >= start_fade)
		{
			ray_occlusion *= saturate(1.0 - (zdiff - start_fade) / fade_range);
		}
		occlusion += ray_occlusion / num_samples;
	}
	return saturate(1.0 - occlusion * Strength);
}

technique MC_DAO
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MadCakeDiskAOPass;
		RenderTarget0 = AOTex;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BlurAOHorizontalPass;
		RenderTarget0 = AOTex2;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BlurAOVerticalPass;
	}
}
