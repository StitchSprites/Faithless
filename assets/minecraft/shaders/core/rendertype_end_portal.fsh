#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:matrix.glsl>
#include <minecraft:frag_utils.glsl>
#include <minecraft:globals.glsl>
#include <minecraft:config.glsl>

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;

layout(location = 0) in vec4 texProj0;

layout(location = 0) out vec4 fragColor;

void main() {
    vec3 color = textureProj(Sampler0, texProj0).rgb * Endportal_Colors[0];
    for (int i = 0; i < PORTAL_LAYERS; i++) {
        color += textureProj(Sampler1, texProj0 * end_portal_layer(i + 1.0, GameTime)).rgb * Endportal_Colors[i];
    }

    fragColor = vec4(color, 1.0);
    fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
