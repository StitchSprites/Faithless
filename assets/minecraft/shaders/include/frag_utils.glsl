#version 150

// -- Colorblindness --------------------------------------------------------------------------------------

vec3 cone_filter(int Colorblindness, vec3 color) {
	switch (Colorblindness) {
	case 1: color = mat3(		
		0.170556992, 0.170556991,-0.004517144,
		0.829443014, 0.829443008, 0.004517144,
		0          , 0          , 1          ) * color; break;
	case 2: color = mat3(	
		0.33066007 , 0.33066007 ,-0.02785538 ,
		0.66933993 , 0.66933993 , 0.02785538 ,
		0          , 0          , 1          ) * color; break;
	case 3: color = mat3(	
		1          , 0          , 0          ,
		0.1273989  , 0.8739093  , 0.8739093  ,
	   -0.1273989  , 0.1260907  , 0.1260907  ) * color; break;
	case 4: color = color * mat3(	
		0.2126     , 0.7152     , 0.0722     ,
		0.2126     , 0.7152     , 0.0722     ,
		0.2126     , 0.7152     , 0.0722     ); break;
	}
	return color;
}

// -- End Portal --------------------------------------------------------------------------------------

#moj_import <matrix.glsl>
#define Portal_Layers 16

float hash12(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

const vec3[] Endportal_Colors = vec3[](
    vec3(5, 25, 28) * (0.00392), vec3(3, 24, 22) * (0.00392), vec3(7, 25, 25) * (0.00392), vec3(11, 28, 29) * (0.00392),
    vec3(16, 30, 24) * (0.00392), vec3(16, 22, 31) * (0.00392), vec3(21, 28, 42) * (0.00392), vec3(24, 39, 23) * (0.00392),
    vec3(27, 33, 49) * (0.00392), vec3(24, 28, 47) * (0.00392), vec3(34, 35, 37) * (0.00392), vec3(17, 62, 60) * (0.00392),
    vec3(50, 36, 54) * (0.00392), vec3(12, 80, 82) * (0.00392), vec3(52, 99, 77) * (0.00392), vec3(20, 80, 168) * (0.00392)
);

mat4 end_portal_layer(float layer, float GameTime) {
    mat4 translate = mat4(
        1.0, 0.0, 0.0, 17.0 / layer,
        0.0, 1.0, 0.0, layer * GameTime * 1.125,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );

    mat2 rotate = mat2_rotate_z(radians(layer * layer));
    mat2 scale = mat2((4.5 - layer * 0.25) * 2.0);
    return mat4(scale * rotate) * translate;
}

vec3 render_endParallax(vec3 baseColor, vec2 fragCoord, vec2 screenSize, float GameTime) {
    vec3 color = baseColor * vec3(0.463, 0.337, 0.647);
    for (int i = 0; i < Portal_Layers; i++) {
        vec4 proj = vec4(fragCoord / screenSize, 0, 1) * end_portal_layer(i + 1.0, GameTime);
        float pixel = hash12(floor(fract(proj.xy / proj.w) * 256.0));
        color += (step(0.95, pixel) * 0.2 + step(0.99, pixel) * 0.8) * Endportal_Colors[i];
    }
    return color;
}