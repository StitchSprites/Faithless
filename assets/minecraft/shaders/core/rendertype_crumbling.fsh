#version 330

#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in vec4 vertexColor;
in vec2 texCoord0;
in vec3 fragPos;

out vec4 fragColor;

void main() {
    // Face normal from the slope of the position across the screen (no Normal attribute in 26.2).
    // Taken before any branch or discard so the derivatives stay well-defined.
    vec3 faceN = cross(dFdx(fragPos), dFdy(fragPos));

    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < 0.1) discard;

    if (Destroy_Depth > 0 && color.a == 1) {
        vec3 Normal = normalize(faceN);
        if (dot(Normal, fragPos) > 0.0) Normal = -Normal;   // point it back toward the camera (outward for visible faces)

        // Parallax offset: exactly the maths the vertex stage used to do with the real Normal
        mat3 mat;
        if (abs(Normal.y) >= 0.9) mat = mat3(vec3(1, 0, 0), vec3(0, 0, -1), Normal);
        else mat = mat3(cross(Normal, vec3(0, 1, 0)), vec3(0, 1, 0), Normal);

        vec3 viewDir = normalize(fragPos * mat);
        vec3 offset = viewDir / -viewDir.z / textureSize(Sampler0, 0).x / 16.0 * Destroy_Depth;

        if (abs(Normal.z) >= 0.9) offset.x *= -1;
        if (Normal.y > -0.9) offset.y *= -1;

        float i;
        for (i = 1.0; i <= 16.0; i++) if (texture(Sampler0, texCoord0 + offset.xy * i).a != 1) break;

        if (i <= 16.0) color = (i <= 2.0) ? vec4(0.6, 0.6, 0.58, 1.0) : vec4(vec3(0.3 - i * 0.01), 1.0); 
        else color = vec4(vec3(0.5 - i * 0.01), 1.0); 
    }

    fragColor = color * vertexColor;
}
