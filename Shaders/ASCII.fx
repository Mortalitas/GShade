/*------------------.
| :: Description :: |
'-------------------/

	Ascii (Version 0.9)

  	Author: CeeJay.dk
	License: MIT

	About:
	Converts the image to ASCII characters using a greyscale algoritm,
	cherrypicked characters and a custom bitmap font stored in a set of floats.
	
	It has 17 gray levels but uses dithering to greatly increase that number.

	Ideas for future improvement:
	* Cleanup code
	* Maybe find a better/faster pattern - possibly blur the pixels first with a 2 pass aproach
	* Try using a font atlas for more fonts or perhaps more performance
	* Try making an ordered dither rather than the random one. I think the random looks a bit too noisy.
	* Calculate luma from linear colorspace

	History:
	(*) Feature (+) Improvement	(x) Bugfix (-) Information (!) Compatibility

	Version 0.7 by CeeJay.dk
	* Added the 3x5 font

	Version 0.8 by CeeJay.dk 
	+ Cleaned up settings UI for Reshade 3.x
	
	Version 0.9 by CeeJay.dk
	x Fixed an issue with the settings where the 3x5 could not be selected.
	- Cleaned up and commented the code. More cleanup is still needed.
	* Added the ability to toggle dithering on/off
	x Removed temporal dither code due to incompatibility with humans - it was giving me headaches and I didn't want to cause anyones seizure
	x Fixed an uneven distribution of the greyscale shades
	
  Version 0.9.1 by Marot
  + Minor code modifications for Reshade 4.x compatibility.
*/


/*---------------.
| :: Includes :: |
'---------------*/

#include "ReShade.fxh"


/*------------------.
| :: UI Settings :: |
'------------------*/

uniform int Ascii_spacing <
	ui_type = "slider";
	ui_min = 0;
	ui_max = 5;
	ui_label = "Character Spacing";
	ui_tooltip = "Determines the spacing between characters. I feel 1 to 3 looks best.";
	ui_category = "Font style";
> = 1;

uniform int Ascii_font <
	ui_type = "combo";
	ui_label = "Font Size";
	ui_tooltip = "Choose font size";
	ui_category = "Font style";
	ui_items = 
	"Smaller 3x5 font\0"
	"Normal 5x5 font\0"
	;
> = 1;

uniform int Ascii_font_color_mode < 
	ui_type = "slider";
	ui_min = 0;
	ui_max = 2;
	ui_label = "Font Color Mode";
	ui_tooltip = "0 = Foreground color on background color, 1 = Colorized grayscale, 2 = Full color";
	ui_category = "Color options";
> = 1;

uniform float3 Ascii_font_color <
	ui_type = "color";
	ui_label = "Font Color";
	ui_tooltip = "Choose a font color";
	ui_category = "Color options";
> = float3(1.0, 1.0, 1.0);

uniform float3 Ascii_background_color <
	ui_type = "color";
	ui_label = "Background Color";
	ui_tooltip = "Choose a background color";
	ui_category = "Color options";
> = float3(0.0, 0.0, 0.0);

uniform bool Ascii_swap_colors <
	ui_label = "Swap Colors";
	ui_tooltip = "Swaps the font and background color when you are too lazy to edit the settings above (I know I am)";
	ui_category = "Color options";
> = 0;

uniform bool Ascii_invert_brightness <
	ui_label = "Invert Brightness";
	ui_category = "Color options";
> = 0;

uniform bool Ascii_dithering <
	ui_label = "Dithering";
	ui_category = "Dithering";
> = 1;

uniform float Ascii_dithering_intensity <
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 4.0;
	ui_label = "Dither shift intensity";
	ui_tooltip = "For debugging purposes";
	ui_category = "Debugging";
> = 2.0;

uniform bool Ascii_dithering_debug_gradient <
	ui_label = "Dither debug gradient";
	ui_category = "Debugging";
> = 0;

/*-------------------------.
| :: Sampler and timers :: |
'-------------------------*/

#define asciiSampler ReShade::BackBuffer

uniform float timer < source = "timer"; >;
uniform float framecount < source = "framecount"; >;

/*-------------------.
| :: Sub-Routines :: |
'-------------------*/

// !!! after switching to step func for
// !!! quantizing which char to use, a
// !!! loop to go through each quant level
// !!! and add up the index with steps seemed
// !!! like a more useful, re-useable choice.
// !!! however, it doesn't seem to run as
// !!! good as the dot(step) hand-coded
// !!! parts. But, keeping the func here,
// !!! b/c if more ASCII font sizes get
// !!! added to this code, it may be more
// !!! efficient to switch back to using
// !!! this loop func in "fire-n-forget"
// !!! fashion instead of manually writing
// !!! out all the dot(step)s for each one.

// !!! start with quant*2
// !!! end   with quant*chararraylen
// !!! go through each to see if value < gray (gray >= value)
// !!! if it is, add the step 1 to index
// !!! to generate index to pull character
// !!! to use from char array.

int charindex( float quant, float gray, int chararraylen )
{
	float q = quant;
	int index = 0;

	[unroll]
	for ( int i = 0; i < chararraylen; i++ )
	{
		q += quant;
		index += step( q, gray );
	}

	return index;
}

/*-------------.
| :: Effect :: |
'-------------*/

// modified - Craig - Jul 8th, 2020
// !!! indented AsciiPass contents,
// !!! b/c hard to tell where func started / ended

float3 AsciiPass( float2 tex )
{
	/*-------------------------.
	| :: Sample and average :: |
	'-------------------------*/

	//if (Ascii_font != 1)
	float2 Ascii_font_size = float2(3.0,5.0); //3x5
	float num_of_chars = 14. ; 

	if (Ascii_font == 1)
	{
		Ascii_font_size = float2(5.0,5.0); //5x5
		num_of_chars = 17.; 
	}

	float quant = 1.0/(num_of_chars-1.0); //value used for quantization 

	const float2 Ascii_block = Ascii_font_size + float(Ascii_spacing);
	const float2 cursor_position = trunc((BUFFER_SCREEN_SIZE / Ascii_block) * tex) * (Ascii_block / BUFFER_SCREEN_SIZE);
	
	// !!! cleaned it up a bit by pre-calc'ing texcoords/offsets.
	const float2 cp15 = cursor_position + BUFFER_PIXEL_SIZE * 1.5;
	const float2 cp35 = cursor_position + BUFFER_PIXEL_SIZE * 3.5;
	const float2 cp55 = cursor_position + BUFFER_PIXEL_SIZE * 5.5;

	float3 color = tex2D(asciiSampler, float2( cp15.x, cp15.y )).rgb;
	color += tex2D(asciiSampler, float2( cp15.x, cp35.y )).rgb;
	color += tex2D(asciiSampler, float2( cp15.x, cp55.y )).rgb;
	color += tex2D(asciiSampler, float2( cp35.x, cp15.y )).rgb;
	color += tex2D(asciiSampler, float2( cp35.x, cp35.y )).rgb;
	color += tex2D(asciiSampler, float2( cp35.x, cp55.y )).rgb;
	color += tex2D(asciiSampler, float2( cp55.x, cp15.y )).rgb;
	color += tex2D(asciiSampler, float2( cp55.x, cp35.y )).rgb;
	color += tex2D(asciiSampler, float2( cp55.x, cp55.y )).rgb;

	// !!! this is avg'ing the color, so if you uncomment
	// !!! extra lines above, you'll need to modify the divisor
	color /= 9.0;

	/*------------------------.
	| :: Make it grayscale :: |
	'------------------------*/

	float gray = dot(color,float3(0.2126, 0.7152, 0.0722));

	if (Ascii_invert_brightness)
		gray = 1.0 - gray;


	/*----------------.
	| :: Debugging :: |
	'----------------*/

	if (Ascii_dithering_debug_gradient)
	{
		gray = cursor_position.x; //horizontal test gradient
	}

	/*-------------------.
	| :: Get position :: |
	'-------------------*/

	const float2 p = trunc(frac((BUFFER_SCREEN_SIZE / Ascii_block) * tex) * Ascii_block); //p is the position of the current pixel inside the character

	const float x = (Ascii_font_size.x * p.y + p.x); //x is the number of the position in the bitfield

	/*----------------.
	| :: Dithering :: |
	'----------------*/

	//TODO : Try make an ordered dither rather than the random dither. Random looks a bit too noisy for my taste.	

	if (Ascii_dithering != 0)
	{
	//Pseudo Random Number Generator
	// -- PRNG 1 - Reference --
	const float seed = dot(cursor_position, float2(12.9898,78.233)); //I could add more salt here if I wanted to
	const float sine = sin(seed); //cos also works well. Sincos too if you want 2D noise.
	const float noise = frac(sine * 43758.5453 + cursor_position.y);

	float dither_shift = (quant * Ascii_dithering_intensity); // Using noise to determine shift.

	const float dither_shift_half = (dither_shift * 0.5); // The noise should vary between +- 0.5
	dither_shift = dither_shift * noise - dither_shift_half; // MAD

	//shift the color by dither_shift
	gray += dither_shift; //apply dithering
	}

	/*---------------------------.
	| :: Convert to character :: |
	'---------------------------*/

	float n = 0;

	if (Ascii_font == 1)
	{	
		// -- 5x5 bitmap font by CeeJay.dk --
		// .:^"~cvo*wSO8Q0#
		//17 characters including space which is handled as a special case
		// !!! taking it a step further, we can
		// !!! chuck the chars into an array, then
		// !!! use step to compare the quants to the gray
		// !!! value, and dots to sum up the # of 1's vs. 0's we get
		// !!! to generate an index value for the char to use.

		float	chars[16];
			chars[0]  = 4194304.0;
			chars[1]  = 131200.00;
			chars[2]  = 324.00000;
			chars[3]  = 330.00000;
			chars[4]  = 283712.00;
			chars[5]  = 12650880.;
			chars[6]  = 4532768.0;
			chars[7]  = 13191552.;
			chars[8]  = 10648704.;
			chars[9]  = 11195936.;
			chars[10] = 15218734.;
			chars[11] = 15255086.;
			chars[12] = 15252014.;
			chars[13] = 32294446.;
			chars[14] = 15324974.;
			chars[15] = 11512810.;

		// !!! doing dot(step) seems to process quicker
		// !!! but charindex() func will be more elegant
		// !!! if more ASCII font sizes are created in the code

		const float4	charsA = float4(  2.,  3.,  4.,  5. )	* quant;
		const float4	charsB = float4(  6.,  7.,  8.,  9. )	* quant;
		const float4	charsC = float4( 10., 11., 12., 13. )	* quant;
		const float3	charsD = float3( 14., 15., 16.) 	* quant;

		int		index  = dot( step( charsA, gray ), 1 );
				index += dot( step( charsB, gray ), 1 );
				index += dot( step( charsC, gray ), 1 );
				index += dot( step( charsD, gray ), 1 );

		// !!! charindex() func seems slower, but more re-useable
//		int		index = charindex( quant, gray, 16 );

		n = chars[index];

	}
	else // Ascii_font == 0 , the 3x5 font
	{
		// -- 3x5 bitmap font by CeeJay.dk --
		// .:;s*oSOXH0

		//14 characters including space which is handled as a special case

		/* Font reference :

		//The plusses are "likes". I was rating how much I liked that character over other alternatives.

		3  ^ 42.
		3  - 448.
		3  i (short) 9232.
		3  ; 5136. ++
		4  " 45.
		4  i 9346.
		4  s 5200. ++
		5  + 1488.
		5  * 2728. ++
		6  c 25200.
		6  o 11088. ++
		7  v 11112.
		7  S 14478. ++
		8  O 11114. ++
		9  F 5071.
		9  5 (rounded) 14543.
		9  X 23213. ++
		10 A 23530.
		10 D 15211. +
		11 H 23533. +
		11 5 (square) 31183.
		11 2 (square) 29671. ++

		5 (rounded) 14543.
		*/
		// !!! taking it a step further, we can
		// !!! chuck the chars into an array, then
		// !!! use step to compare the quants to the gray
		// !!! value, and dots to sum up the # of 1's vs. 0's we get
		// !!! to generate an index value for the char to use.

		float	chars[13];
			chars[0]  = 4096.0;
			chars[1]  = 1040.0;
			chars[2]  = 5136.0;
			chars[3]  = 5200.0;
			chars[4]  = 2728.0;
			chars[5]  = 11088.;
			chars[6]  = 14478.;
			chars[7]  = 11114.;
			chars[8]  = 23213.;
			chars[9]  = 15211.;
			chars[10] = 23533.;
			chars[11] = 31599.;
			chars[12] = 31727.;

		/*
		// !!! reshade doesn't like matrix vars for some reason
		// !!! compile gives error about it
		// !!! tried float4x3 & float3x4, not sure if row or col major
		float3x4 charsX = { 2.,  3.,  4.,  5.,
				    6.,  7.,  8.,  9.,
				   10., 11., 12., 13.
				};

		int	index = dot( mul( step( charsX, gray ), 1 ), 1 );
		*/

		// !!! doing dot(step) seems to process quicker
		// !!! but charindex() func will be more elegant
		// !!! if more ASCII font sizes are created in the code

		const float4	charsA = float4(  2.,  3.,  4.,  5. ) * quant;
		const float4	charsB = float4(  6.,  7.,  8.,  9. ) * quant;
		const float4	charsC = float4( 10., 11., 12., 13. ) * quant;

		int		index  = dot( step( charsA, gray ), 1 );
				index += dot( step( charsB, gray ), 1 );
				index += dot( step( charsC, gray ), 1 );

		// !!! charindex() func seems slower, but more re-useable
//		int		index = charindex( quant, gray, 13 );

		n = chars[index];
	}


	/*--------------------------------.
	| :: Decode character bitfield :: |
	'--------------------------------*/

	float character = 0.0;

	//Test values
	//n = -(exp2(24.)-1.0); //-(2^24-1) All bits set - a white 5x5 box
	
	//If black then set all pixels to black (the space character)
	//That way I don't have to use a character bitfield for space
	//I simply let it to decode to the second darkest "." and turn its pixels off
	float lit = 1.0;
	if (gray <= 1.0 * quant)
		lit = 0.0;

	//is n negative? (I would like to test for negative 0 here too but can't)
	float signbit = 0.0;
	if (n < 0.0)
		signbit = lit;

	//is this the first pixel in the character?
	//if so set to the signbit (which may be on or off depending on if the number was negative)
	//else make it black
	if (x < 23.5)
		signbit = 0.0;

	//If the bit for the right position is set, then light up the pixel
	//This way I can use all 24 bits in the mantissa as well as the signbit for characters.
	if (frac(abs(n*exp2(-x-1.0))) >= 0.5) //Multiply exp2
		character = lit;
	else
		character = signbit;

	// !!! re-wrote this part to organize code a bit more
	const float2 clampP = clamp(p.xy, 0.0, Ascii_font_size.xy);

	//If this is space around character, make pixel black
	if (clampP.x != p.x || clampP.y != p.y)
		character = 0.0;


	/*---------------.
	| :: Colorize :: |
	'---------------*/

	if (Ascii_swap_colors)
	{
		switch (Ascii_font_color_mode)
		{
			case 1:
				if (character)
					color = Ascii_background_color;
				else
					color = Ascii_font_color;
				break;
			case 2:
				if (character == 0.0)
					color = Ascii_font_color;
				break;
			default:
				if (character)
					color = Ascii_background_color;
				else
					color = Ascii_font_color;
				break;
		}
	}
	else
	{
		switch (Ascii_font_color_mode)
		{
			case 1:
				if (character)
					color = Ascii_font_color * gray;
				else
					color = Ascii_background_color;
				break;
			case 2:
				if (character == 0.0)
					color = Ascii_background_color;
				break;
			default:
				if (character)
					color = Ascii_font_color;
				else
					color = Ascii_background_color;
				break;
		}
	}

	/*-------------.
	| :: Return :: |
	'-------------*/

	//color = gray;
	return saturate(color);
}


float3 PS_Ascii(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return AsciiPass(texcoord).rgb;
}


technique ASCII
{
	pass ASCII
	{
		VertexShader=PostProcessVS;
		PixelShader=PS_Ascii;
	}
}


/*
.---------------------.
| :: Character set :: |
'---------------------'

Here are some various chacters and gradients I created in my quest to get the best look

.'~:;!>+=icjtJY56SXDQKHNWM
.':!+ijY6XbKHNM
.:%oO$8@#M
.:+j6bHM
.:coCO8@
.:oO8@
.:oO8
:+#

.:^"~cso*wSO8Q0#
.:^"~csoCwSO8Q0#
.:^"~c?o*wSO8Q0#

n value // # of pixels // character
------------//----//-------------------
4194304.	//  1 // . (bottom aligned) *
131200.		//  2 // : (middle aligned) *
4198400.	//  2 // : (bottom aligned)
132.		//  2 // ' 
2228352.	//  3 // ;
4325504.	//  3 // i (short)
14336.		//  3 // - (small)
324.		//  3 // ^
4329476.	//  4 // i (tall)
330.		//  4 // "
31744.		//  5 // - (larger)
283712.		//  5 // ~
10627072.	//  5 // x
145536.		//  5 // * or + (small and centered)
6325440.	//  6 // c (narrow - left aligned)
12650880.	//  6 // c (narrow - center aligned)
9738240.	//  6 // n (left aligned)
6557772.	//  7 // s (tall)
8679696.	//  7 // f
4532768.	//  7 // v (1st)
4539936.	//  7 // v (2nd)
4207118.	//  7 // ?
-17895696.	//  7 // %
6557958.	//  7 // 3  
6595776.	//  8 // o (left aligned)
13191552.	//  8 // o (right aligned)
14714304.	//  8 // c (wide)
12806528.	//  9 // e (right aligned)
332772.		//  9 // * (top aligned)
10648704.	//  9 // * (bottom aligned)
4357252.	//  9 // +
-18157904.	//  9 // X
11195936.	// 10 // w
483548.		// 10 // s (thick)
15218734.	// 11 // S
31491134.	// 11 // C
15238702.	// 11 // C (rounded)
22730410.	// 11 // M (more like a large m)
10648714.	// 11 // * (larger)
4897444.	// 11 // * (2nd larger)
14726438.	// 11 // @ (also looks like a large e)
23385164.	// 11 // &
15255086.	// 12 // O
16267326.	// 13 // S (slightly larger)
15252014.	// 13 // 8
15259182.	// 13 // 0  (O with dot in the middle)
15517230.	// 13 // Q (1st)
-18405232.	// 13 // M
-11196080.	// 13 // W
32294446.	// 14 // Q (2nd)
15521326.	// 14 // Q (3rd)
32298542.	// 15 // Q (4th)
15324974.	// 15 // 0 or Ø
16398526.	// 15 // $
11512810.	// 16 // #
-33061950.	// 17 // 5 or S (stylized)
-33193150.	// 19 // $ (stylized)
-33150782.	// 19 // 0 (stylized)

*/
