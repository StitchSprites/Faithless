#version 330
#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:config.glsl>
uniform sampler2D Sampler0;
in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec4 tint;
flat in int Debug;
flat in int GUIFlag;
out vec4 fragColor;
void main() {
    vec4 texColor = texture(Sampler0, texCoord0).rrrr;
    vec4 color = texColor * vertexColor * tint * ColorModulator;
    if (color.a < 0.1) discard;
    if (GUIFlag != 0) {
        if (Debug != 0) {
            ivec4 ctrlF = ivec4(color * 255.0 + 0.5);
            if (ctrlF.a == 255 && (tint == debugMenu[5] || tint == debugMenu[6] || tint == debugMenu[7])) color = debugMenu[1];
            if (ctrlF.a == 254 && (tint == debugMenu[1] || tint == debugMenu[8] || tint == debugMenu[0])) color = debugMenu[2];
            if (ctrlF.a == 253 && (tint == debugMenu[1] || tint == debugMenu[8] || tint == debugMenu[0])) color = debugMenu[3];
        }
        fragColor = color;
    } else {
        fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance,
            FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart,
            FogRenderDistanceEnd, FogColor);
    }
}
