#ifndef COMMON_SURFACE_INCLUDED
#define COMMON_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ColorConversion.hlsl"
#include "../../Debug.hlsl"
#include "../ShadowCascade.hlsl"
#include "../Normals.hlsl"

#include "Struct.hlsl"

#include "ComputeInstancing.hlsl"
#include "GlobalIllumination/Base.hlsl"
#include "GlobalIllumination/AmbientOcclusion.hlsl"
#include "GlobalIllumination/Occlusion.hlsl"
#include "LuminanceNoise.hlsl"

#include "Weather.hlsl"
#include "MotionBlur.hlsl"

SurfaceParameters CreateCommonSurface(PixelInput input)
{
    SurfaceParameters parameters = InitSurfaceParameters();
    parameters.debug_normal = normalize(input.world_normal);
    SetupSurfaceParamFromInput(input, parameters);
    ComputeInstanceDithering(parameters);
    return parameters;
}

SurfaceParameters CreateCommonSurface(PixelInput input, uint shading_model_type, bool is_vegetation)
{
    SurfaceParameters parameters = CreateCommonSurface(input);
    parameters.shading_model = ShadingModelFromCB(shading_model_type, false);
    return parameters;
}

SurfaceParameters CreateCommonSurface(PixelInput input, uint shading_model_type)
{
    SurfaceParameters parameters = CreateCommonSurface(input);
    parameters.shading_model = ShadingModelFromCB(shading_model_type);
    return parameters;
}

//////////////////////////////////////////////////

void SetupCommonAlbedoTransparency(inout SurfaceParameters parameters, PixelInput input, float4 albedo_transparency, float transparency)
{
    parameters.albedo = albedo_transparency.rgb;
    parameters.transparency = albedo_transparency.a * transparency;

    ComputeInstanceAlbedoHSVShift(parameters);
    parameters.albedo = LinearToSrgb(parameters.albedo);
}

void SetupCommonAlbedoTransparency(inout SurfaceParameters parameters, PixelInput input, float4 albedo_transparency)
{
    SetupCommonAlbedoTransparency(parameters, input, albedo_transparency, 1.0);
}

void SetupCommonAlbedoTransparencyVC(inout SurfaceParameters parameters, PixelInput input, float4 albedo_transparency, float transparency)
{
    SetupCommonAlbedoTransparency(parameters, input, albedo_transparency, transparency);

    if(!VertexColorIsVATDirection())
    {
        parameters.albedo *= input.color.rgb;
    }
}

void SetupCommonAlbedoTransparencyVC(inout SurfaceParameters parameters, PixelInput input, float4 albedo_transparency)
{
    SetupCommonAlbedoTransparencyVC(parameters, input, albedo_transparency, 1.0);
}

void SetupCommonAlbedoTransparencyVCA(inout SurfaceParameters parameters, PixelInput input, float4 albedo_transparency, float transparency)
{
    SetupCommonAlbedoTransparencyVC(parameters, input, albedo_transparency, transparency * input.color.a);
}

void SetupCommonAlbedoTransparencyVCA(inout SurfaceParameters parameters, PixelInput input, float4 albedo_transparency)
{
    SetupCommonAlbedoTransparencyVCA(parameters, input, albedo_transparency, 1.0);
}

void SetupCommonAlbedoTransparencyVA(inout SurfaceParameters parameters, PixelInput input, float4 albedo_transparency, float transparency)
{
    SetupCommonAlbedoTransparency(parameters, input, albedo_transparency, transparency * input.color.a);
}

void SetupCommonAlbedoTransparencyVA(inout SurfaceParameters parameters, PixelInput input, float4 albedo_transparency)
{
    SetupCommonAlbedoTransparencyVA(parameters, input, albedo_transparency, 1.0);
}

//////////////////////////////////////////////////

void SetupCommonNormal(inout SurfaceParameters parameters, PixelInput input)
{
    NormalDirections world_dirs = ComputeWorldNormalDirs(input);
    parameters.normal = world_dirs.normal;
}

void SetupCommonNormalMap(inout SurfaceParameters parameters, PixelInput input, float2 normal_map)
{
    NormalDirections world_dirs = ComputeWorldNormalDirs(input);
    parameters.normal = UnpackNormalMapSafe(normal_map, world_dirs);
}

//////////////////////////////////////////////////

float SmoothnessToRoughness(float smoothness)
{
    return max(0.01, 1.0 - smoothness);
}

void SetupCommonPRM(inout SurfaceParameters parameters, float4 prm)
{
	parameters.specular = prm.x;
	parameters.roughness = SmoothnessToRoughness(prm.y);
	parameters.metallic = prm.z;
	parameters.cavity = prm.w;

	parameters.fresnel_reflectance = lerp(
		parameters.specular,
		parameters.albedo,
		parameters.metallic
	);
}

void SetupCommonPRMTexture(inout SurfaceParameters parameters, float4 prm)
{
    prm.x *= 0.25;
    SetupCommonPRM(parameters, prm);
}

void SetupCommonPBRFactor(inout SurfaceParameters parameters, float4 pbr_factor)
{
    SetupCommonPRM(parameters, float4(pbr_factor.xyz, 1.0));
}

//////////////////////////////////////////////////

void SetupCommonSurface(inout SurfaceParameters parameters)
{
    parameters.emission += ComputeLuminanceNoise(parameters.world_position.xyz);

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