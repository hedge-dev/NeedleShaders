#ifndef REFLECTION_LIGHTING_INCLUDED
#define REFLECTION_LIGHTING_INCLUDED

void ApplyReflection(inout float3 emission, inout float3 sunlight_specular, float ambient_occlusion)
{
	if(ambient_occlusion <= 0.00001)
	{
		return;
	}

	//TODO
}

#endif