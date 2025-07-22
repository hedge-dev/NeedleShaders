#include "../Include/Pixel/Material.hlsl"
#include "../Include/Pixel/UserModel.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    UVInput(normal)
    UVInput(specular)
    UVInput(transparency)
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(normal);
Texture2D<float4> WithSampler(specular);
Texture2D<float4> WithSampler(transparency);

PixelOutput main(const PixelInput input)
{
    SurfaceParameters parameters = InitSurfaceParameters();
    SetupSurfaceParamFromInput(input, parameters);
    parameters.shading_model = ShadingModelFromCB(ShadingModelType_Default, false);

    ComputeInstanceDithering(parameters);

    //////////////////////////////////////////////////
    // Albedo Color

    float4 diffuse_texture = SampleUV0(diffuse);
    parameters.albedo = diffuse_texture.rgb;
    parameters.transparency = diffuse_texture.a * input.color.a;

    float transparency_texture = SampleUV3(transparency);
    parameters.transparency *= transparency_texture.x;

    ComputeInstanceAlbedoHSVShift(parameters);
    parameters.albedo = LinearToSrgb(parameters.albedo);

    if(!IsVATEnabled())
    {
        parameters.albedo *= input.color.rgb;
    }

    AlphaThresholdDiscard(parameters);

    //////////////////////////////////////////////////
    // Normals

    float3 world_normal = normalize(input.world_normal.xyz);
    float3 world_tangent = normalize(input.world_tangent.xyz);
    float3 world_binormal = normalize(cross(world_normal, world_tangent) * input.binormal_orientation.x);

    float4 normal_texture = SampleUV2(normal);
    parameters.normal = UnpackNormalMapToWorldSpaceSafe(normal_texture.xy, world_normal, world_tangent, world_binormal);
    parameters.debug_normal = world_normal;

    //////////////////////////////////////////////////
    // PBR Parameters

    float4 prm = SampleUV0(specular);
    ApplyPRMTexture(parameters, prm);

    //////////////////////////////////////////////////

    #ifdef u_model_user_flag_0
        parameters.emission = UserModel1Stuff(parameters.world_position.xyz);
    #endif

    //////////////////////////////////////////////////

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}