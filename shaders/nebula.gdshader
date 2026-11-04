shader_type canvas_item;
// Nebulosa procedural (ruído fBm) que rola devagar atrás das estrelas.
// Escura de propósito: dá profundidade sem competir com a jogabilidade.

uniform vec4 color_a : source_color = vec4(0.06, 0.10, 0.32, 1.0);
uniform vec4 color_b : source_color = vec4(0.16, 0.04, 0.28, 1.0);
uniform float intensity = 0.85;
uniform float scroll = 0.0;          // avanço vertical (atualizado pelo script)
uniform vec2 aspect = vec2(1.0, 2.2); // proporção da tela (largura, altura)

// Hash sem seno (estável em GPU de celular, sem "blocos").
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));  // gira cada camada: esconde a grade
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = rot * p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = UV * aspect * 1.6 + vec2(0.0, -scroll);
	float n = fbm(p + vec2(TIME * 0.008, 0.0));
	float tint = noise(p * 0.6 + vec2(4.0, -TIME * 0.004));
	float cloud = smoothstep(0.3, 0.85, n);
	vec3 col = mix(color_a.rgb, color_b.rgb, tint) * cloud * intensity;
	COLOR = vec4(col, 1.0);
}
