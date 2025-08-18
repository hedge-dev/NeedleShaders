/////////////////////////////////////////////////
// Excluded Default features
#define no_is_compute_instancing
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    UVInput(specular)
    UVInput(normal)
    UVInput(emission)
    UVInput(transparency)
    float4 Luminance;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(specular);
Texture2D<float4> WithSampler(normal);
Texture2D<float4> WithSampler(emission);
Texture2D<float4> WithSampler(transparency);

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
    float4 normal_texture = SampleUV0(normal);
    float4 emission_texture = SampleUV2(emission);
    float4 transparency_texture = SampleUV3(transparency);

    SetupCommonAlbedoTransparencyVC(parameters, input, diffuse_texture);
    TransparencyDitherDiscardW(parameters);
    SetupCommonNormalMap(parameters, input, normal_texture.xy);
    SetupCommonPRMTexture(parameters, specular_texture);

    parameters.emission =
        emission_texture.xyz
        * ambient_color.xyz
        * Luminance.x
        * transparency_texture.x
        * input.color.a;

    //////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}