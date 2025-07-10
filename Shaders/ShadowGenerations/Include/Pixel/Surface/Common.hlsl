#ifndef COMMON_SURFACE_INCLUDED
#define COMMON_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../Debug.hlsl"
#include "../ShadowCascade.hlsl"

#include "Struct.hlsl"
#include "Weather.hlsl"
#include "MotionBlur.hlsl"

#include "GlobalIllumination/Base.hlsl"
#include "GlobalIllumination/AmbientOcclusion.hlsl"
#include "GlobalIllumination/Occlusion.hlsl"

void SetupCommonSurface(inout SurfaceParameters parameters)
{
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
            parameters.cavity = 1.0;
            break;
    }

    ApplyAOGI(parameters);
    ApplyWeatherEffects(parameters);

    ApplyGlobalIllumination(parameters);
    parameters.emission *= ComputeShadowCascadeDebugColor(parameters.world_position);

    parameters.typed_occlusion = ComputeGIOcclusion(parameters.gi_uv);

    parameters.velocity = ComputeVelocity(parameters.pixel_position, parameters.previous_position);

    // TODO figure out what these do
    parameters.unk_o5 = u_model_user_param_3.xy;
}

#endif