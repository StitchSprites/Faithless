#version 150

#moj_import <fog.glsl>
#moj_import <dynamictransforms.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in float vertexDistance;
in vec4 vertexColor;
in vec4 tint;
in vec2 texCoord0;
flat in int Debug;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator * tint;
    if (color.a < 0.1) discard;
	
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
	
	fragColor = apply_fog(color, vertexDistance, vertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
