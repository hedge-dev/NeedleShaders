#ifndef BILLBOARD_VERTEX_INCLUDED
#define BILLBOARD_VERTEX_INCLUDED

#include "../Common.hlsl"

#if !defined(u_enable_billboard) && !defined(no_u_enable_billboard)
	DefineFeature(u_enable_billboard);
#endif

#include "../Transform.hlsl"

float4x4 ComputeBillboardMatrix(float4x4 world_matrix, float4x4 inv_view_matrix, float3 camera_position, bool enable_billboard_y)
{
    float3x3 rotation_matrix;

	if(enable_billboard_y)
	{
		rotation_matrix = CreateLookAtMatrix(
            world_matrix._m30_m31_m32,
            normalize(world_matrix._m20_m21_m22),
            normalize(world_matrix._m10_m11_m12),
            camera_position.xyz
        );
	}
	else
	{
        rotation_matrix = (float3x3)inv_view_matrix;
	}

    float3x3 result_rotation = mul((float3x3)world_matrix, rotation_matrix);

    return float4x4(
        result_rotation._m00_m01_m02, 0,
        result_rotation._m10_m11_m12, 0,
        result_rotation._m20_m21_m22, 0,
        world_matrix._m30_m31_m32, 1
    );
}

#endif