#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in vec4 vertexColor;
in vec4 rawVertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
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

	// 26.2 applies lightmap and overlay in this stage.
	vec4 tint = vertexColor;
	vec4 shade = lightMapColor;

	// Control alphas from the old item_entity_translucent_cull program.
	switch (ctrlF.a) {
	case 255: case 254: color.a = 1.0; break;												// solid
	case 250: if (Emissives) shade = vec4(1.0); tint = rawVertexColor; color.a = 1.0; break;	// emissive
	case 1: discard;
	}

	color *= tint * ColorModulator;
	color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
	color *= shade;

	fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
	// Only control codes go opaque; real translucency (stained glass) keeps its alpha even when ALPHA_CUTOUT is defined.
	if (ctrlF.a == 180 || ctrlF.a == 181) {
		fragColor.a = 1.0;
	}
}
