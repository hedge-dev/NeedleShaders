#include "Include/Pixel/Lighting/Composite.hlsl"

Texture2D<float4> s_DepthBuffer;
Texture2D<float4> s_GBuffer0;
Texture2D<float4> s_GBuffer1;
Texture2D<float4> s_GBuffer2;
Texture2D<float4> s_GBuffer3;

struct DeferredIn
{
	float4 pixel_position : SV_POSITION0;
	float2 screen_position : TEXCOORD0;
};

struct DeferredOut
{
	float4 color : SV_Target0;

	#ifdef enable_ssss
		float4 ssss_color : SV_Target1;
		float ssss_mask : SV_Depth;
	#endif
};


DeferredOut main(DeferredIn input)
{
	SurfaceData deferred_data = InitSurfaceData();

	uint3 buffer_uv = int3(input.pixel_position.xy, 0);
	deferred_data.albedo = s_GBuffer0.Load(buffer_uv);
	deferred_data.normal = s_GBuffer1.Load(buffer_uv).xyz;
	deferred_data.emission = s_GBuffer2.Load(buffer_uv);
	deferred_data.prm = s_GBuffer3.Load(buffer_uv);

	LightingParameters parameters = InitLightingParameters();
	TransferSurfaceData(deferred_data, parameters);

	DeferredOut result;

	if(parameters.shading_model.type == ShadingModelType_Clear)
	{
		result.color = clear_color;

		#ifdef enable_ssss
			result.ssss_color = 0.0;
			result.ssss_mask = 0.0;
		#endif
		return result;
	}

	float depth = s_DepthBuffer.Load(buffer_uv).x;
	parameters.view_distance = DepthToViewDistance(depth);

	parameters.pixel_position = buffer_uv.xy;
	parameters.tile_position = buffer_uv.xy >> 4;

	parameters.screen_position = PixelToScreen(parameters.pixel_position);
	parameters.world_position = ScreenDepthToWorldPosition(parameters.screen_position, depth);

	parameters.view_direction = normalize(u_cameraPosition.xyz - parameters.world_position.xyz);
	parameters.cos_view_normal = saturate(dot(parameters.view_direction, parameters.world_normal));
	parameters.light_scattering_colors = ComputeLightScatteringColors(parameters.view_distance, parameters.view_direction);

	float4 ssss_color;
	float ssss_mask;
	result.color = CompositeLighting(parameters, ssss_color, ssss_mask);

	#ifdef enable_ssss
		result.ssss_color = ssss_color;
		result.ssss_mask = ssss_mask;
	#endif

	return result;
}