// Easy LUT config
// Name which will display in the UI. Should be without spaces
/*
 *  MIT License

 *  Copyright (c) 2020 prod80

 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:

 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.

 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

#define PD80_Technique_Name     prod80_02_Bonus_LUT_pack

// Texture name which contains the LUT(s) and the Tile Sizes, Amounts, etc.
#define PD80_LUT_File_Name      "pd80_example-lut.png"
#define PD80_Tile_SizeXY        64
#define PD80_Tile_Amount        64
#define PD80_LUT_Amount         50

// Drop down menu which gives the names of the LUTs, each menu option should be followed by \0
#define PD80_Drop_Down_Menu     "PD80 Cinematic 01\0PD80 Cinematic 02\0PD80 Cinematic 03\0PD80 Cinematic 04\0PD80 Cinematic 05\0PD80 Cinematic 06\0PD80 Cinematic 07\0PD80 Cinematic 08\0PD80 Cinematic 09\0PD80 Cinematic 10\0PD80 Cinematic 11\0PD80 Cinematic 12\0PD80 Cinematic 13\0PD80 Cinematic 14\0PD80 Cinematic 15\0PD80 Cinematic 16\0PD80 Cinematic 17\0PD80 Cinematic 18\0PD80 Cinematic 19\0PD80 Cinematic 20\0PD80 Cinematic 21\0PD80 Cinematic 22\0PD80 Cinematic 23\0PD80 Cinematic 24\0PD80 Cinematic 25\0PD80 Cinematic 26\0PD80 Cinematic 27\0PD80 Cinematic 28\0PD80 Cinematic 29\0PD80 Cinematic 30\0PD80 Cinematic 31\0PD80 Cinematic 32\0PD80 Cinematic 33\0PD80 Cinematic 34\0PD80 Cinematic 35\0PD80 Cinematic 36\0PD80 Cinematic 37\0PD80 Cinematic 38\0PD80 Cinematic 39\0PD80 Cinematic 40\0PD80 Cinematic 41\0PD80 Cinematic 42\0PD80 Cinematic 43\0PD80 Cinematic 44\0PD80 Cinematic 45\0PD80 Cinematic 46\0PD80 Cinematic 47\0PD80 Cinematic 48\0PD80 Cinematic 49\0PD80 Cinematic 50\0"

// Final pass to the shader
#include "PD80_LUT_v2.fxh"
