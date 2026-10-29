class_name PlanetBadge
extends Control
## Runde Planeten-Plakette (obere Leiste, Planetenwahl auf der Oberfläche).

var planet: Dictionary:
	set(value):
		planet = value
		queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	draw_circle(c, r, Color("0e0e10"), true, -1.0, true)
	if not planet.is_empty():
		PlanetPainter.draw_planet(self, c, r * 0.8, planet)
	draw_arc(c, r - 1.5, 0, TAU, 64, Color("3a3a3e"), 3.0, true)
