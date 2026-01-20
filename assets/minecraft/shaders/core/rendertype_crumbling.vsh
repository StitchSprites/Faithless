#version 150

#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>
#moj_import <config.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in vec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;

out vec4 vertexColor;
out vec2 texCoord0;
out vec2 texCoord2;
out vec3 offset;

void main() {
    texCoord0 = UV0, texCoord2 = UV2;

    if (Destroy_Depth > 0) {
        vec3 rNorm = normalize(Normal);
		mat3 mat;
        if (abs(rNorm.y) >= 0.9) mat = mat3(vec3(1, 0, 0), vec3(0, 0, -1), Normal);
        else mat = mat3(cross(Normal, vec3(0, 1, 0)), vec3(0, 1, 0), Normal);

        vec3 viewDir = normalize(Position * mat);
        offset = viewDir / -viewDir.z / textureSize(Sampler0, 0).x / 16.0 * Destroy_Depth;

        if (abs(rNorm.z) >= 0.9) offset.x *= -1;
        if (rNorm.y > -0.9) offset.y *= -1;
    }

    vertexColor = Color;
    mat4 ProjViewMat = ProjMat * ModelViewMat;
    gl_Position = ProjViewMat * vec4(Position, 1.0);
}