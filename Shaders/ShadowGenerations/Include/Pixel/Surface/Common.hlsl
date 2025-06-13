#ifndef COMMON_SURFACE_INCLUDED
#define COMMON_SURFACE_INCLUDED

static const uint FEATURE_is_use_gi_prt;
static const uint FEATURE_is_use_gi_sg;
static const uint FEATURE_is_use_gi;

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/MaterialDynamic.hlsl"
#include "../../ConstantBuffer/SHLightfieldProbes.hlsl"

#include "../../Debug.hlsl"
#include "../../Common.hlsl"
#include "../PBRUtils.hlsl"
#include "Struct.hlsl"

// TODO figure out the context behind this
#define WEATHER_PARAMETER_FLAG_BIT 2

// TODO figure out what these SGGI modes(?) do
#define SGGI_MODE_0 0
#define SGGI_MODE_1 1
#define SGGI_MODE_2 2
#define SGGI_MODE_3 3
#define SGGI_MODE_5 5
#define SGGI_MODE_6 6

#ifdef is_use_gi
    #ifdef is_use_gi_prt
        TextureArrayInput(gi_texture)
    #else
        TextureInput(gi_texture)
        TextureInput(gi_shadow_texture)
    #endif
#endif

static const float4 shadow_cascade_something[] = {
    { 1.0, 0.0, 0.0, 0.0 },
    { 0.0, 1.0, 0.0, 0.0 },
    { 0.0, 0.0, 1.0, 0.0 },
    { 0.0, 0.0, 0.0, 1.0 },

    { 1.5, 0.3, 0.3, 1.0 },
    { 0.3, 1.5, 0.3, 1.0 },
    { 0.3, 0.3, 5.5, 1.0 },
    { 1.5, 0.3, 5.5, 1.0 },
};

float3 GetShadowCascadeSomething(float4 world_position)
{
    if(shadow_map_parameter[0].z != -1.0)
    {
        return 1.0;
    }

    float view_dot = dot(shadow_camera_view_matrix_third_row.xyzw, world_position);
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
                    shadow_cascade_something[shadow_cascade]
                ) + view_dot
            )
        );
    }

    if(shadow_cascade >= parameter_cascade)
    {
        return 1.0;
    }

    float3 shadow_view_position = mul(shadow_view_matrix, world_position).xyz
        * shadow_cascade_scale[shadow_cascade].xyz
        + shadow_cascade_offset[shadow_cascade].xyz;

    if(shadow_view_position.x < 0.0 || shadow_view_position.x >= 1.0
        || shadow_view_position.y < 0.0 || shadow_view_position.y >= 1.0
        || shadow_view_position.z < 0.0 || shadow_view_position.z >= 1.0)
    {
        return 1.0;
    }

    parameter_cascade -= 1;
    int another_cascade = min(shadow_cascade + 1, parameter_cascade); // r1.w

    float last_cascade = dot(shadow_cascade_frustums_eye_space_depth, shadow_cascade_something[parameter_cascade]); // r1.y
    last_cascade += view_dot;
    last_cascade = saturate(shadow_map_parameter[1].x * last_cascade);

    return lerp(
        1.0,
        lerp(
            shadow_cascade_something[shadow_cascade+4].xyz,
            shadow_cascade_something[another_cascade+4].xyz,
            other_shadow_cascade
        ),
        last_cascade
    );
}

SurfaceData CreateCommonSurface(
	float3 position,
	float3 prev_position,
    float4 world_position,
	float3 albedo,
	float3 normal,
    float3 debug_normal,
	float3 emission,
	PBRParameters pbr_parameters,
    float2 gi_uv)
{
	SurfaceData result;

    //////////////////////////////////////////////////
    // Debugging

    switch(DEBUG_MODE)
    {
        case DEBUG_MODE_NO_NORMAL_MAP:
            normal = debug_normal;
            break;
        case DEBUG_MODE_NO_ALBEDO:
            albedo = 1.0;
            break;
        case DEBUG_MODE_NO_ALBEDO_NO_AO:
            albedo = 1.0;
            pbr_parameters.ambient_occlusion = 1.0;
            break;
    }

    //////////////////////////////////////////////////
    // Global illumination textures

    float3 gi_color = 0.0;
    float gi_shadow = 1.0;

    #if defined(is_use_gi) && !defined(is_use_gi_prt)

        float4 gi_tex = SampleTexture(gi_texture, gi_uv);
        float gi_shadow_tex = SampleTexture(gi_shadow_texture, gi_uv).x;

        gi_color = gi_tex.xyz * pbr_parameters.metallic_inv * (1.0 - pbr_parameters.specular_color);
        gi_shadow = gi_tex.w * gi_shadow_tex;
    #endif

    //////////////////////////////////////////////////
    // Adjusting ambient occlusion

    uint sggi_mode = (uint)u_sggi_param[1].z;
    float gi_ao = 0.0;

    #if defined(is_use_gi) && defined(is_use_gi_prt)

        bool is_ao_mode = sggi_mode == SGGI_MODE_0
            || sggi_mode == SGGI_MODE_1
            || sggi_mode == SGGI_MODE_5;

        if(is_ao_mode)
        {
            gi_ao = saturate(SampleTextureLevel(gi_texture, float3(gi_uv, 0.0), 0).x);
            pbr_parameters.ambient_occlusion *= gi_ao;
        }

    #endif

    if(sggi_mode == SGGI_MODE_5)
    {
        pbr_parameters.ambient_occlusion = gi_ao;
    }

    //////////////////////////////////////////////////
    // Obtaining the weather parameter

    int weather_flag;

    if(WEATHER_PARAMETER_FLAG_BIT == 0)
    {
        weather_flag = false;
    }
    else if(WEATHER_PARAMETER_FLAG_BIT + 4 < 32)
    {
        weather_flag = (
            (
                (uint)u_shading_model_flag.x
                << (32 - (WEATHER_PARAMETER_FLAG_BIT + 4))
            ) >> (32 - WEATHER_PARAMETER_FLAG_BIT)
        ) == 1;
    }
    else
    {
        weather_flag = ((uint)u_shading_model_flag.x >> 4) == 1;
    }

	float weather_param = u_weather_param.x;
    if(weather_flag)
    {
        weather_param *= u_weather_param.w;
    }

	//////////////////////////////////////////////////
    // Albedo, Specular, Roughness and Ambient Occlusion

    if(weather_param > 0.0)
    {
        result.albedo.xyz = lerp(albedo, albedo * albedo, saturate(2.85714293 * weather_param));
        result.prm.xyz = lerp(
            float3(pbr_parameters.specular, pbr_parameters.roughness, pbr_parameters.ambient_occlusion),
            float3(0.02, 0.1, 1),
            saturate((weather_param.xxx - float3(0.2, 0.2, 0.45)) * float3(1.25, 1.25, 2))
        );
    }
    else
    {
        result.albedo.xyz = albedo;
        result.prm.xyz = float3(pbr_parameters.specular, pbr_parameters.roughness, pbr_parameters.ambient_occlusion);
    }

    float3 gi_color_2 = gi_color * result.albedo.xyz * result.prm.z; //prm.z = AO

    //////////////////////////////////////////////////
    // Global Illumination shadows (?)

    bool some_sggi_mode = true;
    float some_sggi_mode_add = 0.0;

    #ifdef is_use_gi

        some_sggi_mode =
            sggi_mode == SGGI_MODE_1
            || sggi_mode == SGGI_MODE_2
            || sggi_mode == SGGI_MODE_3
            || sggi_mode == SGGI_MODE_6;

        #ifdef is_use_gi_prt
            some_sggi_mode = some_sggi_mode || is_ao_mode;
        #endif

    #endif

    result.emission.w = shlightfield_param.x > 0 && some_sggi_mode ? 0.0001 : gi_shadow;

    if(!some_sggi_mode)
    {
        #ifdef is_use_gi_prt
            result.emission.w += 20.0;
        #else
            result.emission.w += 10.0;
        #endif
    }

    if(!enable_shadow_map)
    {
        result.emission.w = -result.emission.w;
    }

    //////////////////////////////////////////////////
    // Debugging

    // The optimized code is not a switch, and i am sure there is more to this,
    // but this is as far as i could see how this works so far
    switch(DEBUG_MODE)
    {
        case DEBUG_MODE_3:
            gi_color_2 = gi_color;
            break;
        case DEBUG_MODE_4:
            gi_color_2 = 0.0;
            break;
        case DEBUG_MODE_43:
            gi_color_2 = gi_color;
            break;
        case DEBUG_MODE_44:
            emission = 0.0;
            break;
    }

    //////////////////////////////////////////////////
    // (?)

    result.albedo.w = (0.5 + ((int)u_shading_model_flag.x | 2)) / 255.0;

    //////////////////////////////////////////////////
    // Normal

    result.normal.xyz = normal * 0.5 + 0.5;

    //////////////////////////////////////////////////
    // Motion blur direction (?)

    result.o4.xy = position.xy - jitter_offset.xy - (u_viewport_info.xy * ((prev_position.xy / prev_position.zz) * float2(1.0,-1.0) + 1.0) * 0.5 - jitter_offset.zw);

    //////////////////////////////////////////////////
    // SGGI stuff (?)

    gi_color_2 += emission;

    switch(DEBUG_MODE)
    {
        case DEBUG_MODE_12:
            gi_color_2 = gi_color;
            break;
        case DEBUG_MODE_19:
            gi_color_2 = gi_color;
            break;
    }

    result.emission.xyz = gi_color_2 * GetShadowCascadeSomething(world_position);

    //////////////////////////////////////////////////
    // (?)

    result.normal.w = 0;

    //////////////////////////////////////////////////
    // Metallic

    result.prm.w = pbr_parameters.metallic;

    //////////////////////////////////////////////////
    // (?)

    result.o4.zw = 0.0;

    //////////////////////////////////////////////////
    // (?)

    result.o5.xy = u_model_user_param_3.xy;
    result.o5.zw = 0.0;


	return result;
}

#endif