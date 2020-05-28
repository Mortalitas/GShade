/*
Reshade Fog Removal
By: Lord of Lunacy
License: CC0 1.0 Universal

This shader attempts to remove fog so that affects that experience light bleeding from it can be applied,
and then reintroduce the fog over the image.



This code was inspired by the following paper:

B. Cai, X. Xu, K. Jia, C. Qing, and D. Tao, “DehazeNet: An End-to-End System for Single Image Haze Removal,”
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



#include "ReShade.fxh"



uniform float STRENGTH<
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Strength";
	ui_bind = "FOGREMOVALSTRENGTH";
> = 1.0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALSTRENGTH
#define FOGREMOVALSTRENGTH 1.0
#endif

uniform float X<
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Depth Curve";
	ui_bind = "FOGREMOVALDEPTHCURVE";
> = 0.0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALDEPTHCURVE
#define FOGREMOVALDEPTHCURVE 0.0
#endif

uniform float K<
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "K-Level";
	ui_tooltip = "Make sure this feature is not set too high or too low" ;
	ui_bind = "FOGREMOVALKLEVEL";
> = 0.3;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALKLEVEL
#define FOGREMOVALKLEVEL 0.3
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
texture HueDisparity {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
sampler sHueDisparity {Texture = HueDisparity;};
texture DarkChannel {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
sampler sDarkChannel {Texture = DarkChannel;};
texture MaxContrast {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
sampler sMaxContrast {Texture = MaxContrast;};
texture GaussianH {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
sampler sGaussianH {Texture = GaussianH;};
texture Transmission {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R8;};
sampler sTransmission {Texture = Transmission;};



float Hue(float3 color)
{
	return atan((0.8660254 * (color.g - color.b)) / (color.r - 0.5 * (color.g + color.b)));
}

float colorToLuma(float3 color)
{
	return dot(color, (0.333, 0.333, 0.333)) * 3;
}



void FeaturesPS(float4 pos : SV_Position, float2 texcoord : TexCoord, out float colorAttenuation : SV_Target0, out float hueDisparity : SV_Target1, out float darkChannel : SV_Target2, out float maxContrast : SV_Target3)
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	const float value = max(max(color.r, color.g), color.b);
	colorAttenuation = value - ((value - min(min(color.r, color.g), color.b)) / rcp(value));
	hueDisparity = Hue(float3(max(color.r, 1 - color.r), max(color.g, 1 - color.g), max(color.b, 1 - color.b))) - Hue(color);
	darkChannel = 1;
	const float luma = colorToLuma(color);
	float luma1;
	float sum;
	maxContrast = 0;
	for(int i = -2; i <= 2; i++)
	{
		sum = 0;
		for(int j = -2; j <= 2; j++)
		{
			color = tex2Doffset(ReShade::BackBuffer, texcoord, int2(i, j)).rgb;
			darkChannel = min(min(color.r, color.g), min(color.b, darkChannel));
			luma1 = colorToLuma(color);
			sum += ((luma - luma1) * (luma - luma1));
		}
		maxContrast = max(maxContrast, sum);
	}
	maxContrast = sqrt(0.2 * maxContrast);
	
}

void GaussianHPS(float4 pos: SV_Position, float2 texcoord : TexCoord, out float gaussianH : SV_Target0)
{
	gaussianH = 0;
	static const float kernel[5] = {0.187691, 0.206038, 0.212543, 0.206038, 0.187691};
	for (int i = -2; i <= 2; i++)
	{
		gaussianH += tex2Doffset(sMaxContrast, texcoord, int2(i, 0)).r * kernel[i + 2];
	}
}

void GaussianVPS(float4 pos: SV_Position, float2 texcoord : TexCoord, out float gaussianV : SV_Target0)
{
	gaussianV = 0;
	static const float kernel[5] = {0.187691, 0.206038, 0.212543, 0.206038, 0.187691};
	for (int i = -2; i <= 2; i++)
	{
		gaussianV += tex2Doffset(sGaussianH, texcoord, int2(0, i)).r * kernel[i + 2];
	}
}

void TransmissionPS(float4 pos: SV_Position, float2 texcoord : TexCoord, out float transmission : SV_Target0)
{
	const float darkChannel = tex2D(sDarkChannel, texcoord).r;
	const float colorAttenuation = tex2D(sColorAttenuation, texcoord).r;
	transmission = (darkChannel * (1-colorAttenuation) * rcp(colorAttenuation)) + 2 * tex2D(sMaxContrast, texcoord).r;
	transmission = saturate(darkChannel - K * saturate(transmission));

}
void FogRemovalPS(float4 pos: SV_Position, float2 texcoord : TexCoord, out float3 output : SV_Target0)
{
	const float transmission = tex2D(sTransmission, texcoord).r;
	const float depth = tex2D(ReShade::DepthBuffer, texcoord).r;
#if FOGREMOVALUSEDEPTH
	if(depth >= 1) discard;
#endif
	const float strength = saturate((pow(depth, 100*X)) * STRENGTH);
	output = saturate((tex2D(ReShade::BackBuffer, texcoord).rgb - strength * transmission) * rcp(max(((1 - strength * transmission)), 0.001)));
}

void FogReintroductionPS(float4 pos : SV_Position, float2 texcoord : TexCoord, out float3 output : SV_Target0)
{
	const float depth = tex2D(ReShade::DepthBuffer, texcoord).r;
#if FOGREMOVALUSEDEPTH
	if(depth >= 1) discard;
#endif
	const float transmission = tex2D(sTransmission, texcoord).r;
	const float strength = saturate((pow(depth, 100 * X)) * STRENGTH);
	output = tex2D(ReShade::BackBuffer, texcoord).rgb * max(((1 - strength * transmission)), 0.001) + strength * transmission;
}



technique FogRemoval <ui_tooltip = "Place this before shaders that you want to be rendered without fog";>
{
	pass Features
	{
		VertexShader = PostProcessVS;
		PixelShader = FeaturesPS;
		RenderTarget0 = ColorAttenuation;
		RenderTarget1 = HueDisparity;
		RenderTarget2 = DarkChannel;
		RenderTarget3 = MaxContrast;
	}
	
	pass GaussianH
	{
		VertexShader = PostProcessVS;
		PixelShader = GaussianHPS;
		RenderTarget0 = GaussianH;
	}
	
	pass GaussianV
	{
		VertexShader = PostProcessVS;
		PixelShader = GaussianVPS;
		RenderTarget0 = MaxContrast;
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
