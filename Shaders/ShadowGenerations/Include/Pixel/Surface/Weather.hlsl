#ifndef WEATHER_SURFACE_INCLUDED
#define WEATHER_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/MaterialDynamic.hlsl"

#include "../../Math.hlsl"

// TODO Figure out what the first and second weather modes signify
#define WEATHER_MODE_0 0
#define WEATHER_MODE_1 1

uint GetWeatherMode()
{
	return UnpackUIntBits((uint)u_shading_model_flag.x, 2, 4);
}

void ApplyWeatherEffects(
	inout float3 albedo,
	inout float specular,
	inout float roughness,
	inout float ambient_occlusion)
{
	float weather_param = u_weather_param.x;

    if(GetWeatherMode() == WEATHER_MODE_1)
    {
        weather_param *= u_weather_param.w;
    }

	if(weather_param <= 0.0)
    {
		return;
    }


	albedo = lerp(albedo, albedo * albedo, saturate(2.85714293 * weather_param));

	#define WeatherLerp(dest, to, threshold, mult) \
		dest = lerp(dest, to, saturate((weather_param - threshold) * mult))

	WeatherLerp(specular, 0.02, 0.2, 1.25);
	WeatherLerp(roughness, 0.02, 0.2, 1.25);
	WeatherLerp(ambient_occlusion, 1.0, 0.45, 2);

	#undef WeatherLerp
}


#endif