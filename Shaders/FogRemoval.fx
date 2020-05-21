/*
Reshade Fog Removal
By: Lord of Lunacy
License: CC0 1.0 Universal

This shader attempts to remove fog so that affects that experience light bleeding from it can be applied,
and then reintroduce the fog over the image.



This code was inspired by the following papers:

M. J. Abbaspour, M. Yazdi, and M. Masnadi-Shirazi, “A new fast method for foggy image enhancement,” 
2016 24th Iranian Conference on Electrical Engineering (ICEE), 2016.

W. Sun, “A new single-image fog removal algorithm based on physical model,” 
Optik, vol. 124, no. 21, pp. 4770–4775, 2013.



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


#include "Reshade.fxh"
#define euler	2.71828

uniform float STRENGTH <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Strength";
	ui_bind = "FOGREMOVALSTRENGTH";
> = 1.0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALSTRENGTH
#define FOGREMOVALSTRENGTH 1.0
#endif

uniform bool USEDEPTH <
	ui_label = "Ignore the sky";
	ui_tooltip = "Useful for shaders such as RTGI that rely on skycolor";
	ui_bind = "FOGREMOVALDEPTH";
> = 0;

// Set default value(see above) by source code if the preset has not modified yet this variable/definition
#ifndef FOGREMOVALDEPTH
#define FOGREMOVALDEPTH 0
#endif

texture Veil {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F;};
sampler sVeil {Texture = Veil;};

texture Erosion <pooled = true;> {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F;};
sampler sErosion {Texture = Erosion;};

texture OpenedVeil {Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16F;};
sampler sOpenedVeil {Texture = OpenedVeil;};



void VeilPass(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float output : SV_Target)
{
	const float3 a = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, -2)).rgb;
    const float3 b = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, -1)).rgb;
    const float3 c = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-2, 0)).rgb;
    const float3 d = tex2Doffset(ReShade::BackBuffer, texcoord, int2(-1, 0)).rgb;
    const float3 e = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, 0)).rgb;
    const float3 f = tex2Doffset(ReShade::BackBuffer, texcoord, int2(1, 0)).rgb;
    const float3 g = tex2Doffset(ReShade::BackBuffer, texcoord, int2(2, 0)).rgb;
    const float3 h = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, 1)).rgb;
    const float3 i = tex2Doffset(ReShade::BackBuffer, texcoord, int2(0, 2)).rgb;
	
	//Find the smallest single rgb value out of all the pixels
	float minimum = min(a.r, b.r);
	minimum = min(minimum, c.r);
	minimum = min(minimum, d.r);
	minimum = min(minimum, e.r);
	minimum = min(minimum, f.r);
	minimum = min(minimum, g.r);
	minimum = min(minimum, h.r);
	minimum = min(minimum, i.r);
	minimum = min(minimum, a.g);
	minimum = min(minimum, c.g);
	minimum = min(minimum, d.g);
	minimum = min(minimum, e.g);
	minimum = min(minimum, f.g);
	minimum = min(minimum, g.g);
	minimum = min(minimum, h.g);
	minimum = min(minimum, i.g);
	minimum = min(minimum, a.b);
	minimum = min(minimum, c.b);
	minimum = min(minimum, d.b);
	minimum = min(minimum, e.b);
	minimum = min(minimum, f.b);
	minimum = min(minimum, g.b);
	minimum = min(minimum, h.b);
	minimum = min(minimum, i.b);
	
	output = minimum;
}

void ErosionPass(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float output : SV_Target)
{
	const float a = tex2Doffset(sVeil, texcoord, int2(0, -2)).r;
    const float b = tex2Doffset(sVeil, texcoord, int2(0, -1)).r;
    const float c = tex2Doffset(sVeil, texcoord, int2(-2, 0)).r;
    const float d = tex2Doffset(sVeil, texcoord, int2(-1, 0)).r;
    const float e = tex2Doffset(sVeil, texcoord, int2(0, 0)).r;
    const float f = tex2Doffset(sVeil, texcoord, int2(1, 0)).r;
    const float g = tex2Doffset(sVeil, texcoord, int2(2, 0)).r;
    const float h = tex2Doffset(sVeil, texcoord, int2(0, 1)).r;
    const float i = tex2Doffset(sVeil, texcoord, int2(0, 2)).r;
	
	//Find the smallest single value out of all the pixels
	float minimum = min(a, b);
	minimum = min(minimum, c);
	minimum = min(minimum, d);
	minimum = min(minimum, e);
	minimum = min(minimum, f);
	minimum = min(minimum, g);
	minimum = min(minimum, h);
	minimum = min(minimum, i);
	
	output = minimum;
}

void DilationPass(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float output : SV_Target)
{
    const float a = tex2Doffset(sErosion, texcoord, int2(0, -2)).r;
    const float b = tex2Doffset(sErosion, texcoord, int2(0, -1)).r;
    const float c = tex2Doffset(sErosion, texcoord, int2(-2, 0)).r;
    const float d = tex2Doffset(sErosion, texcoord, int2(-1, 0)).r;
    const float e = tex2Doffset(sErosion, texcoord, int2(0, 0)).r;
    const float f = tex2Doffset(sErosion, texcoord, int2(1, 0)).r;
    const float g = tex2Doffset(sErosion, texcoord, int2(2, 0)).r;
    const float h = tex2Doffset(sErosion, texcoord, int2(0, 1)).r;
    const float i = tex2Doffset(sErosion, texcoord, int2(0, 2)).r;
	
	//Find the largest single value out of all the pixels
	float maximum = max(a, b);
	maximum = max(maximum, c);
	maximum = max(maximum, d);
	maximum = max(maximum, e);
	maximum = max(maximum, f);
	maximum = max(maximum, g);
	maximum = max(maximum, h);
	maximum = max(maximum, i);
	
	output = maximum;
}

void ReflectivityPass(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float3 output : SV_Target)
{
	const float depth = tex2D(ReShade::DepthBuffer, texcoord).x;

#if FOGREMOVALDEPTH == 1
	if(depth >= 1) discard;
#endif
	float a = tex2D(sOpenedVeil, texcoord).r;
	if(depth >= 1)
		a = a - 0.1171875;
	const float v = tex2D(sVeil, texcoord).r;
	a = max(a, 0.0001);
	output = max(((1 - FOGREMOVALSTRENGTH * v.rrr) * rcp(a.rrr)), 0.001);
	output = (tex2D(ReShade::BackBuffer, texcoord).rgb - FOGREMOVALSTRENGTH * v.rrr) * rcp(output);
	output = saturate(output * rcp(a.rrr));
}


void ReintroductionPass(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float3 output : SV_Target)
{
#if FOGREMOVALDEPTH == 1
	const float depth = tex2D(ReShade::DepthBuffer, texcoord).x;

	if(depth >= 1) discard;
#endif
	const float3 fogLevel = tex2D(sVeil, texcoord).rrr;
	output = tex2D(ReShade::BackBuffer, texcoord).rgb * (1 - FOGREMOVALSTRENGTH * fogLevel) + FOGREMOVALSTRENGTH * fogLevel;
}

technique FogRemoval <ui_tooltip = "Place this before shaders that you want to be rendered without fog";>
{
	pass VeilDetection
	{
		VertexShader = PostProcessVS;
		PixelShader = VeilPass;
		RenderTarget0 = Veil;
	}
	
	pass ErodeVeil
	{
		VertexShader = PostProcessVS;
		PixelShader = ErosionPass;
		RenderTarget0 = Erosion;
	}
	
	pass OpenVeil
	{
		VertexShader = PostProcessVS;
		PixelShader = DilationPass;
		RenderTarget0 = OpenedVeil;
	}
	
	pass ReflectivityAndRemoval
	{
		VertexShader = PostProcessVS;
		PixelShader = ReflectivityPass;
	}
}

technique FogReintroduction <ui_tooltip = "Place this after the shaders you want to be rendered without fog";>
{
	pass FogReintroduction
	{
		VertexShader = PostProcessVS;
		PixelShader = ReintroductionPass;
	}
}
