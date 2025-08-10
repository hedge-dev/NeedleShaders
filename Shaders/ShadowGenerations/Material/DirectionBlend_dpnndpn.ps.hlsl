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
	UVInput(normal2)
	float4 DetailFactor;
	float4 DirectionParam;
	float4 NormalBlendParam;
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(diffuse1);
Texture2D<float4> WithSampler(specular);
Texture2D<float4> WithSampler(specular1);
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
	float4 specular1_texture = SampleUVD(specular1);
	float4 normal_texture = SampleUVD(normal);
	float4 normal1_texture = SampleUVDM(normal1, * DetailFactor.x);
	float4 normal2_texture = SampleUVD(normal2);

	//////////////////////////////////////////////////
	// Computing the blend factors

	float detail_distance = ComputeDetailDistance(parameters.world_position.xyz);

	NormalDirections world_dirs = ComputeWorldNormalDirs(input);

	float3 normal = BlendNormalMapDetail(
		normal_texture.xy,
		normal1_texture.xy,
		detail_distance,
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

	// Why did they do this??? IBLs will look wrong with this?????
	if(GetDebugView() == DebugView_IblCapture)
	{
		dir_blend = 0.0;
	}

	//////////////////////////////////////////////////

	float3 albedo = lerp(
		diffuse_texture.rgb,
		diffuse1_texture.rgb,
		dir_blend
	);

	SetupCommonAlbedoTransparency(parameters, input, float4(albedo, dir_blend));

	if(!VertexColorIsVATDirection())
	{
		parameters.albedo = lerp(
			parameters.albedo * input.color.rgb,
			parameters.albedo,
			ambient_color.x
		);
	}

	// This is incorrectly implemented.
	// I assume they attempted to do a multi tangent implementation,
	// but the tangent and binormal ended up as 0, so only the normal
	// direction got applied to the denormal

	NormalDirections broken_dir = { world_dirs.normal, { 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0} };
	float3 normal_2 = UnpackNormalMap(normal2_texture.xy, broken_dir);

	parameters.normal = normalize(lerp(normal, normal_2, dir_blend));
	parameters.debug_normal = world_dirs.normal;


	float4 prm = lerp(
		specular_texture,
		specular1_texture,
		dir_blend
	);

	SetupCommonPRMTexture(parameters, prm);

	//////////////////////////////////////////////////
    // Output

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}