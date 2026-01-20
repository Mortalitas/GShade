uniform float anim_rate <
    source = "timer";
>;

uniform float anim_rate_multiplier <
    ui_type = "slider";
    ui_label = "Animation Speed";
    ui_category = "Animation Settings";
    ui_min = 0.05;
    ui_max = 10;
    ui_step = 0.05;
> = 1.0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_category = "Animation Settings";
#ifdef ANIMATE_AP
    ui_items = "No\0Amplitude\0Phase\0";
#endif
#ifdef ANIMATE_APA
    ui_items = "No\0Amplitude\0Phase\0Angle\0";
#endif
#ifdef ANIMATE_NY
    ui_items = "No\0Yes\0";
#endif
    ui_tooltip = "Animates the effect and by which value (if specified).";
    ui_category = "Properties";
> = 0;
