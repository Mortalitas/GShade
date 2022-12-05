//NiceGuy Lamps
//Written by MJ_Ehsan with the contribution of LVunter(tnx <3) for Reshade
//Version 0.1 alpha

//license
//CC0 ^_^
///////////////Include/////////////////////

#include "ReShade.fxh"

#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
#define LDepth ReShade::GetLinearizedDepth

uniform float Frame < source = "framecount"; >;
#pragma warning(disable : 3571)
///////////////Include/////////////////////
///////////////PreProcessor-Definitions////

static const float fov = 60;
#define PI 3.1415927
#define PI2 2*PI
#define rad(x) (x/360)*PI2
#define FAR_PLANE RESHADE_DEPTH_LINEARIZATION_FAR_PLANE
#define CENTER_POINT 0.5

#define ICON_SIZE 0.02
#define IconOcclusionTransparency 0.1

#ifndef SMOOTH_NORMALS
 #define SMOOTH_NORMALS 2
#endif
//Smooth Normals configs. It uses a separable bilateral blur which uses only normals as determinator. 
#define SNThreshold 0.5 //Bilateral Blur Threshold for Smooth normals passes. default is 0.5
#define SNDepthW FAR_PLANE*SNThreshold //depth weight as a determinator. default is 100/SNThreshold
#if SMOOTH_NORMALS <= 1 //13*13 8taps
 #define LODD 0.5    //Don't touch this for God's sake
 #define SNWidth 5.5 //Blur pixel offset for Smooth Normals
 #define SNSamples 1 //actually SNSamples*4+4!
#elif SMOOTH_NORMALS == 2 //16*16 16taps
 #define LODD 0.5
 #define SNWidth 2.5
 #define SNSamples 3
#elif SMOOTH_NORMALS > 2 //31*31 84taps
 #warning "SMOOTH_NORMALS 3 is slow and should to be used for photography or old games. Otherwise set to 2 or 1."
 #define LODD 0
 #define SNWidth 1
 #define SNSamples 30
#endif

///////////////PreProcessor-Definitions////
///////////////Textures-Samplers///////////

texture TexColor : COLOR;
sampler sTexColor {Texture = TexColor; };

texture LampIcon <source = "NGLamp-Lamp-Icon.jpg";>{ Width = 814; Height = 814; Format = R8; MipLevels = 6; };
sampler sLampIcon { Texture = LampIcon; AddressU = CLAMP; AddressV = CLAMP; };

texture NormTex  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sNormTex { Texture = NormTex; };

texture NormTex1  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16f; };
sampler sNormTex1 { Texture = NormTex1; };

texture2D RoughnessTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = R16f;};
sampler sRoughnessTex {Texture = RoughnessTex;};

///////////////Textures-Samplers///////////
///////////////UI//////////////////////////

uniform int Hints<
	ui_text = "This shader lacks an internal denoiser at the moment.\n"
			  "Use either FXAA or TFAA and set the denoiser option accordingly."
			  "Bump mapping may break the look. I'm trying to solve it tho.";
			  
	ui_category = "Hints - Please Read for good results.";
	ui_category_closed = true;
	ui_label = " ";
	ui_type = "radio";
>;

uniform bool debug <
	ui_label = "Debug";
	ui_category = "General";
> = 0;

uniform bool OGLighting <
	ui_label = "Include original lighting";
	ui_category = "General";
> = 1;

uniform bool ShowIcon <
	ui_label = "Show lamp icons";
	ui_category = "General";
> = 1;

uniform bool LimitPos <
	ui_label = "Limit lamp to depth";
	ui_tooltip = "Limit lamp position to the wall behind them";
	ui_category = "General";
> = 0;

uniform int TA <
	ui_label = "Denoiser";
	ui_type = "combo";
	ui_items = "FXAA\0TFAA\0";
	ui_category = "General";
> = 0;

uniform float UI_FOG_DENSITY <
	ui_type = "slider";
	ui_label = "Fog Density";
	ui_category = "General";
	ui_max = 1;
> = 0.2;
#define UI_FOG_DENSITY UI_FOG_DENSITY/3000

uniform float3 UI_FOG_COLOR <
	ui_type = "color";
	ui_label = "Fog Color";
	ui_category = "General";
> = 1;

uniform float specular <
	ui_type = "slider";
	ui_category = "General";
	ui_min = 0;
	ui_max = 1;
> = 0.1;

uniform float BUMP <
	ui_label = "Bump mapping";
	ui_type = "slider";
	ui_category = "General";
	ui_min = 0.0;
	ui_max = 1;
> = 0;

uniform int Shadow_Quality <
	ui_label = "Shadow quality";
	ui_type = "combo";
	ui_items = "Low (16 steps)\0Medium (48 steps)\0High (256 steps)\0";
	ui_category = "General";
> = 0;

uniform float roughfac1 <
	ui_type = "slider";
	ui_category = "Roughness";
	ui_label = "Variation Frequency";
	ui_tooltip = "How wide it should search for variation in roughness?\n"
				 "Low = Detailed\nHigh = Soft";
	ui_max = 3;
> = 1;

uniform float roughfac2 <
	ui_type = "slider";
	ui_category = "Roughness";
	ui_label = "Roughness Curve";
	ui_tooltip = "Overall roughness bias\n"
				 "Final Roughness is also affected by (Surface Relief Height - Recommended : 1)\n"
				 "and (Surface Relief Scale - Recommended : 0.35) Values in SSR.";
	ui_min = 0.1;
	ui_max = 2;
> = 0.17;

uniform float2 fromrough <
	ui_type = "slider";
	ui_category = "Roughness";
	ui_label = "Levels - input";
	ui_tooltip = "1st one: Any color below this will become black.\n"
				 "2nd one: Any color above this will become white.";
> = float2( 0, 1);

uniform float2 torough <
	ui_type = "slider";
	ui_category = "Roughness";
	ui_label = "Levels - output";
	ui_tooltip = "1st one: Brightens the dark pixels.\n"
				 "2nd one: Darkens the bright pixels.";
> = float2( 0.5, 1);

/*_________________________________________
                                           |
Lamp 1 Inputs                              |
__________________________________________*/

uniform bool L1 <
	ui_label = "Enable Lamp 1";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 1;

uniform bool UI_FOG1 <
	ui_label = "Enable fog";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 1;

uniform bool UI_S_ENABLE1 <
	ui_label = "Enable Shadows";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 1;

uniform float3 UI_LAMP1 <
	ui_type = "slider";
	ui_label= "Position";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = float3(0.5, 0.5, 0.03125);

uniform float3 UI_LAMP1_PRECISE <
	ui_type = "slider";
	ui_label= "Precise Position";
	ui_max =  0.02;
	ui_min = -0.02;
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = float3(0, 0, 0);

uniform float3 UI_COLOR1 <
	ui_type = "color";
	ui_label= "Color";
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 1;

uniform float UI_POWER1 <
	ui_type = "slider";
	ui_label= "Power";
	ui_max  = 1000;
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 500;

uniform float UI_SOFT_S1 <
	ui_type = "slider";
	ui_label= "Shadow Softness";
	ui_max  = 10;
	ui_category = "Lamp 1";
	ui_category_closed = true;
> = 0;

/*_________________________________________
                                           |
Lamp 2 Inputs                              |
__________________________________________*/
uniform bool L2 <
	ui_label = "Enable Lamp 2";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 0;

uniform bool UI_FOG2 <
	ui_label = "Enable fog";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 1;

uniform bool UI_S_ENABLE2 <
	ui_label = "Enable Shadows";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 1;

uniform float3 UI_LAMP2 <
	ui_type = "slider";
	ui_label= "Position";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = float3(0.5, 0.25, 0.03125);

uniform float3 UI_LAMP2_PRECISE <
	ui_type = "slider";
	ui_label= "Precise Position";
	ui_max =  0.02;
	ui_min = -0.02;
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = float3(0, 0, 0);

uniform float3 UI_COLOR2 <
	ui_type = "color";
	ui_label= "Color";
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 1;

uniform float UI_POWER2 <
	ui_type = "slider";
	ui_label= "Power";
	ui_max  = 1000;
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 500;

uniform float UI_SOFT_S2 <
	ui_type = "slider";
	ui_label= "Shadow Softness";
	ui_max  = 10;
	ui_category = "Lamp 2";
	ui_category_closed = true;
> = 0;

/*_________________________________________
                                           |
Lamp 3 Inputs                              |
__________________________________________*/
uniform bool L3 <
	ui_label = "Enable Lamp 3";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 0;

uniform bool UI_FOG3 <
	ui_label = "Enable fog";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 1;

uniform bool UI_S_ENABLE3 <
	ui_label = "Enable Shadows";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 1;

uniform float3 UI_LAMP3 <
	ui_type = "slider";
	ui_label= "Position";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = float3(0.5, 0.75, 0.03125);

uniform float3 UI_LAMP3_PRECISE <
	ui_type = "slider";
	ui_label= "Precise Position";
	ui_max =  0.02;
	ui_min = -0.02;
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = float3(0, 0, 0);

uniform float3 UI_COLOR3 <
	ui_type = "color";
	ui_label= "Color";
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 1;

uniform float UI_POWER3 <
	ui_type = "slider";
	ui_label= "Power";
	ui_max  = 1000;
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 500;

uniform float UI_SOFT_S3 <
	ui_type = "slider";
	ui_label= "Shadow Softness";
	ui_max  = 10;
	ui_category = "Lamp 3";
	ui_category_closed = true;
> = 0;

/*_________________________________________
                                           |
Lamp 4 Inputs                              |
__________________________________________*/
uniform bool L4 <
	ui_label = "Enable Lamp 4";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 0;

uniform bool UI_FOG4 <
	ui_label = "Enable fog";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 1;

uniform bool UI_S_ENABLE4 <
	ui_label = "Enable Shadows";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 1;

uniform float3 UI_LAMP4 <
	ui_type = "slider";
	ui_label= "Position";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = float3(0.25, 0.5, 0.03125);

uniform float3 UI_LAMP4_PRECISE <
	ui_type = "slider";
	ui_label= "Precise Position";
	ui_max =  0.02;
	ui_min = -0.02;
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = float3(0, 0, 0);

uniform float3 UI_COLOR4 <
	ui_type = "color";
	ui_label= "Color";
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 1;

uniform float UI_POWER4 <
	ui_type = "slider";
	ui_label= "Power";
	ui_max  = 1000;
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 500;

uniform float UI_SOFT_S4 <
	ui_type = "slider";
	ui_label= "Shadow Softness";
	ui_max  = 10;
	ui_category = "Lamp 4";
	ui_category_closed = true;
> = 0;

///////////////UI//////////////////////////
///////////////Vertex Shader///////////////
///////////////Vertex Shader///////////////
///////////////Functions///////////////////

#include "NGLamps-GGX.fxh"

float noise(float2 co)
{
  return frac(sin(dot(co.xy ,float2(1.0,73))) * 437580.5453);
}

float interleavedGradientNoise(float2 n) {
    float f = 0.06711056 * n.x + 0.00583715 * n.y;
    return frac(52.9829189 * frac(f));
}


float3 noise3dts(float2 co, float s, float frame)
{
	co += sin(frame/120.347668756453546);
	co += s/16.3542625435332254;
	return float3( noise(co), noise(co+0.6432168421), noise(co+0.19216811));
}

float3 UVtoPos(float2 texcoord)
{
	float3 scrncoord = float3(texcoord.xy*2-1, LDepth(texcoord) * FAR_PLANE);
	scrncoord.xy *= scrncoord.z * (rad(fov*0.5));
	scrncoord.x *= BUFFER_ASPECT_RATIO;
	
	return scrncoord.xyz;
}

float3 UVtoPos(float2 texcoord, float depth)
{
	float3 scrncoord = float3(texcoord.xy*2-1, depth * FAR_PLANE);
	scrncoord.xy *= scrncoord.z * (rad(fov*0.5));
	scrncoord.x *= BUFFER_ASPECT_RATIO;
	
	return scrncoord.xyz;
}

float2 PostoUV(float3 position)
{
	float2 scrnpos = position.xy;
	scrnpos.x /= BUFFER_ASPECT_RATIO;
	scrnpos /= position.z*rad(fov/2);
	
	return scrnpos/2 + 0.5;
}

float3 Normal(float2 texcoord)
{
	float2 p = pix;
	float3 u,d,l,r,u2,d2,l2,r2;
	
	u = UVtoPos( texcoord + float2( 0, p.y));
	d = UVtoPos( texcoord - float2( 0, p.y));
	l = UVtoPos( texcoord + float2( p.x, 0));
	r = UVtoPos( texcoord - float2( p.x, 0));
	
	p *= 2;
	
	u2 = UVtoPos( texcoord + float2( 0, p.y));
	d2 = UVtoPos( texcoord - float2( 0, p.y));
	l2 = UVtoPos( texcoord + float2( p.x, 0));
	r2 = UVtoPos( texcoord - float2( p.x, 0));
	
	u2 = u + (u - u2);
	d2 = d + (d - d2);
	l2 = l + (l - l2);
	r2 = r + (r - r2);
	
	float3 c = UVtoPos( texcoord);
	
	float3 v = u-c; float3 h = r-c;
	
	if( abs(d2.z-c.z) < abs(u2.z-c.z) ) v = c-d;
	if( abs(l2.z-c.z) < abs(r2.z-c.z) ) h = c-l;
	
	return normalize(cross( v, h));
}


float3 Tonemapper(float3 color)
{//Timothy Lottes fast_reversible
	return color.rgb / (1.001 + color);
}

float InvTonemapper(float color)
{//Reinhardt reversible
	return color / (1.0000001 - color);
}

float3 InvTonemapper(float3 color)
{//Timothy Lottes fast_reversible
	return color / (1.001 - color);
}

float3 Bump(float2 texcoord, float height)
{
	float2 T = pix;

	float4 s[5];
	s[0].rgb = tex2D(sTexColor, texcoord + float2(T.x,0)).rgb * height;
	s[1].rgb = tex2D(sTexColor, texcoord + float2(0,T.y)).rgb * height;
	s[2].rgb = tex2D(sTexColor, texcoord + float2(-T.x,0)).rgb * height;
	s[3].rgb = tex2D(sTexColor, texcoord + float2(0,-T.y)).rgb * height;
	s[4].rgb = tex2D(sTexColor, texcoord).rgb * height;
	
	s[0].a = LDepth(texcoord + float2(T.x,0));
	s[1].a = LDepth(texcoord + float2(0,T.y));
	s[2].a = LDepth(texcoord + float2(-T.x,0));
	s[3].a = LDepth(texcoord + float2(0,-T.y));
	s[4].a = LDepth(texcoord);
	
	float4 XB0 = s[4]-s[0];
	float4 YB0 = s[4]-s[1];
	float4 XB1 = s[4]-s[3];
	float4 YB1 = s[4]-s[2];
	
	XB0 = (abs(XB0.a) < abs(XB1.a)) ? XB0 : XB1;
	YB0 = (abs(YB0.a) < abs(YB1.a)) ? YB0 : YB1;
	
	return float3(XB0.x*2, YB0.y*2, 1);
}

float3 blend_normals(float3 n1, float3 n2)
{
    n1 += float3( 0, 0, 1);
    n2 *= float3(-1, -1, 1);
    return n1*dot(n1, n2)/n1.z - n2;
}

float lum(in float3 color)
{
	return dot(0.333333333, color);
}

bool is_saturated(float2 uv)
{
	return uv.x>1||uv.y>1||uv.x<0||uv.y<0;
}

///////////////Functions///////////////////
///////////////Pixel Shader////////////////

float3 roughness( float4 Position : SV_Position, float2 texcoord : TEXCOORD0) : SV_Target
{
	float2 p = pix;
	
	//roughness estimation based on color variation
	float3 center = tex2D( sTexColor, texcoord).rgb;
	float3 r = tex2D( sTexColor, texcoord + float2(  roughfac1*p.x, 0)).rgb;
	float3 l = tex2D( sTexColor, texcoord + float2( -roughfac1*p.x, 0)).rgb;
	float3 d = tex2D( sTexColor, texcoord + float2( 0, -roughfac1*p.y)).rgb;
	float3 u = tex2D( sTexColor, texcoord + float2( 0,  roughfac1*p.y)).rgb;
	
	//using depth as bilateral blur's determinator
	float depth = LDepth(texcoord);
	float ld = LDepth(texcoord + float2(  roughfac1*p.x, 0));
	float rd = LDepth(texcoord + float2( -roughfac1*p.x, 0));
	float dd = LDepth(texcoord + float2( 0, -roughfac1*p.y));
	float ud = LDepth(texcoord + float2( 0,  roughfac1*p.y));
	
	//a formula based on trial and error!
	l = clamp(abs(center - l), 0, 0.25);
	r = clamp(abs(center - r), 0, 0.25);
	u = clamp(abs(center - u), 0, 0.25);
	d = clamp(abs(center - d), 0, 0.25);
	
	float a = 0.02;
	
	float3 sharp = 0;
	if ( abs(ld - depth) <= a ) { sharp += l; }
	if ( abs(rd - depth) <= a ) { sharp += r; }
	if ( abs(ud - depth) <= a ) { sharp += u; }
	if ( abs(dd - depth) <= a ) { sharp += d; }
	//sharp = sharp + l+r+u+d;
	
	sharp = pow( sharp, roughfac2);
	sharp = clamp(sharp, fromrough.x, fromrough.y);
	sharp = (sharp - fromrough.x) / ( 1 - fromrough.x );
	sharp = sharp / fromrough.y;
	sharp = clamp(sharp, torough.x, torough.y);
	//sharp = normalize(sharp);

	
	return sharp;
}

void GBuffer1
(
	float4 vpos : SV_Position,
	float2 texcoord : TexCoord,
	out float4 normal : SV_Target) //SSSR_NormTex
{
	normal.rgb = Normal(texcoord.xy);
	normal.a   = LDepth(texcoord.xy);
#if SMOOTH_NORMALS <= 0
	normal.rgb = blend_normals( Bump(texcoord, -BUMP), normal.rgb);
#endif
}

float4 SNH(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color = tex2D(sNormTex, texcoord);
	float4 s, s1; float sc;
	
	float2 p = pix; p*=SNWidth;
	float T = SNThreshold * saturate(2*(1-color.a)); T = rcp(max(T, 0.0001));
	for (int i = -SNSamples; i <= SNSamples; i++)
	{
		s = tex2D(sNormTex, float2(texcoord + float2(i*p.x, 0)/*, 0, LODD*/));
		float diff = dot(0.333, abs(s.rgb - color.rgb)) + abs(s.a - color.a)*SNDepthW;
		diff = 1-saturate(diff*T);
		s1 += s*diff;
		sc += diff;
	}
	
	//SNFilter( texcoord, color, s, s1, sc, T, p, 0);
	
	return s1.rgba/sc;
}

float3 SNV(float4 vpos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float4 color = tex2Dlod(sNormTex1, float4(texcoord, 0, 0));
	float4 s, s1; float sc;

	float2 p = pix; p*=SNWidth;
	float T = SNThreshold * saturate(2*(1-color.a)); T = rcp(max(T, 0.0001));
	for (int i = -SNSamples; i <= SNSamples; i++)
	{
		s = tex2D(sNormTex1, float2(texcoord + float2(0, i*p.y)/*, 0, LODD*/));
		float diff = dot(0.333, abs(s.rgb - color.rgb)) + abs(s.a - color.a)*SNDepthW;
		diff = 1-saturate(diff*T*2);
		s1 += s*diff;
		sc += diff;
		}
	
	//SNFilter( texcoord, color, s, s1, sc, T, p, 1);
	
	s1.rgba = s1.rgba/sc;
	s1.rgb = blend_normals( Bump(texcoord, BUMP), s1.rgb);
	return s1.rgb;
}

// Settings
#define STEPNOISE 1
#define MINBIAS 0

float GetShadows(float3 position, float3 lamppos, float3 normal, float2 texcoord, float penumbra, float NdotL)
{
    // Compute ray position and direction (in view-space)
    float i; float2 UVraypos; float3 Check; bool hit; float a;
	
	int STEPCOUNT_Selector[3] = {16, 48, 256};
	int STEPCOUNT = STEPCOUNT_Selector[Shadow_Quality];
	
	static const float raydepth = -70;
		
	float3 noise;
	noise.r = interleavedGradientNoise((texcoord*BUFFER_SCREEN_SIZE+(Frame%((TA)?16:1))*1.31415));
	noise.g = interleavedGradientNoise((texcoord*BUFFER_SCREEN_SIZE+(Frame%((TA)?16:1))*1.31415)+4);
	noise.b = interleavedGradientNoise((texcoord*BUFFER_SCREEN_SIZE+(Frame%((TA)?16:1))*1.31415)+8);

    lamppos += (noise.yz-0.5)*penumbra;
    
    float3 raydir = normalize(lamppos - position);
    raydir *= distance(position, lamppos)/STEPCOUNT;
    
	float3 raypos = position + raydir * (1 + noise.x * STEPNOISE);
    // Ray march towards the light
    [loop]for( i = 0; i < STEPCOUNT; i++)
	{
		UVraypos = PostoUV(raypos);
		Check = UVtoPos(UVraypos) - raypos;
		//if(UVraypos.x>1||UVraypos.x<0||UVraypos.y>1||UVraypos.y<0){ a = 0; break;}

		hit = Check.z < 0;
		if(hit && Check.z > raydepth)
		{
			a = 1;//if(i<=1)a=0;
			break;
		}
		raypos += raydir;
	}
    return 1-a;
}

float3 GetLampPos(float3 UI_LAMP)
{
	float3 sspos = UI_LAMP;
	float3 wspos = UVtoPos(sspos.xy, sspos.z);
	
	return wspos;
}
	

float3 GetLighting(
	inout float3 FinalColor, inout float spr, inout float3 Specular, inout float3 fog, 
	float alpha, float3 position, float3 normal, float3 eyedir, float NdotV, float F0, float2 texcoord, float2 sprite, float3 diffusecolor,
	float3 UI_LAMP, float3 UI_LAMP_PRECISE, float3 UI_COLOR, float UI_POWER, float UI_SOFT_S, float UI_S_ENABLE, bool UI_FOG)
{
	float3 lamppos, lamp, lampdir, light; float2 icopos; float DepthLimit, AngFalloff, backfacing, sprtex, Shadow;

	//lamp data
	//lamppos    = UI_LAMP+UI_LAMP_PRECISE-float3(CENTER_POINT,CENTER_POINT,0);
	lamppos = GetLampPos(UI_LAMP + UI_LAMP_PRECISE);
	if(LimitPos)
	{
	DepthLimit = LDepth(PostoUV(lamppos.xyz));
	lamppos.z  = min(lamppos.z, DepthLimit*FAR_PLANE-5);
	}
	lamp       = 1/pow(distance(position, lamppos), 2);
	lampdir    = normalize(lamppos - position);
	
	//Dots and shit
	float3 H    = normalize(lampdir + eyedir);
	float NdotH = dot(normal, H);
	float VdotH = dot(eyedir, H);
	float NdotL = dot(normal, lampdir);
	float LdotV = dot(lampdir, eyedir);
	backfacing = dot(-lampdir, normal);
	
	//Compute Screen Space Ray Marched Shadows
	Shadow = 1;
	if(UI_S_ENABLE)Shadow = GetShadows(position, lamppos, normal, texcoord, UI_SOFT_S, NdotL);
	
	//Diffuse Lighting
	AngFalloff = dot(lampdir, normal); 
	float DisFalloff = 1/pow(distance(position, lamppos), 2);
	light      = lamp*UI_POWER*UI_COLOR*(1-AngFalloff);
	
	//FinalColor += hammon(LdotV, NdotH, NdotL, NdotV, alpha, diffusecolor) * (backfacing >= 0) * UI_COLOR * UI_POWER * DisFalloff * Shadow;
	FinalColor+= lerp( 0, light, saturate(backfacing)) * Shadow;
	//Specular Lighting
	float3 ThisSpecular = ggx_smith_brdf(NdotL, NdotV, NdotH, VdotH, F0, alpha, texcoord) * NdotL;
	ThisSpecular *= DisFalloff;
	ThisSpecular *= specular*UI_POWER*UI_COLOR*Shadow;
	Specular += ThisSpecular;
	//View to UV projection of the light. Used for icon and fog sprites
	icopos = sprite - (PostoUV(lamppos) * 2 - 1)*float2(1.7778, 2);
	icopos *= sqrt(max(1,lamppos.z))/(16*ICON_SIZE);
	icopos = icopos * 0.5 + 0.5;
	sprtex = 1-(tex2D(sLampIcon, icopos).r);
	if(lamppos.z>position.z)sprtex *= IconOcclusionTransparency; //Z test
	if(is_saturated(icopos))sprtex = 0;//Border UV address
	spr += sprtex;
	
	//Volumetric Lighting
	if(UI_FOG)fog += UI_POWER2/length(icopos-0.5)*UI_COLOR*UI_FOG_DENSITY;
	return 0;
}

struct i
{
	float4 vpos : SV_Position;
	float2 texcoord : TexCoord0;
};

void A(i i, out float3 FinalColor : SV_Target0)
{
	FinalColor = 0;
	float3 raypos, Check; float2 UVraypos; float a; bool hit; //ss shadows ray marcher
	float3 lamppos, lamp, lampdir, light, fog, Specular,K,R; float2 icopos; float AngFalloff, backfacing, sprtex, spr; //lamps data
	
	float3 diffusecolor = tex2D(sTexColor, i.texcoord).rgb;
	float3 albedo = lerp( diffusecolor, diffusecolor/(lum(diffusecolor)*2), 0);
	if(debug)diffusecolor = 1;
	//sprites coords
	float2 sprite = i.texcoord;
	sprite = sprite * 2 - 1; //range 0~1 to -1~1
	sprite.x *= BUFFER_ASPECT_RATIO; //1:1 aspect ratio as of the icon
	//GBuffer Data
	float roughness = tex2D(sRoughnessTex, i.texcoord).r;
	float3 position = UVtoPos(i.texcoord);
	float3 normal   = tex2D(sNormTex, i.texcoord).rgb;
	float3 eyedir   = -normalize(position); //should be inverted for GGX
	float  NdotV    = dot(normal, eyedir);
	float  F0       = 0.04; //reflectance at 0deg angle
	float  alpha    = roughness * roughness; //roughness used for GGX
	//Lamp 1
	if(L1)
	GetLighting(
		FinalColor, spr, Specular, fog,
		alpha, position, normal, eyedir, NdotV, F0, i.texcoord, sprite, albedo,
		UI_LAMP1, UI_LAMP1_PRECISE, UI_COLOR1, UI_POWER1, UI_SOFT_S1, UI_S_ENABLE1, UI_FOG1);

	if(L2)
	GetLighting(
		FinalColor, spr, Specular, fog,
		alpha, position, normal, eyedir, NdotV, F0, i.texcoord, sprite, albedo,
		UI_LAMP2, UI_LAMP2_PRECISE, UI_COLOR2, UI_POWER2, UI_SOFT_S2, UI_S_ENABLE2, UI_FOG2);
		
	if(L3)
	GetLighting(
		FinalColor, spr, Specular, fog,
		alpha, position, normal, eyedir, NdotV, F0, i.texcoord, sprite, albedo,
		UI_LAMP3, UI_LAMP3_PRECISE, UI_COLOR3, UI_POWER3, UI_SOFT_S3, UI_S_ENABLE3, UI_FOG2);
		
	if(L4)
	GetLighting(
		FinalColor, spr, Specular, fog,
		alpha, position, normal, eyedir, NdotV, F0, i.texcoord, sprite, albedo,
		UI_LAMP4, UI_LAMP4_PRECISE, UI_COLOR4, UI_POWER4, UI_SOFT_S4, UI_S_ENABLE4, UI_FOG2);
/*_________________________________________

Here is the rest of the code.
__________________________________________*/
	
	if(!debug)FinalColor = FinalColor*diffusecolor;
	
	FinalColor += fog*UI_FOG_COLOR;
	FinalColor += -min(Specular, 0);

	if(OGLighting&&!debug)FinalColor += InvTonemapper(diffusecolor);
	FinalColor = Tonemapper(FinalColor);
	if(ShowIcon)FinalColor += spr;
	
	//Fresnel = saturate(Fresnel);
	//FinalColor += lerp(0, saturate(1-(K.rgb)), Fresnel)*max(0.25, lum(color));
	if(LDepth(i.texcoord)==0)FinalColor = diffusecolor;
	//FinalColor = GetShadows(position, UI_LAMP1, normal, texcoord);
}

///////////////Pixel Shader////////////////
///////////////Techniques//////////////////

technique NGLamps<
	ui_label   = "NiceGuy Lamps";
	ui_tooltip = "NiceGuy Lamps 1.0 Beta\n"
				 "    ||By Ehsan2077||  \n";	
>
{
	pass
    {
    	VertexShader = PostProcessVS;
    	PixelShader = roughness;
    	RenderTarget = RoughnessTex;
    }
	pass GBuffer
	{
		VertexShader  = PostProcessVS;
		PixelShader   = GBuffer1;
		RenderTarget0 = NormTex;
	}
#if SMOOTH_NORMALS > 0
	pass SmoothNormalHpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNH;
		RenderTarget = NormTex1;
	}
	pass SmoothNormalVpass
	{
		VertexShader = PostProcessVS;
		PixelShader = SNV;
		RenderTarget = NormTex;
	}
#endif
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = A;
	}
}

///////////////Techniques//////////////////
