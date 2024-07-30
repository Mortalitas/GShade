/*-----------------------------------------------------------------------------------------------------*/
/* Wave Shader - by Radegast Stravinsky of Ultros.                                                     */
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
#include "RadegastShaders.Depth.fxh"
#include "RadegastShaders.BlendingModes.fxh"

uniform int wave_type <
    ui_type = "combo";
    ui_label = "Wave Type";
    ui_tooltip = "Selects the type of distortion to apply.";
    ui_items = "X/X\0X/Y\0";
    ui_tooltip = "Which axis the distortion should be performed against.";
    ui_category = "Properties";
> = 1;

uniform float angle <
    ui_type = "slider";
    ui_label = "Angle";
    ui_tooltip = "The angle at which the distortion occurs.";
    ui_category = "Properties";
    ui_min = -360.0; 
    ui_max = 360.0; 
    ui_step = 1.0;
> = 0.0;

uniform float period <
    ui_type = "slider";
    ui_label = "Period";
    ui_tooltip = "The wavelength of the distortion. Smaller values make for a longer wavelength.";
    ui_category = "Properties";
    ui_min = 0.1; 
    ui_max = 10.0;
> = 3.0;

uniform float amplitude <
    ui_type = "slider";
    ui_label = "Amplitude";
    ui_tooltip = "The amplitude of the distortion in each direction.";
    ui_category = "Properties";
    ui_min = -1.0; 
    ui_max = 1.0;
> = 0.075;

uniform float phase <
    ui_type = "slider";
    ui_label = "Phase";
    ui_min = -5.0; 
    ui_max = 5.0;
    ui_tooltip = "The offset being applied to the distortion's waves.";
> = 0.0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Amplitude\0Phase\0Angle\0";
    ui_tooltip = "Enable or disable the animation. Animates the wave effect by phase, amplitude, or angle.";
    ui_category = "Properties";
> = 0;

uniform float anim_rate <
    source = "timer";
>;
