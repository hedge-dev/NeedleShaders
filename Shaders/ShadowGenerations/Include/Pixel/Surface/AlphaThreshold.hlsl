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

    void AlphaThresholdDiscard(SurfaceParameters parameters, float threshold, float dither)
    {
        float transparency = parameters.transparency * GetInstanceData(parameters.instance_index).transparency;

        if(transparency < threshold)
        {
            transparency = 0.0;
        }

        // apply viewport transparency
        transparency *= dot(u_current_viewport_mask, u_forcetrans_param);
        transparency -= dither * 0.98 + 0.01;

        if(transparency < 0.0)
        {
            discard;
        }
    }

    // W = Uses the world buffers g_alphathreshold.x
    void TransparencyDitherDiscardW(SurfaceParameters parameters)
    {
        float dither = SampleDither(parameters.pixel_position);
        AlphaThresholdDiscard(parameters, g_alphathreshold.x, dither);
    }

    // Z = Uses zero for the threshold
    void NoiseDitherDiscardZ(SurfaceParameters parameters)
    {
        float noise = ComputeBlueNoise(parameters.pixel_position);
        AlphaThresholdDiscard(parameters, 0, noise);
    }

#else
    void AlphaThresholdDiscard(SurfaceParameters parameters, float threshold, float dither) { }
    void TransparencyDitherDiscardW(SurfaceParameters parameters) { }
    void NoiseDitherDiscardZ(SurfaceParameters parameters) { }
#endif




#endif