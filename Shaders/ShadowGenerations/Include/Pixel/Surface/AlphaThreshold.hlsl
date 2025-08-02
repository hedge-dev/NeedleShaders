#ifndef ALPHA_THRESHOLD_SURFACE_INCLUDED
#define ALPHA_THRESHOLD_SURFACE_INCLUDED

#include "../../Common.hlsl"

#if !defined(enable_alpha_threshold) && !defined(no_enable_alpha_threshold)
	DefineFeature(enable_alpha_threshold);
#endif

#include "Struct.hlsl"


#if defined(enable_alpha_threshold) && defined(enable_deferred_rendering)

    #include "../../ConstantBuffer/Instancing.hlsl"
    #include "../Dithering.hlsl"

    void AlphaThresholdDiscard(SurfaceParameters parameters, bool blue_noise)
    {
        float transparency = parameters.transparency * GetInstanceData(parameters.instance_index).transparency;

        if(transparency < g_alphathreshold.x)
        {
            transparency = 0.0;
        }

        // apply viewport transparency
        transparency *= dot(u_current_viewport_mask, u_forcetrans_param);

        float dither;
        if(blue_noise)
        {
            dither = ComputeBlueNoise(parameters.pixel_position);
        }
        else
        {
            dither = SampleDither(parameters.pixel_position);
        }

        transparency -= dither * 0.98 + 0.01;

        if(transparency < 0.0)
        {
            discard;
        }
    }

#else
    void AlphaThresholdDiscard(SurfaceParameters parameters, bool blue_noise) { };
#endif




#endif