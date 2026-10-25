#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:frag_utils.glsl>
#include <minecraft:config.glsl>

layout(location = 0) in vec4 vertexColor;

layout(location = 0) out vec4 fragColor;

void main() {
	fragColor = vertexColor;
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
