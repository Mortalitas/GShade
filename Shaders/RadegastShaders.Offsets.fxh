uniform bool use_offset_coords <
    ui_label = "Use Offset Coordinates";
    ui_tooltip = "Display the distortion in any location besides its original coordinates.";
    ui_category = "Offset";
> = 0;

uniform float offset_x <
    ui_type = "slider";
    ui_label = "X";
    ui_category = "Offset";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;


uniform float offset_y <
    ui_type = "slider";
    ui_label = "Y";
    ui_category = "Offset";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;
