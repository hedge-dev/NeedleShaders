#ifndef INSTANCING_VERTEX_INCLUDED
#define INSTANCING_VERTEX_INCLUDED

#include "../Common.hlsl"
#include "../Transform.hlsl"

#if !defined(is_compute_instancing) && !defined(no_is_compute_instancing)
	DefineFeature(is_compute_instancing);
#endif

#if !defined(is_instancing) && !defined(no_is_instancing)
	DefineFeature(is_instancing);
#endif

#if defined(is_compute_instancing)

	#include "../ConstantBuffer/MaterialDynamic.hlsl"

	struct ComputeInstanceBuffer
	{
		float4 position;
		float4 scale;
		float4 quaternion;
		uint4 interaction;
		uint4 append;
		int shadow;
	};

	StructuredBuffer<ComputeInstanceBuffer> s_User1;
	StructuredBuffer<uint> s_User2;

	struct ComputeInstanceParameters
	{
		float4x4 ci_matrix;
		float4 ci_parameter;
	};

	ComputeInstanceParameters GetComputeInstanceParameters(uint instance_index)
	{
		uint compute_instance_index = (uint)floor(u_compute_instance_param.x);
		compute_instance_index = s_User2[compute_instance_index].x;
		compute_instance_index += instance_index;

		uint buffer_index = s_User2[compute_instance_index].x;
		bool unk = buffer_index >> 31;
		buffer_index &= 0x7fffffff;

		ComputeInstanceBuffer buffer = s_User1[buffer_index];

		ComputeInstanceParameters result;

		result.ci_matrix = CreateTransformMatrixQuat(
			buffer.position.xyz,
			buffer.quaternion,
			buffer.scale.xyz
		);

		uint packed_append = asuint(buffer.append.x);
		float3 unpacked_append = float3(
			(packed_append & 0x7FF) / 2047.0,
			((packed_append >> 11) & 0x7FF) / 2047.0,
			(packed_append >> 22) / 1023.0
		);

		result.ci_parameter.xyz = unpacked_append - 0.5;
		result.ci_parameter.w = buffer.append.w;
		if(unk)
		{
			result.ci_parameter.w = -result.ci_parameter.w;
		}

		return result;
	}

#elif defined(is_instancing)
	#include "../ConstantBuffer/Instancing.hlsl"
#endif

#endif