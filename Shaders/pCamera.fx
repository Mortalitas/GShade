///////////////////////////////////////////////////////////////////////////////////
// pCamera.fx by Gimle Larpes
// A high performance all-in-one shader with many common lens and camera effects.
// License: MIT
// Repository: https://github.com/GimleLarpes/potatoFX
//
// MIT License
//
// Copyright (c) 2023 Gimle Larpes
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///////////////////////////////////////////////////////////////////////////////////

#define P_OKLAB_VERSION_REQUIRE 103
#include "ReShade.fxh"
#include "Oklab.fxh"

//Version check
#if !defined(__RESHADE__) || __RESHADE__ < 50900
	#error "Outdated ReShade installation - ReShade 5.9+ is required"
#endif


static const float PI = pUtils::PI;
static const float EPSILON = pUtils::EPSILON;

//Blur
uniform float BlurStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Blur amount";
	ui_tooltip = "Amount of blur to apply";
	ui_category = "Blur";
> = 0.0;
uniform int GaussianQuality <
	ui_type = "radio";
	ui_label = "Blur quality";
	ui_tooltip = "Quality and size of gaussian blur";
	ui_items = "High quality\0Medium quality\0Fast\0";
	ui_category = "Blur";
> = 2;

//DOF
#ifndef DOF_SENSOR_SIZE
	#define DOF_SENSOR_SIZE 36.0
#endif
uniform bool UseDOF <
	ui_type = "bool";
	ui_label = "Enable DOF";
	ui_tooltip = "Use depth of field\n\nMake sure depth is set up correctly using DisplayDepth.fx";
	ui_category = "DOF";
> = false;
uniform float DOFAperture <
	ui_type = "slider";
	ui_min = 0.95; ui_max = 22.0;
	ui_label = "Aperture";
	ui_tooltip = "Aperture of the simulated camera";
	ui_category = "DOF";
> = 1.4;
uniform int DOFFocalLength <
	ui_type = "slider";
	ui_min = 12u; ui_max = 85u;
	ui_label = "Focal length";
	ui_tooltip = "Focal length of the simulated camera";
	ui_category = "DOF";
	ui_units = " mm";
> = 35u;
uniform bool UseDOFAF <
	ui_type = "bool";
	ui_label = "Autofocus";
	ui_tooltip = "Use autofocus";
	ui_category = "DOF";
> = true;
uniform float DOFFocusSpeed <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 5;
	ui_label = "Focus speed";
	ui_tooltip = "Focus speed in seconds";
	ui_category = "DOF";
	ui_units = " s";
> = 0.5;
uniform float DOFFocusPx <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Focus point X";
	ui_tooltip = "AF focus point position X (width)\nLeft side = 0\nRight side = 1";
	ui_category = "DOF";
> = 0.5;
uniform float DOFFocusPy <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Focus point Y";
	ui_tooltip = "AF focus point position Y (height)\nTop side = 0\nBottom side = 1";
	ui_category = "DOF";
> = 0.5;
uniform float DOFManualFocusDist <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Manual focus";
	ui_tooltip = "Manual focus distance, only used when autofocus is disabled";
	ui_category = "DOF";
> = 0.5;
uniform int BokehQuality <
	ui_type = "radio";
	ui_label = "Blur quality";
	ui_tooltip = "Quality and size of bokeh blur";
	ui_items = "High quality\0Medium quality\0Fast\0";
	ui_category = "DOF";
> = 2;
uniform bool DOFDebug <
	ui_type = "bool";
	ui_label = "AF debug";
	ui_tooltip = "Display autofocus point";
	ui_category = "DOF";
> = false;

//Fish eye
uniform bool UseFE <
	ui_type = "bool";
	ui_label = "Fisheye";
	ui_tooltip = "Adds fisheye distortion";
	ui_category = "Fisheye";
> = false;
uniform int FEFoV <
	ui_type = "slider";
	ui_min = 20u; ui_max = 160u;
	ui_label = "FOV";
	ui_tooltip = "FOV in degrees\n\n(set to in-game FOV)";
	ui_category = "Fisheye";
	ui_units = "°";
> = 90u;
uniform float FECrop <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Crop";
	ui_tooltip = "How much to crop into the image\n\n(0 = circular, 1 = full-frame)";
	ui_category = "Fisheye";
> = 0.0;
uniform bool FEVFOV <
	ui_type = "bool";
	ui_label = "Use vertical FOV";
	ui_tooltip = "Assume FOV is vertical\n\n(enable if FOV is given as vertical FOV)";
	ui_category = "Fisheye";
> = false;

//Glass imperfections
uniform float GeoIStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 4.0;
	ui_label = "Glass quality";
	ui_tooltip = "Amount of surface lens imperfections";
	ui_category = "Lens Imperfections";
> = 0.25;

//Chromatic aberration
uniform float CAStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "CA amount";
	ui_tooltip = "Amount of chromatic aberration";
	ui_category = "Lens Imperfections";
> = 0.04;

//Dirt
uniform float DirtStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Dirt amount";
	ui_tooltip = "Amount of dirt on the lens";
	ui_category = "Lens Imperfections";
> = 0.08;
uniform float DirtScale <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 2.5;
	ui_label = "Dirt scale";
	ui_tooltip = "Scaling of dirt texture";
	ui_category = "Lens Imperfections";
> = 1.35;

//Bloom
#if BUFFER_COLOR_SPACE > 1
	static const float BLOOM_CURVE_DEFAULT = 1.0;
	static const float BLOOM_GAMMA_DEFAULT = 1.0;
#else
	static const float BLOOM_CURVE_DEFAULT = 1.0;
	static const float BLOOM_GAMMA_DEFAULT = 0.8;

	#ifndef HDR_ACES_TONEMAP
		#define HDR_ACES_TONEMAP 1
	#endif
#endif
uniform float BloomStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Bloom amount";
	ui_tooltip = "Amount of blooming to apply";
	ui_category = "Bloom";
> = 0.18;
uniform float BloomRadius <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 1.0;
	ui_label = "Bloom radius";
	ui_tooltip = "Controls radius of bloom";
	ui_category = "Bloom";
> = 0.95;
uniform float BloomCurve <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 5.0;
	ui_label = "Bloom curve";
	ui_tooltip = "What parts of the image to apply bloom to\n1 = linear      5 = brightest parts only";
	ui_category = "Bloom";
> = BLOOM_CURVE_DEFAULT;
uniform float BloomGamma <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 2;
	ui_label = "Bloom gamma";
	ui_tooltip = "Controls shape of bloom";
	ui_category = "Bloom";
> = BLOOM_GAMMA_DEFAULT;

//Lens flare
#if BUFFER_COLOR_SPACE > 1
	static const float LFLARE_GLOCALMASK_DEFAULT = false;
	static const float LFLARE_CURVE_DEFAULT = 0.4;
	static const float LFLARE_STRENGTH_DEFAULT = 0.5;
#else
	static const float LFLARE_GLOCALMASK_DEFAULT = true;
	static const float LFLARE_CURVE_DEFAULT = 1.0;
	static const float LFLARE_STRENGTH_DEFAULT = 0.25;
#endif
uniform bool UseLF <
	ui_type = "bool";
	ui_label = "Lens flare";
	ui_tooltip = "Apply ghosting, haloing and glare from light sources";
	ui_category = "Lens Flare";
> = true;
uniform bool GLocalMask <
	ui_type = "bool";
	ui_label = "Non-intrusive lens flares";
	ui_tooltip = "Only apply flaring when looking right at light sources";
	ui_category = "Lens Flare";
> = LFLARE_GLOCALMASK_DEFAULT;
uniform float LFStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Lens flare amount";
	ui_tooltip = "Amount of flaring to apply";
	ui_category = "Lens Flare";
> = LFLARE_STRENGTH_DEFAULT;
#ifndef ENABLE_ADVANCED_LENS_FLARE_SETTINGS
	#define ENABLE_ADVANCED_LENS_FLARE_SETTINGS 0
#endif
#if ENABLE_ADVANCED_LENS_FLARE_SETTINGS
	uniform float GhostStrength <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 1.0;
		ui_label = "Ghosting amount";
		ui_tooltip = "Amount of ghosting to apply";
		ui_category = "Lens Flare";
	> = 0.3;

	//Ghost 1
	uniform float4 GColor1 <
		ui_type = "color";
		ui_label = "Color 1";
		ui_tooltip = "Tint of ghost 1";
		ui_category = "Lens Flare";
	> = float4(1.0, 0.8, 0.4, 1.0);
	uniform float GSize1 <
		ui_type = "slider";
		ui_min = -10.0; ui_max = 10.0;
		ui_label = "Size 1";
		ui_tooltip = "Size of ghost 1";
		ui_category = "Lens Flare";
	> = -1.5;
	//Ghost 2
	uniform float4 GColor2 <
		ui_type = "color";
		ui_label = "Color 2";
		ui_tooltip = "Tint of ghost 2";
		ui_category = "Lens Flare";
	> = float4(1.0, 1.0, 0.6, 1.0);
	uniform float GSize2 <
		ui_type = "slider";
		ui_min = -10.0; ui_max = 10.0;
		ui_label = "Size 2";
		ui_tooltip = "Size of ghost 2";
		ui_category = "Lens Flare";
	> = 2.5;
	//Ghost 3
	uniform float4 GColor3 <
		ui_type = "color";
		ui_label = "Color 3";
		ui_tooltip = "Tint of ghost 3";
		ui_category = "Lens Flare";
	> = float4(0.8, 0.8, 1.0, 1.0);
	uniform float GSize3 <
		ui_type = "slider";
		ui_min = -10.0; ui_max = 10.0;
		ui_label = "Size 3";
		ui_tooltip = "Size of ghost 3";
		ui_category = "Lens Flare";
	> = -5.0;
	//Ghost 4
	uniform float4 GColor4 <
		ui_type = "color";
		ui_label = "Color 4";
		ui_tooltip = "Tint of ghost 4";
		ui_category = "Lens Flare";
	> = float4(0.5, 1.0, 0.4, 1.0);
	uniform float GSize4 <
		ui_type = "slider";
		ui_min = -10.0; ui_max = 10.0;
		ui_label = "Size 4";
		ui_tooltip = "Size of ghost 4";
		ui_category = "Lens Flare";
	> = 10.0;
	//Ghost 5
	uniform float4 GColor5 <
		ui_type = "color";
		ui_label = "Color 5";
		ui_tooltip = "Tint of ghost 5";
		ui_category = "Lens Flare";
	> = float4(0.5, 0.8, 1.0, 1.0);
	uniform float GSize5 <
		ui_type = "slider";
		ui_min = -10.0; ui_max = 10.0;
		ui_label = "Size 5";
		ui_tooltip = "Size of ghost 5";
		ui_category = "Lens Flare";
	> = 0.7;
	//Ghost 6
	uniform float4 GColor6 <
		ui_type = "color";
		ui_label = "Color 6";
		ui_tooltip = "Tint of ghost 6";
		ui_category = "Lens Flare";
	> = float4(0.9, 1.0, 0.8, 1.0);
	uniform float GSize6 <
		ui_type = "slider";
		ui_min = -10.0; ui_max = 10.0;
		ui_label = "Size 6";
		ui_tooltip = "Size of ghost 6";
		ui_category = "Lens Flare";
	> = -0.4;
	//Ghost 7
	uniform float4 GColor7 <
		ui_type = "color";
		ui_label = "Color 7";
		ui_tooltip = "Tint of ghost 7";
		ui_category = "Lens Flare";
	> = float4(1.0, 0.8, 0.4, 1.0);
	uniform float GSize7 <
		ui_type = "slider";
		ui_min = -10.0; ui_max = 10.0;
		ui_label = "Size 7";
		ui_tooltip = "Size of ghost 7";
		ui_category = "Lens Flare";
	> = -0.2;
	//Ghost 8
	uniform float4 GColor8 <
		ui_type = "color";
		ui_label = "Color 8";
		ui_tooltip = "Tint of ghost 8";
		ui_category = "Lens Flare";
	> = float4(0.9, 0.7, 0.7, 1.0);
	uniform float GSize8 <
		ui_type = "slider";
		ui_min = -10.0; ui_max = 10.0;
		ui_label = "Size 8";
		ui_tooltip = "Size of ghost 8";
		ui_category = "Lens Flare";
	> = -0.1;

	uniform float HaloStrength <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 1.0;
		ui_label = "Halo amount";
		ui_tooltip = "Amount of haloing to apply";
		ui_category = "Lens Flare";
	> = 0.2;
	uniform float HaloRadius <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 0.8;
		ui_label = "Halo radius";
		ui_tooltip = "Radius of the halo";
		ui_category = "Lens Flare";
	> = 0.5;
	uniform float HaloWidth <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 1.0;
		ui_label = "Halo width";
		ui_tooltip = "Width of the halo";
		ui_category = "Lens Flare";
	> = 0.5;
#else
	static const float GhostStrength = 0.3;
	static const float HaloStrength = 0.2;
	static const float HaloRadius = 0.5;
	static const float HaloWidth = 0.5;
	static const float LensFlareCA = 1.0;
#endif
uniform float GlareStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Glare amount";
	ui_tooltip = "Amount of glare to apply";
	ui_category = "Lens Flare";
> = 0.5;
uniform int GlareQuality <
	ui_type = "radio";
	ui_label = "Glare size";
	ui_tooltip = "Quality and size of glare";
	ui_items = "Large\0Medium\0Small\0";
	ui_category = "Lens Flare";
> = 1;
uniform float LensFlareCurve <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Lens flare curve";
	ui_tooltip = "What parts of the image produce lens flares";
	ui_category = "Lens Flare";
> = LFLARE_CURVE_DEFAULT;
#if ENABLE_ADVANCED_LENS_FLARE_SETTINGS
	uniform float LensFlareCA <
		ui_type = "slider";
		ui_min = 0.0; ui_max = 2.0;
		ui_label = "Lens flare CA";
		ui_tooltip = "Lens flare chromatic aberration";
		ui_category = "Lens Flare";
	> = 1.0;
#endif

//Vignette
uniform float VignetteStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Vignette amount";
	ui_tooltip = "Amount of vignetting to apply";
	ui_category = "Vignette";
> = 0.0;
uniform float VignetteInnerRadius <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.25;
	ui_label = "Inner radius";
	ui_tooltip = "Inner vignette radius";
	ui_category = "Vignette";
> = 0.25;
uniform float VignetteOuterRadius <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.5;
	ui_label = "Outer radius";
	ui_tooltip = "Outer vignette radius";
	ui_category = "Vignette";
> = 0.75;
uniform float VignetteWidth <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Width";
	ui_tooltip = "Controls the shape of vignette";
	ui_category = "Vignette";
> = 1.0;
uniform bool VignetteDebug <
	ui_type = "bool";
	ui_label = "Vignette debug";
	ui_tooltip = "Display vignette radii";
	ui_category = "Vignette";
> = false;

//Noise
uniform float NoiseStrength <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Noise amount";
	ui_tooltip = "Amount of noise to apply";
	ui_category = "Noise";
> = 0.08;
uniform int NoiseType <
	ui_type = "radio";
	ui_label = "Noise type";
	ui_tooltip = "Type of noise to use";
	ui_items = "Film grain\0Color noise\0";
	ui_category = "Noise";
> = 0;

//Auto exposure
#ifndef AE_RANGE
	#define AE_RANGE 1.0
#endif
#ifndef AE_MIN_BRIGHTNESS
	#define AE_MIN_BRIGHTNESS 0.02
#endif
uniform bool UseAE <
	ui_type = "bool";
	ui_label = "Auto exposure";
	ui_tooltip = "Enable auto exposure";
	ui_category = "Auto Exposure";
> = false;
uniform bool AEProtectHighlights <
	ui_type = "bool";
	ui_label = "Only underexpose";
	ui_tooltip = "Only changes exposure to recover blown-out highlights";
	ui_category = "Auto Exposure";
> = false;
uniform float AESpeed <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 10.0;
	ui_label = "Speed";
	ui_tooltip = "Auto exposure adaption speed in seconds";
	ui_category = "Auto Exposure";
	ui_units = " s";
> = 1.0;
uniform float AEGain <
	ui_type = "slider";
	ui_min = 0.1; ui_max = 1.0;
	ui_label = "Gain";
	ui_tooltip = "Auto exposure gain";
	ui_category = "Auto Exposure";
> = 0.5;
uniform float AETarget <
	ui_type = "slider";
	ui_min = AE_MIN_BRIGHTNESS; ui_max = 1.0;
	ui_label = "Target";
	ui_tooltip = "Exposure target";
	ui_category = "Auto Exposure";
> = 0.5;
uniform int AEMetering <
	ui_type = "radio";
	ui_label = "Metering mode";
	ui_tooltip = "What metering mode is used:\nMatrix metering considers the whole screen\nSpot metering only considers the center of the screen";
	ui_items = "Matrix\0Spot\0";
	ui_category = "Auto Exposure";
> = 0;
uniform float AEHighlightSensitivity <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 40.0;
	ui_label = "Highlight sensitivity";
	ui_tooltip = "Matrix metering: How sensitive metering is to overexposing highlights";
	ui_category = "Auto Exposure";
> = 10.0;
uniform float AEPx <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "AE point X";
	ui_tooltip = "Spot metering: Metering point X position (width)\nLeft side = 0\nRight side = 1";
	ui_category = "Auto Exposure";
> = 0.5;
uniform float AEPy <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "AE point Y";
	ui_tooltip = "Spot metering: Metering point Y position (height)\nTop side = 0\nBottom side = 1";
	ui_category = "Auto Exposure";
> = 0.5;
uniform bool AEDebug <
	ui_type = "bool";
	ui_label = "AE debug";
	ui_tooltip = "Spot metering: Display metering point";
	ui_category = "Auto Exposure";
> = false;


//Performance
uniform bool UseApproximateTransforms <
	ui_type = "bool";
	ui_label = "Fast colorspace transform";
	ui_tooltip = "Use less accurate approximations instead of the full transform functions";
	ui_category = "Performance";
> = false;


#ifndef _BUMP_MAP_RESOLUTION
	#define _BUMP_MAP_RESOLUTION 32
#endif
#ifndef _BUMP_MAP_SCALE
	#define _BUMP_MAP_SCALE 4
#endif
#ifndef _BUMP_MAP_SOURCE
	#define _BUMP_MAP_SOURCE "pBumpTex.png"
#endif

#ifndef _DIRT_MAP_RESOLUTION
	#define _DIRT_MAP_RESOLUTION 1024
#endif
#ifndef _DIRT_MAP_SOURCE
	#define _DIRT_MAP_SOURCE "pDirtTex.png"
#endif

#ifndef _LENS_COLOR_MAP_RESOLUTION
	#define _LENS_COLOR_MAP_RESOLUTION 16
#endif

#ifndef _STORAGE_TEX_RESOLUTION
	#define _STORAGE_TEX_RESOLUTION 32
#endif
static const int STORAGE_TEX_MIPLEVELS = 3;

texture pStorageTex < pooled = true; > { Width = _STORAGE_TEX_RESOLUTION; Height = _STORAGE_TEX_RESOLUTION; Format = RG16F; MipLevels = STORAGE_TEX_MIPLEVELS; };
sampler spStorageTex { Texture = pStorageTex; };
texture pStorageTexC < pooled = true; > { Width = _STORAGE_TEX_RESOLUTION; Height = _STORAGE_TEX_RESOLUTION; Format = RG16F; };
sampler spStorageTexC { Texture = pStorageTexC; };

texture pBumpTex < source = _BUMP_MAP_SOURCE; pooled = true; > { Width = _BUMP_MAP_RESOLUTION; Height = _BUMP_MAP_RESOLUTION; Format = RG8; };
sampler spBumpTex { Texture = pBumpTex; AddressU = REPEAT; AddressV = REPEAT; };

texture pDirtTex < source = _DIRT_MAP_SOURCE; pooled = true; > { Width = _DIRT_MAP_RESOLUTION; Height = _DIRT_MAP_RESOLUTION; Format = RGBA8; };
sampler spDirtTex { Texture = pDirtTex; AddressU = REPEAT; AddressV = REPEAT; };

texture pBokehBlurTex < pooled = true; > { Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = RGBA16F; };
sampler spBokehBlurTex { Texture = pBokehBlurTex; AddressU = MIRROR; AddressV = MIRROR; };
texture pGaussianBlurTex < pooled = true; > { Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = RGBA16F; };
sampler spGaussianBlurTex { Texture = pGaussianBlurTex; AddressU = MIRROR; AddressV = MIRROR; };

texture pFlareTex < pooled = true; > { Width = BUFFER_WIDTH/4; Height = BUFFER_HEIGHT/4; Format = RGBA16F; };
sampler spFlareTex { Texture = pFlareTex; };
texture pFlareSrcTex < pooled = true; > { Width = BUFFER_WIDTH/4; Height = BUFFER_HEIGHT/4; Format = RGBA16F; };
sampler spFlareSrcTex { Texture = pFlareSrcTex; AddressU = BORDER; AddressV = BORDER; };

texture pBloomTex0 < pooled = true; > { Width = BUFFER_WIDTH/2; Height = BUFFER_HEIGHT/2; Format = RGBA16F; };
sampler spBloomTex0 { Texture = pBloomTex0; AddressU = MIRROR; AddressV = MIRROR; };
texture pBloomTex1 < pooled = true; > { Width = BUFFER_WIDTH/4; Height = BUFFER_HEIGHT/4; Format = RGBA16F; };
sampler spBloomTex1 { Texture = pBloomTex1; AddressU = MIRROR; AddressV = MIRROR; };
texture pBloomTex2 < pooled = true; > { Width = BUFFER_WIDTH/8; Height = BUFFER_HEIGHT/8; Format = RGBA16F; };
sampler spBloomTex2 { Texture = pBloomTex2; AddressU = MIRROR; AddressV = MIRROR; };
texture pBloomTex3 < pooled = true; > { Width = BUFFER_WIDTH/16; Height = BUFFER_HEIGHT/16; Format = RGBA16F; };
sampler spBloomTex3 { Texture = pBloomTex3; AddressU = MIRROR; AddressV = MIRROR; };
texture pBloomTex4 < pooled = true; > { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; Format = RGBA16F; };
sampler spBloomTex4 { Texture = pBloomTex4; AddressU = MIRROR; AddressV = MIRROR; };
texture pBloomTex5 < pooled = true; > { Width = BUFFER_WIDTH/64; Height = BUFFER_HEIGHT/64; Format = RGBA16F; };
sampler spBloomTex5 { Texture = pBloomTex5; AddressU = MIRROR; AddressV = MIRROR; };
texture pBloomTex6 < pooled = true; > { Width = BUFFER_WIDTH/128; Height = BUFFER_HEIGHT/128; Format = RGBA16F; };
sampler spBloomTex6 { Texture = pBloomTex6; AddressU = MIRROR; AddressV = MIRROR; };
texture pBloomTex7 < pooled = true; > { Width = BUFFER_WIDTH/256; Height = BUFFER_HEIGHT/256; Format = RGBA16F; };
sampler spBloomTex7 { Texture = pBloomTex7; AddressU = MIRROR; AddressV = MIRROR; };
texture pBloomTex8 < pooled = true; > { Width = BUFFER_WIDTH/512; Height = BUFFER_HEIGHT/512; Format = RGBA16F; };
sampler spBloomTex8 { Texture = pBloomTex8; AddressU = MIRROR; AddressV = MIRROR; };


//Functions
float2 FishEye(float2 texcoord, float FEFoV, float FECrop)
{
	float2 radiant_vector = texcoord - 0.5;
	float diagonal_length = length(pUtils::ASPECT_RATIO);
		
	float fov_factor = PI * float(FEFoV)/360.0;
	if (FEVFOV)
	{
		fov_factor = atan(tan(fov_factor) * BUFFER_ASPECT_RATIO);
	}

	float fit_fov = sin(atan(tan(fov_factor) * diagonal_length));
	float crop_value = lerp(1.0 + (diagonal_length - 1.0) * cos(fov_factor), diagonal_length, FECrop * pow(abs(sin(fov_factor)), 6.0));//This is stupid and there is a better way.
		
	//Circularize radiant vector and apply cropping
	float2 cn_radiant_vector = 2.0 * radiant_vector * pUtils::ASPECT_RATIO / crop_value * fit_fov;

	if (length(cn_radiant_vector) < 1.0)
	{
		//Calculate z-coordinate and angle
		float z = sqrt(1.0 - cn_radiant_vector.x*cn_radiant_vector.x - cn_radiant_vector.y*cn_radiant_vector.y);
		float theta = acos(z) / fov_factor;

		float2 d = normalize(cn_radiant_vector);
		texcoord = (theta * d) / (2.0 * pUtils::ASPECT_RATIO) + 0.5;
	} 

	return texcoord;
}

float3 SampleLinear(float2 texcoord)
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	color = (UseApproximateTransforms)
		? Oklab::Fast_DisplayFormat_to_Linear(color)
		: Oklab::DisplayFormat_to_Linear(color);
	return color;
}
float3 SampleLinear(float2 texcoord, bool use_tonemap)
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
	color = (UseApproximateTransforms)
		? Oklab::Fast_DisplayFormat_to_Linear(color)
		: Oklab::DisplayFormat_to_Linear(color);

	if (use_tonemap && !Oklab::IS_HDR)
	{
		color = Oklab::TonemapInv(color);
	}
    
	return color;
}

float4 SampleCA(sampler s, float2 texcoord, float strength)
{
	float3 influence = float3(0.04, 0.0, 0.03);
	float2 CAr = (texcoord - 0.5) * (1.0 - strength * influence.r) + 0.5;
	float2 CAb = (texcoord - 0.5) * (1.0 + strength * influence.b) + 0.5;

	float4 color;
	color.r = tex2D(s, CAr).r;
	color.ga = tex2D(s, texcoord).ga;
	color.b = tex2D(s, CAb).b;

	return color;
}

float3 RedoTonemap(float3 c)
{
	return (Oklab::IS_HDR) ? c : Oklab::Tonemap(c);
}

float3 ClipBlacks(float3 c)
{
    return float3(max(c.r, 0.0), max(c.g, 0.0), max(c.b, 0.0));
}

float4 KarisAverage(float4 c)
{
	return 1.0 / (1.0 + Oklab::get_Luminance_RGB(c.rgb) * 0.25);
}

float4 GaussianBlur(sampler s, float2 texcoord, float size, float2 direction, bool sample_linear, int quality)
{
	float2 TEXEL_SIZE = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 step_length = TEXEL_SIZE * size;

	int start;
	int end;
	switch (quality)
	{
		case 0: //High quality 31 samples
		{
			start = 12;
			end = 28;
		} break;
		case 1: //Medium quality 15 samples
		{
			start = 4;
			end = 12;
		} break;
		case 2: //Fast 7 samples
		{
			start = 0;
			end = 4;
		} break;
	}

	static const float OFFSET[28] = { 0.0, 1.4118, 3.2941, 5.1765, 
	                                  0.0, 1.4839, 3.4624, 5.4409, 7.4194, 9.3978, 11.3763, 13.3548, 
	                                  0.0, 1.4971, 3.4931, 5.4892, 7.4853, 9.4813, 11.4774, 13.4735, 15.4695, 17.4656, 19.4617, 21.4578, 23.4538, 25.4499, 27.4460, 29.4420 };
	static const float WEIGHT[28] = { 0.1965, 0.2969, 0.0945, 0.0104, 
	                                  0.0832, 0.1577, 0.1274, 0.0868, 0.0497, 0.0239, 0.0096, 0.0032, 
	                                  0.0356, 0.0706, 0.0678, 0.0632, 0.0571, 0.0500, 0.0424, 0.0348, 0.0277, 0.0214, 0.0160, 0.0116, 0.0081, 0.0055, 0.0036, 0.0023 };
    
	float4 color;
	[branch]
	if (sample_linear)
	{
		color.rgb = SampleLinear(texcoord, true) * WEIGHT[start];
		[unroll]
		for (int i = start + 1; i < end; ++i)
		{
			color.rgb += SampleLinear(texcoord + direction * OFFSET[i] * step_length, true) * WEIGHT[i];
			color.rgb += SampleLinear(texcoord - direction * OFFSET[i] * step_length, true) * WEIGHT[i];
		}
	}
	else
	{
		color = tex2D(s, texcoord) * WEIGHT[start];
		[unroll]
		for (int i = start + 1; i < end; ++i)
		{
			color += tex2D(s, texcoord + direction * OFFSET[i] * step_length) * WEIGHT[i];
			color += tex2D(s, texcoord - direction * OFFSET[i] * step_length) * WEIGHT[i];
		}
	}

	return color;
}

float3 BokehBlur(sampler s, float2 texcoord, float size, bool sample_linear)
{
	float brightness_compensation;
	float size_compensation;
	int samples;

	switch (BokehQuality)
	{
		case 0: //High quality (91 points, 5 rings)
		{
			brightness_compensation = 0.010989010989;
			size_compensation = 1.0;
			samples = 90;
		} break;
		case 1: //Medium quality (37 points, 3 rings)
		{
			brightness_compensation = 0.027027027027;
			size_compensation = 1.666666666667;
			samples = 36;
		} break;
		case 2: //Fast (low quality, 13 points, 2 rings)
		{
			brightness_compensation = 0.0769230769231;
			size_compensation = 2.5;
			samples = 12;
		} break;
	}

	static const float2 OFFSET[90] = { float2(0.0, 4.0), float2(3.4641, 2.0), float2(3.4641, -2.0), float2(0.0, -4.0), float2(-3.4641, -2.0), float2(-3.4641, 2.0), float2(0.0, 8.0), float2(6.9282, 4.0), float2(6.9282, -4.0), float2(0.0, -8.0), float2(-6.9282, -4.0), float2(-6.9282, 4.0), float2(4.0, 6.9282), float2(8.0, 0.0), float2(4.0, -6.9282), float2(-4.0, -6.9282), float2(-8.0, 0.0), float2(-4.0, 6.9282), float2(0.0, 12.0), float2(4.1042, 11.2763), float2(7.7135, 9.1925), float2(10.3923, 6.0), float2(11.8177, 2.0838), float2(11.8177, -2.0838), float2(10.3923, -6.0), float2(7.7135, -9.1925), float2(4.1042, -11.2763), float2(0.0, -12.0), float2(-4.1042, -11.2763), float2(-7.7135, -9.1925), float2(-10.3923, -6.0), float2(-11.8177, -2.0838), float2(-11.8177, 2.0838), float2(-10.3923, 6.0), float2(-7.7135, 9.1925), float2(-4.1042, 11.2763), float2(0.0, 16.0), float2(4.1411, 15.4548), float2(8.0, 13.8564), float2(11.3137, 11.3137), float2(13.8564, 8.0), float2(15.4548, 4.1411), float2(16.0, 0.0), float2(15.4548, -4.1411), float2(13.8564, -8.0), float2(11.3137, -11.3137), float2(8.0, -13.8564), float2(4.1411, -15.4548), float2(0.0, -16.0), float2(-4.1411, -15.4548), float2(-8.0, -13.8564), float2(-11.3137, -11.3137), float2(-13.8564, -8.0), float2(-15.4548, -4.1411), float2(-16.0, 0.0), float2(-15.4548, 4.1411), float2(-13.8564, 8.0), float2(-11.3137, 11.3137), float2(-8.0, 13.8564), float2(-4.1411, 15.4548), float2(0.0, 20.0), float2(4.1582, 19.563), float2(8.1347, 18.2709), float2(11.7557, 16.1803), float2(14.8629, 13.3826), float2(17.3205, 10.0), float2(19.0211, 6.1803), float2(19.8904, 2.0906), float2(19.8904, -2.0906), float2(19.0211, -6.1803), float2(17.3205, -10.0), float2(14.8629, -13.3826), float2(11.7557, -16.1803), float2(8.1347, -18.2709), float2(4.1582, -19.563), float2(0.0, -20.0), float2(-4.1582, -19.563), float2(-8.1347, -18.2709), float2(-11.7557, -16.1803), float2(-14.8629, -13.3826), float2(-17.3205, -10.0), float2(-19.0211, -6.1803), float2(-19.8904, -2.0906), float2(-19.8904, 2.0906), float2(-19.0211, 6.1803), float2(-17.3205, 10.0), float2(-14.8629, 13.3826), float2(-11.7557, 16.1803), float2(-8.1347, 18.2709), float2(-4.1582, 19.563) };
    
	float2 TEXEL_SIZE = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 step_length = TEXEL_SIZE * size * size_compensation;

	static const float MAX_VARIANCE = 0.1;
	float2 variance = pUtils::FrameCount * float2(sin(2000.0 * PI * texcoord.x), cos(2000.0 * PI * texcoord.y)) * 1000.0;
	variance %= MAX_VARIANCE;
	variance = 1.0 + variance - MAX_VARIANCE * 0.5;

	float3 color;
	[branch]
	if (sample_linear)
	{
		color = SampleLinear(texcoord, true);
		[unroll]
		for (int i = 0; i < samples; ++i)
		{
			color += SampleLinear(texcoord + step_length * OFFSET[i] * variance, true);
		}
	}
	else
	{
		color = tex2D(s, texcoord).rgb;
		[unroll]
		for (int i = 0; i < samples; ++i)
		{
			color += tex2D(s, texcoord + step_length * OFFSET[i] * variance).rgb;
		}
	}

	return color * brightness_compensation;
}

float4 KawaseBlurDownSample(sampler s, float2 texcoord)
{
    float2 HALF_TEXEL = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * 0.5;

    float2 DirDiag1 = float2(-HALF_TEXEL.x,  HALF_TEXEL.y); // Top left
    float2 DirDiag2 = float2( HALF_TEXEL.x,  HALF_TEXEL.y); // Top right
    float2 DirDiag3 = float2( HALF_TEXEL.x, -HALF_TEXEL.y); // Bottom right
    float2 DirDiag4 = float2(-HALF_TEXEL.x, -HALF_TEXEL.y); // Bottom left

    float4 color = tex2D(s, texcoord) * 4.0;
    color += tex2D(s, texcoord + DirDiag1);
    color += tex2D(s, texcoord + DirDiag2);
    color += tex2D(s, texcoord + DirDiag3);
    color += tex2D(s, texcoord + DirDiag4);

    return color * 0.125;
}
float4 KawaseBlurUpSample(sampler s, float2 texcoord)
{
    float2 HALF_TEXEL = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * 0.5;

    float2 DirDiag1 = float2(-HALF_TEXEL.x,  HALF_TEXEL.y); // Top left
    float2 DirDiag2 = float2( HALF_TEXEL.x,  HALF_TEXEL.y); // Top right
    float2 DirDiag3 = float2( HALF_TEXEL.x, -HALF_TEXEL.y); // Bottom right
    float2 DirDiag4 = float2(-HALF_TEXEL.x, -HALF_TEXEL.y); // Bottom left
    float2 DirAxis1 = float2(-HALF_TEXEL.x,  0.0);          // Left
    float2 DirAxis2 = float2( HALF_TEXEL.x,  0.0);          // Right
    float2 DirAxis3 = float2(0.0,  HALF_TEXEL.y);           // Top
    float2 DirAxis4 = float2(0.0, -HALF_TEXEL.y);           // Bottom

    float4 color = 0.0;
    color += tex2D(s, texcoord + DirDiag1);
    color += tex2D(s, texcoord + DirDiag2);
    color += tex2D(s, texcoord + DirDiag3);
    color += tex2D(s, texcoord + DirDiag4);

    color += tex2D(s, texcoord + DirAxis1) * 2.0;
    color += tex2D(s, texcoord + DirAxis2) * 2.0;
    color += tex2D(s, texcoord + DirAxis3) * 2.0;
    color += tex2D(s, texcoord + DirAxis4) * 2.0;

    return color / 12.0;
}

float4 HQDownSample(sampler s, float2 texcoord)
{
	float2 TEXEL_SIZE = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

	static const float2 OFFSET[13] = { float2(-1.0, 1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, -1.0),
	                                   float2(-2.0, 2.0), float2(0.0, 2.0), float2(2.0, 2.0),
									   float2(-2.0, 0.0), float2(0.0, 0.0), float2(2.0, 0.0),
									   float2(-2.0, -2.0), float2(0.0, -2.0), float2(2.0, -1.0) };
	static const float WEIGHT[13] = { 0.125, 0.125, 0.125, 0.125,
	                                  0.03125, 0.0625, 0.03125,
									  0.0625, 0.125, 0.0625,
									  0.03125, 0.0625, 0.03125 };

	float4 color;
	[unroll]
	for (int i = 0; i < 13; ++i)
	{
		color += tex2D(s, texcoord + OFFSET[i] * TEXEL_SIZE) * WEIGHT[i];
	}
	return color;
}
float4 HQDownSampleKA(sampler s, float2 texcoord)
{
	float2 TEXEL_SIZE = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	
	static const float2 OFFSET[13] = { float2(-1.0, 1.0), float2(1.0, 1.0), float2(-1.0, -1.0), float2(1.0, -1.0),
	                                   float2(-2.0, 2.0), float2(0.0, 2.0), float2(2.0, 2.0),
									   float2(-2.0, 0.0), float2(0.0, 0.0), float2(2.0, 0.0),
									   float2(-2.0, -2.0), float2(0.0, -2.0), float2(2.0, -1.0) };

	float4 samplecolor[13];
	[unroll]
	for (int i = 0; i < 13; ++i)
	{
		samplecolor[i] = tex2D(s, texcoord + OFFSET[i] * TEXEL_SIZE);
	}

	//Groups
	float4 groups[5];
	groups[0] = 0.125 * (samplecolor[0] + samplecolor[1] + samplecolor[2] + samplecolor[3]);
	groups[1] = 0.03125 * (samplecolor[4] + samplecolor[5] + samplecolor[7] + samplecolor[8]);
	groups[2] = 0.03125 * (samplecolor[5] + samplecolor[6] + samplecolor[8] + samplecolor[9]);
	groups[3] = 0.03125 * (samplecolor[7] + samplecolor[8] + samplecolor[10] + samplecolor[11]);
	groups[4] = 0.03125 * (samplecolor[8] + samplecolor[9] + samplecolor[11] + samplecolor[12]);

	//Karis average
	groups[0] *= KarisAverage(groups[0]);
	groups[1] *= KarisAverage(groups[1]);
	groups[2] *= KarisAverage(groups[2]);
	groups[3] *= KarisAverage(groups[3]);
	groups[4] *= KarisAverage(groups[4]);

	return groups[0] + groups[1] + groups[2] + groups[3] + groups[4];
}

float4 HQUpSample(sampler s, float2 texcoord, float radius)
{
	float2 TEXEL_SIZE = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

	static const float2 OFFSET[9] = { float2(-1.0, 1.0), float2(0.0, 1.0), float2(1.0, 1.0),
	                                  float2(-1.0, 0.0), float2(0.0, 0.0), float2(1.0, 0.0),
									  float2(-1.0, -1.0), float2(0.0, -1.0), float2(1.0, -1.0) };
	static const float WEIGHT[9] = { 0.0625, 0.125, 0.0625,
	                                 0.125, 0.25, 0.125,
									 0.0625, 0.125, 0.0625 };

	float4 color;
	[unroll]
	for (int i = 0; i < 9; ++i)
	{
		color += tex2D(s, texcoord + OFFSET[i] * TEXEL_SIZE * radius) * WEIGHT[i];
	}
	return color;
}


//Vertex shaders
struct vs2ps
{
	float4 vpos : SV_Position;
	float4 texcoord : TexCoord;
};

vs2ps vs_basic(const uint id)
{
	vs2ps o;
	o.texcoord.x = (id == 2) ? 2.0 : 0.0;
	o.texcoord.y = (id == 1) ? 2.0 : 0.0;
	o.vpos = float4(o.texcoord.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	return o;
}

vs2ps VS_Storage(uint id : SV_VertexID)
{
	vs2ps o = vs_basic(id);
	if ((UseDOFAF && UseDOF) || UseAE)
	{
		o.texcoord.w = ReShade::GetLinearizedDepth(float2(DOFFocusPx, DOFFocusPy));
	}
	else
	{
		o.vpos.xy = 0.0;
	}
	return o;
}

vs2ps VS_Blur(uint id : SV_VertexID)
{
	vs2ps o = vs_basic(id);
	if (BlurStrength == 0.0)
	{
		o.vpos.xy = 0.0;
	}
	return o;
}

vs2ps VS_DOF(uint id : SV_VertexID)
{
	vs2ps o = vs_basic(id);
	if (UseDOF)
	{
		float depth = (UseDOFAF) ? tex2Dfetch(spStorageTex, 0, 0).x : DOFManualFocusDist;
		float scale = ((float(DOFFocalLength*DOFFocalLength) / 10000.0) * float(DOF_SENSOR_SIZE) / 18.0) / ((1.0 + depth*depth) * DOFAperture) * length(float2(BUFFER_WIDTH, BUFFER_HEIGHT))/2048.0;
		o.texcoord.z = depth;
		o.texcoord.w = scale;
	}
	else
	{
		o.vpos.xy = 0.0;
	}
	return o;
}

vs2ps VS_Bloom(uint id : SV_VertexID)
{   
	vs2ps o = vs_basic(id);
	if (BloomStrength == 0.0 && DirtStrength == 0.0)
	{
		o.vpos.xy = 0.0;
	}
	return o;
}

vs2ps VS_BloomLF(uint id : SV_VertexID)
{   
	vs2ps o = vs_basic(id);
	if (BloomStrength == 0.0 && DirtStrength == 0.0 && (!UseLF || ((LFStrength == 0.0 || (GhostStrength == 0.0 && HaloStrength == 0.0)) && GlareStrength == 0.0)))
	{
		o.vpos.xy = 0.0;
	}
	return o;
}

vs2ps VS_Ghosts(uint id : SV_VertexID)
{   
	vs2ps o = vs_basic(id);
	if (!UseLF || ((LFStrength == 0.0 || (GhostStrength == 0.0 && HaloStrength == 0.0)) && GlareStrength == 0.0))
	{
		o.vpos.xy = 0.0;
	}
	return o;
}

vs2ps VS_Glare(uint id : SV_VertexID)
{   
	vs2ps o = vs_basic(id);
	if (!UseLF || GlareStrength == 0.0)
	{
		o.vpos.xy = 0.0;
	}
	else
	{
		o.texcoord.z = 4.0 * GlareStrength * (0.4 * GlareQuality + 1.0);
	}
	return o;
}

vs2ps VS_Camera(uint id : SV_VertexID)
{
	vs2ps o = vs_basic(id);
	float exposure;
	switch (AEMetering)
	{
		case 0: //Matrix metering
		{
			float s;
			float2 OFFSET[9] = { float2(0.5, 0.5), float2(0.15, 0.15), float2(0.25, 0.5), float2(0.15, 0.85), float2(0.5, 0.25), float2(0.5, 0.75), float2(0.85, 0.15), float2(0.75, 0.5), float2(0.85, 0.85) };
			float WEIGHT[9] = { 0.25, 0.0625, 0.125, 0.0625, 0.125, 0.125, 0.0625, 0.125, 0.0625 };

			[unroll]
			for (int i = 0; i < 9; ++i)
			{
				s = tex2Dlod(spStorageTex, float4(OFFSET[i], 0.0, STORAGE_TEX_MIPLEVELS - 1)).y;

				exposure += ((s > AETarget) ? AEHighlightSensitivity * (s - AETarget * (1.0 - rcp(AEHighlightSensitivity))) : s) * WEIGHT[i];
			}
		} break;
		case 1: //Spot metering
		{
			exposure = tex2Dlod(spStorageTex, float4(AEPx, AEPy, 0.0, STORAGE_TEX_MIPLEVELS - 1)).y;
		} break;
	}
	o.texcoord.z = exposure;
	return o;
}


////Passes
float2 StoragePass(vs2ps o) : COLOR
{
	float2 data = tex2D(spStorageTexC, o.texcoord.xy).xy;
	//Sample DOF
	data.x = lerp(data.x, o.texcoord.w, min(pUtils::FrameTime / (DOFFocusSpeed * 500.0 + EPSILON), 1.0));

	//Sample AE
	data.y = lerp(data.y, max(Oklab::get_Adapted_Luminance_RGB(SampleLinear(o.texcoord.xy).rgb, AE_RANGE), AE_MIN_BRIGHTNESS), min(pUtils::FrameTime / (AESpeed * 1000.0 + EPSILON), 1.0));
	return data.xy;
}
float2 StoragePassC(float4 vpos : SV_Position, float2 texcoord : TexCoord) : COLOR
{
	return tex2D(spStorageTex, texcoord).xy;
}

//Blur
float3 GaussianBlurPass1(vs2ps o) : COLOR
{
	return GaussianBlur(spBumpTex, o.texcoord.xy, BlurStrength, float2(1.0, 0.0), true, GaussianQuality).rgb;
}
float3 GaussianBlurPass2(vs2ps o) : COLOR
{
	return GaussianBlur(spBokehBlurTex, o.texcoord.xy, BlurStrength, float2(0.0, 1.0), false, GaussianQuality).rgb;
}

//DOF
float4 BokehBlurPass(vs2ps o) : COLOR
{
	float size = abs(ReShade::GetLinearizedDepth(o.texcoord.xy) - o.texcoord.z) * o.texcoord.w;
	float4 color;
	color.rgb = (BlurStrength != 0.0) ? BokehBlur(spGaussianBlurTex, o.texcoord.xy, size, false) : BokehBlur(spBumpTex, o.texcoord.xy, size, true);
	color.a = size;
    
	return color;
}

//Bloom
float4 HighPassFilter(vs2ps o) : COLOR
{
	float3 color = (UseDOF) ? tex2D(spBokehBlurTex, o.texcoord.xy).rgb : (BlurStrength == 0.0) ? SampleLinear(o.texcoord.xy, true).rgb : tex2D(spGaussianBlurTex, o.texcoord.xy).rgb;
	float adapted_luminance = Oklab::get_Adapted_Luminance_RGB(RedoTonemap(color), 1.0);

	float mask = pow(abs(Oklab::get_Adapted_Luminance_RGB(color, Oklab::INVNORM_FACTOR) / (1.0 + Oklab::INVNORM_FACTOR)), LensFlareCurve*LensFlareCurve + EPSILON);

	color *= pow(abs(adapted_luminance), BloomCurve*BloomCurve);
	return float4(color, mask);
}
//Downsample
float4 BloomDownS1(vs2ps o) : COLOR
{
	return HQDownSampleKA(spBloomTex0, o.texcoord.xy);
}
float4 BloomDownS2(vs2ps o) : COLOR
{
	return HQDownSample(spBloomTex1, o.texcoord.xy);
}
float4 BloomDownS3(vs2ps o) : COLOR
{
	return HQDownSample(spBloomTex2, o.texcoord.xy);
}
float4 BloomDownS4(vs2ps o) : COLOR
{
	return HQDownSample(spBloomTex3, o.texcoord.xy);
}
float4 BloomDownS5(vs2ps o) : COLOR
{
	return HQDownSample(spBloomTex4, o.texcoord.xy);
}
float4 BloomDownS6(vs2ps o) : COLOR
{
	return HQDownSample(spBloomTex5, o.texcoord.xy);
}
float4 BloomDownS7(vs2ps o) : COLOR
{
	return HQDownSample(spBloomTex6, o.texcoord.xy);
}
float4 BloomDownS8(vs2ps o) : COLOR
{
	return HQDownSample(spBloomTex7, o.texcoord.xy);
}
//Upsample
float4 BloomUpS7(vs2ps o) : COLOR
{
	return BloomRadius * HQUpSample(spBloomTex8, o.texcoord.xy, BloomRadius);
}
float4 BloomUpS6(vs2ps o) : COLOR
{
	return BloomRadius * HQUpSample(spBloomTex7, o.texcoord.xy, BloomRadius);
}
float4 BloomUpS5(vs2ps o) : COLOR
{
	return BloomRadius * HQUpSample(spBloomTex6, o.texcoord.xy, BloomRadius);
}
float4 BloomUpS4(vs2ps o) : COLOR
{
	return BloomRadius * HQUpSample(spBloomTex5, o.texcoord.xy, BloomRadius);
}
float4 BloomUpS3(vs2ps o) : COLOR
{
	return BloomRadius * HQUpSample(spBloomTex4, o.texcoord.xy, BloomRadius);
}
float4 BloomUpS2(vs2ps o) : COLOR
{
	return BloomRadius * HQUpSample(spBloomTex3, o.texcoord.xy, BloomRadius);
}
float4 BloomUpS1(vs2ps o) : COLOR
{
	return BloomRadius * HQUpSample(spBloomTex2, o.texcoord.xy, BloomRadius);
}
float4 BloomUpS0(vs2ps o) : COLOR
{
	float4 color = BloomRadius * HQUpSample(spBloomTex1, o.texcoord.xy, BloomRadius);
	color.rgb = RedoTonemap(color.rgb);

	if (BloomGamma != 1.0)
	{
		color.rgb *= pow(abs(Oklab::get_Luminance_RGB(color.rgb / Oklab::INVNORM_FACTOR)), BloomGamma);
	}
	return color;
}

//Lens Flare
//Downsample
float4 FlareDownS2(vs2ps o) : COLOR
{
	return KawaseBlurDownSample(spFlareTex, o.texcoord.xy);
}
float4 FlareDownS3(vs2ps o) : COLOR
{
	return KawaseBlurDownSample(spBloomTex2, o.texcoord.xy);
}
float4 FlareDownS4(vs2ps o) : COLOR
{
	return KawaseBlurDownSample(spBloomTex3, o.texcoord.xy);
}
float4 FlareDownS5(vs2ps o) : COLOR
{
	return KawaseBlurDownSample(spBloomTex4, o.texcoord.xy);
}
//Upsample
float4 FlareUpS4(vs2ps o) : COLOR
{
	return KawaseBlurUpSample(spBloomTex5, o.texcoord.xy);
}
float4 FlareUpS3(vs2ps o) : COLOR
{
	return KawaseBlurUpSample(spBloomTex4, o.texcoord.xy);
}
float4 FlareUpS2(vs2ps o) : COLOR
{
	return KawaseBlurUpSample(spBloomTex3, o.texcoord.xy);
}
float4 FlareUpS1(vs2ps o) : COLOR
{
	return KawaseBlurUpSample(spBloomTex2, o.texcoord.xy);
}

float4 CAPass(vs2ps o) : COLOR
{
	return SampleCA(spBloomTex1, o.texcoord.xy, LensFlareCA);
}
float3 GhostsPass(vs2ps o) : COLOR
{
	float weight;
	float4 s = 0.0;
	float3 color = 0.0;

	float2 texcoord_clean = o.texcoord.xy;
	o.texcoord.xy = FishEye(texcoord_clean, FEFoV, FECrop);
	
	//Fisheye
	float2 radiant_vector;
	float2 halo_vector;
	if (UseFE)
	{
		radiant_vector = o.texcoord.xy - 0.5;
		halo_vector = texcoord_clean;
	}
	else
	{
		radiant_vector = texcoord_clean - 0.5;
		halo_vector = o.texcoord.xy;
	}

	//Ghosts
	[branch]
	if (GhostStrength != 0.0)
	{
		//Taken from https://www.froyok.fr/blog/2021-09-ue4-custom-lens-flare/
    	for(int i = 0; i < 8; i++)
    	{
			//Ghost settings
			#if ENABLE_ADVANCED_LENS_FLARE_SETTINGS
				static const float4 GHOST_COLORS[8] = { GColor1, GColor2, GColor3, GColor4, GColor5, GColor6, GColor7, GColor8 };
				static const float GHOST_SCALES[8] = { GSize1, GSize2, GSize3, GSize4, GSize5, GSize6, GSize7, GSize8 };
			#else
				static const float4 GHOST_COLORS[8] = { float4(1.0, 0.8, 0.4, 1.0), float4(1.0, 1.0, 0.6, 1.0), float4(0.8, 0.8, 1.0, 1.0), float4(0.5, 1.0, 0.4, 1.0), float4(0.5, 0.8, 1.0, 1.0), float4(0.9, 1.0, 0.8, 1.0), float4(1.0, 0.8, 0.4, 1.0), float4(0.9, 0.7, 0.7, 1.0) };
				static const float GHOST_SCALES[8] = { -1.5, 2.5, -5.0, 10.0, 0.7, -0.4, -0.2, -0.1 };
			#endif

			//Apply ghosts
        	if(abs(GHOST_COLORS[i].a * GHOST_SCALES[i]) > 0.0001)
        	{
            	float2 ghost_vector = radiant_vector * GHOST_SCALES[i];

            	//Local mask
				float distance_mask = 1.0 - length(ghost_vector);
				if (GLocalMask)
				{
            		float mask1 = smoothstep(0.5, 0.9, distance_mask);
            		float mask2 = smoothstep(0.75, 1.0, distance_mask) * 0.95 + 0.05;
					weight = mask1 * mask2;
				}
				else
				{
					weight = distance_mask;
				}

				float4 s = tex2D(spFlareSrcTex, ghost_vector + 0.5);
            	color += s.rgb * s.a * GHOST_COLORS[i].rgb * GHOST_COLORS[i].a * weight;
        	}
    	}

		//Screen border mask
		static const float SBMASK_SIZE = 0.9;
		float sb_mask = clamp(length(float2(abs(SBMASK_SIZE * texcoord_clean.x - 0.5), abs(SBMASK_SIZE * texcoord_clean.y - 0.5))), 0.0, 1.0);

    	color *= sb_mask * (GhostStrength*GhostStrength);
	}

	//Halo
	if (HaloStrength != 0.0)
	{
		halo_vector -= normalize(radiant_vector) * HaloRadius;
		weight = 1.0 - min(rcp(HaloWidth + EPSILON) * length(0.5 - halo_vector), 1.0);
		weight = pow(abs(weight), 5.0);

		s = SampleCA(spFlareSrcTex, halo_vector, 8.0 * LensFlareCA);
		color += s.rgb * s.a * weight * (HaloStrength*HaloStrength);
	}

	return color * (LFStrength*LFStrength);
}
float3 GlarePass(vs2ps o) : COLOR
{
	float2 radiant_vector = o.texcoord.xy - 0.5;

	float2 d_vertical = float2(0.1, 1.0) - 0.5 * radiant_vector;
	float2 d_horizontal = float2(1.0, -0.3) + 0.5 * radiant_vector;
	d_vertical /= length(d_vertical);
	d_horizontal /= length(d_horizontal);

	float4 s_vertical = GaussianBlur(spBloomTex1, o.texcoord.xy, o.texcoord.z, d_vertical, false, GlareQuality);
	float4 s_horizontal = GaussianBlur(spBloomTex1, o.texcoord.xy, o.texcoord.z, d_horizontal, false, GlareQuality);

	return (s_vertical.rgb * s_vertical.a + s_horizontal.rgb * s_horizontal.a) * (GlareStrength * GlareStrength) / (0.5 * GlareQuality + 1.0);
}

float3 CameraPass(vs2ps o) : SV_Target
{
	static const float INVNORM_FACTOR = Oklab::INVNORM_FACTOR;
	static const float2 TEXEL_SIZE = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
	float2 texcoord = o.texcoord.xy; //TODO: Replace texcoord with o.texcoord
	float2 radiant_vector = texcoord.xy - 0.5;
	float2 texcoord_clean = texcoord.xy;
	
	////Effects
	//Fisheye
	if (UseFE)
	{
		texcoord.xy = FishEye(texcoord_clean, FEFoV, FECrop);
	}

	//Glass imperfections
	[branch]
	if (GeoIStrength != 0.0)
	{
		float2 bump = 0.6666667 * tex2D(spBumpTex, texcoord * _BUMP_MAP_SCALE).xy + 0.33333334 * tex2D(spBumpTex, texcoord * _BUMP_MAP_SCALE * 3.0).xy;
    
		bump = bump * 2.0 - 1.0;
		texcoord += bump * TEXEL_SIZE * (GeoIStrength * GeoIStrength);
	}
	float3 color = SampleLinear(texcoord).rgb;
    
	//Blur
	float blur_mix = min((4 - GaussianQuality) * BlurStrength, 1.0);
	if (BlurStrength != 0.0)
	{
		color = lerp(color, RedoTonemap(tex2D(spGaussianBlurTex, texcoord).rgb), blur_mix);
	}

	//DOF
	if (UseDOF)
	{
		float4 dof_data = tex2D(spBokehBlurTex, texcoord);
		float dof_mix = min(10.0 * dof_data.a, 1.0);
		color = lerp(color, RedoTonemap(dof_data.rgb), dof_mix);
	}

	//Chromatic aberration
	[branch]
	if (CAStrength != 0.0)
	{
		float3 influence = float3(-0.04, 0.0, 0.03);

		float2 step_length = CAStrength * radiant_vector;
		color.r = (UseDOF) ? RedoTonemap(tex2D(spBokehBlurTex, texcoord + step_length * influence.r).rgb).r : lerp(SampleLinear(texcoord + step_length * influence.r).r, RedoTonemap(tex2D(spGaussianBlurTex, texcoord + step_length * influence.r).rgb).r, blur_mix);
		color.b = (UseDOF) ? RedoTonemap(tex2D(spBokehBlurTex, texcoord + step_length * influence.b).rgb).b : lerp(SampleLinear(texcoord + step_length * influence.b).b, RedoTonemap(tex2D(spGaussianBlurTex, texcoord + step_length * influence.b).rgb).b, blur_mix);
	}

	//Dirt
	[branch]
	if (DirtStrength != 0.0)
	{
		float3 weight = 0.15 * length(radiant_vector) * tex2D(spBloomTex6, -radiant_vector + 0.5).rgb + 0.25 * tex2D(spBloomTex3, texcoord.xy).rgb;
		color += tex2D(spDirtTex, texcoord * float2(1.0, TEXEL_SIZE.x / TEXEL_SIZE.y) * DirtScale).rgb * weight * DirtStrength;
	}

	//Bloom
	if (BloomStrength != 0.0)
	{
		color += (BloomStrength*BloomStrength) * tex2D(spBloomTex0, texcoord).rgb;
	}

	//Lens flare
	if (UseLF && (GlareStrength != 0.0 || (LFStrength != 0.0 && (GhostStrength != 0.0 || HaloStrength != 0.0))))
	{
		color += tex2D(spFlareTex, texcoord).rgb;
	}

	//Vignette
	if (VignetteStrength != 0.0)
	{
		float weight = clamp((length(float2(abs(texcoord_clean.x - 0.5) * rcp(VignetteWidth), abs(texcoord_clean.y - 0.5))) - VignetteInnerRadius) / (VignetteOuterRadius - VignetteInnerRadius), 0.0, 1.0);
		color.rgb *= 1.0 - VignetteStrength * weight;
	}

	//Noise
	[branch]
	if (NoiseStrength != 0.0)
	{
		static const float NOISE_CURVE = max(INVNORM_FACTOR * 0.025, 1.0);
		float luminance = Oklab::get_Luminance_RGB(color);

		//White noise
		float noise1 = pUtils::wnoise(texcoord_clean, float2(6.4949, 39.116));
		float noise2 = pUtils::wnoise(texcoord_clean, float2(19.673, 5.5675));
		float noise3 = pUtils::wnoise(texcoord_clean, float2(36.578, 26.118));

		//Box-Muller transform
		float r = sqrt(-2.0 * log(noise1 + EPSILON));
		float theta1 = 2.0 * PI * noise2;
		float theta2 = 2.0 * PI * noise3;

		//Sensor sensitivity to color channels: https://www.1stvision.com/cameras/AVT/dataman/ibis5_a_1300_8.pdf
		float3 gauss_noise = float3(r * cos(theta1) * 1.33, r * sin(theta1) * 1.25, r * cos(theta2) * 2.0);
		gauss_noise = (NoiseType == 0) ? gauss_noise.rrr : gauss_noise;

		float weight = (NoiseStrength * NoiseStrength) * NOISE_CURVE / (luminance * (1.0 + rcp(INVNORM_FACTOR)) + 2.0); //Multiply luminance to simulate a wider dynamic range
		color.rgb = ClipBlacks(color.rgb + gauss_noise * weight);
	}

	//Auto exposure
	if (UseAE && ((AEProtectHighlights && o.texcoord.z > AETarget) || !AEProtectHighlights))
	{
		color *= lerp(1.0, AETarget / o.texcoord.z, AEGain);
	}
    
	//DEBUG stuff
	if (AEDebug)
	{
		if (pow(abs(texcoord_clean.x - AEPx) * BUFFER_ASPECT_RATIO, 2.0) + pow(abs(texcoord_clean.y - AEPy), 2.0) < 0.001)
		{
			color.rgb = float3(0.0, 0.0, 1.0) * INVNORM_FACTOR;
		}
	}
	if (DOFDebug)
	{
		if (pow(abs(texcoord_clean.x - DOFFocusPx) * BUFFER_ASPECT_RATIO, 2.0) + pow(abs(texcoord_clean.y - DOFFocusPy), 2.0) < 0.0001)
		{
			color.rgb = float3(1.0, 0.0, 0.0) * INVNORM_FACTOR;
		}
	}
	if (VignetteDebug)
	{
		float vignette_distance = length(radiant_vector * float2(rcp(VignetteWidth), 1.0));
		if (abs(vignette_distance - VignetteInnerRadius) < 0.001) //Inner radius
		{
			color.rgb = float3(1.0, 0.0, 0.0) * INVNORM_FACTOR;
		}
		if (abs(vignette_distance - VignetteOuterRadius) < 0.0015) //Outer radius
		{
			color.rgb = float3(1.0, 0.0, 0.0) * INVNORM_FACTOR;
		}
	}

	if (!Oklab::IS_HDR) { color = Oklab::Saturate_RGB(color); }
	color = (UseApproximateTransforms)
		? Oklab::Fast_Linear_to_DisplayFormat(color)
		: Oklab::Linear_to_DisplayFormat(color);
	return color.rgb;
}

technique Camera <ui_tooltip = 
"A high performance all-in-one shader with many common camera and lens effects.\n\n"
"(HDR compatible)";>
{
	pass
	{
		VertexShader = VS_Storage; PixelShader = StoragePass; RenderTarget = pStorageTex;
	}
	pass
	{
		VertexShader = PostProcessVS; PixelShader = StoragePassC; RenderTarget = pStorageTexC;
	}


	pass
	{
		VertexShader = VS_Blur; PixelShader = GaussianBlurPass1; RenderTarget = pBokehBlurTex;
	}
	pass
	{
		VertexShader = VS_Blur; PixelShader = GaussianBlurPass2; RenderTarget = pGaussianBlurTex;
	}


	pass
	{
		VertexShader = VS_DOF; PixelShader = BokehBlurPass; RenderTarget = pBokehBlurTex;
	}


	pass
	{
		VertexShader = VS_BloomLF; PixelShader = HighPassFilter; RenderTarget = pBloomTex0;
	}
    
	//Bloom downsample and upsample passes
	#define BLOOM_DOWN_PASS(i) pass { VertexShader = VS_Bloom; PixelShader = BloomDownS##i; RenderTarget = pBloomTex##i; }
	#define BLOOM_UP_PASS(i) pass { VertexShader = VS_Bloom; PixelShader = BloomUpS##i; RenderTarget = pBloomTex##i; ClearRenderTargets = FALSE; BlendEnable = TRUE; BlendOp = 1; SrcBlend = 1; DestBlend = 9; }

	pass
	{
		VertexShader = VS_BloomLF; PixelShader = BloomDownS1; RenderTarget = pBloomTex1; 
	}
	
	//Lens flare
	pass
	{
		VertexShader = VS_Ghosts; PixelShader = CAPass; RenderTarget = pFlareSrcTex;
	}
	pass
	{
		VertexShader = VS_Ghosts; PixelShader = GhostsPass; RenderTarget = pFlareTex;
	}

	//Blur lens flare
	#define FLARE_DOWN_PASS(i) pass { VertexShader = VS_Ghosts; PixelShader = FlareDownS##i; RenderTarget = pBloomTex##i; }
	#define FLARE_UP_PASS(i) pass { VertexShader = VS_Ghosts; PixelShader = FlareUpS##i; RenderTarget = pBloomTex##i; }
	#define FLARE_UP_PASS_FINAL(i) pass { VertexShader = VS_Ghosts; PixelShader = FlareUpS##i; RenderTarget = pFlareTex; }

	//Number of blurs dependent on resolution
	FLARE_DOWN_PASS(2)
	#if BUFFER_HEIGHT > 1024
	FLARE_DOWN_PASS(3)
	#if BUFFER_HEIGHT > 2048
	FLARE_DOWN_PASS(4)
	#if BUFFER_HEIGHT > 4096
	FLARE_DOWN_PASS(5)

	FLARE_UP_PASS(4)
	#endif
	FLARE_UP_PASS(3)
	#endif
	FLARE_UP_PASS(2)
	#endif
	FLARE_UP_PASS_FINAL(1)
	
	pass //Glare
	{
		VertexShader = VS_Glare; PixelShader = GlarePass; RenderTarget = pFlareTex; ClearRenderTargets = FALSE; BlendEnable = TRUE; BlendOp = 1; SrcBlend = 1; DestBlend = 9;
	}

	BLOOM_DOWN_PASS(2)
	BLOOM_DOWN_PASS(3)
	BLOOM_DOWN_PASS(4)
	BLOOM_DOWN_PASS(5)
	BLOOM_DOWN_PASS(6)
	BLOOM_DOWN_PASS(7)
	BLOOM_DOWN_PASS(8)

	BLOOM_UP_PASS(7)
	BLOOM_UP_PASS(6)
	BLOOM_UP_PASS(5)
	BLOOM_UP_PASS(4)
	BLOOM_UP_PASS(3)
	BLOOM_UP_PASS(2)
	BLOOM_UP_PASS(1)
	BLOOM_UP_PASS(0)

    
	pass
	{
		VertexShader = VS_Camera; PixelShader = CameraPass;
	}
}
