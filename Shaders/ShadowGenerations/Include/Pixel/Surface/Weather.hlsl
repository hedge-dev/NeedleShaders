#ifndef WEATHER_SURFACE_INCLUDED
#define WEATHER_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/MaterialDynamic.hlsl"

#include "../../Math.hlsl"

#include "Struct.hlsl"

#define WeatherMode_1 1

uint GetWeatherMode()
{
	return UnpackUIntBits((uint)u_shading_model_flag.x, 2, 4);
}

void ApplyWeatherEffects(inout SurfaceParameters parameters)
{
	float weather_param = u_weather_param.x;

    if(GetWeatherMode() == WeatherMode_1)
    {
        weather_param *= u_weather_param.w;
    }

	if(weather_param <= 0.0)
    {
		return;
    }

	parameters.albedo = lerp(
		parameters.albedo,
		parameters.albedo * parameters.albedo,
		saturate(2.85714293 * weather_param)
	);

	#define WeatherLerp(dest, to, threshold, mult) \
		dest = lerp(dest, to, saturate((weather_param - threshold) * mult))

	WeatherLerp(parameters.specular, 0.02, 0.2, 1.25);
	WeatherLerp(parameters.roughness, 0.02, 0.2, 1.25);
	WeatherLerp(parameters.ambient_occlusion, 1.0, 0.45, 2);

	#undef WeatherLerp
}


#endif