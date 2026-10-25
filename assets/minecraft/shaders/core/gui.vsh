#version 330
#extension GL_ARB_separate_shader_objects : require

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:config.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;

layout(location = 0) out vec4 vertexColor;

const int remap_BR_TR_TL_BL[4] = int[4](3, 1, 0, 2);
const int remap_TL_BL_BR_TR[4] = int[4](0, 2, 3, 1);

void main() {
	vec4 tint = Color;

    int vertID = remap_BR_TR_TL_BL[gl_VertexIndex % 4];
	ivec4 ctrlV = ivec4(Color * 255 + 0.5);
	
	switch (int(Position.z)) {
	case 0:
		if (ctrlV.rgb == vec3(239, 50, 61)) { // --- RELOAD SCREEN --- 
			tint = vec4(Reload_Screen[vertID].rgb, Reload_Screen[vertID].a / 1.0 * Color.a);
		} else if (ctrlV.rgb == vec3(16) && // --- CONTAINER BACKGROUND --- 
			(Color.a == 0.81568626 && (vertID == 0 || vertID == 1)) || 
			(Color.a == 0.75294122 && (vertID == 2 || vertID == 3))) {
			vertID = remap_TL_BL_BR_TR[gl_VertexIndex % 4];
			tint = Inventory[vertID];
		} break;
	case 1800: 
		if (ctrlV == vec4(vec3(80), 144)) { // --- DEBUG MENU: F3 ---
			tint = Debug_Menu[vertID];
		} break;
	case 2600: 
		if (ctrlV.rgb == vec3(0) && ctrlV.a < 128) { // --- CHAT BOXES ---
			tint = vec4(Chat_Messages[vertID].rgb, Chat_Messages[vertID].a / 0.49803922 * Color.a);
		} break;
	}
		
	vertexColor = tint;
	gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
}
