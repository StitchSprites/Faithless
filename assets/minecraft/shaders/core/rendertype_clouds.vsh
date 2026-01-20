//#version 150
//
//#moj_import <fog.glsl>
//#moj_import <dynamictransforms.glsl>
//#moj_import <projection.glsl>
//#moj_import <config.glsl>
//
//in vec3 Position;
//in vec4 Color;
//
//out float vertexDistance;
//out vec4 vertexColor;
//
//void main() {
//    vec3 pos = Position + ModelOffset;
//	vec4 tint = Color;
//	ivec4 CtrlV = ivec4(Color * 255 + 0.5);
//	
//	if (!Layered_Clouds) { CtrlV.a = 255; tint.a = 0.5; }
//    if (Sunken_Clouds) pos.y += CtrlV.a * ColorModulator.r - 130;
//
//	if (Puffy_Clouds) {
//		tint = vec4(vec3(1.0), Color.r);
//		int vertID = gl_VertexID % 4;	
//		if (CtrlV.r == 255 || (CtrlV.r == 204 || CtrlV.r == 229) && (vertID == 1 || vertID == 2)) { 
//			pos.y += 8; 
//			tint.a = 0.0;
//		}	
//	}
//
//    vertexColor = tint * ColorModulator;
//    vertexDistance = fog_distance(pos, 1);
//    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
//}

#version 150

#moj_import <fog.glsl>
#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>
#moj_import <config.glsl>

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

out float vertexDistance;
out vec4 vertexColor;
	
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
    int quadVertex = gl_VertexID % 4;
    int index = (gl_VertexID / 4) * 3;

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

    float dist = length(pos.xz);
    pos.y -= (dist * dist) / 20000.0;

    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
    vertexDistance = fog_cylindrical_distance(pos);
}