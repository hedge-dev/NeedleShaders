#ifndef COMMON_SURFACE_INCLUDED
#define COMMON_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/MaterialDynamic.hlsl"
#include "../../ConstantBuffer/SHLightfieldProbes.hlsl"

#include "../../Debug.hlsl"
#include "../PBRUtils.hlsl"

#include "Struct.hlsl"
#include "ShadowCascade.hlsl"
#include "Weather.hlsl"
#include "MotionBlur.hlsl"

#include "GlobalIllumination/Base.hlsl"
#include "GlobalIllumination/AmbientOcclusion.hlsl"
#include "GlobalIllumination/Shadow.hlsl"

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

    switch(GetDebugMode())
    {
        case DebugModeNoNormalMap:
            normal = debug_normal;
            break;
        case DebugModeNoAlbedo:
            albedo = 1.0;
            break;
        case DebugModeNoAlbedoNoAO:
            albedo = 1.0;
            pbr_parameters.ambient_occlusion = 1.0;
            break;
    }

    ApplyAOGI(pbr_parameters.ambient_occlusion, gi_uv);

    ApplyWeatherEffects(
        albedo,
        pbr_parameters.specular,
        pbr_parameters.roughness,
        pbr_parameters.ambient_occlusion
    );

    result.albedo.xyz = albedo;
    result.prm = float4(
        pbr_parameters.specular,
        pbr_parameters.roughness,
        pbr_parameters.ambient_occlusion,
        pbr_parameters.metallic
    );

    result.emission.xyz = ComputeIllumination(
        gi_uv,
        world_position.xyz,
        albedo,
        emission,
        pbr_parameters
    );

    ApplyShadowCascadeThing(result.emission.xyz, world_position);

    result.emission.w = GetGIShadow(gi_uv);

    result.normal.xyz = normal * 0.5 + 0.5;
    result.motion_vector.xy = GetMotionVector(position, prev_position);

    // TODO figure out what these do
    result.albedo.w = (0.5 + (asuint(u_shading_model_flag.x) | 2)) / 255.0;
    result.o5.xy = u_model_user_param_3.xy;

	return result;
}

#endif