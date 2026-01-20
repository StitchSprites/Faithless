#version 150

#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>
#moj_import <light.glsl>
#moj_import <fog.glsl>
#moj_import <vertex_utils.glsl>
#moj_import <config.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

out float vertexDistance;
out vec2 texCoord0;
out vec4 vertexColor;
out vec4 lightMapColor;

out vec3 cubePos;

out vec4 UV;
out vec3 glPos;
out vec2 uv1, uv2, inUV;
out float size;
flat out vec2 face;

void main() {
    texCoord0 = UV0;
	vec4 tint = Color;
	vec4 shade = texelFetch(Sampler2, UV2 / 16, 0);
	
	int vertID = gl_VertexID % 4;
	vec3 pos = Position;
	cubePos = vec3(0);
	vec2 quadSize = vec2(0);
	
	ivec4 ctrlV = ivec4(texture(Sampler0, UV0 + (corners[vertID] - 0.5) * 0.001) * 255 + 0.5);
	ivec4 ctrlT = ivec4(tint * 255 + 0.5);
	
	if (ctrlV.a == 2) { 
		int texture = 0;
			 if (ctrlT.rgb == vec3(128, 167, 85)) texture = 1; //Birch
		else if (ctrlT.rgb == vec3( 97, 153, 97)) texture = 2; //Spruce
		else if (ctrlT.rgb == vec3(112, 146, 45)) texture = 3; //Azalea		
		if (texture != 0) tint.rgb = vec3(1);
		
		if (vertID > 1) texCoord0.x += (1.0 / textureSize(Sampler0, 0).x) * (5 * (texture));
		if (vertID < 2) texCoord0.x -= (1.0 / textureSize(Sampler0, 0).x) * (5 * (3 - texture));
	} 
	
	if (Cubic_Particles) {
		vec2 texSize = textureSize(Sampler0, 0);
		vec2 texUV = UV0 * texSize;
		size = 0;
		float scale = 1.5;
		
		if (floor(texUV) != texUV && texSize.y / texSize.x != 4) { size = 3; pos.y += 0.0625; }
		else if (ctrlV.a == 1) {
			switch (ctrlV.r) {
			case 255: case 254: case 253: case 252: 
				size = 256 - ctrlV.r; break;
			case 251: { // -=- GENERIC -=-
				if (ctrlT.r == ctrlT.g && ctrlT.g == ctrlT.b) {
					if (Between(ctrlT.r, 177, 255)) size = 3;	//Death Puffs
					if (ctrlT.r < 77) size = 2;	//Smoke 
				} else {
					if (Between(ctrlT.r, 61, 244) && ctrlT.g < 49 && ctrlT.b == 0)	//Redstone Wire
						{ size = 2; tint.rgb = vec3(1,0,0); }
					if (Between(ctrlT.r, 134, 186) && Between(ctrlT.g, 125, 177) && Between(ctrlT.b, 142, 194)) //Decorated Pot 
						{ size = 3; scale = 1; }
				}} break;
			case 250: size = 2; scale = 1.4; break;
			case 249: size = 3; scale = 1.1; pos.y -= 0.03125; break;
			case 248: size = 2; scale = 1.4; tint.rgb = vec3(1); break;
			case 247: size = 3; scale = 1.1; tint.rgb = vec3(1); pos.y -= 0.03125; break;
			}
		}
		
		if (size != 0) {
			cubePos = pos;
			quadSize = (corners[vertID] - 0.5) * vec2(0.1, -0.1) * size;
			size = 1.0 / pow(2, 7 - size);
			glPos = pos - (vec4(quadSize * scale, 0, 0) * ModelViewMat).xyz;
			UV = vec4((vertID == 0) ? texUV : vec2(0), (vertID == 2) ? texUV : vec2(0));
			face = inUV = corners[vertID];
		}
	}

	vertexColor = tint;
	lightMapColor = shade;
    vertexDistance = fog_cylindrical_distance(Position);
	gl_Position = ProjMat * (ModelViewMat * vec4(pos, 1.0) - vec4(quadSize, 0, 0));
}