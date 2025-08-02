#ifndef COMPUTE_INSTANCING_PIXEL_INCLUDED
#define COMPUTE_INSTANCING_PIXEL_INCLUDED

#include "../../Common.hlsl"

#if !defined(is_compute_instancing) && !defined(no_is_compute_instancing)
	DefineFeature(is_compute_instancing);
#endif

#include "Struct.hlsl"

#if defined(is_compute_instancing) && defined(enable_deferred_rendering)

	#include "../../ColorConversion.hlsl"
	#include "../Dithering.hlsl"

	void ComputeInstanceDithering(SurfaceParameters parameters)
	{
		DiscardDithering(parameters.pixel_position, parameters.compute_instance_parameters.w);
	}

	void ComputeInstanceAlbedoHSVShift(inout SurfaceParameters parameters)
	{
		parameters.albedo = HSVtoRGB(RGBtoHSV(parameters.albedo) + parameters.compute_instance_parameters.xyz);
	}

#else
	void ComputeInstanceDithering(SurfaceParameters parameters) { };
	void ComputeInstanceAlbedoHSVShift(inout SurfaceParameters parameters) { };
#endif



#endif