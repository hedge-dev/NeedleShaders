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
	UVInput(diffuse1)
	UVInput(specular)
	UVInput(specular1)
	UVInput(normal)
	UVInput(normal1)
	float4 DetailFactor;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(diffuse1);
Texture2D<float4> WithSampler(specular);
Texture2D<float4> WithSampler(specular1);
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
	float4 diffuse1_texture = SampleUV2M(diffuse1, * DetailFactor.x);
	float4 specular_texture = SampleUV0(specular);
	float4 specular1_texture = SampleUV2M(specular1, * DetailFactor.x);
	float4 normal_texture = SampleUV0(normal);
	float4 normal1_texture = SampleUV2M(normal1, * DetailFactor.x);

	float detail_distance = ComputeDetailDistance(parameters.world_position.xyz);


	float3 detail = BlendDetail(diffuse_texture.xyz, diffuse1_texture.xyz);
	float3 albedo = lerp(
		detail,
		diffuse_texture.xyz,
		detail_distance
	);

	SetupCommonAlbedoTransparencyVCA(parameters, input, float4(albedo, diffuse_texture.a));
	TransparencyDitherDiscardW(parameters);


	NormalDirections world_dirs = ComputeWorldNormalDirs(input);
	parameters.normal = BlendNormalMapDetail(
		normal_texture.xy,
		normal1_texture.xy,
		detail_distance,
		world_dirs
	);


    SetupCommonPRMTexture(parameters, specular_texture);

	// detail specular is unused

	parameters.roughness = BlendDetail(
		parameters.roughness,
		SmoothnessToRoughness(specular1_texture.y),
		detail_distance
	);

	parameters.metallic = lerp(
		saturate(specular1_texture.z * 2.0 - 1.0 + parameters.metallic),
		parameters.metallic,
		detail_distance
	);

	parameters.cavity = lerp(
		parameters.cavity * specular1_texture.w,
		parameters.cavity,
		detail_distance
	);

	// why did they did this???
	parameters.cavity *= input.color.a;

	//////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}