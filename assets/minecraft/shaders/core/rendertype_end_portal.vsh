#version 150

#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>

in vec3 Position;

out vec4 texProj0;

void main() {
    vec3 pos = Position + ModelOffset;	
	if (PORTAL_LAYERS == 15) pos.y -= 0.746;
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
    texProj0 = projection_from_position(gl_Position);
}
