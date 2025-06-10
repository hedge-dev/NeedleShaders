#ifndef MATERIAL_IMMUTABLE_CONSTANTBUFFER_INCLUDED
#define MATERIAL_IMMUTABLE_CONSTANTBUFFER_INCLUDED

#define MaterialImmutables cbuffer cbMaterialImmutable : register(b1)

#define UVInput(name) \
	float4 TexcoordIndex_##name; \
	float4 TexcoordMtx_##name[2];

#endif