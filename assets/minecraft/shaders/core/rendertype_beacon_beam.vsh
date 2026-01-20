#version 150

#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;

uniform mat3 IViewRotMat;

out vec4 vertexColor;
out vec2 texCoord0;
out float posY;

void main() {
    texCoord0 = UV0;
	
	int vertID = gl_VertexID % 4;
    if (vertID == 0 || vertID == 3) posY = 1024; else posY = 0; 
	
    vertexColor = Color;
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
}
