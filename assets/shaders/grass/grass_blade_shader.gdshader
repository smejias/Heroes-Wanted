shader_type spatial;
render_mode cull_disabled, shadows_disabled;

uniform sampler2D noise_tex : hint_default_white;
uniform vec3 color_base : source_color = vec3(0.15, 0.4, 0.1);
uniform vec3 color_tip : source_color = vec3(0.4, 0.75, 0.2);
uniform vec2 wind_direction = vec2(1.0, 0.5);
uniform float wind_speed : hint_range(0.0, 0.1) = 0.02;
uniform float sway_strength : hint_range(0.0, 5.0) = 2.0;

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float noise = texture(noise_tex, world_pos.xz * 0.1 + TIME * wind_speed).r;
    
    float sway_factor = 1.0 - UV.y;
    vec2 wind = normalize(wind_direction) * sin(TIME * 2.0 + noise * 6.0) * sway_strength;
    
    VERTEX.xz += wind * sway_factor * 0.05;
}

void fragment() {
    vec3 color = mix(color_base, color_tip, 1.0 - UV.y);
    ALBEDO = color;
    ROUGHNESS = 0.9;
}