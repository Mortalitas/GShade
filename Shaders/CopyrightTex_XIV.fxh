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
               "Nalukai\0" \
               "Yomi\0" \
               "Neneko Fipps\0"\
               "Neneko Foglihten No.07\0"\
               "Neneko 000webfont\0"\
               "Neneko !Sketchy Times\0"\
               "Neneko Arual\0"\
               "Poppins\0" \
               "Meridien\0" \
               "Poppins Rectangle\0" \
               "Helvetica\0" \
               "Futura\0" \
               "Futura Large\0" \
               "Sophia DF\0" \
               "Frutiger XCn\0" \
               "Meridien Large\0" \
               "Caslon Old Face\0" \
               "Baskerville\0" \
               "Josefin Slab\0" \
               "Andante\0" \
               "Codex\0" \
               "Empire\0" \
               "With GShade Dark\0" \
               "With GShade White\0" \
               "Euphoria Script\0" \
               "Copperplate Gothic\0" \
               "Sophia DF 2\0" \
               "Rachel DF\0" \
               "Kabel\0" \
               "Futura Square\0" \
               "Sophia DF Square\0" \
               "Meridian Square\0" \
               "Stymie Square\0" \
               "Stymie Square 2\0" \
               "Broadway Square\0" \
               "Super Bodoni DF\0" \
               "Bungee Shade\0" \
               "Gill Sans Framed\0" \
               "Gill Sans Framed 2\0" \
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

#if   _Copyright_Texture_Source == 0 // FFXIV Vanilla
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1450.0, 100.0
#elif _Copyright_Texture_Source == 1 // Nalukai
#define _SOURCE_COPYRIGHT_FILE "CopyrightF4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1250.0, 200.0
#elif _Copyright_Texture_Source == 2 // Yomi
#define _SOURCE_COPYRIGHT_FILE "CopyrightYWhH.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 150.0
#elif _Copyright_Texture_Source == 3 // Neneko Fipps
#define _SOURCE_COPYRIGHT_FILE "copyright_neneko_fipps.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 250.0
#elif _Copyright_Texture_Source == 4 // Neneko Foglihten No.07
#define _SOURCE_COPYRIGHT_FILE "copyright_neneko_foglihten_no07.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 250.0
#elif _Copyright_Texture_Source == 5 // Neneko 000webfont
#define _SOURCE_COPYRIGHT_FILE "copyright_neneko_000webfont.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 400.0
#elif _Copyright_Texture_Source == 6 // Neneko !Sketchy Times
#define _SOURCE_COPYRIGHT_FILE "copyright_neneko_!sketchy_times.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 350.0
#elif _Copyright_Texture_Source == 7 // Neneko Arual Square
#define _SOURCE_COPYRIGHT_FILE "copyright_neneko_arual.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 600.0
#elif _Copyright_Texture_Source == 8 // Poppins
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_poppins.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 60.0
#elif _Copyright_Texture_Source == 9 // Meridian
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_meridien.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 100.0
#elif _Copyright_Texture_Source == 10 // Poppins Rectangle
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_poppins_rectangle.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 180.0
#elif _Copyright_Texture_Source == 11 // Helvetica
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_swiss721(Helvetica).png"
#define _SOURCE_COPYRIGHT_SIZE 680.0, 300.0
#elif _Copyright_Texture_Source == 12 // Futura
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_futura.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 250.0
#elif _Copyright_Texture_Source == 13 // Futura Large
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_futura_large.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 250.0
#elif _Copyright_Texture_Source == 14 // Sophia DF
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 400.0
#elif _Copyright_Texture_Source == 15 // Frutiger XCn
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_frutiger_xcn.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 300.0
#elif _Copyright_Texture_Source == 16 // Meridien Large
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_meridien_large.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 300.0
#elif _Copyright_Texture_Source == 17 // Caslon Old Face
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_caslon_old_face.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 250.0
#elif _Copyright_Texture_Source == 18 // Basker Ville
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_baskerville.png"
#define _SOURCE_COPYRIGHT_SIZE 830.0, 300.0
#elif _Copyright_Texture_Source == 19 // Josefin Slab
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_josefin_slab.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 350.0
#elif _Copyright_Texture_Source == 20 // Andante
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_andante.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 250.0
#elif _Copyright_Texture_Source == 21 // Codex
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_codex.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 300.0
#elif _Copyright_Texture_Source == 22 // Empire
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_empire.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 350.0
#elif _Copyright_Texture_Source == 23 // GShade Dark
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_by_gshade_dark_1550.png"
#define _SOURCE_COPYRIGHT_SIZE 1550.0, 100.0
#elif _Copyright_Texture_Source == 24 // GShade White
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_by_gshade_light_1550.png"
#define _SOURCE_COPYRIGHT_SIZE 1550.0, 100.0
#elif _Copyright_Texture_Source == 25 // Euphoria Script
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_euphoriascript.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 120.0
#elif _Copyright_Texture_Source == 26 // Copperplate Gothic
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_copperplate.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 100.0
#elif _Copyright_Texture_Source == 27 // Sophia DF 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df_2.png"
#define _SOURCE_COPYRIGHT_SIZE 550.0, 400.0
#elif _Copyright_Texture_Source == 28 // Rachel DF
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_rachel_df.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 550.0
#elif _Copyright_Texture_Source == 29 // Kabel
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_geometric231(Kabel)_square.png"
#define _SOURCE_COPYRIGHT_SIZE 550.0, 500.0
#elif _Copyright_Texture_Source == 30 // Futura Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_futura_square.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 400.0
#elif _Copyright_Texture_Source == 31 // Sophia DF Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df_square.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 400.0
#elif _Copyright_Texture_Source == 32 // Meridian Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_meridien_square.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 500.0
#elif _Copyright_Texture_Source == 33 // Stymie Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_stymie_square.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 400.0
#elif _Copyright_Texture_Source == 34 // Stymie Square 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_stymie_square_2.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 500.0
#elif _Copyright_Texture_Source == 35 // Broadway Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_broadway.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 500.0
#elif _Copyright_Texture_Source == 36 // Super Bodoni DF
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_super_bodoni_df.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 500.0
#elif _Copyright_Texture_Source == 37 // Bungee Shade
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_bungee_shade.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 300.0
#elif _Copyright_Texture_Source == 38 // Gill Sans Framed
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_gill_sans_nova_framed.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 330.0
#elif _Copyright_Texture_Source == 39 // Gill Sans Framed 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_gill_sans_nova_framed_2.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 500.0
#elif _Copyright_Texture_Source == 40    // Custom
#define _SOURCE_COPYRIGHT_FILE cLayerTex
#define _SOURCE_COPYRIGHT_SIZE cLayer_SIZE_X, cLayer_SIZE_Y
#else // Default
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0
#endif