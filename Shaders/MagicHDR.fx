//#region Includes

#include "FXShadersCommon.fxh"
#include "FXShadersConvolution.fxh"
#include "FXShadersMath.fxh"
#include "FXShadersTonemap.fxh"

//#endregion

//#region Preprocessor

#ifndef MAGIC_HDR_BLUR_SAMPLES
#define MAGIC_HDR_BLUR_SAMPLES 21
#endif

#if MAGIC_HDR_BLUR_SAMPLES < 1
	#error "Blur samples cannot be less than 1"
#endif

#ifndef MAGIC_HDR_DOWNSAMPLE
#define MAGIC_HDR_DOWNSAMPLE 1
#endif

#if MAGIC_HDR_DOWNSAMPLE < 1
	#error "Downsample cannot be less than 1x"
#endif

//#endregion

namespace FXShaders
{

//#region Constants

static const int2 DownsampleAmount = MAGIC_HDR_DOWNSAMPLE;

static const int BlurSamples = MAGIC_HDR_BLUR_SAMPLES;

static const int InvTonemap_Reinhard = 0;

static const int Tonemap_Reinhard = 0;
static const int Tonemap_BakingLabACES = 1;
static const int Tonemap_Uncharted2Filmic = 2;

//#endregion

//#region Uniforms

FXSHADERS_WIP_WARNING();

FXSHADERS_CREDITS();

FXSHADERS_HELP(
	"This effect allows you to add both bloom and tonemapping, drastically "
	"changing the mood of the image.\n"
	"\n"
	"Care should be taken to select an appropriate inverse tonemapper that can "
	"accurately extract HDR information from the original image.\n"
	"HDR10 users should also take care to select a tonemapper that's "
	"compatible with what the HDR monitor is expecting from the LDR output of "
	"the game, which *is* tonemapped too.\n"
	"\n"
	"Available preprocessor directives:\n"
	"\n"
	"MAGIC_HDR_BLUR_SAMPLES:\n"
	"  Determines how many pixels are sampled during each blur pass for the "
	"bloom effect.\n"
	"  This value directly influences the Blur Size, so the more samples the "
	"bigger the blur size can be.\n"
	"  Setting MAGIC_HDR_DOWNSAMPLE above 1x will also increase the blur size "
	"to compensate for the lower resolution. This effect may be desirable, "
	"however.\n"
	"\n"
	"MAGIC_HDR_DOWNSAMPLE:\n"
	"  Serves to divide the resolution of the textures used for processing the "
	"bloom effect.\n"
	"  Leave at 1x for maximum detail, 2x or 4x should still be fine.\n"
	"  Values too high may introduce flickering.\n"
);

uniform float BloomAmount
<
	ui_category = "Bloom Appearance";
	ui_label = "Bloom Amount";
	ui_tooltip =
		"Amount of bloom to apply to the image.\n"
		"\nDefault: 0.2";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
> = 0.2;

uniform float BlurSize
<
	ui_category = "Blur Appearance";
	ui_label = "Blur Size";
	ui_tooltip =
		"The size of the gaussian blur applied to create the bloom effect.\n"
		"This value is directly influenced by the values of "
		"MAGIC_HDR_BLUR_SAMPLES and MAGIC_HDR_DOWNSAMPLE.\n"
		"\nDefault: 1.0";
	ui_type = "slider";
	ui_min = 0.01;
	ui_max = 1.0;
> = 1.0;

uniform float Whitepoint
<
	ui_category = "Tonemapping";
	ui_label = "Whitepoint";
	ui_tooltip =
		"The whitepoint of the HDR image.\n"
		"Anything with this brightness is pure white.\n"
		"It controls how bright objects are perceived after inverse "
		"tonemapping, with higher values leading to a brighter bloom effect.\n"
		"\nDefault: 2";
	ui_type = "slider";
	ui_min = 1;
	ui_max = 10;
	ui_step = 1;
> = 2;

uniform float Exposure
<
	ui_category = "Tonemapping";
	ui_label = "Exposure";
	ui_tooltip =
		"Exposure applied at the end of the effect.\n"
		"This value is measured in f-stops.\n"
		"\nDefault: 1.0";
	ui_type = "slider";
	ui_min = -3.0;
	ui_max = 3.0;
> = 1.0;

uniform int InvTonemap
<
	ui_category = "Tonemapping";
	ui_label = "Inverse Tonemapper";
	ui_tooltip =
		"The inverse tonemapping operator used at the beginning of the "
		"effect.\n"
		"\nDefault: Reinhard";
	ui_type = "combo";
	ui_items = "Reinhard\0";
> = 0;

uniform int Tonemap
<
	ui_category = "Tonemapping";
	ui_label = "Tonemapper";
	ui_tooltip =
		"The tonemapping operator used at the end of the effect.\n"
		"\nDefault: Baking Lab ACES";
	ui_type = "combo";
	ui_items = "Reinhard\0Baking Lab ACES\0Uncharted 2 Filmic\0";
> = 1;

//#endregion

//#region Textures

texture ColorTex : COLOR;

sampler Color
{
	Texture = ColorTex;
	SRGBTexture = true;
};

// TODO: Try to figure out a way to get rid of the need for this texture.
texture DownsampledTex <pooled = true;>
{
	Width = BUFFER_WIDTH / DownsampleAmount.x;
	Height = BUFFER_HEIGHT / DownsampleAmount.y;
	Format = RGBA16F;
};

sampler Downsampled
{
	Texture = DownsampledTex;
};

texture TempTex <pooled = true;>
{
	Width = BUFFER_WIDTH / DownsampleAmount.x;
	Height = BUFFER_HEIGHT / DownsampleAmount.y;
	Format = RGBA16F;
};

sampler Temp
{
	Texture = TempTex;
};

texture Bloom0Tex <pooled = true;>
{
	Width = BUFFER_WIDTH / DownsampleAmount.x;
	Height = BUFFER_HEIGHT / DownsampleAmount.y;
	Format = RGBA16F;
};

sampler Bloom0
{
	Texture = Bloom0Tex;
};

texture Bloom1Tex <pooled = true;>
{
	Width = BUFFER_WIDTH / DownsampleAmount.x / 2;
	Height = BUFFER_HEIGHT / DownsampleAmount.y / 2;
	Format = RGBA16F;
};

sampler Bloom1
{
	Texture = Bloom1Tex;
};

texture Bloom2Tex <pooled = true;>
{
	Width = BUFFER_WIDTH / DownsampleAmount.x / 4;
	Height = BUFFER_HEIGHT / DownsampleAmount.y / 4;
	Format = RGBA16F;
};

sampler Bloom2
{
	Texture = Bloom2Tex;
};

texture Bloom3Tex <pooled = true;>
{
	Width = BUFFER_WIDTH / DownsampleAmount.x / 8;
	Height = BUFFER_HEIGHT / DownsampleAmount.y / 8;
	Format = RGBA16F;
};

sampler Bloom3
{
	Texture = Bloom3Tex;
};

texture Bloom4Tex <pooled = true;>
{
	Width = BUFFER_WIDTH / DownsampleAmount.x / 16;
	Height = BUFFER_HEIGHT / DownsampleAmount.y / 16;
	Format = RGBA16F;
};

sampler Bloom4
{
	Texture = Bloom4Tex;
};

texture Bloom5Tex <pooled = true;>
{
	Width = BUFFER_WIDTH / DownsampleAmount.x / 32;
	Height = BUFFER_HEIGHT / DownsampleAmount.y / 32;
	Format = RGBA16F;
};

sampler Bloom5
{
	Texture = Bloom5Tex;
};

texture Bloom6Tex <pooled = true;>
{
	Width = BUFFER_WIDTH / DownsampleAmount.x / 64;
	Height = BUFFER_HEIGHT / DownsampleAmount.y / 64;
	Format = RGBA16F;
};

sampler Bloom6
{
	Texture = Bloom6Tex;
};

//#endregion

//#region Functions

float3 ApplyInverseTonemap(float3 color)
{
	float w = max(Whitepoint, FloatEpsilon);
	w = exp2(w);

	// TODO: Add more inverse tonemappers.
	switch (InvTonemap)
	{
		case InvTonemap_Reinhard:
			color = ReinhardInv(color, rcp(w));
			break;
	}

	return color;
}

float4 Blur(sampler sp, float2 uv, float2 dir)
{
	float4 color = GaussianBlur1D(
		sp,
		uv,
		dir * GetPixelSize() * DownsampleAmount,
		sqrt(BlurSamples) * BlurSize,
		BlurSamples);

	return color;
}

//#endregion

//#region Shaders

float4 InverseTonemapPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{
	const float4 color = tex2D(Color, uv);

	// TODO: Saturation and other color filtering options?

	return float4(ApplyInverseTonemap(color.rgb), color.a);
}

// TODO: Create a blur shader macro?
float4 Blur0PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Downsampled, uv, float2(1.0, 0.0));
}

float4 Blur1PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Temp, uv, float2(0.0, 1.0));
}

float4 Blur2PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Bloom0, uv, float2(2.0, 0.0));
}

float4 Blur3PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Temp, uv, float2(0.0, 2.0));
}

float4 Blur4PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Bloom1, uv, float2(4.0, 0.0));
}

float4 Blur5PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Temp, uv, float2(0.0, 4.0));
}

float4 Blur6PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Bloom2, uv, float2(8.0, 0.0));
}

float4 Blur7PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Temp, uv, float2(0.0, 8.0));
}

float4 Blur8PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Bloom3, uv, float2(16.0, 0.0));
}

float4 Blur9PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Temp, uv, float2(0.0, 16.0));
}

float4 Blur10PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Bloom4, uv, float2(32.0, 0.0));
}

float4 Blur11PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Temp, uv, float2(0.0, 32.0));
}

float4 Blur12PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Bloom5, uv, float2(64.0, 0.0));
}

float4 Blur13PS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	return Blur(Temp, uv, float2(0.0, 64.0));
}

float4 TonemapPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD) : SV_TARGET
{
	float4 color = tex2D(Color, uv);
	color.rgb = ApplyInverseTonemap(color.rgb);

	// TODO: Maybe implement normal distribution?

	float4 bloom =
		tex2D(Bloom0, uv) +
		tex2D(Bloom1, uv) +
		tex2D(Bloom2, uv) +
		tex2D(Bloom3, uv) +
		tex2D(Bloom4, uv) +
		tex2D(Bloom5, uv) +
		tex2D(Bloom6, uv);

	bloom /= 7;

	color.rgb = lerp(color.rgb, bloom.rgb, log10(BloomAmount + 1.0));

	// TODO: Implement adaptation.
	float exposure = exp(Exposure);

	// TODO: Add more tonemappers.
	switch (Tonemap)
	{
		case Tonemap_Reinhard:
			color.rgb = Reinhard(color.rgb * exposure);
			break;
		case Tonemap_BakingLabACES:
			color.rgb = BakingLabACESTonemap(color.rgb * exposure);
			break;
		case Tonemap_Uncharted2Filmic:
			color.rgb = Uncharted2Tonemap(color.rgb * exposure);
			break;
	}

	return color;
}

//#endregion

//#region Technique

technique MagicHDR <ui_tooltip = "FXShaders - Bloom and tonemapping effect.";>
{
	pass InverseTonemap
	{
		VertexShader = ScreenVS;
		PixelShader = InverseTonemapPS;
		RenderTarget = DownsampledTex;
	}
	// TODO: Create a blur pass macro?
	pass Blur0
	{
		VertexShader = ScreenVS;
		PixelShader = Blur0PS;
		RenderTarget = TempTex;
	}
	pass Blur1
	{
		VertexShader = ScreenVS;
		PixelShader = Blur1PS;
		RenderTarget = Bloom0Tex;
	}
	pass Blur2
	{
		VertexShader = ScreenVS;
		PixelShader = Blur2PS;
		RenderTarget = TempTex;
	}
	pass Blur3
	{
		VertexShader = ScreenVS;
		PixelShader = Blur3PS;
		RenderTarget = Bloom1Tex;
	}
	pass Blur4
	{
		VertexShader = ScreenVS;
		PixelShader = Blur4PS;
		RenderTarget = TempTex;
	}
	pass Blur5
	{
		VertexShader = ScreenVS;
		PixelShader = Blur5PS;
		RenderTarget = Bloom2Tex;
	}
	pass Blur6
	{
		VertexShader = ScreenVS;
		PixelShader = Blur6PS;
		RenderTarget = TempTex;
	}
	pass Blur7
	{
		VertexShader = ScreenVS;
		PixelShader = Blur7PS;
		RenderTarget = Bloom3Tex;
	}
	pass Blur8
	{
		VertexShader = ScreenVS;
		PixelShader = Blur8PS;
		RenderTarget = TempTex;
	}
	pass Blur9
	{
		VertexShader = ScreenVS;
		PixelShader = Blur9PS;
		RenderTarget = Bloom4Tex;
	}
	pass Blur10
	{
		VertexShader = ScreenVS;
		PixelShader = Blur10PS;
		RenderTarget = TempTex;
	}
	pass Blur11
	{
		VertexShader = ScreenVS;
		PixelShader = Blur11PS;
		RenderTarget = Bloom5Tex;
	}
	pass Blur12
	{
		VertexShader = ScreenVS;
		PixelShader = Blur12PS;
		RenderTarget = TempTex;
	}
	pass Blur13
	{
		VertexShader = ScreenVS;
		PixelShader = Blur13PS;
		RenderTarget = Bloom6Tex;
	}
	pass Tonemap
	{
		VertexShader = ScreenVS;
		PixelShader = TonemapPS;
		SRGBWriteEnable = true;
	}
}

//#endregion

} // Namespace.
