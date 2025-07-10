#ifndef NORMALS_INCLUDED
#define NORMALS_INCLUDED

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

float3 UnpackNormalMapToWorldSpace(float2 normal_map, float3 world_normal, float3 world_tangent, float3 world_binormal)
{
    float3 local_normal = DenormalizeNormalMap(normal_map);
    return LocalToWorldNormal(local_normal, world_normal, world_tangent, world_binormal);
}

float3 UnpackNormalMapToWorldSpaceSafe(float2 normal_map, float3 world_normal, float3 world_tangent, float3 world_binormal)
{
    float3 result = UnpackNormalMapToWorldSpace(normal_map, world_normal, world_tangent, world_binormal);

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

#endif