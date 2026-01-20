/*-----------------------------------------------------------------------------------------------------*/
/* Swirl Shader - by Radegast Stravinsky of Ultros.                                                    */
/* There are plenty of shaders that make your game look amazing. This isn't one of them.               */
/* License: MIT                                                                                        */
/*                                                                                                     */
/* MIT License                                                                                         */
/*                                                                                                     */
/* Copyright (c) 2021 Radegast-FFXIV                                                                   */
/*                                                                                                     */
/* Permission is hereby granted, free of charge, to any person obtaining a copy                        */
/* of this software and associated documentation files (the "Software"), to deal                       */
/* in the Software without restriction, including without limitation the rights                        */
/* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell                           */
/* copies of the Software, and to permit persons to whom the Software is                               */
/* furnished to do so, subject to the following conditions:                                            */
/*                                                                                                     */
/* The above copyright notice and this permission notice shall be included in all                      */
/* copies or substantial portions of the Software.                                                     */
/*                                                                                                     */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                          */
/* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                            */
/* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                         */
/* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                              */
/* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                       */
/* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE                       */
/* SOFTWARE.                                                                                           */
/*-----------------------------------------------------------------------------------------------------*/
#define ANIMATE_NY

#include "WarpFX.Animate.fxh"
#include "WarpFX.Depth.fxh"
#include "WarpFX.Positional.fxh"
#include "WarpFX.Radial.fxh"
#include "WarpFX.AspectRatio.fxh"
#include "WarpFX.Offsets.fxh"
#include "WarpFX.Transforms.fxh"
#include "WarpFX.BlendingModes.fxh"

uniform float inner_radius <
    ui_type = "slider";
    ui_label = "Inner Radius";
    ui_tooltip = "Normal Mode -- Sets the inner radius at which the maximum angle is automatically set.\nSpliced Radial mode -- defines the innermost spliced circle's size.";
    ui_category = "Properties";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0;

uniform float angle <
    ui_type = "slider";
    ui_label="Angle";
    ui_category = "Properties";
    ui_min = -1800.0; 
    ui_max = 1800.0; 
    ui_step = 30.0;
> = 180.0;

uniform int inverse <
    ui_type = "combo";
    ui_label = "Inverse Angle";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Inverts the angle of the swirl, making the edges the most distorted.";
    ui_category = "Properties";
> = 0;
