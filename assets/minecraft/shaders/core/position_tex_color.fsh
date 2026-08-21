#version 150

#moj_import <dynamictransforms.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>
#moj_import <globals.glsl>
#moj_import <config.glsl>

uniform sampler2D Sampler0;

in vec2 texCoord0;
in vec4 vertexColor;
in vec3 skyDir;
in float isEndSky;

out vec4 fragColor;

// ═══════════════════════════════════════════════════════════════════════════════
//  UTILITY
// ═══════════════════════════════════════════════════════════════════════════════

// Simple value hash
float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float hash3(vec3 p) {
    p = fract(p * vec3(127.1, 311.7, 74.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y + p.z);
}

// Smooth noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0,0)), hash(i + vec2(1,0)), u.x),
        mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), u.x),
        u.y
    );
}

// Layered FBM
float fbm(vec2 p, int octaves) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < octaves; i++) {
        v += a * noise(p);
        p *= 2.1;
        a *= 0.5;
    }
    return v;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  END PORTAL  (the classic layered coloured-noise look)
// ═══════════════════════════════════════════════════════════════════════════════

vec3 endPortalColor(vec2 uv, float t) {
    // Five layered noise passes, each a different hue – mirrors vanilla portal
    vec3 col = vec3(0.0);

    // Layer 1 – dark violet base
    float n1 = fbm(uv * 3.0 + vec2(t * 0.11, t * 0.07), 4);
    col += vec3(0.05, 0.0, 0.15) * n1;

    // Layer 2 – teal / cyan streaks
    float n2 = fbm(uv * 5.5 - vec2(t * 0.13, t * 0.09), 4);
    col += vec3(0.0, 0.4, 0.5) * pow(n2, 1.5);

    // Layer 3 – bright green-white sparkle
    float n3 = fbm(uv * 9.0 + vec2(t * 0.17, -t * 0.15), 3);
    col += vec3(0.1, 0.8, 0.4) * pow(n3, 3.0);

    // Layer 4 – deep purple globs
    float n4 = fbm(uv * 2.0 + vec2(-t * 0.08, t * 0.12), 5);
    col += vec3(0.3, 0.0, 0.5) * n4 * 0.7;

    // Layer 5 – white-hot stars
    float n5 = fbm(uv * 14.0 - vec2(t * 0.2, t * 0.2), 2);
    col += vec3(1.0) * pow(n5, 6.0) * 0.8;

    return clamp(col, 0.0, 1.0);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SKYBOX FACE → UV  (cubic projection)
//  skyDir is the unnormalised world-space direction from the vertex shader.
// ═══════════════════════════════════════════════════════════════════════════════

// Returns the dominant axis face index and a [0,1]² UV on that face.
// Face indices: 0=+X, 1=-X, 2=+Y, 3=-Y, 4=+Z, 5=-Z
void cubeFaceUV(vec3 d, out int face, out vec2 uv) {
    vec3 a = abs(d);
    if (a.x >= a.y && a.x >= a.z) {
        face = (d.x > 0.0) ? 0 : 1;
        uv = (d.x > 0.0) ? vec2(-d.z, -d.y) / a.x
        : vec2( d.z, -d.y) / a.x;
    } else if (a.y >= a.x && a.y >= a.z) {
        face = (d.y > 0.0) ? 2 : 3;
        uv = (d.y > 0.0) ? vec2( d.x, d.z) / a.y
        : vec2( d.x, -d.z) / a.y;
    } else {
        face = (d.z > 0.0) ? 4 : 5;
        uv = (d.z > 0.0) ? vec2( d.x, -d.y) / a.z
        : vec2(-d.x, -d.y) / a.z;
    }
    uv = uv * 0.5 + 0.5;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TEAR  SHAPE
//  We define the tear in a 2D space on the +Y (top / up) face.
//  It bleeds onto the side faces via a smooth vertical gradient.
// ═══════════════════════════════════════════════════════════════════════════════

// Signed-distance to the tear "crack" shape on the top face.
// Returns negative INSIDE the tear, positive outside.
float tearSDF(vec2 uv, float t) {
    // Centre the UV
    vec2 p = uv - 0.5;

    // Base tear is a tapered ellipse leaning diagonally
    float angle = 0.38;          // ~22° tilt
    float c = cos(angle), s = sin(angle);
    vec2 rp = vec2(c * p.x - s * p.y, s * p.x + c * p.y);

    float lenA = 0.30, lenB = 0.055;   // half-extents
    float sdf = length(rp / vec2(lenA, lenB)) - 1.0;

    // Jagged, breathing distortion along the perimeter
    float breathe = 0.5 + 0.5 * sin(t * 0.0008);          // slow in/out
    float jagged = fbm(uv * 6.0 + vec2(t * 0.0003), 5);

    // Irregular spike teeth
    float spikes = sin(atan(p.y, p.x) * 9.0 + t * 0.001) * 0.04;

    sdf -= jagged * 0.06 * breathe;
    sdf -= spikes * breathe;

    return sdf;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AURORA  effect
// ═══════════════════════════════════════════════════════════════════════════════

// t is game time (GameTime * 24000 gives a convenient integer counter of ticks)
vec3 auroraColor(vec2 uv, float t, float strength) {
    // Drift the aurora bands slowly
    float wave = sin(uv.x * 6.0 + t * 0.0005) * 0.5
    + sin(uv.x * 3.2 - t * 0.0003) * 0.5;
    wave = wave * 0.5 + 0.5;

    float bands = noise(vec2(uv.x * 4.0, t * 0.0002)) * 0.6
    + noise(vec2(uv.x * 8.0 + 1.3, t * 0.00035)) * 0.4;

    float intensity = wave * bands * strength;

    // Hue: magenta → violet → pink → back to magenta
    float hShift = sin(uv.x * 3.0 + t * 0.0004) * 0.5 + 0.5;
    vec3 auroraHue = mix(vec3(1.0, 0.0, 1.0),   // magenta
            vec3(0.6, 0.0, 1.0),    // violet
            hShift);
    auroraHue = mix(auroraHue, vec3(1.0, 0.2, 0.8), // pink
            noise(vec2(uv.x * 5.0, t * 0.0006)));

    return auroraHue * intensity * 1.4;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PROCEDURAL END SKY  – main entry point
// ═══════════════════════════════════════════════════════════════════════════════

vec4 endSkyColor(vec3 dir) {
    // GameTime advances 1/24000 per tick; scale to get a steadily growing counter
    float t = GameTime * 24000.0;

    // Identify which cube face we're on and get the face-local UV
    int face;
    vec2 faceUV;
    cubeFaceUV(dir, face, faceUV);

    // Normalise direction for later use
    vec3 nd = normalize(dir);

    // ── 1. Base void sky ──────────────────────────────────────────────────────
    // A very dark purple / indigo gradient, slightly lighter toward the horizon.
    float horizonFactor = 1.0 - abs(nd.y);        // 0 at poles, 1 at equator
    vec3 baseSky = mix(vec3(0.01, 0.0, 0.04),      // zenith / nadir – near black
            vec3(0.04, 0.01, 0.08),      // horizon – slightly purple
            pow(horizonFactor, 2.0));

    // Subtle noise grain in the base
    baseSky += fbm(faceUV * 12.0 + vec2(t * 0.00005), 3) * 0.015;

    vec3 sky = baseSky;

    // ── 2. Tear (only visible on the +Y top face) ─────────────────────────────
    float tearMask    = 0.0;   // 1 inside the tear
    float tearEdge    = 0.0;   // 0‥1 — distance to the tear edge (for glow)
    float auroraStrength = 0.0;

    if (face == 2) {
        // We're on the top (+Y) face
        float sdf = tearSDF(faceUV, t);

        // Interior portal colour
        tearMask = smoothstep(0.005, -0.02, sdf);

        // Edge glow band (magenta)
        float edgeWidth = 0.06 + 0.03 * sin(t * 0.0007);   // breathes slightly
        tearEdge = smoothstep(edgeWidth, 0.0, sdf)
        * smoothstep(-0.02,  0.0, sdf);

        // Aurora starts at the edge and fans down from the top face.
        // Strength is largest right at the crack.
        auroraStrength = smoothstep(0.25, 0.0, sdf) * 0.9;
    }

    // On side faces, aurora bleeds in from above – stronger the closer to the
    // top of the face (faceUV.y → 1 is "up" on side faces after our mapping).
    bool isSideFace = (face == 0 || face == 1 || face == 4 || face == 5);
    if (isSideFace) {
        // How far up the side face are we? (0 = bottom, 1 = top)
        float upness = faceUV.y;
        auroraStrength = pow(upness, 2.5) * 0.55;
    }

    // ── 3. Portal fill ────────────────────────────────────────────────────────
    if (tearMask > 0.0) {
        // UV for the portal – swirling over time
        vec2 portalUV = faceUV * 2.5 + vec2(t * 0.00008, t * 0.00006);
        vec3 portal = endPortalColor(portalUV, t);
        sky = mix(sky, portal, tearMask);
    }

    // ── 4. Tear edge magenta glow ─────────────────────────────────────────────
    vec3 magenta = vec3(1.0, 0.0, 1.0);
    // Add an inner blooming bright core to the edge
    float edgeCore = (face == 2)
    ? smoothstep(0.01, -0.005, tearSDF(faceUV, t))
    * (1.0 - smoothstep(-0.005, -0.02, tearSDF(faceUV, t)))
    : 0.0;

    sky = mix(sky, magenta * 2.0, tearEdge * 0.85);
    sky += magenta * edgeCore * 0.6;

    // ── 5. Aurora on all faces ────────────────────────────────────────────────
    if (auroraStrength > 0.001) {
        // Use spherical longitude/latitude to keep the aurora consistent across
        // faces rather than per-face UV, so there are no seams.
        float lon = atan(nd.x, nd.z);          // -π .. π
        float lat = asin(clamp(nd.y, -1.0, 1.0));  // -π/2 .. π/2
        vec2 auroraUV = vec2(lon / 6.2832, lat / 3.1416) + 0.5;

        vec3 aurora = auroraColor(auroraUV, t, auroraStrength);
        sky += aurora;
    }

    // ── 6. Bottom face – single white star point ──────────────────────────────
    if (face == 3) {
        // Centred point, very small & sharp
        float dist = length(faceUV - 0.5);
        float star = smoothstep(0.018, 0.0, dist);
        // Soft twinkling
        float twinkle = 0.85 + 0.15 * sin(t * 0.0013 + 1.57);
        sky += vec3(1.0) * star * twinkle;
        // Tiny four-pointed diffraction spike
        vec2 sp = faceUV - 0.5;
        float spike = smoothstep(0.002, 0.0, abs(sp.x)) * smoothstep(0.06, 0.0, abs(sp.y))
        + smoothstep(0.002, 0.0, abs(sp.y)) * smoothstep(0.06, 0.0, abs(sp.x));
        sky += vec3(0.9, 0.95, 1.0) * spike * 0.5 * twinkle;
    }

    // ── 7. Scatter a handful of dim stars on side/top faces ──────────────────
    if (face != 3) {
        // Cheap star field: hash-based puncturing
        vec2 stCell = floor(faceUV * 40.0);
        float stH = hash(stCell + float(face) * 17.3);
        if (stH > 0.97) {
            vec2 stPos = fract(faceUV * 40.0) - vec2(hash(stCell), hash(stCell + 7.7));
            float stBright = smoothstep(0.08, 0.0, length(stPos));
            float stTwinkle = 0.7 + 0.3 * sin(t * 0.001 * stH * 6.0);
            sky += vec3(0.8, 0.85, 1.0) * stBright * stTwinkle * 0.6;
        }
    }

    return vec4(clamp(sky, 0.0, 1.0), 1.0);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MAIN
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
    if (isEndSky > 0.5) {
        // ── Procedural End Skybox path ────────────────────────────────────────
        fragColor = endSkyColor(skyDir);
        // Still apply ColorModulator alpha (Minecraft may fade the sky in/out)
        fragColor.a *= ColorModulator.a;
    } else {
        // ── Normal path (all other position_tex_color draw calls) ─────────────
        vec4 color = texture(Sampler0, texCoord0) * vertexColor;
        if (color.a == 0.0) discard;
        fragColor = color * ColorModulator;
        fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
    }
}
