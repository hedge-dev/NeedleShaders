#ifndef INSTANCING_PIXEL_INCLUDED
#define INSTANCING_PIXEL_INCLUDED

#include "../ConstantBuffer/Instancing.hlsl"

float GetInstanceOpacity(float instance_index)
{
	int rounded_instance_index = (int)round(instance_index);

    if(rounded_instance_index <= 0)
    {
		return 1.0f;
    }

	int packed_instance_index = rounded_instance_index * 5 + 4;
	return instancing_data_packed[packed_instance_index].w;
}

#endif