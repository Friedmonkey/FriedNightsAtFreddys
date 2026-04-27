shader_type spatial;

//snowy mountains shader
//holy fucking shit, ts is ass
//i couldnt get this to work and spent over like 2 hours on this
//1000% ai slop
//but atleast we have crappy snowy mountains

render_mode blend_mix, depth_draw_always, cull_back;

varying vec3 world_pos;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {

    float h = world_pos.y;

    // ------------------------
    // HALVED SPACING (was 40 / 45 / 50)
    // ------------------------
    // now compressed range
    float line1 = 42.0;
    float line2 = 44.0;
    float line3 = 46.0; // NEW LINE
    float line4 = 48.0; // shifted hard cap (was 50)

    // ------------------------
    // BASE SNOW (light)
    // ------------------------
    float base = step(line1, h);

    float n1 = noise(world_pos.xz * 0.15);
    float mask1 = base * smoothstep(0.3, 0.7, n1);

    // ------------------------
    // SECOND SNOW BAND
    // ------------------------
    float band2 = step(line2, h);

    float n2 = noise(world_pos.xz * 0.25);
    float mask2 = band2 * smoothstep(0.2, 0.8, n2);

    // ------------------------
    // NEW THIRD SNOW BAND (ADDED)
    // ------------------------
    float band3 = step(line3, h);

    float n3 = noise(world_pos.xz * 0.18);
    float mask3 = band3 * smoothstep(0.25, 0.75, n3);

    // ------------------------
    // HARD FULL SNOW CAP (still exists, just moved down)
    // ------------------------
    float hard_cap = step(line4, h);

    // ------------------------
    // COMBINE (UNCHANGED LOGIC)
    // ------------------------
    float mask = max(mask1, mask2);
    mask = max(mask, mask3);
    mask = max(mask, hard_cap);

    ALBEDO = vec3(1.0);
    ALPHA = mask;
}