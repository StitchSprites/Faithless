#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:fog.glsl>
#include <minecraft:oit.glsl>
#include <minecraft:frag_utils.glsl>
#include <minecraft:config.glsl>

layout(location = 0) in float vertexDistance;
layout(location = 1) in vec4 vertexColor;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

vec4 calculateFinalColor(vec4 color) {
    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    #endif
    color.rgb = cone_filter(Colorblindness, color.rgb);
    return color;
}

void main() {
	vec4 color = vertexColor;
	// distance fade, same as vanilla: clouds fade out towards FogCloudsEnd
	#ifndef OIT_DEPTH_BOUNDS
	color.a *= 1.0 - linear_fog_value(vertexDistance, 0.0, FogCloudsEnd);
	#endif

	#ifdef OIT_ALPHA_ONLY
	executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
	#else
	fragColor = calculateFinalColor(color);
	#endif
}
