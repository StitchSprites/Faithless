#version 330

#moj_import <fog.glsl>
#moj_import <frag_utils.glsl>
#moj_import <globals.glsl>
#moj_import <chunksection.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in float sphericalVertexDistance;
in float cylindricalVertexDistance;
in float vertexDistance;
in vec4 vertexLight;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

// Unpack a premultiplied-alpha sample back to straight alpha.
// Transparent texels (alpha == 0) contribute zero color weight, so they
// cannot bleed their RGB into opaque neighbours during filtering.
vec4 unpremultiply(vec4 c) {
	return vec4(c.a > 0.0 ? c.rgb / c.a : vec3(0.0), c.a);
}

// Sample and immediately convert to premultiplied alpha so that blending
// across opaque/transparent borders is color-correct.
vec4 samplePremul(sampler2D s, vec2 uv, vec2 du, vec2 dv, float lod) {
	vec4 c = (lod < 0.0) ? textureGrad(s, uv, du, dv) : textureLod(s, uv, lod);
	c.rgb *= c.a;   // premultiply
	return c;
}

vec4 sampleNearest(sampler2D sampler, vec2 uv, vec2 pixelSize, vec2 du, vec2 dv, vec2 texelScreenSize) {
	// Convert our UV back up to texel coordinates and find out how far over we are from the center of each pixel
	vec2 uvTexelCoords = uv / pixelSize;
	vec2 texelCenter = round(uvTexelCoords) - 0.5f;
	vec2 texelOffset = uvTexelCoords - texelCenter;

	// Move our offset closer to the texel center based on texel size on screen
	texelOffset = (texelOffset - 0.5f) * pixelSize / texelScreenSize + 0.5f;
	texelOffset = clamp(texelOffset, 0.0f, 1.0f);

	uv = (texelCenter + texelOffset) * pixelSize;
	// Sample in premultiplied space then unpack — transparent texels carry no color.
	return unpremultiply(samplePremul(sampler, uv, du, dv, -1.0));
}

vec4 sampleNearest(sampler2D source, vec2 uv, vec2 pixelSize) {
	vec2 du = dFdx(uv);
	vec2 dv = dFdy(uv);
	vec2 texelScreenSize = sqrt(du * du + dv * dv);
	return sampleNearest(source, uv, pixelSize, du, dv, texelScreenSize);
}

vec4 sampleRGSS(sampler2D source, vec2 uv, vec2 pixelSize) {
	vec2 du = dFdx(uv);
	vec2 dv = dFdy(uv);

	vec2 texelScreenSize = sqrt(du * du + dv * dv);
	float maxTexelSize = max(texelScreenSize.x, texelScreenSize.y);

	float minPixelSize = min(pixelSize.x, pixelSize.y);

	float transitionStart = minPixelSize * 1.0;
	float transitionEnd = minPixelSize * 2.0;
	float blendFactor = smoothstep(transitionStart, transitionEnd, maxTexelSize);

	float duLength = length(du);
	float dvLength = length(dv);
	float minDerivative = min(duLength, dvLength);
	float maxDerivative = max(duLength, dvLength);

	float effectiveDerivative = sqrt(minDerivative * maxDerivative);

	float mipLevelExact = max(0.0, log2(effectiveDerivative / minPixelSize));

	float mipLevelLow = floor(mipLevelExact);
	float mipLevelHigh = mipLevelLow + 1.0;
	float mipBlend = fract(mipLevelExact);

	const vec2 offsets[4] = vec2[](
	vec2(0.125, 0.375),
	vec2(-0.125, -0.375),
	vec2(0.375, -0.125),
	vec2(-0.375, 0.125)
	);

	// Accumulate in premultiplied-alpha space so transparent samples
	// carry zero color weight — this eliminates the fringe/outline artefact.
	vec4 rgssColorLow = vec4(0.0);
	vec4 rgssColorHigh = vec4(0.0);
	for (int i = 0; i < 4; ++i) {
		vec2 sampleUV = uv + offsets[i] * pixelSize;
		rgssColorLow  += samplePremul(source, sampleUV, du, dv, mipLevelLow);
		rgssColorHigh += samplePremul(source, sampleUV, du, dv, mipLevelHigh);
	}
	rgssColorLow  = unpremultiply(rgssColorLow  * 0.25);
	rgssColorHigh = unpremultiply(rgssColorHigh * 0.25);

	vec4 rgssColor = mix(rgssColorLow, rgssColorHigh, mipBlend);

	vec4 nearestColor = sampleNearest(source, uv, pixelSize, du, dv, texelScreenSize);

	return mix(nearestColor, rgssColor, blendFactor);
}

void main() {
	vec4 color = (UseRgss == 1 ? sampleRGSS(Sampler0, texCoord0, 1.0f / TextureSize) : sampleNearest(Sampler0, texCoord0, 1.0f / TextureSize)) * vertexColor;
	if (color.a == 0.0) discard;

	// Snap to the nearest texel centre before reading the control alpha so that
	// bilinear interpolation across an opaque/transparent border cannot produce
	// a blended alpha value that accidentally hits one of the discard cases
	// (1, 2, 3, 25) and carves dark outline holes into alpha-cutout geometry.
	vec2 ctrlPixelSize = 1.0f / TextureSize;
	vec2 ctrlTexelCoords = texCoord0 / ctrlPixelSize;
	vec2 ctrlTexelCenter = (round(ctrlTexelCoords - 0.5) + 0.5) * ctrlPixelSize;
	ivec4 ctrlF = ivec4(textureLod(Sampler0, ctrlTexelCenter, 0) * 255.0 + 0.5);

	// Recover the texture color before the lightmap was applied, so emissive
	// blocks can be shown at full brightness regardless of ambient light level.
	// vertexColor = Color * lightmap, vertexLight = lightmap, so dividing out
	// vertexLight gives us Color * rawTexture without the lightmap darkening.
	vec4 emissiveColor = vec4(all(greaterThan(vertexLight.rgb, vec3(0.0))) ? color.rgb / vertexLight.rgb : color.rgb, color.a);

	switch (ctrlF.a) {
		// Emissive cases: restore full-brightness colour before fog so the
		// lightmap darkening and ChunkVisibility don't suppress the glow.
		case 251: if (Emissives) color = vec4(emissiveColor.rgb, 1.0); break;
		case 250: if (Emissives) color = vec4(emissiveColor.rgb * vertexColor.rgb, 1.0); break;
		case 249: if (Emissives) color = vec4(emissiveColor.rgb, 1.0); break;
		case 25: case 3: case 2: case 1: discard;
		default:
		// Apply ChunkVisibility fog only for non-emissive blocks so that the End's
		// void fog doesn't replace distant block colours with solid black.
		color = mix(FogColor * vec4(1, 1, 1, color.a), color, ChunkVisibility);
		break;
	}
	if (ctrlF.a == 180 || ctrlF.a == 181) {
		color.a = 1.0;
	}
	#ifdef ALPHA_CUTOUT
	if (color.a < ALPHA_CUTOUT) {
		discard;
	}
	color.a = 1.0;
	#endif
	fragColor = color; //apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
