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

*/

// -------------------------------------
// Texture Macros
// -------------------------------------

#undef TEXTURE_COMBO
#define TEXTURE_COMBO(variable, name_label, description) \
uniform int variable \
< \
    ui_items = \
               "FFXIV\0" \
               "FFXIV Nalukai\0" \
               "FFXIV Yomi Black\0" \
               "FFXIV Yomi White\0" \
               "FFXIV Poppins Rectangle\0" \
               "FFXIV Helvetica\0" \
               "FFXIV Caslon Old Face\0" \
               "FFXIV Baskerville\0" \
               "FFXIV Josefin Slab\0" \
               "FFXIV Andante\0" \
               "FFXIV Codex\0" \
               "FFXIV Empire\0" \
               "FFXIV With GShade Dark\0" \
               "FFXIV With GShade White\0" \
               "FFXIV Poppins\0" \
               "FFXIV Euphoria Script\0" \
               "FFXIV Copperplate Gothic\0" \
               "FFXIV uchu suzume's Kabel\0" \
               "FFXIV Gill Sans Framed\0" \
               "FFXIV Gill Sans Framed 2\0" \
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

// (?<=Source == )[\d]{0,999} Regular expression for renumbering. Make sure this line doesn't hit.

#if   _Copyright_Texture_Source == 0 // FFXIV Vanilla
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0
#elif _Copyright_Texture_Source == 1 // FFXIV Nalukai
#define _SOURCE_COPYRIGHT_FILE "CopyrightF4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1162.0, 135.0
#elif _Copyright_Texture_Source == 2 // FFXIV Yomi Black
#define _SOURCE_COPYRIGHT_FILE "CopyrightYBlH.png"
#define _SOURCE_COPYRIGHT_SIZE 843.0, 103.0
#elif _Copyright_Texture_Source == 3 // FFXIV Yomi White
#define _SOURCE_COPYRIGHT_FILE "CopyrightYWhH.png"
#define _SOURCE_COPYRIGHT_SIZE 843.0, 103.0
#elif _Copyright_Texture_Source == 4 // FFXIV Poppins Rectangle
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_poppins_rectangle.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 180.0
#elif _Copyright_Texture_Source == 5 // FFXIV Helvetica
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_swiss721(Helvetica).png"
#define _SOURCE_COPYRIGHT_SIZE 680.0, 300.0
#elif _Copyright_Texture_Source == 6 // Caslon Old Face
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_caslon_old_face.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 250.0
#elif _Copyright_Texture_Source == 7 // Basker Ville
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_baskerville.png"
#define _SOURCE_COPYRIGHT_SIZE 830.0, 300.0
#elif _Copyright_Texture_Source == 8 // Josefin Slab
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_josefin_slab.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 350.0
#elif _Copyright_Texture_Source == 9 // Andante
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_andante.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 250.0
#elif _Copyright_Texture_Source == 10 // Codex
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_codex.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 300.0
#elif _Copyright_Texture_Source == 11 // Empire
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_empire.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 350.0
#elif _Copyright_Texture_Source == 12 // FFXIV With GShade Dark
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_by_gshade_dark_1550.png"
#define _SOURCE_COPYRIGHT_SIZE 1550.0, 100.0
#elif _Copyright_Texture_Source == 13 // FFXIV With GShade White
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_by_gshade_light_1550.png"
#define _SOURCE_COPYRIGHT_SIZE 1550.0, 100.0
#elif _Copyright_Texture_Source == 14 // FFXIV Poppins
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_poppins.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 60.0
#elif _Copyright_Texture_Source == 15 // FFXIV Euphoria Script
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_euphoriascript.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 120.0
#elif _Copyright_Texture_Source == 16 // FFXIV Copperplate Gothic
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_copperplate.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 100.0
#elif _Copyright_Texture_Source == 17 // FFXIV uchu suzume's Kabel
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_geometric231(Kabel)_square.png"
#define _SOURCE_COPYRIGHT_SIZE 550.0, 500.0
#elif _Copyright_Texture_Source == 18 // FFXIV Gill Sans Framed
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_gill_sans_nova_framed.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 330.0
#elif _Copyright_Texture_Source == 19 // FFXIV Gill Sans Framed 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_gill_sans_nova_framed_2.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 500.0
#elif _Copyright_Texture_Source == 20 // Custom
#define _SOURCE_COPYRIGHT_FILE cLayerTex
#define _SOURCE_COPYRIGHT_SIZE cLayer_SIZE_X, cLayer_SIZE_Y
#endif