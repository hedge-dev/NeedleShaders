#ifndef SHADOW_CASCADE_SURFACE_INCLUDED
#define SHADOW_CASCADE_SURFACE_INCLUDED

#include "../ConstantBuffer/World.hlsl"
#include "../Math.hlsl"

static const float4 shadow_cascade_levels[] = {
    { 1.0, 0.0, 0.0, 0.0 },
    { 0.0, 1.0, 0.0, 0.0 },
    { 0.0, 0.0, 1.0, 0.0 },
    { 0.0, 0.0, 0.0, 1.0 },
};

static const float3 shadow_cascade_params[] = {
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
        shadow_cascade_levels[level]
    );

    return saturate((level_depth - depth) * scale);
}

float3 ComputeShadowCascadeLevelColor(float3 shadow_position, float shadow_depth, int level, float level_step)
{
    ShadowMapData data = GetShadowMapData();

    if(level >= data.cascade_count)
    {
        return 1.0;
    }

    float3 shadow_view_position = shadow_position
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
        shadow_cascade_params[level],
        shadow_cascade_params[next_level],
        level_step
    );

    float result_factor = ComputeShadowCascadeLevelStep(
        shadow_depth,
        data.cascade_count - 1,
        data.level_end_scale
    );

    return lerp(1.0, result, result_factor);
}

float3 ComputeShadowCascadeColor(float4 world_position)
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
        depth,
        level,
        data.level_step_scale
    );

    return ComputeShadowCascadeLevelColor(position, depth, level, level_step);
}

#endif