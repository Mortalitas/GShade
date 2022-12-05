#ifndef UI_DIFFICULTY
 #define UI_DIFFICULTY 0
#endif

#define NGAspectRatio float2(1, BUFFER_WIDTH/BUFFER_HEIGHT)          

#ifndef SMOOTH_NORMALS
 #define SMOOTH_NORMALS 1
#endif

#ifndef RESOLUTION_SCALE_
 #define RESOLUTION_SCALE_ 0.67
#endif

//Full res denoising on all passes. Otherwise only Spatial Filter 1 will be full res.
//Deprecated. Always HQ. LQ performance benefit isn't enough to sacrifice that much of the quality.
//But kept the code in case I regret. :')
//#ifndef HQ_UPSCALING
// #define HQ_UPSCALING 1
//#endif

#define HQ_SPECULAR_REPROJECTION 0  //WIP!

//Blur radius adaptivity threshold depending on the number of accumulated frames per pixel
#define Off       2025  //Default is 2025 //0 pass (___ - ___ - ___)  1*1           no filter
#define VerySmall 225.  //Default is 225. //1 pass (3*3 - ___ - ___)  3*3          box filter
#define Small     81.0  //Default is 81.0 //1 pass (5*5 - ___ - ___)  5*5          box filter
#define Medium    25.0  //Default is 25.0 //2 pass (3*3 - 3*3 - ___)  9*9  chained box filter
#define Large     9.00  //Default is 9.00 //2 pass (3*3 - 5*5 - ___) 15*15 chained box filter
#define VeryLarge 3.00  //Default is 3.00 //3 pass (3*3 - 3*3 - 3*3) 27*27 chained box filter
#define Largest   1.00  //Default is 1.00 //3 pass (3*3 - 3*3 - 5*5) 45*45 chained box filter
//These numbers are gathered by ceil(2025/radius^2). 2025 is the number of samples in the widest mode.
//Will increase in the shader if the Inverse Tonemapping Intensity is too high.

//To check if needed to bilinear sample the smallest filter in order to achieve 5*5 box filter
//#define Bilinearize (HLOut < VeryLarge || (HLOut < Medium && HLOut >= Large) || (HLOut < VerySmall && HLOut >= Small))

//if the History Length is lower than this threshold, edge avoiding function will be ignored to make
//sure the temporally underaccumulated pixel is getting enough spatial accumulation.
//HistoryFix0 should be lower or equal to HistoryFix1 in order to avoid artifacts.
#define HistoryFix0 0 //Big one  . Default is 1
#define HistoryFix1 0 //Small one. Default is 1
#define NGLi_MAX_MipFilter 3 //additional mip based blur (radius = 2^MAX_MipFilters). Default is 3

//Motion Based Deghosting Threshold is the minimum value to be multiplied to the history length.
//Higher value causes more ghosting but less blur. Too low values might result in strong flickering in motion.
#define MBSDThreshold 0.5 //Default is 0.05
#define MBSDMultiplier 80 //Default is 90

//Temporal stabilizer Intensity
#define TSIntensity 0.97

//Temporal Refine min blend value. lower is more stable but ghosty and too low values may introduce banding
#define TRThreshold 0.001

//Smooth Normals configs. It uses a separable bilateral blur which uses only normals as determinator. 
#define SNThreshold 0.99 //Bilateral Blur Threshold for Smooth normals passes. default is 0.5
#define SNDepthW FAR_PLANE*1*SNThreshold //depth weight as a determinator. default is 100/SNThreshold
#if SMOOTH_NORMALS <= 1 //13*13 8taps
 #define LODD 0.5    //Don't touch this for God's sake
 #define SNWidth 5.5 //Blur pixel offset for Smooth Normals
 #define SNSamples 1 //actually SNSamples*4+4!
#elif SMOOTH_NORMALS == 2 //16*16 16taps
 #define LODD 0.5
 #define SNWidth 2.5
 #define SNSamples 3
#elif SMOOTH_NORMALS > 2 //41*41 84taps
 #warning "SMOOTH_NORMALS 3 is slow and should to be used for photography or old games. Otherwise set to 2 or 1."
 #define LODD 0
 #define SNWidth 1.5
 #define SNSamples 30
#endif
