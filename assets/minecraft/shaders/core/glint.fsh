#version 150

#moj_import <fog.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in vec2 texCoord0;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a == 0.0) discard;
		
    fragColor = color;
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
