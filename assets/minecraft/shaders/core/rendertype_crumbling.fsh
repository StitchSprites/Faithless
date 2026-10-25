#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:oit.glsl>
#include <minecraft:frag_utils.glsl>
#include <minecraft:config.glsl>

uniform sampler2D Sampler0;

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in vec2 texCoord0;
layout(location = 2) in vec3 fragPos;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

vec4 calculateFinalColor(vec4 color) {
    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    #endif
    return color;
}

void main() {
    // Face normal from the slope of the position across the screen.
    // Taken before any branch or discard so the derivatives stay well-defined.
    vec3 faceN = cross(dFdx(fragPos), dFdy(fragPos));

    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < 0.1) discard;

    if (Destroy_Depth > 0 && color.a == 1) {
        vec3 Normal = normalize(faceN);
        if (dot(Normal, fragPos) > 0.0) Normal = -Normal;   // point it back toward the camera (outward for visible faces)

        // Parallax offset
        mat3 mat;
        if (abs(Normal.y) >= 0.9) mat = mat3(vec3(1, 0, 0), vec3(0, 0, -1), Normal);
        else mat = mat3(cross(Normal, vec3(0, 1, 0)), vec3(0, 1, 0), Normal);

        vec3 viewDir = normalize(fragPos * mat);
        vec3 offset = viewDir / -viewDir.z / textureSize(Sampler0, 0).x / 16.0 * Destroy_Depth;

        if (abs(Normal.z) >= 0.9) offset.x *= -1;
        if (Normal.y > -0.9) offset.y *= -1;

        float i;
        for (i = 1.0; i <= 16.0; i++) if (texture(Sampler0, texCoord0 + offset.xy * i).a != 1) break;

        if (i <= 16.0) color = (i <= 2.0) ? vec4(0.6, 0.6, 0.58, 1.0) : vec4(vec3(0.3 - i * 0.01), 1.0);
        else color = vec4(vec3(0.5 - i * 0.01), 1.0);
    }

    color *= vertexColor;

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color);
    #endif
}
