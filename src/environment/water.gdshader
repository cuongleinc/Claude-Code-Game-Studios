shader_type spatial;
render_mode specular_schlick_ggx, depth_draw_opaque;

uniform vec4 shallow_color : source_color = vec4(0.18, 0.68, 0.78, 0.95);
uniform vec4 deep_color : source_color = vec4(0.05, 0.22, 0.42, 1.0);
uniform float wave_speed : hint_range(0.1, 5.0) = 1.2;
uniform float wave_frequency : hint_range(0.1, 10.0) = 0.8;
uniform float wave_amplitude : hint_range(0.0, 1.0) = 0.18;

void vertex() {
	float wave1 = sin(VERTEX.x * wave_frequency + TIME * wave_speed) * cos(VERTEX.z * wave_frequency * 0.7 + TIME * wave_speed * 0.8);
	float wave2 = cos(VERTEX.x * wave_frequency * 1.5 - TIME * wave_speed * 1.2) * sin(VERTEX.z * wave_frequency * 1.2 + TIME * wave_speed * 0.9);
	VERTEX.y += (wave1 + wave2) * wave_amplitude;
}

void fragment() {
	float wave_fac = (sin(UV.x * 20.0 + TIME * wave_speed) + cos(UV.y * 20.0 + TIME * wave_speed)) * 0.5;
	vec3 color = mix(deep_color.rgb, shallow_color.rgb, wave_fac * 0.3 + 0.5);
	ALBEDO = color;
	ROUGHNESS = 0.15;
	METALLIC = 0.1;
	SPECULAR = 0.6;
}
