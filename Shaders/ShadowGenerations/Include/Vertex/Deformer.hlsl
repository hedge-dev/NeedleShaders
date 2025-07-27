#ifndef DEFORMER_VERTEX_INCLUDED
#define DEFORMER_VERTEX_INCLUDED

#include "../ConstantBuffer/Deformer.hlsl"
#include "../Transform.hlsl"
#include "../Math.hlsl"

// Notes:
// -This feature was shown off in the autodesk interview. Yet to be seen ingame
// -Possibly busts normals considering how it handles everything as offsets
// -Does layers multiple even work properly???

struct DeformerData
{
	float radius;
	int radius_type;

	float transform_factor;
	float normal_offset_factor;

	float4x4 deform_matrix;
	float4x4 inv_deform_matrix;

	float3 offset;
	float3 scale;
	float3 rotation;

	float4x4 inv_origin_matrix;
	float3 wave_param;

	bool enable_udim_x_check;
};

DeformerData GetDeformerData(int index)
{
	int offset = 1 + index * 18;
	DeformerData result;

	// deformer_data_packed[offset].xyz;
	result.radius = deformer_data_packed[offset].w;

	result.radius_type = (int)deformer_data_packed[offset + 1].x;
	result.transform_factor = deformer_data_packed[offset + 1].y;
	result.normal_offset_factor = deformer_data_packed[offset + 1].z;
	// deformer_data_packed[offset + 1].w;

	result.deform_matrix = float4x4(
		deformer_data_packed[offset + 2],
		deformer_data_packed[offset + 3],
		deformer_data_packed[offset + 4],
		deformer_data_packed[offset + 5]
	);

	result.inv_deform_matrix = float4x4(
		deformer_data_packed[offset + 6],
		deformer_data_packed[offset + 7],
		deformer_data_packed[offset + 8],
		deformer_data_packed[offset + 9]
	);

	result.offset = deformer_data_packed[offset + 10].xyz;
	result.scale = deformer_data_packed[offset + 11].xyz;
	result.rotation = deformer_data_packed[offset + 12].xyz;

	result.inv_origin_matrix = float4x4(
		deformer_data_packed[offset + 13],
		deformer_data_packed[offset + 14],
		deformer_data_packed[offset + 15],
		deformer_data_packed[offset + 16]
	);

	result.wave_param = deformer_data_packed[offset + 17].xyz;
	result.enable_udim_x_check = deformer_data_packed[offset + 17].w > 0;

	return result;

}


void ApplyDeformers(inout float3 position, inout float3 normal, inout float3 tangent, inout float3 tangent_2, float2 uv)
{
	int count = (int)deformer_data_packed[0].x;

	if(count <= 0)
	{
		return;
	}

	count = min(3, count);

	float3 position_offset = 0.0;
	float3 normal_offset = 0.0;
	float3 tangent_offset = 0.0;
	float3 tangent_2_offset = 0.0;

	for(int i = 0; i < count; i++)
	{
		DeformerData dd = GetDeformerData(i);


		bool udim_x_check =
			dd.enable_udim_x_check
			&& uv.x >= 1.0
			&& i == ((int)floor(uv.x) - 1);

		if(udim_x_check)
		{
			continue;
		}

		float factor = 0.0;
		float distance = length(TransformPosition3(position, dd.inv_origin_matrix));

		switch (dd.radius_type) {
			case 0:
				factor = saturate(1.0 - (distance / dd.radius));
				break;

			case 1:
				factor = saturate(distance / dd.radius);
				break;

			case 2:
				factor = 1.0;
				break;

			case 3:
				float3 p = dd.wave_param;
				factor = cos((p.y * distance * Pi + p.z) / p.x) * 0.5 + 0.5;
				factor *= saturate(1.0 - (distance / dd.radius));
				break;
			default:
				break;
		}

		if(factor == 0)
		{
			continue;
		}

		float transform_factor = dd.transform_factor * factor;

		// into deform space
		float4 deform_position = TransformPosition3To4H(position, dd.inv_deform_matrix);
		float3 deform_normal = TransformDirection(normal, dd.inv_deform_matrix);
		float3 deform_tangent = TransformDirection(tangent, dd.inv_deform_matrix);
		float3 deform_tangent_2 = TransformDirection(tangent_2, dd.inv_deform_matrix);

		// Apply transformations
		deform_position.xyz += dd.offset * transform_factor;

		float3x3 rotation = ZYXEulerToRotationMatrix(dd.rotation * transform_factor);
		deform_position.xyz = TransformDirection3x3(deform_position.xyz, rotation);
		deform_normal = TransformDirection3x3(deform_normal, rotation);
		deform_tangent = TransformDirection3x3(deform_tangent, rotation);
		deform_tangent_2 = TransformDirection3x3(deform_tangent_2, rotation);

		deform_position.xyz *= lerp(1.0, dd.scale, transform_factor);
		deform_position.xyz += deform_normal * dd.normal_offset_factor * factor;

		// Back into the local space
		deform_position = TransformPosition4(deform_position, dd.deform_matrix);
		deform_normal = TransformDirection(deform_normal, dd.deform_matrix);
		deform_tangent = TransformDirection(deform_tangent, dd.deform_matrix);
		deform_tangent_2 = TransformDirection(deform_tangent_2, dd.deform_matrix);

		// Storing the offsets
		position_offset += deform_position.xyz - position;
		normal_offset += deform_normal - normal;
		tangent_offset += deform_tangent - tangent;
		tangent_2_offset += deform_tangent_2 - tangent_2;
    }

	position += position_offset;
	normal += normal_offset;
	tangent += tangent_offset;
	tangent_2 += tangent_2_offset;
}

#endif