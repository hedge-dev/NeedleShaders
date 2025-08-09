#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    UVInput(specular)
    UVInput(normal)
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(specular);
Texture2D<float4> WithSampler(normal);

PixelOutput main(const PixelInput input)
{
    //////////////////////////////////////////////////
    // Surface setup

    SurfaceParameters parameters = CreateCommonSurface(
        input, ShadingModelType_Default);

    //////////////////////////////////////////////////
    // Surface parameters

    float4 diffuse_texture = SampleUV0(diffuse);
    float4 specular_texture = SampleUV0(specular);
    float4 normal_texture = SampleUV2(normal);

    SetupCommonAlbedoTransparencyVCA(parameters, input, diffuse_texture);
    TransparencyDitherDiscardW(parameters);
    SetupCommonNormalMap(parameters, input, normal_texture.xy);
    SetupCommonPRMTexture(parameters, specular_texture);

    //////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}