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
               "Kabel\0" \
               "Neneko Fipps\0"\
               "Neneko Foglihten No.07\0"\
               "Neneko 000webfont\0"\
               "Neneko !Sketchy Times\0"\
               "Neneko Arual\0"\
               "Poppins\0" \
               "Sophia DF 4.5\0" \
               "Meridien\0" \
               "Euphoria Script\0" \
               "Grandmaster\0" \
               "Midnight Sun DF\0" \
               "With GShade Dark\0" \
               "With GShade White\0" \
               "-------------------------------------------------\0" \
               "Gill Sans\0" \
               "Sophia DF 4\0" \
               "Midnight Sun DF 2\0" \
               "Grandmaster 2.5\0" \
               "-------------------------------------------------\0" \
               "Frutiger XCn\0" \
               "Poppins Rectangle\0" \
               "Futura Large\0" \
               "Sophia DF Large\0" \
               "Sophia DF Large 2\0" \
               "Sophia DF\0" \
               "Meridien Large\0" \
               "Caslon Old Face\0" \
               "Andante\0" \
               "Tokyosign\0" \
               "Candlelight\0" \
               "Helvetica\0" \
               "-------------------------------------------------\0" \
               "Futura\0" \
               "Sophia DF 3\0" \
               "Copperplate Gothic\0" \
               "Grandmaster 2\0" \
               "-------------------------------------------------\0" \
               "Baskerville\0" \
               "Josefin Slab\0" \
               "Josefin Slab 2\0" \
               "Codex\0" \
               "Empire\0" \
               "Rachel DF\0" \
               "-------------------------------------------------\0" \
               "Futura 2\0" \
               "Futura Square\0" \
               "Sophia DF Square\0" \
               "Sophia DF 2\0" \
               "Meridian Square\0" \
               "Stymie Square\0" \
               "Stymie Square 2\0" \
               "Broadway Square\0" \
               "Grandmaster 3\0" \
               "Bernhard Neo DF\0" \
               "Super Bodoni DF\0" \
               "Bungee Shade\0" \
               "Bernhard Neo DF 2\0" \
               "Grandmaster 4\0" \
               "-------------------------------------------------\0" \
               "Gill Sans Framed\0" \
               "Gill Sans Framed 2\0" \
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

#if   _Copyright_Texture_Source == 0 // FFXIV Vanilla
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 100.0
#elif _Copyright_Texture_Source == 1 // Nalukai
#define _SOURCE_COPYRIGHT_FILE "CopyrightF4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1250.0, 200.0
#elif _Copyright_Texture_Source == 2 // Yomi
#define _SOURCE_COPYRIGHT_FILE "CopyrightYWhH.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 150.0
#elif _Copyright_Texture_Source == 3 // Kabel
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_geometric231(Kabel)_square.png"
#define _SOURCE_COPYRIGHT_SIZE 550.0, 500.0
#elif _Copyright_Texture_Source == 4 // Neneko Fipps
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_neneko_fipps.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 250.0
#elif _Copyright_Texture_Source == 5 // Neneko Foglihten No.07
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_neneko_foglihten_no07.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 250.0
#elif _Copyright_Texture_Source == 6 // Neneko 000webfont
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_neneko_000webfont.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 400.0
#elif _Copyright_Texture_Source == 7 // Neneko !Sketchy Times
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_neneko_!sketchy_times.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 350.0
#elif _Copyright_Texture_Source == 8 // Neneko Arual Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_neneko_arual.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 600.0
#elif _Copyright_Texture_Source == 9 // Poppins
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_poppins.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 60.0
#elif _Copyright_Texture_Source == 10 // Sophia DF 4.5
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df_4.5.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 100.0
#elif _Copyright_Texture_Source == 11 // Meridian
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_meridien.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 100.0
#elif _Copyright_Texture_Source == 12 // Euphoria Script
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_euphoriascript.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 120.0
#elif _Copyright_Texture_Source == 13 // Grandmaster
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_grandmaster.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 200.0
#elif _Copyright_Texture_Source == 14 // Midnightsun DF
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_midnightsun_df.png"
#define _SOURCE_COPYRIGHT_SIZE 950.0, 100.0
#elif _Copyright_Texture_Source == 15 // GShade Dark
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_by_gshade_dark_1550.png"
#define _SOURCE_COPYRIGHT_SIZE 1550.0, 100.0
#elif _Copyright_Texture_Source == 16 // GShade White
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_by_gshade_light_1550.png"
#define _SOURCE_COPYRIGHT_SIZE 1550.0, 100.0
#elif _Copyright_TextureNGS_Source == 17 // -------------------------------------------border line---------------------------------------------
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1450.0, 100.0
#elif _Copyright_Texture_Source == 18 // Gill Sans
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_gill_sans.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 150.0
#elif _Copyright_Texture_Source == 19 // Sophia DF 4
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df_4.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 200.0
#elif _Copyright_Texture_Source == 20 // Midnightsun DF 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_midnightsun_df_2.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 200.0
#elif _Copyright_Texture_Source == 21 // Grandmaster 2.5
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_grandmaster_2.5.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 500.0
#elif _Copyright_TextureNGS_Source == 22 // -------------------------------------------border line---------------------------------------------
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1450.0, 100.0
#elif _Copyright_Texture_Source == 23 // Frutiger XCn
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_frutiger_xcn.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 300.0
#elif _Copyright_Texture_Source == 24 // Poppins Rectangle
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_poppins_rectangle.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 180.0
#elif _Copyright_Texture_Source == 25 // Futura Large
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_futura_large.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 250.0
#elif _Copyright_Texture_Source == 26 // Sophia DF Large
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df_large.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 300.0
#elif _Copyright_Texture_Source == 27 // Sophia DF Large 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df_large_2.png"
#define _SOURCE_COPYRIGHT_SIZE 1200.0, 300.0
#elif _Copyright_Texture_Source == 28 // Sophia DF
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 400.0
#elif _Copyright_Texture_Source == 29 // Meridien Large
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_meridien_large.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 300.0
#elif _Copyright_Texture_Source == 30 // Caslon Old Face
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_caslon_old_face.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 250.0
#elif _Copyright_Texture_Source == 31 // Andante
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_andante.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 250.0
#elif _Copyright_Texture_Source == 32 // Tokyosign
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_tokyosign.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 300.0
#elif _Copyright_Texture_Source == 33 // Candlelight
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_candlelight.png"
#define _SOURCE_COPYRIGHT_SIZE 1000.0, 200.0
#elif _Copyright_Texture_Source == 34 // Helvetica
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_swiss721(Helvetica).png"
#define _SOURCE_COPYRIGHT_SIZE 680.0, 300.0
#elif _Copyright_TextureNGS_Source == 35 // -------------------------------------------border line---------------------------------------------
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1450.0, 100.0
#elif _Copyright_Texture_Source == 36 // Futura
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_futura.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 250.0
#elif _Copyright_Texture_Source == 37 // Sophia DF 3
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df_3.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 200.0
#elif _Copyright_Texture_Source == 38 // Copperplate Gothic
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_copperplate.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 100.0
#elif _Copyright_Texture_Source == 39 // Grandmaster 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_grandmaster_2.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 500.0
#elif _Copyright_TextureNGS_Source == 40 // -------------------------------------------border line---------------------------------------------
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1450.0, 100.0
#elif _Copyright_Texture_Source == 41 // Basker Ville
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_baskerville.png"
#define _SOURCE_COPYRIGHT_SIZE 830.0, 300.0
#elif _Copyright_Texture_Source == 42 // Josefin Slab
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_josefin_slab.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 350.0
#elif _Copyright_Texture_Source == 43 // Josefin Slab 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_josefin_slab_2.png"
#define _SOURCE_COPYRIGHT_SIZE 700.0, 350.0
#elif _Copyright_Texture_Source == 44 // Codex
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_codex.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 300.0
#elif _Copyright_Texture_Source == 45 // Empire
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_empire.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 350.0
#elif _Copyright_Texture_Source == 46 // Rachel DF
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_rachel_df.png"
#define _SOURCE_COPYRIGHT_SIZE 900.0, 550.0
#elif _Copyright_TextureNGS_Source == 47 // -------------------------------------------border line---------------------------------------------
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1450.0, 100.0
#elif _Copyright_Texture_Source == 48 // Futura 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_futura_2.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 300.0
#elif _Copyright_Texture_Source == 49 // Futura Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_futura_square.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 400.0
#elif _Copyright_Texture_Source == 50 // Sophia DF Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df_square.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 400.0
#elif _Copyright_Texture_Source == 51 // Sophia DF 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_sophia_df_2.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 400.0
#elif _Copyright_Texture_Source == 52 // Meridian Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_meridien_square.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 500.0
#elif _Copyright_Texture_Source == 53 // Stymie Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_stymie_square.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 400.0
#elif _Copyright_Texture_Source == 54 // Stymie Square 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_stymie_square_2.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 500.0
#elif _Copyright_Texture_Source == 55 // Broadway Square
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_broadway.png"
#define _SOURCE_COPYRIGHT_SIZE 800.0, 500.0
#elif _Copyright_Texture_Source == 56 // Grandmaster 3
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_grandmaster_3.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 700.0
#elif _Copyright_Texture_Source == 57 // Bernhard Neo DF
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_bernhard_neo_df.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 500.0
#elif _Copyright_Texture_Source == 58 // Super Bodoni DF
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_super_bodoni_df.png"
#define _SOURCE_COPYRIGHT_SIZE 750.0, 500.0
#elif _Copyright_Texture_Source == 59 // Bungee Shade
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_bungee_shade.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 300.0
#elif _Copyright_Texture_Source == 60 // Bernhard Neo DF 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_bernhard_neo_df_2.png"
#define _SOURCE_COPYRIGHT_SIZE 400.0, 700.0
#elif _Copyright_Texture_Source == 61 // Grandmaster 4
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_grandmaster_4.png"
#define _SOURCE_COPYRIGHT_SIZE 250.0, 1200.0
#elif _Copyright_TextureNGS_Source == 62 // -------------------------------------------border line---------------------------------------------
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1450.0, 100.0
#elif _Copyright_Texture_Source == 63 // Gill Sans Framed
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_gill_sans_nova_framed.png"
#define _SOURCE_COPYRIGHT_SIZE 600.0, 300.0
#elif _Copyright_Texture_Source == 64 // Gill Sans Framed 2
#define _SOURCE_COPYRIGHT_FILE "copyright_ffxiv_gill_sans_nova_framed_2.png"
#define _SOURCE_COPYRIGHT_SIZE 500.0, 500.0
#else // Default
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0
#endif
