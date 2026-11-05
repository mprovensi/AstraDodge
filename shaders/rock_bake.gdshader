shader_type canvas_item;
// SÓ PARA GERAR IMAGENS (tools/bake_rocks.gd) — não é usado durante o jogo.
// Asteroide ESTILIZADO girando em 3D: esfera irregular com 3 tons chapados (claro/médio/escuro),
// crateras simples, contorno escuro e borda de luz. `spin` (0..1) é a volta do giro: a ferramenta
// fotografa vários valores e monta a folha de quadros. Borda suave (alfa), sem recorte duro.

uniform vec3 c_light : source_color = vec3(0.80, 0.80, 0.84);
uniform vec3 c_mid : source_color = vec3(0.55, 0.55, 0.60);
uniform vec3 c_dark : source_color = vec3(0.30, 0.30, 0.35);
uniform vec3 c_outline : source_color = vec3(0.10, 0.10, 0.13);
uniform vec3 c_rim : source_color = vec3(0.95, 0.96, 1.0);
uniform vec3 c_glow : source_color = vec3(1.0, 0.5, 0.1);  // veios (cristal, vulcânico)
uniform float glow = 0.0;
uniform float craters = 0.6;
uniform float lumpiness = 0.11;   // irregularidade da silhueta (o teste confere a colisão)
uniform float seed = 0.0;
uniform float spin = 0.0;         // 0..1 = uma volta completa
uniform float tilt = 0.5;         // inclinação do eixo de giro
uniform float fill = 0.92;        // fração do raio da imagem ocupada (casa com ArtSet.dust_fill)

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
	vec2 p = (UV - 0.5) * 2.0 / fill;
	float ang = atan(p.y, p.x);
	// Silhueta: irregular mas suave, e gira junto (o contorno muda com o giro 3D).
	vec3 dir = rot(spin * 6.2831853, tilt) * vec3(cos(ang), sin(ang), 0.0);
	float edge = 1.0 - lumpiness * (0.7 * noise3(dir * 1.4 + seed) + 0.3 * noise3(dir * 3.5 + seed + 4.0));
	float r = length(p) / edge;
	float aa = fwidth(r) * 1.5;
	float alpha = 1.0 - smoothstep(1.0 - aa, 1.0, r);
	if (alpha <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		vec3 n = normalize(vec3(p / edge, sqrt(max(0.0, 1.0 - min(r, 1.0) * min(r, 1.0)))));
		vec3 s = rot(spin * 6.2831853, tilt) * n * 1.8 + seed * 3.0;
		float cr = crater_field(s * 1.2);
		float crater = craters * step(cr, 0.32);
		float crater_lip = craters * step(0.32, cr) * step(cr, 0.4);
		vec3 l = normalize(vec3(-0.55, -0.65, 0.55));
		float diff = dot(n, l) + (noise3(s * 1.3) - 0.5) * 0.25 - crater * 0.35 + crater_lip * 0.15;
		// Tons chapados.
		vec3 col = diff > 0.45 ? c_light : (diff > 0.05 ? c_mid : c_dark);
		// Borda de luz fina no lado iluminado.
		float rim = step(0.86, r) * step(0.25, dot(normalize(p), normalize(l.xy)));
		col = mix(col, c_rim, rim * 0.8);
		// Veios brilhantes (cristalino/vulcânico).
		col = mix(col, c_glow, glow * step(abs(noise3(s * 2.4) - 0.5), 0.03));
		// Contorno escuro na borda da silhueta.
		col = mix(col, c_outline, smoothstep(0.9, 0.97, r));
		COLOR = vec4(col, alpha);
	}
}
