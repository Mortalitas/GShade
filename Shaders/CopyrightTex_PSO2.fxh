/*------------------.
| :: Description :: |
'-------------------/

    Texture Header (version 0.1)

    Authors: originalnicodr, prod80, uchu suzume, Marot Satil

    About:
    Provides a variety of blending methods for you to use as you wish. Just include this header.

    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
    
    Version 0.1 by Marot Satil & uchu suzume
    + Divided into corresponding lists for each game.
    * Added warning message when specified Non-existing source reference numbers.
    x Fixed incorrect specification of PSO2 logo in ui_item and Texture Definition. 

    Version 0.x by Marot Satil & uchu suzume
    + Added "else" in _Copyright_Texture_Source list to avoid errors when switching *Tex.fxh.    
*/

// -------------------------------------
// Texture Macros
// -------------------------------------

#define TEXTURE_COMBO(variable, name_label, description) \
uniform int variable \
< \
    ui_items = \
               "PSO2\0" \
               "PSO2 Century\0" \
               "PSO2 Schoolbell\0" \
               "PSO2 Helvetica Condensed\0" \
               "PSO2 with GShade Dark\0" \
               "PSO2 with GShade White\0" \
               "PSO2 Montserrat\0" \
               "PSO2 Montserrat Simple\0" \
               "PSO2 With Flat Logo\0" \
               "PSO2 Eurostile\0" \
               "PSO2 Metro No. 2 Cutout\0" \
               "PSO2 Kranky\0" \
               "PSO2 GN Fuyu-iro Script\0" \
               "PSO2 Sacramento\0" \
               "PSO2 Century Rectangle\0" \
               "PSO2 Eurostile Left\0" \
               "PSO2 Eurostile Right\0" \
               "PSO2 Eurostile Center\0" \
               "PSO2 Futura Center\0" \
               "PSO2 Neuzeit Grotesk\0" \
               "PSO2 Krona One\0" \
               "PSO2 Mouse Memories\0" \
               "PSO2 Swanky And Moo Moo\0" \
               "PSO2 Staccato555 A\0" \
               "PSO2 Staccato555 B\0" \
               "PSO2 PSO2 Lato Cutout\0" \
               "PSO2 Rockwell Nova\0" \
               "PSO2 Kabel Heavy\0" \
               "PSO2 Poiret One Small\0" \
               "PSO2 Poiret One Large\0" \
               "PSO2 Kranky Large\0" \
               "PSO2 Futura Triangle\0" \
               "PSO2 Helvetica Square\0" \
               "PSO2 Righteous\0" \
               "PSO2 Poppins\0" \
               "PSO2 Bank Gothic\0" \
               "PSO2 Flat Logo\0" \
               "PSO2 Yanone Kaffeesatz A\0" \
               "PSO2 Yanone Kaffeesatz B\0" \
               "Custom\0" \
               ; \
    ui_bind = "_Copyright_Texture_Source"; \
    ui_label = name_label; \
    ui_tooltip = description; \
    ui_spacing = 1; \
    ui_type = "combo"; \
> = 0;
/* Set default value(see above) by source code if the preset has not modified yet this variable/definition */
#ifndef cLayer_Texture_Source
#define cLayer_Texture_Source 0
#warning "Non-existing source reference numbers specified. Try selecting the logo texture at the top and then reload."
#endif

// -------------------------------------
// Texture Definition
// -------------------------------------

// (?<=Source == )[\d][\S+]{0,999} Regular expression for renumbering.

#if _Copyright_Texture_Source == 0 // PSO2
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2.png"
#define _SOURCE_COPYRIGHT_SIZE 435.0, 31.0
#elif _Copyright_Texture_Source == 1 // PSO2 Century
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_century.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 40.0
#elif _Copyright_Texture_Source == 2 // PSO2 Schoolbell
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_schoolbell.png"
#define _SOURCE_COPYRIGHT_SIZE 435.0, 31.0
#elif _Copyright_Texture_Source == 3 // PSO2 Helvetica Condensed
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_helvetica_condenced.png"
#define _SOURCE_COPYRIGHT_SIZE 540.0, 54.0
#elif _Copyright_Texture_Source == 4 // PSO2 With GShade Dark
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_w_gshade_dark.png"
#define _SOURCE_COPYRIGHT_SIZE 1092.0, 66.0
#elif _Copyright_Texture_Source == 5 // PSO2 With GShade White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_w_gshade_white.png"
#define _SOURCE_COPYRIGHT_SIZE 1092.0, 66.0
#elif _Copyright_Texture_Source == 6 // PSO2 Montserrat
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_montserrat.png"
#define _SOURCE_COPYRIGHT_SIZE 880.0, 90.0
#elif _Copyright_Texture_Source == 7 // PSO2 Montserrat Simple
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_montserrat_simple.png"
#define _SOURCE_COPYRIGHT_SIZE 1030.0, 90.0
#elif _Copyright_Texture_Source == 8 // PSO2 With Flat Logo
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_w_flat_logo.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 70.0
#elif _Copyright_Texture_Source == 9 // PSO2 Eurostile
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 120.0
#elif _Copyright_Texture_Source == 10 // PSO2 Metro No. 2 Cutout
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_metro_no2_cutout.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 100.0
#elif _Copyright_Texture_Source == 11 // PSO2 Kranky
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_kranky.png"
#define _SOURCE_COPYRIGHT_SIZE 1280.0, 120.0
#elif _Copyright_Texture_Source == 12 // PSO2 GN Fuyu-iro Script
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_gn-fuyu-iro_script.png"
#define _SOURCE_COPYRIGHT_SIZE 820.0, 160.0
#elif _Copyright_Texture_Source == 13 // PSO2 Sacramento
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sacramento.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 150.0
#elif _Copyright_Texture_Source == 14 // PSO2 Century Rectangle
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_century_rectangle.png"
#define _SOURCE_COPYRIGHT_SIZE 580.0, 150.0
#elif _Copyright_Texture_Source == 15 // PSO2 Eurostile Left
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile_left.png"
#define _SOURCE_COPYRIGHT_SIZE 960.0, 216.0
#elif _Copyright_Texture_Source == 16 // PSO2 Eurostile Right
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile_right.png"
#define _SOURCE_COPYRIGHT_SIZE 960.0, 216.0
#elif _Copyright_Texture_Source == 17 // PSO2 Eurostile Center
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile_center.png"
#define _SOURCE_COPYRIGHT_SIZE 960.0, 216.0
#elif _Copyright_Texture_Source == 18 // PSO2 Futura Center
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_center.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 190.0
#elif _Copyright_Texture_Source == 19 // PSO2 Neuzeit Grotesk
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_neuzeit_grotesk.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 350.0
#elif _Copyright_Texture_Source == 20 // PSO2 Krona One
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_krona_one.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 300.0
#elif _Copyright_Texture_Source == 21 // PSO2 Mouse Memories
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_mouse_memories.png"
#define _SOURCE_COPYRIGHT_SIZE 660.0, 240.0
#elif _Copyright_Texture_Source == 22 // PSO2 Swanky And Moo Moo
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_swanky_and_moo_moo.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 150.0
#elif _Copyright_Texture_Source == 23 // PSO2 Staccato555 A
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_staccato555_a.png"
#define _SOURCE_COPYRIGHT_SIZE 820.0, 350.0
#elif _Copyright_Texture_Source == 24 // PSO2 Staccato555 B
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_staccato555_b.png"
#define _SOURCE_COPYRIGHT_SIZE 870.0, 320.0
#elif _Copyright_Texture_Source == 25 // PSO2 Lato Cutout
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_lato_cutout.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 180.0
#elif _Copyright_Texture_Source == 26 // PSO2 Rockwell Nova
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_rockwell_nova.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 130.0
#elif _Copyright_Texture_Source == 27 // PSO2 Kabel Heavy
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_kabel_heavy.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 240.0
#elif _Copyright_Texture_Source == 28 // PSO2 Poiret One Small
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_poiret_one_s.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 210.0
#elif _Copyright_Texture_Source == 29 // PSO2 Poiret One Large
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_poiret_one_l.png"
#define _SOURCE_COPYRIGHT_SIZE 1440.0, 500.0
#elif _Copyright_Texture_Source == 30 // PSO2 Kranky Large
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_kranky_l.png"
#define _SOURCE_COPYRIGHT_SIZE 830.0, 340.0
#elif _Copyright_Texture_Source == 31 // PSO2 Futura Triangle
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_tri.png"
#define _SOURCE_COPYRIGHT_SIZE 329.0, 432.0
#elif _Copyright_Texture_Source == 32 // PSO2 Helvetica Square
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_helvetica_square.png"
#define _SOURCE_COPYRIGHT_SIZE 360.0, 400.0
#elif _Copyright_Texture_Source == 33 // PSO2 Righteous
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_righteous.png"
#define _SOURCE_COPYRIGHT_SIZE 550.0, 300.0
#elif _Copyright_Texture_Source == 34 // PSO2 Poppins
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_poppins.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 200.0
#elif _Copyright_Texture_Source == 35 // PSO2 Bank Gothic
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_bank_gothic.png"
#define _SOURCE_COPYRIGHT_SIZE 650.0, 300.0
#elif _Copyright_Texture_Source == 36 // PSO2 Flat Logo
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_flat_logo.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 400.0
#elif _Copyright_Texture_Source == 37 // PSO2 Yanone Kaffeesatz A
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_yanone_kaffeesatz_a.png"
#define _SOURCE_COPYRIGHT_SIZE 300.0, 300.0
#elif _Copyright_Texture_Source == 38 // PSO2 Yanone Kaffeesatz B
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_yanone_kaffeesatz_b.png"
#define _SOURCE_COPYRIGHT_SIZE 300.0, 300.0
#elif _Copyright_Texture_Source == 39    // Custom
#define _SOURCE_COPYRIGHT_FILE cLayerTex
#define _SOURCE_COPYRIGHT_SIZE cLayer_SIZE_X, cLayer_SIZE_Y
#else 
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2.png"
#define _SOURCE_COPYRIGHT_SIZE 435.0, 31.0
#endif
