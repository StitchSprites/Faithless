#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>

layout(location = 0) in vec3 Position;

layout(location = 0) out vec4 texProj0;

void main() {
    vec3 pos = Position + ModelOffset;
    if (PORTAL_LAYERS == 15) pos.y -= 0.746;
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
    texProj0 = projection_from_position(gl_Position);
}
