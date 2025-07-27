#ifndef DEFORMER_CONSTANTBUFFER_INCLUDED
#define DEFORMER_CONSTANTBUFFER_INCLUDED

cbuffer cbDeformer : register(b10)
{
  float4 deformer_data_packed[30] : packoffset(c0);
  float4 deformer_data_packed_end : packoffset(c256);
}

#endif