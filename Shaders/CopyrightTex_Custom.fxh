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

#define TEXTURE_COMBO(variable, name_label, description) \
uniform int variable \
< \
    ui_items = \
               "Logo 00\0" \/* Name displayed in Dropdown. Logo 00の部分を書き換えることでGShadeのUI上で表示される名前を任意のものに変更できます。 */
               "Logo 01\0" \/* Leave symbols / and ". スラッシュやダブルクォーテーション等は動作上必要なものなので書き換える際は注意してください。 */
               "Logo 02\0" \
               "Logo 03\0" \
               "Logo 04\0" \
               "Logo 05\0" \
               "Logo 06\0" \
               "Logo 07\0" \
               "Logo 08\0" \
               "Logo 09\0" \
               "Logo 10\0" \
               "-------------------------------------------------\0" \/* Use this partition if you need. よければロゴの種類が増えた時に仕切りとしてお使いください。 */
               ; \/* This ; marking an end of the list. Do not delete. ここのセミコロン(;)はリストの終わりを表すものなので、間違って消すとエラーになります。*/
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

// (?<=Source == )[\d][\S+]{0,999} Regular expression for renumbering. 連番修正用の正規表現。VSCode等のエディタと連番入力機能用。

#if _Copyright_Texture_Source == 0 // Logo 00        Textures are matched by number here and in the drop-down lines. この番号とドロップダウンの行でテクスチャを照合しています。面倒ですがリストを入れ替えたりした時は番号の並びも直してください。
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png" // Name for textures including extension. 表示するテクスチャのファイル名(.pngまで含めないとチェックに通らずエラーが出ます。
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0       // Cannot be known by error if value is wrong. Make sure to type correctly. テクスチャの横解像度、縦解像度。数値が間違っていてもエラーメッセージは出ないので注意してください。

#elif _Copyright_Texture_Source == 1 // Logo 01
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 2 // Logo 02
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 3 // Logo 03
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 4 // Logo 04
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 5 // Logo 05
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 6 // Logo 06
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 7 // Logo 07
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 8 // Logo 08
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 9 // Logo 09
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 10 // Logo 10
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#elif _Copyright_Texture_Source == 11 // -------------------------------------------border line---------------------------------------------
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0

#else // To avoid errors when changing list and the list doesn't have a matching number. 別のリストを変更した時に変更先のリストに対応したテクスチャ番号存在しない場合、エラーを回避するためここを参照します。
#define _SOURCE_COPYRIGHT_FILE "Copyright4kH.png"
#define _SOURCE_COPYRIGHT_SIZE 1400.0, 80.0
#endif
