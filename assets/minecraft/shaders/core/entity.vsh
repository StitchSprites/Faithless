#version 150

#moj_import <light.glsl>
#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>
#moj_import <globals.glsl>
#moj_import <fog.glsl>
#moj_import <config.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler1;
uniform sampler2D Sampler2;

out float vertexDistance;
out vec4 vertexColor0;
out vec4 vertexColor1;
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;
out vec3 screenPos;

void main() {
    texCoord0 = UV0;
	overlayColor = texelFetch(Sampler1, UV1, 0);
	lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
	
	bool shade = true;
	vec3 pos = Position;
	
    if (Fresh_Animations) {
        ivec4 ctrlL = ivec4(texture(Sampler0, vec2(0)) * 255.0 + 0.5);
        if (ctrlL.a == 128) {
            switch (ctrlL.r) {
                case 1: shade = false; break; //MagmaCube
                case 2: shade = false; break; //WitherSkeleton
                case 3: shade = false; break; //Enderman
                case 4: shade = false; break; //Blaze
            }
        }
    }
	
	vec4 test = vec4(texelFetch(Sampler0, ivec2(62, 51), 0) * 255);
	if (Player_Skin_Features && test.a == 220 && textureSize(Sampler0, 0) == ivec2(64, 64)) {
		shade = false;
	}
	
	vertexColor0 = shade ? minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color) : vec4(1);
	vertexColor1 = Color;
	
    vertexDistance = fog_cylindrical_distance(Position);
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
    if (Ender_Chest) screenPos = gl_Position.xyw;
}
