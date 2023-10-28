#include "RadegastShaders.Depth.fxh"
#include "RadegastShaders.Positional.fxh"
#include "RadegastShaders.Radial.fxh"
#include "RadegastShaders.AspectRatio.fxh"
#include "RadegastShaders.Offsets.fxh"
#include "RadegastShaders.Transforms.fxh"
#include "RadegastShaders.BlendingModes.fxh"

uniform int mode <
    ui_type = "combo";
    ui_label = "Mode";
    ui_items = "Around center\0Out from center\0";
    ui_tooltip = "Selects the mode the distortion should be processed through.";
    ui_category = "Properties";
> = 0;

uniform float angle <
    ui_type = "slider";
    ui_label = "Angle";
    ui_tooltip = "Serves as a multiplier for the phase and amplitude. Also affects the motion of the animation by phase based on whether the value is negative or positive.";
    ui_category = "Properties";
    ui_min = -999.0; 
    ui_max = 999.0; 
    ui_step = 1.0;
> = 180.0;

uniform float period <
    ui_type = "slider";
    ui_type = "Phase";
    ui_label = "Period";
    ui_tooltip = "Adjusts the rate of distortion.";
    ui_category = "Properties";
    ui_min = 0.1; 
    ui_max = 10.0;
> = 0.25;

uniform float amplitude <
    ui_type = "slider";
    ui_label = "Amplitude";
    ui_tooltip = "Increases how extreme the picture twists back and forth.";
    ui_category = "Properties";
    ui_min = -10.0; 
    ui_max = 10.0;
> = 1.0;

uniform float phase <
    ui_type = "slider";
    ui_label = "Phase";
    ui_tooltip = "The offset at which the pixels twist back and forth from the center.";
    ui_category = "Properties";
    ui_min = -5.0; 
    ui_max = 5.0;
> = 0.0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Amplitude\0Phase\0";
    ui_tooltip = "Enable or disable the animation. Animates the zigzag effect by phase or by amplitude.";
    ui_category = "Properties";
> = 0;

uniform float anim_rate <
    source = "timer";
>;
