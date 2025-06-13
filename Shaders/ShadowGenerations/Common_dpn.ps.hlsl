static const uint FEATURE_is_compute_instancing;
static const uint FEATURE_is_use_tex_srt_anim;
static const uint FEATURE_enable_deferred_rendering;
static const uint FEATURE_enable_alpha_threshold;

#include "Include/ConstantBuffer/World.hlsl"
#include "Include/ConstantBuffer/MaterialDynamic.hlsl"
#include "Include/ConstantBuffer/MaterialImmutable.hlsl"

#include "Include/Common.hlsl"
#include "Include/ColorConversion.hlsl"
#include "Include/IOStructs.hlsl"

#include "Include/Pixel/Common.hlsl"
#include "Include/Pixel/Instancing.hlsl"
#include "Include/Pixel/Dithering.hlsl"
#include "Include/Pixel/Normals.hlsl"
#include "Include/Pixel/PBRUtils.hlsl"

#include "Include/Pixel/Surface/Common.hlsl"

// must be inside some include that comes inside or after surface/common
static const uint FEATURE_u_model_user_flag_0;

MaterialImmutables
{
    UVInput(diffuse)
    UVInput(normal)
    UVInput(specular)
}

TextureInput(diffuse)
TextureInput(normal)
TextureInput(specular)

PixelOutput main(const PixelInput input)
{
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
    float3 albedo = diffuse_texture.rgb;

    #if defined(is_compute_instancing) && defined(enable_deferred_rendering)

        //////////////////////////////////////////////////
        // Compute Instance HSV modification

        albedo = HSVtoRGB(RGBtoHSV(albedo) + input.compute_instance_parameters.xyz);

    #endif

    albedo = LinearToSrgb(albedo);

    // Color will be applied if it's not used for a vertex animation (?)
    if(u_vat_type.x <= 0)
    {
        albedo *= input.color.rgb;
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

    float3 normal = normalize(input.world_normal.xyz);
    float3 tangent = normalize(input.world_tangent.xyz);
    float3 binormal = normalize(cross(normal, tangent) * input.binormal_orientation.x);

    float4 normal_texture = SampleUV2(normal);
    float3 normal_map = UnpackNormalMapToWorldSpaceSafe(normal_texture.xy, normal, tangent, binormal);

    //////////////////////////////////////////////////
    // PBR Parameters

    float4 prm = SampleUV0(specular);
    PBRParameters pbr_parameters = ProcessPRMTexture(prm, albedo);

    //////////////////////////////////////////////////

    SurfaceData surface = CreateCommonSurface(
        input.position.xyz,
        input.previous_position.xyz,
        WorldPosition4(input),
        albedo.xyz,
        normal_map,
        normal,
        0.0,
        pbr_parameters,
        input.uv01.zw
    );

	return ProcessSurface(surface);
}