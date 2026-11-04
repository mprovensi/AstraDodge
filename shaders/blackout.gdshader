shader_type canvas_item;
// Blecaute (Setor 7): escurece a tela, menos um círculo de luz em volta da nave.
uniform vec2 light_pos = vec2(540.0, 1500.0);
uniform float light_radius = 430.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.0;

varying vec2 world_pos;

void vertex() {
	world_pos = VERTEX;
}

void fragment() {
	float d = distance(world_pos, light_pos);
	float shade = smoothstep(light_radius * 0.55, light_radius, d);
	COLOR = vec4(0.0, 0.0, 0.01, darkness * shade);
}
