#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:config.glsl>

const int FLAG_MASK_DIR = 7;
const int FLAG_INSIDE_FACE = 1 << 4;
const int FLAG_USE_TOP_COLOR = 1 << 5;
const int FLAG_EXTRA_Z = 1 << 6;
const int FLAG_EXTRA_X = 1 << 7;

layout(std140) uniform CloudInfo {
    vec4 CloudColor;
    vec3 CloudOffset;
    vec3 CellSize;
};

uniform isamplerBuffer CloudFaces;

layout(location = 0) out float vertexDistance;
layout(location = 1) out vec4 vertexColor;
	
	//Bottom Top North South West East
const vec3[] vertices = vec3[](
    vec3(1, 0, 0), vec3(1, 0, 1), vec3(0, 0, 1), vec3(0, 0, 0),
    vec3(0, 1, 0), vec3(0, 1, 1), vec3(1, 1, 1), vec3(1, 1, 0),
    vec3(0, 0, 0), vec3(0, 1, 0), vec3(1, 1, 0), vec3(1, 0, 0),
    vec3(1, 0, 1), vec3(1, 1, 1), vec3(0, 1, 1), vec3(0, 0, 1),
    vec3(0, 0, 1), vec3(0, 1, 1), vec3(0, 1, 0), vec3(0, 0, 0),
    vec3(1, 0, 0), vec3(1, 1, 0), vec3(1, 1, 1), vec3(1, 0, 1)
);

const vec4[] faceColors = vec4[](
    vec4(1.0, 1.0, 1.0, 0.6),
    vec4(1.0, 1.0, 1.0, 0.0),
    vec4(1.0, 1.0, 1.0, 0.5),
    vec4(1.0, 1.0, 1.0, 0.5),
    vec4(1.0, 1.0, 1.0, 0.4),
    vec4(1.0, 1.0, 1.0, 0.4)
);

void main() {
    int quadVertex = gl_VertexIndex % 4;
    int index = (gl_VertexIndex / 4) * 3;

    int cellX = texelFetch(CloudFaces, index).r;
    int cellZ = texelFetch(CloudFaces, index + 1).r;
    int dirAndFlags = texelFetch(CloudFaces, index + 2).r;
    int direction = dirAndFlags & FLAG_MASK_DIR;
    cellX = (cellX << 1) | ((dirAndFlags & FLAG_EXTRA_X) >> 7);
    cellZ = (cellZ << 1) | ((dirAndFlags & FLAG_EXTRA_Z) >> 6);

    bool isInsideFace = (dirAndFlags & FLAG_INSIDE_FACE) == FLAG_INSIDE_FACE;
    bool useTopColor = (dirAndFlags & FLAG_USE_TOP_COLOR) == FLAG_USE_TOP_COLOR;
    vec3 faceVertex = vertices[(direction * 4) + (isInsideFace ? 3 - quadVertex : quadVertex)];
    vertexColor = (useTopColor ? faceColors[1] : faceColors[direction]) * CloudColor;

    if ((direction >= 2 && direction <= 5) && (quadVertex == 1 || quadVertex == 2)) {
        faceVertex.y += 8.0 / CellSize.y;
        vertexColor.a = 0.0;
    }

    vec3 pos = (faceVertex * CellSize) + (vec3(cellX, 0, cellZ) * CellSize) + CloudOffset;

    // Fade distance is measured like vanilla (spherical, before the curvature below is applied)
    vertexDistance = fog_spherical_distance(pos);

    float dist = length(pos.xz);
    pos.y -= (dist * dist) / 20000.0;

    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
}
