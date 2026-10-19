#version 330

// -- Depth buffer convention ---------------------------------------------------------------------------------------
// 26.2 renders with a reversed depth buffer (near = 1, far = 0), and the clip range can be [-1, 1] (classic OpenGL)
// or [0, 1] (Vulkan style) depending on the backend. Rather than hard-coding one, read it out of ProjMat.

// NDC depth ProjMat gives to a point `dist` blocks in front of the camera (perspective: ndc = -m22 - m32 / z, z = -dist).
float projection_ndc_depth(mat4 proj, float dist) {
    return -proj[2][2] + proj[3][2] / dist;
}

// true when near maps to a bigger depth value than far (26.2+).
bool projection_is_reversed(mat4 proj) {
    return projection_ndc_depth(proj, 0.05) > projection_ndc_depth(proj, 4096.0);
}

// true when NDC depth spans 0..1 instead of -1..1.
bool projection_is_zero_to_one(mat4 proj) {
    return abs(projection_ndc_depth(proj, 0.05) - projection_ndc_depth(proj, 4096.0)) < 1.5;
}

// Value to write to gl_FragDepth for a clip-space position produced with `proj`.
float projection_window_depth(mat4 proj, vec4 clipPos) {
    float ndc = clipPos.z / clipPos.w;
    return projection_is_zero_to_one(proj) ? ndc : ndc * 0.5 + 0.5;
}
