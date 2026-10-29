class_name TroopsPanel
extends PanelContainer
## Truppenübersicht einer Kolonie: Einheiten, Angriffs- und Verteidigungswert, Unterstützungen.

var _body: VBoxContainer
var _summary: HBoxContainer
var _units: HBoxContainer
var _attack_label: Label
var _defense_label: Label
var _support: HBoxContainer


func _init() -> void:
	custom_minimum_size.x = 440
	add_theme_stylebox_override("panel", HudStyle.panel_box(Color("121214"), HudStyle.BORDER, 3, 0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	add_child(column)

	# Kopfzeile mit Minimieren/Schließen
	var header := HudStyle.margin(10, 4)
	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 6)
	head_row.add_child(HudStyle.icon(HudIcon.Kind.STAR, HudStyle.ACCENT, 16))
	head_row.add_child(HudStyle.label("TRUPPEN", 15, HudStyle.TEXT, true))
	head_row.add_child(HudStyle.spacer())
	var minimize := HudStyle.icon_button(HudIcon.Kind.MINUS, Vector2(24, 24))
	minimize.flat = true
	minimize.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	minimize.pressed.connect(func(): _body.visible = not _body.visible)
	head_row.add_child(minimize)
	var close := HudStyle.close_button()
	close.pressed.connect(func(): visible = false)
	head_row.add_child(close)
	header.add_child(head_row)
	column.add_child(header)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 0)
	column.add_child(_body)

	# Reiter: eigene Truppen / Verteidigung
	var tabs_margin := HudStyle.margin(10, 0)
	var tabs := PanelContainer.new()
	tabs.add_theme_stylebox_override("panel", HudStyle.panel_box(Color("1a1a1c"), Color("1a1a1c"), 0, 0))
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 0)
	var group := ButtonGroup.new()
	for kind in [HudIcon.Kind.STAR, HudIcon.Kind.SHIELD]:
		var tab := HudStyle.icon_button(kind, Vector2(46, 40), HudStyle.ACCENT if kind == HudIcon.Kind.STAR else HudStyle.TEXT_DIM)
		tab.toggle_mode = true
		tab.button_group = group
		tab.button_pressed = kind == HudIcon.Kind.STAR
		tab.add_theme_stylebox_override("normal", HudStyle.panel_box(Color("1a1a1c"), Color("1a1a1c"), 0, 0))
		tab.add_theme_stylebox_override("pressed", HudStyle.panel_box(Color("0f0f11"), Color("0f0f11"), 0, 0))
		tab_row.add_child(tab)
	tabs.add_child(tab_row)
	tabs_margin.add_child(tabs)
	_body.add_child(tabs_margin)

	var content_margin := HudStyle.margin(12, 12)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	_summary = HBoxContainer.new()
	_summary.add_theme_constant_override("separation", 0)
	content.add_child(_summary)
	_units = HBoxContainer.new()
	_units.alignment = BoxContainer.ALIGNMENT_CENTER
	_units.add_theme_constant_override("separation", 8)
	content.add_child(_units)

	var values := HBoxContainer.new()
	values.add_theme_constant_override("separation", 0)
	_attack_label = HudStyle.label("", 15, Color("ff4a4a"), true)
	_defense_label = HudStyle.label("", 15, Color("8cc4ff"), true)
	values.add_child(_value_box(HudStyle.icon(HudIcon.Kind.TARGET, Color("ff4040"), 16), _attack_label, Color("4a0808")))
	values.add_child(_value_box(HudStyle.icon(HudIcon.Kind.HEART, Color("5aa8ff"), 16), _defense_label, Color("0d2a52")))
	content.add_child(values)

	_support = HBoxContainer.new()
	_support.add_theme_constant_override("separation", 0)
	content.add_child(_support)
	content_margin.add_child(content)
	_body.add_child(content_margin)


## units: Array von {"unit": UnitIcon.Unit, "count": int}
func show_troops(location: String, units: Array, attack: int, defense: int, supports: int) -> void:
	var total := 0
	for u in units:
		total += u.count
	_fill(_summary, [[str(total), HudStyle.ACCENT, true], [" Eigene Truppen in ", HudStyle.TEXT, false], [location, HudStyle.TEXT, true]])
	_fill(_support, [[str(supports), HudStyle.TEXT, false], [" Unterstützungen in ", HudStyle.TEXT, false], [location, HudStyle.TEXT, true], [" von", HudStyle.TEXT_DIM, false]])

	for child in _units.get_children():
		child.queue_free()
	for u in units:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var icon := UnitIcon.new()
		icon.unit = u.unit
		icon.custom_minimum_size = Vector2(56, 56)
		cell.add_child(icon)
		var count := HudStyle.label(str(u.count), 15, HudStyle.TEXT, true)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(count)
		_units.add_child(cell)

	_attack_label.text = str(attack)
	_defense_label.text = str(defense)
	visible = true


func _value_box(icon: Control, label: Label, bg: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", HudStyle.panel_box(bg, bg, 0, 7))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.add_child(icon)
	row.add_child(label)
	panel.add_child(row)
	return panel


## parts: [[text, color, bold], ...] – Text mit gemischten Farben in einer Zeile
func _fill(row: HBoxContainer, parts: Array) -> void:
	for child in row.get_children():
		child.queue_free()
	for part in parts:
		row.add_child(HudStyle.label(part[0], 13, part[1], part[2]))


## Prozedural gezeichnete Einheiten-Grafik.
class UnitIcon extends Control:
	enum Unit { INFANTRY, SHIELD, TANK, HEAVY_TANK, DRONE, MECH }

	var unit := Unit.INFANTRY:
		set(value):
			unit = value
			queue_redraw()

	var _c := Vector2.ZERO
	var _u := 1.0

	func _draw() -> void:
		_c = size * 0.5
		_u = minf(size.x, size.y) / 48.0
		var dark := Color("2e3440")
		match unit:
			Unit.INFANTRY, Unit.SHIELD:
				var red := Color("c8282a")
				_rect(-7, 6, 5, 14, Color("5a1214"))
				_rect(2, 6, 5, 14, Color("5a1214"))
				_rect(-9, -8, 18, 15, red)
				draw_circle(_p(0, -13), 6 * _u, red.lightened(0.15), true, -1.0, true)
				_rect(-3, -15, 8, 3, Color("ffd040"))
				if unit == Unit.INFANTRY:
					_rect(4, -2, 16, 4, Color("3a3f48"))
				else:
					_poly([_p(6, -14), _p(20, -10), _p(20, 8), _p(13, 18), _p(6, 8)], Color("c9c2b0"))
					_rect(12, -6, 2, 14, red)
					_rect(8, -1, 10, 2, red)
			Unit.TANK:
				_rect(-20, 6, 40, 10, dark)
				for i in 4:
					draw_circle(_p(-14 + i * 9.5, 11), 3 * _u, Color("6a7280"), true, -1.0, true)
				_poly([_p(-18, 6), _p(18, 6), _p(14, -4), _p(-14, -4)], Color("5b6b84"))
				_rect(4, -10, 18, 4, Color("4a5468"))
				draw_circle(_p(-2, -7), 8 * _u, Color("6f80a0"), true, -1.0, true)
				draw_circle(_p(-6, -9), 1.6 * _u, Color("40e0ff"), true, -1.0, true)
			Unit.HEAVY_TANK:
				var blue := Color("2f5aa8")
				_rect(-22, 8, 44, 11, Color("1c2840"))
				_poly([_p(-20, 8), _p(20, 8), _p(16, -4), _p(-16, -4)], blue)
				_rect(6, -12, 18, 5, Color("23417a"))
				draw_circle(_p(0, -8), 11 * _u, blue.lightened(0.15), true, -1.0, true)
				draw_circle(_p(-4, -12), 4 * _u, blue.lightened(0.45), true, -1.0, true)
				for x in [-12, 0, 12]:
					draw_circle(_p(x, 2), 1.8 * _u, Color("40e0ff"), true, -1.0, true)
			Unit.DRONE:
				var orange := Color("f0a020")
				for side in [-1, 1]:
					draw_line(_p(side * 4, 0), _p(side * 13, -6), Color("8a5a10"), 3 * _u, true)
					_ellipse(_p(side * 13, -8), 10, 4, Color(1.0, 0.82, 0.4, 0.8))
				draw_circle(_p(0, 3), 10 * _u, orange, true, -1.0, true)
				draw_circle(_p(0, 4), 5 * _u, Color("3a2a10"), true, -1.0, true)
				draw_circle(_p(0, 4), 2 * _u, Color("40e0ff"), true, -1.0, true)
			Unit.MECH:
				var orange := Color("e89420")
				_rect(-9, 6, 6, 14, Color("6a4a20"))
				_rect(3, 6, 6, 14, Color("6a4a20"))
				_rect(-17, -6, 6, 12, Color("8a8f98"))
				_rect(11, -6, 6, 12, Color("8a8f98"))
				_rect(-12, -12, 24, 19, orange)
				_rect(-7, -9, 14, 6, Color("ffd060"))
				_rect(13, 2, 10, 4, dark)

	func _p(x: float, y: float) -> Vector2:
		return _c + Vector2(x, y) * _u

	func _rect(x: float, y: float, w: float, h: float, color: Color) -> void:
		draw_rect(Rect2(_p(x, y), Vector2(w, h) * _u), color)

	func _poly(points: Array, color: Color) -> void:
		draw_colored_polygon(PackedVector2Array(points), color)

	func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
		var pts := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry) * _u)
		draw_colored_polygon(pts, color)
