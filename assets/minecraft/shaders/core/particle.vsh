#version 330

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:sample_lightmap.glsl>
#moj_import <config.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec2 texCoord0;
out vec4 vertexColor;
out vec4 lightMapColor;

out vec3 cubePos;
out vec4 UV;
out vec3 glPos;
out vec2 inUV;
out float size;
flat out vec2 face;

const vec2 corners[4] = vec2[4](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));

bool between(float v, float minValue, float maxValue) {
    return minValue < v && v < maxValue;
}

void main() {
    texCoord0 = UV0;
    vec4 tint = Color;
    vec4 shade = sample_lightmap(Sampler2, UV2);

    int vertID = gl_VertexID % 4;
    vec3 pos = Position;
    cubePos = vec3(0.0);
    vec2 quadSize = vec2(0.0);

    ivec4 ctrlV = ivec4(texture(Sampler0, UV0 + (corners[vertID] - 0.5) * 0.001) * 255.0 + 0.5);
    ivec4 ctrlT = ivec4(tint * 255.0 + 0.5);

    if (ctrlV.a == 2) {
        int textureIndex = 0;
        if (ctrlT.rgb == ivec3(128, 167, 85)) {
            textureIndex = 1;
        } else if (ctrlT.rgb == ivec3(97, 153, 97)) {
            textureIndex = 2;
        } else if (ctrlT.rgb == ivec3(112, 146, 45)) {
            textureIndex = 3;
        }
        if (textureIndex != 0) {
            tint.rgb = vec3(1.0);
        }

        if (vertID > 1) {
            texCoord0.x += (1.0 / float(textureSize(Sampler0, 0).x)) * float(5 * textureIndex);
        }
        if (vertID < 2) {
            texCoord0.x -= (1.0 / float(textureSize(Sampler0, 0).x)) * float(5 * (3 - textureIndex));
        }
    }

    if (Cubic_Particles) {
        vec2 texSize = vec2(textureSize(Sampler0, 0));
        vec2 texUV = UV0 * texSize;
        size = 0.0;
        float scale = 1.5;

        if (floor(texUV) != texUV && texSize.y / texSize.x != 4.0) {
            size = 3.0;
            pos.y += 0.0625;
        } else if (ctrlV.a == 1) {
            switch (ctrlV.r) {
            case 255:
            case 254:
            case 253:
            case 252:
                size = float(256 - ctrlV.r);
                break;
            case 251:
                if (ctrlT.r == ctrlT.g && ctrlT.g == ctrlT.b) {
                    if (between(float(ctrlT.r), 177.0, 255.0)) {
                        size = 3.0;
                    }
                    if (ctrlT.r < 77) {
                        size = 2.0;
                    }
                } else {
                    if (between(float(ctrlT.r), 61.0, 244.0) && ctrlT.g < 49 && ctrlT.b == 0) {
                        size = 2.0;
                        tint.rgb = vec3(1.0, 0.0, 0.0);
                    }
                    if (between(float(ctrlT.r), 134.0, 186.0) && between(float(ctrlT.g), 125.0, 177.0) && between(float(ctrlT.b), 142.0, 194.0)) {
                        size = 3.0;
                        scale = 1.0;
                    }
                }
                break;
            case 250:
                size = 2.0;
                scale = 1.4;
                break;
            case 249:
                size = 3.0;
                scale = 1.1;
                pos.y -= 0.03125;
                break;
            case 248:
                size = 2.0;
                scale = 1.4;
                tint.rgb = vec3(1.0);
                break;
            case 247:
                size = 3.0;
                scale = 1.1;
                tint.rgb = vec3(1.0);
                pos.y -= 0.03125;
                break;
            }
        }

        if (size != 0.0) {
            cubePos = pos;
            quadSize = (corners[vertID] - 0.5) * vec2(0.1, -0.1) * size;
            size = 1.0 / pow(2.0, 7.0 - size);
            glPos = pos - (vec4(quadSize * scale, 0.0, 0.0) * ModelViewMat).xyz;
            UV = vec4((vertID == 0) ? texUV : vec2(0.0), (vertID == 2) ? texUV : vec2(0.0));
            face = inUV = corners[vertID];
        }
    } else {
        size = 0.0;
        UV = vec4(0.0);
        glPos = vec3(0.0);
        inUV = vec2(0.0);
        face = vec2(0.0);
    }

    vertexColor = tint;
    lightMapColor = shade;
    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    gl_Position = ProjMat * (ModelViewMat * vec4(pos, 1.0) - vec4(quadSize, 0.0, 0.0));
}
