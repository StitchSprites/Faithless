#version 150

#moj_import <matrix.glsl>
#moj_import <frag_utils.glsl>
#moj_import <globals.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;

in vec4 texProj0;

out vec4 fragColor;

void main() {
    vec3 color = textureProj(Sampler0, texProj0).rgb * Endportal_Colors[0];
    for (int i = 0; i < PORTAL_LAYERS; i++) {
        color += textureProj(Sampler1, texProj0 * end_portal_layer(i + 1.0, GameTime)).rgb * Endportal_Colors[i];
    }
	
    fragColor = vec4(color, 1.0);
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
