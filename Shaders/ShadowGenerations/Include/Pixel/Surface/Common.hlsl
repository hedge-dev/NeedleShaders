#ifndef COMMON_SURFACE_INCLUDED
#define COMMON_SURFACE_INCLUDED

#include "Struct.hlsl"

#include "../Debug.hlsl"

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/MaterialDynamic.hlsl"
#include "../../ConstantBuffer/SHLightfieldProbes.hlsl"

#if !defined(NO_SPECULAR_ADJUSTMENT) && !defined(SPECULAR_ADJUSTMENT_VALUE)
#define SPECULAR_ADJUSTMENT_VALUE 0.25
#endif

// TODO figure out the context behind this
#define WEATHER_PARAMETER_FLAG_BIT 2

SurfaceData CreateCommonSurface(
	float3 position,
	float3 prev_position,
	float3 albedo,
	float3 normal,
    float3 debug_normal,
	float3 emission,
	float4 prm)
{
	SurfaceData result;

    //////////////////////////////////////////////////
    // PBR Parameter adjustments

    prm.x *= SPECULAR_ADJUSTMENT_VALUE;
    prm.y = max(0.01, 1.0 - prm.y);

    //////////////////////////////////////////////////
    // Debug modes

    DebugSwitch(
        normal,
        albedo,
        prm.w,
        debug_normal
    );

    //////////////////////////////////////////////////
    // Adjusting ambient occlusion

    float4 local_prm = prm;

    if((int)u_sggi_param[1].z == 5)
    {
        local_prm.w = 0.0;
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
            local_prm.xyw,
            float3(0.02, 0.1, 1),
            saturate((weather_param.xxx - float3(0.2, 0.2, 0.45)) * float3(1.25, 1.25, 2))
        );
    }
    else
    {
        result.albedo.xyz = albedo;
        result.prm.xyz = local_prm.xyw;
    }


    //////////////////////////////////////////////////
    // (?)

    result.emission.w = shlightfield_param.x > 0 ? 0.0001 : 1;

    if(!enable_shadow_map)
    {
        result.emission.w = -result.emission.w;
    }

    //////////////////////////////////////////////////
    // (?)

    result.albedo.w = (0.5 + ((int)u_shading_model_flag.x | 2)) / 255.0;


    //////////////////////////////////////////////////
    // Normal

    result.normal.xyz = normal * 0.5 + 0.5;

    //////////////////////////////////////////////////
    // (?)

    result.o4.xy = position.xy - jitter_offset.xy - (u_viewport_info.xy * ((prev_position.xy / prev_position.zz) * float2(1,-1) + float2(1,1)) * 0.5 - jitter_offset.zw);

    //////////////////////////////////////////////////
    // (?)

    result.normal.w = 0;

    //////////////////////////////////////////////////
    // Emission

    result.emission.xyz = emission;

    //////////////////////////////////////////////////
    // Metallic

    result.prm.w = local_prm.z;

    //////////////////////////////////////////////////
    // (?)

    result.o4.zw = 0.0;

    //////////////////////////////////////////////////
    // (?)

    result.o5.xy = u_model_user_param_3.xy;

    //////////////////////////////////////////////////
    // (?)

    result.o5.zw = 0.0;


	return result;
}

#endif