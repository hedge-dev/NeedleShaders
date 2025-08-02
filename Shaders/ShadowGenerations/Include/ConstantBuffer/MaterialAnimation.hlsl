#ifndef MATERIALANIM_CONSTANTBUFFER_INCLUDED
#define MATERIALANIM_CONSTANTBUFFER_INCLUDED

cbuffer cbMaterialAnimation : register(b4)
{
  float4 diffuse_color : packoffset(c0);
  float4 ambient_color : packoffset(c1);
  float4 specular_color : packoffset(c2);
  float4 emissive_color : packoffset(c3);
  float4 alpha_threshold : packoffset(c4);
}

#endif