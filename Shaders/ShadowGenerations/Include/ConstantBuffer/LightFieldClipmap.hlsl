#ifndef LIGHTFIELDCLIPMAP_CONSTANTBUFFER_INCLUDED
#define LIGHTFIELDCLIPMAP_CONSTANTBUFFER_INCLUDED

cbuffer cbLightFieldClipmap : register(b10)
{
    // --- Light field parameter ---
    // X: number of light fields
    // Y: Distance (in pixels) from the surface (in the surfaces normal direction)
    //    at which the lightfield probe should be sampled
    // Z: Distance factor to the bounds of the lightfield at which the influence
    //    should start (linearly) falling
    // W: if not 0, ignore floor/bottom samples and use black instead
    float4 u_lf_param;

    // ???
    float4 u_probe_param[12];

    // --- Light field probe texture resolutions ---
    // xyz: resolution of a single probe tile
    // w: unused
    float4 u_probe_resolution[12];

    // Matrices to transform from world space to light field local space
    row_major float4x4 u_inv_obb[12];
}

#endif