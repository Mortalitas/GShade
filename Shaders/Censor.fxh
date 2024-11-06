// Made by Marot Satil, seri14, & Uchu Suzume using code from sYNTHwAVE88's Pixelate.fx 1.0 for the GShade ReShade package!
// You can follow me via @MarotSatil on Twitter, but I don't use it all that much.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, the header above it, this list of conditions, and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#define CENSOR_SUMMONING(Censor_Category, Censor_Opacity, Censor_Depth, Censor_Cell_Size, Censor_Smoothness_Average, CENSOR_SCALE, Censor_ScaleX, Censor_ScaleY, Censor_PosX, Censor_PosY, Censor_SnapRotate, Censor_Rotate, Censor_InvertDepth, PS_Censor, CENSOR_NAME) \
uniform float Censor_Opacity < \
	ui_category = Censor_Category; \
	ui_category_closed = true; \
    ui_label = "Opacity"; \
    ui_tooltip = "The transparency of the censor."; \
    ui_type = "slider"; \
    ui_min = 0.0; \
    ui_max = 1.0; \
    ui_step = 0.002; \
> = 1.0; \
\
uniform float Censor_Depth < \
	ui_category = Censor_Category; \
    ui_type = "slider"; \
    ui_min = 0.0; \
    ui_max = 1.0; \
    ui_label = "Depth"; \
> = 0.97; \
\
uniform int Censor_Cell_Size < \
	ui_category = Censor_Category; \
	ui_type		= "slider"; \
	ui_min		= 2; \
	ui_max		= 48; \
	ui_label	= "Cell Size"; \
> = 4; \
\
uniform float Censor_Smoothness_Average < \
	ui_category = Censor_Category; \
	ui_type		= "slider"; \
	ui_min		= 0.0; \
	ui_max		= 1.0; \
	ui_label	= "Smoothness"; \
> = 0.333; \
\
uniform float CENSOR_SCALE < \
	ui_category = Censor_Category; \
    ui_type = "slider"; \
    ui_label = "Scale X & Y"; \
    ui_min = 0.001; ui_max = 5.0; \
    ui_step = 0.001; \
> = 1.001; \
\
uniform float Censor_ScaleX < \
	ui_category = Censor_Category; \
    ui_type = "slider"; \
    ui_label = "Scale X"; \
    ui_min = 0.001; ui_max = 5.0; \
    ui_step = 0.001; \
> = 1.0; \
\
uniform float Censor_ScaleY < \
	ui_category = Censor_Category; \
    ui_type = "slider"; \
    ui_label = "Scale Y"; \
    ui_min = 0.001; ui_max = 5.0; \
    ui_step = 0.001; \
> = 1.0; \
\
uniform float Censor_PosX < \
	ui_category = Censor_Category; \
    ui_type = "slider"; \
    ui_label = "Position X"; \
    ui_min = -2.0; ui_max = 2.0; \
    ui_step = 0.001; \
> = 0.5; \
\
uniform float Censor_PosY < \
	ui_category = Censor_Category; \
    ui_type = "slider"; \
    ui_label = "Position Y"; \
    ui_min = -2.0; ui_max = 2.0; \
    ui_step = 0.001; \
> = 0.5; \
\
uniform int Censor_SnapRotate < \
	ui_category = Censor_Category; \
    ui_type = "combo"; \
	ui_label = "Snap Rotation"; \
    ui_items = "None\0" \
               "90 Degrees\0" \
               "-90 Degrees\0" \
               "180 Degrees\0" \
               "-180 Degrees\0"; \
	ui_tooltip = "Snap rotation to a specific angle."; \
> = false; \
\
uniform float Censor_Rotate < \
	ui_category = Censor_Category; \
    ui_label = "Rotate"; \
    ui_type = "slider"; \
    ui_min = -180.0; \
    ui_max = 180.0; \
    ui_step = 0.01; \
> = 0; \
\
uniform bool Censor_InvertDepth < \
	ui_category = Censor_Category; \
	ui_label = "Invert Depth"; \
	ui_tooltip = "Inverts the depth buffer so that the censor is applied to the foreground instead."; \
> = false; \
\
void PS_Censor(in float4 position : SV_Position, in float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) \
{ \
	const float depth = Censor_InvertDepth ? ReShade::GetLinearizedDepth(texCoord).r : 1 - ReShade::GetLinearizedDepth(texCoord).r; \
\
    if (depth < Censor_Depth) \
    { \
        const float3 backColor = tex2D(ReShade::BackBuffer, texCoord).rgb; \
        const float3 pivot = float3(0.5, 0.5, 0.0); \
        const float3 mulUV = float3(texCoord.x, texCoord.y, 1); \
		const float2 ScaleSize = (float2(BUFFER_WIDTH, BUFFER_HEIGHT) * CENSOR_SCALE); \
		const float ScaleX =  ScaleSize.x * Censor_ScaleX; \
		const float ScaleY =  ScaleSize.y * Censor_ScaleY; \
        float Rotate = Censor_Rotate * (3.1415926 / 180.0); \
		const int2 pixcoord = floor((BUFFER_SCREEN_SIZE * texCoord) / Censor_Cell_Size) * Censor_Cell_Size; \
\
		passColor = tex2D(ReShade::BackBuffer, ((pixcoord) + 0.5) * BUFFER_PIXEL_SIZE); \
\
		if(Censor_Smoothness_Average > 0.1) \
		{ \
			const float step = Censor_Cell_Size * 0.25; \
			float4 avg_color = 0.0; \
\
			[unroll] \
			for( int x = 0 ; x < 4 ; ++x ) \
				[unroll] \
				for( int y = 0 ; y < 4 ; ++y ) \
					avg_color += tex2Dlod(ReShade::BackBuffer, float4((float2(pixcoord.x + (x * step), pixcoord.y + (y * step)) + 0.5) * BUFFER_PIXEL_SIZE, 0.0, 0.0)); \
\
			avg_color *= 0.0625; \
			passColor = (avg_color * Censor_Smoothness_Average) + (passColor * (1.0 - Censor_Smoothness_Average)); \
		} \
\
        switch(Censor_SnapRotate) \
        { \
            default: \
                break; \
            case 1: \
                Rotate = -90.0 * (3.1415926 / 180.0); \
                break; \
            case 2: \
                Rotate = 90.0 * (3.1415926 / 180.0); \
                break; \
            case 3: \
                Rotate = 0.0; \
                break; \
            case 4: \
                Rotate = 180.0 * (3.1415926 / 180.0); \
                break; \
        } \
\
        const float3x3 positionMatrix = float3x3 ( \
            1, 0, 0, \
            0, 1, 0, \
            -Censor_PosX, -Censor_PosY, 1 \
        ); \
        const float3x3 scaleMatrix = float3x3 ( \
            1/ScaleX, 0, 0, \
            0,  1/ScaleY, 0, \
            0, 0, 1 \
        ); \
        const float3x3 rotateMatrix = float3x3 ( \
            cos (Rotate), sin(Rotate), 0, \
            -sin(Rotate), cos(Rotate), 0, \
            0, 0, 1 \
        ); \
\
        const float3 SumUV = mul (mul (mul (mulUV, positionMatrix) * float3(BUFFER_SCREEN_SIZE, 1.0), rotateMatrix), scaleMatrix); \
\
		passColor *= all(SumUV + pivot == saturate(SumUV + pivot)); \
\
		passColor.rgb = lerp(backColor, passColor.rgb, passColor.a * Censor_Opacity); \
    } \
	else \
	{ \
		passColor = tex2D(ReShade::BackBuffer, texCoord); \
	} \
} \
\
technique CENSOR_NAME \
{ \
    pass \
    { \
        VertexShader = PostProcessVS; \
        PixelShader = PS_Censor; \
    } \
} \