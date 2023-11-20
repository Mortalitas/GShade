//Dynamic Raindrops written by Ehsan2077 aka. NiceGuy for ReShade.
//Version: 1.0.0
//License: CC0

//todo:
//1- [v]brightness of raindrops based on a blurred backbuffer luminance
//2- [ ]raindrops blurring the image a little bit
//3- [ ]fade speed dependent on time rather than frame count

///////////////Include/////////////////////

#include "ReShade.fxh"
uniform int rand < source = "random"; min = 0; max = 1; >;
uniform int Frame < source = "framecount"; >;
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
#define PI 3.1415926535

///////////////Include/////////////////////
///////////////UI//////////////////////////

static const float2 shapeList[10] =
{
	float2(7,6),
	float2(1,7),
	float2(5,1),
	float2(9,1),
	float2(2,0),
	float2(3,0),
	float2(0,1),
	float2(0,1),
	float2(2,4),
	float2(3,4)
};

uniform int bokehShape <
	ui_type  = "combo";
	ui_label = "Bokeh Shape";
	ui_items = "pentagon\0pentagon CA\0hexagon\0hexagon CA\0heptagon\0heptagon CA\0octagon\0octagon CA\0Circle\0Circle CA\0";
> = 1;

uniform float uiscale <
	ui_type  = "slider";
	ui_label = "Bokeh Size";
	ui_tooltip = "The size will be further modified\n"
	             "by a random value per raindrop.";
> = 1;

uniform float BokehBrightness <
	ui_type  = "slider";
	ui_label = "Bokeh Brightness";
> = 0.5;

uniform float fadeSpeed <
	ui_type  = "slider";
	ui_label = "Raindrop Presistence";
	ui_tooltip = "Lower values makes raindrops fade sooner.\n"
	             "If set t one: A thing of beauty, will never fade away :)!";
> = 0.9;

uniform float uicount <
	ui_type  = "slider";
	ui_label = "Spawn Rate";
	ui_tooltip = "The probability of new raindrops landing\n"
	             "on the camera lense relevant to time.";
	ui_max = 2;
> = 0.15;

///////////////UI//////////////////////////
///////////////Textures-Samplers///////////

//namespace dynamic_raindrops
//{

	texture TexColor : COLOR;
	sampler sTexColor {Texture = TexColor;};

	texture DRD_Tex0 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
	sampler sDRD_Tex0{ Texture = DRD_Tex0; };
	
	texture DRD_Tex1 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
	sampler sDRD_Tex1{ Texture = DRD_Tex1; };
	
	texture DRD_Tex2 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
	sampler sDRD_Tex2{ Texture = DRD_Tex2; };
	
	texture DRD_TexBackBuffer0 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; MipLevels = 5; };
	sampler sDRD_TexBackBuffer0{ Texture = DRD_TexBackBuffer0; };
	
	texture DRD_TexBackBuffer1 { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA16f; };
	sampler sDRD_TexBackBuffer1{ Texture = DRD_TexBackBuffer1; };
	
	texture DRD_TexBackBuffer2 { Width = BUFFER_WIDTH / 8; Height = BUFFER_HEIGHT / 8; Format = RGBA16f; };
	sampler sDRD_TexBackBuffer2{ Texture = DRD_TexBackBuffer2; };
	
    texture DRD_BokehTex <source = "NGbokeh.jpg";> { Width = 683; Height = 1024; Format = RGBA8; MipLevels = 8; };
    sampler sDRD_BokehTex {Texture = DRD_BokehTex; };

///////////////Textures-Samplers///////////
///////////////Functions///////////////////

	float4 SampleTextureCatmullRom9t(in sampler tex, in float4 uv)
	{
		float2 texSize = tex2Dsize(tex);
	    float2 samplePos = uv.xy * texSize;
	    float2 texPos1 = floor(samplePos - 0.5f) + 0.5f;
	
	    float2 f = samplePos - texPos1;
	
	    float2 w0 = f * (-0.5f + f * (1.0f - 0.5f * f));
	    float2 w1 = 1.0f + f * f * (-2.5f + 1.5f * f);
	    float2 w2 = f * (0.5f + f * (2.0f - 1.5f * f));
	    float2 w3 = f * f * (-0.5f + 0.5f * f);
	
	    float2 w12 = w1 + w2;
	    float2 offset12 = w2 / (w1 + w2);
	    
	    float2 texPos0 = texPos1 - 1;
	    float2 texPos3 = texPos1 + 2;
	    float2 texPos12 = texPos1 + offset12;
	
	    texPos0 /= texSize;
	    texPos3 /= texSize;
	    texPos12 /= texSize;
	
	    float4 result = 0.0f;
	    result += tex2Dlod(tex, float4(texPos0.x, texPos0.y,0,0)) * w0.x * w0.y;
	    result += tex2Dlod(tex, float4(texPos12.x, texPos0.y,0,0)) * w12.x * w0.y;
	    result += tex2Dlod(tex, float4(texPos3.x, texPos0.y,0,0)) * w3.x * w0.y;
	
	    result += tex2Dlod(tex, float4(texPos0.x, texPos12.y,0,0)) * w0.x * w12.y;
	    result += tex2Dlod(tex, float4(texPos12.x, texPos12.y,0,0)) * w12.x * w12.y;
	    result += tex2Dlod(tex, float4(texPos3.x, texPos12.y,0,0)) * w3.x * w12.y;
	
	    result += tex2Dlod(tex, float4(texPos0.x, texPos3.y,0,0)) * w0.x * w3.y;
	    result += tex2Dlod(tex, float4(texPos12.x, texPos3.y,0,0)) * w12.x * w3.y;
	    result += tex2Dlod(tex, float4(texPos3.x, texPos3.y,0,0)) * w3.x * w3.y;
	
	    return result;
	}

	float lum(in float3 color)
	{
		return dot(color, float3(0.25, 0.5, 0.25));
	}
	
	float4 sampleBokeh(in float2 uv, in float2 pos, in float scale, in float opacity)
	{
		uv -= pos;
		uv *= BUFFER_SCREEN_SIZE;
		
		uv -= 32;
		uv /= scale;
		uv += 32;
		
		bool mask = !(uv.x <= 3 || uv.x >= 61 || uv.y <= 3 || uv.y >= 61);
		
		uv += 64 * shapeList[bokehShape];
		
		uv /= tex2Dsize(sDRD_BokehTex);
		
		float3 color = SampleTextureCatmullRom9t(sDRD_BokehTex, float4(uv,0,0)).rgb;
		
		float  alpha = saturate(lum(color)*10);
		alpha *= alpha; alpha *= alpha; alpha *= alpha; alpha *= mask;
		
        return float4(color * alpha * opacity, alpha * opacity);
    }
    
    float Randt(float2 co)
	{
		co += frac(Frame*0.00116589);
		return frac(sin(dot(co.xy ,float2(1.0,73))) * 437580.5453);
	}
	
	//From fastBlur.fx by Robert Jessop under MIT license with a little customization
	//Copyright © 2023 <copyright holders>
	
	//Permission is hereby granted, free of charge, to any person obtaining a copy of this 
	//software and associated documentation files (the “Software”), to deal in the Software
	//without restriction, including without limitation the rights to use, copy, modify, 
	//merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
	//permit persons to whom the Software is furnished to do so, subject to the following conditions:
	
	//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
	
	//THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	//BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	//NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	//DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	#define FAST_BLUR_SCALE 8
	float4 fastBlur(sampler s, in float2 texcoord, in float2 step)
	{
		step *= FAST_BLUR_SCALE * 1 / BUFFER_SCREEN_SIZE;
		const uint steps=5;
		
		//The numbers are from pascals triange. You could add more steps and/or change the row used to change the shape of the blur. using float4 because for w we want brightness over a larger area - it's basically two different blurs in one.
		const float sum=6+15+20+15+6;
	    const float w = 0.2;
	    float4 color = 0;
			
		float2 offset = -floor(steps / 2) * step;
		for( uint i = 0; i < steps; i++) {
			float4 c = tex2Dlod(s, float4(texcoord + offset, 0, 3));
			offset += step;
			c *= 0.2;
			color += c;
			//sum+=w[i];
		}
		return color;
	}
		
///////////////Functions///////////////////
///////////////Vertex Shader///////////////
///////////////Vertex Shader///////////////
///////////////Pixel Shader////////////////

    struct passInput
    {
        float4 vp : SV_Position;
        float2 uv : TEXCOORD;
    };
    
    void PrePassPS(passInput i, out float4 outColor : SV_Target0)
    {
    	outColor = tex2D(sTexColor, i.uv);
    	outColor /= (1.01 - outColor);
    }
    
    #define halfp (0.5 * FAST_BLUR_SCALE / BUFFER_SCREEN_SIZE)
    float4 Blur0PS(passInput i) : SV_Target0 {return fastBlur(sDRD_TexBackBuffer0, i.uv + halfp, float2( 5, 2));}
	float4 Blur1PS(passInput i) : SV_Target0 {return fastBlur(sDRD_TexBackBuffer1, i.uv + halfp, float2(-2, 5));}
	float4 Blur2PS(passInput i) : SV_Target0 {return fastBlur(sDRD_TexBackBuffer2, i.uv + halfp, float2( 2, 5));}
	float4 Blur3PS(passInput i) : SV_Target0 {return fastBlur(sDRD_TexBackBuffer1, i.uv + halfp, float2(-5, 2));}
	
    void MainPS(passInput i, out float4 outColor : SV_Target0, out float4 outBackBuffer : SV_Target1)
    {
    	float fac = fadeSpeed * 0.1 + 0.9;
        float4 bokehs = tex2D(sDRD_Tex1, i.uv) * fac;
        float4 current = 0;
        
        if(Randt(1.215435) < (uicount))
		{
	        [loop]for(int x; x <= uicount; x++)
	        {
	        	float t = x / float(uicount);
	        	float2 offset = float2(Randt(0.168468 * t + 0.546597), Randt(0.2558479 * t)); 
	        	float scale = Randt(0.3 + t) * uiscale + uiscale;
	        	
	        	current += sampleBokeh(i.uv, offset, scale, 1);
	        }
        }
        
		outColor = bokehs + float4(current.rgb, 1-fac);
		outBackBuffer = tex2D(sTexColor, i.uv);
		
		outBackBuffer = outBackBuffer / (1 - outBackBuffer);
    }
    
    void CopyPS(passInput i, out float4 outData : SV_Target0, out float4 outBackBuffer : SV_Target1)
    {
    	outData = tex2D(sDRD_Tex0, i.uv);
    	outBackBuffer = 1;
    }
    
    float4 OutPS(passInput i) : SV_Target
    {
    	float4 mainColor = tex2D(sTexColor, i.uv);
    	float4 Drops     = tex2D(sDRD_Tex1, i.uv);
    	float4 blurredBackBuffer = tex2D(sDRD_TexBackBuffer2, i.uv);
		float4 HDRBackBuffer = mainColor / (1.01 - mainColor);
		
    	Drops *= BokehBrightness * blurredBackBuffer;
    	Drops += HDRBackBuffer;
    	Drops /= (1.0 + Drops);
    	
    	Drops += frac(sin(dot(i.uv.xy ,float2(1.0,73))) * 437580.5453)/255;
    	
    	return Drops;
    	//return lerp(mainColor, Drops + mainColor, lum(Drops.rgb));
    }

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////

	technique DynamicRaindrops
	<
        ui_label = "NiceGuy RainDrops";
	    ui_tooltip = "||         NiceGuy Raindrops || Version 1.0.0           ||\n"
	                 "||                      By NiceGuy                      ||\n"
		             "||Simulates dynamic raindrops  hitting the camera lense.||";
    >
	{
		pass
		{
			VertexShader = PostProcessVS;
			PixelShader  = PrePassPS;
			RenderTarget = DRD_TexBackBuffer0;
		}
		pass  
		{
	        VertexShader = PostProcessVS;
	        PixelShader  = Blur0PS;
	        RenderTarget = DRD_TexBackBuffer1;
	    }
	    pass 
		{
	        VertexShader = PostProcessVS;
	        PixelShader  = Blur1PS;
	        RenderTarget = DRD_TexBackBuffer2;
	    }
		pass  
		{
	        VertexShader = PostProcessVS;
	        PixelShader  = Blur2PS;
	        RenderTarget = DRD_TexBackBuffer1;
	    }
	    pass
		{
	        VertexShader = PostProcessVS;
	        PixelShader  = Blur3PS;
	        RenderTarget = DRD_TexBackBuffer2;
	    }
		pass
        {
            VertexShader = PostProcessVS;
            PixelShader  = MainPS;
            RenderTarget = DRD_Tex0;
        }
        pass
        {
        	VertexShader = PostProcessVS;
        	PixelShader  = CopyPS;
        	RenderTarget = DRD_Tex1;
        }
        pass
        {
        	VertexShader = PostProcessVS;
        	PixelShader  = OutPS;
        }
    }
//}
