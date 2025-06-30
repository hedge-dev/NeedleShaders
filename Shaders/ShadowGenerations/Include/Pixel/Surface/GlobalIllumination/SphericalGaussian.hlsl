#ifndef SG_GI_SURFACE_INCLUDED
#define SG_GI_SURFACE_INCLUDED

#include "../../../ConstantBuffer/World.hlsl"
#include "../../../Texture.hlsl"
#include "../../../Math.hlsl"

#include "../../ShaderModel.hlsl"
#include "../../EnvironmentBRDF.hlsl"

#include "Common.hlsl"

static const float3 SGGIAxis[4] =
{
	float3( 0.224566802, 1.12283194,  3.83260012),
	float3( 0.224566802, 1.12283194, -3.83260012),
	float3( 3.83260012,  1.12283194,  0.224566802),
	float3(-3.83260012,  1.12283194,  0.224566802)
};

float ComputeSGDiffuseFactor(float3 normal, int index)
{
	float3 direction = normal
		* float3(4.02, 4.02, -4.02)
		+ SGGIAxis[index];

	float l = length(direction);
	return ((exp(l) - exp(-l)) * 0.5) / l * 0.00421554781;
}

float3 ComputeSGGIDiffuse(float3 colors[4], SurfaceParameters parameters)
{
	if(!IsSGGIEnabled())
	{
		return 0.0;
	}

	float3 result = 0.0;

	for(int i = 0; i < 4; i++)
	{
		result += colors[i] * ComputeSGDiffuseFactor(parameters.normal, i);
	}

	return result * 0.64;
}

float ComputeSGGISpecularFactor(float3 normal, int index, float fac)
{
	float3 direction = normal
		* float3(fac, fac, -fac)
		+ SGGIAxis[index];

	float l = length(direction);
	return (12.566371 / exp(4 + fac - l)) * ((1.0 - exp((l) * -2)) * 0.5 / l);
}

float3 ComputeSGGISpecular(float3 colors[4], SurfaceParameters parameters)
{
	if(!IsSGGIEnabled())
	{
		return 0.0;
	}

	int debug_mode = GetDebugMode();
	if(!debug_mode || debug_mode == DebugMode_SpecularLighting)
	{
		return 0.0;
	}

	float3 view_dir = normalize(u_cameraPosition.xyz - parameters.world_position.xyz);
	float cos_view_normal_raw = dot(view_dir, parameters.normal);
	float cos_view_normal = saturate(cos_view_normal_raw);

	float3 t = parameters.normal * 2 * cos_view_normal - view_dir;
	float t2 = 2.0 / pow(max(0.05, pow(saturate(parameters.roughness * 2.5 - 1.5), 2)), 2);
	float t3 = min(70, (t2 / (4 * max(0.05, abs(cos_view_normal_raw)))) * 2);

	float3 result = 0.0;

	for(int i = 0; i < 4; i++)
	{
		result += colors[i] * ComputeSGGISpecularFactor(parameters.normal, i, t3);
	}

	result /= (1.0 - exp2(t3 * -2.88539004)) * (Tau / t3);

	float2 env_brdf = ComputeEnvironmentBRDF(parameters.shader_model, parameters.roughness, cos_view_normal);
	result *= parameters.fresnel_reflectance * env_brdf.x + env_brdf.y;

	return max(result, 0.0);
}

void ComputeSGGIColors(SurfaceParameters parameters, out float3 diffuse, out float3 specular)
{
	if(!IsSGGIEnabled())
	{
		return;
	}

	float3 colors[4];
	for(int i = 0; i < 4; i++)
	{
		colors[i] = SampleGITextureLevel(parameters.gi_uv, i, 0).xyz;
	}

	diffuse = ComputeSGGIDiffuse(colors, parameters);
	specular = ComputeSGGISpecular(colors, parameters);
}


#endif