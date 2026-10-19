#version 330

#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;

out vec4 vertexColor;
out vec2 texCoord0;
out vec3 fragPos;

void main() {
    texCoord0 = UV0;
    // The 3D breaking effect needs the face normal, but 26.2 removed the Normal attribute from this program.
    // The position is handed to the fragment stage, which rebuilds the normal from its screen-space derivatives.
    fragPos = Position;

    vertexColor = Color;
    mat4 ProjViewMat = ProjMat * ModelViewMat;
    gl_Position = ProjViewMat * vec4(Position, 1.0);
}
