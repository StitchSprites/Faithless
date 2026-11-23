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

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 0) out vec4 vertexColor;
const vec4 Reload_Screen[4] = vec4[4](
			vec4(127, 51, 26, 200) * (0.00392), vec4(76, 26, 26, 200) * (0.00392),
			vec4( 76, 26, 26, 200) * (0.00392), vec4( 0,  0,  0, 200) * (0.00392)
		);

		const vec4 Inventory[4] = vec4[4](
			vec4(0, 0, 0, 0) * (0.00392), vec4(0, 0, 0, 200) * (0.00392),
			vec4(0, 0, 0, 0) * (0.00392), vec4(0, 0, 0, 200) * (0.00392)
		);

		const vec4 Debug_Menu[4] = vec4[4](
			vec4(0, 0, 0, 220) * (0.00392), vec4(0, 0, 0, 220) * (0.00392),
			vec4(0, 0, 0, 190) * (0.00392), vec4(0, 0, 0, 190) * (0.00392)
		);

		const vec4 Chat_Messages[4] = vec4[4](
			vec4(0, 0, 0, 255) * (0.00392), vec4(0, 0, 0, 0) * (0.00392),
			vec4(0, 0, 0, 255) * (0.00392), vec4(0, 0, 0, 0) * (0.00392)
		);


const int remap_BR_TR_TL_BL[4] = int[4](3, 1, 0, 2);
const int remap_TL_BL_BR_TR[4] = int[4](0, 2, 3, 1);

void main() {
	vec4 tint = Color;
	vec3 pos = (ProjMat * vec4(Position, 1.0)).xyz;
	
    int vertID = remap_BR_TR_TL_BL[VERT_ID % 4];
	ivec4 ctrlV = ivec4(Color * 255 + 0.5);
	
	switch (int(Position.z)) {
	case 0:
		if (ctrlV.rgb == ivec3(239, 50, 61)) { // --- RELOAD SCREEN --- 
			tint = vec4(Reload_Screen[vertID].rgb, Reload_Screen[vertID].a / 1.0 * Color.a);
		} else if (ctrlV.rgb == ivec3(16) && // --- CONTAINER BACKGROUND ---
            (ctrlV.a == 208 || ctrlV.a == 192)) {
            // Use one alpha across all four corners, independent of the
            // current batched draw index. Original array indexed vertices,
            // making the overlay switch opacity when GUI batches changed.
            tint = vec4(0.0, 0.0, 0.0, 0.55);
		} break;
	case 1800: 
		if (ctrlV == ivec4(80, 80, 80, 144)) { // --- DEBUG MENU: F3 ---
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
