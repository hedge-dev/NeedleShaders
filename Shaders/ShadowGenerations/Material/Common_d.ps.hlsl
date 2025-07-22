#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    float4 PBRFactor;
}

Texture2D<float4> WithSampler(diffuse);

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

    parameters.normal = world_normal;
    parameters.debug_normal = world_normal;

    //////////////////////////////////////////////////
    // PBR Parameters

    ApplyPBRFactor(parameters, PBRFactor);

    //////////////////////////////////////////////////

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}