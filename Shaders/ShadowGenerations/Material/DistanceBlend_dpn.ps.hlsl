/////////////////////////////////////////////////
// Excluded Default features
#define no_is_compute_instancing
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
	UVInput(diffuse2)
	UVInput(specular)
	UVInput(normal)
	UVInput(normal1)
	UVInput(normal2)
	float4 DistanceBlend;
	float4 DetailFactor;
	float4 PBRFactor;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(diffuse1);
Texture2D<float4> WithSampler(diffuse2);
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

	float4 diffuse_texture = SampleUV0(diffuse);
	float4 diffuse1_texture = SampleUVDM(diffuse1, * DetailFactor.x);
	float4 diffuse2_texture = SampleUVDM(diffuse2, * DetailFactor.y);
	float4 specular_texture = SampleUV0(specular);
	float4 specular_texture_1 = SampleUV0M(specular, * DetailFactor.x);
	float4 specular_texture_2 = SampleUV0M(specular, * DetailFactor.y);
	float4 normal_texture = SampleUV2(normal);
	float4 normal1_texture = SampleUVDM(normal1, * DetailFactor.x);
	float4 normal2_texture = SampleUVDM(normal2, * DetailFactor.y);

	float distance_blend_1 = ComputeDetailDistance(parameters.world_position.xyz, DistanceBlend.x, DistanceBlend.z);
	float distance_blend_2 = ComputeDetailDistance(parameters.world_position.xyz, DistanceBlend.y, DistanceBlend.w);

	//////////////////////////////////////////////////
	// Albedo

	float4 albedo_transparency = lerp(
		lerp(
			diffuse_texture,
			diffuse1_texture,
			distance_blend_1
		),
		diffuse2_texture,
		distance_blend_2
	);

	SetupCommonAlbedoTransparencyVCA(parameters, input, albedo_transparency);
	TransparencyDitherDiscardW(parameters);

	//////////////////////////////////////////////////
	// Normals

	NormalDirections world_dirs = ComputeWorldNormalDirs(input);

	float3 denormal = DenormalizeNormalMap(normal_texture.xy);
	float3 denormal_1 = DenormalizeNormalMap(normal1_texture.xy);
	float3 denormal_2 = DenormalizeNormalMap(normal2_texture.xy);

	float3 denormal_blended = lerp(
		BlendNormals(denormal, denormal_1),
		denormal,
		distance_blend_1
	);

	denormal_blended = lerp(
		BlendNormals(denormal_blended, denormal_2),
		denormal_blended,
		distance_blend_2
	);

	parameters.normal = TransformNormal(denormal_blended, world_dirs);
	parameters.debug_normal = world_dirs.normal;

	//////////////////////////////////////////////////
	// PRM

	float2 prm_1 = float2(specular_texture.x, specular_texture.w);
	float2 prm_2 = float2(specular_texture_1.y, 1);
	float2 prm_3 = float2(specular_texture_2.z, 1);

	float2 prm = lerp(
		lerp(
			prm_1,
			prm_2,
			distance_blend_1
		),
		prm_3,
		distance_blend_2
	);

	SetupCommonPRM(parameters, float4(PBRFactor.x, prm.x, 0, prm.y));

	//////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}