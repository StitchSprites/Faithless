#version 150

#moj_import <light.glsl>
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

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform int FogShape;
uniform float GameTime;

uniform vec3 Light0_Direction;
uniform vec3 Light1_Direction;

out float vertexDistance;
out vec4 vertexColor;
out vec4 lightMapColor;
out vec4 overlayColor;
out vec2 texCoord0;
out vec4 normal;

out vec4 damageTint;
flat out int isPlayer;
flat out ivec3 redDigits;
flat out ivec3 greenDigits;
flat out ivec3 blueDigits;
flat out ivec3 alphaDigits;

float hash(float p) {
    p = fract(p * 0.011);
    p *= p + 7.5;
    p *= p + p;
    return fract(p);
}

float noise(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), u);
}

float fbm(float x) {
    float v = 0.0;
    float a = 0.5;
    float shift = float(100);
    for (int i = 0; i < 3; ++i) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

ivec3 getDigits(int value) {
    int digit0 = value % 10;
    int digit1 = (value / 10) % 10;
    int digit2 = (value / 100) % 10;
    return ivec3(digit0, digit1, digit2);
}

void main() {
    texCoord0 = UV0;
	vec3 position = Position;

    vertexDistance = fog_distance(Position, FogShape);
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
    lightMapColor = texelFetch(Sampler2, UV2 / 16, 0);
    overlayColor = texelFetch(Sampler1, UV1, 0);
	
	vec4 test = vec4(texelFetch(Sampler0, ivec2(62, 51), 0) * 255);
    if (test.a == 220 && textureSize(Sampler0, 0) == ivec2(64, 64) && Player_Skin_Features) {
		vec4 controlP = vec4(texelFetch(Sampler0, ivec2(63, 51), 0));
		if (controlP.rgba != vec4(0)) {
			isPlayer = 1;
			ivec4 controlV = ivec4(controlP * 255.0);
			redDigits = getDigits(controlV.r);
			greenDigits = getDigits(controlV.g);
			blueDigits = getDigits(controlV.b);
			alphaDigits = getDigits(controlV.a);
			
			vec4 damageFlash = texelFetch(Sampler1, UV1, 0);
			
			vec4 texel = texelFetch(Sampler0, ivec2(20, 20), 0);
			float Blinking = fbm(floor((GameTime + texel.r + texel.g + texel.b + texel.a) * 10000));
			
			if (Player_Hurt_Mask) damageTint = vec4(test.rgb, damageFlash.a);
			
			if (damageFlash == vec4(1.0)) {
				if (redDigits.b == 1 && Blinking > 0.725 && Player_Blink_Face) {
					if (texCoord0.x >= 0.125 && texCoord0.y >= 0.125 && texCoord0.x <= 0.25 && texCoord0.y <= 0.25) {                                                                          
						if 		(gl_VertexID == 12) texCoord0 = vec2(0.125, 0.0);
						else if (gl_VertexID == 13) texCoord0 = vec2(0.0, 0.0);
						else if (gl_VertexID == 14) texCoord0 = vec2(0.0, 0.125);
						else if (gl_VertexID == 15) texCoord0 = vec2(0.125, 0.125);
					} 
					if (texCoord0.x >= 0.625 && texCoord0.y >= 0.125 && texCoord0.x <= 0.75 && texCoord0.y <= 0.25) {    
						if 		(gl_VertexID == 156) texCoord0 = vec2(0.625, 0.0);
						else if (gl_VertexID == 157) texCoord0 = vec2(0.5, 0.0);
						else if (gl_VertexID == 158) texCoord0 = vec2(0.5, 0.125);
						else if (gl_VertexID == 159) texCoord0 = vec2(0.625, 0.125);
					}
				}
				
				if (blueDigits.b == 1 && Blinking <= 0.725 && (UV2.x >= 200 && UV2.x < 240 || UV2.x > 240 || UV2.x <= 50 && UV2.y <= 50) && Player_Squint_Face) {
					if (texCoord0.x >= 0.125 && texCoord0.y >= 0.125 && texCoord0.x <= 0.25 && texCoord0.y <= 0.25) {
						if 		(gl_VertexID == 12) texCoord0 = vec2(1.0, 0.625);
						else if (gl_VertexID == 13) texCoord0 = vec2(0.875, 0.625);
						else if (gl_VertexID == 14) texCoord0 = vec2(0.875, 0.75);
						else if (gl_VertexID == 15) texCoord0 = vec2(1.0, 0.75);
					}
					if (texCoord0.x >= 0.625 && texCoord0.y >= 0.125 && texCoord0.x <= 0.75) {
						if 		(gl_VertexID == 156) texCoord0 = vec2(1.0, 0.5);
						else if (gl_VertexID == 157) texCoord0 = vec2(0.875, 0.5);
						else if (gl_VertexID == 158) texCoord0 = vec2(0.875, 0.625);
						else if (gl_VertexID == 159) texCoord0 = vec2(1.0, 0.625);
					}
				}
			}
			
			if (greenDigits.b == 1 && damageFlash != vec4(1.0) && Player_Hurt_Face) {
				if ( texCoord0.x >= 0.125 && texCoord0.y >= 0.125 && texCoord0.x <= 0.25 && texCoord0.y <= 0.25 ) {
					if 		(gl_VertexID == 12) { texCoord0 = vec2(0.5, 0.0); } 
					else if (gl_VertexID == 13) { texCoord0 = vec2(0.375, 0.0); } 
					else if (gl_VertexID == 14) { texCoord0 = vec2(0.375, 0.125); } 
					else if (gl_VertexID == 15) { texCoord0 = vec2(0.5, 0.125); }
				} 
				if ( texCoord0.x >= 0.625 && texCoord0.y >= 0.125 && texCoord0.x <= 0.75 && texCoord0.y <= 0.25 ) {
					if 		(gl_VertexID == 156) { texCoord0 = vec2(1.0, 0.0); } 
					else if (gl_VertexID == 157) { texCoord0 = vec2(0.875, 0.0); } 
					else if (gl_VertexID == 158) { texCoord0 = vec2(0.875, 0.125); } 
					else if (gl_VertexID == 159) { texCoord0 = vec2(1.0, 0.125); }
				}
			} 
			
			if (blueDigits.r == 1 && Player_Cape && SODIUM == false) {
				vec3 norm = Normal;
				if (ivec4(texelFetch(Sampler0, ivec2(51, 19), 0) * 255.0 + 0.5) == ivec4(0, 0, 0, 255)) {
					if 		(gl_VertexID == 284) { texCoord0 = vec2(1.0, 0.25); position += norm * 0.045; }
					else if (gl_VertexID == 285) { texCoord0 = vec2(0.84375, 0.25); position += norm * 0.045; }
					else if (gl_VertexID == 286) { 
						float wave1 = (sin(GameTime * 2000.0) * 0.5 + 0.5) * 0.2 + 0.2;
						texCoord0 = vec2(0.84375, 0.5); position += norm * wave1; position.y += length(wave1) * 0.6 - 0.3; }
					else if (gl_VertexID == 287) { 
						float wave2 = (sin(GameTime * 2000.0 + 0.8) * 0.5 + 0.5) * 0.2 + 0.2;
						texCoord0 = vec2(1.0, 0.5); position += norm * wave2; position.y += length(wave2) * 0.6 - 0.3; }
				} else {
					if 		(gl_VertexID == 284) { texCoord0 = vec2(1.0, 0.25); position += norm * 0.045; }
					else if (gl_VertexID == 285) { texCoord0 = vec2(0.875, 0.25); position += norm * 0.045; }
					else if (gl_VertexID == 286) { 
						float wave1 = (sin(GameTime * 2000.0) * 0.5 + 0.5) * 0.2 + 0.2;
						texCoord0 = vec2(0.875, 0.5); position += norm * wave1; position.y += length(wave1) * 0.6 - 0.3; }
					else if (gl_VertexID == 287) { 
						float wave2 = (sin(GameTime * 2000.0 + 0.8) * 0.5 + 0.5) * 0.2 + 0.2;
						texCoord0 = vec2(1.0, 0.5); position += norm * wave2; position.y += length(wave2) * 0.6 - 0.3; }
				}
			}
		}
    } 
    gl_Position = ProjMat * ModelViewMat * vec4(position, 1.0);
}
