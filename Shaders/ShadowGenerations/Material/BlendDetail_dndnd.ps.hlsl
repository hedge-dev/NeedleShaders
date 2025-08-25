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
#include "../Include/Pixel/Detail.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
	UVInput(diffuse1)
	UVInput(diffuse2)
	UVInput(normal)
	UVInput(normal1)
	float4 DetailFactor;
	float4 PBRFactor;
	float4 PBRFactor2;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(diffuse1);
Texture2D<float4> WithSampler(diffuse2);
Texture2D<float4> WithSampler(normal);
Texture2D<float4> WithSampler(normal1);

// Note:
// This shader is broken due to how normals get handled

// Note 2:
// The shader has multi tangent space mode, but
// it's never used, so we can only speculate its purpose.

PixelOutput main(const PixelInput input)
{
    //////////////////////////////////////////////////
    // Surface setup

    SurfaceParameters parameters = CreateCommonSurface(
        input, ShadingModelType_Default);

	//////////////////////////////////////////////////
    // Surface parameters

	float4 diffuse_texture = SampleUVD(diffuse);
	float4 diffuse2_texture = SampleUVD(diffuse2);

	float blend = input.color.a;

	parameters.albedo = lerp(
		LinearToSrgb(diffuse_texture.xyz),
		LinearToSrgb(diffuse2_texture.xyz),
		blend
	);


	float detail_distance = ComputeDetailDistance(parameters.world_position.xyz);
	if(detail_distance < 1.0)
	{
		float4 diffuse1_texture = SampleUV2M(diffuse1, * DetailFactor.x);
		float4 normal_texture = SampleUV0(normal);
		float4 normal1_texture = SampleUV2M(normal1, * DetailFactor.x);

		parameters.albedo = BlendDetail(
			parameters.albedo,
			LinearToSrgb(diffuse1_texture.xyz),
			detail_distance
		);

		NormalDirections world_dirs = ComputeWorldNormalDirs(input);

		parameters.normal = BlendNormalMapDetail(
			normal_texture.xy,
			normal1_texture.xy,
			detail_distance,
			world_dirs
		);
	}

	// Yes, this is how the shader works. Detail >= 1.0? No normals!
	// Explains why they never used it on anything...

	float4 pbr_factor = lerp(
		PBRFactor,
		PBRFactor2,
		blend
	);

	SetupCommonPBRFactor(parameters, pbr_factor);

	//////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}