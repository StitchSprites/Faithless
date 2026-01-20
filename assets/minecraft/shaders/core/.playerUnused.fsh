#version 150

#moj_import <fog.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;
in vec4 normal;

in vec4 damageTint;
flat in int isPlayer;
flat in ivec3 redDigits;
flat in ivec3 greenDigits;
flat in ivec3 blueDigits;
flat in ivec3 alphaDigits;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a == 0.0) discard; 
	
	if (isPlayer == 1) {
		if (redDigits.g != 0 && Player_Transparency) {
			bool DiscardPixel = false;
			for (int i = 0; i < 8; i++) {
				for (int j = 0; j < 2; j++) {
					vec4 DiscardGrid = texelFetch(Sampler0, ivec2(12 + i, 16 + j), 0);
					if (DiscardGrid.rgb == color.rgb) DiscardPixel = true; break;
				}
			}
			switch (redDigits.g) {
			case 1: if (DiscardPixel == true) discard; break;
			case 2: if (DiscardPixel != true) discard; break;
			}
		}
		
		if (greenDigits.g != 0 && Player_Hurt_Mask) {
			bool HurtMaskPixel = false;
			for (int i = 0; i < 8; i++) {
				for (int j = 0; j < 2; j++) {
					vec4 HurtMaskGrid = texelFetch(Sampler0, ivec2(36 + i, 16 + j), 0);
					if (HurtMaskGrid.rgb == color.rgb) HurtMaskPixel = true; break;
				}
			}
			switch (greenDigits.g) {
			case 1: if (damageTint.a < 0.99 && HurtMaskPixel == true) color.rgb = color.rgb * mat3(0.2126, 0.7152, 0.0722, 0.2126, 0.7152, 0.0722, 0.2126, 0.7152, 0.0722) * damageTint.rgb; break;
			case 2: if (damageTint.a < 0.99 && HurtMaskPixel != true) color.rgb = color.rgb * mat3(0.2126, 0.7152, 0.0722, 0.2126, 0.7152, 0.0722, 0.2126, 0.7152, 0.0722) * damageTint.rgb; break;
			case 3: if (damageTint.a < 0.99) color.rgb = color.rgb * mat3(0.2126, 0.7152, 0.0722, 0.2126, 0.7152, 0.0722, 0.2126, 0.7152, 0.0722) * damageTint.rgb; break;
			}
		} else { color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a); }
		
		if (redDigits.r != 0 && Player_Emissives) {
			bool EmissivePixel = false;
			for (int i = 0; i < 8; i++) {
				for (int j = 0; j < 2; j++) {
					vec4 EmissiveGrid = texelFetch(Sampler0, ivec2(12 + i, 18 + j), 0);
					if (EmissiveGrid.rgb == color.rgb) EmissivePixel = true; break;
				}
			}
			switch (redDigits.r) {
			case 1: if (EmissivePixel != true) color *= lightMapColor * vertexColor; break;
			case 2: if (EmissivePixel == true) color *= lightMapColor * vertexColor; break;
			case 3: break;
			}
		} else { color *= lightMapColor * vertexColor; }
	} else { 
		color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a); 
		color *= vertexColor * lightMapColor; 
	}
	
	switch (Colorblindness) {
	case 1: color.rgb = mat3(		
		0.170556992, 0.170556991,-0.004517144,
		0.829443014, 0.829443008, 0.004517144,
		0          , 0          , 1          ) * color.rgb; break;
	case 2: color.rgb = mat3(	
		0.33066007 , 0.33066007 ,-0.02785538 ,
		0.66933993 , 0.66933993 , 0.02785538 ,
		0          , 0          , 1          ) * color.rgb; break;
	case 3: color.rgb = mat3(	
		1          , 0          , 0          ,
		0.1273989  , 0.8739093  , 0.8739093  ,
	   -0.1273989  , 0.1260907  , 0.1260907  ) * color.rgb; break;
	case 4: color.rgb = color.rgb * mat3(	
		0.2126     , 0.7152     , 0.0722     ,
		0.2126     , 0.7152     , 0.0722     ,
		0.2126     , 0.7152     , 0.0722     ); break;
	}
	
	fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
