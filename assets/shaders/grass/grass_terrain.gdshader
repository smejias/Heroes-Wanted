shader_type spatial;

uniform vec3 grass_color : source_color = vec3(0.32, 0.58, 0.22);
uniform vec3 grass_color_alt : source_color = vec3(0.28, 0.52, 0.20);
uniform vec3 wind_highlight : source_color = vec3(0.48, 0.72, 0.35);
uniform float wind_speed : hint_range(0.0, 2.0) = 0.8;
uniform float wind_strength : hint_range(0.0, 1.0) = 0.25;
uniform vec2 wind_direction = vec2(1.0, 0.3);
uniform float grass_line_strength : hint_range(0.0, 0.15) = 0.06;

// Contact shadow
uniform vec3 building_position = vec3(0.0);
uniform float ao_radius : hint_range(0.0, 2.0) = 0.6;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.4;

varying vec3 world_pos;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(269.5, 183.3))) * 43758.5453);
}

float streak(vec2 uv, float t, float offset, float freq) {
    vec2 dir = normalize(wind_direction);
    
    // Distorsión orgánica
    float warp = sin(uv.y * 2.0 + t * 0.5) * 0.2;
    uv.x += warp;
    
    float d = dot(uv, dir);
    float wave = sin(d * freq - t * wind_speed + offset);
    return smoothstep(0.3, 0.9, wave);
}

float grass_stroke(vec2 uv, float seed) {
    // Curvas más pronunciadas y variables
    float curve1 = sin(uv.y * 6.0 + seed * 10.0) * 0.25;
    float curve2 = sin(uv.y * 11.0 + seed * 7.0) * 0.1;
    float x = uv.x + curve1 + curve2;
    
    // Grosor variable
    float thickness = 0.92 + hash(vec2(seed)) * 0.05;
    float line = sin(x * 45.0 + seed * 20.0);
    line = smoothstep(thickness, 1.0, line);
    
    // Trazos cortos e irregulares
    float seg = floor(uv.y * 8.0 + seed * 5.0);
    float visible = step(0.6, hash(vec2(seg, seed)));
    
    return line * visible;
}

float grass_lines(vec2 uv) {
    float lines = 0.0;
    
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float angle = 0.3 + fi * 0.15 + hash(vec2(fi)) * 0.2;
        
        vec2 ruv = vec2(
            uv.x * cos(angle) - uv.y * sin(angle),
            uv.x * sin(angle) + uv.y * cos(angle)
        );
        
        float scale = 0.8 + hash(vec2(fi + 10.0)) * 0.5;
        float offset = hash(vec2(fi + 20.0)) * 10.0;
        
        lines += grass_stroke(ruv * scale + offset, fi) * (0.7 + 0.3 * hash(vec2(fi)));
    }
    
    return clamp(lines, 0.0, 1.0) * grass_line_strength;
}

float color_variation(vec2 uv) {
    float v = sin(uv.x * 0.8) * sin(uv.y * 0.6) * 0.5 + 0.5;
    return v;
}

float contact_ao(vec3 pos) {
    float dist = length(pos.xz - building_position.xz);
    float ao = smoothstep(0.0, ao_radius, dist);
    return mix(1.0 - ao_strength, 1.0, ao);
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 uv = world_pos.xz;
    
    float variation = color_variation(uv);
    vec3 base_color = mix(grass_color_alt, grass_color, variation);
    
    float s1 = streak(uv, TIME, 0.0, 3.0);
    float s2 = streak(uv, TIME * 1.2, 2.5, 4.0) * 0.6;
    float s3 = streak(uv, TIME * 0.8, 4.0, 2.2) * 0.4;
    float wind = (s1 + s2 + s3) / 2.5 * wind_strength;
    
    float lines = grass_lines(uv);
    
    vec3 color = mix(base_color, wind_highlight, wind);
    color = mix(color, color * 0.85, lines);
    
    // Aplicar AO de contacto
    color *= contact_ao(world_pos);
    
    ALBEDO = color;
    ROUGHNESS = 0.85;
}