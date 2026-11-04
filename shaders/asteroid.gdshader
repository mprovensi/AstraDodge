shader_type canvas_item;
// Asteroide "2.5D" (PLANO_ARTE_25D.md, técnica A): um quadrado vira uma esfera irregular,
// iluminada, que gira em 3D. Superfície por ruído 3D (crateras, relevo, veios), material por tipo.
// O quadrado desenhado tem o tamanho da rocha; UV 0..1.

uniform vec3 color_light : source_color = vec3(0.72, 0.72, 0.76);
uniform vec3 color_dark : source_color = vec3(0.25, 0.25, 0.29);
uniform vec3 rim_color : source_color = vec3(0.85, 0.88, 1.0);
uniform vec3 emission_color : source_color = vec3(1.0, 0.45, 0.1);
uniform float emission = 0.0;        // veios brilhantes (cristal, vulcânico)
uniform float craters = 0.6;         // quantidade de crateras
uniform float bumpiness = 0.5;       // relevo
uniform float porosity = 0.0;        // furinhos (pedra-pomes)
uniform float specular = 0.0;        // brilho de metal/gelo
uniform float translucency = 0.0;    // gelo: miolo mais claro
uniform float lumpiness = 0.22;      // irregularidade da borda
uniform float seed = 0.0;
uniform float spin = 0.4;            // velocidade de giro
uniform vec3 light_dir = vec3(-0.55, -0.65, 0.55);

float hash3(vec3 p) {
	p = fract(p * vec3(443.897, 441.423, 437.195));
	p += dot(p, p.yzx + 19.19);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash3(i);
	float n100 = hash3(i + vec3(1, 0, 0));
	float n010 = hash3(i + vec3(0, 1, 0));
	float n110 = hash3(i + vec3(1, 1, 0));
	float n001 = hash3(i + vec3(0, 0, 1));
	float n101 = hash3(i + vec3(1, 0, 1));
	float n011 = hash3(i + vec3(0, 1, 1));
	float n111 = hash3(i + vec3(1, 1, 1));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
			mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
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

// Crateras: distância ao "centro" mais próximo numa grade 3D (células).
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

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float ang = atan(p.y, p.x);
	// Borda irregular (silhueta de rocha, não um círculo).
	float edge = 1.0 - lumpiness * (fbm(vec3(cos(ang) * 1.3, sin(ang) * 1.3, seed)) * 1.2 + 0.25 * noise3(vec3(cos(ang) * 4.0, sin(ang) * 4.0, seed + 5.0)));
	edge *= 1.0 - 0.12 * lumpiness * 4.0 * (0.5 + 0.5 * cos(2.0 * ang + seed * 3.0));  // levemente alongado
	float r = length(p) / edge;
	if (r > 1.0) {
		discard;
	}
	vec3 n = normalize(vec3(p / edge, sqrt(max(0.0, 1.0 - r * r))));
	// Ponto na superfície girando em 3D.
	vec3 s = rot(TIME * spin + seed, 0.6 + seed * 0.3) * n * 2.2 + seed * 3.0;
	float h = fbm(s * 1.4);
	float cr = crater_field(s * 1.1);
	float crater = craters * smoothstep(0.45, 0.12, cr);
	float crater_rim = craters * smoothstep(0.38, 0.45, cr) * smoothstep(0.55, 0.45, cr);
	float pores = porosity * step(0.82, noise3(s * 9.0));
	// Relevo: perturba a normal pelo gradiente aproximado do "terreno".
	float e = 0.08;
	float hx = fbm((s + vec3(e, 0, 0)) * 1.4) - h;
	float hy = fbm((s + vec3(0, e, 0)) * 1.4) - h;
	vec3 nb = normalize(n - bumpiness * vec3(hx, hy, 0.0) * 9.0);
	vec3 l = normalize(light_dir);
	float diff = clamp(dot(nb, l), 0.0, 1.0);
	float shade = 0.18 + 0.82 * diff;
	vec3 albedo = mix(color_dark, color_light, clamp(h * 1.3 - crater * 0.8 + crater_rim * 0.5 - pores, 0.0, 1.0));
	vec3 col = albedo * shade;
	// Especular (metal, gelo).
	vec3 hv = normalize(l + vec3(0, 0, 1));
	col += specular * pow(clamp(dot(nb, hv), 0.0, 1.0), 24.0) * vec3(1.0);
	// Gelo: luz atravessando o miolo.
	col += translucency * (1.0 - r) * color_light * 0.5;
	// Borda iluminada (contorno que ajuda a ler a forma no fundo escuro).
	float rim = smoothstep(0.75, 1.0, r) * (0.35 + 0.65 * clamp(dot(n.xy, -l.xy), 0.0, 1.0));
	col += rim * rim_color * 0.55;
	// Veios brilhantes (emissivos: passam do limiar do glow HDR).
	float vein = smoothstep(0.035, 0.0, abs(noise3(s * 2.6) - 0.5)) * emission;
	col += vein * emission_color * 2.5;
	COLOR = vec4(col, 1.0);
}
