#include "Swirl.fxh"

uniform int number_splices <
    ui_type = "slider";
    ui_label = "Number of Splices";
    ui_tooltip = "Sets the number of splices. A higher value makes the effect look closer to Normal mode by increasing the number of splices.";
    ui_category = "Properties";
    ui_min = 1;
    ui_max = 50;
> = 10;
