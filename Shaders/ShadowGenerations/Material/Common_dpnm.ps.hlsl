#include "../Include/Pixel/Material.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
	UVInput(diffuse1)
    UVInput(normal)
    UVInput(specular)
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(diffuse1);
Texture2D<float4> WithSampler(normal);
Texture2D<float4> WithSampler(specular);

PixelOutput main(const PixelInput input)
{
    SurfaceParameters parameters = InitSurfaceParameters();
    SetupSurfaceParamFromInput(input, parameters);
    parameters.shading_model = ShadingModelFromCB(ShadingModelType_Default, false);

    ComputeInstanceDithering(parameters);

    //////////////////////////////////////////////////
    // Albedo Color

    float4 diffuse_texture = SampleUV0(diffuse);
    parameters.albedo = diffuse_texture.rgb;
    parameters.transparency = diffuse_texture.a * input.color.a;

    ComputeInstanceAlbedoHSVShift(parameters);
    parameters.albedo = LinearToSrgb(parameters.albedo);

    if(!VertexColorIsVATDirection())
    {
        parameters.albedo *= input.color.rgb;
    }

    TransparencyDitherDiscardW(parameters);

    //////////////////////////////////////////////////
    // Normals

    float3 world_normal = normalize(input.world_normal.xyz);
    float3 world_tangent = normalize(input.world_tangent.xyz);
    float3 world_binormal = normalize(cross(world_normal, world_tangent) * input.binormal_orientation.x);

    float4 normal_texture = SampleUV0(normal);
    parameters.normal = UnpackNormalMapToWorldSpaceSafe(normal_texture.xy, world_normal, world_tangent, world_binormal);
    parameters.debug_normal = world_normal;

    //////////////////////////////////////////////////
    // PBR Parameters

    float4 prm = SampleUV0(specular);
    ApplyPRMTexture(parameters, prm);

	//////////////////////////////////////////////////
	// Mask

	float mask = SampleUV0(diffuse1).x;
	parameters.albedo = lerp(parameters.albedo, parameters.albedo * diffuse_color.xyz, mask);

    //////////////////////////////////////////////////

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}