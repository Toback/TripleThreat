shader_type canvas_item;

uniform float strength : hint_range(0.0, 20.0) = 4.0;
uniform float vertical_strength : hint_range(0.0, 5.0) = 0.5;
uniform float speed : hint_range(0.0, 5.0) = 0.8;
uniform float frequency : hint_range(0.0, 10.0) = 2.0;
uniform float phase_offset = 0.0;

uniform float updates_per_second : hint_range(1.0, 60.0) = 12.0;

void vertex() {
	// Make the animation update in discrete steps
	float t = floor(TIME * updates_per_second) / updates_per_second;

	// Slightly more movement toward the top of the leaves
	float weight = mix(1.0, 1.3, 1.0 - UV.y);

	// Single horizontal wind wave
	float horizontal = sin(
		t * speed +
		VERTEX.y * 0.03 * frequency +
		phase_offset
	);

	// Gentle vertical floating motion
	float vertical =
		sin(
			t * speed * 0.8 +
			phase_offset
		) * 0.6
		+
		sin(
			t * speed * 1.3 +
			phase_offset * 1.7
		) * 0.4;

	VERTEX.x += horizontal * strength * weight;
	VERTEX.y += vertical * vertical_strength * weight;
}