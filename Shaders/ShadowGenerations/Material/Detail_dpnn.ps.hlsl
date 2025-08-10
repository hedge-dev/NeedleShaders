/////////////////////////////////////////////////
// Excluded Default features
#define no_u_model_user_flag_0

// Force enabled default features
#define enable_deferred_rendering
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"
#include "../Include/Pixel/Detail.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
	UVInput(specular)
	UVInput(normal)
	UVInput(normal1)
	float4 DetailFactor;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(specular);
Texture2D<float4> WithSampler(normal);
Texture2D<float4> WithSampler(normal1);

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
	float4 normal1_texture = SampleUV2M(normal1, * DetailFactor.x);

	SetupCommonAlbedoTransparencyVCA(parameters, input, diffuse_texture);
	TransparencyDitherDiscardW(parameters);

	float detail_distance = ComputeDetailDistance(parameters.world_position.xyz);

	NormalDirections world_dirs = ComputeWorldNormalDirs(input);
	parameters.normal = BlendNormalMapDetail(
		normal_texture.xy,
		normal1_texture.xy,
		detail_distance,
		world_dirs
	);
	parameters.debug_normal = world_dirs.normal;


    SetupCommonPRMTexture(parameters, specular_texture);

	//////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}