#ifndef BONES_CONSTANTBUFFER_INCLUDED
#define BONES_CONSTANTBUFFER_INCLUDED

cbuffer cbBones : register(b5)
{
  row_major float3x4 needle_bone_matrix[4] : packoffset(c0);
  row_major float3x4 needle_bone_matrix_end : packoffset(c1021);
}

#endif