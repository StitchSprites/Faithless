#version 330
#extension GL_ARB_separate_shader_objects : require

layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    mat4 TextureMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
};
layout(std140) uniform Projection {
    mat4 ProjMat;
};
// Minecraft 26.3 ShaderC/SPIR-V uses Vulkan-style vertex built-in names.
// For quad-based GUI drawing, indices of each quad are consecutive groups of four.
#define VERT_ID gl_VertexIndex
layout(std140) uniform Globals {
    ivec3 CameraBlockPos;
    float GlintAlpha;
    vec3 CameraOffset;
    float GameTime;
    vec2 ScreenSize;
    int MenuBlurRadius;
    int UseRgss;
};

layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;
layout(location = 2) in vec4 Color;
uniform sampler2D Sampler0;
layout(location = 0) out vec2 texCoord0;
layout(location = 1) out vec4 vertexColor;
layout(location = 2) out vec3 skyDir;
layout(location = 3) out float isEndSky;
const vec2 corners[4] = vec2[4](vec2(0.0), vec2(0.0, 1.0), vec2(1.0), vec2(1.0, 0.0));

const int End_Skybox = 1;

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

     // The sky is a cube centred on the camera, so Position already IS the view
     // direction in world axes (+Y = up).
     skyDir = Position;
     // ─────────────────────────────────────────────────────────────────────────

    ivec4 ctrlL = ivec4(texture(Sampler0, vec2(0)) * 255 + 0.5);
    ivec2 sourceSize = textureSize(Sampler0, 0);
    bool faithlessContainerControl = (ctrlL.a == 2 && (
        (ctrlL.rgb == ivec3(0, 0, 0) && (
            sourceSize == ivec2(176, 166) || sourceSize == ivec2(192, 192) ||
            sourceSize == ivec2(230, 219) || sourceSize == ivec2(195, 136) ||
            sourceSize == ivec2(125, 75)  || sourceSize == ivec2(1056, 221) ||
            sourceSize == ivec2(176, 133) || sourceSize == ivec2(248, 166)
        )) ||
        (ctrlL.rgb == ivec3(76, 0, 0)  && sourceSize == ivec2(328, 166)) ||
        (ctrlL.rgb == ivec3(40, 45, 0) && sourceSize == ivec2(256, 256)) ||
        (ctrlL.rgb == ivec3(54, 45, 0) && sourceSize == ivec2(384, 256)) ||
        (ctrlL.rgb == ivec3(0, 0, 1)  && sourceSize == ivec2(176, 332))
    ));
    int vertID = VERT_ID % 4;

    // Faithless GUI containers are drawn by Minecraft with atlas UVs that
    // indicate their corner.  Minecraft 26.3 can batch GUI draws with base
    // vertex offsets, so gl_VertexIndex % 4 is NOT a local quad-corner ID.
    // Derive the rectangle corner from the actual UVs for control-alpha 2.
    if (faithlessContainerControl) {
        bool right = UV0.x > 0.001;
        bool bottom = UV0.y > 0.001;

        // The chest GUI is split into top and bottom source strips.  Both
        // edges of a strip may have nonzero V; recognize their atlas UVs.
        if (abs(UV0.y - 0.27734375) < 0.00001 ||
            abs(UV0.y - 0.49218750) < 0.00001) bottom = false;
        if (abs(UV0.y - 0.48828125) < 0.00001 ||
            abs(UV0.y - 0.86718750) < 0.00001) bottom = true;

        // corners[] has TL, BL, BR, TR winding.
        vertID = right ? (bottom ? 2 : 3) : (bottom ? 1 : 0);
    }

    switch (faithlessContainerControl ? 2 : 0) {
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
        // The three smelter fuel indicators encode (128,128,1,1) at their
        // left border; furnace/lit_progress also encodes it at the far right
        // of its 182x14 strip.  With 26.3 GUI batching, gl_VertexIndex % 4
        // is not reliably tied to a sprite's UV corner.  Probe the border
        // texels instead of using the draw's vertex ordering for this meter.
        vec2 fuelTexel = 1.0 / vec2(textureSize(Sampler0, 0));
        bool fuelMeterCorner = false;
        bool wideFuelRightCorner = false;
        for (int dx = -1; dx <= 1; dx += 2) {
            for (int dy = -1; dy <= 1; dy += 2) {
                vec2 inside = UV0 + vec2(float(dx), float(dy)) * fuelTexel * 0.25;
                ivec4 nearCode = ivec4(texture(Sampler0, inside) * 255.0 + 0.5);
                if (nearCode == ivec4(128, 128, 1, 1)) {
                    fuelMeterCorner = true;
                }
            }
        }
        if (fuelMeterCorner) {
            // On the wide furnace strip's right edge, exactly 182 pixels to
            // the left is the identical marker at its left edge.  On 14x14
            // smoker/blast-furnace flames there is no such matching marker.
            // Crop the *UV* span to one 14px-wide frame; keep all 13 frames
            // in the original PNG and retain Minecraft's normal burn clipping.
            for (int dy = -1; dy <= 1; dy += 2) {
                vec2 otherEdge = UV0 + vec2(-181.75, float(dy) * 0.25) * fuelTexel;
                ivec4 otherCode = ivec4(texture(Sampler0, otherEdge) * 255.0 + 0.5);
                if (otherCode == ivec4(128, 128, 1, 1)) {
                    wideFuelRightCorner = true;
                }
            }
        }
        if (wideFuelRightCorner) {
            texCoord0.x = UV0.x - 168.0 * fuelTexel.x;
        }
        // Restrict alpha-1 animation/meter controls to Faithless's actual
        // encoded marker colors. HUD sprites from other mods must pass through.
        bool faithlessSpriteControl = (ctrlV.a == 1 && (
            (ctrlV.b == 0 && ((ctrlV.g == 128 &&
                (ctrlV.r == 70 || ctrlV.r == 97 || ctrlV.r == 115 || ctrlV.r == 130)) ||
                (ctrlV.g == 100 && (ctrlV.r == 115 || ctrlV.r == 130)))) ||
            (ctrlV.b == 1 && ctrlV.r == 128 && ctrlV.g == 128) ||
            (ctrlV.b == 2 && ctrlV.r == 128 && (ctrlV.g == 127 || ctrlV.g == 129))
        ));

		
        // The fuel meter above is now independent of vertex IDs; do not
        // apply the old index-dependent cropping to those same vertices.
        if (faithlessSpriteControl && !fuelMeterCorner) {
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
