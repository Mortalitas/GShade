// -------------------------------------------------------------------------- //

// FGFX::Energy-Conservative Film Grain
// Author  : Alex Tuduran | alex.tuduran@gmail.com | github.com/AlexTuduran
// Version : 0.1 [ReShade 3.0]

// -------------------------------------------------------------------------- //

#include "ReShadeUI.fxh"

// -------------------------------------------------------------------------- //

uniform int ___ABOUT <
    ui_type = "radio";
    ui_label = " ";
    ui_category = "About";
    ui_category_closed = true;
    ui_text =
        "+------------------------------------------------------------------------+\n"
        "|-=[ FGFX::Energy-Conservative Film Grain ]=-|\n"
        "+------------------------------------------------------------------------+\n"
        "\n"

		"The Energy-Conservative Film Grain is a post-processing effect that aims "
        "at injecting random noise in the frame to achieve a film grain / digital "
		"sensor noise effect.\n"
        "\n"

		"However, it tries to achieve that while not introducing undesired "
		"luminance offsets in the image by staying neutral to 0 (the noise "
		"averages to 0 if integrated both in time and / or space).\n"
        "\n"

		"This property makes it energy-conservative and it mimics how real "
		"devices integrate noise in their output signal.\n"
        "\n"

        "* Where is this effect best placed? *\n"
        "\n"

        "Since the effect addresses film / sensor defects, it's best to place "
		"it after all effects (especially after any form of sharpening).\n";
>;

uniform float Intensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Intensity";
	ui_tooltip = "Film grain global intensity.";
> = 0.15;

uniform float HighlightIntensity < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0;
	ui_max = 1.0;
	ui_label = "Highlight Intensity";
	ui_tooltip = "Intensity of the grain in highlights.";
> = 0.25;

uniform float LuminanceExponent < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.1;
	ui_max = 4.0;
	ui_label = "Luminance Exponent";
	ui_tooltip = "Exponent to which the luminance is raised before used as modulator.";
> = 1.5;

// -------------------------------------------------------------------------- //

uniform float FrameTime <source = "frametime";>;

// -------------------------------------------------------------------------- //

#include "ReShade.fxh"

// -------------------------------------------------------------------------- //

sampler2D ReShadeBackBufferSRGBSampler {
    Texture = ReShade::BackBufferTex;
};

// -------------------------------------------------------------------------- //

float3 Hash33(in float3 p3) {
    p3 = frac(p3 * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return frac((p3.xxy + p3.yxx) * p3.zyx);
}

float3 Hash32UV(in float2 uv, in float step) {
    return Hash33(float3(uv * 14353.45646, (FrameTime % 100.0) * step));
}

// -------------------------------------------------------------------------- //

float3 MainPass(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target {
	// sample the color buffer
	float2 screenUV = texcoord.xy;
	float3 color = tex2D(ReShadeBackBufferSRGBSampler, screenUV).rgb;

	// generate RGB noise
	float3 grain = Hash32UV(texcoord, 0.6457);

	// apply gamma
	grain = pow(grain, 2.2);

	// offset to achieve energy-conservative, zero-average noise
	grain -= 0.5;

	// compute luminance
	float luminance = dot(color, 0.333333333333); // I believe in channel equality
	luminance = pow(luminance, LuminanceExponent); // bend it
	float luminanceModulator = lerp(1.0, HighlightIntensity, luminance); // modulator is 1 when either luminance is at 0 or HighlightIntensity is at 1

	// luminance-modulate grain
	grain *= luminanceModulator;

	// global-modulate grain
	grain *= Intensity;

	// integrate grain
	color += grain;

	// that's it
	return color.rgb;
}

technique FilmGrain <
    ui_label = "FGFX::Energy-Conservative Film Grain";
    ui_tooltip =
        "+------------------------------------------------------------------------+\n"
        "|-=[ FGFX::Energy-Conservative Film Grain ]=-|\n"
        "+------------------------------------------------------------------------+\n"
        "\n"

        "The Energy-Conservative Film Grain is a post-processing effect that aims\n"
        "at injecting random noise in the frame to achieve a film grain effect.\n"
        "\n"

        "The Energy-Conservative Film Grain is written by\n"
        "Alex Tuduran.\n";
> {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = MainPass;
	}
}
