#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;

layout(location = 0) out vec4 vertexColor;
layout(location = 1) out vec2 texCoord0;
layout(location = 2) out float posY;

void main() {
    texCoord0 = UV0;

    int vertID = gl_VertexIndex % 4;
    if (vertID == 0 || vertID == 3) posY = 1024; else posY = 0;

    vertexColor = Color;
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
}
