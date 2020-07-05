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

#define PD80_Technique_Name     prod80_02_Cinetools_LUT

// Texture name which contains the LUT(s) and the Tile Sizes, Amounts, etc.
#define PD80_LUT_File_Name      "pd80_cinelut.png"
#define PD80_Tile_SizeXY        64
#define PD80_Tile_Amount        64
#define PD80_LUT_Amount         31

// Drop down menu which gives the names of the LUTs, each menu option should be followed by \0
#define PD80_Drop_Down_Menu     "FilmicGold\0FilmicGold_Contrast\0FilmicBlue\0FilmicBlue_Contrast\0TealOrangeNeutral\0TealOrangeYCSplit\0TealOrangeWarmMatte\0CinematicColors\0UltraWarmMatte\0UltraMatte\0BW-Max\0BW-MaxSepia\0BW-MatteLooks\0AlternativeProcess-01\0AlternativeProcess-02\0SuperGreens\0ColorHarmony-01\0ColorHarmony-02\0GoingBrownAgain\0Cyanolyte\0DustyOldMan\0DustyOldMatte\0DrankAllTheRedWine\0OldEleganceClean\0OldEleganceMatte\0HundredDollarStripper\0HundredDollarStripperMatte\0ClassicTealOrange\0ClassicTealOrangeMatte\0ClassicTealOrangeYHL\0ClassicTealOrangeYHLMatte\0"

// Final pass to the shader
#include "PD80_LUT_v2.fxh"