shader_type spatial;
render_mode specular_toon;

uniform vec3 water_base : source_color = vec3(0.22, 0.52, 0.60);
uniform vec3 water_dark : source_color = vec3(0.15, 0.42, 0.52);
uniform vec3 water_highlight : source_color = vec3(0.45, 0.70, 0.78);

uniform float wave_speed : hint_range(0.0, 1.0) = 0.25;
uniform float line_frequency : hint_range(5.0, 30.0) = 12.0;
uniform float line_sharpness : hint_range(0.01, 0.2) = 0.06;

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 uv = world_pos.xz;
    
    // Líneas paralelas simples que se mueven
    float wave1 = sin(uv.y * line_frequency - TIME * wave_speed * 5.0);
    float wave2 = sin(uv.y * line_frequency * 0.7 + 2.0 - TIME * wave_speed * 4.0);
    
    // Convertir a líneas finas
    float line1 = smoothstep(1.0 - line_sharpness, 1.0, wave1);
    float line2 = smoothstep(1.0 - line_sharpness * 0.7, 1.0, wave2) * 0.5;
    
    // Variación base sutil
    float depth_var = sin(uv.x * 0.5 + uv.y * 0.3) * 0.5 + 0.5;
    vec3 base = mix(water_dark, water_base, depth_var * 0.3 + 0.7);
    
    // Aplicar líneas como highlights
    float lines = clamp(line1 + line2, 0.0, 1.0);
    vec3 color = mix(base, water_highlight, lines * 0.6);
    
    ALBEDO = color;
    ROUGHNESS = 0.25;
    SPECULAR = 0.5;
}