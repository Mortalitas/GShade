// -------------------------------------------------------------------------- //

// FGFX::FCSB[16X] - Fast Cascaded Separable Blur [16X]
// Author  : Alex Tuduran | alex.tuduran@gmail.com | github.com/AlexTuduran
// Version : 0.7 [ReShade 3.0]
// License : MIT

// -------------------------------------------------------------------------- //
// preprocessor definitions
// -------------------------------------------------------------------------- //

// 0 = anti-aliased down-sampling off
// 1 = anti-aliased down-sampling on
// def = 1
#ifndef FCSB16X_ANTI_ALIASED_DOWN_SAMPLING_ON
    #define FCSB16X_ANTI_ALIASED_DOWN_SAMPLING_ON 1
#endif

// 0 = blur off
// 1 = blur on
// def = 1
#ifndef FCSB16X_BLUR_ON
    #define FCSB16X_BLUR_ON 1
#endif

// 0 = cascade 1 off
// 1 = cascade 1 on
// def = 1
#ifndef FCSB16X_CASCADE_1_ON
    #define FCSB16X_CASCADE_1_ON 1
#endif

// 0 = cascade 2 off
// 1 = cascade 2 on
// def = 1
#ifndef FCSB16X_CASCADE_2_ON
    #define FCSB16X_CASCADE_2_ON 1
#endif

// 0 = cascade 3 off
// 1 = cascade 3 on
// def = 0
#ifndef FCSB16X_CASCADE_3_ON
    #define FCSB16X_CASCADE_3_ON 0
#endif

// -------------------------------------------------------------------------- //

// -------------------------------------------------------------------------- //
// "About" category
// -------------------------------------------------------------------------- //

uniform int ___ABOUT <
    ui_type = "radio";
    ui_label = " ";
    ui_category = "About";
    ui_category_closed = true;
    ui_text =
        "-=[ FGFX::FCSB[16X] - Fast Cascaded Separable Blur [16X] ]=-\n"
        "\n"

        "FCSB is a blur technique that combines cascaded H / V blur "
        "passes and alias-free down-sampling in order to produce "
        "large, smooth and alias-free blur at a fraction of the cost of "
        "traditional separable Gaussian blur.\n"
        "\n"

        "For reference, the technique performs ~35 times faster than "
        "traditional separable Gaussian blur on a 121 texels radius and "
        "an astonishing ~122 times faster on a 484 texels radius.\n"
        "\n"

        "The complexity of standard separable Gaussian blur is "
        "O(n), while the complexity of FCSB is O(log(n)), making it "
        "ideal for cases where large smooth blur is required.\n"
        "\n"

        "In other words, as the radius increases exponentially, the "
        "cost of FCSB increases linearly.\n"
        "\n"

        "The FCSB16X effect is provided not as an actual usable in-game "
        "effect, but rather as a technique demonstration that can be "
        "used as a performance booster alternative to the classic "
        "separable Gaussian blur in other effects that make use of "
        "blur to achieve their goals.\n"
        "\n"

        "The 16X refers to the fact that prior to cascading, the "
        "back-buffer is down-sampled 16 times its original size, "
        "yielding a performance boost of 16X compared to cascading on "
        "the full-sized back-buffer.\n"
        "\n"

        "Even used on the full back-buffer, FCSB is much faster than "
        "standard separable Gaussian blur due to the exhibited "
        "O(log(n)) complexity.";
>;

// -------------------------------------------------------------------------- //
// "Parameters" category
// -------------------------------------------------------------------------- //

uniform float BlurRadius <
	ui_type = "slider";
    ui_min = 0.00;
    ui_max = 1.00;
    ui_category = "Parameters";
    ui_label = "Blue Radius";
    ui_tooltip = "Blur radius in unit space.";
> = 0.25;

// -------------------------------------------------------------------------- //

#include "ReShade.fxh"

// -------------------------------------------------------------------------- //

// this value is tightly related to the architecture of this implementation (16X)
// of FCSB, therefore should not be changed
#define ___BUFFER_SIZE_MAX_BIT_SHIFT___ (4)

// -------------------------------------------------------------------------- //
// down-samplers and their textures
// -------------------------------------------------------------------------- //

texture HalfBlurTex {
    Width = BUFFER_WIDTH >> 1;
    Height = BUFFER_HEIGHT >> 1;
    Format = RGBA16F;
};

sampler HalfBlurSampler {
    Texture = HalfBlurTex;
};

texture QuadBlurTex {
    Width = BUFFER_WIDTH >> 2;
    Height = BUFFER_HEIGHT >> 2;
    Format = RGBA16F;
};

sampler QuadBlurSampler {
    Texture = QuadBlurTex;
};

texture OctoBlurTex {
    Width = BUFFER_WIDTH >> 3;
    Height = BUFFER_HEIGHT >> 3;
    Format = RGBA16F;
};

sampler OctoBlurSampler {
    Texture = OctoBlurTex;
};

texture HexaBlurTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = RGBA16F;
};

sampler HexaBlurSampler {
    Texture = HexaBlurTex;
};

// -------------------------------------------------------------------------- //
// cascades ping-pong textures & samplers
// -------------------------------------------------------------------------- //

texture HBlurTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = RGBA16F;
};

sampler HBlurSampler {
    Texture = HBlurTex;
};

texture VBlurTex {
    Width = BUFFER_WIDTH >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Height = BUFFER_HEIGHT >> ___BUFFER_SIZE_MAX_BIT_SHIFT___;
    Format = RGBA16F;
};

sampler VBlurSampler {
    Texture = VBlurTex;
};

// -------------------------------------------------------------------------- //

#define ___BLUR_SAMPLE_OFFSET_CASCADE_0___ (  1.0) // 3 ^ 0
#define ___BLUR_SAMPLE_OFFSET_CASCADE_1___ (  3.0) // 3 ^ 1
#define ___BLUR_SAMPLE_OFFSET_CASCADE_2___ (  9.0) // 3 ^ 2
#define ___BLUR_SAMPLE_OFFSET_CASCADE_3___ ( 27.0) // 3 ^ 3
#define ___BLUR_SAMPLE_OFFSET_CASCADE_4___ ( 81.0) // 3 ^ 4
#define ___BLUR_SAMPLE_OFFSET_CASCADE_5___ (243.0) // 3 ^ 5

// -------------------------------------------------------------------------- //

#define ___ONE_THIRD___ (0.333333333)

// -------------------------------------------------------------------------- //

static const int ___BUFFER_SIZE_DIVIDER___ = 1 << ___BUFFER_SIZE_MAX_BIT_SHIFT___;

// we use a step of 1.5 for sampling 2 pixels at the same time with just one
// tex2D call and directly get their average:
// lerp(a, b, 0.5) =
//   = a + (b - a) * 0.5
//   = a + b * 0.5 - a * 0.5
//   = a + b / 2 - a / 2
//   = (2 * a + b - a) / 2
//   = (a + a + b - a) / 2
//   = (a + b + a - a) / 2
//   = (a + b) / 2
//
// therefore, when we sample a texture with an offset of half texel (linear
// sampler required), we in fact fetch directly the average of left and right
// texel
//
// better yet, if we sample the texture at half texel on x and y as well, we in fact fetch directly the average of the neighbour 4 texels TL, TR, BL, BR:
// tex2D(sampler, (intUV + 0.5) * BUFFER_PIXEL_SIZE) =
//   = lerp(lerp(TL, TR, 0.5), lerp(BL, BR, 0.5), 0.5)
//   = (lerp(TL, TR, 0.5) + lerp(BL, BR, 0.5)) / 2
//   = ((TL + TR) / 2 + (BL + BR) / 2) / 2
//   = ((TL + TR + BL + BR) / 2) / 2
//   = (TL + TR + BL + BR) / 4
// where:
//   TL = tex2D(sampler, BUFFER_PIXEL_SIZE * (intUV + float2(0, 0)))
//   TR = tex2D(sampler, BUFFER_PIXEL_SIZE * (intUV + float2(0, 1)))
//   BL = tex2D(sampler, BUFFER_PIXEL_SIZE * (invUV + float2(1, 0)))
//   BR = tex2D(sampler, BUFFER_PIXEL_SIZE * (intUV + float2(1, 1)))
//
// so we get a 2x2 convolution basically for free
static const float ___STEP_MULTIPLIER___ = 1.5;
static const float ___BUFFER_SIZE_DIVIDER_COMPENSATION_OFFSET___ = ___BUFFER_SIZE_DIVIDER___ * ___STEP_MULTIPLIER___;
static const float2 ___SCALED_BUFFER_SIZE_DIVIDER_DIVIDER_COMPENSATION_OFFSET___ = ___BUFFER_SIZE_DIVIDER_COMPENSATION_OFFSET___ * BUFFER_PIXEL_SIZE;

// -------------------------------------------------------------------------- //
// * down-sampling routines *
//
// we don't down-sample to the smallest texture directly in order to avoid aliasing
// by down-sampling in steps, we get an energy-conservative down-sampling that
// accounts for all pixels in the back-buffer, hence free of any aliasing
// -------------------------------------------------------------------------- //

float3 CopyBBPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(ReShade::BackBuffer, texcoord.xy).rgb;
}

float3 CopyHalfPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(HalfBlurSampler, texcoord.xy).rgb;
}

float3 CopyQuadPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(QuadBlurSampler, texcoord.xy).rgb;
}

float3 CopyOctoPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(OctoBlurSampler, texcoord.xy).rgb;
}

float3 CopyHexaPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // if writing to a half-sized texture, this returns the average of 4 neighbour texels
    return tex2D(HexaBlurSampler, texcoord.xy).rgb;
}

// -------------------------------------------------------------------------- //
// * separable cascades routines *
//
// we call these many times in a "cascade" fashion with exponentially increasing
// blurSampleOffset in order to achieve a large radius blur
//
// since we're sampling 3 texels at a time, the next cascade should use a
// blurSampleOffset that is 3 times wider
//
// because now the 3 times wider apart samples contain the average of the
// previous 3 close samples in previous cascade, their average effectivelly
// equals to the average of 9 close samples
//
// to harness the power behind this principle, we use multiple cascades:
// cascade 0 will yield a 1 * 3 = 3 (3 ^ 1) texel wide blur
// cascade 1 will yield a 3 * 3 = 9 (3 ^ 2) texels wide blur
// cascade 2 will yield a 9 * 3 = 27 (3 ^ 3) texels wide blur
// cascade 3 will yield a 27 * 3 = 81 (3 ^ 4) texels wide blur
// cascade 4 will yield a 81 * 3 = 243 (3 ^ 5) texels wide blur
// cascade 5 will yield a 243 * 3 = 729 (3 ^ 6) texels wide blur
//
// if we also factor in the 1.5 step multiplier, the radius of the achieved blur
// is actually even wider
//
// futher more, to achieve smooth blur instead of box blur, we apply some
// cascades 2 or more times - this not only turns the rectangular convolution
// into smooth convolution, but also widens the effective radius of
// the convolution
//
// * why applying a rectangular convolution multiple times yields smoothness?
//
// mathematically speaking, convolution shares a lot in common with sumation
// or multiplication: it is *commutative* and *associative*
//
// if we denote * as the convolution operation, the following statements are
// both true:
// a * b = b * a
// a * (b * c) = (a * b) * c
//
// what that means is that if we're convolving N signals, the convolution
// order doesn't matter at all
// a * b * c * d * e * f = f * c * b * e * d * a
//
// more than that, convolving any subsets from the N signals and then taking the
// resulted convolutions of those subsets and convolve them afterwards is the
// same of convolving all the N signals one after another in any order
// (a * b * c) * (d * e * f) = a * b * c * d * e * f
//
// for us, it means that if we have a signal s and a rectangular kernel r, the
// following is true:
// s * r * r * r = (r * r * r) * s
//
// in other words, convolving the signal with consecutive rectangulars is the
// same as convolving the rectangulars first and convolving the resulting kernel
// with our signal
//
// but what happens when you convolve a rectangular with itself?
// -> a trapezoid kernel emerges
//
// and what if we convolve the trapezoid kernel with another rectangular?
// -> an *almost* gaussian kernel emerges
//
// and if we keep on convolving with a rectangular?
// -> the resulting kernel starts to approximate a gaussian kernel with each
// rectangular convolution
//
// it will never reach a perfect gaussian shape, but for our application is
// good enough
//
// in practice, convolving with 3 rectangulars produces a very smooth result
// and that's all we need to approximate the convolution with a gaussian kernel
// -------------------------------------------------------------------------- //

float3 HBlur(in float2 texcoord : TEXCOORD, float blurSampleOffset, sampler srcSampler) {
    float offset = ___SCALED_BUFFER_SIZE_DIVIDER_DIVIDER_COMPENSATION_OFFSET___.x * blurSampleOffset * BlurRadius;

    float3 color = tex2D(srcSampler, texcoord).rgb; // center
    color += tex2D(srcSampler, float2(texcoord.x - offset, texcoord.y)).rgb; // left-center
    color += tex2D(srcSampler, float2(texcoord.x + offset, texcoord.y)).rgb; // right-center
    color *= ___ONE_THIRD___;

    return color;
}

float3 VBlur(in float2 texcoord : TEXCOORD, float blurSampleOffset, sampler srcSampler) {
    float offset = ___SCALED_BUFFER_SIZE_DIVIDER_DIVIDER_COMPENSATION_OFFSET___.y * blurSampleOffset * BlurRadius;

    float3 color = tex2D(srcSampler, texcoord).rgb; // center
    color += tex2D(srcSampler, float2(texcoord.x, texcoord.y - offset)).rgb; // center-bottom
    color += tex2D(srcSampler, float2(texcoord.x, texcoord.y + offset)).rgb; // center-top
    color *= ___ONE_THIRD___;

    return color;
}

// -------------------------------------------------------------------------- //
// cascade 0
// -------------------------------------------------------------------------- //

float3 HBlurC0BBPS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from backbuffer, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_0___, ReShade::BackBuffer);
}

float3 HBlurC0PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_0___, VBlurSampler);
}

float3 VBlurC0PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_0___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 1
// -------------------------------------------------------------------------- //

float3 HBlurC1PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_1___, VBlurSampler);
}

float3 VBlurC1PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_1___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 2
// -------------------------------------------------------------------------- //

float3 HBlurC2PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_2___, VBlurSampler);
}

float3 VBlurC2PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_2___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 3
// -------------------------------------------------------------------------- //

float3 HBlurC3PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_3___, VBlurSampler);
}

float3 VBlurC3PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_3___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 4
// -------------------------------------------------------------------------- //

float3 HBlurC4PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_4___, VBlurSampler);
}

float3 VBlurC4PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_4___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// cascade 5
// -------------------------------------------------------------------------- //

float3 HBlurC5PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from VBlurTex, writes to HBlurTex
    return HBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_5___, VBlurSampler);
}

float3 VBlurC5PS(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD): COLOR {
    // reads from HBlurTex, writes to VBlurTex
    return VBlur(texcoord, ___BLUR_SAMPLE_OFFSET_CASCADE_5___, HBlurSampler);
}

// -------------------------------------------------------------------------- //
// techniques
// -------------------------------------------------------------------------- //

technique FGFXFCSB16X <
    ui_label = "FGFX::FCSB[16X]";
    ui_tooltip =
        "+------------------------------------------------------------+\n"
        "|-=[ FGFX::FCSB[16X] - Fast Cascaded Separable Blur [16X] ]=-|\n"
        "+------------------------------------------------------------+\n"
        "\n"

        "FCSB is a blur technique that combines cascaded H / V blur\n"
        "passes and alias-free down-sampling in order to produce\n"
        "large, smooth and alias-free blur at a fraction of the cost of\n"
        "traditional separable Gaussian blur.\n"
        "\n"

        "The Fast Cascaded Separable Blur is written by Alex Tuduran.\n";
> {

// -------------------------------------------------------------------------- //
// back-buffer reduction
// -------------------------------------------------------------------------- //

#if FCSB16X_ANTI_ALIASED_DOWN_SAMPLING_ON

    pass CopyBB {
        VertexShader = PostProcessVS;
        PixelShader  = CopyBBPS;
        RenderTarget = HalfBlurTex;
    }

    pass CopyHalf {
        VertexShader = PostProcessVS;
        PixelShader  = CopyHalfPS;
        RenderTarget = QuadBlurTex;
    }

    pass CopyQuad {
        VertexShader = PostProcessVS;
        PixelShader  = CopyQuadPS;
        RenderTarget = OctoBlurTex;
    }

    pass CopyOcto {
        VertexShader = PostProcessVS;
        PixelShader  = CopyOctoPS;
        RenderTarget = HexaBlurTex;
    }

#else // FCSB16X_ANTI_ALIASED_DOWN_SAMPLING_ON

    pass CopyBB {
        VertexShader = PostProcessVS;
        PixelShader  = CopyBBPS;
        RenderTarget = HexaBlurTex;
    }

#endif // FCSB16X_ANTI_ALIASED_DOWN_SAMPLING_ON

// -------------------------------------------------------------------------- //
// blur cascades
// -------------------------------------------------------------------------- //

#if FCSB16X_BLUR_ON

    pass CopyHexa {
        VertexShader = PostProcessVS;
        PixelShader  = CopyHexaPS;
        RenderTarget = VBlurTex;
    }

    
#if 1 // cascade 0 rectangular

    pass HBlurC0R {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC0PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC0R {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC0PS;
        RenderTarget = VBlurTex;
    }

#endif

#if 1 // cascade 0 smooth

    pass HBlurC0S {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC0PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC0S {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC0PS;
        RenderTarget = VBlurTex;
    }

#endif

#if 1 // cascade 0 super-smooth

    pass HBlurC0SS {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC0PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC0SS {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC0PS;
        RenderTarget = VBlurTex;
    }

#endif

#if FCSB16X_CASCADE_1_ON // cascade 1 rectangular

    pass HBlurC1R {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC1PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC1R {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC1PS;
        RenderTarget = VBlurTex;
    }

#endif // FCSB16X_CASCADE_1_ON

#if FCSB16X_CASCADE_2_ON // cascade 2 rectangular

    pass HBlurC2R {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC2PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC2R {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC2PS;
        RenderTarget = VBlurTex;
    }

#endif // FCSB16X_CASCADE_2_ON

#if FCSB16X_CASCADE_2_ON // cascade 2 smooth

    pass HBlurC2S {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC2PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC2S {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC2PS;
        RenderTarget = VBlurTex;
    }

#endif // FCSB16X_CASCADE_2_ON

#if FCSB16X_CASCADE_3_ON // cascade 3 rectangular

    pass HBlurC3R {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC3PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC3R {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC3PS;
        RenderTarget = VBlurTex;
    }

#endif // FCSB16X_CASCADE_3_ON

#if 1 // cascade 0 ultra-smooth

    pass HBlurC0US {
        VertexShader = PostProcessVS;
        PixelShader  = HBlurC0PS;
        RenderTarget = HBlurTex;
    }

    pass VBlurC0US {
        VertexShader = PostProcessVS;
        PixelShader  = VBlurC0PS;
        // RenderTarget is back-buffer
    }

#endif

#else // FCSB16X_BLUR_ON

    pass CopyHexaBlur {
        VertexShader = PostProcessVS;
        PixelShader  = CopyHexaPS;
        // RenderTarget is back-buffer
    }

#endif // FCSB16X_BLUR_ON

// -------------------------------------------------------------------------- //

} // technique

// -------------------------------------------------------------------------- //
