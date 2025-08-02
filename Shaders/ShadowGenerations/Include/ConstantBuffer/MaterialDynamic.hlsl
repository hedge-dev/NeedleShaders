#ifndef MATERIALDYNAMIC_CONSTANTBUFFER_INCLUDED
#define MATERIALDYNAMIC_CONSTANTBUFFER_INCLUDED

cbuffer cbMaterialDynamic : register(b2)
{
    row_major float4x4 world_matrix;
    row_major float4x4 prev_world_matrix;
    float4 light_field_color[8];
    float4 u_modulate_color;
    float4 u_forcetrans_param;
    float4 u_view_offset;
    float4 u_vat_type;
    float4 u_vat_param;
    float4 u_vat_param2;
    float4 u_dvat_pos;
    float4 u_dvat_param;
    float4 u_timestamp;
    float4 u_shading_model_flag;
    float4 u_model_user_param_0;
    float4 u_model_user_param_1;
    float4 u_model_user_param_2;
    float4 u_model_user_param_3;
    float4 u_model_user_param_4;
    float4 u_model_user_param_5;
    float4 u_model_user_param_6;
    float4 u_model_user_param_7;
    float4 u_compute_instance_param;
    bool enable_shadow_map;
    bool u_disable_max_bone_influences_8;
}

bool VertexColorIsVATDirection()
{
	return u_vat_type.x > 0;
}

#endif