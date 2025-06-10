#ifndef DEBUG_PIXEL_INCLUDED
#define DEBUG_PIXEL_INCLUDED

#include "../ConstantBuffer/World.hlsl"

void DebugSwitch(
	inout float3 albedo,
	inout float3 normal,
	inout float ambient_occlusion,
	float3 vertex_normal
)
{
	switch((int)round(g_debug_option.x))
    {
        case 6:
            normal = vertex_normal;
            break;
        case 8:
            albedo = 1.0;
            break;
        case 9:
            albedo = 1.0;
            ambient_occlusion = 1.0;
            break;
    }
}

#endif