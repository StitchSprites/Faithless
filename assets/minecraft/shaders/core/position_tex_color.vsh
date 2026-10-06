#version 150

#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>
#moj_import <vertex_utils.glsl>
#moj_import <globals.glsl>
#moj_import <config.glsl>

in vec3 Position;
in vec2 UV0;
in vec4 Color;

uniform sampler2D Sampler0;

out vec2 texCoord0;
out vec4 vertexColor;
out vec3 skyDir;       // world-space direction for End Skybox cubic projection
out float isEndSky;    // 1.0 when drawing the End Sky

//[CONTAINER ANIMATIONS]: SPEED, SHEET_FRAMES, TOTAL_FRAMES

	const ivec3 ANIMATION_params[3] = ivec3[](
		ivec3(    0, 1,  1),
		ivec3(15000, 2,  3),	// STONECUTTER
		ivec3(10000, 2, 14)		// VILLAGER
	);	
	const int Stonecutter[3] = int[](0, 0, 1);
	const int Villager[14] = int[](0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0);
	
//[SPRITE METERS]: WIDTH, SHEET_FRAMES [EXPERIMENTAL]

	const vec2 METER_params[3] = vec2[](
		vec2( 0,  1),
		vec2(14, 13),	// SMELTING FUEL
		vec2(24, 24)	// SMELTING ARROW
	);

void main() {
    texCoord0 = UV0;
    vec3 pos = Position;
	mat4 MVM = ModelViewMat;

     // ── End Skybox detection ──────────────────────────────────────────────────
     // The End Sky texture is a 1x1 control pixel (10, 0, 10, 255),
	// we know this is the End Sky.
     vec4 ctrl1x1 = texture(Sampler0, vec2(0.5));
	float endSkyFlag = (textureSize(Sampler0, 0) == ivec2(1) &&
                         ctrl1x1.r > 0.02 && ctrl1x1.r < 0.08 &&
                         ctrl1x1.g < 0.02 &&
                         ctrl1x1.b > 0.02 && ctrl1x1.b < 0.08 &&
                         ctrl1x1.a > 0.9) ? 1.0 : 0.0;

     // Always initialised: the old switch left isEndSky undefined for any
     // End_Skybox value other than 1 or 2. 1 = procedural sky, anything else = off.
     isEndSky = (End_Skybox == 1) ? endSkyFlag : 0.0;

     skyDir = Position;

    int vertID = gl_VertexID % 4;
	ivec4 ctrlL = ivec4(texture(Sampler0, vec2(0)) * 255 + 0.5);
	
    switch (ctrlL.a) {
    case 2: //CONTAINERS
		texCoord0 = corners[vertID];
		pos.xy += (corners[vertID] - 0.5) * ctrlL.rg * 2;
		
		if (UV0.x == 0.0 || UV0.x == 0.6875) {
			if (UV0.y == 0.27734375 || UV0.y == 0.48828125) { 
				if (vertID == 2) pos.xy = vec2(0, 0);
			} else if (UV0.y == 0.4921875 || UV0.y == 0.8671875) {
				vec2 screenScale = ScreenSize / (ScreenSize.x * ProjMat[0][0] * 0.5);
				float size = Position.y - round(screenScale.y * 0.5) - 62.5;
				if (vertID == 0 || vertID == 3) { size += 96; pos.y -= 125; }
				texCoord0.x = (corners[vertID].x + int(size / 9)) / 6;
			}
		}
		
		ivec3 animParams = ANIMATION_params[ctrlL.b]; 
		int frameIndex = int(GameTime * animParams[0]) % animParams[2];
		
		switch (ctrlL.b) {
			case 1: frameIndex = Stonecutter[frameIndex]; break;
			case 2: frameIndex = Villager[frameIndex]; break;
		}
		
		texCoord0.y = (frameIndex + texCoord0.y) / animParams[1];
		break;

    default: //case 1: SPRITES
		ivec4 ctrlV = ivec4(texture(Sampler0, UV0 - 0.00001 * corners[vertID]) * 255.0 + 0.5);
		
        if (ctrlV.a == 1) {
            pos.xy += vec2(ctrlV.r - 128, 128 - ctrlV.g);
			
			vec2 meterParams = METER_params[ctrlV.b];
			int state = 1;
			if (vertID < 2) texCoord0.x += (1.0 / textureSize(Sampler0, 0).x) * (meterParams.x * (state - 1));
			if (vertID > 1) texCoord0.x -= (1.0 / textureSize(Sampler0, 0).x) * (meterParams.x * (meterParams.y - state));
        }
    }

    gl_Position = ProjMat * MVM * vec4(pos, 1.0);
    vertexColor = Color;
}
