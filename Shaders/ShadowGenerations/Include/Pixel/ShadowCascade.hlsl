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

float GetShadowDepth(float4 position)
{
    return -dot(shadow_camera_view_matrix_third_row, position);
}

int GetShadowCascadeLevel(float4 position)
{
    int result = CountTrue(shadow_cascade_frustums_eye_space_depth < GetShadowDepth(position));

    // no idea what this is for, but definitely not for anything here so far
    if(GetShadowMapData().cascade_count <= 0)
    {
        result += 4;
    }

    return result;
}

float ComputeShadowCascadeLevelStep(float4 position, int level, float scale)
{
    if(scale == 0.0)
    {
        return 0.0;
    }

    float level_depth = dot(
        shadow_cascade_frustums_eye_space_depth,
        shadow_cascade_levels[level]
    );

    return saturate((level_depth - GetShadowDepth(position)) * scale);
}

float3 ComputeShadowCascadeLevelColor(float4 position, int level, float level_step)
{
    ShadowMapData data = GetShadowMapData();

    if(level >= data.cascade_count)
    {
        return 1.0;
    }

    float3 shadow_view_position = mul(shadow_view_matrix, position).xyz
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
        position,
        data.cascade_count - 1,
        data.level_end_scale
    );

    return lerp(1.0, result, result_factor);
}

float3 ComputeShadowCascadeColor(float4 position)
{
    ShadowMapData data = GetShadowMapData();

    if(data.shadow_filter_mode != ShadowFilterMode_Invalid)
    {
        return 1.0;
    }

    int level = GetShadowCascadeLevel(position);

    float level_step = 1.0 - ComputeShadowCascadeLevelStep(
        position,
        level,
        data.level_step_scale
    );

    return ComputeShadowCascadeLevelColor(position, level, level_step);
}

#endif