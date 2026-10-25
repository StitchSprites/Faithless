#version 330
#extension GL_ARB_separate_shader_objects : require

#ifdef GLINT
#include <minecraft:globals.glsl>
#endif
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>
#include <minecraft:frag_utils.glsl>
#include <minecraft:config.glsl>

uniform sampler2D Sampler0;

#ifdef GLINT
uniform sampler2D GlintSampler;
#endif

#ifndef OIT_ALPHA_ONLY
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#endif
layout(location = 2) in vec4 vertexColor;
#ifndef OIT_ALPHA_ONLY
layout(location = 3) in vec4 lightMapColor;
layout(location = 4) in vec4 overlayColor;
#endif
layout(location = 5) in vec2 texCoord0;
#ifdef GLINT
layout(location = 6) in vec2 texCoordGlint;
#endif
#ifndef OIT_ALPHA_ONLY
layout(location = 7) in vec4 rawVertexColor;
#endif

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

#ifndef OIT_ALPHA_ONLY
vec4 calculateFinalColor(vec4 color, vec4 shade) {
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= shade;

    #ifdef GLINT
    vec4 glintColor = GlintAlpha * texture(GlintSampler, texCoordGlint);
    // Matches BlendFuntion.GLINT
    color.rgb += glintColor.rgb * glintColor.rgb;
    #endif

    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif

    color = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
    color.rgb = cone_filter(Colorblindness, color.rgb);
    return color;
}
#endif

void main() {
	vec4 color = texture(Sampler0, texCoord0);
#ifdef ALPHA_CUTOUT
	if (color.a < ALPHA_CUTOUT) {
		discard;
	}
#endif

	vec2 ctrlTextureSize = vec2(textureSize(Sampler0, 0));
	vec2 ctrlTexelCenter = (floor(texCoord0 * ctrlTextureSize) + 0.5) / ctrlTextureSize;
	ivec4 ctrlF = ivec4(textureLod(Sampler0, ctrlTexelCenter, 0) * 255.0 + 0.5);

	vec4 tint = vertexColor;
	bool fullbright = false;

	// Control alphas from the old item_entity_translucent_cull program.
	switch (ctrlF.a) {
	case 255: case 254: color.a = 1.0; break;												// solid
	case 250:																				// emissive
		if (Emissives) fullbright = true;
#ifndef OIT_ALPHA_ONLY
		tint = rawVertexColor;
#endif
		color.a = 1.0;
		break;
	case 1: discard;
	}

	// Only control codes go opaque; real translucency (stained glass) keeps its alpha even when ALPHA_CUTOUT is defined.
	if (ctrlF.a == 180 || ctrlF.a == 181) color.a = 1.0;

	color *= tint * ColorModulator;

#ifdef GLINT
	color.a = max(color.a, GlintAlpha);
#endif

#ifdef OIT_ALPHA_ONLY
	executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
#else
	fragColor = calculateFinalColor(color, fullbright ? vec4(1.0) : lightMapColor);
#endif
}
