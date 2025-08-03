#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    UVInput(specular)
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(specular);

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

    if(!VertexColorIsVATDirection())
    {
        parameters.albedo *= input.color.rgb;
    }

    TransparencyDitherDiscardW(parameters);

    //////////////////////////////////////////////////
    // Normals

    float3 world_normal = normalize(input.world_normal.xyz);

    parameters.normal = world_normal;
    parameters.debug_normal = world_normal;

    //////////////////////////////////////////////////
    // PBR Parameters

    float4 prm = SampleUV0(specular);
    ApplyPRMTexture(parameters, prm);

    //////////////////////////////////////////////////

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}