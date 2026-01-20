#version 150

#moj_import <fog.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in float vertexDistance;
in vec4 vertexLight;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a == 0.0) discard;
	
	ivec4 ctrlF = ivec4(textureLod(Sampler0, texCoord0, 0) * 255.0 + 0.5);
	
	switch (ctrlF.a) {
	case 251: if (Emissives) color = mix(color, vec4(color.rgb, 1.0), color.a); break;
	case 250: if (Emissives) color = mix(color, vec4(color.rgb, 1.0), color.a); color *= vertexColor; break;
	case 249: if (Emissives) color = mix(color, vec4(color.rgb, 1.0), color.a); break;
	case 25: case 3: case 2: case 1: discard;
	default: 
		color *= vertexColor;
		
		//vec3 dotLuminance = vertexLight.rgb * vec3(0.114, 0.299, 0.587);
		//float luminance = dotLuminance.r + dotLuminance.g + dotLuminance.b;
		//vec3 dotBrightness = color.rgb * vec3(0.299, 0.587, 0.114);
		//float brightness = (dotBrightness.r + dotBrightness.g + dotBrightness.b);
		//
		//float lightFactor = mix(1.2, 0.0, smoothstep(0.0, 3.5, vertexDistance)) * (1.0 - luminance) + 1.2;
		//
		//color.rgb = mix(vec3(brightness * 0.5), color.rgb, luminance) * lightFactor;
		
		color *= vertexLight;
		break;
	}

	fragColor = color;
	//fragColor = apply_fog(color, vertexDistance, vertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}