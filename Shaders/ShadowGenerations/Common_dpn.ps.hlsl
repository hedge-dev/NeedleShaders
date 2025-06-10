static const uint FEATURE_is_compute_instancing;
static const uint FEATURE_is_use_tex_srt_anim;
static const uint FEATURE_enable_deferred_rendering;
static const uint FEATURE_enable_alpha_threshold;
static const uint FEATURE_is_use_gi_prt;
static const uint FEATURE_is_use_gi_sg;
static const uint FEATURE_is_use_gi;
static const uint FEATURE_u_model_user_flag_0;

#include "Include/ConstantBuffer/World.hlsl"
#include "Include/ConstantBuffer/MaterialDynamic.hlsl"
#include "Include/ConstantBuffer/SHLightfieldProbes.hlsl"

#include "Include/Common.hlsl"
#include "Include/ColorConversion.hlsl"
#include "Include/IOStructs.hlsl"

#include "Include/Pixel/Common.hlsl"
#include "Include/Pixel/Instancing.hlsl"
#include "Include/Pixel/Dithering.hlsl"
#include "Include/Pixel/Normals.hlsl"

#include "Include/Pixel/Surface/Common.hlsl"

TextureInput(diffuse)
TextureInput(normal)
TextureInput(specular)

TextureInput(gi_texture)
TextureInput(gi_shadow_texture)

const float4 icb[] = {
    { 1.0, 0.0, 0.0, 0.0 },
    { 0.0, 1.0, 0.0, 0.0 },
    { 0.0, 0.0, 1.0, 0.0 },
    { 0.0, 0.0, 0.0, 1.0 },

    { 1.5, 0.3, 0.3, 1.0 },
    { 0.3, 1.5, 0.3, 1.0 },
    { 0.3, 0.3, 5.5, 1.0 },
    { 1.5, 0.3, 5.5, 1.0 },
};

PixelOutput main(const PixelInput input)
{
    #define Sample(name) SampleTextureBiasedGl(name, TexUV(input.UV01.xy, name))

    #if defined(is_compute_instancing) && defined(enable_deferred_rendering)

        //////////////////////////////////////////////////
        // Compute Instance opacity dithering

        DiscardDithering(input.Position.xy, input.ComputeInstanceParameters.w);

    #endif

    //////////////////////////////////////////////////
    // Albedo Color

    float4 diffuse_texture = Sample(diffuse);
    float3 albedo = diffuse_texture.rgb;

    #if defined(is_compute_instancing) && defined(enable_deferred_rendering)

        //////////////////////////////////////////////////
        // Compute Instance HSV modification

        albedo = HSVtoRGB(RGBtoHSV(albedo) + input.ComputeInstanceParameters.xyz);

    #endif

    albedo = LinearToSrgb(albedo);

    // Color will be applied if it's not used for a vertex animation (?)
    if(u_vat_type.x <= 0)
    {
        albedo *= input.Color.rgb;
    }

    #ifdef enable_alpha_threshold

        //////////////////////////////////////////////////
        // Transparency

        float transparency =
            diffuse_texture.a
            * input.Color.a
            * GetInstanceOpacity(input.BinormalOrientation.y);

        if(transparency < g_alphathreshold.x)
        {
            discard;
        }

        ViewportTransparencyDiscardDithering(input.Position.xy);

    #endif

    //////////////////////////////////////////////////
    // Normals

    float3 normal = normalize(input.WorldNormal.xyz);
    float3 tangent = normalize(input.WorldTangent.xyz);
    float3 binormal = normalize(cross(normal, tangent) * input.BinormalOrientation.x);

    float4 normal_texture = Sample(normal);
    float3 normal_map = UnpackNormalMapToWorldSpaceSafe(normal_texture.xy, normal, tangent, binormal);

    //////////////////////////////////////////////////
    // PBR Parameters

    float4 prm = Sample(specular);

    SurfaceData surface = CreateCommonSurface(
        input.Position.xyz,
        input.PrevPosition.xyz,
        albedo.xyz,
        normal_map,
        normal,
        0.0,
        prm
    );

	return ProcessSurface(surface);
}