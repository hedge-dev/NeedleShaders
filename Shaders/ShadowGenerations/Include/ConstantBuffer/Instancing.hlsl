#ifndef INSTANCING_CONSTANTBUFFER_INCLUDED
#define INSTANCING_CONSTANTBUFFER_INCLUDED

cbuffer cb_instancing : register(b13)
{
  float4 instancing_data_packed[10];
  float4 instancing_data_packed_end;
}

#endif