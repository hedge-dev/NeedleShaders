#ifndef WORLD_CONSTANTBUFFER_INCLUDED
#define WORLD_CONSTANTBUFFER_INCLUDED

static const uint MaxProbeCount = 24;
static const uint ProbeDataSize = 3;
static const uint SHProbeParamSize = 7;

cbuffer cbWorld : register(b0)
{
    row_major float4x4 view_matrix;
    row_major float4x4 proj_matrix;
    row_major float4x4 inv_view_matrix;
    row_major float4x4 inv_proj_matrix;
    float4 global_clip_plane;
    float4 clear_color;
    row_major float4x4 view_proj_matrix;
    row_major float4x4 inv_view_proj_matrix;
    row_major float4x4 prev_view_proj_matrix;
    row_major float4x4 uv_reproj_matrix;
    float4 jitter_offset;
    float4 global_mip_bias;
    float4 shadow_camera_view_matrix_third_row;
    row_major float4x4 shadow_view_matrix;
    row_major float4x4 shadow_view_proj_matrix;
    float4 shadow_map_parameter[2];
    float4 shadow_map_size;
    float4 shadow_cascade_offset[4];
    float4 shadow_cascade_scale[4];
    float4 shadow_parallax_correct_param[4];
    float4 shadow_cascade_frustums_eye_space_depth;
    float4 shadow_cascade_transition_scale;
    row_major float4x4 heightmap_view_matrix;
    row_major float4x4 heightmap_view_proj_matrix;
    float4 heightmap_parameter;
    float4 planar_reflection_parameter;
    float4 u_lightColor;
    float4 u_lightDirection;
    float4 u_cameraPosition;

    float4 g_probe_data[MaxProbeCount * ProbeDataSize];
    float4 g_probe_pos[MaxProbeCount];
    float4 g_probe_param[MaxProbeCount];
    float4 g_probe_shparam[MaxProbeCount * SHProbeParamSize];
    float4 g_probe_count;

    // xyz: rayleigh value (color)
    // w: mie value
    float4 g_LightScattering_Ray_Mie_Ray2_Mie2;

    // x: (1.0f - g) * (1.0f - g);
    // y: g * g + 1.0f;
    // z: g * -2.0f;
    float4 g_LightScattering_ConstG_FogDensity;

    // x: 1.0f / (zFar - zNear)
    // y: zNear
    // z: depthScale
    // w: inScatteringScale
    float4 g_LightScatteringFarNearScale;

    float4 g_LightScatteringColor;
    float4 g_alphathreshold;
    float4 g_smoothness_param;
    float4 g_time_param;
    float4 u_ibl_param;
    float4 u_planar_projection_shadow_plane;
    float3 u_planar_projection_shadow_light_position;
    float4 u_planar_projection_shadow_color;
    float4 u_planar_projection_shadow_param;
    float4 g_global_user_param_0;
    float4 g_global_user_param_1;
    float4 g_global_user_param_2;
    float4 g_global_user_param_3;
    float4 g_global_user_param_4;
    float4 g_global_user_param_5;
    float4 g_global_user_param_6;
    float4 g_global_user_param_7;
    bool u_enable_fog_d;
    bool u_enable_fog_h;
    float4 u_fog_param_0;
    float4 u_fog_param_1;
    float4 u_fog_param_2;
    float4 u_fog_param_3;
    float4 g_tonemap_param;
    float4 u_contrast_factor[3];
    float4 u_hls_offset;
    float4 u_hls_rgb;
    float4 u_hls_colorize;
    float4 u_color_grading_factor;

    // x: screen width
    // y: screen height
    // z: 1 / screen width
    // w: 1 / screen height
    float4 u_screen_info;
    float4 u_current_viewport_mask;

    // x: screen width
    // y: screen height
    // zw: ??
    float4 u_viewport_info;

    // u_viewport_info on the previous frame
    float4 u_prev_viewport_info;
    float4 u_view_param;
    float4 u_sggi_param[2];
    float4 u_histogram_param;
    float4 u_occlusion_capsule_param[2];
    float4 u_ssao_param;
    float4 u_wind_param[5];
    float4 u_wind_frequencies;
    float4 u_wind_global_param[3];
    float4 u_grass_lod_distance;
    float4 u_grass_dither_distance;
    float4 u_weather_param;
    float4 u_hiz_param;
    float4 u_rlr_param[2];
    float4 u_sky_sh_param[9];

    // x: screen width (in tiles)
    // y: light data offset start (?)
    // z: screen width
    // w: screen height
    float4 u_tile_info;
    float4 u_detail_param;
    bool enable_ibl_plus_directional_specular;
    bool enable_rlr;
    bool enable_rlr_trans_surface;
    bool enable_vol_shadow;
    float4 g_debug_option;
    float4 g_debug_param_float;
    int4 g_debug_param_int;
    float4 u_interaction_param[2];
    float4 u_cloud_shadow_param;
    float4 u_vol_shadow_param[5];
    float4 cyber_space_noise_param[2];
}

struct SHColors
{
    float3 colors[9];
};

SHColors GetSkySHColors()
{
    SHColors result;

    for(int i = 0; i < 9; i++)
    {
        result.colors[i] = u_sky_sh_param[i].xyz;
    }

    return result;
}

struct SHProbeData
{
    float3 position;
    uint type;
    bool unk0;
    float unk1;
    float unk2;
    column_major float3x4 inv_world_matrix;
    SHColors sh_colors;
};

SHProbeData GetSHProbeData(int index)
{
    int offset = index * SHProbeParamSize;
    SHProbeData result;

    result.position = g_probe_pos[index].xyz;

    uint flags = asuint(g_probe_param[index].x);;
    result.type = flags >> 1;
    result.unk0 = flags & 1;

    result.unk1 = g_probe_param[index].y;
    result.unk2 = g_probe_param[index].z;

    result.inv_world_matrix = float3x4(
        g_probe_data[index * 3],
        g_probe_data[index * 3 + 1],
        g_probe_data[index * 3 + 2]
    );

    #define d(o) g_probe_shparam[offset + o]
    #define d3(i, x, j, y, k, z) float3(d(i).x, d(j).y, d(k).z);

    result.sh_colors.colors[0] = d3(0, x, 0, y, 0, z);
    result.sh_colors.colors[1] = d3(0, w, 1, x, 1, y);
    result.sh_colors.colors[2] = d3(1, z, 1, w, 2, x);
    result.sh_colors.colors[3] = d3(2, y, 2, z, 2, w);
    result.sh_colors.colors[4] = d3(3, x, 3, y, 3, z);
    result.sh_colors.colors[5] = d3(3, w, 4, x, 4, y);
    result.sh_colors.colors[6] = d3(4, z, 4, w, 5, x);
    result.sh_colors.colors[7] = d3(5, y, 5, z, 5, w);
    result.sh_colors.colors[8] = d3(6, x, 6, y, 6, z);

    #undef d
    #undef d3

    return result;
}


#endif