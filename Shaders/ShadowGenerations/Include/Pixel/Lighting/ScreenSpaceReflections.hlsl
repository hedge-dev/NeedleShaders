#ifndef SSR_LIGHTING_INCLUDED
#define SSR_LIGHTING_INCLUDED

#include "Struct.hlsl"

#ifndef disable_ssr
	#include "../../Texture.hlsl"
	#include "../EnvironmentBRDF.hlsl"
	Texture2D<float4> WithSampler(s_RLR);
#endif

float2 ComputeRLRPosition(float2 screen_position, float3 position, float3 normal, float3 view_direction)
{
	#ifdef IS_COMPUTE_SHADER
		return screen_position;
	#else
		float3 ddx = ddx_coarse(position);
		float3 ddy = ddy_coarse(position);
		float3 geo_normal = normalize(cross(ddx, ddy));

		float3 ref_view_geonrm = reflect(view_direction, geo_normal);
		float3 ref_view_nrm = view_direction - normal * saturate(dot(view_direction, normal)) * 2;

		float cos_view_geonrm_raw = dot(view_direction, ref_view_geonrm);
		float cos_view_geonrm = abs(cos_view_geonrm_raw);
		float asin_view_geonrm = asin_view_geonrm = min(1.0, asin(cos_view_geonrm) * 0.9);

		float3 reflection_dir = lerp(ref_view_geonrm, ref_view_nrm, asin_view_geonrm) - ref_view_nrm;

		float2 result = mul(reflection_dir, (float3x3)view_matrix).xy;
		result.y = abs(result.y);

		result *= u_rlr_param[0].z;
		result = clamp(result, -u_rlr_param[0].w, u_rlr_param[0].w);
		result += screen_position;
		return min(u_rlr_param[0].xy, result);
	#endif
}

float4 SampleScreenSpaceReflection(float2 sample_pos, float level)
{
	#ifdef disable_ssr
		return 0.0;
	#else

		if(!enable_rlr)
		{
			return 0.0;
		}

		return SampleTextureLevel(
			s_RLR,
			sample_pos,
			level
		);
	#endif
}

float4 ComputeScreenSpaceReflectionColor(LightingParameters parameters)
{
	#ifdef disable_ssr
		return 0.0;
	#else

		if(!enable_rlr)
		{
			return 0.0;
		}

		float2 sample_pos = ComputeRLRPosition(
			parameters.screen_position,
			parameters.world_position.xyz,
			parameters.world_normal,
			parameters.view_direction
		);

		float4 rlr_color = SampleTextureLevel(
			s_RLR,
			sample_pos,
			u_rlr_param[1].w * parameters.roughness
		);

		ComputeApplyEnvironmentBRDF(
			parameters.approximate_env_brdf,
			parameters.cos_view_normal,
			parameters.roughness,
			parameters.fresnel_reflectance,
			rlr_color.xyz
		);

		return float4(
			rlr_color.xyz,
			smoothstep(1.0 - u_sggi_param[1].x, 1.0001, rlr_color.w)
		);
	#endif
}

void ComputeApplyScreenSpaceReflectionColor(LightingParameters parameters, float4 result)
{
	#ifdef disable_ssr
		return;
	#else
		if(!enable_rlr)
		{
			return;
		}

		float4 ssr = ComputeScreenSpaceReflectionColor(parameters);
		result = lerp(result, float4(ssr.xyz, 1.0), ssr.w);
		result.w *= (1.0 - ssr.w);
	#endif
}

#endif