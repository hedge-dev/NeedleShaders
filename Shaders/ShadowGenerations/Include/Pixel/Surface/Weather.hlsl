#ifndef WEATHER_SURFACE_INCLUDED
#define WEATHER_SURFACE_INCLUDED

#include "../../ConstantBuffer/World.hlsl"
#include "../../ConstantBuffer/MaterialDynamic.hlsl"

#include "Struct.hlsl"

void ApplyWeatherEffects(inout SurfaceParameters parameters)
{
	float weather_param = u_weather_param.x;

    if(parameters.shading_model.kind == ShadingModelKind_Character)
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
	WeatherLerp(parameters.cavity, 1.0, 0.45, 2);

	#undef WeatherLerp
}


#endif