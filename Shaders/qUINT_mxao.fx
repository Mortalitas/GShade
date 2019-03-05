/*=============================================================================

	ReShade 3 effect file
    github.com/martymcmodding

	Support me:
   		paypal.me/mcflypg
   		patreon.com/mcflypg

    Ambient Obscurance with Indirect Lighting "MXAO"
    by Marty McFly / P.Gilcher
    part of qUINT shader library for ReShade 3

    Modified by who knows and updated for ReShade 4 by Marot.

    CC BY-NC-ND 3.0 licensed.

=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

#ifndef qMXAO_MIPLEVEL_AO
 #define qMXAO_MIPLEVEL_AO		0	//[0 to 2]      Miplevel of AO texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth. Best results: IL MipLevel = AO MipLevel + 2
#endif

#ifndef qMXAO_MIPLEVEL_IL
 #define qMXAO_MIPLEVEL_IL		2	//[0 to 4]      Miplevel of IL texture. 0 = fullscreen, 1 = 1/2 screen width/height, 2 = 1/4 screen width/height and so forth.
#endif

#ifndef qMXAO_ENABLE_IL
 #define qMXAO_ENABLE_IL			0	//[0 or 1]	Enables Indirect Lighting calculation. Will cause a major fps hit.
#endif

#ifndef qMXAO_SMOOTHNORMALS
 #define qMXAO_SMOOTHNORMALS     1       //[0 or 1]      This feature makes low poly surfaces smoother, especially useful on older games.
#endif

#ifndef qMXAO_TWO_LAYER
 #define qMXAO_TWO_LAYER         1       //[0 or 1]      Splits MXAO into two separate layers that allow for both large and fine AO.
#endif

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform int qMXAO_GLOBAL_SAMPLE_QUALITY_PRESET <
	ui_type = "combo";
    ui_label = "Sample Quality";
	ui_items = "Very Low  (4 samples)\0Low       (8 samples)\0Medium    (16 samples)\0High      (24 samples)\0Very High (32 samples)\0Ultra     (64 samples)\0Maximum   (255 samples)\0Auto      (variable)\0";
	ui_tooltip = "Global quality control, main performance knob. Higher radii might require higher quality.";
    ui_category = "Global";
> = 2;

uniform float qMXAO_SAMPLE_RADIUS <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 20.0;
    ui_label = "Sample Radius";
	ui_tooltip = "Sample radius of MXAO, higher means more large-scale occlusion with less fine-scale details.";  
    ui_category = "Global";      
> = 2.5;

uniform float qMXAO_SAMPLE_NORMAL_BIAS <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 0.8;
    ui_label = "Normal Bias";
	ui_tooltip = "Occlusion Cone bias to reduce self-occlusion of surfaces that have a low angle to each other.";
    ui_category = "Global";
> = 0.2;

uniform float qMXAO_GLOBAL_RENDER_SCALE <
	ui_type = "slider";
    ui_label = "Render Size Scale";
	ui_min = 0.50; ui_max = 1.00;
    ui_tooltip = "Factor of MXAO resolution, lower values greatly reduce performance overhead but decrease quality.\n1.0 = MXAO is computed in original resolution\n0.5 = MXAO is computed in 1/2 width 1/2 height of original resolution\n...";
    ui_category = "Global";
> = 1.0;

uniform float qMXAO_SSAO_AMOUNT <
	ui_type = "slider";
	ui_min = 0.00; ui_max = 4.00;
    ui_label = "Ambient Occlusion Amount";        
	ui_tooltip = "Intensity of AO effect. Can cause pitch black clipping if set too high.";
    ui_category = "Ambient Occlusion";
> = 1.00;

#if(qMXAO_ENABLE_IL != 0)
uniform float qMXAO_SSIL_AMOUNT <
    ui_type = "slider";
    ui_min = 0.00; ui_max = 12.00;
    ui_label = "Indirect Lighting Amount";
    ui_tooltip = "Intensity of IL effect. Can cause overexposured white spots if set too high.";
    ui_category = "Indirect Lighting";
> = 4.00;

uniform float qMXAO_SSIL_SATURATION <
    ui_type = "slider";
    ui_min = 0.00; ui_max = 3.00;
    ui_label = "Indirect Lighting Saturation";
    ui_tooltip = "Controls color saturation of IL effect.";
    ui_category = "Indirect Lighting";
> = 1.00;
#endif

#if (qMXAO_TWO_LAYER != 0)
    uniform float qMXAO_SAMPLE_RADIUS_SECONDARY <
        ui_type = "slider";
        ui_min = 0.1; ui_max = 1.00;
        ui_label = "Fine AO Scale";
        ui_tooltip = "Multiplier of Sample Radius for fine geometry. A setting of 0.5 scans the geometry at half the radius of the main AO.";
        ui_category = "Double Layer";
    > = 0.2;

    uniform float qMXAO_AMOUNT_FINE <
        ui_type = "slider";
        ui_min = 0.00; ui_max = 1.00;
        ui_label = "Fine AO intensity multiplier";
        ui_tooltip = "Intensity of small scale AO / IL.";
        ui_category = "Double Layer";
    > = 1.0;

    uniform float qMXAO_AMOUNT_COARSE <
        ui_type = "slider";
        ui_min = 0.00; ui_max = 1.00;
        ui_label = "Coarse AO intensity multiplier";
        ui_tooltip = "Intensity of large scale AO / IL.";
        ui_category = "Double Layer";
    > = 1.0;
#endif

uniform int qMXAO_BLEND_TYPE <
	ui_type = "slider";
	ui_min = 0; ui_max = 3;
    ui_label = "Blending Mode";
	ui_tooltip = "Different blending modes for merging AO/IL with original color.\0Blending mode 0 matches formula of MXAO 2.0 and older.";
    ui_category = "Blending";
> = 0;

uniform float qMXAO_FADE_DEPTH_START <
	ui_type = "slider";
    ui_label = "Fade Out Start";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Distance where MXAO starts to fade out. 0.0 = camera, 1.0 = sky. Must be less than Fade Out End.";
    ui_category = "Blending";
> = 0.05;

uniform float qMXAO_FADE_DEPTH_END <
	ui_type = "slider";
    ui_label = "Fade Out End";
	ui_min = 0.00; ui_max = 1.00;
	ui_tooltip = "Distance where MXAO completely fades out. 0.0 = camera, 1.0 = sky. Must be greater than Fade Out Start.";
    ui_category = "Blending";
> = 0.4;

uniform int qMXAO_DEBUG_VIEW_ENABLE <
	ui_type = "combo";
    ui_label = "Enable Debug View";
	ui_items = "None\0AO/IL channel\0Normal vectors\0";
	ui_tooltip = "Different debug outputs";
    ui_category = "Debug";
> = 0;

/*=============================================================================
	Textures, Samplers, Globals
=============================================================================*/

#include "qUINT_common.fxh"

texture2D qMXAO_ColorTex 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = 3+qMXAO_MIPLEVEL_IL;};
texture2D qMXAO_DepthTex 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = R16F;  MipLevels = 3+qMXAO_MIPLEVEL_AO;};
texture2D qMXAO_NormalTex	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = 3+qMXAO_MIPLEVEL_IL;};

sampler2D sqMXAO_ColorTex	{ Texture = qMXAO_ColorTex;	};
sampler2D sqMXAO_DepthTex	{ Texture = qMXAO_DepthTex;	};
sampler2D sqMXAO_NormalTex	{ Texture = qMXAO_NormalTex;	};

#if(qMXAO_ENABLE_IL != 0)
 #define qBLUR_COMP_SWIZZLE xyzw
#else
 #define qBLUR_COMP_SWIZZLE w
#endif

/*=============================================================================
	Vertex Shader
=============================================================================*/

struct qMXAO_VSOUT
{
	float4                  vpos        : SV_Position;
    float4                  uv          : TEXCOORD0;
    nointerpolation float   samples     : TEXCOORD1;
    nointerpolation float3  uvtoviewADD : TEXCOORD4;
    nointerpolation float3  uvtoviewMUL : TEXCOORD5;
};

struct qBlurData
{
	float4 key;
	float4 mask;
};

qMXAO_VSOUT VS_qMXAO(in uint id : SV_VertexID)
{
    qMXAO_VSOUT qMXAO;

    qMXAO.uv.x = (id == 2) ? 2.0 : 0.0;
    qMXAO.uv.y = (id == 1) ? 2.0 : 0.0;
    qMXAO.uv.zw = qMXAO.uv.xy / qMXAO_GLOBAL_RENDER_SCALE;
    qMXAO.vpos = float4(qMXAO.uv.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);

    static const int samples_per_preset[8] = {4, 8, 16, 24, 32, 64, 255, 8 /*overridden*/};
    qMXAO.samples   = samples_per_preset[qMXAO_GLOBAL_SAMPLE_QUALITY_PRESET];
    
    qMXAO.uvtoviewADD = float3(-1.0,-1.0,1.0);
    qMXAO.uvtoviewMUL = float3(2.0,2.0,0.0);

#if 0
    static const float qFOV = 75.0; //vertical FoV

    qMXAO.uvtoviewADD = float3(-tan(radians(qFOV * 0.5)).xx,1.0) * qUINT::ASPECT_RATIO;
    qMXAO.uvtoviewMUL = float3(-2.0 * qMXAO.uvtoviewADD.xy,0.0);
#endif




    return qMXAO;
}

/*=============================================================================
	Functions
=============================================================================*/

float3 qget_position_from_uv(in float2 uv, in qMXAO_VSOUT qMXAO)
{
    return (uv.xyx * qMXAO.uvtoviewMUL + qMXAO.uvtoviewADD) * qUINT::linear_depth(uv) * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
}

float3 qget_position_from_uv_mipmapped(in float2 uv, in qMXAO_VSOUT qMXAO, in int miplevel)
{
    return (uv.xyx * qMXAO.uvtoviewMUL + qMXAO.uvtoviewADD) * tex2Dlod(sqMXAO_DepthTex, float4(uv.xyx, miplevel)).x;
}

void qspatial_blur_data(inout qBlurData o, in sampler inputsampler, in float inputscale, in float4 uv)
{
	o.key = tex2Dlod(inputsampler, uv * inputscale);
	o.mask = tex2Dlod(sqMXAO_NormalTex, uv);
	o.mask.xyz = o.mask.xyz * 2 - 1;
}

float qcompute_spatial_tap_weight(in qBlurData center, in qBlurData tap)
{
	float qdepth_term = saturate(1 - abs(tap.mask.w - center.mask.w));
	float qnormal_term = saturate(dot(tap.mask.xyz, center.mask.xyz) * 16 - 15);
	return qdepth_term * qnormal_term;
}

float4 qblur_filter(in qMXAO_VSOUT qMXAO, in sampler inputsampler, in float inputscale, in float radius, in int blursteps)
{
	float4 qblur_uv = float4(qMXAO.uv.xy, 0, 0);

    qBlurData center, tap;
	qspatial_blur_data(center, inputsampler, inputscale, qblur_uv);

	float4 qblursum 			= center.key;
	float4 qblursum_noweight = center.key;
	float qblurweight = 1;

    static const float2 qoffsets[8] = 
    {
    	float2(1.5,0.5),float2(-1.5,-0.5),float2(-0.5,1.5),float2(0.5,-1.5),
        float2(1.5,2.5),float2(-1.5,-2.5),float2(-2.5,1.5),float2(2.5,-1.5)
    };

    float2 qblur_offsetscale = qUINT::PIXEL_SIZE / inputscale * radius;

	[unroll]
	for(int i = 0; i < blursteps; i++) 
	{
		qblur_uv.xy = qMXAO.uv.xy + qoffsets[i] * qblur_offsetscale;
		qspatial_blur_data(tap, inputsampler, inputscale, qblur_uv);

		float qtap_weight = qcompute_spatial_tap_weight(center, tap);

		qblurweight += qtap_weight;
		qblursum.qBLUR_COMP_SWIZZLE += tap.key.qBLUR_COMP_SWIZZLE * qtap_weight;
		qblursum_noweight.qBLUR_COMP_SWIZZLE += tap.key.qBLUR_COMP_SWIZZLE;
	}

	qblursum.qBLUR_COMP_SWIZZLE /= qblurweight;
	qblursum_noweight.qBLUR_COMP_SWIZZLE /= 1 + blursteps;

	return lerp(qblursum.qBLUR_COMP_SWIZZLE, qblursum_noweight.qBLUR_COMP_SWIZZLE, qblurweight < 2);
}

void qsample_parameter_setup(in qMXAO_VSOUT qMXAO, in float scaled_depth, in float qlayer_id, out float qscaled_radius, out float qfalloff_factor)
{
    qscaled_radius  = 0.25 * qMXAO_SAMPLE_RADIUS / (qMXAO.samples * (scaled_depth + 2.0));
    qfalloff_factor = -1.0/(qMXAO_SAMPLE_RADIUS * qMXAO_SAMPLE_RADIUS);

    #if(qMXAO_TWO_LAYER != 0)
        qscaled_radius  *= lerp(1.0, qMXAO_SAMPLE_RADIUS_SECONDARY + 1e-6, qlayer_id);
        qfalloff_factor *= lerp(1.0, 1.0 / (qMXAO_SAMPLE_RADIUS_SECONDARY * qMXAO_SAMPLE_RADIUS_SECONDARY + 1e-6), qlayer_id);
    #endif
}

void qsmooth_normals(inout float3 qnormal, in float3 qposition, in qMXAO_VSOUT qMXAO)
{
    float2 qscaled_radius = 0.018 / qposition.z * qUINT::ASPECT_RATIO;
    float3 qneighbour_normal[4] = {qnormal, qnormal, qnormal, qnormal};

    [unroll]
    for(int i = 0; i < 4; i++)
    {
        float2 qdirection;
        sincos(6.28318548 * 0.25 * i, qdirection.y, qdirection.x);

        [unroll]
        for(int qdirection_step = 1; qdirection_step <= 5; qdirection_step++)
        {
            float qsearch_radius = exp2(qdirection_step);
            float2 qsample_uv = qMXAO.uv.zw + qdirection * qsearch_radius * qscaled_radius;

            float3 qtemp_normal = tex2Dlod(sqMXAO_NormalTex, float4(qsample_uv, 0, 0)).xyz * 2.0 - 1.0;
            float3 qtemp_position = qget_position_from_uv_mipmapped(qsample_uv, qMXAO, 0);

            float3 qposition_delta = qtemp_position - qposition;
            float qdistance_weight = saturate(1.0 - dot(qposition_delta, qposition_delta) * 20.0 / qsearch_radius);
            float qnormal_angle = dot(qnormal, qtemp_normal);
            float qangle_weight = smoothstep(0.3, 0.98, qnormal_angle) * smoothstep(1.0, 0.98, qnormal_angle); //only take normals into account that are NOT equal to the current normal.

            float qtotal_weight = saturate(3.0 * qdistance_weight * qangle_weight / qsearch_radius);

            qneighbour_normal[i] = lerp(qneighbour_normal[i], qtemp_normal, qtotal_weight);
        }
    }

    qnormal = normalize(qneighbour_normal[0] + qneighbour_normal[1] + qneighbour_normal[2] + qneighbour_normal[3]);
}

/*=============================================================================
	Pixel Shaders
=============================================================================*/

void PS_qInputBufferSetup(in qMXAO_VSOUT qMXAO, out float4 qcolor : SV_Target0, out float4 qdepth : SV_Target1, out float4 qnormal : SV_Target2)
{
    float3 qsingle_pixel_offset = float3(qUINT::PIXEL_SIZE.xy, 0);

	float3 qposition          =              qget_position_from_uv(qMXAO.uv.xy, qMXAO);
	float3 qposition_delta_x1 = - qposition + qget_position_from_uv(qMXAO.uv.xy + qsingle_pixel_offset.xz, qMXAO);
	float3 qposition_delta_x2 =   qposition - qget_position_from_uv(qMXAO.uv.xy - qsingle_pixel_offset.xz, qMXAO);
	float3 qposition_delta_y1 = - qposition + qget_position_from_uv(qMXAO.uv.xy + qsingle_pixel_offset.zy, qMXAO);
	float3 qposition_delta_y2 =   qposition - qget_position_from_uv(qMXAO.uv.xy - qsingle_pixel_offset.zy, qMXAO);

	qposition_delta_x1 = lerp(qposition_delta_x1, qposition_delta_x2, abs(qposition_delta_x1.z) > abs(qposition_delta_x2.z));
	qposition_delta_y1 = lerp(qposition_delta_y1, qposition_delta_y2, abs(qposition_delta_y1.z) > abs(qposition_delta_y2.z));

	float qdeltaz = abs(qposition_delta_x1.z * qposition_delta_x1.z - qposition_delta_x2.z * qposition_delta_x2.z)
				 + abs(qposition_delta_y1.z * qposition_delta_y1.z - qposition_delta_y2.z * qposition_delta_y2.z);

	qnormal  = float4(normalize(cross(qposition_delta_y1, qposition_delta_x1)) * 0.5 + 0.5, qdeltaz);
    qcolor 	= tex2D(qUINT::sBackBufferTex, qMXAO.uv.xy);
	qdepth 	= qUINT::linear_depth(qMXAO.uv.xy) * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;   
}

void PS_qStencilSetup(in qMXAO_VSOUT qMXAO, out float4 qcolor : SV_Target0)
{        
    if(    qUINT::linear_depth(qMXAO.uv.zw) >= qMXAO_FADE_DEPTH_END
        || 0.25 * 0.5 * qMXAO_SAMPLE_RADIUS / (tex2D(sqMXAO_DepthTex, qMXAO.uv.zw).x + 2.0) * BUFFER_HEIGHT < 1.0
        || qMXAO.uv.z > 1.0
        || qMXAO.uv.w > 1.0
        ) discard;

    qcolor = 1.0;
}

void PS_qAmbientObscurance(in qMXAO_VSOUT qMXAO, out float4 qcolor : SV_Target0)
{
    qcolor = 0.0;

	float3 qposition = qget_position_from_uv_mipmapped(qMXAO.uv.zw, qMXAO, 0);
    float3 qnormal = tex2D(sqMXAO_NormalTex, qMXAO.uv.zw).xyz * 2.0 - 1.0;

    float qsample_jitter = dot(floor(qMXAO.vpos.xy % 4 + 0.1), float2(0.0625, 0.25)) + 0.0625;

    float  qlayer_id = (qMXAO.vpos.x + qMXAO.vpos.y) % 2.0;

#if(qMXAO_SMOOTHNORMALS != 0)
    qsmooth_normals(qnormal, qposition, qMXAO);
#endif
    float linear_depth = qposition.z / RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;        
    qposition += qnormal * linear_depth;

    if(qMXAO_GLOBAL_SAMPLE_QUALITY_PRESET == 7) qMXAO.samples = 2 + floor(0.05 * qMXAO_SAMPLE_RADIUS / linear_depth);

    float qscaled_radius;
    float qfalloff_factor;
    qsample_parameter_setup(qMXAO, qposition.z, qlayer_id, qscaled_radius, qfalloff_factor);

    float2 qsample_uv, qsample_direction;
    sincos(2.3999632 * 16 * qsample_jitter, qsample_direction.x, qsample_direction.y); //2.3999632 * 16
    qsample_direction *= qscaled_radius;   

    [loop]
    for(int i = 0; i < qMXAO.samples; i++)
    {                    
        qsample_uv = qMXAO.uv.zw + qsample_direction.xy * qUINT::ASPECT_RATIO * (i + qsample_jitter);   
        qsample_direction.xy = mul(qsample_direction.xy, float2x2(0.76465, -0.64444, 0.64444, 0.76465)); //cos/sin 2.3999632 * 16            

        float qsample_mip = saturate(qscaled_radius * i * 20.0) * 3.0;
           
    	float3 qocclusion_vector = -qposition + qget_position_from_uv_mipmapped(qsample_uv, qMXAO, qsample_mip + qMXAO_MIPLEVEL_AO);                
        float  qocclusion_distance_squared = dot(qocclusion_vector, qocclusion_vector);
        float  qocclusion_normal_angle = dot(qocclusion_vector, qnormal) * rsqrt(qocclusion_distance_squared);

        float qsample_occlusion = saturate(1.0 + qfalloff_factor * qocclusion_distance_squared) * saturate(qocclusion_normal_angle - qMXAO_SAMPLE_NORMAL_BIAS);
#if(qMXAO_ENABLE_IL != 0)
        [branch]
        if(qsample_occlusion > 0.1)
        {
                float3 qsample_indirect_lighting = tex2Dlod(sqMXAO_ColorTex, float4(qsample_uv, 0, qsample_mip + qMXAO_MIPLEVEL_IL)).xyz;
                float3 sample_normal = tex2Dlod(sqMXAO_NormalTex, float4(qsample_uv, 0, qsample_mip + qMXAO_MIPLEVEL_IL)).xyz * 2.0 - 1.0;
                qsample_indirect_lighting *= saturate(dot(-sample_normal, qocclusion_vector) * rsqrt(qocclusion_distance_squared) * 4.0) * saturate(1.0 + qfalloff_factor * qocclusion_distance_squared * 0.25);
                qcolor += float4(qsample_indirect_lighting, qsample_occlusion);
        }
#else
        qcolor.w += qsample_occlusion;
#endif
    }

    qcolor = saturate(qcolor / ((1.0 - qMXAO_SAMPLE_NORMAL_BIAS) * qMXAO.samples) * 2.0);
    qcolor = sqrt(qcolor.qBLUR_COMP_SWIZZLE); //AO denoise

#if(qMXAO_TWO_LAYER != 0)
    qcolor *= lerp(qMXAO_AMOUNT_COARSE, qMXAO_AMOUNT_FINE, qlayer_id); 
#endif
}

void PS_qSpatialFilter1(in qMXAO_VSOUT qMXAO, out float4 qcolor : SV_Target0)
{
    qcolor = qblur_filter(qMXAO, qUINT::sCommonTex0, qMXAO_GLOBAL_RENDER_SCALE, 0.75, 8);
}

void PS_qSpatialFilter2(qMXAO_VSOUT qMXAO, out float4 qcolor : SV_Target0)
{
    float4 qssil_ssao = qblur_filter(qMXAO, qUINT::sCommonTex1, 1, 1.0 / qMXAO_GLOBAL_RENDER_SCALE, 4);

    qssil_ssao *= qssil_ssao; //AO denoise

	qcolor = tex2D(sqMXAO_ColorTex, qMXAO.uv.xy);

    static const float3 qlumcoeff = float3(0.2126, 0.7152, 0.0722);
    float qscenedepth = qUINT::linear_depth(qMXAO.uv.xy);        
    float qcolorgray = dot(qcolor.rgb, qlumcoeff);
    float qblendfact = 1.0 - qcolorgray;

#if(qMXAO_ENABLE_IL != 0)
	qssil_ssao.xyz  = lerp(dot(qssil_ssao.xyz, qlumcoeff), qssil_ssao.xyz, qMXAO_SSIL_SATURATION) * qMXAO_SSIL_AMOUNT * 2.0;
#else
    qssil_ssao.xyz = 0.0;
#endif
	qssil_ssao.w  = 1.0 - pow(abs(1.0 - qssil_ssao.w), qMXAO_SSAO_AMOUNT * 4.0);
    qssil_ssao    *= 1.0 - smoothstep(qMXAO_FADE_DEPTH_START, qMXAO_FADE_DEPTH_END, qscenedepth * float4(2.0, 2.0, 2.0, 1.0));

    if(qMXAO_BLEND_TYPE == 0)
    {
        qcolor.rgb -= (qssil_ssao.www - qssil_ssao.xyz) * qblendfact * qcolor.rgb;
    }
    else if(qMXAO_BLEND_TYPE == 1)
    {
        qcolor.rgb = qcolor.rgb * saturate(1.0 - qssil_ssao.www * qblendfact * 1.2) + qssil_ssao.xyz * qblendfact * qcolorgray * 2.0;
    }
    else if(qMXAO_BLEND_TYPE == 2)
    {
        float qcolordiff = saturate(2.0 * distance(normalize(qcolor.rgb + 1e-6),normalize(qssil_ssao.rgb + 1e-6)));
        qcolor.rgb = qcolor.rgb + qssil_ssao.rgb * lerp(qcolor.rgb, dot(qcolor.rgb, 0.3333), qcolordiff) * qblendfact * qblendfact * 4.0;
        qcolor.rgb = qcolor.rgb * (1.0 - qssil_ssao.www * (1.0 - dot(qcolor.rgb, qlumcoeff)));
    }
    else if(qMXAO_BLEND_TYPE == 3)
    {
        qcolor.rgb *= qcolor.rgb;
        qcolor.rgb -= (qssil_ssao.www - qssil_ssao.xyz) * qcolor.rgb;
        qcolor.rgb = sqrt(qcolor.rgb);
    }

    if(qMXAO_DEBUG_VIEW_ENABLE == 1)
    {
        qcolor.rgb = max(0.0, 1.0 - qssil_ssao.www + qssil_ssao.xyz);
        qcolor.rgb *= (qMXAO_ENABLE_IL != 0) ? 0.5 : 1.0;
    }
    else if(qMXAO_DEBUG_VIEW_ENABLE == 2)
    {      
        qcolor.rgb = tex2D(sqMXAO_NormalTex, qMXAO.uv.xy).xyz;
    }
       
    qcolor.a = 1.0;        
}

/*=============================================================================
	Techniques
=============================================================================*/

technique qMXAO

{
    pass
	{
		VertexShader = VS_qMXAO;
		PixelShader  = PS_qInputBufferSetup;
		RenderTarget0 = qMXAO_ColorTex;
		RenderTarget1 = qMXAO_DepthTex;
		RenderTarget2 = qMXAO_NormalTex;
	}
    pass
    {
        VertexShader = VS_qMXAO;
		PixelShader  = PS_qStencilSetup;
        /*Render Target is Backbuffer*/
        ClearRenderTargets = true;
		StencilEnable = true;
		StencilPass = REPLACE;
        StencilRef = 1;
    }
    pass
    {
        VertexShader = VS_qMXAO;
        PixelShader  = PS_qAmbientObscurance;
        RenderTarget = qUINT::CommonTex0;
        ClearRenderTargets = true;
        StencilEnable = true;
        StencilPass = KEEP;
        StencilFunc = EQUAL;
        StencilRef = 1;
    }
    pass
	{
		VertexShader = VS_qMXAO;
		PixelShader  = PS_qSpatialFilter1;
        RenderTarget = qUINT::CommonTex1;
	}
	pass
	{
		VertexShader = VS_qMXAO;
		PixelShader  = PS_qSpatialFilter2;
        /*Render Target is Backbuffer*/
	}
}