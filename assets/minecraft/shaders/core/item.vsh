#version 330

// Bucket / potion / soup liquid wobble (it used to live in rendertype_item_entity_translucent_cull.vsh, a program
// 26.1 removed). It needs GameTime from the Globals block. If your game log ever complains about a missing
// "Globals" uniform for the item program, comment this define out; everything else keeps working.
#define ITEM_LIQUID_WOBBLE

#moj_import <minecraft:light.glsl>
#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:sample_lightmap.glsl>
#ifdef ITEM_LIQUID_WOBBLE
#moj_import <minecraft:globals.glsl>
#endif

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec4 rawVertexColor;
out vec4 lightMapColor;
out vec4 overlayColor;

out vec2 texCoord0;

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

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);

    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    rawVertexColor = Color;
    lightMapColor = sample_lightmap(Sampler2, UV2);
    overlayColor = texelFetch(Sampler1, UV1, 0);

    texCoord0 = UV0;
}
