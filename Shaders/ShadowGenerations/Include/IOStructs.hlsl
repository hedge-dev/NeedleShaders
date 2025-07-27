#ifndef IO_STRUCTS_INCLUDED
#define IO_STRUCTS_INCLUDED

//////////////////////////////////////////////////
// Vertex shader input

struct VertexInput
{
	float4 position : POSITION0;
	float3 normal : NORMAL0;
	float3 tangent : TANGENT0;
	float3 binormal : BINORMAL0;
	float4 color : COLOR0;
	float2 uv0 : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float2 uv2 : TEXCOORD2;
	float2 uv3 : TEXCOORD3;

	#ifdef is_has_bone
		float4 bone_weights : BLENDWEIGHT0;
		uint4 bone_indices : BLENDINDICES0;

		#ifdef enable_max_bone_influences_8
			float4 bone_weights_2 : BLENDWEIGHT1;
			uint4 bone_indices_2 : BLENDINDICES1;
		#endif
	#endif

	#ifdef enable_multi_tangent_space
		float3 tangent_2 : TANGENT1;
		float3 binormal_2 : BINORMAL1;
	#endif

	#if defined(is_compute_instancing) || defined(is_instancing)
		uint instance_id : SV_InstanceID0;
	#endif
};

//////////////////////////////////////////////////
// Vertex shader output
// Pixel shader input

#define VertexOutput Vertex2Pixel
#define PixelInput Vertex2Pixel

struct Vertex2Pixel
{
	// --- Position ---
	// XYZW: Screen space position (aligned with pixels)
	float4 position : SV_POSITION;

	// --- Color ---
	// XYZW: RGBA color
	float4 color : COLOR0;

	// --- UV set #1 ---
	// XY: Third UV map
	// ZW: Fourth UV map
	float4 uv01 : TEXCOORD0;

	// --- UV set #2 ---
	// XY: Third UV map
	// ZW: Fourth UV map
	float4 uv23 : TEXCOORD1;

	// --- World Normal ---
	// XYZ: World space normal direction
	// W: World space X position
	float4 world_normal : TEXCOORD2;

	// --- World Tangent ---
	// XYZ: World space tangent direction
	// W: World space Y position
	float4 world_tangent : TEXCOORD3;

	// --- Preview view position ---
	// XY: Projection space XY position
	// Z: Projection space W position
	// W: World space Z position
	float4 previous_position : TEXCOORD4;

	// --- Binormal orientation ---
	// X: Either 1 or -1; Use on the cross product between the normal and
	// 		tangent to get the correctly orientated binormal
	// Y: Instancing index
	float2 binormal_orientation : TEXCOORD11;

	#ifdef enable_multi_tangent_space
		// --- Second World Tangent ---
		// XYZ: Second World space tangent direection
		// W: Second Binormal direction (see binormal_orientation)
		float4 world_tangent_2 : TEXCOORD10;
	#endif

	#ifndef enable_deferred_rendering
		float4 shadow_position : TEXCOORD5;
		float shadow_depth : TEXCOORD6;
		float3 light_scattering_factor : TEXCOORD7;
		float3 light_scattering_base : TEXCOORD9;
	#endif

	#if defined(is_compute_instancing)
		// --- Compute Instance Parameters ---
		// XYZ: HSV modifier values (range -0.5 to 0.5)
		// W: Instance transparency
		float4 compute_instance_parameters : TEXCOORD12;
	#endif
};

#define WorldPosition(input) float3(input.world_normal.w, input.world_tangent.w, input.previous_position.w)
#define WorldPosition4(input) float4(input.world_normal.w, input.world_tangent.w, input.previous_position.w, 1.0)

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

//////////////////////////////////////////////////
// Blit shader structs

struct BlitIn
{
	float4 pixel_position : SV_POSITION0;
	float2 screen_position : TEXCOORD0;
};

#endif
