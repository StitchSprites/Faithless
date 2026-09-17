#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

void main() {
	vec4 color = texture(Sampler0, texCoord0);
#ifdef ALPHA_CUTOUT
	if (color.a < ALPHA_CUTOUT) {
		discard;
	}
#endif

	vec2 ctrlTextureSize = vec2(textureSize(Sampler0, 0));
	vec2 ctrlTexelCenter = (floor(texCoord0 * ctrlTextureSize) + 0.5) / ctrlTextureSize;
	ivec4 ctrlF = ivec4(textureLod(Sampler0, ctrlTexelCenter, 0) * 255.0 + 0.5);

	color *= vertexColor * ColorModulator;
	fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
#ifdef ALPHA_CUTOUT
	fragColor.a = 1.0;
#else
	if (ctrlF.a == 180 || ctrlF.a == 181) {
		fragColor.a = 1.0;
	}
#endif
}
