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
	UVInput(specular)
	UVInput(specular1)
	UVInput(normal)
	UVInput(normal1)
	UVInput(normal2)
	float4 DetailFactor;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(diffuse1);
Texture2D<float4> WithSampler(specular);
Texture2D<float4> WithSampler(specular1);
Texture2D<float4> WithSampler(normal);
Texture2D<float4> WithSampler(normal1);
Texture2D<float4> WithSampler(normal2);

// Note:
// Normal1 is never used, that is no mistake,
// that is how this shader works.

// Note 2:
// The shader has multi tangent space mode, but
// it's never used, so we can only speculate its purpose.
// Probably has to do with the absent normal1 texture

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
	float4 normal2_texture = SampleUV3M(normal2, * DetailFactor.x);

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


	float detail_distance = ComputeDetailDistance(parameters.world_position.xyz);

	NormalDirections world_dirs = ComputeWorldNormalDirs(input);
	parameters.normal = BlendNormalMapDetail(
		normal_texture.xy,
		normal2_texture.xy,
		detail_distance,
		world_dirs
	);


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