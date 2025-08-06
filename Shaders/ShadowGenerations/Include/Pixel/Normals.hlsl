#ifndef NORMALS_INCLUDED
#define NORMALS_INCLUDED

#include "../IOStructs.hlsl"

float3 CorrectedZNormal(float3 normal)
{
    return float3(
        normal.x,
        normal.y,
        sign(normal.z) * sqrt(1.0 - min(1.0, dot(normal.xy, normal.xy)))
    );
}

float3 ComputeBinormal(float3 normal, float3 tangent)
{
    return normalize(cross(normal, tangent));
}

float3 DenormalizeNormalMap(float2 normal_map)
{
    float2 remapped = normal_map * 2.0 - 1.0;

    return float3(
        remapped.x,
        remapped.y,
        sqrt(1.0 - min(1.0, dot(remapped, remapped)))
    );
}

float3 LocalToWorldNormal(float3 local_normal, float3 world_normal, float3 world_tangent, float3 world_binormal)
{
    return normalize(
        local_normal.x * world_tangent
        + local_normal.y * world_binormal
        + local_normal.z * world_normal
    );
}

float3 UnpackNormalMap(float2 normal_map, float3 world_normal, float3 world_tangent, float3 world_binormal)
{
    float3 local_normal = DenormalizeNormalMap(normal_map);
    return LocalToWorldNormal(local_normal, world_normal, world_tangent, world_binormal);
}

float3 UnpackNormalMapSafe(float2 normal_map, float3 world_normal, float3 world_tangent, float3 world_binormal)
{
    float3 result = UnpackNormalMap(normal_map, world_normal, world_tangent, world_binormal);

    bool3 nan_check = result != result;
    if(nan_check.x | nan_check.y | nan_check.z)
    {
        return world_normal;
    }
    else
    {
        return result;
    }
}

struct NormalDirections
{
    float3 normal;
    float3 tangent;
    float3 binormal;
};

NormalDirections ComputeWorldNormalDirs(PixelInput input)
{
    NormalDirections result;

    result.normal = normalize(input.world_normal.xyz);
    result.tangent = normalize(input.world_tangent.xyz);
    result.binormal = normalize(cross(result.normal, result.tangent) * input.binormal_orientation.x);

    return result;
}

NormalDirections ComputeWorldNormalDirs2(PixelInput input)
{
    NormalDirections result;

    result.normal = normalize(input.world_normal.xyz);

    #ifdef enable_multi_tangent_space
        result.tangent = normalize(input.world_tangent2.xyz);
        result.binormal = normalize(cross(result.normal, result.tangent2) * input.tangent2.w);
    #else
        result.tangent = normalize(input.world_tangent.xyz);
        result.binormal = normalize(cross(result.normal, result.tangent) * input.binormal_orientation.x);
    #endif

    return result;
}

float3 UnpackNormalMap(float2 normal_map, NormalDirections directions)
{
    return UnpackNormalMap(normal_map, directions.normal, directions.tangent, directions.binormal);
}

float3 UnpackNormalMapSafe(float2 normal_map, NormalDirections directions)
{
    return UnpackNormalMapSafe(normal_map, directions.normal, directions.tangent, directions.binormal);
}

#endif