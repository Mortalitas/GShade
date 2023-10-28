#include "RadegastShaders.Transforms.fxh"
#include "RadegastShaders.Positional.fxh"

#define PI 3.141592358

uniform float2 offset <
    ui_type = "slider";
    ui_label = "Offset";
    ui_tooltip = "Horizontally/Vertically offsets the center of the display by a certain amount.";
    ui_category = "Properties";
    ui_min = -.5; 
    ui_max = .5;
> = 0;

uniform float scale <
    ui_type = "slider";
    ui_label = "Scale";
    ui_tooltip = "Determine's the display's Z-position on the projected sphere. Use this to zoom into or zoom out of the planet if it's too small or big respectively.";
    ui_category = "Properties";
    ui_min = 0.0; 
    ui_max = 10.0;
> = 10.0;

uniform float z_rotation <
    ui_type = "slider";
    ui_label = "Z-Rotation";
    ui_tooltip = "Rotates the display along the z-axis. This can help you orient characters or features on your display the way you want.";
    ui_category = "Properties";
    ui_min = 0.0; 
    ui_max = 360.0;
> = 0.5;

uniform float seam_scale <
    ui_type = "slider";
    ui_min = 0.5;
    ui_max = 1.0;
    ui_label = "Seam Blending";
    ui_tooltip = "Blends the ends of the screen so that the seam is somewhat reasonably hidden.";
    ui_category = "Properties";
> = 0.5;
