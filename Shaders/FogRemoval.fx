/*
Reshade Fog Removal
By: Lord of Lunacy
License: CC0 1.0 Universal

This shader attempts to remove fog so that affects that experience light bleeding from it can be applied,
and then reintroduce the fog over the image.



This code was inspired by the following paper:

B. Cai, X. X, K. Jia, C. Qing, and D. Tao, “DehazeNet: An End-to-End System for Single Image Haze Removal,”
IEEE Transactions on Image Processing, vol. 25, no. 11, pp. 5187–5198, 2016.



CC0 1.0 Universal

    CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
    LEGAL SERVICES. DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN
    ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS
    INFORMATION ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES
    REGARDING THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS
    PROVIDED HEREUNDER, AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM
    THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED
    HEREUNDER.

Statement of Purpose

The laws of most jurisdictions throughout the world automatically confer
exclusive Copyright and Related Rights (defined below) upon the creator
and subsequent owner(s) (each and all, an "owner") of an original work of
authorship and/or a database (each, a "Work").

Certain owners wish to permanently relinquish those rights to a Work for
the purpose of contributing to a commons of creative, cultural and
scientific works ("Commons") that the public can reliably and without fear
of later claims of infringement build upon, modify, incorporate in other
works, reuse and redistribute as freely as possible in any form whatsoever
and for any purposes, including without limitation commercial purposes.
These owners may contribute to the Commons to promote the ideal of a free
culture and the further production of creative, cultural and scientific
works, or to gain reputation or greater distribution for their Work in
part through the use and efforts of others.

For these and/or other purposes and motivations, and without any
expectation of additional consideration or compensation, the person
associating CC0 with a Work (the "Affirmer"), to the extent that he or she
is an owner of Copyright and Related Rights in the Work, voluntarily
elects to apply CC0 to the Work and publicly distribute the Work under its
terms, with knowledge of his or her Copyright and Related Rights in the
Work and the meaning and intended legal effect of CC0 on those rights.

1. Copyright and Related Rights. A Work made available under CC0 may be
protected by copyright and related or neighboring rights ("Copyright and
Related Rights"). Copyright and Related Rights include, but are not
limited to, the following:

  i. the right to reproduce, adapt, distribute, perform, display,
     communicate, and translate a Work;
 ii. moral rights retained by the original author(s) and/or performer(s);
iii. publicity and privacy rights pertaining to a person's image or
     likeness depicted in a Work;
 iv. rights protecting against unfair competition in regards to a Work,
     subject to the limitations in paragraph 4(a), below;
  v. rights protecting the extraction, dissemination, use and reuse of data
     in a Work;
 vi. database rights (such as those arising under Directive 96/9/EC of the
     European Parliament and of the Council of 11 March 1996 on the legal
     protection of databases, and under any national implementation
     thereof, including any amended or successor version of such
     directive); and
vii. other similar, equivalent or corresponding rights throughout the
     world based on applicable law or treaty, and any national
     implementations thereof.

2. Waiver. To the greatest extent permitted by, but not in contravention
of, applicable law, Affirmer hereby overtly, fully, permanently,
irrevocably and unconditionally waives, abandons, and surrenders all of
Affirmer's Copyright and Related Rights and associated claims and causes
of action, whether now known or unknown (including existing as well as
future claims and causes of action), in the Work (i) in all territories
worldwide, (ii) for the maximum duration provided by applicable law or
treaty (including future time extensions), (iii) in any current or future
medium and for any number of copies, and (iv) for any purpose whatsoever,
including without limitation commercial, advertising or promotional
purposes (the "Waiver"). Affirmer makes the Waiver for the benefit of each
member of the public at large and to the detriment of Affirmer's heirs and
successors, fully intending that such Waiver shall not be subject to
revocation, rescission, cancellation, termination, or any other legal or
equitable action to disrupt the quiet enjoyment of the Work by the public
as contemplated by Affirmer's express Statement of Purpose.

3. Public License Fallback. Should any part of the Waiver for any reason
be judged legally invalid or ineffective under applicable law, then the
Waiver shall be preserved to the maximum extent permitted taking into
account Affirmer's express Statement of Purpose. In addition, to the
extent the Waiver is so judged Affirmer hereby grants to each affected
person a royalty-free, non transferable, non sublicensable, non exclusive,
irrevocable and unconditional license to exercise Affirmer's Copyright and
Related Rights in the Work (i) in all territories worldwide, (ii) for the
maximum duration provided by applicable law or treaty (including future
time extensions), (iii) in any current or future medium and for any number
of copies, and (iv) for any purpose whatsoever, including without
limitation commercial, advertising or promotional purposes (the
"License"). The License shall be deemed effective as of the date CC0 was
applied by Affirmer to the Work. Should any part of the License for any
reason be judged legally invalid or ineffective under applicable law, such
partial invalidity or ineffectiveness shall not invalidate the remainder
of the License, and in such case Affirmer hereby affirms that he or she
will not (i) exercise any of his or her remaining Copyright and Related
Rights in the Work or (ii) assert any associated claims and causes of
action with respect to the Work, in either case contrary to Affirmer's
express Statement of Purpose.

4. Limitations and Disclaimers.

 a. No trademark or patent rights held by Affirmer are waived, abandoned,
    surrendered, licensed or otherwise affected by this document.
 b. Affirmer offers the Work as-is and makes no representations or
    warranties of any kind concerning the Work, express, implied,
    statutory or otherwise, including without limitation warranties of
    title, merchantability, fitness for a particular purpose, non
    infringement, or the absence of latent or other defects, accuracy, or
    the present or absence of errors, whether or not discoverable, all to
    the greatest extent permissible under applicable law.
 c. Affirmer disclaims responsibility for clearing rights of other persons
    that may apply to the Work or any use thereof, including without
    limitation any person's Copyright and Related Rights in the Work.
    Further, Affirmer disclaims responsibility for obtaining any necessary
    consents, permissions or other rights required for any use of the
    Work.
 d. Affirmer understands and acknowledges that Creative Commons is not a
    party to this document and has no duty or obligation with respect to
this CC0 or use of the Work.
*/



#undef SAMPLEDISTANCE
#define SAMPLEDISTANCE 15

#define SAMPLEDISTANCE_SQUARED (SAMPLEDISTANCE*SAMPLEDISTANCE)
#define SAMPLEHEIGHT (BUFFER_HEIGHT / SAMPLEDISTANCE)
#define SAMPLEWIDTH (BUFFER_WIDTH / SAMPLEDISTANCE)
#define SAMPLECOUNT (SAMPLEHEIGHT * SAMPLEWIDTH)
#define SAMPLECOUNT_RCP (1/SAMPLECOUNT)
#define HISTOGRAMPIXELSIZE (1/255)



#include "ReShade.fxh"



uniform float STRENGTH<
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Strength";
	ui_tooltip = "Setting strength to high is known to cause bright regions to turn black before reintroduction.";
	ui_bind = "FOGREMOVALSTRENGTH";
> = 0.950;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALSTRENGTH
#define FOGREMOVALSTRENGTH 0.950
#endif

uniform float DEPTHCURVE<
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Depth Curve";
	ui_bind = "FOGREMOVALDEPTHCURVE";
> = 0.0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALDEPTHCURVE
#define FOGREMOVALDEPTHCURVE 0.0
#endif

uniform float REMOVALCAP<
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Fog Removal Cap";
	ui_tooltip = "Prevents fog removal from trying to extract more details than can actually be removed, \n"
		"also helps preserve textures or lighting that may be detected as fog.";
	ui_bind = "FOGREMOVALCAP";
> = 0.35;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALCAP
#define FOGREMOVALCAP 0.35
#endif

uniform float2 MEDIANBOUNDS<
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Average Light Levels";
	ui_tooltip = "The number to the left should correspond to the average amount of light at night, \n"
		"the number to the right should correspond to the amount of light during the day.";
	ui_bind = "FOGREMOVALMEDIANBOUNDS";
> = float2(0.2, 0.8);

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALMEDIANBOUNDS
#define FOGREMOVALMEDIANBOUNDS float2(0.2, 0.8)
#endif

uniform float2 SENSITIVITYBOUNDS<
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Fog Sensitivity";
	ui_tooltip = "This number adjusts how sensitive the shader is to fog, a lower number means that \n"
			"it will detect more fog in the scene, but will also be more vulnerable to false positives.\n"
			"A higher number means that it will detect less fog in the scene but will also be more \n"
			"likely to fail at detecting fog. The number on the left corresponds to the value used at night, \n"
			"while the number on the right corresponds to the value used during the day.";
		ui_bind = "FOGREMOVALSENSITIVITYBOUNDS";
> = float2(0.2, 0.75);

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALSENSITIVITYBOUNDS
#define FOGREMOVALSENSITIVITYBOUNDS float2(0.2, 0.75)
#endif

uniform bool USEDEPTH<
	ui_label = "Ignore the sky";
	ui_tooltip = "Useful for shaders such as RTGI that rely on skycolor";
	ui_bind = "FOGREMOVALUSEDEPTH";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALUSEDEPTH
#define FOGREMOVALUSEDEPTH 0
#endif



texture ColorAttenuation {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
sampler sColorAttenuation {Texture = ColorAttenuation;};
texture DarkChannel {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
sampler sDarkChannel {Texture = DarkChannel;};
texture Transmission {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
sampler sTransmission {Texture = Transmission;};
texture LumaHistogram {Width = 256; Height = 1; Format = R32F;};
sampler sLumaHistogram {Texture = LumaHistogram;};
texture MedianLuma {Width = 1; Height = 1; Format = R8;};
sampler sMedianLuma {Texture = MedianLuma;};
texture FogRemoved {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;};
sampler sFogRemoved {Texture = FogRemoved;};
texture TruncatedPrecision {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F;};
sampler sTruncatedPrecision {Texture = TruncatedPrecision;};



void HistogramVS(uint id : SV_VERTEXID, out float4 pos : SV_POSITION)
{
	pos = float4(((dot(tex2Dfetch(ReShade::BackBuffer, int4(abs(uint((id % SAMPLEWIDTH * SAMPLEDISTANCE))), abs(uint((id / SAMPLEWIDTH) * SAMPLEDISTANCE)), 0, 0)).rgb, float3(0.3333, 0.3333, 0.3333)) * 255 + 0.5) / 256) * 2 - 1, 0, 0, 1);
}



void HistogramPS(float4 pos : SV_POSITION, out float col : SV_TARGET )
{
	col = 1.0;
}

void MedianLumaPS(float4 pos : SV_Position, out float output : SV_Target0)
{
	const int fifty = abs(0.5 * SAMPLECOUNT);
	int sum = 0;
	uint i = 0;
	while (sum < fifty)
	{
		sum += tex2Dfetch(sLumaHistogram, int4(i, 0, 0, 0)).r;
		i++;
		if (i >= 255) sum = fifty;
	}

	output = i;
	output = output / 255;
}

void FeaturesPS(float4 pos : SV_Position, float2 texcoord : TexCoord, out float colorAttenuation : SV_Target0, out float darkChannel : SV_Target1)
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	const float value = max(max(color.r, color.g), color.b);
	const float minimum = min(min(color.r, color.g), color.b);
	colorAttenuation = value - ((value - minimum) / (value));
	darkChannel = 1.0;
	const float depth = ReShade::GetLinearizedDepth(texcoord);
	float2 pixSize = tex2Dsize(ReShade::BackBuffer, 0.0);
	pixSize.x = 1.0 / pixSize.x;
	pixSize.y = 1.0 / pixSize.y;
	float depthContrast = 0.0;
	for(int i = -2; i <= 2; i++)
	{
		float depthSum = 0.0;
		for(int j = -2; j <= 2; j++)
		{
			color = tex2Doffset(ReShade::BackBuffer, texcoord, int2(i, j)).rgb;
			darkChannel = min(min(color.r, color.g), min(color.b, darkChannel));
			float depthSubtract = depth - ReShade::GetLinearizedDepth(float2(texcoord.x + pixSize.x * i, texcoord.y + pixSize.y * j));
			depthSum += depthSubtract * depthSubtract;
		}
		depthContrast = max(depthContrast, depthSum);
	}
	depthContrast = sqrt(0.2 * depthContrast);
	darkChannel = lerp(darkChannel, minimum, saturate(2.0 * depthContrast));
}

void TransmissionPS(float4 pos: SV_Position, float2 texcoord : TexCoord, out float transmission : SV_Target0)
{
	const float darkChannel = tex2D(sDarkChannel, texcoord).r;
	transmission = darkChannel / (1.0 - tex2D(sColorAttenuation, texcoord).r);
	const float v = (clamp(tex2Dfetch(sMedianLuma, int4(0, 0, 0, 0)).r, FOGREMOVALMEDIANBOUNDS.x, FOGREMOVALMEDIANBOUNDS.y) - FOGREMOVALMEDIANBOUNDS.x) * ((FOGREMOVALSENSITIVITYBOUNDS.x - FOGREMOVALSENSITIVITYBOUNDS.y) / (FOGREMOVALMEDIANBOUNDS.x - FOGREMOVALMEDIANBOUNDS.y)) + FOGREMOVALSENSITIVITYBOUNDS.x;
	transmission = saturate(transmission - v * (darkChannel + darkChannel));
	transmission = clamp(transmission * (1.0 - v), 0, FOGREMOVALCAP);
}

void FogRemovalPS(float4 pos: SV_Position, float2 texcoord : TexCoord, out float4 output : SV_Target0)
{
	const float transmission = tex2D(sTransmission, texcoord).r;
	const float depth = ReShade::GetLinearizedDepth(texcoord).r;
#if FOGREMOVALUSEDEPTH == 1
	if(depth >= 1.0) discard;
#endif
	const float strength = saturate((pow(depth, 100 * FOGREMOVALDEPTHCURVE)) * FOGREMOVALSTRENGTH);
	output = float4((tex2D(ReShade::BackBuffer, texcoord).rgb - strength * transmission) / max(((1 - strength * transmission)), 0.01), 1.0);
}

void BackBufferPS(float4 pos: SV_Position, float2 texcoord : TexCoord, out float3 output : SV_Target0)
{
#if FOGREMOVALUSEDEPTH == 1
	const float depth = ReShade::GetLinearizedDepth(texcoord).r;
	if(depth >= 1.0) discard;
#endif
	output = tex2D(sFogRemoved, texcoord).rgb;
}

void TruncatedPrecisionPS(float4 pos: SV_Position, float2 texcoord : TexCoord, out float4 output : SV_Target0)
{
#if FOGREMOVALUSEDEPTH == 1
	const float depth = ReShade::GetLinearizedDepth(texcoord).r;
	if(depth >= 1.0) discard;
#endif
	output = float4((tex2D(sFogRemoved, texcoord).rgb - tex2D(ReShade::BackBuffer, texcoord).rgb), 1);
}

void FogReintroductionPS(float4 pos : SV_Position, float2 texcoord : TexCoord, out float3 output : SV_Target0)
{
	const float depth = ReShade::GetLinearizedDepth(texcoord).r;
#if FOGREMOVALUSEDEPTH == 1
	if(depth >= 1.0) discard;
#endif
	float transmission = tex2D(sTransmission, texcoord).r;
	const float strength = saturate((pow(depth, 100 * FOGREMOVALDEPTHCURVE)) * FOGREMOVALSTRENGTH);
	output = tex2D(ReShade::BackBuffer, texcoord).rgb + tex2D(sTruncatedPrecision, texcoord).rgb * max(((1 - strength * transmission)), 0.01) + strength * transmission;
}



technique FogRemoval
{
	pass Histogram
	{
		PixelShader = HistogramPS;
		VertexShader = HistogramVS;
		PrimitiveTopology = POINTLIST;
		VertexCount = SAMPLECOUNT;
		RenderTarget0 = LumaHistogram;
		ClearRenderTargets = true; 
		BlendEnable = true; 
		SrcBlend = ONE; 
		DestBlend = ONE;
		BlendOp = ADD;
	}
	
	pass MedianLuma
	{
		VertexShader = PostProcessVS;
		PixelShader = MedianLumaPS;
		RenderTarget0 = MedianLuma;
		ClearRenderTargets = true;
	}
	
	pass Features
	{
		VertexShader = PostProcessVS;
		PixelShader = FeaturesPS;
		RenderTarget0 = ColorAttenuation;
		RenderTarget1 = DarkChannel;
	}
	
	pass Transmission
	{
		VertexShader = PostProcessVS;
		PixelShader = TransmissionPS;
		RenderTarget0 = Transmission;
	}
	
	pass FogRemoval
	{
		VertexShader = PostProcessVS;
		PixelShader = FogRemovalPS;
		RenderTarget0 = FogRemoved;
	}
	
	pass BackBuffer
	{
		VertexShader = PostProcessVS;
		PixelShader = BackBufferPS;
	}
	
	pass TruncatedPrecision
	{
		VertexShader = PostProcessVS;
		PixelShader = TruncatedPrecisionPS;
		RenderTarget0 = TruncatedPrecision;
	}
}

technique FogReintroduction <ui_tooltip = "Place this after the shaders you want to be rendered without fog";>
{
	pass Reintroduction
	{
		VertexShader = PostProcessVS;
		PixelShader = FogReintroductionPS;
	}
}
