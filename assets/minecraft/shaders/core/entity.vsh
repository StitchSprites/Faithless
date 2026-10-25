#version 330
#extension GL_ARB_separate_shader_objects : require

#if defined(PER_FACE_LIGHTING) || !defined(NO_CARDINAL_LIGHTING)
#include <minecraft:light.glsl>
#endif
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:sample_lightmap.glsl>
#include <minecraft:config.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in ivec2 UV1;
layout(location = 4) in ivec2 UV2;
layout(location = 5) in vec3 Normal;

uniform sampler2D Sampler0;

#if !defined(NO_OVERLAY) && !defined(OIT_ALPHA_ONLY)
uniform sampler2D Sampler1;
#endif

#if !defined(EMISSIVE) && !defined(OIT_ALPHA_ONLY)
uniform sampler2D Sampler2;
#endif

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;

#ifdef PER_FACE_LIGHTING
layout(location = 2) out vec4 vertexPerFaceColorBack;
layout(location = 3) out vec4 vertexPerFaceColorFront;
#else
layout(location = 2) out vec4 vertexColor;
#endif

#ifndef EMISSIVE
layout(location = 4) out vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
layout(location = 5) out vec4 overlayColor;
#endif

layout(location = 6) out vec2 texCoord0;
#ifdef GLINT
layout(location = 7) out vec2 texCoordGlint;
#endif
layout(location = 8) out vec4 rawVertexColor;
layout(location = 9) out vec3 screenPos;
layout(location = 10) flat out int isCrystalBeam;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    screenPos = gl_Position.xyw;
    rawVertexColor = Color;

    // End Crystal beam: control pixel (0, 0, 0, 12) at texel (0, 0)
    isCrystalBeam = (ivec4(texelFetch(Sampler0, ivec2(0, 0), 0) * 255.0 + 0.5) == ivec4(0, 0, 0, 12)) ? 1 : 0;

    bool useCardinalLighting = true;
    if (Fresh_Animations) {
        ivec4 ctrlL = ivec4(texture(Sampler0, vec2(0.0)) * 255.0 + 0.5);
        if (ctrlL.a == 128 && ctrlL.r >= 1 && ctrlL.r <= 4) {
            useCardinalLighting = false;
        }
    }

    vec4 skinProbe = texelFetch(Sampler0, ivec2(62, 51), 0) * 255.0;
    if (Player_Skin_Features && skinProbe.a == 220.0 && textureSize(Sampler0, 0) == ivec2(64, 64)) {
        useCardinalLighting = false;
    }

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);

#ifdef PER_FACE_LIGHTING
    vec2 light = minecraft_compute_light(Light0_Direction, Light1_Direction, Normal);
    vertexPerFaceColorBack = minecraft_mix_light_separate(-light, Color);
    vertexPerFaceColorFront = minecraft_mix_light_separate(light, Color);
    if (!useCardinalLighting) {
        vertexPerFaceColorBack = vec4(1.0);
        vertexPerFaceColorFront = vec4(1.0);
    }
#elif defined(NO_CARDINAL_LIGHTING)
    vertexColor = Color;
#else
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    if (!useCardinalLighting) {
        vertexColor = vec4(1.0);
    }
#endif

#if !defined(EMISSIVE) && !defined(OIT_ALPHA_ONLY)
    lightMapColor = sample_lightmap(Sampler2, UV2);
#endif

#if !defined(NO_OVERLAY) && !defined(OIT_ALPHA_ONLY)
    overlayColor = texelFetch(Sampler1, UV1, 0);
#endif

    texCoord0 = UV0;

#ifdef APPLY_TEXTURE_MATRIX
    texCoord0 = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
#endif

#ifdef GLINT
    texCoordGlint = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
#endif
}
