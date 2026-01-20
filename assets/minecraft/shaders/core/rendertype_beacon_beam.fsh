#version 150

#moj_import <fog.glsl>
#moj_import <dynamictransforms.glsl>
#moj_import <projection.glsl>
#moj_import <globals.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in vec4 vertexColor;
in vec2 texCoord0;
in float posY;

out vec4 fragColor;

mat4 dither_matrix = mat4(
    1,  9,  3,  11,
    13, 5,  15, 7,
    4,  12, 2,  10,
    16, 8,  14, 6
) / 17.0;

void main() {
    vec2 uv = mod(texCoord0, 1.0) + sin(GameTime * vec2(-12000, -20000) + posY * vec2(2, 1)) * vec2(0.1, 0.5);
	
    vec4 color = texture(Sampler0, uv);
    color.a *= clamp(posY * 4.0 - 1.5, 0.0, 1.0);
    
    if (color.a < dither_matrix[int(gl_FragCoord.x) % 4][int(gl_FragCoord.y) % 4]) discard;
	
    color = vec4(vec3(color.rgb * color.rgb + 0.3), color.a) * vertexColor;
	color.rgb = cone_filter(Colorblindness, color.rgb);
	
    fragColor = color;
	fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
}
