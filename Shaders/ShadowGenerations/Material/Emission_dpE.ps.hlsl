/////////////////////////////////////////////////
// Excluded Default features
#define no_is_compute_instancing
#define no_u_model_user_flag_0
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    UVInput(specular)
    UVInput(emission)
    float4 Luminance;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(specular);
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
    float4 specular_texture = SampleUV0(specular);
    float4 emission_texture = SampleUV2(emission);

    SetupCommonAlbedoTransparencyVC(parameters, input, diffuse_texture);
    TransparencyDitherDiscardW(parameters);
    SetupCommonNormal(parameters, input);
    SetupCommonPRMTexture(parameters, specular_texture);

    parameters.emission =
        emission_texture.xyz
        * ambient_color.xyz
        * Luminance.x;

    //////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}