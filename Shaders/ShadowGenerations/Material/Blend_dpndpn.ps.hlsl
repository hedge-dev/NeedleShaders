/////////////////////////////////////////////////
// Excluded Default features
#define no_enable_alpha_threshold
#define no_is_compute_instancing
#define no_u_model_user_flag_0

// Force enabled default features
#define enable_deferred_rendering

// Optional default features
#define add_enable_multi_tangent_space
/////////////////////////////////////////////////

#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
	UVInput(diffuse1)
	UVInput(specular)
	UVInput(specular1)
	UVInput(normal)
	UVInput(normal1)
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
	float4 diffuse1_texture = SampleUV2(diffuse1);
	float4 specular_texture = SampleUV0(specular);
	float4 specular1_texture = SampleUV2(specular1);
	float4 normal_texture = SampleUV0(normal);
	float4 normal1_texture = SampleUV2(normal1);

	float blend = input.color.a;


	parameters.albedo = lerp(
		LinearToSrgb(diffuse_texture.xyz),
		LinearToSrgb(diffuse1_texture.xyz),
		blend * diffuse1_texture.a
	);

	if(!VertexColorIsVATDirection())
    {
        parameters.albedo *= input.color.rgb;
    }


	NormalDirections world_dirs = ComputeWorldNormalDirs(input);
	NormalDirections world_dirs2 = ComputeWorldNormalDirs2(input);

	float3 normal_map = UnpackNormalMapSafe(normal_texture.xy, world_dirs);
	float3 normal1_map = UnpackNormalMap(normal1_texture.xy, world_dirs2);

	parameters.normal = normalize(lerp(
		normal_map,
		normal1_map,
		blend
	));


	float4 prm = lerp(
		specular_texture,
		specular1_texture,
		blend
	);

	SetupCommonPRMTexture(parameters, prm);

	//////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}