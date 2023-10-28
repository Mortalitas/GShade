#include "RadegastShaders.BlendingModes.fxh"

uniform float x_col <
    ui_type = "slider";
    ui_label = "Position";
    ui_tooltip = "The position on the screen to start scanning. (Does not work with Animate enabled.)"; 
    ui_category = "Properties";
    ui_max = 1.0;
    ui_min = 0.0;
> = 0.5;

uniform float scan_speed <
    ui_type = "slider";
    ui_label="Scan Speed";
    ui_tooltip=
        "Adjusts the rate of the scan. Lower values mean a slower scan, which can get you better images at the cost of scan speed.";
    ui_category = "Properties";
    ui_max = 3.0;
    ui_min = 0.0;
> = 1.0;

uniform int direction <
    ui_type = "combo";
    ui_label = "Scan Direction";
    ui_items = "Left\0Right\0Up\0Down\0";
    ui_tooltip = "Changes the direction of the scan to the direction specified.";
    ui_category = "Properties";
> = 0;

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Animates the scanned column, moving it from one end to the other.";
    ui_category = "Properties";
> = 0;

uniform float frame_rate <
    source = "framecount";
>;

uniform float2 anim_rate <
    source = "pingpong";
    min = 0.0;
    max = 1.0;
    step = 0.001;
    smoothing = 0.0;
>;

uniform float min_depth <
    ui_type = "slider";
    ui_label="Minimum Depth";
    ui_tooltip="Unmasks anything before a set depth.";
    ui_category="Depth";
    ui_min=0.0;
    ui_max=1.0;
> = 0;