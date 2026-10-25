#version 330
#extension GL_ARB_separate_shader_objects : require

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#include <minecraft:fog.glsl>
#endif

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>
#include <minecraft:frag_utils.glsl>
#include <minecraft:config.glsl>

uniform sampler2D Sampler0;

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#endif

layout(location = 2) in vec4 vertexColor;
layout(location = 3) in vec2 texCoord0;
layout(location = 4) in vec4 tint;
layout(location = 5) flat in int Debug;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

vec4 calculateFinalColor(vec4 color) {
    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    #endif

    #if !defined(IS_SEE_THROUGH) && !defined(IS_GUI)

    #ifdef OIT_ACCUMULATE
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif

    color = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
    #endif

    color.rgb = cone_filter(Colorblindness, color.rgb);
    return color;
}

void main() {
#ifdef IS_GRAYSCALE
    vec4 texColor = texture(Sampler0, texCoord0).rrrr;
#else
    vec4 texColor = texture(Sampler0, texCoord0);
#endif

    vec4 color = texColor * vertexColor * ColorModulator * tint;
    if (color.a < 0.1) discard;
	
#ifndef IS_GRAYSCALE
	if (Debug != 0) {
		
		ivec4 ctrlF = ivec4(color * 255.0 + 0.5);
		
		switch (ctrlF.a) {
			case 255: if (tint == debugMenu[5] || tint == debugMenu[6] || tint == debugMenu[7]) color = debugMenu[1]; break;
			case 254: if (tint == debugMenu[1] || tint == debugMenu[8] || tint == debugMenu[0]) color = debugMenu[2]; 
					  if (tint == debugMenu[10]) color = debugMenu[12]; break;
			case 253: if (tint == debugMenu[1] || tint == debugMenu[8] || tint == debugMenu[0]) color = debugMenu[3]; 
					  if (tint == debugMenu[10]) color = debugMenu[11]; break;
			case 252: if (tint == debugMenu[5] || tint == debugMenu[6] || tint == debugMenu[7]) color = debugMenu[3]; 
					  if (tint == debugMenu[10]) color = debugMenu[12]; break;
		}
		
		 if (tint == debugMenu[10] && Debug == 1) color += 0.1;
	}
#endif

#ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
#else
    fragColor = calculateFinalColor(color);
#endif
}
