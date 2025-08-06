/////////////////////////////////////////////////
// Excluded Default features
#define no_is_compute_instancing
#define no_u_model_user_flag_0
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    UVInput(normal)
    UVInput(emission)
    float4 Luminance;
    float4 PBRFactor;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(normal);
Texture2D<float4> WithSampler(emission);

PixelOutput main(const PixelInput input)
{
    //////////////////////////////////////////////////
    // Surface setup

    SurfaceParameters parameters = CreateCommonSurface(
        input, ShadingModelType_Default, false);

    //////////////////////////////////////////////////
    // Surface parameters

    float4 diffuse_texture = SampleUV0(diffuse);
    float4 normal_texture = SampleUV2(normal);
    float4 emission_texture = SampleUV3(emission);

    SetupCommonAlbedoTransparencyICA(parameters, input, diffuse_texture);
    TransparencyDitherDiscardW(parameters);
    SetupCommonNormalMap(parameters, input, normal_texture.xy);
    SetupCommonPBRFactor(parameters, PBRFactor);

    parameters.emission =
        emission_texture.xyz
        * ambient_color.xyz
        * Luminance.x;

    //////////////////////////////////////////////////

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}