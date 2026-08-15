shader_type canvas_item;
render_mode unshaded;

uniform float background_cut : hint_range(0.0, 0.3) = 0.065;
uniform float background_softness : hint_range(0.01, 0.3) = 0.085;
uniform float edge_fade_start : hint_range(0.2, 0.7) = 0.43;
uniform float edge_fade_end : hint_range(0.3, 0.8) = 0.56;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 centered = UV - vec2(0.5);
	float radius = length(centered);
	float sample_radius = max(radius, 0.47);
	vec2 diagonal = normalize(vec2(1.0));
	vec3 corner_a = texture(TEXTURE, vec2(0.5) + diagonal * sample_radius).rgb;
	vec3 corner_b = texture(TEXTURE, vec2(0.5) + vec2(-diagonal.x, diagonal.y) * sample_radius).rgb;
	vec3 corner_c = texture(TEXTURE, vec2(0.5) + vec2(diagonal.x, -diagonal.y) * sample_radius).rgb;
	vec3 corner_d = texture(TEXTURE, vec2(0.5) - diagonal * sample_radius).rgb;
	vec3 estimated_background = min(min(corner_a, corner_b), min(corner_c, corner_d));
	float separation = distance(source.rgb, estimated_background);
	float subject_alpha = smoothstep(background_cut, background_cut + background_softness, separation);
	float luminance = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
	subject_alpha = max(subject_alpha, smoothstep(0.26, 0.52, luminance));
	float edge_alpha = 1.0 - smoothstep(edge_fade_start, edge_fade_end, radius);
	COLOR = vec4(source.rgb, source.a * subject_alpha * edge_alpha);
}
