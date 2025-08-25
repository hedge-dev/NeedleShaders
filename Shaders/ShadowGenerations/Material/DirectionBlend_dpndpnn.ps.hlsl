/////////////////////////////////////////////////
// Excluded Default features
#define no_u_model_user_flag_0

// Force enabled default features
#define enable_deferred_rendering
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
	UVInput(diffuse1)
	UVInput(specular)
	UVInput(normal)
	UVInput(normal1)
	UVInput(normal2)
	float4 DirectionParam;
	float4 NormalBlendParam;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(diffuse1);
Texture2D<float4> WithSampler(specular);
Texture2D<float4> WithSampler(normal);
Texture2D<float4> WithSampler(normal1);
Texture2D<float4> WithSampler(normal2);

PixelOutput main(const PixelInput input)
{
    //////////////////////////////////////////////////
    // Surface setup

    SurfaceParameters parameters = CreateCommonSurface(
        input, ShadingModelType_Default);

	//////////////////////////////////////////////////
    // Surface parameters

	float4 diffuse_texture = SampleUVD(diffuse);
	float4 diffuse1_texture = SampleUVD(diffuse1);
	float4 specular_texture = SampleUVD(specular);
	float4 normal_texture = SampleUVD(normal);
	float4 normal1_texture = SampleUVD(normal1);
	float4 normal2_texture = SampleUVD(normal2);

	//////////////////////////////////////////////////
	// Computing the blend factor

	NormalDirections world_dirs = ComputeWorldNormalDirs(input);

	float3 normal = TransformNormal(
		BlendNormals(
			DenormalizeNormalMap(normal_texture.xy),
			DenormalizeNormalMap(normal2_texture.xy)
		),
		world_dirs
	);

	float dir_blend = ComputeDirectionBlendFactor(
		normal,
		DirectionParam.xyz,
		input.color.r,
		diffuse_texture.a * diffuse1_texture.a,
		NormalBlendParam.x,
		NormalBlendParam.y
	);

	//////////////////////////////////////////////////

	float3 albedo = lerp(
		diffuse_texture.rgb,
		diffuse1_texture.rgb,
		dir_blend
	);

	SetupCommonAlbedoTransparency(parameters, input, float4(albedo, dir_blend));


	float3 normal_1 = TransformNormal(
		BlendNormals(
			DenormalizeNormalMap(normal1_texture.xy),
			DenormalizeNormalMap(normal2_texture.xy)
		),
		world_dirs
	);

	parameters.normal = normalize(lerp(
		normal,
		normal_1,
		dir_blend
	));


	SetupCommonPRMTexture(parameters, specular_texture);

	//////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}