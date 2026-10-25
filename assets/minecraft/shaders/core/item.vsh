#version 330
#extension GL_ARB_separate_shader_objects : require

// Bucket / potion / soup liquid wobble. It needs GameTime from the Globals block. If your game log ever
// complains about a missing "Globals" uniform for the item program, comment this define out; everything
// else keeps working.
#define ITEM_LIQUID_WOBBLE

#include <minecraft:light.glsl>
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:sample_lightmap.glsl>
#ifdef ITEM_LIQUID_WOBBLE
#include <minecraft:globals.glsl>
#endif

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in ivec2 UV1;
layout(location = 4) in ivec2 UV2;
#ifdef GLINT_SPECIAL
layout(location = 5) in vec2 UV3;
#endif
layout(location = 6) in vec3 Normal;

uniform sampler2D Sampler0;
#ifndef OIT_ALPHA_ONLY
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
#endif
layout(location = 2) out vec4 vertexColor;
#ifndef OIT_ALPHA_ONLY
layout(location = 3) out vec4 lightMapColor;
layout(location = 4) out vec4 overlayColor;
#endif
layout(location = 5) out vec2 texCoord0;
#ifdef GLINT
layout(location = 6) out vec2 texCoordGlint;
#endif
#ifndef OIT_ALPHA_ONLY
layout(location = 7) out vec4 rawVertexColor;
#endif

#ifdef ITEM_LIQUID_WOBBLE
vec3 liquid_render(float value) {
    float wave = (Position.x + Position.y + Position.z + GameTime * 5000.0) * 0.333;
    return (sin(wave) + sin(wave * 2.1)) * vec3(0.005, 0.015, 0.005) * value;
}
#endif

void main() {
    vec3 pos = Position;

#ifdef ITEM_LIQUID_WOBBLE
    ivec2 atlasSize = textureSize(Sampler0, 0);
    ivec4 ctrlV = ivec4(texelFetch(Sampler0, clamp(ivec2(floor(UV0 * vec2(atlasSize))), ivec2(0), atlasSize - 1), 0) * 255.0 + 0.5);
    switch (ctrlV.a) {
    case 255: case 0: break;
    case 254: pos.y += liquid_render(1.0).y; break;	// Bucket, Potion, & Soup
    case 1: pos.y += liquid_render(1.0).y; break;	// Bucket, Potion, & Soup
    }
#endif

    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

#ifndef OIT_ALPHA_ONLY
    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
#endif
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
#ifndef OIT_ALPHA_ONLY
    rawVertexColor = Color;
    lightMapColor = sample_lightmap(Sampler2, UV2);
    overlayColor = texelFetch(Sampler1, UV1, 0);
#endif

    texCoord0 = UV0;
#ifdef GLINT
#ifdef GLINT_SPECIAL
    texCoordGlint = (TextureMat * vec4(UV3, 0.0, 1.0)).xy;
#else
    texCoordGlint = (TextureMat * vec4(UV0, 0.0, 1.0)).xy;
#endif
#endif
}
