#version 330
#extension GL_ARB_separate_shader_objects : require
layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    mat4 TextureMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
};
layout(location = 0) in vec4 vertexColor;
layout(location = 0) out vec4 fragColor;
void main() {
    if (vertexColor.a <= 0.0) discard;
    fragColor = vertexColor * ColorModulator;
}
