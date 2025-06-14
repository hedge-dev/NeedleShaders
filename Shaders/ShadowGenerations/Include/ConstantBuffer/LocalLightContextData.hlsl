#ifndef LOCALLIGHTCONTEXTDATA_CONSTANTBUFFER_INCLUDED
#define LOCALLIGHTCONTEXTDATA_CONSTANTBUFFER_INCLUDED

cbuffer cb_local_light_context_data : register(b8)
{
    float4 g_local_light_count;
    float4 g_local_light_shadow_param[3];
    row_major float4x4 g_local_light_shadow_matrix[3];
    row_major float4x4 g_local_light_data[1000];
}

#endif