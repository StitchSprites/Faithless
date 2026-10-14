#version 330

uniform sampler2D MainSampler;
uniform sampler2D MainDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ItemEntitySampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesSampler;
uniform sampler2D ParticlesDepthSampler;
uniform sampler2D WeatherSampler;
uniform sampler2D WeatherDepthSampler;
uniform sampler2D CloudsSampler;
uniform sampler2D CloudsDepthSampler;

in vec2 texCoord;

// ---- End Crystal beam distortion tunables ----
const float BEAM_ALPHA   = 12.0 / 255.0; // marker written by entity.fsh
const float MIN_PUSH     = 6.0;          // smallest displacement, in pixels
const float MAX_PUSH     = 22.0;         // largest displacement, in pixels
const int   SEARCH_STEPS = 10;           // how far we hunt for background outside the beam
const float SEARCH_GROW  = 1.45;         // each step reaches this much further
const vec3  VOID_COLOR   = vec3(0.03, 0.0, 0.06); // used if the beam fills the whole search area
const float TAU          = 6.2831853;

vec4 color_layers[6] = vec4[](vec4(0.0), vec4(0.0), vec4(0.0), vec4(0.0), vec4(0.0), vec4(0.0));
float depth_layers[6] = float[](0, 0, 0, 0, 0, 0);
int active_layers = 0;

out vec4 fragColor;

void try_insert(vec4 color, float depth) {
    if (color.a == 0.0) {
        return;
    }

    color_layers[active_layers] = color;
    depth_layers[active_layers] = depth;

    int jj = active_layers++;
    int ii = jj - 1;
    while (jj > 0 && depth_layers[jj] > depth_layers[ii]) {
        float depthTemp = depth_layers[ii];
        depth_layers[ii] = depth_layers[jj];
        depth_layers[jj] = depthTemp;

        vec4 colorTemp = color_layers[ii];
        color_layers[ii] = color_layers[jj];
        color_layers[jj] = colorTemp;

        jj = ii--;
    }
}

vec3 blend(vec3 dst, vec4 src) {
    return (dst * (1.0 - src.a)) + src.rgb;
}

// Vanilla layer composite, but the opaque "main" layer is supplied by the caller.
vec3 compose(vec3 mainRgb, float mainDepth, vec2 uv) {
    color_layers[0] = vec4(mainRgb, 1.0);
    depth_layers[0] = mainDepth;
    active_layers = 1;

    try_insert(texture(TranslucentSampler, uv), texture(TranslucentDepthSampler, uv).r);
    try_insert(texture(ItemEntitySampler, uv), texture(ItemEntityDepthSampler, uv).r);
    try_insert(texture(ParticlesSampler, uv), texture(ParticlesDepthSampler, uv).r);
    try_insert(texture(WeatherSampler, uv), texture(WeatherDepthSampler, uv).r);
    try_insert(texture(CloudsSampler, uv), texture(CloudsDepthSampler, uv).r);

    vec3 texelAccum = color_layers[0].rgb;
    for (int ii = 1; ii < active_layers; ++ii) {
        texelAccum = blend(texelAccum, color_layers[ii]);
    }
    return texelAccum;
}

bool is_beam(vec4 c) {
    return abs(c.a - BEAM_ALPHA) < 0.5 / 255.0;
}

void main() {
    vec4 mainSample = texture(MainSampler, texCoord);
    float mainDepth = texture(MainDepthSampler, texCoord).r;
    vec3 mainRgb = mainSample.rgb;

    if (is_beam(mainSample)) {
        // The beam overwrote the pixels behind it, so the "background" has to be
        // borrowed from the nearest non-beam pixels, pushed along a swirling direction field.
        ivec2 size = textureSize(MainSampler, 0);
        ivec2 here = ivec2(texCoord * vec2(size));

        float pu = mainSample.r * TAU;               // fract(u) of the beam texture
        float pv = mainSample.g * TAU;               // fract(v), scrolls along the beam over time
        float angle = 2.0 * pu + pv;                 // integer multipliers keep it seamless at the wrap
        vec2 dir = vec2(cos(angle), sin(angle));
        float amp = 0.5 + 0.5 * sin(3.0 * pv - pu);
        float dist = mix(MIN_PUSH, MAX_PUSH, amp);

        vec3 bg = VOID_COLOR;
        for (int i = 0; i < SEARCH_STEPS; i++) {
            ivec2 pa = here + ivec2(round(dir * dist));
            ivec2 pb = here - ivec2(round(dir * dist));
            if (all(greaterThanEqual(pa, ivec2(0))) && all(lessThan(pa, size))) {
                vec4 s = texelFetch(MainSampler, pa, 0);
                if (!is_beam(s)) { bg = s.rgb; break; }
            }
            if (all(greaterThanEqual(pb, ivec2(0))) && all(lessThan(pb, size))) {
                vec4 s = texelFetch(MainSampler, pb, 0);
                if (!is_beam(s)) { bg = s.rgb; break; }
            }
            dist *= SEARCH_GROW;
        }

        mainRgb = bg * mix(0.9, 1.1, amp); // faint shimmer
    }

    // Particles, weather, etc. in front of the beam still sort over the distorted background.
    fragColor = vec4(compose(mainRgb, mainDepth, texCoord), 1.0);
}
