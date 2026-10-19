#version 150

#moj_import <frag_utils.glsl>
#moj_import <config.glsl>
#moj_import <fog.glsl>

in vec2 texCoord0;
in float vertexDistance;
in vec4 vertexColor;

out vec4 fragColor;

void main() {
	vec4 color = vertexColor;
	// distance fade, same as vanilla: clouds fade out towards FogCloudsEnd
	color.a *= 1.0 - linear_fog_value(vertexDistance, 0.0, FogCloudsEnd);
	fragColor = vec4(cone_filter(Colorblindness, color.rgb), color.a);
}
