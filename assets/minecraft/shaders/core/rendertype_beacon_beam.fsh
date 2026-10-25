#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:globals.glsl>
#include <minecraft:oit.glsl>
#include <minecraft:frag_utils.glsl>
#include <minecraft:config.glsl>

uniform sampler2D Sampler0;

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in vec2 texCoord0;
layout(location = 2) in float posY;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

mat4 dither_matrix = mat4(
    1,  9,  3,  11,
    13, 5,  15, 7,
    4,  12, 2,  10,
    16, 8,  14, 6
) / 17.0;

vec4 calculateFinalColor(vec4 color) {
    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    #endif
    color.rgb = cone_filter(Colorblindness, color.rgb);
    return color;
}

void main() {
    vec2 uv = mod(texCoord0, 1.0) + sin(GameTime * vec2(-12000, -20000) + posY * vec2(2, 1)) * vec2(0.1, 0.5);

    vec4 color = texture(Sampler0, uv);
    color.a *= clamp(posY * 4.0 - 1.5, 0.0, 1.0);

    if (color.a < dither_matrix[int(gl_FragCoord.x) % 4][int(gl_FragCoord.y) % 4]) discard;

    color = vec4(vec3(color.rgb * color.rgb + 0.3), color.a) * vertexColor;

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color);
    #endif
}
