#ifndef SHLIGHTFIELD_PROBES_CONSTANTBUFFER_INCLUDED
#define SHLIGHTFIELD_PROBES_CONSTANTBUFFER_INCLUDED

static const uint SGLightFieldCount = 3;
static const uint SGLightFieldDataSize = 9;

cbuffer cb_shlightfield_probes : register(b6)
{
    float4 shlightfield_param;
    float4 shlightfield_multiply_color_up;
    float4 shlightfield_multiply_color_down;
    float4 shlightfield_probes_SHLightFieldProbe[SGLightFieldCount * SGLightFieldDataSize];
    float4 shlightfield_probe_SHLightFieldProbe_end;
}

static const uint SGLightFieldType_AmbientLighting = 0;
static const uint SGLightFieldType_AmbientOcclusion = 2;

struct SGLightFieldData
{
    int index;
    float3 scale;
    uint type;
	float4x4 inv_world_matrix;
};

SGLightFieldData GetSGLightFieldData(int index)
{
	int offset = index * SGLightFieldDataSize;

	SGLightFieldData result;
    result.index = index;

    result.scale = shlightfield_probes_SHLightFieldProbe[offset].xyz;
    result.type = (int)floor(shlightfield_probes_SHLightFieldProbe[offset + 1].x + 0.5);

	for(int i = 0; i < 4; i++)
	{
		result.inv_world_matrix[i] = shlightfield_probes_SHLightFieldProbe[offset + 5 + i];
	}

	return result;
}

#endif