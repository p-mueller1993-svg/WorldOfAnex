@tool
class_name HudIcon
extends Control
## Vektor-Icon, prozedural gezeichnet – braucht keine Textur-Assets.

enum Kind {
	GEM, STAR, TARGET, POWER, CHAT, MENU, ALERT, GEAR, SUN, WIND, BOLT,
	RING, HALF, CLOCK, CUBE, MAIL, LIST, ARROW_LEFT, CHEVRON_DOWN, CHEVRON_RIGHT, PLANET, SHIELD,
}

@export var kind := Kind.GEM:
	set(value):
		kind = value
		queue_redraw()

@export var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := size * 0.5
	var w := maxf(1.5, r * 0.16)
	match kind:
		Kind.GEM:
			draw_circle(c, r * 0.9, color.darkened(0.45), true, -1.0, true)
			draw_circle(c + Vector2(-0.12, -0.12) * r, r * 0.68, color, true, -1.0, true)
			draw_circle(c + Vector2(-0.32, -0.32) * r, r * 0.22, Color(1, 1, 1, 0.75), true, -1.0, true)
		Kind.STAR:
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2 + i * PI / 5
				pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
			draw_colored_polygon(pts, color)
		Kind.TARGET:
			draw_arc(c, r * 0.62, 0, TAU, 32, color, w, true)
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(c + d * r * 0.35, c + d * r, color, w, true)
			draw_circle(c, r * 0.14, color, true, -1.0, true)
		Kind.POWER:
			draw_arc(c, r * 0.7, -PI / 2 + 0.7, PI * 1.5 - 0.7, 32, color, w, true)
			draw_line(c + Vector2(0, -r * 0.95), c + Vector2(0, -r * 0.2), color, w, true)
		Kind.CHAT:
			var rect := Rect2(c - Vector2(r * 0.85, r * 0.7), Vector2(r * 1.7, r * 1.15))
			draw_rect(rect, color, false, w)
			draw_line(rect.position + Vector2(r * 0.35, rect.size.y), c + Vector2(-r * 0.6, r * 0.85), color, w, true)
			for i in 2:
				var y := rect.position.y + rect.size.y * (0.35 + i * 0.3)
				draw_line(Vector2(c.x - r * 0.5, y), Vector2(c.x + r * 0.5, y), color, w * 0.7)
		Kind.MENU:
			for i in 3:
				var y := c.y + (i - 1) * r * 0.5
				draw_line(Vector2(c.x - r * 0.6, y), Vector2(c.x + r * 0.6, y), color, w, true)
		Kind.ALERT:
			draw_line(c + Vector2(0, -r * 0.65), c + Vector2(0, r * 0.2), color, w * 1.2, true)
			draw_circle(c + Vector2(0, r * 0.6), w * 0.75, color, true, -1.0, true)
		Kind.GEAR:
			for i in 8:
				var d := Vector2.from_angle(i * TAU / 8)
				draw_line(c + d * r * 0.55, c + d * r * 0.92, color, w * 1.6, true)
			draw_arc(c, r * 0.55, 0, TAU, 32, color, w, true)
			draw_circle(c, r * 0.2, color, true, -1.0, true)
		Kind.SUN:
			for i in 12:
				var d := Vector2.from_angle(i * TAU / 12)
				draw_line(c + d * r * 0.64, c + d * r * 0.98, color, w * 0.8, true)
			draw_circle(c, r * 0.5, color, true, -1.0, true)
		Kind.WIND:
			for i in 4:
				var d := Vector2.from_angle(PI / 4 + i * PI / 2)
				var side := d.orthogonal()
				draw_colored_polygon(PackedVector2Array([
					c + d * r * 0.15, c + d * r * 0.95 + side * r * 0.2, c + d * r * 0.9 - side * r * 0.1,
				]), color)
			draw_circle(c, r * 0.18, color, true, -1.0, true)
		Kind.BOLT:
			var pts := PackedVector2Array()
			for p in [Vector2(0.2, -1), Vector2(-0.55, 0.12), Vector2(-0.05, 0.12), Vector2(-0.25, 1), Vector2(0.55, -0.18), Vector2(0.05, -0.18)]:
				pts.append(c + p * r)
			draw_colored_polygon(pts, color)
		Kind.RING:
			draw_arc(c, r * 0.8, 0, TAU, 32, color, w, true)
		Kind.HALF:
			draw_arc(c, r * 0.8, 0, TAU, 32, color, w, true)
			var pts := PackedVector2Array()
			for i in 17:
				pts.append(c + Vector2.from_angle(-PI / 2 + i * PI / 16) * r * 0.8)
			draw_colored_polygon(pts, color)
		Kind.CLOCK:
			draw_arc(c, r * 0.8, 0, TAU, 32, color, w, true)
			draw_line(c, c + Vector2(0, -r * 0.5), color, w, true)
			draw_line(c, c + Vector2(r * 0.4, 0), color, w, true)
		Kind.CUBE:
			var top := c + Vector2(0, -r)
			var tr := c + Vector2(0.87, -0.5) * r
			var br := c + Vector2(0.87, 0.5) * r
			var bottom := c + Vector2(0, r)
			var bl := c + Vector2(-0.87, 0.5) * r
			var tl := c + Vector2(-0.87, -0.5) * r
			draw_colored_polygon(PackedVector2Array([top, tr, c, tl]), color.lightened(0.45))
			draw_colored_polygon(PackedVector2Array([tl, c, bottom, bl]), color)
			draw_colored_polygon(PackedVector2Array([c, tr, br, bottom]), color.darkened(0.3))
		Kind.MAIL:
			var rect := Rect2(c - Vector2(r * 0.85, r * 0.55), Vector2(r * 1.7, r * 1.1))
			draw_rect(rect, color, false, w)
			draw_polyline(PackedVector2Array([rect.position, c + Vector2(0, r * 0.1), rect.position + Vector2(rect.size.x, 0)]), color, w, true)
		Kind.LIST:
			var rect := Rect2(c - Vector2(r * 0.6, r * 0.85), Vector2(r * 1.2, r * 1.7))
			draw_rect(rect, color, false, w)
			for i in 3:
				var y := rect.position.y + rect.size.y * (0.28 + i * 0.22)
				draw_line(Vector2(c.x - r * 0.3, y), Vector2(c.x + r * 0.3, y), color, w * 0.7)
		Kind.ARROW_LEFT:
			_chevron(c, r, [Vector2(0.25, -0.5), Vector2(-0.25, 0), Vector2(0.25, 0.5)], w)
		Kind.CHEVRON_DOWN:
			_chevron(c, r, [Vector2(-0.5, -0.2), Vector2(0, 0.3), Vector2(0.5, -0.2)], w)
		Kind.CHEVRON_RIGHT:
			_chevron(c, r, [Vector2(-0.25, -0.5), Vector2(0.25, 0), Vector2(-0.25, 0.5)], w)
		Kind.PLANET:
			draw_circle(c, r * 0.5, color, true, -1.0, true)
			var ring := PackedVector2Array()
			for i in 33:
				var a := i * TAU / 32
				ring.append(c + Vector2(cos(a) * r * 0.95, sin(a) * r * 0.3).rotated(-0.35))
			draw_polyline(ring, color, w * 0.8, true)
		Kind.SHIELD:
			var pts := PackedVector2Array()
			for p in [Vector2(-0.7, -0.8), Vector2(0.7, -0.8), Vector2(0.7, 0.05), Vector2(0, 0.95), Vector2(-0.7, 0.05)]:
				pts.append(c + p * r)
			draw_colored_polygon(pts, color)


func _chevron(c: Vector2, r: float, points: Array, w: float) -> void:
	var pts := PackedVector2Array()
	for p in points:
		pts.append(c + p * r)
	draw_polyline(pts, color, w, true)
