#ifndef IO_STRUCTS_INCLUDED
#define  IO_STRUCTS_INCLUDED

//////////////////////////////////////////////////
// Vertex shader input

struct VertexInput
{
	float4 Position : POSITION;
	float3 Normal : NORMAL0;
	float3 Tangent : TANGENT0;
	float3 Binormal : BINORMAL0;
	float4 Color : COLOR0;
	float2 UV0 : TEXCOORD0;
	float2 UV1 : TEXCOORD1;
	float2 UV2 : TEXCOORD2;
	float2 UV3 : TEXCOORD3;
};

//////////////////////////////////////////////////
// Vertex shader output
// Pixel shader input

#define VertexOutput Vertex2Pixel
#define PixelInput Vertex2Pixel

struct Vertex2Pixel
{
	// --- Position ---
	// XYZW: Screen (?) space position (or clip space?)
	float4 Position : SV_POSITION;

	// --- Color ---
	// XYZW: RGBA color
	float4 Color : COLOR;

	// --- UV set #1 ---
	// XY: Third UV map
	// ZW: Fourth UV map
	float4 UV01 : TEXCOORD0;

	// --- UV set #2 ---
	// XY: Third UV map
	// ZW: Fourth UV map
	float4 UV23 : TEXCOORD1;

	// --- World Normal ---
	// XYZ: World space normal direction
	// W: World space X position
	float4 WorldNormal : TEXCOORD2;

	// --- World Tangent ---
	// XYZ: World space tangent direction
	// W: World space Y position
	float4 WorldTangent : TEXCOORD3;

	// --- Preview view position ---
	// XYZ: Previous (?) Screen space position (or clip space?)
	// W: World space Z position
	float4 PrevPosition : TEXCOORD4;

	// --- Binormal orientation ---
	// X: Either 1 or -1; Use on the cross product between the normal and
	// 		tangent to get the correctly orientated binormal
	// Y: Instancing index (?)
	float2 BinormalOrientation : TEXCOORD11;

	#ifndef enable_deferred_rendering
		float4 ShadowPosition : TEXCOORD5;
		float Depth : TEXCOORD6;
		float3 Light1 : TEXCOORD7;
		float3 Light2 : TEXCOORD9;
	#endif

	#if defined(is_compute_instancing) && defined(enable_deferred_rendering)
		// --- Compute Instance Parameters ---
		// XYZ: HSV modifier values (range -0.5 to 0.5)
		// W: ?
		float4 ComputeInstanceParameters : TEXCOORD12;
	#endif
};

//////////////////////////////////////////////////
// Pixel shader output

// When using deferred rendering, we just output the surface data.
// Otherwise a pixel shader simply outputs the final color

#ifdef enable_deferred_rendering
	#include "Pixel/Surface/Struct.hlsl"
	#define PixelOutput SurfaceData
#else
	struct PixelOutput
	{
		float4 Color : SV_Target;
	};
#endif

#endif