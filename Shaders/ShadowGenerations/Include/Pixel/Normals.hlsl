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

float3 TransformNormal(float3 to_transform, float3 normal, float3 tangent, float3 binormal)
{
    return normalize(
        to_transform.x * tangent
        + to_transform.y * binormal
        + to_transform.z * normal
    );
}

float3 UnpackNormalMap(float2 normal_map, float3 normal, float3 tangent, float3 binormal)
{
    float3 local_normal = DenormalizeNormalMap(normal_map);

    return TransformNormal(local_normal, normal, tangent, binormal);
}

float3 UnpackNormalMapSafe(float2 normal_map, float3 normal, float3 tangent, float3 binormal)
{
    float3 result = UnpackNormalMap(normal_map, normal, tangent, binormal);

    bool3 nan_check = result != result;
    if(nan_check.x | nan_check.y | nan_check.z)
    {
        return normal;
    }
    else
    {
        return result;
    }
}

float3 BlendNormals(float3 a, float3 b)
{
    a += float3(0, 0, 1);
    b *= float3(-1, -1, 1);

    return a * dot(a, b) / a.z - b;
}

//////////////////////////////////////////////////

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
        result.tangent = normalize(input.world_tangent_2.xyz);
        result.binormal = normalize(cross(result.normal, result.tangent) * input.world_tangent_2.w);
    #else
        result.tangent = normalize(input.world_tangent.xyz);
        result.binormal = normalize(cross(result.normal, result.tangent) * input.binormal_orientation.x);
    #endif

    return result;
}

float3 TransformNormal(float3 normal, NormalDirections directions)
{
    return TransformNormal(normal, directions.normal, directions.tangent, directions.binormal);
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