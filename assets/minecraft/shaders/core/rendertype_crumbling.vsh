#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;

layout(location = 0) out vec4 vertexColor;
layout(location = 1) out vec2 texCoord0;
layout(location = 2) out vec3 fragPos;

void main() {
    texCoord0 = UV0;
    // The 3D breaking effect needs the face normal, but the Normal attribute is not available here.
    // The position is handed to the fragment stage, which rebuilds the normal from its screen-space derivatives.
    fragPos = Position;

    vertexColor = Color;
    mat4 ProjViewMat = ProjMat * ModelViewMat;
    gl_Position = ProjViewMat * vec4(Position, 1.0);
}
