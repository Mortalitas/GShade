uniform bool use_mouse_point <
    ui_label="Use Mouse Coordinates";
    ui_category="Coordinates";
> = false;

uniform float x_coord <
    ui_type = "slider";
    ui_label="X";
    ui_category="Coordinates";
    ui_tooltip="The X position of the center of the effect.";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;

uniform float y_coord <
    ui_type = "slider";
    ui_label="Y";
    ui_category="Coordinates";
    ui_tooltip="The Y position of the center of the effect.";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;

uniform float2 mouse_coordinates < 
source= "mousepoint";
>;
