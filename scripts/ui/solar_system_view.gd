class_name SolarSystemView
extends Control
## Zeichnet ein Sonnensystem mit animierten, perspektivisch gekippten Umlaufbahnen.
## Planeten sind anklickbar; die Auswahl wird über planet_selected gemeldet.

signal planet_selected(planet: Dictionary)

const ORBIT_TILT := 0.42
## Spielsekunden pro Echtsekunde für die Bahnanimation
const TIME_SCALE := 400.0

var planets: Array[Dictionary] = []:
	set(value):
		planets = value
		queue_redraw()

var _moon := {"name": "moon", "color": Color(0.62, 0.62, 0.64), "detail": Color(0.36, 0.36, 0.4), "blobs": 5}
var _selected := ""
var _time := 0.0
var _stars: Array[Dictionary] = []
var _nebula: Array[Dictionary] = []
## Bildschirmpositionen aus dem letzten Frame, sortiert von hinten nach vorne (für Hit-Tests)
var _bodies: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	var rng := RandomNumberGenerator.new()
	rng.seed = 4711
	for i in 280:
		_stars.append({
			"pos": Vector2(rng.randf(), rng.randf()), "r": rng.randf_range(0.4, 1.4),
			"a": rng.randf_range(0.25, 0.9), "speed": rng.randf_range(0.5, 2.5), "phase": rng.randf() * TAU,
		})
	var tints := [Color(0.18, 0.3, 0.85, 0.07), Color(0.5, 0.2, 0.75, 0.06), Color(0.1, 0.45, 0.8, 0.06)]
	for i in 36:
		_nebula.append({
			"pos": Vector2(rng.randf_range(0.1, 0.6), rng.randf()), "r": rng.randf_range(0.04, 0.16),
			"color": tints[i % tints.size()],
		})
	# helle Gaswolke auf der rechten Seite
	for i in 22:
		_nebula.append({
			"pos": Vector2(rng.randf_range(0.6, 0.85), rng.randf_range(0.2, 0.75)), "r": rng.randf_range(0.04, 0.12),
			"color": Color(0.75, 0.82, 0.95, 0.06),
		})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func select(planet_name: String) -> void:
	for p in planets:
		if p.name == planet_name:
			_selected = planet_name
			planet_selected.emit(p)
			queue_redraw()
			return


func clear_selection() -> void:
	_selected = ""
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("050816"))
	# Nebel als weiche Flecken: mehrere konzentrische Kreise mit wenig Deckkraft
	for n in _nebula:
		var tint: Color = n.color
		for k in 6:
			draw_circle(n.pos * size, n.r * size.x * (1.0 - k * 0.15), Color(tint, tint.a * 0.4))
	for s in _stars:
		var alpha: float = s.a * (0.65 + 0.35 * sin(_time * s.speed + s.phase))
		draw_circle(s.pos * size, s.r, Color(0.85, 0.9, 1.0, alpha))

	var center := size * 0.5
	var max_orbit := 1.0
	for p in planets:
		max_orbit = maxf(max_orbit, p.orbit)
	var rx_max := minf(size.x * 0.5 - 60.0, (size.y * 0.5 - 50.0) / ORBIT_TILT)
	var body_scale := clampf(size.x / 1000.0, 0.55, 1.3)

	_bodies.clear()
	for p in planets:
		var rx: float = p.orbit / max_orbit * rx_max
		_draw_ellipse(center, rx, rx * ORBIT_TILT, Color(0.55, 0.7, 1.0, 0.2))
		var angle: float = p.phase + _time * TIME_SCALE * TAU / p.period
		var pos := center + Vector2(cos(angle) * rx, sin(angle) * rx * ORBIT_TILT)
		# Planeten im Vordergrund (unten) etwas größer zeichnen
		var depth := 0.85 + 0.15 * (sin(angle) + 1.0)
		_bodies.append({"planet": p, "pos": pos, "radius": p.size * body_scale * depth})
	_bodies.append({"planet": {}, "pos": center, "radius": 28.0 * body_scale})
	_bodies.sort_custom(func(a, b): return a.pos.y < b.pos.y)

	for b in _bodies:
		if b.planet.is_empty():
			PlanetPainter.draw_sun(self, b.pos, b.radius)
		else:
			_draw_planet_with_moons(b.planet, b.pos, b.radius)
	for b in _bodies:
		if not b.planet.is_empty() and b.planet.name == _selected:
			_draw_selection(b.planet, b.pos, b.radius)


func _draw_planet_with_moons(p: Dictionary, pos: Vector2, r: float) -> void:
	var front: Array = []
	for i in int(p.get("moons", 0)):
		var a := _time * (0.6 + 0.25 * i) + i * 2.1
		var moon := [pos + Vector2(cos(a) * r * 1.45, sin(a) * r * 0.45), r * (0.2 - 0.03 * i)]
		if sin(a) < 0.0:
			PlanetPainter.draw_planet(self, moon[0], moon[1], _moon)
		else:
			front.append(moon)
	PlanetPainter.draw_planet(self, pos, r, p)
	for moon in front:
		PlanetPainter.draw_planet(self, moon[0], moon[1], _moon)


func _draw_selection(p: Dictionary, pos: Vector2, r: float) -> void:
	draw_arc(pos, r + 5.0, 0, TAU, 64, HudStyle.ACCENT, 2.0, true)
	draw_arc(pos, r + 9.0, 0, TAU, 64, Color(HudStyle.ACCENT, 0.35), 1.0, true)

	var font := get_theme_default_font()
	var bold := HudStyle.bold_font()
	var name_size := bold.get_string_size(p.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	var type_size := font.get_string_size(p.type, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	var w := maxf(name_size.x, type_size.x) + 16.0
	var top := pos + Vector2(-w * 0.5, r + 14.0)
	draw_rect(Rect2(top, Vector2(w, 36)), Color(0.02, 0.03, 0.06, 0.75))
	draw_string(bold, top + Vector2((w - name_size.x) * 0.5, 15), p.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, HudStyle.ACCENT)
	draw_string(font, top + Vector2((w - type_size.x) * 0.5, 30), p.type, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, HudStyle.TEXT_DIM)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 97:
		var a := i * TAU / 96
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, color, 1.0, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_default_cursor_shape = CURSOR_POINTING_HAND if _hit_test(event.position) != "" else CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit := _hit_test(event.position)
		if hit != "":
			select(hit)


func _hit_test(point: Vector2) -> String:
	for i in range(_bodies.size() - 1, -1, -1):
		var b := _bodies[i]
		if not b.planet.is_empty() and point.distance_to(b.pos) <= b.radius + 4.0:
			return b.planet.name
	return ""
