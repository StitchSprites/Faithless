#version 150

#moj_import <dynamictransforms.glsl>
#moj_import <frag_utils.glsl>
#moj_import <config.glsl>
#moj_import <globals.glsl>

uniform sampler2D Sampler0;

in vec2 texCoord0;
in vec4 vertexColor;
in vec3 skyDir;
in float isEndSky;

out vec4 fragColor;

// ═══════════════════════════════════════════════════════════════════════════════
//  END SKYBOX – "THE RIFT"
//
//  Everything below is a pure function of the view DIRECTION (never of a cube
//  face's UV), so there are no face seams. All animation is built from integer
//  numbers of cycles per GameTime wrap (GameTime loops every 24000 ticks), so
//  there is no pop when the clock wraps either.
//
//  Layout of the sky:
//    +Y (top)   : the rift, dead centre of the face
//    side faces : aurora curtains hanging DOWN from the sky, fading out
//    -Y (bottom): black, with one square star
// ═══════════════════════════════════════════════════════════════════════════════

// ───────────────────────────── TUNABLES ───────────────────────────────────────
// Rift size is in "top-face units": 1.0 = distance from face centre to face edge.
const float RIFT_MIN_RADIUS   = 0.30;   // rift when fully squeezed shut
const float RIFT_MAX_RADIUS   = 0.47;   // rift when fully pushed open
const float RIFT_LUMPINESS    = 1.45;   // how blobby / how many islands pinch off
const float RIFT_CORE_SIZE    = 0.50;   // keystone blob at the zenith, as a fraction of the rift radius
const float AURORA_STRENGTH   = 1.0;
const float STAR_CHANCE       = 0.17;   // chance a sky cell holds a star

const vec3  RIM_COLOR     = vec3(0.60, 0.03, 0.56);   // dark magenta rim
const vec3  RIM_HOT       = vec3(0.95, 0.30, 0.95);   // thin bright line on the very edge
const vec3  BLEED_COLOR   = vec3(0.55, 0.04, 0.90);   // aurora bleeding off the rift
const vec3  AURORA_RED    = vec3(0.70, 0.00, 0.62);
const vec3  AURORA_VIOLET = vec3(0.50, 0.00, 1.05);
const vec3  RIFT_VOID     = vec3(0.027, 0.012, 0.150); // rift interior

// Rift animation rates, in cycles per GameTime wrap (24000 ticks = 20 min).
// MUST stay whole numbers or the animation pops when the clock wraps.
// Pulse: 38/58/94 cycles  ->  ~32 s / ~21 s / ~13 s per swell.
const int RIFT_PULSE_A     = 38;
const int RIFT_PULSE_B     = 58;
const int RIFT_PULSE_C     = 94;
// Outline morphing (lattice steps per wrap): warp / big lumps / edge fizz.
const int RIFT_MORPH_WARP  = 22;
const int RIFT_MORPH_LUMPS = 40;
const int RIFT_MORPH_FIZZ  = 120;

// End-portal style star layers inside the rift
const int   RIFT_STAR_LAYERS = 7;
const float RIFT_STAR_SPEED_FAR  = 0.015;  // drift speed of the finest layer (face units / second)
const float RIFT_STAR_SPEED_NEAR = 0.060;  // drift speed of the coarsest layer
// Drift heading of each layer in degrees. Deliberately scattered (neighbouring
// layers are 95-190 degrees apart, none are in order) so the layers read as
// moving in unrelated directions. Independent of the layer's rotation angle.
const float RIFT_STAR_HEADING[7] = float[](15.0, 190.0, 95.0, 285.0, 50.0, 235.0, 140.0);
// Each layer also meanders: a slow looping wobble (RIFT_STAR_WOBBLE cells wide)
// bends its path so the headings keep shifting instead of being dead straight.
const float RIFT_STAR_WOBBLE = 2.0;
// Star cells repeat every RIFT_STAR_PERIOD cells (far larger than the rift), and
// each layer scrolls a whole multiple of that per wrap, so the field loops exactly.
const int   RIFT_STAR_PERIOD = 64;

const float TAU = 6.28318530718;

// ═══════════════════════════════════════════════════════════════════════════════
//  HASH / NOISE   (integer hash, same result on every GPU)
// ═══════════════════════════════════════════════════════════════════════════════

uint pcg(uint v) {
    uint s = v * 747796405u + 2891336453u;
    uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}

uint hashI(ivec3 c) {
    c += ivec3(65536);
    return pcg(uint(c.x) + pcg(uint(c.y) + pcg(uint(c.z))));
}

float h01(uint h) { return float(h & 0xFFFFFFu) * (1.0 / 16777216.0); }

// 3D value noise. If zPeriod > 0 the lattice repeats every zPeriod cells along
// z, which lets z be driven by GameTime and loop perfectly.
float vnoise(vec3 p, int zPeriod) {
    vec3 ip = floor(p);
    vec3 f  = p - ip;
    vec3 u  = f * f * (3.0 - 2.0 * f);
    ivec3 c = ivec3(ip);
    int z0 = c.z;
    int z1 = c.z + 1;
    if (zPeriod > 0) {
        z0 = ((z0 % zPeriod) + zPeriod) % zPeriod;
        z1 = ((z1 % zPeriod) + zPeriod) % zPeriod;
    }
    float n000 = h01(hashI(ivec3(c.x,     c.y,     z0)));
    float n100 = h01(hashI(ivec3(c.x + 1, c.y,     z0)));
    float n010 = h01(hashI(ivec3(c.x,     c.y + 1, z0)));
    float n110 = h01(hashI(ivec3(c.x + 1, c.y + 1, z0)));
    float n001 = h01(hashI(ivec3(c.x,     c.y,     z1)));
    float n101 = h01(hashI(ivec3(c.x + 1, c.y,     z1)));
    float n011 = h01(hashI(ivec3(c.x,     c.y + 1, z1)));
    float n111 = h01(hashI(ivec3(c.x + 1, c.y + 1, z1)));
    return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
               mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

// 2D fbm that evolves in time and loops with GameTime.
// timeCells = lattice steps in time per GameTime wrap (bigger = faster).
// Octave i runs (i+1)x faster, still looping.
float fbmT(vec2 p, int octaves, int timeCells) {
    float v = 0.0, a = 0.5, norm = 0.0;
    for (int i = 0; i < octaves; i++) {
        int period = timeCells * (i + 1);
        v += a * vnoise(vec3(p, GameTime * float(period)), period);
        norm += a;
        p = p * 2.03 + vec2(17.3, 9.1);
        a *= 0.5;
    }
    return v / norm;
}

vec2 rot(vec2 v, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  THE RIFT
//  Works in the gnomonic plane above the zenith:  p = dir.xz / dir.y
//  (identical to the top face's UV, but continuous onto the sides).
// ═══════════════════════════════════════════════════════════════════════════════

// 0..1 – how far open the rift is right now. A few unrelated pulse rates are
// stacked so it never settles into a clean sine: it looks like it's struggling.
float riftPulse() {
    float T = GameTime;
    float a = 0.50 * sin(TAU * T * float(RIFT_PULSE_A))
            + 0.30 * sin(TAU * T * float(RIFT_PULSE_B) + 1.7)
            + 0.20 * sin(TAU * T * float(RIFT_PULSE_C) + 4.1);
    float s = a * 0.5 + 0.5;
    // ease the extremes a little so it lingers wide open / pinched shut
    return smoothstep(0.0, 1.0, s);
}

float smax(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return max(a, b) + h * h * k * 0.25;
}

// > 0 inside the rift, < 0 outside. Roughly distance in top-face units.
float riftField(vec2 p, float R) {
    // domain warp -> torn, organic outline
    vec2 w = vec2(fbmT(p * 1.4 + vec2(3.7, 1.9), 3, RIFT_MORPH_WARP),
                  fbmT(p * 1.4 + vec2(8.3, 2.8), 3, RIFT_MORPH_WARP)) - 0.5;
    vec2 q = p + w * 0.55;

    float lumps  = fbmT(q * 2.9, 4, RIFT_MORPH_LUMPS);          // big blobs / islands
    float bubble = fbmT(q * 5.0 + 11.0, 2, RIFT_MORPH_FIZZ);    // fizzing on the edge

    float d = R - length(q)
            + (lumps  - 0.5) * RIFT_LUMPINESS * 1.05
            + (bubble - 0.5) * 0.06;

    // Keystone: a small ragged blob pinned to the zenith. The aurora rays all
    // converge on that exact point, so it must never be exposed, however far
    // the rest of the rift pinches shut. Its noise is at most +-0.11, and its
    // base radius is R * RIFT_CORE_SIZE (>= 0.15), so p = 0 is always inside.
    float coreN = fbmT(p * 5.5 + 31.0, 3, RIFT_MORPH_FIZZ);
    float core  = R * RIFT_CORE_SIZE - length(p) + (coreN - 0.5) * 0.22;
    d = smax(d, core, 0.08);

    // always fully closed well away from the zenith
    d -= smoothstep(0.9, 1.35, length(p)) * 3.0;
    return d;
}

// One layer of stars inside the rift, modelled on vanilla's end_portal_layer():
//   * every layer is rotated by its own angle  radians((L*L*4321 + L*9) * 2)
//     (so its sparkles are tilted differently too),
//   * every layer has its own scale: finer/dimmer = far, coarser/brighter = near,
//   * every layer scrolls, faster for the nearer ones, along its OWN rotated
//     axis, so the layers slide past each other in different directions.
// Each layer's drift heading is its own scattered angle, plus a looping wobble.
// The scroll is a whole multiple of RIFT_STAR_PERIOD cells per GameTime wrap and
// the cell hash repeats with that period, so the star field is identical at
// GameTime 0 and 1 and never pops (speeds are rounded to that grid, ~+-8%).
vec3 riftStarLayer(vec2 p, int layer) {
    float L = float(layer);
    float t = (L - 1.0) / float(RIFT_STAR_LAYERS - 1);      // 0 = far, 1 = near

    float ang = radians(mod((L * L * 4321.0 + L * 9.0) * 2.0, 360.0));
    float sc  = mix(32.0, 11.0, t);                         // cells per face unit
    float spd = mix(RIFT_STAR_SPEED_FAR, RIFT_STAR_SPEED_NEAR, t);

    float hd = radians(RIFT_STAR_HEADING[layer - 1]);
    // heading is wanted in face space, but the grid is rotated by `ang` and a
    // scrolling grid moves its stars the opposite way, so convert:
    vec2 dir = -rot(vec2(cos(hd), sin(hd)), ang);
    float P  = float(RIFT_STAR_PERIOD);
    vec2 k   = P * floor(dir * (spd * 1200.0 * sc / P) + 0.5);  // cells per wrap

    // wobble: whole cycles per wrap (26..44 and +7), phases differ per layer
    float wm = float(26 + (layer * 5) % 19);
    vec2 wob = RIFT_STAR_WOBBLE * vec2(sin(TAU * GameTime * wm + L * 2.399),
                                       sin(TAU * GameTime * (wm + 7.0) + L * 4.113));

    vec2 g  = rot(p, ang) * sc + vec2(17.0 / L, 0.0) + k * GameTime + wob;
    vec2 id = floor(g);
    vec2 f  = g - id - 0.5;

    ivec2 ic = ivec2(mod(id, P));                           // fold into the repeat period
    uint h = hashI(ivec3(ic, 97 * layer));
    if (h01(h) > mix(0.05, 0.21, t)) return vec3(0.0);

    vec2 pt = vec2(h01(pcg(h + 1u)), h01(pcg(h + 2u))) * 0.5 - 0.25;
    vec2 v  = f - pt;
    if (h01(pcg(h + 3u)) > 0.5) v = rot(v, 0.785398);       // x-shaped instead of +

    float core = smoothstep(0.10, 0.0, length(v));
    float arms = smoothstep(0.06, 0.0, abs(v.x)) * smoothstep(0.22, 0.0, abs(v.y))
               + smoothstep(0.06, 0.0, abs(v.y)) * smoothstep(0.22, 0.0, abs(v.x));
    float s = core + arms * smoothstep(0.1, 0.7, t);        // far layers = plain dots

    float kt = float(40 + int(h01(pcg(h + 4u)) * 160.0));
    float tw = 0.65 + 0.35 * sin(TAU * GameTime * kt + h01(pcg(h + 5u)) * TAU);

    float c = h01(pcg(h + 6u));
    vec3 col = c < 0.45 ? vec3(0.20, 0.85, 0.95)       // cyan
             : c < 0.70 ? vec3(0.90, 0.35, 0.95)       // pink
             : c < 0.90 ? vec3(0.30, 0.45, 1.00)       // blue
                        : vec3(0.75, 0.85, 1.00);      // white
    return col * s * tw * mix(0.50, 1.10, t) * (0.55 + 0.45 * h01(pcg(h + 7u)));
}

vec3 riftInterior(vec2 p, float d) {
    float n = fbmT(p * 2.2, 3, 60);
    vec3 col = mix(RIFT_VOID * 0.55, RIFT_VOID * 1.35 + vec3(0.02, 0.0, 0.05), n);

    for (int i = 1; i <= RIFT_STAR_LAYERS; i++) col += riftStarLayer(p, i);

    // faint luminous lip just inside the edge
    col += RIM_COLOR * 0.18 * exp(-max(d, 0.0) * 22.0);
    return col;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STARS (seamless: 3D lattice on the view direction)
// ═══════════════════════════════════════════════════════════════════════════════

vec3 skyStars(vec3 nd) {
    const float S = 46.0;
    vec3 g  = nd * S;
    vec3 id = floor(g);
    vec3 f  = g - id;
    uint h  = hashI(ivec3(id));
    if (h01(h) > STAR_CHANCE) return vec3(0.0);

    vec3 pt = vec3(h01(pcg(h + 1u)), h01(pcg(h + 2u)), h01(pcg(h + 3u))) * 0.56 + 0.22;
    float size = mix(0.09, 0.17, h01(pcg(h + 4u)));
    float s = smoothstep(size, 0.0, length(f - pt));
    s *= s;

    float k  = float(60 + int(h01(pcg(h + 5u)) * 180.0));
    float tw = 0.6 + 0.4 * sin(TAU * GameTime * k + h01(pcg(h + 6u)) * TAU);

    float c = h01(pcg(h + 7u));
    vec3 col = c < 0.55 ? vec3(0.40, 0.45, 0.95)
             : c < 0.80 ? vec3(0.35, 0.75, 0.90)
                        : vec3(0.80, 0.55, 1.00);
    return col * s * tw * mix(0.45, 1.10, h01(pcg(h + 8u)));
}

// Single square star + soft blue glow straight down.
vec3 nadirStar(vec3 nd) {
    if (nd.y > -0.5) return vec3(0.0);
    vec2 p = nd.xz / (-nd.y);
    float cheb = max(abs(p.x), abs(p.y));
    float core = smoothstep(0.0345, 0.0305, cheb);
    float glow = 0.36 * smoothstep(0.14, 0.03, length(p));
    float tw   = 0.93 + 0.07 * sin(TAU * GameTime * 200.0);
    return (vec3(core) + vec3(0.20, 0.44, 1.00) * glow) * tw;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MAIN SKY
// ═══════════════════════════════════════════════════════════════════════════════

vec4 endSkyColor(vec3 dir) {
    float T  = GameTime;
    vec3  nd = normalize(dir);
    float ny = nd.y;

    // Gnomonic coordinates around the zenith. Derivatives are taken here, outside
    // any branch, and used for anti-aliasing the rift edge.
    vec2  p  = nd.xz / max(ny, 0.25);
    float pw = length(fwidth(p));

    // ── Rift ────────────────────────────────────────────────────────────────
    float R = mix(RIFT_MIN_RADIUS, RIFT_MAX_RADIUS, riftPulse());
    float d = -4.0;
    if (ny > 0.35 && length(p) < 1.45) d = riftField(p, R);

    float aa     = pw * 2.0 + 0.0015;
    float inside = smoothstep(-aa, aa, d);
    float outD   = max(-d, 0.0);

    // ── Aurora rays ─────────────────────────────────────────────────────────
    // Rays are lines of constant AZIMUTH around the vertical axis: straight
    // down the side faces, and fanning out from the rift on the top face.
    // Sampling noise on the azimuth circle (cos, sin) makes it wrap seamlessly.
    vec2  hz = nd.xz;
    float hl = length(hz);
    vec2  c  = hz / max(hl, 1e-4);
    vec2  cf = rot(c,  TAU * T * 3.0);     // fine rays drift slowly one way...
    vec2  cb = rot(c, -TAU * T * 2.0);     // ...broad colour bands the other
    float zs = 0.35 * sin(TAU * T * 120.0);

    float fine = vnoise(vec3(cf * 7.5,        ny * 1.3 + zs),        0) * 0.6
               + vnoise(vec3(cf * 15.0 + 3.1, ny * 2.2 - zs * 0.7),  0) * 0.4;
    float rays = clamp((fine - 0.22) * 1.7, 0.0, 1.0);
    rays = mix(0.5, rays, smoothstep(0.04, 0.30, hl));   // calm near the pole

    float band = vnoise(vec3(cb * 1.6, ny * 0.8), 0);
    vec3  hue  = mix(AURORA_RED, AURORA_VIOLET, smoothstep(0.15, 0.65, band));

    // Curtain: brightest up top, falling off exponentially DOWNWARD, gone by
    // the nadir. (ny = +1 is straight up.)
    float elev = exp(2.8 * (ny - 1.0)) * smoothstep(-0.8, -0.3, ny);
    float curt = elev * (0.55 + 0.75 * rays);
    curt *= 0.88 + 0.12 * sin(TAU * T * 240.0 - ny * 9.0 + fine * 6.0);

    vec3 col = hue * curt * AURORA_STRENGTH;

    // ── Aurora bleeding off the rift edge ───────────────────────────────────
    col += BLEED_COLOR * exp(-outD * 2.6) * (0.50 + 0.90 * rays) * 0.22;

    // ── Stars + nadir star ──────────────────────────────────────────────────
    col += skyStars(nd) * smoothstep(-0.75, -0.50, ny);
    col += nadirStar(nd);

    // ── Rift rim: dark magenta, ragged, brightest right at the edge ─────────
    float edgeN = 0.55 + 0.90 * vnoise(vec3(p * 8.0, T * 200.0), 200);
    float tight = exp(-outD * 16.0);
    float wide  = exp(-outD *  4.0);
    vec3 rim = RIM_COLOR * (tight * 0.95 * edgeN + wide * 0.12)
             + RIM_HOT   * pow(tight, 4.0) * 0.22 * edgeN;
    col += rim * (1.0 - inside);

    // ── Rift interior ───────────────────────────────────────────────────────
    if (inside > 0.001) col = mix(col, riftInterior(p, d), inside);

    return vec4(clamp(col, 0.0, 1.0), 1.0);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MAIN
// ═══════════════════════════════════════════════════════════════════════════════

void main() {
    if (isEndSky > 0.5) {
        fragColor = endSkyColor(skyDir);
        // tiny dither so the very dark aurora gradients don't band in 8-bit
        fragColor.rgb += (fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715)))) - 0.5) / 255.0;
        fragColor.a *= ColorModulator.a;
    } else {
        vec4 color = texture(Sampler0, texCoord0) * vertexColor;
        if (color.a == 0.0) discard;
        fragColor = color * ColorModulator;
        fragColor.rgb = cone_filter(Colorblindness, fragColor.rgb);
    }
}
