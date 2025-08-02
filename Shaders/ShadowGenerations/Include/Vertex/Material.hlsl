#ifndef MATERIAL_VERTEX_INCLUDED
#define MATERIAL_VERTEX_INCLUDED

#include "../Common.hlsl"

#if !defined(enable_deferred_rendering) && !defined(no_enable_deferred_rendering)
	DefineFeature(enable_deferred_rendering);
#endif

#if !defined(enable_multi_tangent_space) && !defined(no_enable_multi_tangent_space)
	DefineFeature(enable_multi_tangent_space);
#endif

#include "Billboard.hlsl"
#include "VertexAnimationTextures.hlsl"
#include "Instancing.hlsl"
#include "Bone.hlsl"
#include "Deformer.hlsl"
#include "../LightScattering.hlsl"
#include "../Transform.hlsl"

#include "../ConstantBuffer/World.hlsl"
#include "../ConstantBuffer/MaterialDynamic.hlsl"
#include "../ConstantBuffer/MaterialImmutable.hlsl"

#include "../IOStructs.hlsl"

MaterialImmutables
{
    bool u_enable_billboard_y;
}

float4x4 GetWorldMatrix(float4x4 world_matrix, float4x4 inv_view_matrix)
{
	#ifdef u_enable_billboard
		return ComputeBillboardMatrix(world_matrix, inv_view_matrix, u_cameraPosition.xyz, u_enable_billboard_y);
	#else
		return world_matrix;
	#endif
}

bool2 PreviousTimeCheck()
{
	int4 time_param = asuint(g_time_param);
	int4 timestamp = asuint(u_timestamp);

  	return time_param.ww == timestamp.zx && timestamp.zx - timestamp.wy == 1;
}

float3 GetPreviousPosition(float3 local_position, float3 world_position)
{
    float3 prev_world_position = world_position;

    if(PreviousTimeCheck().y)
    {
		float4x4 local_previous_world_matrix = GetWorldMatrix(prev_world_matrix, inv_view_matrix);
        prev_world_position = TransformPosition3(local_position, local_previous_world_matrix);
    }

    return TransformPosition3To4H(prev_world_position, prev_view_proj_matrix).xyw;
}


VertexOutput SetupVertexOutput(const VertexInput input)
{
	VertexOutput result;

	VertexInput local_input = input;
	VertexInput previous_local_input = input;
	#ifdef is_has_bone
		local_input = ComputeBoneInput(input);

		if(PreviousTimeCheck().x)
		{
			previous_local_input = ComputePreviousBoneInput(input);
		}
		else
		{
			previous_local_input = local_input;
		}

		float3 pre_deform_pos = local_input.position.xyz;
		float3 tangent_2_placeholder = 0.0;

		ApplyDeformers(
			local_input.position.xyz,
			local_input.normal,
			local_input.tangent,

			#ifdef enable_multi_tangent_space
				local_input.tangent_2,
			#else
				tangent_2_placeholder,
			#endif

			input.uv0
		);

		previous_local_input.position.xyz += pre_deform_pos - local_input.position.xyz;
	#endif

	#ifdef is_vat_enabled
		ComputeVertexAnimation(
			input.uv1.x,
			local_input.color.xyz,
			local_input.position.xyz,
			local_input.normal,
			previous_local_input.position.xyz
		);
	#endif

	float4x4 local_world_matrix = world_matrix;

	#if defined(is_compute_instancing)
		result.binormal_orientation.y = input.instance_id;
		ComputeInstanceParameters cip = GetComputeInstanceParameters(input.instance_id);

		local_world_matrix = mul(cip.ci_matrix, local_world_matrix);
		previous_local_input.position.xyz = TransformPosition3(previous_local_input.position.xyz, cip.ci_matrix);

		result.compute_instance_parameters = cip.ci_parameter;

	#elif defined(is_instancing)
		result.binormal_orientation.y = input.instance_id;
		InstanceData ip = GetInstanceData(input.instance_id);

		local_world_matrix = mul(ip.instance_matrix, local_world_matrix);
		previous_local_input.position.xyz = TransformPosition3(previous_local_input.position.xyz, ip.instance_matrix);

	#else
		result.binormal_orientation.y = -1;
	#endif

	local_world_matrix = GetWorldMatrix(local_world_matrix, inv_view_matrix);

	float3 world_position = TransformPosition3(local_input.position.xyz, local_world_matrix);
	float3 view_position = TransformPosition3(world_position, view_matrix);
	float4 projection_position = TransformPosition3To4H(view_position, proj_matrix);

	result.position = projection_position;
	result.previous_position.xyz = GetPreviousPosition(previous_local_input.position.xyz, world_position);

	result.world_normal.xyz = TransformDirection(local_input.normal, local_world_matrix);
    result.world_tangent.xyz = TransformDirection(local_input.tangent, local_world_matrix);
	result.binormal_orientation.x = sign(dot(input.binormal, cross(input.normal, input.tangent)));

	#ifdef enable_multi_tangent_space
		result.world_tangent_2.xyz = TransformDirection(local_input.tangent_2, local_world_matrix);
		result.world_tangent_2.w = sign(dot(input.binormal_2, cross(input.normal, input.tangent_2)));
	#endif

	#ifndef enable_deferred_rendering
		float3 view_dir = normalize(u_cameraPosition.xyz - world_position.xyz);
		LightScatteringColors lsc = ComputeLightScatteringColors(-view_position.z, view_dir);
		result.light_scattering_base = lsc.base;
		result.light_scattering_factor = lsc.factor;

		result.shadow_position = TransformPosition3To4H(world_position, shadow_view_matrix);
		result.shadow_depth = -view_position.z;
	#endif

	result.color = input.color;
    result.uv01 = float4(input.uv0, input.uv1);
    result.uv23 = float4(input.uv2, input.uv3);

	result.world_normal.w = world_position.x;
    result.world_tangent.w = world_position.y;
    result.previous_position.w = world_position.z;

	return result;
}

#endif