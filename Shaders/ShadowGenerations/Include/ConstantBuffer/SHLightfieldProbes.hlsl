#ifndef SHLIGHTFIELD_PROBES_CONSTANTBUFFER_INCLUDED
#define SHLIGHTFIELD_PROBES_CONSTANTBUFFER_INCLUDED

cbuffer cb_shlightfield_probes : register(b6)
{
    float4 shlightfield_param;
    float4 shlightfield_multiply_color_up;
    float4 shlightfield_multiply_color_down;
    float4 shlightfield_probes_SHLightFieldProbe[27];
    float4 shlightfield_probe_SHLightFieldProbe_end;
}

#endif