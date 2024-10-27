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
               "Century\0" \
               "Schoolbell\0" \
               "Helvetica Condensed\0" \
               "Sophia DF\0" \
               "with GShade Dark\0" \
               "with GShade White\0" \
               "Montserrat\0" \
               "Montserrat Simple\0" \
               "With Flat Logo\0" \
               "Eurostile\0" \
               "Metro No. 2 Cutout\0" \
               "Kranky\0" \
               "GN Fuyu-iro Script\0" \
               "Sacramento\0" \
               "Century Rectangle\0" \
               "Eurostile Left\0" \
               "Eurostile Right\0" \
               "Eurostile Center\0" \
               "Sophia DF Rectangle\0" \
               "Futura Center\0" \
               "Sophia DF Center\0" \
               "Neuzeit Grotesk\0" \
               "Krona One\0" \
               "Grand Master\0" \
               "Mouse Memories\0" \
               "Swanky And Moo Moo\0" \
               "Staccato555 A\0" \
               "Staccato555 B\0" \
               "PSO2 Lato Cutout\0" \
               "Rockwell Nova\0" \
               "Kabel Heavy\0" \
               "Sophia DF SEGA\0" \
               "Sophia DF SEGA 2\0" \
               "Sophia DF PSO2\0" \
               "Poiret One Small\0" \
               "Poiret One Large\0" \
               "Kranky Large\0" \
               "Futura Triangle\0" \
               "Sophia DF Triangle\0" \
               "Helvetica Square\0" \
               "Righteous\0" \
               "Poppins\0" \
               "Bank Gothic\0" \
               "Flat Logo\0" \
               "Yanone Kaffeesatz A\0" \
               "Yanone Kaffeesatz B\0" \
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
//#warning "Non-existing source reference numbers specified. Try selecting the logo texture at the top and then reload."
#endif

// -------------------------------------
// Texture Definition
// -------------------------------------

// (?<=Source == )[\d][\S+]{0,999} Regular expression for renumbering.

#if _Copyright_Texture_Source == 0 // PSO2
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2.png"
#define _SOURCE_COPYRIGHT_SIZE 650.0, 60.0
#elif _Copyright_Texture_Source == 1 // Century
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_century.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 60.0
#elif _Copyright_Texture_Source == 2 // Schoolbell
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_schoolbell.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 60.0
#elif _Copyright_Texture_Source == 3 // Helvetica Condensed
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_helvetica_condenced.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 60.0
#elif _Copyright_Texture_Source == 4 // Sophia DF
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sophia_df_2.png"
#define _SOURCE_COPYRIGHT_SIZE 1150.0, 150.0
#elif _Copyright_Texture_Source == 5 // With GShade Dark
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_by_gshade_dark.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 120.0
#elif _Copyright_Texture_Source == 6 // With GShade White
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_by_gshade_white.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 120.0
#elif _Copyright_Texture_Source == 7 // Montserrat
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_montserrat.png"
#define _SOURCE_COPYRIGHT_SIZE 950.0, 120.0
#elif _Copyright_Texture_Source == 8 // Montserrat Simple
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_montserrat_simple.png"
#define _SOURCE_COPYRIGHT_SIZE 950.0, 120.0
#elif _Copyright_Texture_Source == 9 // With Flat Logo
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_frutiger_with_flat_logo.png"
#define _SOURCE_COPYRIGHT_SIZE 1100.0, 120.0
#elif _Copyright_Texture_Source == 10 // Eurostile
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 60.0
#elif _Copyright_Texture_Source == 11 // Metro No. 2 Cutout
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_metro_no.2_cutout.png"
#define _SOURCE_COPYRIGHT_SIZE 850.0, 150.0
#elif _Copyright_Texture_Source == 12 // Kranky
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_kranky.png"
#define _SOURCE_COPYRIGHT_SIZE 1300.0, 150.0
#elif _Copyright_Texture_Source == 13 // GN Fuyu-iro Script
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_gn-fuyu-iro_script.png"
#define _SOURCE_COPYRIGHT_SIZE 850.0, 200.0
#elif _Copyright_Texture_Source == 14 // Sacramento
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sacramento.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 150.0
#elif _Copyright_Texture_Source == 15 // Century Rectangle
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_century_rectangle.png"
#define _SOURCE_COPYRIGHT_SIZE 850.0, 250.0
#elif _Copyright_Texture_Source == 16 // Eurostile Left
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile_left.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 250.0
#elif _Copyright_Texture_Source == 17 // Eurostile Right
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile_right.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 250.0
#elif _Copyright_Texture_Source == 18 // Eurostile Center
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_eurostile_center.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 250.0
#elif _Copyright_Texture_Source == 19 // Sophia DF Rectangle
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sophia_df_5.png"
#define _SOURCE_COPYRIGHT_SIZE 950.0, 400.0
#elif _Copyright_Texture_Source == 20 // Futura Center
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_center.png"
#define _SOURCE_COPYRIGHT_SIZE 850.0, 200.0
#elif _Copyright_Texture_Source == 21 // Sophia DF Center
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sophia_df_4.png"
#define _SOURCE_COPYRIGHT_SIZE 950.0, 300.0
#elif _Copyright_Texture_Source == 22 // Neuzeit Grotesk
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_neuzeit_grotesk.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 350.0
#elif _Copyright_Texture_Source == 23 // Krona One
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_krona_one.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 300.0
#elif _Copyright_Texture_Source == 24 // Grand Mater
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_grandmaster_ngs_2.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 400.0
#elif _Copyright_Texture_Source == 25 // Mouse Memories
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_mouse_memories.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 300.0
#elif _Copyright_Texture_Source == 26 // Swanky And Moo Moo
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_swanky_and_moo_moo.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 150.0
#elif _Copyright_Texture_Source == 27 // Staccato555 A
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_staccato555_a.png"
#define _SOURCE_COPYRIGHT_SIZE 850.0, 400.0
#elif _Copyright_Texture_Source == 28 // Staccato555 B
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_staccato555_b.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 350.0
#elif _Copyright_Texture_Source == 29 // Lato Cutout
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_lato_cutout.png"
#define _SOURCE_COPYRIGHT_SIZE 650.0, 250.0
#elif _Copyright_Texture_Source == 30 // Rockwell Nova
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_rockwell_nova.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 150.0
#elif _Copyright_Texture_Source == 31 // Kabel Heavy
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_kabel_heavy.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 200.0
#elif _Copyright_Texture_Source == 32 // Sophia DF SEGA
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sophia_df_6.png"
#define _SOURCE_COPYRIGHT_SIZE 550.0, 250.0
#elif _Copyright_Texture_Source == 33 // Sophia DF SEGA 2
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sophia_df_8.png"
#define _SOURCE_COPYRIGHT_SIZE 550.0, 150.0
#elif _Copyright_Texture_Source == 34 // Sophia DF PSO2
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sophia_df_7.png"
#define _SOURCE_COPYRIGHT_SIZE 650.0, 300.0
#elif _Copyright_Texture_Source == 35 // Poiret One Small
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_poiret_one.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 250.0
#elif _Copyright_Texture_Source == 36 // Poiret One Large
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_poiret_one_huge.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 550.0
#elif _Copyright_Texture_Source == 37 // Kranky Large
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_kranky_large.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 350.0
#elif _Copyright_Texture_Source == 38 // Futura Triangle
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_futura_tri.png"
#define _SOURCE_COPYRIGHT_SIZE 350.0, 450.0
#elif _Copyright_Texture_Source == 39 // Sophia DF Triangle
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_sophia_df_tri.png"
#define _SOURCE_COPYRIGHT_SIZE 350.0, 450.0
#elif _Copyright_Texture_Source == 40 // Helvetica Square
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_helvetica(Swis721)_square.png"
#define _SOURCE_COPYRIGHT_SIZE 350.0, 400.0
#elif _Copyright_Texture_Source == 41 // Righteous
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_righteous.png"
#define _SOURCE_COPYRIGHT_SIZE 550.0, 300.0
#elif _Copyright_Texture_Source == 42 // Poppins
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_poppins.png"
#define _SOURCE_COPYRIGHT_SIZE 650.0, 200.0
#elif _Copyright_Texture_Source == 43 // Bank Gothic
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_bank_gothic.png"
#define _SOURCE_COPYRIGHT_SIZE 650.0, 300.0
#elif _Copyright_Texture_Source == 44 // Flat Logo
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_flat_logo.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 400.0
#elif _Copyright_Texture_Source == 45 // Yanone Kaffeesatz A
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_yanone_kaffeesatz_square.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 400.0
#elif _Copyright_Texture_Source == 46 // Yanone Kaffeesatz B
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2_yanone_kaffeesatz_square_2.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 400.0
#elif _Copyright_Texture_Source == 47 // Custom
#define _SOURCE_COPYRIGHT_FILE cLayerTex
#define _SOURCE_COPYRIGHT_SIZE cLayer_SIZE_X, cLayer_SIZE_Y
#else 
#define _SOURCE_COPYRIGHT_FILE "copyright_pso2.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 60.0
#endif
