#ifndef BONE_VERTEX_INCLUDED
#define BONE_VERTEX_INCLUDED

#include "../Common.hlsl"

#if !defined(enable_max_bone_influences_8) && !defined(no_enable_max_bone_influences_8)
	DefineFeature(enable_max_bone_influences_8);
#endif

#if !defined(is_has_bone) && !defined(no_is_has_bone)
	DefineFeature(is_has_bone);
#endif

#include "../ConstantBuffer/Bones.hlsl"
#include "../ConstantBuffer/PreviousBones.hlsl"
#include "../IOStructs.hlsl"
#include "../Transform.hlsl"

float4x4 GetBone4Matrix(float4 weights, uint4 indices, float3x4 bone_matrices[4])
{
	weights.w = 1
		- weights.x
		- weights.y
		- weights.z;

	float3x4 result =
		mul(weights.x, bone_matrices[indices.x])
		+ mul(weights.y, bone_matrices[indices.y])
		+ mul(weights.z, bone_matrices[indices.z])
		+ mul(weights.w, bone_matrices[indices.w]);

	return transpose(float4x4(result, 0, 0, 0, 1));
}

float4x4 GetBone8Matrix(float4 weights1, float4 weights2, uint4 indices1, uint4 indices2, float3x4 bone_matrices[4])
{
	weights2.w = 1
		- weights1.x
		- weights1.y
		- weights1.z
		- weights1.w
		- weights2.x
		- weights2.y
		- weights2.z;

	float3x4 result =
		mul(weights1.x, bone_matrices[indices1.x])
		+ mul(weights1.y, bone_matrices[indices1.y])
		+ mul(weights1.z, bone_matrices[indices1.z])
		+ mul(weights1.w, bone_matrices[indices1.w])
		+ mul(weights2.x, bone_matrices[indices2.x])
		+ mul(weights2.y, bone_matrices[indices2.y])
		+ mul(weights2.z, bone_matrices[indices2.z])
		+ mul(weights2.w, bone_matrices[indices2.w]);

	return transpose(float4x4(result, 0, 0, 0, 1));
}

#ifdef is_has_bone

VertexInput ComputeDynamicBoneInput(VertexInput input, float3x4 bone_matrices[4])
{
	VertexInput result = input;

	float4x4 bone_matrix;

	#ifdef enable_max_bone_influences_8
		bone_matrix = GetBone8Matrix(
			result.bone_weights,
			result.bone_weights_2,
			result.bone_indices,
			result.bone_indices_2,
			bone_matrices);
	#else
		bone_matrix = GetBone4Matrix(
			result.bone_weights,
			result.bone_indices,
			bone_matrices);
	#endif

	result.position.xyz = TransformPosition3(result.position.xyz, bone_matrix);
	result.normal = TransformDirection(result.normal, bone_matrix);
	result.tangent = TransformDirection(result.tangent, bone_matrix);
	result.binormal = TransformDirection(result.binormal, bone_matrix);

	#ifdef enable_multi_tangent_space
		result.tangent_2 = TransformDirection(result.tangent_2, bone_matrix);
		result.binormal_2 = TransformDirection(result.binormal_2, bone_matrix);
	#endif

	return result;
}

VertexInput ComputeBoneInput(VertexInput input)
{
	return ComputeDynamicBoneInput(input, needle_bone_matrix);
}

VertexInput ComputePreviousBoneInput(VertexInput input)
{
	return ComputeDynamicBoneInput(input, needle_prev_bone_matrix);
}

#endif

#endif