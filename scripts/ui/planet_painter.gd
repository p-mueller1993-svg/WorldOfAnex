class_name PlanetPainter
extends RefCounted
## Zeichenhilfen für Planeten, Monde und Sonnen – prozedural, ohne Texturen.
## Ein Planet ist ein Dictionary mit mindestens "name", "color" und "detail" (optional "glow", "blobs").

const SEGMENTS := 40
const LIGHT := Vector2(-0.55, -0.83)


static func draw_planet(ci: CanvasItem, pos: Vector2, radius: float, p: Dictionary) -> void:
	if radius < 0.5:
		return
	var detail: Color = p.detail
	if p.has("glow"):
		var glow: Color = p.glow
		ci.draw_circle(pos, radius * 1.14, Color(glow, 0.08), true, -1.0, true)
		ci.draw_circle(pos, radius * 1.06, Color(glow, 0.18), true, -1.0, true)
	ci.draw_circle(pos, radius, p.color, true, -1.0, true)

	# Oberflächenflecken, deterministisch pro Planetenname
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p.name)
	for i in int(p.get("blobs", 9)):
		var br := radius * rng.randf_range(0.12, 0.34)
		var dir := Vector2.from_angle(rng.randf() * TAU)
		var dist := sqrt(rng.randf()) * (radius - br)
		ci.draw_circle(pos + dir * dist, br, Color(detail, rng.randf_range(0.45, 0.9)), true, -1.0, true)

	# Schattierung: zur Lichtquelle hin transparent, auf der Rückseite dunkel
	var light := LIGHT.normalized()
	var center_shade := _shade(Vector2.ZERO, light)
	var prev := Vector2.RIGHT
	for i in range(1, SEGMENTS + 1):
		var d := Vector2.from_angle(TAU * i / SEGMENTS)
		ci.draw_polygon(
			PackedVector2Array([pos, pos + prev * radius, pos + d * radius]),
			PackedColorArray([center_shade, _shade(prev, light), _shade(d, light)]))
		prev = d
	ci.draw_circle(pos + light * radius * 0.42, radius * 0.32, Color(1, 1, 1, 0.07), true, -1.0, true)
	ci.draw_arc(pos, radius, 0, TAU, SEGMENTS, Color(1, 1, 1, 0.12), 1.0, true)


static func draw_sun(ci: CanvasItem, pos: Vector2, radius: float) -> void:
	for i in range(6, 0, -1):
		ci.draw_circle(pos, radius * (1.0 + i * 0.45), Color(1.0, 0.55, 0.15, 0.035), true, -1.0, true)
	ci.draw_circle(pos, radius, Color(1.0, 0.72, 0.2), true, -1.0, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 10:
		var br := radius * rng.randf_range(0.15, 0.35)
		var dist := sqrt(rng.randf()) * (radius - br)
		ci.draw_circle(pos + Vector2.from_angle(rng.randf() * TAU) * dist, br, Color(1.0, 0.92, 0.5, 0.45), true, -1.0, true)
	ci.draw_circle(pos, radius * 0.55, Color(1.0, 1.0, 0.85, 0.35), true, -1.0, true)


static func _shade(dir: Vector2, light: Vector2) -> Color:
	return Color(0, 0, 0, clampf(0.3 - 0.5 * dir.dot(light), 0.0, 0.8))
