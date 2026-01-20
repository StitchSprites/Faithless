#version 150

#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

in vec4 vertexColor;

out vec4 fragColor;

void main() {
	fragColor = vertexColor;
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
