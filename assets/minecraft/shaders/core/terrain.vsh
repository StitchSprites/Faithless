#version 330

// 26.2 batched rendering: gl_VertexID now includes the draw's base vertex offset.
#extension GL_ARB_shader_draw_parameters : enable
#ifdef GL_ARB_shader_draw_parameters
    #define VERT_ID (gl_VertexID - gl_BaseVertexARB)
#else
    #define VERT_ID gl_VertexID
#endif

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:chunksection.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:sample_lightmap.glsl>
#moj_import <minecraft:vertex_utils.glsl>
#moj_import <config.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler2;
uniform sampler2D Sampler0;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexLight;
out vec4 vertexColor;
out vec2 texCoord0;
out float slopeUV;
out vec3 fragPos;
#if Chunk_Loading == 2
out vec3 facePos;
out vec3 relPos;
#endif

vec3 rendWave(vec3 chunkPos, float value) {
	float seed = (chunkPos.x * 256 + chunkPos.y * 16 + chunkPos.z) / (17 - chunkPos.z) * 5;
    float wave = (seed * 0.1 + GameTime * 4000.0) * 0.333;
    float offset = sin(wave) + sin(wave * 2.1) + sin(wave * 5.15);
    return offset * vec3(0.01, 0.008, 0.01) * value;
}

vec3 rendWind(vec3 chunkPos, float value) {
    float seed = chunkPos.x + chunkPos.z;
    vec2 wind = sin(vec2(0.05, 0.30) * seed + GameTime * vec2(1234.0, 3210.0));
    return vec3(wind.x * 0.2, 0, wind.y * 0.05) * value;
}

vec3 rendLiquid(vec3 chunkPos, float yPos, float value, inout vec4 tint) {
	float seed = (chunkPos.x * 256 + chunkPos.y * 16 + chunkPos.z) / (17 - chunkPos.z) * 5;
	float wave = 0.0;
	for (int i = 1; i <= 5; i++) {
		wave += sin(seed * i + GameTime * (6000.0 / i));
	}
	vec3 offset = wave * vec3(0.04, 0.06, 0.04) * fract(yPos);
	tint += offset.y * vec4(-0.7, 1.0, -0.4, 1.0);
    return offset * value;
}

vec3 rendWater(vec3 chunkPos, float yPos, float value, inout vec4 tint) {
    float seed = (chunkPos.x * 256 + chunkPos.y * 16 + chunkPos.z) / (17 - chunkPos.z) * 5;
    float wave = 0.0;
    for (int i = 1; i <= 5; i++) {
        wave += sin(seed * i + GameTime * (6000.0 / i));
    }
    float offsetY = wave * 0.03 * fract(yPos + 0.5);
    tint += offsetY * 2 * vec4(-0.7, 1.0, -0.4, 1.0);
    return vec3(0, offsetY * value, 0);
}

vec3 rendSwing(vec3 blockPos, float value) {
	vec3 rand = floor(Position);
    float theta = GameTime * 1600.0 + dot(rand, vec3(1.0));
    float sinX = sin(theta) * 0.1, sinZ = sin(theta * 1.618) * 0.1;
    float cosX = 1.0 - 0.5 * sinX * sinX, cosZ = 1.0 - 0.5 * sinZ * sinZ;
    blockPos.yz = vec2(cosX * blockPos.y - sinX * blockPos.z, sinX * blockPos.y + cosX * blockPos.z);
    blockPos.xy = vec2(cosZ * blockPos.x - sinZ * blockPos.y, sinZ * blockPos.x + cosZ * blockPos.y);
    return (-Position + blockPos + rand + 0.5) * value;
}

float rendBounce() {
    float t = fract(GameTime * 6000.0) * 2.0 - 1.0;
    return (t * t) * -0.008;
}

vec3 rendPulse(vec3 blockPos) {
    float t = fract(GameTime * 3000.0) * 2.0 - 1.0; 
    return blockPos * max(0.0, 1.0 - t * t) * 0.1;
}

vec3 rendOrbital(vec3 pos, vec3 blockPos) {
	pos -= blockPos;
	float theta = GameTime * 2500.0;
	float sinTheta = sin(theta), cosTheta = cos(theta);
	
	mat3 rot = mat3(
		vec3(1.0, 0.0, 0.0), 
		vec3(0.0, cosTheta, -sinTheta), 
		vec3(0.0, sinTheta, cosTheta)) *
		mat3(vec3(cosTheta, 0.0, sinTheta), vec3(0.0, 1.0, 0.0), vec3(-sinTheta, 0.0, cosTheta)) *
		mat3(vec3(cosTheta, -sinTheta, 0.0), vec3(sinTheta, cosTheta, 0.0), vec3(0.0, 0.0, 1.0));
	
	blockPos *= 1.0 + max(0.0, sin(GameTime * 20000.0) - 0.8) * 0.25;
	return pos + vec3(0.0, 0.07, 0.0) + blockPos * rot;
}

vec3 rendRotation(vec3 pos, vec3 blockPos) {
    pos -= blockPos;
    float theta = GameTime * 4000.0;
    float cosTheta = cos(theta), sinTheta = sin(theta);
    blockPos.xz = mat2(cosTheta, -sinTheta, sinTheta, cosTheta) * blockPos.xz;
    return pos + blockPos;
}

vec3 rendHeartbeat(vec3 blockPos) {
    vec3 t = fract(GameTime * vec3(200.0, 500.0, 1000.0)) * 1.0 - 0.5;
    vec3 pulse_vals = max(vec3(0.0), 0.5 - t * t);
    return blockPos * (pulse_vals.x + max(0.0, pulse_vals.y + pulse_vals.z - 0.8)) * 0.5;
}

vec3 slopes(vec3 pos, vec3 blockPos, int ctrl) {
	if (ctrl == 240 || ctrl == 239) {
		float slope_offset = clamp((1.0 - Color.r), 0.0, -blockPos.y + 0.5);
		pos.y += slope_offset;
		if (ctrl == 240) {
			// Snow texture shift is passed to terrain.fsh, which applies it on top faces only.
			float elevation = 0.5 - slope_offset - blockPos.y;
			slopeUV = elevation * 16.0 / textureSize(Sampler0, 0).y;
		}
	} else { pos.y -= blockPos.y + 0.5; }
    return pos;
}

vec3 grass_physics(vec3 pos, mat4 ModelViewMat) {
    if (pos.y < ModelViewMat[3].y + 0.8) {
        vec2 dist = vec2(length(pos.xz - ModelViewMat[3].xz), abs(pos.y - ModelViewMat[3].y));		
        float smoothFactor = max(0.0, 1.0 - (dist.x - 0.3) * 1.444) * max(0.0, 1.0 - (dist.y - 0.5) * 0.666);		
        pos.y = mix(pos.y, -1.5, smoothFactor);
        pos += normalize(vec3(ModelViewMat[2].x, 0.0, -ModelViewMat[2].z)) * smoothFactor;
    }
    return pos;
}

void main() {
    texCoord0 = UV0;
	slopeUV = 0.0;
	vec4 tint = Color;
	vec4 shade = sample_lightmap(Sampler2, UV2);
	
	mat4 ViewMat = Orthographic ? getOrthoMat(ProjMat, 0.007) : ProjMat;
	mat4 Camera = Orthographic ? getIsometricViewMat(ModelViewMat) : ModelViewMat;
	
	vec3 ModelOffset = (ChunkPosition - CameraBlockPos) + CameraOffset;
    vec3 pos = Position + ModelOffset;
	vec3 blockPos = fract(Position) - 0.5;
	vec3 absPos = vec3(abs(blockPos.x), (blockPos.y + 0.5), abs(blockPos.z)) * 16;
	vec3 chunkPos = mod(round(Position), 16) + 1;
    int vertID = VERT_ID % 4;

	sphericalVertexDistance = fog_spherical_distance(pos);
	cylindricalVertexDistance = fog_cylindrical_distance(pos);
	fragPos = pos;

    switch (Chunk_Loading) {
    case 1: pos.y += chunk_translate(ModelOffset, FogRenderDistanceEnd); break;
    }
#if Chunk_Loading == 2
	// Block Fade runs per pixel in terrain.fsh.
	facePos = Position;
	relPos = pos;
#endif
    	
	// Exact-texel control read; UVs on a sprite edge step inward (standard corner order), UVs inset in the model are read as-is.
	ivec2 atlasSize = textureSize(Sampler0, 0);
	vec2 texC = UV0 * vec2(atlasSize);
	vec2 edgeDist = abs(texC - round(texC));
	vec2 texS = texC + (0.5 - corners[vertID]) * 0.5 * step(edgeDist, vec2(0.02));
	ivec4 ctrlV = ivec4(texelFetch(Sampler0, clamp(ivec2(floor(texS)), ivec2(0), atlasSize - 1), 0) * 255.0 + 0.5);

	// Beacon gem/glow faces have flipped UVs, so the inward step can miss; their geometry is unique, so accept 251 from any adjacent texel.
	if (Block_Animations && ctrlV.a != 251 && (absPos.xz == vec2(4) && (absPos.y == 4 || absPos.y == 12) || absPos.xz == vec2(3.5) && (absPos.y == 4.5 || absPos.y == 11.5))) {
		ivec2 t0 = ivec2(round(texC));
		for (int i = 0; i < 4; i++) {
			ivec2 tc = clamp(t0 - ivec2(i & 1, i >> 1), ivec2(0), atlasSize - 1);
			if (int(texelFetch(Sampler0, tc, 0).a * 255.0 + 0.5) == 251) ctrlV.a = 251;
		}
	}

	switch (ctrlV.a) {
	case 255: case 0: break;
	case 254: if (Waving_Features) if (absPos == vec3(8,0,8)) {
				pos += rendWave(chunkPos, Waving_Foliage);									// Leaves & Azalea
			} else {
				pos += rendWave(chunkPos, Waving_Foliage * 0.25);							// Bamboo, Chorus & Dripleaf
			} break;
	case 253: if (Block_Animations) if (absPos.y == 0 || absPos.y == 0.5) { 				// Jukebox
				pos = rendRotation(pos, blockPos);
			} else if (absPos.y == 1 || absPos.y == 1.5 || absPos.y == 2.5 || absPos.y == 3) {
				pos.y += rendBounce() - 0.01;
			} else {
				pos += rendPulse(blockPos);
			} break;
	case 251: if (Emissives) { tint = vec4(1); shade = vec4(1); }							// full bright, see terrain.fsh
			if (Waving_Features && absPos.x >= 7 && absPos.z >= 7) { 
				pos += rendLiquid(chunkPos, blockPos.y, Waving_Lava, tint);				// LAVA & CAULDRON
			} else if (Block_Animations && (absPos.xz == vec2(4) && (absPos.y == 4 || absPos.y == 12) || absPos.xz == vec2(3.5) && (absPos.y == 4.5 || absPos.y == 11.5))) {
				pos = rendOrbital(pos, blockPos); break;								// BEACON
			} else if (Block_Animations) { 
				pos += rendHeartbeat(blockPos);											// CREAKING HEART
			} break;
	case 250: if (Emissives) { tint = vec4(1); shade = vec4(1); } break;					// EMISSIVES
	case 240: case 239: case 238: if (Dynamic_Slopes) pos = slopes(pos, blockPos, ctrlV.a); break; // Snow & Moss
	case 200: if (Waving_Features) pos += rendWater(chunkPos, blockPos.y, Waving_Water, tint); break; // WATER & CAULDRON
	case 191: if (Waving_Features) pos += rendWave(chunkPos, Waving_Objects); break;		// NETHER PORTAL
	case 181: if (Waving_Features && (absPos.xz == vec2(2) || absPos.xz == vec2(3))) {  // LANTERNS
				if (absPos.y == 1 || absPos.y == 8 || absPos.y == 10) pos += rendSwing(blockPos, Waving_Objects); 
			} else if (Block_Animations && (absPos.xz == vec2(4) && (absPos.y == 4 || absPos.y == 12))) {
				pos += rendSwing(blockPos, Waving_Objects);								// SLIME & HONEY
			} else if (Waving_Features) { 
				pos += rendWave(chunkPos, Waving_Objects);								// CHAINS & WEBS
			} break;
	case 143: if (Fencelogging && absPos == vec3(2, 0, 2)) {
				if (vertID == 0 || vertID == 3) pos.y += 0.5;							// FENCE POSTS
				else pos.y += -0.5;
			} else if (Fencelogging && (absPos == vec3(4, 0, 4) || absPos.xy == vec2(3, 0) || absPos.zy == vec2(3, 0))) {
				if (vertID == 0 || vertID == 3) pos.y += 0.5;							// WALLS
				else pos.y += -0.5;
			} else if (Windowlogging && (absPos.x == 1 || absPos.z == 1)) {
				if (vertID == 0 || vertID == 3) pos.y += 0.5;							// GLASS PANES & BARS
				else pos.y += -0.5;
			} break;
	case 25: // -=- (CUTOUTS) -=-  ----------------------------------------------------------------------------------------
		switch (ctrlV.r) {
		case 2: if (Waving_Features) pos += rendWave(chunkPos, Waving_Foliage * 0.5); break;	// VINES
		case 4: if (absPos.y > 3.5 || absPos.y == 0) {
					if (Waving_Features) pos += rendWind(chunkPos, Waving_Grass);				// GRASS, CROPS & FLOWERS
					if (Displacement) pos = grass_physics(pos, ModelViewMat); 
				} else {
					if (Waving_Features) pos += rendWind(chunkPos, Waving_Grass * 0.25);		// FLOWERBEDS & CLOVERS
				} break; 						
		case 5: if (Waving_Features) pos += rendWave(chunkPos, Waving_Fire); break; 			// FIRE & CAMPFIRE
		case 6: if (Waving_Features) pos += rendWave(chunkPos, Waving_Water * 1.5); 			// SEAGRASS, KELP & LILYPADS
				if (Displacement && absPos.y == 0 || absPos.y > 1) pos = grass_physics(pos, ModelViewMat); 
				break;
		case 10: if (Windowlogging && (absPos.x == 1 || absPos.z == 1)) {
					if (vertID == 0 || vertID == 3) pos.y += 0.5;
					else pos.y += -0.5;
				} break;
		} break;		
	case 3: { if (Waving_Features) if (absPos == vec3(8,0,8)) {
				pos += rendWave(chunkPos, Waving_Foliage);								// LEAVES & AZALEA
			} else {
				pos += rendWave(chunkPos, Waving_Foliage * 0.25);						// BAMBOO, CHORUS & DRIPLEAF
			}} break;
	case 2: break; //DISCARDED
	case 1: // -=- (TRANSLUCENTS) -=-  ------------------------------------------------------------------------------------
		switch (ctrlV.r) {
		case 1: if (Portal_Fog) {
					if (absPos.z > 7) pos.x += (blockPos.x == 0) ? -1.5 : 1.5;					// NETHER PORTAL FOG
					else pos.z += (blockPos.z == 0) ? -1.5 : 1.5;
				} break;
		case 2: if (Waving_Features) pos += rendWave(chunkPos, Waving_Objects); break; 			// TRIPWIRE
		} break;
	}
	
	vertexLight = shade;
	vertexColor = tint * shade;
	gl_Position = ViewMat * Camera * vec4(pos, 1.0);
}
