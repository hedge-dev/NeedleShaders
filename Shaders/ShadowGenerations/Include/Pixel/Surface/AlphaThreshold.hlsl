#ifndef ALPHA_THRESHOLD_SURFACE_INCLUDED
#define ALPHA_THRESHOLD_SURFACE_INCLUDED

#include "../../Common.hlsl"

#if !defined(enable_alpha_threshold) && !defined(no_enable_alpha_threshold)
	DefineFeature(enable_alpha_threshold);
#endif

#include "../../ConstantBuffer/Instancing.hlsl"
#include "../Dithering.hlsl"
#include "Struct.hlsl"

#if defined(enable_alpha_threshold) && defined(enable_deferred_rendering)
    #define IsAlphaThresholdEnabled true
#else
    #define IsAlphaThresholdEnabled false
#endif


float GetInstanceOpacity(int instance_index)
{
    if(instance_index <= 0)
    {
		return 1.0f;
    }

	int packed_instance_index = instance_index * 5 + 4;
	return instancing_data_packed[packed_instance_index].w;
}

void AlphaThresholdDiscard(SurfaceParameters parameters)
{
    if(!IsAlphaThresholdEnabled)
    {
        return;
    }

    float transparency = parameters.transparency * GetInstanceOpacity(parameters.instance_index);

    if(transparency < g_alphathreshold.x)
    {
        discard;
    }

    ViewportTransparencyDiscardDithering(parameters.pixel_position);
}

#endif