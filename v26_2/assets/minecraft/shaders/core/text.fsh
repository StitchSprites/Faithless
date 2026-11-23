#version 330
#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#moj_import <minecraft:fog.glsl>
#endif
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:config.glsl>
uniform sampler2D Sampler0;
#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
in float sphericalVertexDistance;
in float cylindricalVertexDistance;
#endif
in vec4 vertexColor;
in vec2 texCoord0;
in vec4 tint;
flat in int Debug;
out vec4 fragColor;
void main() {
    #ifdef IS_GRAYSCALE
    vec4 texColor = texture(Sampler0, texCoord0).rrrr;
    #else
    vec4 texColor = texture(Sampler0, texCoord0);
    #endif
    // Keep Faithless GUI typography, using the Minecraft 26.2 text pipeline.
    vec4 color = texColor * vertexColor * tint;
#ifndef IS_SEE_THROUGH
    color *= ColorModulator;
#endif
    if (color.a < 0.1) discard;
#if defined(IS_GUI)
    if (Debug != 0) {
        ivec4 ctrlF = ivec4(color * 255.0 + 0.5);
        if (ctrlF.a == 255 && (tint == debugMenu[5] || tint == debugMenu[6] || tint == debugMenu[7])) color = debugMenu[1];
        if (ctrlF.a == 254 && (tint == debugMenu[1] || tint == debugMenu[8] || tint == debugMenu[0])) color = debugMenu[2];
        if (ctrlF.a == 253 && (tint == debugMenu[1] || tint == debugMenu[8] || tint == debugMenu[0])) color = debugMenu[3];
    }
#endif
#ifdef IS_SEE_THROUGH
    fragColor = color * ColorModulator;
#elif defined(IS_GUI)
    fragColor = color;
#else
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance,
        FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart,
        FogRenderDistanceEnd, FogColor);
#endif
}
