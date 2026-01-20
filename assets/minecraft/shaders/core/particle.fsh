#version 150

#moj_import <fog.glsl>
#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec2 texCoord0;

in vec3 cubePos;

in vec4 UV;
in vec3 glPos;
in vec2 inUV;
in float size;
flat in vec2 face;

out vec4 fragColor;

void main() {
    vec4 color;
	
	if (Cubic_Particles && cubePos.z != 0) {
		vec3 glp = normalize(-glPos);
		vec3 com1 = -(1.0 / glp) * cubePos, com2 = size / abs(glp);
		vec3 t1 = com1 - com2, t2 = com1 + com2;
		
		float rayN = max(max(t1.x, t1.y), t1.z);
		if (rayN > min(min(t2.x, t2.y), t2.z)) discard;
		
		vec3 NORM = -sign(glp) * step(t1.yzx, t1) * step(t1.zxy, t1);
		
		vec3 remapPos = (cubePos + glp * rayN) * 4 + 0.5;
		vec3 tex = vec3(abs(NORM.x) != 1 ? (abs(NORM.y) != 1 ? remapPos.xy : remapPos.xz) : remapPos.zy, rayN);
		
		vec2 divisor = (face.x == 0) ? vec2(1 - inUV.x, inUV.y) : vec2(1 - inUV.y, inUV.x);
		vec4 iUV = round(vec4(UV.xy / divisor.x, UV.zw / divisor.y));		
		color = texture(Sampler0, (min(iUV.xy, iUV.zw) + abs(iUV.xy - iUV.zw) * tex.xy) / textureSize(Sampler0, 0));
		if (color.a < 0.1) discard; 
		color.rgb *= dot(NORM, vec3(0.2, -1.0, 0.4)) * 0.5 + 1.0;
		
		vec4 depthPos = ProjMat * ModelViewMat * vec4(-glp * tex.z, 1.0);
		gl_FragDepth = depthPos.z / depthPos.w * 0.5 + 0.5;
	} else {
		color = texture(Sampler0, texCoord0);
		if (color.a < 0.1) discard; 
		gl_FragDepth = gl_FragCoord.z;
	}
	
	ivec4 ctrlF = ivec4(textureLod(Sampler0, texCoord0, 0) * 255.0);
	
	switch (ctrlF.a) {
	case 250: if (Emissives) color *= vertexColor; break;
	default: color *= vertexColor * lightMapColor; break;
	}
	
	
	fragColor = apply_fog(color, vertexDistance, vertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
