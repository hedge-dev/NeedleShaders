#ifndef USERMODEL_PIXEL_INCLUDED
#define USERMODEL_PIXEL_INCLUDED

#include "../Common.hlsl"
DefineFeature(u_model_user_flag_0);

#include "../ConstantBuffer/World.hlsl"
#include "../ConstantBuffer/MaterialDynamic.hlsl"
#include "../Random.hlsl"

#include "Luminance.hlsl"

// TODO What even is this
float3 UserModel1Stuff(float3 world_position)
{
	if(u_model_user_param_5.w <= 0)
	{
		return 0.0;
	}

	float t1 = lerp(
		g_time_param.y,
		lerp(
			g_global_user_param_3.z,
			g_time_param.y,
			u_model_user_param_3.w
		),
		g_global_user_param_3.w * (1 - u_model_user_param_3.w)
	) * u_model_user_param_4.w;

	float random = Random1From3(world_position + float3(0.0, t1, 0.0));

	float t2 = ((random - 0.5) * 2 * u_model_user_param_4.z)
		+ u_model_user_param_4.x
		- world_position.y;

	float t3 = t2 + u_model_user_param_4.y;

	if(t3 < 0)
	{
		discard;
	}

	if(t2 >= u_model_user_param_4.y)
	{
		return 0.0;
	}

	return (t2 / -u_model_user_param_4.y + 1.0)
		* u_model_user_param_5.xyz
		* SampleTexture(s_Luminance, float2(0.75, 0.5)).x;
}

#endif