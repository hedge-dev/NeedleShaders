/////////////////////////////////////////////////
// Excluded Default features
#define u_model_user_flag_0
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    float4 PBRFactor;
}

Texture2D<float4> WithSampler(diffuse);

PixelOutput main(const PixelInput input)
{
    //////////////////////////////////////////////////
    // Surface setup

    SurfaceParameters parameters = CreateCommonSurface(
        input, ShadingModelType_Default, false);

    //////////////////////////////////////////////////
    // Surface parameters

    float4 diffuse_texture = SampleUV0(diffuse);

    SetupCommonAlbedoTransparencyVCA(parameters, input, diffuse_texture);
    TransparencyDitherDiscardW(parameters);
    SetupCommonNormal(parameters, input);
    SetupCommonPBRFactor(parameters, PBRFactor);

    //////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}