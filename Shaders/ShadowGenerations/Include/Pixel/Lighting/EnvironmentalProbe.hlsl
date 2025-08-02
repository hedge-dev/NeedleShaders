#ifndef ENV_PROBE_LIGHTING_INCLUDED
#define ENV_PROBE_LIGHTING_INCLUDED

#include "../../ConstantBuffer/World.hlsl"

// PCR = Parallox corrected reflections
static const uint EnvProbeType_Box = 0;
static const uint EnvProbeType_Box_PCR = 1;
static const uint EnvProbeType_Sphere = 2;
static const uint EnvProbeType_Sphere_PCR = 3;

struct EnvProbeData
{
    float3 position;
    float ibl_index;
    uint type;
    bool unk0;
    float fade_offset;
    float radius;
    column_major float3x4 inv_world_matrix;
    SHColors sh_colors;
};

EnvProbeData GetEnvProbeData(int index)
{
    int offset = index * SHProbeParamSize;
    EnvProbeData result;

    result.position = g_probe_pos[index].xyz;
    result.ibl_index = g_probe_pos[index].w;

    uint flags = asuint(g_probe_param[index].x);;
    result.type = flags >> 1;
    result.unk0 = flags & 1;

    result.fade_offset = g_probe_param[index].y;
    result.radius = g_probe_param[index].z;


    result.inv_world_matrix = float3x4(
        g_probe_data[index * 3],
        g_probe_data[index * 3 + 1],
        g_probe_data[index * 3 + 2]
    );

    #define d(o) g_probe_shparam[offset + o]
    #define d3(i, x, j, y, k, z) float3(d(i).x, d(j).y, d(k).z);

    result.sh_colors.colors[0] = d3(0, x, 0, y, 0, z);
    result.sh_colors.colors[1] = d3(0, w, 1, x, 1, y);
    result.sh_colors.colors[2] = d3(1, z, 1, w, 2, x);
    result.sh_colors.colors[3] = d3(2, y, 2, z, 2, w);
    result.sh_colors.colors[4] = d3(3, x, 3, y, 3, z);
    result.sh_colors.colors[5] = d3(3, w, 4, x, 4, y);
    result.sh_colors.colors[6] = d3(4, z, 4, w, 5, x);
    result.sh_colors.colors[7] = d3(5, y, 5, z, 5, w);
    result.sh_colors.colors[8] = d3(6, x, 6, y, 6, z);

    #undef d
    #undef d3

    return result;
}

float ComputeProbeInfluence(EnvProbeData probe, float4 position)
{
	float result = 1.0;

	switch(probe.type)
	{
		case EnvProbeType_Box:
		case EnvProbeType_Box_PCR:
			float3 pos_rel_to_probe = mul(probe.inv_world_matrix, position).xyz;
			result = max(max(abs(pos_rel_to_probe.x), abs(pos_rel_to_probe.y)), abs(pos_rel_to_probe.z));
			break;

		case EnvProbeType_Sphere:
		case EnvProbeType_Sphere_PCR:
			result = length(position.xyz - probe.position) / probe.radius;
			break;
		default:
			result = 1.0;
            break;
	}

	if(result >= 0.99)
	{
		return 0.0;
	}

	return saturate(1.0 - (result - probe.fade_offset) / (1.0 - clamp(probe.fade_offset, 0.01, 0.99)));
}

#endif