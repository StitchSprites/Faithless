#version 150

#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in vec2 UV0;

in vec4 vertexColor;
in vec2 texCoord0;
in vec2 texCoord2;
in vec3 offset;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < 0.1) discard;

    if (Destroy_Depth > 0 && color.a == 1) {
        float i;
        for (i = 1.0; i <= 16.0; i++) if (texture(Sampler0, texCoord0 + offset.xy * i).a != 1) break;

        if (i <= 16.0) color = (i <= 2.0) ? vec4(0.6, 0.6, 0.58, 1.0) : vec4(vec3(0.3 - i * 0.01), 1.0); 
        else color = vec4(vec3(0.5 - i * 0.01), 1.0); 
    }

    fragColor = color * vertexColor;
}