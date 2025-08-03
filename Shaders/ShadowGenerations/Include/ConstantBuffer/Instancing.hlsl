#ifndef INSTANCING_CONSTANTBUFFER_INCLUDED
#define INSTANCING_CONSTANTBUFFER_INCLUDED

cbuffer cb_instancing : register(b13)
{
    float4 instancing_data_packed[10];
    float4 instancing_data_packed_end;
}

struct InstanceData
{
    float4x4 instance_matrix;
    float transparency;
};

InstanceData GetInstanceData(int instance_index)
{
    InstanceData result;

    bool instancing_check = instance_index >= 0;

    #ifdef is_instancing
        instancing_check = true;
    #endif

    if(instancing_check)
    {
        int offset = instance_index * 5;
        result.instance_matrix = float4x4(
			instancing_data_packed[offset].xyz, 0,
			instancing_data_packed[offset + 1].xyz, 0,
			instancing_data_packed[offset + 2].xyz, 0,
			instancing_data_packed[offset + 3].xyz, 1
		);

        result.transparency = instancing_data_packed[offset + 4].w;
    }
    else
    {
        result.instance_matrix = float4x4(
            1,0,0,0,
            0,1,0,0,
            0,0,1,0,
            0,0,0,1
        );

        result.transparency = 1.0;
    }

    return result;
}

#endif