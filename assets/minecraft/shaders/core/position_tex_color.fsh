#version 150

#moj_import <dynamictransforms.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in vec2 texCoord0;
in vec4 vertexColor;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor;
    if (color.a == 0.0) discard;
	
    fragColor = color * ColorModulator;
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
