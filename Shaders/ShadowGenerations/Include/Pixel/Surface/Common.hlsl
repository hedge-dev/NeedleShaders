#ifndef COMMON_SURFACE_INCLUDED
#define COMMON_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/MaterialDynamic.hlsl"
#include "../../ConstantBuffer/SHLightfieldProbes.hlsl"

#include "../../Debug.hlsl"

#include "../ShadowCascade.hlsl"
#include "Struct.hlsl"
#include "Weather.hlsl"
#include "MotionBlur.hlsl"

#include "GlobalIllumination/Base.hlsl"
#include "GlobalIllumination/AmbientOcclusion.hlsl"
#include "GlobalIllumination/Shadow.hlsl"

SurfaceData CreateCommonSurface(SurfaceParameters parameters)
{
	SurfaceData result;

    switch(GetDebugView())
    {
        case DebugView_OnlyIblSurfNormal:
            parameters.normal = parameters.debug_normal;
            break;
        case DebugView_WhiteAlbedo:
            parameters.albedo = 1.0;
            break;
        case DebugView_WhiteAlbedoNoAo:
            parameters.albedo = 1.0;
            parameters.ambient_occlusion = 1.0;
            break;
    }

    ApplyAOGI(parameters);
    ApplyWeatherEffects(parameters);

    result.albedo.xyz = parameters.albedo;
    result.prm = float4(
        parameters.specular,
        parameters.roughness,
        parameters.ambient_occlusion,
        parameters.metallic
    );

    ApplyGlobalIllumination(parameters);
    ApplyShadowCascadeThing(parameters.world_position, parameters.emission);

    result.emission.xyz = parameters.emission;
    result.emission.w = ComputeGIShadow(parameters.gi_uv);

    result.normal.xyz = parameters.normal * 0.5 + 0.5;
    result.motion_vector.xy = ComputeMotionVector(parameters.screen_position, parameters.previous_position);

    uint deferred_flags = asuint(u_shading_model_flag.x) | parameters.shader_model;
    result.albedo.w = (0.5 + deferred_flags) / 255.0;

    // TODO figure out what these do
    result.o5.xy = u_model_user_param_3.xy;

	return result;
}

#endif