#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:depth_utils.glsl>
#include <minecraft:oit.glsl>
#include <minecraft:frag_utils.glsl>
#include <minecraft:config.glsl>

uniform sampler2D Sampler0;

layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
layout(location = 2) in vec2 texCoord0;
layout(location = 3) in vec4 vertexColor;
layout(location = 4) in vec4 lightMapColor;
layout(location = 5) in vec3 cubePos;
layout(location = 6) in vec4 UV;
layout(location = 7) in vec3 glPos;
layout(location = 8) in vec2 inUV;
layout(location = 9) in float size;
layout(location = 10) flat in vec2 face;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

vec4 calculateFinalColor(vec4 color) {
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

void main() {
    vec4 color;
    float depth;

    if (Cubic_Particles && cubePos.z != 0.0) {
        vec3 glp = normalize(-glPos);
        vec3 com1 = -(1.0 / glp) * cubePos;
        vec3 com2 = size / abs(glp);
        vec3 t1 = com1 - com2;
        vec3 t2 = com1 + com2;

        float rayN = max(max(t1.x, t1.y), t1.z);
        if (rayN > min(min(t2.x, t2.y), t2.z)) {
            discard;
        }

        vec3 norm = -sign(glp) * step(t1.yzx, t1) * step(t1.zxy, t1);
        vec3 remapPos = (cubePos + glp * rayN) * 4.0 + 0.5;
        vec3 tex = vec3(abs(norm.x) != 1.0 ? (abs(norm.y) != 1.0 ? remapPos.xy : remapPos.xz) : remapPos.zy, rayN);

        vec2 divisor = (face.x == 0.0) ? vec2(1.0 - inUV.x, inUV.y) : vec2(1.0 - inUV.y, inUV.x);
        vec4 iUV = round(vec4(UV.xy / divisor.x, UV.zw / divisor.y));
        color = texture(Sampler0, (min(iUV.xy, iUV.zw) + abs(iUV.xy - iUV.zw) * tex.xy) / vec2(textureSize(Sampler0, 0)));
        if (color.a < 0.1) {
            discard;
        }
        color.rgb *= dot(norm, vec3(0.2, -1.0, 0.4)) * 0.5 + 1.0;

        // depth is reversed and its range depends on the backend, so let the projection say how to write it
        vec4 depthPos = ProjMat * ModelViewMat * vec4(-glp * tex.z, 1.0);
        depth = projection_window_depth(ProjMat, depthPos);
    } else {
        color = texture(Sampler0, texCoord0);
        if (color.a < 0.1) {
            discard;
        }
        depth = gl_FragCoord.z;
    }

    ivec4 ctrlF = ivec4(textureLod(Sampler0, texCoord0, 0.0) * 255.0);
    switch (ctrlF.a) {
    case 250:
        if (Emissives) {
            color *= vertexColor;
        }
        break;
    default:
        color *= vertexColor * lightMapColor;
        break;
    }

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(depth, color.a);
    #else
    fragColor = calculateFinalColor(color);
    #endif

    // Written last so it overrides any implicit-depth write the OIT helpers make.
    gl_FragDepth = depth;
}
