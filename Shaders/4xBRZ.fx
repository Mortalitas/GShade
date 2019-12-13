////////////////////////////////////////////////////////////////////////////////
//
// 4xBRZ filter from (DirectX 9+ & OpenGL)
//
//    https://github.com/libretro/common-shaders/blob/master/xbrz/shaders/4xbrz.cg
//
// Ported by spiderh @2018
//
// NOTE:  Only work with pixelated games.
//
// ----------------------------------------------------------------------------
//
//     Strength = Height / Original Height
//
// Example in Mame, one game's original resolution is  "384 x 214"  then:
//
//     Strength = 1080 / 214 = 4.8214
//
// If you use  "1920 x 1080"  resolution, for most games use  "Strength = 6", 
// If you use  "1280 x 720" then use  "Strength = 4".
//
//
////////////////////////////////////////////////////////////////////////////////
//
// 4xBRZ shader - Copyright (C) 2014-2016 DeSmuME team
//
// This file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with the this software.  If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////
/*
   Hyllian's xBR-vertex code and texel mapping
   
   Copyright (C) 2011/2016 Hyllian - sergiogdb@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is 
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.

*/
////////////////////////////////////////////////////////////////////////////////


uniform float coef <
	ui_type = "slider";
	ui_min = 1.0; ui_max = 10.0;
	ui_label = "Strength";
	ui_tooltip = "Strength of the effect (4 or 6)";
> = 4.0;


#include "ReShade.fxh"


#define BLEND_NONE                      0
#define BLEND_NORMAL                    1
#define BLEND_DOMINANT                  2
#define LUMINANCE_WEIGHT                1.0
#define EQUAL_COLOR_TOLERANCE           30.0 / 255.0
#define STEEP_DIRECTION_THRESHOLD       2.2
#define DOMINANT_DIRECTION_THRESHOLD    3.6


float reduce( const float3 color )
{
  return dot( color, float3(65536.0, 256.0, 1.0) );
}
  
float DistYCbCr( const float3 pixA, const float3 pixB )
{
  const float3 w      = float3( 0.2627, 0.6780, 0.0593 );
  const float  scaleB = 0.5 / (1.0 - w.b);
  const float  scaleR = 0.5 / (1.0 - w.r);
        float3 diff   = pixA - pixB;
        float  Y      = dot(diff, w);
        float  Cb     = scaleB * (diff.b - Y);
        float  Cr     = scaleR * (diff.r - Y);
    
  return sqrt( ((LUMINANCE_WEIGHT * Y) * (LUMINANCE_WEIGHT * Y)) + (Cb * Cb) + (Cr * Cr) );
}
  
bool IsPixEqual( const float3 pixA, const float3 pixB )
{
  return ( DistYCbCr(pixA, pixB) < EQUAL_COLOR_TOLERANCE );
}
  
bool IsBlendingNeeded( const int4 blend )
{
  return any( !(blend == (int4)BLEND_NONE) );
}


// --------------------
// --  MAIN  ----------
// --------------------

// Vertex shader generating a triangle covering the entire screen
void VS_Downscale( in  uint   id       : SV_VertexID,
                   out float4 position : SV_Position,
                   out float2 texcoord : TEXCOORD0 )
{
  if (id == 2)
    texcoord.x = 2.0;
  else
    texcoord.x = 0.0;

  if (id == 1)
    texcoord.y = 2.0;
  else
    texcoord.y = 0.0;

  position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
  
  texcoord *= float2(coef, coef);
}


// Vertex shader generating a triangle covering the entire screen
void VS_XBRZ4X( in  uint   id       : SV_VertexID,
                out float4 position : SV_Position,
                out float2 texcoord : TEXCOORD0,
                out float4 t1       : TEXCOORD1,
                out float4 t2       : TEXCOORD2,
                out float4 t3       : TEXCOORD3,
                out float4 t4       : TEXCOORD4,
                out float4 t5       : TEXCOORD5,
                out float4 t6       : TEXCOORD6,
                out float4 t7       : TEXCOORD7
              )
{
  if (id == 2)
    texcoord.x = 2.0;
  else
    texcoord.x = 0.0;
  
  if (id == 1)
    texcoord.y = 2.0;
  else
    texcoord.y = 0.0;

  position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
   
  float dx = ( 1.0 / BUFFER_WIDTH  );
  float dy = ( 1.0 / BUFFER_HEIGHT );
  
  texcoord /= float2(coef, coef);
  
  //  A1 B1 C1
  //  A0 A  B  C C4
  //  D0 D  E  F F4
  //  G0 G  H  I I4
  //  G5 H5 I5

  t1 = texcoord.xxxy + float4(     -dx,   0, dx, -2.0*dy ); // A1 B1 C1
  t2 = texcoord.xxxy + float4(     -dx,   0, dx,     -dy ); // A B C
  t3 = texcoord.xxxy + float4(     -dx,   0, dx,       0 ); // D E F
  t4 = texcoord.xxxy + float4(     -dx,   0, dx,      dy ); // G H I
  t5 = texcoord.xxxy + float4(     -dx,   0, dx,  2.0*dy ); // G5 H5 I5
  t6 = texcoord.xyyy + float4( -2.0*dx, -dy,  0,      dy ); // A0 D0 G0
  t7 = texcoord.xyyy + float4(  2.0*dx, -dy,  0,      dy ); // C4 F4 I4 
}


//---------------------------------------
// Input Pixel Mapping:  --|21|22|23|--
//                       19|06|07|08|09
//                       18|05|00|01|10
//                       17|04|03|02|11
//                       --|15|14|13|--
//
// Output Pixel Mapping:  06|07|08|09
//                        05|00|01|10
//                        04|03|02|11
//                        15|14|13|12

texture DownscaleTex
{
  Width  = BUFFER_WIDTH;
  Height = BUFFER_HEIGHT;
  Format = RGBA8;
};

texture UpscaleTex
{
  Width  = BUFFER_WIDTH;
  Height = BUFFER_HEIGHT;
  Format = RGBA8;
};

sampler DownscaleSampler
{
  Texture   = DownscaleTex;
  MinFilter = Point;
  MagFilter = Point;
};

sampler UpscaleSampler
{
  Texture   = UpscaleTex;
  MinFilter = Point;
  MagFilter = Point;
};


float3 PS_Downscale( float4 pos : SV_Position,
                     float2 uv  : TexCoord0 ) : COLOR
{ 
  return tex2D(ReShade::BackBuffer, uv).rgb;
}


float3 PS_Final( float4 pos : SV_Position,
                 float2 uv  : TexCoord ) : COLOR
{ 
  return tex2D(UpscaleSampler, uv).rgb;
}


float3 PS_XBRZ4X( float4 pos : SV_Position,
                  float2 uv  : TexCoord0,
                  float4 t1  : TexCoord1,
                  float4 t2  : TexCoord2,
                  float4 t3  : TexCoord3,
                  float4 t4  : TexCoord4,
                  float4 t5  : TexCoord5,
                  float4 t6  : TexCoord6,
                  float4 t7  : TexCoord7
                ) : COLOR
{
  //return tex2D(DownscaleSampler, uv).rgb;
  
  float2 f = frac( uv * float2(BUFFER_WIDTH, BUFFER_HEIGHT) );


  //---------------------------------------
  // Input Pixel Mapping:  20|21|22|23|24
  //                       19|06|07|08|09
  //                       18|05|00|01|10
  //                       17|04|03|02|11
  //                       16|15|14|13|12
  
  float3 src[25];
  
  src[21] = tex2D(DownscaleSampler, t1.xw).rgb;
  src[22] = tex2D(DownscaleSampler, t1.yw).rgb;
  src[23] = tex2D(DownscaleSampler, t1.zw).rgb;
  src[ 6] = tex2D(DownscaleSampler, t2.xw).rgb;
  src[ 7] = tex2D(DownscaleSampler, t2.yw).rgb;
  src[ 8] = tex2D(DownscaleSampler, t2.zw).rgb;
  src[ 5] = tex2D(DownscaleSampler, t3.xw).rgb;
  src[ 0] = tex2D(DownscaleSampler, t3.yw).rgb;
  src[ 1] = tex2D(DownscaleSampler, t3.zw).rgb;
  src[ 4] = tex2D(DownscaleSampler, t4.xw).rgb;
  src[ 3] = tex2D(DownscaleSampler, t4.yw).rgb;
  src[ 2] = tex2D(DownscaleSampler, t4.zw).rgb;
  src[15] = tex2D(DownscaleSampler, t5.xw).rgb;
  src[14] = tex2D(DownscaleSampler, t5.yw).rgb;
  src[13] = tex2D(DownscaleSampler, t5.zw).rgb;
  src[19] = tex2D(DownscaleSampler, t6.xy).rgb;
  src[18] = tex2D(DownscaleSampler, t6.xz).rgb;
  src[17] = tex2D(DownscaleSampler, t6.xw).rgb;
  src[ 9] = tex2D(DownscaleSampler, t7.xy).rgb;
  src[10] = tex2D(DownscaleSampler, t7.xz).rgb;
  src[11] = tex2D(DownscaleSampler, t7.xw).rgb;

  float v[9];
  v[0] = reduce( src[0] );
  v[1] = reduce( src[1] );
  v[2] = reduce( src[2] );
  v[3] = reduce( src[3] );
  v[4] = reduce( src[4] );
  v[5] = reduce( src[5] );
  v[6] = reduce( src[6] );
  v[7] = reduce( src[7] );
  v[8] = reduce( src[8] );
  
  int4 blendResult = (int4)BLEND_NONE;
  
  // Preprocess corners
  // Pixel Tap Mapping: --|--|--|--|--
  //                    --|--|07|08|--
  //                    --|05|00|01|10
  //                    --|04|03|02|11
  //                    --|--|14|13|--
    
  // Corner (1, 1)
  if ( !((v[0] == v[1] && v[3] == v[2]) || (v[0] == v[3] && v[1] == v[2])) )
  {
    float dist_03_01       = DistYCbCr(src[ 4], src[ 0]) + DistYCbCr(src[ 0], src[ 8]) + DistYCbCr(src[14], src[ 2]) +
                             DistYCbCr(src[ 2], src[10]) + (4.0 * DistYCbCr(src[ 3], src[ 1]));
    float dist_00_02       = DistYCbCr(src[ 5], src[ 3]) + DistYCbCr(src[ 3], src[13]) + DistYCbCr(src[ 7], src[ 1]) +
                             DistYCbCr(src[ 1], src[11]) + (4.0 * DistYCbCr(src[ 0], src[ 2]));
    bool  dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_03_01) < dist_00_02;

    if ((dist_03_01 < dist_00_02) && (v[0] != v[1]) && (v[0] != v[3]))
    {
      if (dominantGradient)
      {
        blendResult[2] = BLEND_DOMINANT;
      }
      else
      {
        blendResult[2] = BLEND_NORMAL;
      }
    }
    else
    {
      blendResult[2] = BLEND_NONE;
    }
  }
    
    
  // Pixel Tap Mapping: --|--|--|--|--
  //                    --|06|07|--|--
  //                    18|05|00|01|--
  //                    17|04|03|02|--
  //                    --|15|14|--|--
  // Corner (0, 1)
  if ( !((v[5] == v[0] && v[4] == v[3]) || (v[5] == v[4] && v[0] == v[3])) )
  {
    float dist_04_00       = DistYCbCr(src[17], src[ 5]) + DistYCbCr(src[ 5], src[ 7]) + DistYCbCr(src[15], src[ 3]) +
                             DistYCbCr(src[ 3], src[ 1]) + (4.0 * DistYCbCr(src[ 4], src[ 0]));
    float dist_05_03       = DistYCbCr(src[18], src[ 4]) + DistYCbCr(src[ 4], src[14]) + DistYCbCr(src[ 6], src[ 0]) +
                             DistYCbCr(src[ 0], src[ 2]) + (4.0 * DistYCbCr(src[ 5], src[ 3]));
    bool  dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_05_03) < dist_04_00;
    
//    blendResult[3] = ((dist_04_00 > dist_05_03) && (v[0] != v[5]) && (v[0] != v[3])) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
    if ((dist_04_00 > dist_05_03) && (v[0] != v[5]) && (v[0] != v[3]))
    {
      if (dominantGradient)
      {
        blendResult[3] = BLEND_DOMINANT;
      }
      else
      {
        blendResult[3] = BLEND_NORMAL;
      }
    }
    else
    {
      blendResult[3] = BLEND_NONE;
    }
  }
    
  // Pixel Tap Mapping: --|--|22|23|--
  //                    --|06|07|08|09
  //                    --|05|00|01|10
  //                    --|--|03|02|--
  //                    --|--|--|--|--
  // Corner (1, 0)
  if ( !((v[7] == v[8] && v[0] == v[1]) || (v[7] == v[0] && v[8] == v[1])) )
  {
    float dist_00_08       = DistYCbCr(src[ 5], src[ 7]) + DistYCbCr(src[ 7], src[23]) + DistYCbCr(src[ 3], src[ 1]) +
                             DistYCbCr(src[ 1], src[ 9]) + (4.0 * DistYCbCr(src[ 0], src[ 8]));
    float dist_07_01       = DistYCbCr(src[ 6], src[ 0]) + DistYCbCr(src[ 0], src[ 2]) + DistYCbCr(src[22], src[ 8]) +
                             DistYCbCr(src[ 8], src[10]) + (4.0 * DistYCbCr(src[ 7], src[ 1]));
    bool  dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_07_01) < dist_00_08;

    if ((dist_00_08 > dist_07_01) && (v[0] != v[7]) && (v[0] != v[1]))
    {
      if (dominantGradient)
      {
        blendResult[1] = BLEND_DOMINANT;
      }
      else
      {
        blendResult[1] = BLEND_NORMAL;
      }
    }
    else
    {
      blendResult[1] = BLEND_NONE;
    }
  }
    
  // Pixel Tap Mapping: --|21|22|--|--
  //                    19|06|07|08|--
  //                    18|05|00|01|--
  //                    --|04|03|--|--
  //                    --|--|--|--|--
  // Corner (0, 0)
  if ( !((v[6] == v[7] && v[5] == v[0]) || (v[6] == v[5] && v[7] == v[0])) )
  {
    float dist_05_07       = DistYCbCr(src[18], src[ 6]) + DistYCbCr(src[ 6], src[22]) + DistYCbCr(src[ 4], src[ 0]) +
                             DistYCbCr(src[ 0], src[ 8]) + (4.0 * DistYCbCr(src[ 5], src[ 7]));
    float dist_06_00       = DistYCbCr(src[19], src[ 5]) + DistYCbCr(src[ 5], src[ 3]) + DistYCbCr(src[21], src[ 7]) +
                             DistYCbCr(src[ 7], src[ 1]) + (4.0 * DistYCbCr(src[ 6], src[ 0]));
    bool  dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_05_07) < dist_06_00;

    if ((dist_05_07 < dist_06_00) && (v[0] != v[5]) && (v[0] != v[7]))
    {
      if (dominantGradient)
      {
        blendResult[0] = BLEND_DOMINANT;
      }
      else
      {
        blendResult[0] = BLEND_NORMAL;
      }
    }
    else
    {
      blendResult[0] = BLEND_NONE;
    }
  }
  
  float3 dst[16];
  dst[ 0] = src[0];
  dst[ 1] = src[0];
  dst[ 2] = src[0];
  dst[ 3] = src[0];
  dst[ 4] = src[0];
  dst[ 5] = src[0];
  dst[ 6] = src[0];
  dst[ 7] = src[0];
  dst[ 8] = src[0];
  dst[ 9] = src[0];
  dst[10] = src[0];
  dst[11] = src[0];
  dst[12] = src[0];
  dst[13] = src[0];
  dst[14] = src[0];
  dst[15] = src[0];
  
  // Scale pixel
  if (IsBlendingNeeded(blendResult))
  {
    // --- Quality Level 1 ---
    
    float dist_01_04     = DistYCbCr(src[1], src[4]);
    float dist_03_08     = DistYCbCr(src[3], src[8]);
    bool haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[4]) && (v[5] != v[4]);
    bool haveSteepLine   = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[8]) && (v[7] != v[8]);
    bool needBlend       = (blendResult[2] != BLEND_NONE);
    
    bool doLineBlend = ( blendResult[2] >= BLEND_DOMINANT ||
                         !( (blendResult[1] != BLEND_NONE && !IsPixEqual(src[0], src[4])) ||
                            (blendResult[3] != BLEND_NONE && !IsPixEqual(src[0], src[8])) ||
                            (IsPixEqual(src[4], src[3]) && IsPixEqual(src[3], src[2]) && IsPixEqual(src[2], src[1]) && IsPixEqual(src[1], src[8]) && !IsPixEqual(src[0], src[2]))
                          )
                       );

    float3 blendPix;
    if ( DistYCbCr(src[0], src[1]) <= DistYCbCr(src[0], src[3]) )
      blendPix = src[1];
    else
      blendPix = src[3];

    if (needBlend && doLineBlend)
    {
      if (haveShallowLine)
      {
        if (haveSteepLine)
        {
          dst[2] = lerp( dst[2], blendPix, 1.0/3.0 );
        }
        else
        {
          dst[2] = lerp( dst[2], blendPix, 0.25 );
        }
      }
      else
      {
        if (haveSteepLine)
        {
          dst[2] = lerp( dst[2], blendPix, 0.25 );
        }
        else
        {
          dst[2] = lerp( dst[2], blendPix, 0.0 );
        }
      }
    }
    else
    {
      dst[2] = lerp( dst[2], blendPix, 0.0 );
    }

    if (needBlend && doLineBlend && haveSteepLine)
      dst[9] = lerp( dst[9], blendPix, 0.25 );
    else
      dst[9] = lerp( dst[9], blendPix, 0.00 );

    if (needBlend && doLineBlend && haveSteepLine)
      dst[10] = lerp( dst[10], blendPix, 0.75 );
    else
      dst[10] = lerp( dst[10], blendPix, 0.00 );

    if (needBlend)
    {
      if (doLineBlend)
      {
        if (haveSteepLine)
        {
          dst[11] = lerp( dst[11], blendPix, 1.0);
        }
        else
        {
          if (haveShallowLine)
          {
            dst[11] = lerp( dst[11], blendPix, 0.75);
          }
          else
          {
            dst[11] = lerp( dst[11], blendPix, 0.50);
          }
        }
      }
      else
      {
        dst[11] = lerp( dst[11], blendPix, 0.08677704501);
      }
    }
    else
    {
      dst[11] = lerp( dst[11], blendPix, 0.0);
    }

    if (needBlend)
    {
      if (doLineBlend)
      {
        dst[12] = lerp( dst[12], blendPix, 1.0);
      }
      else
      {
        dst[12] = lerp( dst[12], blendPix, 0.6848532563);
      }
    }
    else
    {
      dst[12] = lerp( dst[12], blendPix, 0.00);
    }

    if (needBlend)
    {
      if (doLineBlend)
      {
        if (haveShallowLine)
        {
          dst[13] = lerp( dst[13], blendPix, 1.0);
        }
        else
        {
          if (haveSteepLine)
          {
            dst[13] = lerp( dst[13], blendPix, 0.75);
          }
          else
          {
            dst[13] = lerp( dst[13], blendPix, 0.50);
          }
        }
      }
      else
      {
        dst[13] = lerp( dst[13], blendPix, 0.08677704501);
      }
    }
    else
    {
      dst[13] = lerp( dst[13], blendPix, 0.0);
    }

  if (needBlend && doLineBlend && haveShallowLine)
    dst[14] = lerp( dst[14], blendPix, 0.75);
  else
    dst[14] = lerp( dst[14], blendPix, 0.00);

  if (needBlend && doLineBlend && haveShallowLine)
    dst[15] = lerp( dst[15], blendPix, 0.25);
  else
    dst[15] = lerp( dst[15], blendPix, 0.00);

    // --- Quality Level 2 ---
    
    dist_01_04      = DistYCbCr(src[7], src[2]);
    dist_03_08      = DistYCbCr(src[1], src[6]);
    haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[2]) && (v[3] != v[2]);
    haveSteepLine   = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[6]) && (v[5] != v[6]);
    needBlend       = (blendResult[1] != BLEND_NONE);
    
    doLineBlend = ( blendResult[1] >= BLEND_DOMINANT ||
                    !( (blendResult[0] != BLEND_NONE && !IsPixEqual(src[0], src[2])) ||
                       (blendResult[2] != BLEND_NONE && !IsPixEqual(src[0], src[6])) ||
                       (IsPixEqual(src[2], src[1]) && IsPixEqual(src[1], src[8]) && IsPixEqual(src[8], src[7]) && IsPixEqual(src[7], src[6]) && !IsPixEqual(src[0], src[8]))
                     )
                  );
    
    blendPix = ( DistYCbCr(src[0], src[7]) <= DistYCbCr(src[0], src[1]) ) ? src[7] : src[1];
    dst[ 1] = lerp( dst[ 1], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0/3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00 );
    dst[ 6] = lerp( dst[ 6], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00 );
    dst[ 7] = lerp( dst[ 7], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00 );
    dst[ 8] = lerp( dst[ 8], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00 );
    dst[ 9] = lerp( dst[ 9], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00 );
    dst[10] = lerp( dst[10], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00 );
    dst[11] = lerp( dst[11], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00 );
    dst[12] = lerp( dst[12], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00 );
    
    
    // --- Quality Level 3 ---
    
    dist_01_04      = DistYCbCr(src[5], src[8]);
    dist_03_08      = DistYCbCr(src[7], src[4]);
    haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[8]) && (v[1] != v[8]);
    haveSteepLine   = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[4]) && (v[3] != v[4]);
    needBlend       = (blendResult[0] != BLEND_NONE);
    
    doLineBlend = ( blendResult[0] >= BLEND_DOMINANT ||
                    !( (blendResult[3] != BLEND_NONE && !IsPixEqual(src[0], src[8])) ||
                       (blendResult[1] != BLEND_NONE && !IsPixEqual(src[0], src[4])) ||
                       (IsPixEqual(src[8], src[7]) && IsPixEqual(src[7], src[6]) && IsPixEqual(src[6], src[5]) && IsPixEqual(src[5], src[4]) && !IsPixEqual(src[0], src[6]))
                     )
                  );
    
    blendPix = ( DistYCbCr(src[0], src[5]) <= DistYCbCr(src[0], src[7]) ) ? src[5] : src[7];
    
    dst[ 0] = lerp( dst[ 0], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0/3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00 );
    dst[15] = lerp( dst[15], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00 );
    dst[ 4] = lerp( dst[ 4], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00 );
    dst[ 5] = lerp( dst[ 5], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00 );
    dst[ 6] = lerp( dst[ 6], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00 );
    dst[ 7] = lerp( dst[ 7], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00 );
    dst[ 8] = lerp( dst[ 8], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00 );
    dst[ 9] = lerp( dst[ 9], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00 );
    
    
    // --- Quality Level 4 ---
    
    dist_01_04      = DistYCbCr(src[3], src[6]);
    dist_03_08      = DistYCbCr(src[5], src[2]);
    haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[6]) && (v[7] != v[6]);
    haveSteepLine   = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[2]) && (v[1] != v[2]);
    needBlend       = (blendResult[3] != BLEND_NONE);
    
    doLineBlend = ( blendResult[3] >= BLEND_DOMINANT ||
                    !( (blendResult[2] != BLEND_NONE && !IsPixEqual(src[0], src[6])) ||
                       (blendResult[0] != BLEND_NONE && !IsPixEqual(src[0], src[2])) ||
                       (IsPixEqual(src[6], src[5]) && IsPixEqual(src[5], src[4]) && IsPixEqual(src[4], src[3]) && IsPixEqual(src[3], src[2]) && !IsPixEqual(src[0], src[4]))
                     )
                  );
    
    blendPix = ( DistYCbCr(src[0], src[3]) <= DistYCbCr(src[0], src[5]) ) ? src[3] : src[5];
    dst[ 3] = lerp( dst[ 3], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0/3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00 );
    dst[12] = lerp( dst[12], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00 );
    dst[13] = lerp( dst[13], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00 );
    dst[14] = lerp( dst[14], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00 );
    dst[15] = lerp( dst[15], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00 );
    dst[ 4] = lerp( dst[ 4], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00 );
    dst[ 5] = lerp( dst[ 5], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00 );
    dst[ 6] = lerp( dst[ 6], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00 );
  }
  

  float3 res = lerp
               (
                 lerp
                 (
                   lerp( lerp(dst[ 6], dst[ 7], step(0.25, f.x)), lerp(dst[ 8], dst[ 9], step(0.75, f.x)), step(0.50, f.x) ),
                   lerp( lerp(dst[ 5], dst[ 0], step(0.25, f.x)), lerp(dst[ 1], dst[10], step(0.75, f.x)), step(0.50, f.x) ),
                   step(0.25, f.y)
                 ),
                 lerp
                 (
                   lerp
                   ( lerp(dst[ 4], dst[ 3], step(0.25, f.x)), lerp(dst[ 2], dst[11], step(0.75, f.x)), step(0.50, f.x) ),
                     lerp( lerp(dst[15], dst[14], step(0.25, f.x)), lerp(dst[13], dst[12], step(0.75, f.x)), step(0.50, f.x) ),
                     step(0.75, f.y)
                 ),
                 step(0.50, f.y)
               );

  
  return res;
}


technique xBRZ4x
{
  pass Downscale
  {
   VertexShader = VS_Downscale;
   PixelShader  = PS_Downscale;
   RenderTarget = DownscaleTex;
  }
  pass Upscale
  {
   VertexShader = VS_XBRZ4X;
   PixelShader  = PS_XBRZ4X;
   RenderTarget = UpscaleTex;
  }
  pass Final
  {
   VertexShader = PostProcessVS;
   PixelShader  = PS_Final;
  }
}
