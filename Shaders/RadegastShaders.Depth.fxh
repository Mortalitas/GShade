uniform float2 depth_bounds <
    ui_type = "slider";
    ui_label = "Depth Bounds";
    ui_category = "Depth";
    ui_tooltip = "The depth bounds where the effect is calculated.";
    min = 0.0;
    max = 1.0;
> = float2(0.0, 1.0);

uniform float min_depth <
    ui_type = "slider";
    ui_label="Minimum Depth";
    ui_tooltip="Unmasks anything before a set depth.";
    ui_category="Depth";
    ui_min=0.0;
    ui_max=1.0;
> = 0;