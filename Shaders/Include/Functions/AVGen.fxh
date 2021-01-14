#ifndef _AVGEN_FXH_
#define _AVGEN_FXH_
/*
 *  A helper pass for ReShade 4.0 to generate average luma.
 *                                                  by kingeric1992
 *  Usage:
 *      1. include this file into your code.
 *      2. insert the avgen pass into where it'll generate the backbuffer average.
 */

/*************************************************************************
    Example Usage:
 *************************************************************************

    #include "avgen.fxh"
    //...
    float4 myShader(...) : SV_Target {
        //...
        float average = avGen::get();
        //...
    }

    //...
    technique myTechnique {
        pass myPass { ... }

        // insert avgen pass.
        pass myAvg AVGEN_PASS()

        // now the average result will be avaliable for later passes.
        // use avGen::get() to retreive the value in the shader
        pass myOtherPass {...}

        // insert avgen pass again to recalc
        pass myAvg2 AVGEN_PASS()

        // passes with updated average
        pass myOtherPass {...}

        // insert avgen pass with log average
        pass myAvg2 AVGEN_PASS_LOG()

        // now we have log average. use avGen::getLog() to retreive the value instead.
        pass myOtherPass {...}
    }

*************************************************************************/


//courtesy of crosire (this is pow of 2 only)
//https://graphics.stanford.edu/~seander/bithacks.html#IntegerLog
#define CONST_LOG2(v) ( \
    (((v) & 0xAAAAAAAA) != 0) | \
    ((((v) & 0xFFFF0000) != 0) << 4) | \
    ((((v) & 0xFF00FF00) != 0) << 3) | \
    ((((v) & 0xF0F0F0F0) != 0) << 2) | \
    ((((v) & 0xCCCCCCCC) != 0) << 1))

#define BIT2_LOG2(v)  ( (v) | ( (v) >> 1) )
#define BIT4_LOG2(v)  ( BIT2_LOG2(v) | ( BIT2_LOG2(v) >> 2) )
#define BIT8_LOG2(v)  ( BIT4_LOG2(v) | ( BIT4_LOG2(v) >> 4) )
#define BIT16_LOG2(v) ( BIT8_LOG2(v) | ( BIT8_LOG2(v) >> 8) )

namespace avGen {

    #define SIZE_X  ((BIT16_LOG2(BUFFER_WIDTH) >>1)+1)
    #define SIZE_Y  ((BIT16_LOG2(BUFFER_HEIGHT)>>1)+1)

    texture texOrig : COLOR;
    texture texLod {
        Width  = SIZE_X; Height = SIZE_Y;
        MipLevels =
            ( SIZE_X > SIZE_Y) * CONST_LOG2(SIZE_X) +
            ( SIZE_Y >= SIZE_X) * CONST_LOG2(SIZE_Y) - 1 ;
        Format = RGB10A2;// ( 4x2 at 10 )
    };

    sampler sampOrig { Texture = texOrig; };
    sampler sampLod  { Texture = texLod; };

    float3 get() {
        float3 res    = 0;
        int2   lvl    = int2(CONST_LOG2(SIZE_X), CONST_LOG2(SIZE_Y));
        float4 stp    = 0;
               stp.xy = 0.5 / float2(1 << max(lvl.xy-lvl.yx,0));
               stp.zw = stp.x > stp.y ? stp.zy : stp.xw;
               lvl    = int2(min(lvl.x, lvl.y)-1, 1 << abs(lvl.x-lvl.y) );

        [unroll]
        for(int i=0; i < lvl.y; i++)
            res += tex2Dlod(sampLod, float4(stp.xy + stp.zw*2*i,0,lvl.x)).rgb;

        return res/(float)lvl.y;
    }
    float3 getLog() {
        return exp2(get());
    }
    float4 vs_main( uint vid : SV_VertexID, out float2 uv : TEXCOORD0 ) : SV_Position {
        uv = (vid.xx == uint2(2,1))?(float2)2:0;
        return float4(uv.x*2.-1.,1.-uv.y*2.,0,1);
    }
    float4 ps_main( float4 pos: SV_Position, float2 uv: TEXCOORD0 ) : SV_Target {
        return tex2D(sampOrig, uv); //add additional sampling if preferred
    }
    float4 ps_main_log( float4 pos: SV_Position, float2 uv: TEXCOORD0 ) : SV_Target {
        return log2(tex2D(sampOrig, uv)); //log-avg
    }
} //avGen
#define PASS_AVG() \
            pass \
            { \
                VertexShader  = avGen::vs_main; \
                PixelShader   = avGen::ps_main; \
                RenderTarget  = avGen::texLod; \
            }
#define PASS_AVG_LOG() \
            pass \
            { \
                VertexShader = avGen::vs_main; \
                PixelShader  = avGen::ps_main_log; \
                RenderTarget = avGen::texLod; \
            }
#endif
