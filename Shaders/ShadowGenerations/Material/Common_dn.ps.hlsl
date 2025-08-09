/////////////////////////////////////////////////
// Excluded Default features
#define no_u_model_user_flag_0
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    UVInput(normal)
    float4 PBRFactor;
}

Texture2D<float4> WithSampler(diffuse);
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
    float4 normal_texture = SampleUV2(normal);

    SetupCommonAlbedoTransparencyVCA(parameters, input, diffuse_texture);
    TransparencyDitherDiscardW(parameters);
    SetupCommonNormalMap(parameters, input, normal_texture.xy);
    SetupCommonPBRFactor(parameters, PBRFactor);

    //////////////////////////////////////////////////

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}