#include "RadegastShaders.BlendingModes.fxh"
#include "RadegastShaders.Positional.fxh"

uniform int animate <
    ui_type = "combo";
    ui_label = "Animate";
    ui_items = "No\0Yes\0";
    ui_tooltip = "Animates the scanned column, moving it from one end to the other.";
> = 0;

uniform float frame_rate <
    source = "framecount";
>;

uniform float2 anim_rate <
    source = "pingpong";
    min = 0.0;
    max = 1.0;
    step = 0.0001;
    smoothing = 0.0;
>;

uniform float3 border_color <
    ui_type = "color";
    ui_label = "Border Color";
    ui_category = "Color Settings";
> = float3(1.0, 0.0, 0.0);

uniform float opacity <
    ui_type = "slider";
    ui_label = "Opacity";
    ui_category = "Color Settings";
> = 1.0;

uniform float min_depth <
    ui_type     = "slider";
    ui_label    = "Minimum Depth";
    ui_tooltip  = "Unmasks anything before a set depth.";
    ui_category = "Depth";
    ui_min=0.0;
    ui_max=1.0;
> = 0;