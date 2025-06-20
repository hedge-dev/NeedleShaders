#ifndef SHADOW_CASCADE_SURFACE_INCLUDED
#define SHADOW_CASCADE_SURFACE_INCLUDED

#include "../ConstantBuffer/World.hlsl"

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

void ApplyShadowCascadeThing(float3 position, inout float3 emission)
{
    if(shadow_map_parameter[0].z != -1.0)
    {
        return;
    }

    float view_dot = dot(shadow_camera_view_matrix_third_row.xyzw, float4(position, 1.0));
    int shadow_cascade = (int)dot(float4(1.0, 1.0, 1.0, 1.0), shadow_cascade_frustums_eye_space_depth < -view_dot);

    int parameter_cascade = (int)shadow_map_parameter[0].y;
    if(parameter_cascade <= 0)
    {
        shadow_cascade += 4;
    }

    float other_shadow_cascade = 0.0;
    if(shadow_map_parameter[1].z != 0.0)
    {
        other_shadow_cascade = 1.0 - saturate(
            shadow_map_parameter[1].z * (
                dot(
                    shadow_cascade_frustums_eye_space_depth,
                    shadow_cascade_levels[shadow_cascade]
                ) + view_dot
            )
        );
    }

    if(shadow_cascade >= parameter_cascade)
    {
        return;
    }

    float3 shadow_view_position = mul(shadow_view_matrix, float4(position, 1.0)).xyz
        * shadow_cascade_scale[shadow_cascade].xyz
        + shadow_cascade_offset[shadow_cascade].xyz;

    if(shadow_view_position.x < 0.0 || shadow_view_position.x >= 1.0
        || shadow_view_position.y < 0.0 || shadow_view_position.y >= 1.0
        || shadow_view_position.z < 0.0 || shadow_view_position.z >= 1.0)
    {
        return;
    }

    parameter_cascade -= 1;
    int another_cascade = min(shadow_cascade + 1, parameter_cascade);

    float last_cascade = dot(shadow_cascade_frustums_eye_space_depth, shadow_cascade_levels[parameter_cascade]);
    last_cascade += view_dot;
    last_cascade = saturate(shadow_map_parameter[1].x * last_cascade);

    emission *= lerp(
        1.0,
        lerp(
            shadow_cascade_params[shadow_cascade],
            shadow_cascade_params[another_cascade],
            other_shadow_cascade
        ),
        last_cascade
    );
}

#endif