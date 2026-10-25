#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:globals.glsl>
#include <minecraft:oit.glsl>
#include <minecraft:frag_utils.glsl>
#include <minecraft:config.glsl>

uniform sampler2D Sampler0;

#ifdef DISSOLVE
uniform sampler2D DissolveMaskSampler;
#endif

#ifdef GLINT
uniform sampler2D GlintSampler;
#endif

layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
layout(location = 2) in vec4 vertexPerFaceColorBack;
layout(location = 3) in vec4 vertexPerFaceColorFront;
#else
layout(location = 2) in vec4 vertexColor;
#endif

#ifndef EMISSIVE
layout(location = 4) in vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
layout(location = 5) in vec4 overlayColor;
#endif

layout(location = 6) in vec2 texCoord0;
#ifdef GLINT
layout(location = 7) in vec2 texCoordGlint;
#endif
layout(location = 8) in vec4 rawVertexColor;
layout(location = 9) in vec3 screenPos;
layout(location = 10) flat in int isCrystalBeam;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

#ifndef OIT_ALPHA_ONLY
vec4 calculateFinalColor(vec4 color) {
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
    // The cone filters are linear, so they commute with OIT accumulation.
    color.rgb = cone_filter(Colorblindness, color.rgb);
    return color;
}
#endif

void main() {
    // End Crystal beam: its texture is a single (0, 0, 0, 12) pixel.
    // 26.3 removed the transparency post effect this used to write a marker for, so the beam is simply hidden
    // (same as Fabulous_End_Crystals = false used to do).
    if (isCrystalBeam != 0) {
        discard;
    }

    vec4 color = texture(Sampler0, texCoord0);

#ifdef OIT_ADDITIVE
    color.a = min(0.99, color.a);
#endif

#ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
#endif

#ifdef PER_FACE_LIGHTING
    vec4 faceVertexColor = gl_FrontFacing ? vertexPerFaceColorFront : vertexPerFaceColorBack;
#else
    vec4 faceVertexColor = vertexColor;
#endif

#ifdef DISSOLVE
    if (faceVertexColor.a < texture(DissolveMaskSampler, texCoord0).a) {
        discard;
    }
    // The dissolve effect entirely replaces translucency
    faceVertexColor.a = 1.0;
#endif

    vec4 tint = faceVertexColor;
    vec4 shade = vec4(1.0);
#ifndef EMISSIVE
#ifndef OIT_ALPHA_ONLY
    shade = lightMapColor;
#endif
#endif

#ifndef NO_OVERLAY
#ifndef OIT_ALPHA_ONLY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif
#endif

    ivec4 ctrlF = ivec4(texture(Sampler0, texCoord0) * 255.0 + 0.5);
    switch (ctrlF.a) {
    case 251:
#ifndef OIT_ALPHA_ONLY
        if (Ender_Chest) {
            vec2 screenSize = gl_FragCoord.xy / (screenPos.xy / screenPos.z * 0.5 + 0.5);
            color.rgb = render_endParallax(Endportal_Colors[0], gl_FragCoord.xy, screenSize, GameTime);
        }
#endif
        break;
    case 250:
        if (Emissives) {
            shade = vec4(1.0);
        }
        tint = vec4(rawVertexColor.rgb, faceVertexColor.a);
        break;
    case 2:
    case 1:
        discard;
    }

    color *= tint * shade * ColorModulator;

#ifdef GLINT
    color.a = max(color.a, GlintAlpha);
#endif

#ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
#else
    fragColor = calculateFinalColor(color);
#endif
}
