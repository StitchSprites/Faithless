#version 150

#moj_import <fog.glsl>
#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>
#moj_import <matrix.glsl>
#moj_import <globals.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in float vertexDistance;
in vec4 vertexColor0;
in vec4 vertexColor1;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;
in vec4 texProj0;
in vec3 screenPos;

out vec4 fragColor;

void main() {	
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a == 0.0) discard;
	
#ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
#endif
	
	vec4 tint = vertexColor0;
	vec4 shade = lightMapColor;
	ivec4 ctrlF = ivec4(color * 255.0 + 0.5);
    
	switch (ctrlF.a) {
	case 255: break;
	case 251: if (Ender_Chest) {
			vec2 screenSize = gl_FragCoord.xy / (screenPos.xy / screenPos.z * 0.5 + 0.5);
			color.rgb = render_endParallax(Endportal_Colors[0], gl_FragCoord.xy, screenSize, GameTime);
		} break;
	case 250: if (Emissives) shade = vec4(1); tint = vertexColor1; break;
	case 2: case 1: discard; break;
	}
	
	color *= tint * shade;
	fragColor = color;
    //fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}