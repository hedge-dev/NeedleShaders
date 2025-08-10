/////////////////////////////////////////////////
// Excluded Default features
#define no_is_compute_instancing
#define no_u_model_user_flag_0
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    float4 Luminance;
    float4 PBRFactor;
}

Texture2D<float4> WithSampler(diffuse);

PixelOutput main(const PixelInput input)
{
    //////////////////////////////////////////////////
    // Surface setup

    SurfaceParameters parameters = CreateCommonSurface(
        input, ShadingModelType_Default);

    //////////////////////////////////////////////////
    // Surface parameters

    float4 diffuse_texture = SampleUV0(diffuse);

    SetupCommonAlbedoTransparencyVC(parameters, input, diffuse_texture);
    TransparencyDitherDiscardW(parameters);
    SetupCommonNormal(parameters, input);
    SetupCommonPBRFactor(parameters, PBRFactor);

    parameters.emission =
        emissive_color.xyz
        * ambient_color.xyz
        * Luminance.x;

    //////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}