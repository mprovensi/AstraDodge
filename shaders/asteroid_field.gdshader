shader_type canvas_item;
// Asteroides 2.5D do jogo (PLANO_ARTE_25D.md, A1). Cada rocha é um quadrado desenhado pelo
// AsteroidField com uma textura branca 1x1 (UV 0..1); a COR do vértice traz os dados da rocha:
//   r = material (índice / 8), g = semente (forma e superfície), b = brilho (dano/flash).
// A silhueta é irregular, mas nunca menor que EDGE_MIN do quadrado (ver AsteroidField.DRAW_SCALE:
// a colisão fica sempre dentro do desenho).

const float LUMP = 0.12;

uniform vec3 m_light[7];
uniform vec3 m_dark[7];
uniform vec3 m_rim[7];
uniform vec3 m_emission_color[7];
uniform vec4 m_p1[7];   // crateras, relevo, poros, especular
uniform vec4 m_p2[7];   // translucidez, emissão
uniform vec3 light_dir = vec3(-0.55, -0.65, 0.55);

varying flat vec4 rock;

float hash3(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x),
			mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x),
			mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise3(p);
		p = p * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return v;
}

float crater_field(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float best = 1.0;
	for (int x = -1; x <= 1; x++)
	for (int y = -1; y <= 1; y++)
	for (int z = -1; z <= 1; z++) {
		vec3 c = vec3(float(x), float(y), float(z));
		vec3 o = vec3(hash3(i + c), hash3(i + c + 7.1), hash3(i + c + 13.7));
		best = min(best, length(c + o - f));
	}
	return best;
}

mat3 rot(float a, float b) {
	float ca = cos(a), sa = sin(a), cb = cos(b), sb = sin(b);
	return mat3(vec3(ca, 0.0, -sa), vec3(0.0, 1.0, 0.0), vec3(sa, 0.0, ca))
			* mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, cb, sb), vec3(0.0, -sb, cb));
}

void vertex() {
	rock = COLOR;
}

void fragment() {
	int m = clamp(int(rock.r * 8.0 + 0.5), 0, 6);
	float seed = rock.g * 37.0;
	float bright = rock.b * 4.0;  // 1 = normal; < 1 com dano; > 1 piscando ao levar tiro
	vec2 p = (UV - 0.5) * 2.0;
	float ang = atan(p.y, p.x);
	float bump = fbm(vec3(cos(ang) * 1.3, sin(ang) * 1.3, seed)) * 1.2
			+ 0.25 * noise3(vec3(cos(ang) * 4.0, sin(ang) * 4.0, seed + 5.0));
	float edge = (1.0 - LUMP * bump) * (1.0 - 0.48 * LUMP * (0.5 + 0.5 * cos(2.0 * ang + seed * 3.0)));
	float r = length(p) / edge;
	if (r > 1.0) {
		discard;
	}
	vec4 p1 = m_p1[m];
	vec4 p2 = m_p2[m];
	vec3 n = normalize(vec3(p / edge, sqrt(max(0.0, 1.0 - r * r))));
	vec3 s = rot(TIME * (0.25 + 0.3 * fract(seed)) + seed, 0.6 + seed * 0.3) * n * 2.2 + seed * 3.0;
	float h = fbm(s * 1.4);
	float cr = crater_field(s * 1.1);
	float crater = p1.x * smoothstep(0.45, 0.12, cr);
	float crater_rim = p1.x * smoothstep(0.38, 0.45, cr) * smoothstep(0.55, 0.45, cr);
	float pores = p1.z * step(0.82, noise3(s * 9.0));
	float e = 0.08;
	float hx = fbm((s + vec3(e, 0, 0)) * 1.4) - h;
	float hy = fbm((s + vec3(0, e, 0)) * 1.4) - h;
	vec3 nb = normalize(n - p1.y * vec3(hx, hy, 0.0) * 9.0);
	vec3 l = normalize(light_dir);
	float diff = clamp(dot(nb, l), 0.0, 1.0);
	vec3 albedo = mix(m_dark[m], m_light[m], clamp(h * 1.3 - crater * 0.8 + crater_rim * 0.5 - pores, 0.0, 1.0));
	vec3 col = albedo * (0.3 + 0.75 * diff);
	vec3 hv = normalize(l + vec3(0, 0, 1));
	col += p1.w * pow(clamp(dot(nb, hv), 0.0, 1.0), 24.0) * vec3(1.0);
	col += p2.x * (1.0 - r) * m_light[m] * 0.5;
	float rim = smoothstep(0.75, 1.0, r) * (0.35 + 0.65 * clamp(dot(n.xy, -l.xy), 0.0, 1.0));
	col += rim * m_rim[m] * 0.55;
	float vein = smoothstep(0.035, 0.0, abs(noise3(s * 2.6) - 0.5)) * p2.y;
	col += vein * m_emission_color[m] * 2.5;
	COLOR = vec4(col * bright, 1.0);
}
