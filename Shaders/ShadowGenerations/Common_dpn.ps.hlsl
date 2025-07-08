
#include "Include/Common.hlsl"
DefineFeature(is_compute_instancing);
DefineFeature(is_use_tex_srt_anim);
DefineFeature(enable_deferred_rendering);
DefineFeature(enable_alpha_threshold);

#include "Include/ConstantBuffer/World.hlsl"
#include "Include/ConstantBuffer/MaterialDynamic.hlsl"
#include "Include/ConstantBuffer/MaterialImmutable.hlsl"

#include "Include/Texture.hlsl"
#include "Include/ColorConversion.hlsl"
#include "Include/IOStructs.hlsl"

#include "Include/Pixel/Material.hlsl"
#include "Include/Pixel/Instancing.hlsl"
#include "Include/Pixel/Dithering.hlsl"
#include "Include/Pixel/Normals.hlsl"
#include "Include/Pixel/PBRUtils.hlsl"
#include "Include/Pixel/Surface/Common.hlsl"
#include "Include/Pixel/UserModel.hlsl"

MaterialImmutables
{
    UVInput(diffuse)
    UVInput(normal)
    UVInput(specular)
}

Texture2D<float4> WithSampler(diffuse);
Texture2D<float4> WithSampler(normal);
Texture2D<float4> WithSampler(specular);

PixelOutput main(const PixelInput input)
{
    //////////////////////////////////////////////////
    // Initialization

    SurfaceParameters parameters = InitSurfaceParameters();
    SetupSurfaceParamFromInput(input, parameters);
    parameters.shading_model = ShadingModelFromCB(ShadingModelType_Default);

    //////////////////////////////////////////////////

    #define SampleUV0(name) SampleTextureBiasedGl(name, TexUV(input.uv01.xy, name))
    #define SampleUV2(name) SampleTextureBiasedGl(name, TexUV(input.uv23.xy, name))

    #if defined(is_compute_instancing) && defined(enable_deferred_rendering)

        //////////////////////////////////////////////////
        // Compute Instance opacity dithering

        DiscardDithering(input.position.xy, input.compute_instance_parameters.w);

    #endif

    //////////////////////////////////////////////////
    // Albedo Color

    float4 diffuse_texture = SampleUV0(diffuse);
    parameters.albedo = diffuse_texture.rgb;
    parameters.transparency = diffuse_texture.a;

    #if defined(is_compute_instancing) && defined(enable_deferred_rendering)

        //////////////////////////////////////////////////
        // Compute Instance HSV modification

        parameters.albedo = HSVtoRGB(RGBtoHSV(parameters.albedo) + input.compute_instance_parameters.xyz);

    #endif

    parameters.albedo = LinearToSrgb(parameters.albedo);

    // Color will be applied if it's not used for a vertex animation (?)
    if(u_vat_type.x <= 0)
    {
        parameters.albedo *= input.color.rgb;
    }

    #if defined(enable_alpha_threshold) && defined(enable_deferred_rendering)

        //////////////////////////////////////////////////
        // Transparency

        float transparency =
            diffuse_texture.a
            * input.color.a
            * GetInstanceOpacity(input.binormal_orientation.y);

        if(transparency < g_alphathreshold.x)
        {
            discard;
        }

        ViewportTransparencyDiscardDithering(input.position.xy);

    #endif

    //////////////////////////////////////////////////
    // Normals

    float3 world_normal = normalize(input.world_normal.xyz);
    float3 world_tangent = normalize(input.world_tangent.xyz);
    float3 world_binormal = normalize(cross(world_normal, world_tangent) * input.binormal_orientation.x);

    float4 normal_texture = SampleUV2(normal);
    parameters.normal = UnpackNormalMapToWorldSpaceSafe(normal_texture.xy, world_normal, world_tangent, world_binormal);
    parameters.debug_normal = world_normal;

    //////////////////////////////////////////////////
    // PBR Parameters

    float4 prm = SampleUV0(specular);
    ProcessPRMTexture(parameters, prm);

    //////////////////////////////////////////////////

    #ifdef u_model_user_flag_0
        parameters.emission = UserModel1Stuff(parameters.world_position.xyz);
    #endif

    //////////////////////////////////////////////////

    SetupCommonSurface(parameters);
	return ProcessSurface(input, parameters);
}