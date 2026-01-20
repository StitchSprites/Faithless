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
in vec2 UV1;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler0;
uniform sampler2D Sampler2;

out float vertexDistance;
out vec4 vertexColor0;
out vec4 vertexColor1;
out vec4 lightMapColor;
out vec2 texCoord0;

vec3 liquid_render(float value) {
    float wave = (Position.x + Position.y + Position.z + GameTime * 5000.0) * 0.333;
    return (sin(wave) + sin(wave * 2.1)) * vec3(0.005, 0.015, 0.005) * value;
}

void main() {
    texCoord0 = UV0;
	lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
	
    vec3 pos = Position;
	
	ivec4 ctrlV = ivec4(textureLod(Sampler0, UV0, 0) * 255.0 + 0.5);
	
	switch (ctrlV.a) {
	case 255: case 0: break;
	case 254: pos.y += liquid_render(1.0).y; break;	//Bucket, Potion, & Soup
	case 1: pos.y += liquid_render(1.0).y; break;	//Bucket, Potion, & Soup
	}
	
	vertexColor0 = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
	vertexColor1 = Color;
	
    vertexDistance = fog_cylindrical_distance(Position);
    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);
}
