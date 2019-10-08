 ///---------//
 ///**BIAA**///
 //--------////

 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 //* Bilinear Interpolation Anti Aliasing.                                     																										 
 //* For Reshade 3.0+																																								
 //* --------------------------																																						
 //* This work is licensed under a Creative Commons Attribution 3.0 Unported License.																							
 //* So you are free to share, modify and adapt it for your needs, and even use it for commercial use.																			
 //* I would also love to hear about a project you are using it with.																											
 //* https://creativecommons.org/licenses/by/3.0/us/																															
 //*																																											
 //* Have fun,																																									
 //* Jose Negrete AKA BlueSkyDefender																																			
 //* ---------------------------------																																			    
 //* 																																												
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

uniform float AA_Power <
	ui_type = "slider";
	ui_min = 0.5; ui_max = 1;
	ui_label = "AA Power";
	ui_tooltip = "Use this to adjust the AA power.\n"
				 "Default is 0.75";
	ui_category = "BIAA";
> = 0.75;

uniform int View_Mode <
	ui_type = "combo";
	ui_items = "BIAA\0Mask View\0";
	ui_label = "View Mode";
	ui_tooltip = "This is used to select the normal view output or debug view.\n"
				 "Masked View gives you a view of the edge detection.\n"
				 "Default is BIAA.";
	ui_category = "BIAA";
> = 0;

uniform float Mask_Adjust <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Mask Adjustment";
	ui_tooltip = "Use this to adjust the Mask.\n"
				 "Default is 0.5";
	ui_category = "BIAA";
> = 0.375;
/*
uniform float Adjust <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.5;
	ui_label = "Adjustment";
	ui_category = "BIAA";
> = 0.5;
*/
/////////////////////////////////////////////////////D3D Starts Here/////////////////////////////////////////////////////////////////
#define pix float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

texture BackBufferTex : COLOR;

sampler BackBuffer 
	{ 
		Texture = BackBufferTex;
	};
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Luminosity Intensity
float LI(in float4 value)
{	
	return dot(value.rgb,float3(0.333, 0.333, 0.333));
}

float2 EdgeDetection(float2 TC, float2 offset)
{   
     const float2 X = float2(offset.x,0), Y = float2(0,offset.y);
    
    // Bilinear Interpolation. 
    const float Left = LI( tex2D(BackBuffer, TC-X ) ) + LI( tex2D(BackBuffer, TC-X ) );
    const float Right = LI( tex2D(BackBuffer, TC+X ) ) + LI( tex2D(BackBuffer, TC+X ) );
    
    const float Up = LI( tex2D(BackBuffer, TC-Y ) ) + LI( tex2D(BackBuffer, TC-Y ) );
    const float Down = LI( tex2D(BackBuffer, TC+Y ) ) + LI( tex2D(BackBuffer, TC+Y ) );
	// Calculate like NFAA
    return float2(Down-Up,Right-Left) * 0.5;
}

float4 Out(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 Done = float4(tex2D(BackBuffer, texcoord).rgb,1.0);
	float3 result = tex2D(BackBuffer, texcoord).rgb * (1.0-AA_Power);
	const float2 Offset = pix;
    const float2 X = float2(pix.x, 0.0), Y = float2(0.0, pix.y);
        
    // Calculate Edge
    float2 Edge = EdgeDetection(texcoord, Offset);
    
    // Like NFAA calculate normal from Edge
    float2 N = float2(Edge.x,-Edge.y);
    
	//Calculate Gradient from edge    
	Edge += EdgeDetection( texcoord -X, Offset);
	Edge += EdgeDetection( texcoord +X, Offset);
	Edge += EdgeDetection( texcoord -Y, Offset);
	Edge += EdgeDetection( texcoord +Y, Offset);
	Edge += EdgeDetection( texcoord -X -Y, Offset);
	Edge += EdgeDetection( texcoord -X +Y, Offset);
	Edge += EdgeDetection( texcoord +X -Y, Offset);
	Edge += EdgeDetection( texcoord +X +Y, Offset);
	
	// Like DLAA calculate mask from gradient above.
    const float Mask = length(N) < pow(0.002, Mask_Adjust);
    
    // Like NFAA Calculate Main Mask based on edge strenght.
    if ( Mask )
    {
    	result = tex2D(BackBuffer, texcoord).rgb;
    }
    else
	{
	       	    
	    //Revert gradient
	    N = float2(Edge.x,-Edge.y);
    
	    // Like NFAA reproject with samples along the edge and adjust againts it self.
		// Will Be Making changes for short edges and long later.
	    const float AA_Adjust = AA_Power * rcp(6);   
		result += tex2D(BackBuffer, texcoord+(N * 0.5)*Offset).rgb * AA_Adjust;
		result += tex2D(BackBuffer, texcoord-(N * 0.5)*Offset).rgb * AA_Adjust;
		result += tex2D(BackBuffer, texcoord+(N * 0.25)*Offset).rgb * AA_Adjust;
		result += tex2D(BackBuffer, texcoord-(N * 0.25)*Offset).rgb * AA_Adjust;
		result += tex2D(BackBuffer, texcoord+N*Offset).rgb * AA_Adjust;
		result += tex2D(BackBuffer, texcoord-N*Offset).rgb * AA_Adjust;
	}

    // Set result
   if (View_Mode == 0)
   	Done = float4(result,1.0);
   else
   	Done = lerp(float4(1.0,0.0,1.0,1.0),Done,saturate(Mask));
	
    	return Done;
}

///////////////////////////////////////////////////////////ReShade.fxh/////////////////////////////////////////////////////////////

// Vertex shader generating a triangle covering the entire screen
void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	if (id == 2)
		texcoord.x = 2.0;
	else
		texcoord.x = 0.0;

	if (id == 1)
		texcoord.y = 2.0;
	else
		texcoord.y = 0.0;

	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

//*Rendering passes*//
technique Bilinear_Interpolation_Anti_Aliasing
{
			pass BIAA
		{
			VertexShader = PostProcessVS;
			PixelShader = Out;	
		}
}
