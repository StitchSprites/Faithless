#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

#ifdef DISSOLVE
uniform sampler2D DissolveMaskSampler;
#endif

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
in vec4 vertexPerFaceColorBack;
in vec4 vertexPerFaceColorFront;
#else
in vec4 vertexColor;
#endif

#ifndef EMISSIVE
in vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
in vec4 overlayColor;
#endif

in vec2 texCoord0;
in vec4 rawVertexColor;
in vec3 screenPos;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
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

#ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif

    vec4 tint = faceVertexColor;
#ifndef EMISSIVE
    vec4 shade = lightMapColor;
#else
    vec4 shade = vec4(1.0);
#endif

    ivec4 ctrlF = ivec4(color * 255.0 + 0.5);
    switch (ctrlF.a) {
    case 251:
        if (Ender_Chest) {
            vec2 screenSize = gl_FragCoord.xy / (screenPos.xy / screenPos.z * 0.5 + 0.5);
            color.rgb = render_endParallax(Endportal_Colors[0], gl_FragCoord.xy, screenSize, GameTime);
        }
        break;
    case 250:
        if (Emissives) {
            shade = vec4(1.0);
        }
        tint = rawVertexColor;
        break;
    case 2:
    case 1:
        discard;
    }

    color *= tint * shade * ColorModulator;

    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
    fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
