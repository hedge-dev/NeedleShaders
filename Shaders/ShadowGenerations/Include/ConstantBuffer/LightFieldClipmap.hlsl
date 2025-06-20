#ifndef LIGHTFIELDCLIPMAP_CONSTANTBUFFER_INCLUDED
#define LIGHTFIELDCLIPMAP_CONSTANTBUFFER_INCLUDED

cbuffer cbLightFieldClipmap : register(b10)
{
  float4 u_lf_param;
  float4 u_probe_param[12];
  float4 u_probe_resolution[12];
  row_major float4x4 u_inv_obb[12];
}

#endif