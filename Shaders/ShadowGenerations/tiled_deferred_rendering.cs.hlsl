#include "Include/Common.hlsl"

//DefineFeature(enable_deferred_ambient);
static const uint FEATURE_enable_deferred_ambient;

#include "Include/Pixel/Lighting/Composite.hlsl"


Texture2D<float4> s_DepthBuffer;
Texture2D<float4> s_GBuffer0;
Texture2D<float4> s_GBuffer1;
Texture2D<float4> s_GBuffer2;
Texture2D<float4> s_GBuffer3;

RWTexture2D<float4> rw_Output0 : register(u0);

struct ThreadInfo {
	uint3 groupId : SV_GroupID;
    uint3 groupThreadId : SV_GroupThreadID;
    uint3 dispatchThreadId : SV_DispatchThreadID;
    uint groupIndex : SV_GroupIndex;
};

[numthreads(8, 8, 1)]
void main(ThreadInfo input)
{
	SurfaceData deferred_data = InitSurfaceData();

	uint3 buffer_uv = int3(input.dispatchThreadId.xy, 0);
	deferred_data.albedo = s_GBuffer0.Load(buffer_uv);
	deferred_data.normal = s_GBuffer1.Load(buffer_uv).xyz;
	deferred_data.emission = s_GBuffer2.Load(buffer_uv);
	deferred_data.prm = s_GBuffer3.Load(buffer_uv);

	LightingParameters parameters = InitLightingParameters();
	TransferSurfaceData(deferred_data, parameters);

	ComputeSSSSTile(parameters.shading_mode, input.groupIndex, input.groupThreadId.xy);

	if(parameters.shading_mode == 0
		|| (float)input.dispatchThreadId.x >= u_viewport_info.x
		|| (float)input.dispatchThreadId.y >= u_viewport_info.y)
	{
		rw_Output0[input.dispatchThreadId.xy] = clear_color;
		ClearSSSOutput(input.dispatchThreadId.xy);
		return;
	}

	float depth = s_DepthBuffer.Load(buffer_uv).x;
	float view_distance = DepthToViewDistance(depth);

	parameters.pixel_position = input.dispatchThreadId.xy;
	parameters.tile_position = input.groupThreadId.xy >> 1;

	parameters.screen_position = PixelToScreen(input.dispatchThreadId.xy);
	parameters.world_position = ScreenDepthToWorldPosition(parameters.screen_position, depth);

	parameters.view_direction = normalize(u_cameraPosition.xyz - parameters.world_position.xyz);
	parameters.cos_view_direction = saturate(dot(parameters.world_normal, parameters.view_direction));
	parameters.light_scattering_colors = ComputeLightScatteringColors(view_distance, parameters.view_direction);

	rw_Output0[input.dispatchThreadId.xy] = CompositeLighting(parameters);
}