#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:globals.glsl>

layout(location = 0) in vec3 starPos;

layout(location = 0) out vec4 fragColor;

void main() {
    vec4 color = ColorModulator;
    float twinkle = cos((GameTime * 3000.0) + starPos.x + starPos.z);

    // Alpha = Brightness
    color.a += twinkle * 0.25;

    fragColor = color;
}
