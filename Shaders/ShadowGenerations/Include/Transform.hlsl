#ifndef TRANSFORM_INCLUDED
#define TRANSFORM_INCLUDED

#include "ConstantBuffer/World.hlsl"

int2 ClipToPixelSpace(float3 position)
{
    float2 result = position.xy / position.z;
    result.y = -result.y;
    result *= 0.5;
    result += 0.5;
    result *= u_viewport_info.xy;

    return (int2)result;
}

float4 ScreenDepthToWorldPosition(float2 screen_uv, float depth)
{
    float4 projection_position = float4(
        u_viewport_info.zw * screen_uv * float2(2.0,-2.0) + float2(-1.0,1.0),
        depth,
        1.0
    );

    float4 world_position = mul(projection_position, inv_view_proj_matrix);
    return float4(world_position.xyz / world_position.w, 1.0);
}

float2 PixelToScreen(uint2 pixel_index)
{
    // Making sure the pixel is in bounds
    pixel_index = min((uint2)u_viewport_info.xy, pixel_index);
    return (pixel_index + 0.5) / u_screen_info.xy;
}

float DepthToViewDistance(float depth)
{
    return -u_view_param.x / (depth * u_view_param.w - u_view_param.z);
}

float ViewDistanceToDepth(float view_distance)
{
    // has to be verified!
    return (view_distance * -u_view_param.x + u_view_param.z) / u_view_param.w;
}

float3 TransformPosition3(float3 position, float4x4 transformation_matrix)
{
    return mul(float4(position, 1.0), transformation_matrix).xyz;
}

// homogeneous
float4 TransformPosition3To4H(float3 position, float4x4 transformation_matrix)
{
    return mul(float4(position, 1.0), transformation_matrix);
}

// Affine
float4 TransformPosition3To4A(float3 position, float4x4 transformation_matrix)
{
    return float4(mul(float4(position, 1.0), transformation_matrix).xyz, 1.0);
}

float4 TransformPosition4(float4 position, float4x4 transformation_matrix)
{
    return mul(position, transformation_matrix);
}

float3 TransformDirection(float3 direction, float4x4 transformation_matrix)
{
    return mul(direction, (float3x3)transformation_matrix);
}

float3 TransformDirection3x3(float3 direction, float3x3 rotation_matrix)
{
    return mul(direction, rotation_matrix);
}

float3x3 AxisTrigToRotationMatrix(float3 axis, float sine, float cosine)
{
    float s = sine;
    float c = cosine;
    float t  = 1.0 - c;
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;

    return float3x3(
        t * (1.0 - y * y - z * z) + c,
        t * x * y + z * s,
        t * x * z - y * s,

        t * x * y - z * s,
        t * (1.0 - x * x - z * z) + c,
        t * y * z + x * s,

        t * x * z + y * s,
        t * y * z - x * s,
        t * (1.0 - x * x - y * y) + c
    );
}

float3x3 AxisAngleToRotationMatrix(float3 axis, float angle)
{
    float sin, cos;
    sincos(angle, sin, cos);
    return AxisTrigToRotationMatrix(axis, sin, cos);
}

float3x3 CreateShortestRotationMatrix(float3 from, float3 to)
{
    // from and to are expected to be normalized!

    float cos = clamp(dot(from, to), -1.0, 1.0);
    if(cos >= 0.99999)
    {
        return float3x3(1,0,0,0,1,0,0,0,1);
    }

    float3 axis = normalize(cross(from, to));

    // below is equal to
    // return AxisTrigToRotationMatrix(axis, sin(acos(cos)), cos);
    // but no idea how

    float a = sqrt(0.5 - cos * 0.5);
    float b = sqrt(0.5 + cos * 0.5);

    return AxisTrigToRotationMatrix(axis * a * 2, b, 0);
}

float3x3 CreateLookAtMatrix(float3 position, float3 forward_dir, float3 up_dir, float3 look_at_position)
{
    float3 camera_offset = look_at_position - position;
    float3 up_plane_camera_dir = camera_offset - (up_dir * dot(camera_offset, up_dir));

    if(dot(up_plane_camera_dir, up_plane_camera_dir) <= 0.000001)
    {
        return float3x3(1,0,0,0,1,0,0,0,1);
    }

    float3 target_dir = normalize(up_plane_camera_dir);
    return CreateShortestRotationMatrix(forward_dir, target_dir);
}

float4x4 CreateTranslationMatrix(float3 position)
{
    // return float4x4(
    // 	1, 0, 0, position.x,
    // 	0, 1, 0, position.y,
    // 	0, 0, 1, position.z,
    // 	0, 0, 0, 1
    // );

    return float4x4(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        position, 1
    );
}

float4x4 QuaternionToMatrix(float4 quaternion)
{
    float x = quaternion.x;
    float y = quaternion.y;
    float z = quaternion.z;
    float w = quaternion.w;

    float3 up = float3(
        (x * y - z * w) * 2,
        y * y + w * w - x * x - z * z,
        (y * z + x * w) * 2
    );

    float3 forward = float3(
        (x * z + y * w) * 2,
        (y * z - x * w) * 2,
        w * w + z * z - x * x - y * y
    );

    float3 right = normalize(cross(up, forward));

    return float4x4(
        right, 0,
        up, 0,
        forward, 0,
        0, 0, 0, 1);
}

float4x4 CreateScaleMatrix(float3 scale)
{
    return float4x4(
        scale.x, 0, 0, 0,
        0, scale.y, 0, 0,
        0, 0, scale.z, 0,
        0, 0, 0, 1
    );
}

float4x4 CreateTransformMatrixQuat(float3 position, float4 quaternion, float3 scale)
{
    float4x4 translation_matrix = CreateTranslationMatrix(position);
    float4x4 rotation_matrix = QuaternionToMatrix(quaternion);
    float4x4 scale_matrix = CreateScaleMatrix(scale);

    return mul(mul(scale_matrix, rotation_matrix), translation_matrix);
}

float4x4 RotationToTransformMatrix(float3x3 rotation_matrix)
{
    return float4x4(
        rotation_matrix._m00_m01_m02, 0,
        rotation_matrix._m10_m11_m12, 0,
        rotation_matrix._m20_m21_m22, 0,
        0, 0, 0, 1
    );
}

float3 RotateX(float3 position, float angle)
{
    float sin, cos;
    sincos(angle, sin, cos);

    return float3(
        position.x,
        cos * position.y - sin * position.z,
        sin * position.y + cos * position.z
    );

}

float3 RotateY(float3 position, float angle)
{
    float sin, cos;
    sincos(angle, sin, cos);

    return float3(
        sin * position.z + cos * position.x,
        position.y,
        cos * position.z - sin * position.x
    );
}

float3 RotateZ(float3 position, float angle)
{
    float sin, cos;
    sincos(angle, sin, cos);

    return float3(
        cos * position.x - sin * position.y,
        sin * position.x + cos * position.y,
        position.z
    );
}

float3x3 ZYXEulerToRotationMatrix(float3 euler_angles)
{
    float3 s = sin(euler_angles);
    float3 c = cos(euler_angles);

    return float3x3(
        c.z * c.y,
        s.z * c.y,
        -s.y,

        s.x * s.y * c.z - s.z * c.x,
        s.x * s.z * s.y + c.x * c.z,
        s.x * c.y,

        s.y * c.x * c.z + s.x * s.z,
        s.z * s.y * c.x - s.x * c.z,
        c.x * c.y
    );
}

#endif