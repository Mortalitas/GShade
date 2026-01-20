uniform float radius <
    ui_type = "slider";
    ui_label="Radius";
    ui_category="Bounds";
    ui_tooltip="Controls the size of the distortion.";
    ui_min = 0.0; 
    ui_max = 1.0;
> = 0.5;

uniform float tension <
    ui_type = "slider";
    ui_label = "Tension";
    ui_category="Bounds";
    ui_tooltip="Controls how rapidly the effect reaches its maximum distortion.";
    ui_min = 0.; ui_max = 10.; ui_step = 0.001;
> = 1.0;
