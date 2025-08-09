/////////////////////////////////////////////////
// Excluded Default features
#define no_u_model_user_flag_0
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
	UVInput(diffuse1)
    UVInput(specular)
    UVInput(normal)
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(diffuse1);
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
    float4 diffuse1_texture = SampleUV0(diffuse1);
    float4 specular_texture = SampleUV0(specular);
    float4 normal_texture = SampleUV0(normal);

    SetupCommonAlbedoTransparencyVCA(parameters, input, diffuse_texture);
    TransparencyDitherDiscardW(parameters);
    SetupCommonNormalMap(parameters, input, normal_texture.xy);
    SetupCommonPRMTexture(parameters, specular_texture);

	parameters.albedo = lerp(
        parameters.albedo,
        parameters.albedo * diffuse_color.xyz,
        diffuse1_texture.x
    );

    //////////////////////////////////////////////////

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}