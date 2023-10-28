#include "RadegastShaders.Depth.fxh"
#include "RadegastShaders.Positional.fxh"
#include "RadegastShaders.Radial.fxh"
#include "RadegastShaders.AspectRatio.fxh"
#include "RadegastShaders.Offsets.fxh"
#include "RadegastShaders.Transforms.fxh"
#include "RadegastShaders.BlendingModes.fxh"

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
    ui_step = 1.0;
> = 180.0;

uniform int inverse <
    ui_type = "combo";
    ui_label = "Inverse Angle";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Inverts the angle of the swirl, making the edges the most distorted.";
    ui_category = "Properties";
> = 0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Animates the swirl, moving it clockwise and counterclockwise.";
    ui_category = "Properties";
> = 0;

uniform float anim_rate <
    source = "timer";
>;
