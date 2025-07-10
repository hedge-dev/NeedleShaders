#ifndef SHADOW_CASCADE_SURFACE_INCLUDED
#define SHADOW_CASCADE_SURFACE_INCLUDED

#include "../ConstantBuffer/World.hlsl"
#include "../Math.hlsl"

static const float4 ShadowCascadeLevelMasks[] = {
    { 1.0, 0.0, 0.0, 0.0 },
    { 0.0, 1.0, 0.0, 0.0 },
    { 0.0, 0.0, 1.0, 0.0 },
    { 0.0, 0.0, 0.0, 1.0 },
};

static const float3 ShadowCascadeDebugColors[] = {
    { 1.5, 0.3, 0.3 },
    { 0.3, 1.5, 0.3 },
    { 0.3, 0.3, 5.5 },
    { 1.5, 0.3, 5.5 },
};

float3 ComputeShadowPosition(float4 world_position)
{
    return mul(world_position, shadow_view_matrix).xyz;
}

float ComputeShadowDepth(float4 world_position)
{
    return -dot(shadow_camera_view_matrix_third_row, world_position);
}

int GetShadowCascadeLevel(float depth)
{
    int result = CountTrue(shadow_cascade_frustums_eye_space_depth < depth);

    // no idea what this is for, but definitely not for anything here so far
    if(GetShadowMapData().cascade_count <= 0)
    {
        result += 4;
    }

    return result;
}

float ComputeShadowCascadeLevelStep(int level, float depth, float scale)
{
    if(scale == 0.0)
    {
        return 0.0;
    }

    float level_depth = dot(
        shadow_cascade_frustums_eye_space_depth,
        ShadowCascadeLevelMasks[level]
    );

    return saturate((level_depth - depth) * scale);
}

float3 ComputeShadowCascadeDebugColor(float4 world_position)
{
    ShadowMapData data = GetShadowMapData();

    if(data.shadow_filter_mode != ShadowFilterMode_Invalid)
    {
        return 1.0;
    }

    float3 position = ComputeShadowPosition(world_position);
    float depth = ComputeShadowDepth(world_position);
    int level = GetShadowCascadeLevel(depth);

    float level_step = 1.0 - ComputeShadowCascadeLevelStep(
        level,
        depth,
        data.level_step_scale
    );

    if(level >= data.cascade_count)
    {
        return 1.0;
    }

    float3 shadow_view_position = position
        * shadow_cascade_scale[level].xyz
        + shadow_cascade_offset[level].xyz;

    if(shadow_view_position.x < 0.0 || shadow_view_position.x >= 1.0
        || shadow_view_position.y < 0.0 || shadow_view_position.y >= 1.0
        || shadow_view_position.z < 0.0 || shadow_view_position.z >= 1.0)
    {
        return 1.0;
    }

    int next_level = min(level + 1, data.cascade_count - 1);
    float3 result = lerp(
        ShadowCascadeDebugColors[level],
        ShadowCascadeDebugColors[next_level],
        level_step
    );

    float result_factor = ComputeShadowCascadeLevelStep(
        data.cascade_count - 1,
        depth,
        data.level_end_scale
    );

    return lerp(1.0, result, result_factor);
}

#endif