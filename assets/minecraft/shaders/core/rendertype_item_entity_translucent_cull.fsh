#version 150

#moj_import <fog.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in float vertexDistance;
in vec4 vertexColor0;
in vec4 vertexColor1;
in vec4 lightMapColor;
in vec4 lightColor;
in vec2 texCoord0;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a == 0) discard; 
	
	vec4 tint = vertexColor0;
	vec4 shade = lightMapColor;
	
	ivec4 ctrlF = ivec4(color * 255.0 + 0.5);
	bool isSolid = true;
    
	switch (ctrlF.a) {
	case 255: break;
	case 254: break;
	case 250: if (Emissives) shade = vec4(1); tint = vertexColor1; break;
	case 1: discard;
	default: isSolid = false;
	}
	
	if (isSolid) color.a = 1;
	
	color *= tint * shade;
	
	fragColor = apply_fog(color, vertexDistance, vertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
