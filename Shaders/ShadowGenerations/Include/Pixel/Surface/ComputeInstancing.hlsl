#ifndef COMPUTE_INSTANCING_PIXEL_INCLUDED
#define COMPUTE_INSTANCING_PIXEL_INCLUDED

#include "../../Common.hlsl"

#if !defined(is_compute_instancing) && !defined(no_is_compute_instancing)
	DefineFeature(is_compute_instancing);
#endif

#include "../../ColorConversion.hlsl"
#include "../Dithering.hlsl"
#include "Struct.hlsl"

#if defined(is_compute_instancing) && defined(enable_deferred_rendering)
	#define IsComputeInstancingEnabled true
#else
	#define IsComputeInstancingEnabled false
#endif


void ComputeInstanceDithering(SurfaceParameters parameters)
{
	if(IsComputeInstancingEnabled)
	{
        DiscardDithering(parameters.pixel_position, parameters.compute_instance_parameters.w);
	}
}

void ComputeInstanceAlbedoHSVShift(inout SurfaceParameters parameters)
{
	if(IsComputeInstancingEnabled)
	{
		parameters.albedo = HSVtoRGB(RGBtoHSV(parameters.albedo) + parameters.compute_instance_parameters.xyz);
	}
}

#endif