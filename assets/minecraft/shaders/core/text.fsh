#version 330

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#moj_import <minecraft:fog.glsl>
#endif

#moj_import <dynamictransforms.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
in float sphericalVertexDistance;
in float cylindricalVertexDistance;
#endif

in vec4 vertexColor;
in vec4 tint;
in vec2 texCoord0;
flat in int Debug;

out vec4 fragColor;

void main() {
#ifdef IS_GRAYSCALE
    vec4 texColor = texture(Sampler0, texCoord0).rrrr;
#else
    vec4 texColor = texture(Sampler0, texCoord0);
#endif

#ifdef IS_SEE_THROUGH
    vec4 color = texColor * vertexColor * tint;
#else
    vec4 color = texColor * vertexColor * ColorModulator * tint;
#endif
    if (color.a < 0.1) discard;
	
#ifndef IS_GRAYSCALE
	if (Debug != 0) {
		
		ivec4 ctrlF = ivec4(color * 255.0 + 0.5);
		
		switch (ctrlF.a) {
			case 255: if (tint == debugMenu[5] || tint == debugMenu[6] || tint == debugMenu[7]) color = debugMenu[1]; break;
			case 254: if (tint == debugMenu[1] || tint == debugMenu[8] || tint == debugMenu[0]) color = debugMenu[2]; 
					  if (tint == debugMenu[10]) color = debugMenu[12]; break;
			case 253: if (tint == debugMenu[1] || tint == debugMenu[8] || tint == debugMenu[0]) color = debugMenu[3]; 
					  if (tint == debugMenu[10]) color = debugMenu[11]; break;
			case 252: if (tint == debugMenu[5] || tint == debugMenu[6] || tint == debugMenu[7]) color = debugMenu[3]; 
					  if (tint == debugMenu[10]) color = debugMenu[12]; break;
		}
		
		 if (tint == debugMenu[10] && Debug == 1) color += 0.1;
	}
#endif
	
#ifdef IS_SEE_THROUGH
	fragColor = color * ColorModulator;
#elif defined(IS_GUI)
	fragColor = color;
#else
	fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
#endif
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
