/*
  Modified by Lucas Melo (luluco250):
    - Replaced #ifdef's with #if's for compability with ReShade
*/

//_____________________________/\_______________________________
//==============================================================
//
//
//      [CRTS] PUBLIC DOMAIN CRT-STYLED SCALAR - 20180120b
//
//                      by Timothy Lottes
//
//
//==============================================================
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//_____________________________/\_______________________________
//==============================================================
//
//                         WHAT'S NEW
//
//--------------------------------------------------------------
// Evolution of prior shadertoy example
//--------------------------------------------------------------
// This one is semi-optimized
//  - Less texture fetches
//  - Didn't get to instruction level optimization
//  - Could likely use texture fetch to generate phosphor mask
//--------------------------------------------------------------
// Added options to disable unused features
//--------------------------------------------------------------
// Added in exposure matching
//  - Given scan-line effect and mask always darkens image
//  - Uses generalized tonemapper to boost mid-level
//  - Note this can compress highlights
//  - And won't get back peak brightness
//  - But best option if one doesn't want as much darkening
//--------------------------------------------------------------
// Includes option saturation and contrast controls
//--------------------------------------------------------------
// Added in subtractive aperture grille
//  - This is a bit brighter than prior
//--------------------------------------------------------------
// Make sure input to this filter is already low-resolution
//  - This is not designed to work on titles doing the following
//     - Rendering to hi-res with nearest sampling
//--------------------------------------------------------------
// Added a fast and more pixely option for 2 tap/pixel
//--------------------------------------------------------------
// Improved the vignette when WARP is enabled
//==============================================================
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//_____________________________/\_______________________________
//==============================================================
//
//          LICENSE = UNLICENSE (aka PUBLIC DOMAIN)
//
//--------------------------------------------------------------
// This is free and unencumbered software released into the 
// public domain.
//--------------------------------------------------------------
// Anyone is free to copy, modify, publish, use, compile, sell, 
// or distribute this software, either in source code form or as
// a compiled binary, for any purpose, commercial or 
// non-commercial, and by any means.
//--------------------------------------------------------------
// In jurisdictions that recognize copyright laws, the author or
// authors of this software dedicate any and all copyright 
// interest in the software to the public domain. We make this
// dedication for the benefit of the public at large and to the
// detriment of our heirs and successors. We intend this 
// dedication to be an overt act of relinquishment in perpetuity
// of all present and future rights to this software under 
// copyright law.
//--------------------------------------------------------------
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
// KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT 
// OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
// DEALINGS IN THE SOFTWARE.
//--------------------------------------------------------------
// For more information, please refer to 
// <http://unlicense.org/>
//==============================================================
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//_____________________________/\_______________________________
//==============================================================
//
//                           DEFINES
//
//--------------------------------------------------------------
// CRTS_DEBUG - Define to see on/off split screen
//--------------------------------------------------------------
// CRTS_WARP - Apply screen warp
//--------------------------------------------------------------
// CRTS_2_TAP - Faster very pixely 2-tap filter (off is 8)
//--------------------------------------------------------------
// CRTS_MASK_GRILLE      - Aperture grille (aka Trinitron)
// CRTS_MASK_GRILLE_LITE - Brighter (subtractive channels)
// CRTS_MASK_NONE        - No mask
// CRTS_MASK_SHADOW      - Horizontally stretched shadow mask
//--------------------------------------------------------------
// CRTS_TONE       - Normalize mid-level and process color
// CRTS_CONTRAST   - Process color - enable contrast control
// CRTS_SATURATION - Process color - enable saturation control
//==============================================================
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//_____________________________/\_______________________________
//==============================================================
//                         MACROS
//==============================================================
#define CrtsRcpF1(x) (1.0 / (x))
#define CrtsSatF1(x) saturate(x)
//--------------------------------------------------------------
float CrtsMax3F1(float a, float b, float c)
{
   return max(a, max(b, c));
}
//_____________________________/\_______________________________
//==============================================================
//              TONAL CONTROL CONSTANT GENERATION
//--------------------------------------------------------------
// This is in here for rapid prototyping
// Please use the CPU code and pass in as constants
//==============================================================
 float4 CrtsTone(
 float contrast,
 float saturation,
 float thin,
 float mask){
//--------------------------------------------------------------
  #if CRTS_MASK_NONE
   mask=1.0;
  #endif
//--------------------------------------------------------------
  #if CRTS_MASK_GRILLE_LITE
   // Normal R mask is {1.0, mask, mask}
   // LITE   R mask is {mask, 1.0, 1.0}
   mask = 0.5 + mask * 0.5;
  #endif
//--------------------------------------------------------------
  float4 ret;
  const float midOut = 0.18 / ((1.5 - thin) * (0.5 * mask + 0.5));
  const float pMidIn = pow(0.18, contrast);
  ret.x = contrast;
  ret.y = ((-pMidIn) + midOut) / ((1.0 - pMidIn) * midOut);
  ret.z = ((-pMidIn) * midOut + pMidIn) / (midOut * (-pMidIn) + midOut);
  ret.w = contrast + saturation;
  return ret;}
//_____________________________/\_______________________________
//==============================================================
//                            MASK
//--------------------------------------------------------------
// Letting LCD/OLED pixel elements function like CRT phosphors
// So "phosphor" resolution scales with display resolution
//--------------------------------------------------------------
// Not applying any warp to the mask (want high frequency)
// Real aperture grille has a mask which gets wider on ends
// Not attempting to be "real" but instead look the best
//--------------------------------------------------------------
// Shadow mask is stretched horizontally
//  RRGGBB
//  GBBRRG
//  RRGGBB
// This tends to look better on LCDs than vertical
// Also 2 pixel width is required to get triad centered
//--------------------------------------------------------------
// The LITE version of the Aperture Grille is brighter
// Uses {dark, 1.0, 1.0} for R channel
// Non LITE version uses {1.0, dark, dark}
//--------------------------------------------------------------
// 'pos' - This is 'fragCoord.xy'
//         Pixel {0, 0} should be {0.5, 0.5}
//         Pixel {1, 1} should be {1.5, 1.5} 
//--------------------------------------------------------------
// 'dark' - Exposure of of masked channel
//          0.0 = fully off, 1.0 = no effect
//==============================================================
 float3 CrtsMask(float2 pos, float dark){
  #if CRTS_MASK_GRILLE
   float3 m = float3(dark, dark, dark);
   const float x = frac(pos.x * (1.0 / 3.0));
   if(x < (1.0 / 3.0))
      m.r = 1.0;
   else if(x < (2.0 / 3.0))
      m.g = 1.0;
   else
      m.b = 1.0;
   return m;
  #endif
//--------------------------------------------------------------
  #if CRTS_MASK_GRILLE_LITE
   float3 m = float3(1.0, 1.0, 1.0);
   const float x = frac(pos.x * (1.0 / 3.0));
   if(x < (1.0 / 3.0))
      m.r = dark;
   else if(x < (2.0 / 3.0))
      m.g = dark;
   else
      m.b = dark;
   return m;
  #endif
//--------------------------------------------------------------
  #if CRTS_MASK_NONE
   return float3(1.0, 1.0, 1.0);
  #endif
//--------------------------------------------------------------
  #if CRTS_MASK_SHADOW
   pos.x += pos.y * 3.0;
   float3 m = float3(dark, dark, dark);
   const float x = frac(pos.x * (1.0 / 6.0));
   if(x < (1.0 / 3.0))
      m.r = 1.0;
   else if(x < (2.0 / 3.0))
      m.g = 1.0;
   else
      m.b = 1.0;
   return m;
  #endif
 }
//_____________________________/\_______________________________
//==============================================================
//                        FILTER ENTRY
//--------------------------------------------------------------
// Input must be linear
// Output color is linear
//--------------------------------------------------------------
// Must have fetch function setup: float3 CrtsFetch(float2 uv)
//  - The 'uv' range is {0.0 to 1.0} for input texture
//  - Output of this must be linear color
//--------------------------------------------------------------
// SCANLINE MATH & AUTO-EXPOSURE NOTES
// ===================================
// Each output line has contribution from at most 2 scanlines
// Scanlines are shaped by a windowed cosine function
// This shape blends together well with only 2 lines of overlap
//--------------------------------------------------------------
// Base scanline intensity is as follows
// which leaves output intensity range from {0 to 1.0}
// --------
// thin := range {thick 0.5 to thin 1.0}
// off  := range {0.0 to < 1.0}, 
//         sub-pixel offset between two scanlines
//  --------
//  a0 = cos(min(0.5,     off  * thin) * 2pi) * 0.5 + 0.5;
//  a1 = cos(min(0.5, (1.0 - off) * thin) * 2pi) * 0.5 + 0.5;
//--------------------------------------------------------------
// This leads to a image darkening factor of roughly: 
//  {(1.5 - thin) / 1.0}
// This is further reduced by the mask: 
//  {1.0 / 2.0 + mask * 1.0 / 2.0}
// Reciprocal of combined effect is used for auto-exposure
//  to scale up the mid-level in the tonemapper
//==============================================================
 float3 CrtsFilter(
//--------------------------------------------------------------
  // SV_POSITION, fragCoord.xy
  float2 ipos,
//--------------------------------------------------------------
  // inputSize / outputSize (in pixels)
  float2 inputSizeDivOutputSize,     
//--------------------------------------------------------------
  // 0.5 * inputSize (in pixels)
  float2 halfInputSize,
//--------------------------------------------------------------
  // 1.0 / inputSize (in pixels)
  float2 rcpInputSize,
//--------------------------------------------------------------
  // 1.0 / outputSize (in pixels)
  float2 rcpOutputSize,
//--------------------------------------------------------------
  // 2.0 / outputSize (in pixels)
  float2 twoDivOutputSize,   
//--------------------------------------------------------------
  // inputSize.y
  float inputHeight,
//--------------------------------------------------------------
  // Warp scanlines but not phosphor mask
  //  0.0 = no warp
  //  1.0/64.0 = light warping
  //  1.0/32.0 = more warping
  // Want x and y warping to be different (based on aspect)
  float2 warp,
//--------------------------------------------------------------
  // Scanline thinness
  //  0.50 = fused scanlines
  //  0.70 = recommended default
  //  1.00 = thinner scanlines (too thin)
  // Shared with CrtsTone() function
  float thin,
//--------------------------------------------------------------
  // Horizonal scan blur
  //  -3.0 = pixely
  //  -2.5 = default
  //  -2.0 = smooth
  //  -1.0 = too blurry
  float blur,
//--------------------------------------------------------------
  // Shadow mask effect, ranges from,
  //  0.25 = large amount of mask (not recommended, too dark)
  //  0.50 = recommended default
  //  1.00 = no shadow mask
  // Shared with CrtsTone() function
  float mask,
//--------------------------------------------------------------
  // Tonal curve parameters generated by CrtsTone()
  float4 tone
//--------------------------------------------------------------
 ){
//--------------------------------------------------------------
  #if CRTS_DEBUG
   float2 uv = ipos * rcpOutputSize;
   // Show second half processed, and first half un-processed
   if(uv.x < 0.5)
   {
      // Force nearest to get squares
      uv *= 1.0 / rcpInputSize;
      uv = floor(uv) + float2(0.5, 0.5);
      uv *= rcpInputSize;
      return CrtsFetch(uv);
   }
  #endif
//--------------------------------------------------------------
  // Optional apply warp
  float2 pos;
  #if CRTS_WARP
   // Convert to {-1 to 1} range
   pos = ipos * twoDivOutputSize - float2(1.0, 1.0);
   // Distort pushes image outside {-1 to 1} range
   pos *= float2(
    1.0 + (pos.y * pos.y) * warp.x,
    1.0 + (pos.x * pos.x) * warp.y);
   // TODO: Vignette needs optimization
   float vin = 1.0 - (
    (1.0 - CrtsSatF1(pos.x * pos.x)) * (1.0 - CrtsSatF1(pos.y * pos.y)));
   vin = CrtsSatF1((-vin) * inputHeight + inputHeight);
   // Leave in {0 to inputSize}
   pos = pos * halfInputSize + halfInputSize;     
  #else
   pos = ipos * inputSizeDivOutputSize;
  #endif
//--------------------------------------------------------------
  // Snap to center of first scanline
  float y0 = floor(pos.y - 0.5) + 0.5;
  #if CRTS_2_TAP
   // Using Inigo's "Improved Texture Interpolation"
   // http://iquilezles.org/www/articles/texture/texture.htm
   pos.x += 0.5;
   const float xi = floor(pos.x);
   float xf = pos.x - xi;
   xf = xf * xf * xf * (xf * (xf * 6.0 - 15.0) + 10.0);  
   const float x0 = xi + xf - 0.5;
   float2 p = float2(x0 * rcpInputSize.x, y0 * rcpInputSize.y);     
   // Coordinate adjusted bilinear fetch from 2 nearest scanlines
   const float3 colA = CrtsFetch(p);
   p.y += rcpInputSize.y;
   const float3 colB = CrtsFetch(p);
  #else
   // Snap to center of one of four pixels
   const float x0 = floor(pos.x - 1.5) + 0.5;
   // Inital UV position
   float2 p = float2(x0 * rcpInputSize.x, y0 * rcpInputSize.y);     
   // Fetch 4 nearest texels from 2 nearest scanlines
   const float3 colA0 = CrtsFetch(p);
   p.x += rcpInputSize.x;
   float3 colA1 = CrtsFetch(p);
   p.x += rcpInputSize.x;
   float3 colA2 = CrtsFetch(p);
   p.x += rcpInputSize.x;
   float3 colA3 = CrtsFetch(p);
   p.y += rcpInputSize.y;
   float3 colB3 = CrtsFetch(p);
   p.x -= rcpInputSize.x;
   float3 colB2 = CrtsFetch(p);
   p.x -= rcpInputSize.x;
   float3 colB1 = CrtsFetch(p);
   p.x -= rcpInputSize.x;
   const float3 colB0 = CrtsFetch(p);
  #endif
//--------------------------------------------------------------
  // Vertical filter
  // Scanline intensity is using sine wave
  // Easy filter window and integral used later in exposure
  const float off = pos.y - y0;
  float scanA = cos(min(0.5,  off * thin     ) * 6.28318530717958) * 0.5 + 0.5;
  float scanB = cos(min(0.5, (-off) * thin + thin) * 6.28318530717958) * 0.5 + 0.5;
//--------------------------------------------------------------
  #if CRTS_2_TAP
   #if CRTS_WARP
    // Get rid of wrong pixels on edge
    scanA *= vin;
    scanB *= vin;
   #endif
   // Apply vertical filter
   float3 color = (colA * scanA) + (colB * scanB);
  #else
   // Horizontal kernel is simple gaussian filter
   const float off0 = pos.x - x0;
   const float off1 = off0 - 1.0;
   const float off2 = off0 - 2.0;
   const float off3 = off0 - 3.0;
   const float pix0 = exp2(blur * off0 * off0);
   const float pix1 = exp2(blur * off1 * off1);
   const float pix2 = exp2(blur * off2 * off2);
   const float pix3 = exp2(blur * off3 * off3);
   float pixT = CrtsRcpF1(pix0 + pix1 + pix2 + pix3);
   #if CRTS_WARP
    // Get rid of wrong pixels on edge
    pixT *= vin;
   #endif
   scanA *= pixT;
   scanB *= pixT;
   // Apply horizontal and vertical filters
   float3 color =
    (colA0 * pix0 + colA1 * pix1 + colA2 * pix2 + colA3 * pix3) * scanA +
    (colB0 * pix0 + colB1 * pix1 + colB2 * pix2 + colB3 * pix3) * scanB;
  #endif
//--------------------------------------------------------------
  // Apply phosphor mask          
  color *= CrtsMask(ipos, mask);
//--------------------------------------------------------------
  // Optional color processing
  #if CRTS_TONE
   // Tonal control, start by protecting from /0
   float peak = max(1.0 / (256.0 * 65536.0),
    CrtsMax3F1(color.r, color.g, color.b));
   // Compute the ratios of {R, G, B}
   float3 ratio = color * CrtsRcpF1(peak);
   // Apply tonal curve to peak value
   #if CRTS_CONTRAST
    peak = pow(peak, tone.x);
   #endif
   peak = peak * CrtsRcpF1(peak * tone.y + tone.z);
   // Apply saturation
   #if CRTS_SATURATION
    ratio = pow(ratio, float3(tone.w, tone.w, tone.w));
   #endif
   // Reconstruct color
   return ratio * peak;
 #else
  return color;
 #endif
//--------------------------------------------------------------
 }
