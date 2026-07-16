shader_type canvas_item;

uniform vec2 scroll_direction = vec2(1.0, 0.0);
uniform float scroll_speed : hint_range(0.0, 100.0) = 10.0;

uniform float wind_strength : hint_range(0.0, 0.2) = 0.03;
uniform float wind_speed : hint_range(0.0, 5.0) = 0.8;
uniform float wind_frequency : hint_range(0.0, 10.0) = 3.0;
uniform float phase_offset = 0.0;

void fragment() {
	vec2 offset = scroll_direction * scroll_speed * 0.001 * TIME;

	vec2 wind_direction = vec2(-scroll_direction.y, scroll_direction.x);

	float wind = sin(
		TIME * wind_speed +
		UV.y * wind_frequency +
		phase_offset
	);

	offset += wind_direction * wind * wind_strength;

	vec2 scrolled_uv = fract(UV + offset);

	COLOR = texture(TEXTURE, scrolled_uv);
}