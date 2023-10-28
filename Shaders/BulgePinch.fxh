#include "RadegastShaders.Depth.fxh"
#include "RadegastShaders.Positional.fxh"
#include "RadegastShaders.Radial.fxh"
#include "RadegastShaders.AspectRatio.fxh"
#include "RadegastShaders.Offsets.fxh"
#include "RadegastShaders.Transforms.fxh"
#include "RadegastShaders.BlendingModes.fxh"

uniform float magnitude <
    ui_type = "slider";
    ui_label = "Magnitude";
    ui_min = -1.0; 
    ui_max = 1.0;
    ui_tooltip = "The magnitude of the distortion. Positive values cause the image to bulge out. Negative values cause the image to pinch in.";    
    ui_category = "Properties";
> = -0.5;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Animates the effect.";
    ui_category = "Properties";
> = 0;

uniform float anim_rate <
    source = "timer";
>;
