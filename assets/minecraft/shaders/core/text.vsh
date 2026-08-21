#version 150

#moj_import <fog.glsl>
#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>
#moj_import <vertex_utils.glsl>
#moj_import <config.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

out float vertexDistance;
out vec4 vertexColor;
out vec4 tint;
out vec2 texCoord0;
flat out int Debug;

const ivec2 debug_lines[26] = ivec2[](
	ivec2(8, 0), ivec2(9, 9), ivec2(1, 9), ivec2(1, 9), ivec2(1, 9),
	ivec2(1, 9), ivec2(1, 9), ivec2(1, 9), ivec2(1, 9), ivec2(1, 9),
	ivec2(7, 9), ivec2(1, 8), ivec2(1, 10), ivec2(1, 10), ivec2(8, 10),
	ivec2(1, 10), ivec2(1, 10), ivec2(8, 10), ivec2(8, 10), ivec2(1, 10),
	ivec2(1, 10), ivec2(1, 10), ivec2(1, 10), ivec2(1, 10), ivec2(1, 10), ivec2(1, 10)
);

const int debug_padding[26] = int[](
	160, 232, 202, 206, 69,
	63, 170, 210, 103, 0,
	337, 142, 197, 217, 141,
	102, 132, 173, 162, 429,
	429, 235, 337, 337, 337, 90
);

void main() {
    texCoord0 = UV0;
    tint = vec4(1.0);
    vec4 color = Color;
	vec3 pos = Position;
	Debug = 0;

    int vertID = gl_VertexID % 4;
	ivec3 ctrlT = ivec3(color.rgb * 255 + 0.5);
    ivec4 ctrlV = ivec4(texture(Sampler0, UV0 - 0.00001 * corners[vertID]) * 255.0 + 0.5);
	bool isGRAYSCALE = (ctrlT.r == ctrlT.g) && (ctrlT.g == ctrlT.b);
	
	if (ctrlV.a == 1) {
		if (isGRAYSCALE && int(Position.z) == 0 && ctrlT.r == 64) {
			pos.xy += vec2(ctrlV.r - 128, 128 - ctrlV.g);
			color = vec4(1.0);
		} else { pos = vec3(0); }
	} else {
	
		switch (int(Position.z)) {
		case 0: 
			if (isGRAYSCALE) { switch (ctrlT.r) {
				case 255:	tint = buttons[0]; break;
				case 224:	tint = beacon[0]; break;
				case 170:	tint = cmd_n_packInfo[0]; break;
				case 160:	tint = disabledButtons[0]; break;
				case 128:	tint = worldInfo[0]; break;
				case 64:	tint = inventory[0]; break;
				case 63:	tint = buttons[1]; break;
				case 56:	tint = beacon[1]; break;
				case 42:	tint = cmd_n_packInfo[1]; break;
				case 40:	tint = disabledButtons[1]; break;
				case 32:	tint = worldInfo[1]; break;
			}} else {
				if (ctrlT.r == 255) {
						if (ctrlT.gb == ivec2(255, 0))	tint = splash[0];
					else if (ctrlT.gb == ivec2(96, 96)) tint = anvilExpLow[0];
					else if (ctrlT.gb == ivec2(85, 85)) tint = cmdError[0];
				} else if (ctrlT.r == 63) {
						if (ctrlT.gb == ivec2(63, 0))	tint = splash[1];
					else if (ctrlT.gb == ivec2(24, 24)) tint = anvilExpLow[1];
					else if (ctrlT.gb == ivec2(21, 21)) tint = cmdError[1];
				} 
				else if (ctrlT == ivec3(128, 255, 32))  tint = anvilExp[0];
				else if (ctrlT == ivec3(32, 63, 8))     tint = anvilExp[1];
			} break;
		case 200: 
			if (isGRAYSCALE) { switch (ctrlT.r) {
				case 170:	tint = cmdFill[0]; break;
				case 42:	tint = cmdFill[1]; break;
			}} else {
				if (ctrlT == vec3(255, 255, 0))	tint = cmdSelect[0];
				if (ctrlT == vec3(63, 63, 0))	tint = cmdSelect[1];
			} break;
		case 400: 
			if (isGRAYSCALE) { switch (ctrlT.r) {
				case 255:	tint = tooltip[0]; break;
				case 63:	tint = tooltip[1]; break;
			}} break;
		case 600: 
			if (isGRAYSCALE) {
				if (ctrlT.r == 0)	tint = experience[1];
			} else {
				if (ctrlT == ivec3(128, 255, 32))	tint = experience[0];
			} break;
		case 1800: 
			if (isGRAYSCALE) {
				if (ctrlT.r == 224)	{
					
					int offsetY = (vertID == 0 || vertID == 3) ? 2 : 10;
					int offsetX = (vertID == 0 || vertID == 1) ? 2 : 10;
					int row = int(Position.y - offsetY) / 9;
					int col = int(Position.x - offsetX);
						
					int tintID = 10;
					if (row < 26) {
						if (col < debug_padding[row]) tintID = debug_lines[row].x;
						else tintID = debug_lines[row].y;
					}
					Debug = (row % 2) + 1;
					tint = debugMenu[tintID];
					
					switch (row) {
					case 0: if (col < 37) tint = debugMenu[0]; break;
					case 1: 
						if (col < 42) tint = debugMenu[1];
						if (col < 29) tint = debugMenu[4];
						break;
					case 8: if (col < 79) tint = debugMenu[8]; break;
					case 10: 
						if (col != 12) {
							if (col < 63) tint = debugMenu[5];
							else if (col < 113) tint = debugMenu[6];
							
							if (col == 0) tint = debugMenu[5];
							else if (col == 6) tint = debugMenu[6];
							else if (col == 17) tint = debugMenu[1];
						} break;
					case 13: 
						if (col == 139 || col == 137) tint = debugMenu[7];
						if (col == 132 || col == 136) tint = debugMenu[5];
						if (col < 51) tint = debugMenu[8];
						if (col < 27) tint = debugMenu[1];
						break;
					case 14: if (col < 46) tint = debugMenu[1]; break;
					case 17: if (col < 24) tint = debugMenu[1]; break;
					case 18: if (col < 63) tint = debugMenu[1]; break;
					}
				}
			} break;
		case 2650: 
			if (isGRAYSCALE) { switch (ctrlT.r) {
				case 255:	tint = vec4(messages[0].rgb, messages[0].a * color.a); break;
				case 63:	tint = vec4(messages[1].rgb, messages[1].a * color.a); break; 
			}} break;
		}
	}
	
	vertexColor = color * texelFetch(Sampler2, UV2 / 16, 0);
    vertexDistance = fog_cylindrical_distance(Position);
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
}
