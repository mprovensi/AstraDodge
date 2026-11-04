class_name FxLayer
extends Node2D
## Partículas simples desenhadas à mão (explosões, faíscas, coletas).

const MAX_PARTICLES := 700

class Particle:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var life := 0.0
	var max_life := 1.0
	var size := 4.0
	var color := Color.WHITE

var _particles: Array[Particle] = []


func burst(pos: Vector2, color: Color, count: int, speed: float, life: float, size: float) -> void:
	for i in count:
		if _particles.size() >= MAX_PARTICLES:
			return
		var p := Particle.new()
		p.pos = pos
		p.vel = Vector2.from_angle(randf() * TAU) * speed * randf_range(0.3, 1.0)
		p.max_life = life * randf_range(0.6, 1.0)
		p.life = p.max_life
		p.size = size * randf_range(0.6, 1.2)
		p.color = color
		_particles.append(p)


func explosion(pos: Vector2, radius: float, color: Color) -> void:
	burst(pos, color, 10 + int(radius / 5.0), 300.0 + radius * 3.0, 0.55, 6.0)
	burst(pos, Color(1.0, 0.9, 0.7), 6 + int(radius / 12.0), 200.0 + radius * 2.0, 0.3, 8.0)


func spark(pos: Vector2, color: Color) -> void:
	burst(pos, color, 4, 260.0, 0.18, 3.0)


func clear() -> void:
	_particles.clear()
	queue_redraw()


func update(dt: float) -> void:
	var damp := exp(-3.0 * dt)
	for p in _particles:
		p.pos += p.vel * dt
		p.vel *= damp
		p.life -= dt
	for i in range(_particles.size() - 1, -1, -1):
		if _particles[i].life <= 0.0:
			_particles.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for p in _particles:
		var k := p.life / p.max_life
		draw_circle(p.pos, p.size * (0.4 + 0.6 * k), Color(p.color, k))
