extends Control
## Haupt-HUD: Ressourcenleiste oben, Sonnensystem-Ansicht mit Planeten-Infopanel darunter.

var resources: Array[Dictionary] = [
	{"id": "metal", "name": "Metall", "color": Color("b9bec8"), "amount": 6860.0, "rate": 2490.0, "cap": 10000.0},
	{"id": "water", "name": "Wasser", "color": Color("3a8dff"), "amount": 4704.0, "rate": 1824.0, "cap": 7000.0},
	{"id": "bio", "name": "Biomasse", "color": Color("3fd25a"), "amount": 3528.0, "rate": 1089.0, "cap": 5500.0},
]

var type_styles := {
	"Eisplanet": {"color": Color("cfe6f7"), "detail": Color("2f7fd0"), "glow": Color("7fc0ff"), "resource": HudIcon.Kind.CUBE, "resource_color": Color("4fb4ff")},
	"Wüstenplanet": {"color": Color("c8641e"), "detail": Color("e8964a"), "glow": Color("ff9a50"), "resource": HudIcon.Kind.GEM, "resource_color": Color("b9bec8")},
	"Lavaplanet": {"color": Color("3a1410"), "detail": Color("e0431a"), "glow": Color("ff5020"), "resource": HudIcon.Kind.BOLT, "resource_color": Color("ffcc33")},
	"Gasriese": {"color": Color("5b1f86"), "detail": Color("e04a7a"), "glow": Color("b060ff"), "resource": HudIcon.Kind.GEM, "resource_color": Color("3a8dff")},
	"Dschungelplanet": {"color": Color("4f8f2a"), "detail": Color("c2a55a"), "glow": Color("8fe070"), "resource": HudIcon.Kind.GEM, "resource_color": Color("3fd25a")},
}

var _resource_widgets := {}
var _view: SolarSystemView
var _info_panel: PlanetInfoPanel


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = HudStyle.BG
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(bg)

	var margin := HudStyle.margin(24, 16)
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	column.add_child(_build_top_bar())

	var body := HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	column.add_child(body)
	body.add_child(_build_view_frame())
	body.add_child(_build_side_buttons())

	_view.planets = _demo_planets()
	_view.select("Anthe")


func _process(delta: float) -> void:
	for r in resources:
		r.amount = minf(r.cap, r.amount + r.rate * delta / 3600.0)
		var widget: Dictionary = _resource_widgets[r.id]
		widget.label.text = str(int(r.amount))
		widget.bar.value = r.amount


# --- Obere Leiste ---------------------------------------------------------

func _build_top_bar() -> Control:
	var center := CenterContainer.new()
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 22)
	center.add_child(bar)

	var res_box := HBoxContainer.new()
	res_box.add_theme_constant_override("separation", 10)
	res_box.size_flags_vertical = SIZE_SHRINK_CENTER
	for r in resources:
		res_box.add_child(_resource_widget(r))
	res_box.add_child(_extractor_widget())
	bar.add_child(res_box)
	bar.add_child(_build_medallion())
	bar.add_child(_build_stats())

	var system := VBoxContainer.new()
	system.add_theme_constant_override("separation", 8)
	system.size_flags_vertical = SIZE_SHRINK_CENTER
	system.add_child(HudStyle.icon_button(HudIcon.Kind.POWER, Vector2(58, 28)))
	system.add_child(HudStyle.icon_button(HudIcon.Kind.CHAT, Vector2(58, 28)))
	bar.add_child(system)
	return center


func _resource_widget(r: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 88
	box.add_theme_constant_override("separation", 5)
	box.tooltip_text = r.name

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 6)
	top.add_child(HudStyle.icon(HudIcon.Kind.GEM, r.color, 18))
	var value := HudStyle.label(str(int(r.amount)), 15, HudStyle.TEXT, true)
	top.add_child(value)
	box.add_child(top)

	var bar := HudStyle.progress_bar()
	bar.max_value = r.cap
	bar.value = r.amount
	box.add_child(bar)

	var rate := HudStyle.label("+%d" % int(r.rate), 11, HudStyle.ACCENT)
	rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rate)
	_resource_widgets[r.id] = {"label": value, "bar": bar}
	return box


func _extractor_widget() -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 88
	box.add_theme_constant_override("separation", 5)
	box.tooltip_text = "Kristalle"

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 6)
	top.add_child(HudStyle.icon(HudIcon.Kind.GEM, Color("27c3ff"), 18))
	top.add_child(HudStyle.label("16", 15, HudStyle.TEXT, true))
	box.add_child(top)

	var bar := HudStyle.progress_bar()
	bar.value = 15
	box.add_child(bar)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	status.add_child(HudStyle.icon(HudIcon.Kind.GEAR, Color("d99a2b"), 18))
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", -4)
	lines.add_child(HudStyle.label("Extraktor", 11, HudStyle.ACCENT))
	lines.add_child(HudStyle.label("wartet", 10, HudStyle.TEXT_DIM))
	status.add_child(lines)
	box.add_child(status)
	return box


func _build_medallion() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 4)
	for kind in [HudIcon.Kind.MENU, HudIcon.Kind.ALERT, HudIcon.Kind.GEAR]:
		top.add_child(HudStyle.icon_button(kind, Vector2(26, 26), HudStyle.TEXT_DIM, true))
	box.add_child(top)

	var mid := HBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 6)
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 6)
	left.add_child(_dual_icon_button(HudIcon.Kind.PLANET))
	left.add_child(_dual_icon_button(HudIcon.Kind.SHIELD))
	mid.add_child(left)

	var badge := PlanetBadge.new()
	badge.custom_minimum_size = Vector2(86, 86)
	badge.planet = _styled({"name": "Bümsbüdä2000!", "type": "Dschungelplanet"})
	mid.add_child(badge)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 6)
	right.add_child(_counter_button(HudIcon.Kind.MAIL, "0", false))
	right.add_child(_counter_button(HudIcon.Kind.LIST, "2", true))
	mid.add_child(right)
	box.add_child(mid)

	var plate := PanelContainer.new()
	plate.size_flags_horizontal = SIZE_SHRINK_CENTER
	var plate_box := HudStyle.panel_box(HudStyle.PANEL, HudStyle.BORDER, 3, 3)
	plate_box.content_margin_left = 10
	plate_box.content_margin_right = 10
	plate.add_theme_stylebox_override("panel", plate_box)
	var plate_row := HBoxContainer.new()
	plate_row.add_theme_constant_override("separation", 8)
	plate_row.add_child(HudStyle.icon(HudIcon.Kind.CHEVRON_DOWN, HudStyle.TEXT_DIM, 10))
	plate_row.add_child(HudStyle.label("Bümsbüdä2000!", 14, HudStyle.TEXT, true))
	plate_row.add_child(HudStyle.icon(HudIcon.Kind.CHEVRON_RIGHT, HudStyle.TEXT_DIM, 10))
	plate.add_child(plate_row)
	box.add_child(plate)

	var system_name := HudStyle.label("Woox-Taur", 10, HudStyle.TEXT_DIM)
	system_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(system_name)
	return box


func _dual_icon_button(kind: HudIcon.Kind) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(HudStyle.icon(HudIcon.Kind.ARROW_LEFT, HudStyle.TEXT, 10))
	row.add_child(HudStyle.icon(kind, HudStyle.TEXT_DIM, 14))
	return HudStyle.content_button(row, Vector2(44, 24))


func _counter_button(kind: HudIcon.Kind, text: String, highlight: bool) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(HudStyle.icon(kind, HudStyle.TEXT_DIM, 14))
	if highlight:
		var pill := PanelContainer.new()
		var pill_box := HudStyle.panel_box(HudStyle.ACCENT, HudStyle.ACCENT, 9, 0)
		pill_box.content_margin_left = 5
		pill_box.content_margin_right = 5
		pill.add_theme_stylebox_override("panel", pill_box)
		pill.add_child(HudStyle.label(text, 10, Color.WHITE, true))
		row.add_child(pill)
	else:
		row.add_child(HudStyle.label(text, 12, HudStyle.TEXT_DIM))
	return HudStyle.content_button(row, Vector2(44, 24))


func _build_stats() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.size_flags_vertical = SIZE_SHRINK_CENTER

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.add_child(_stat(HudStyle.icon(HudIcon.Kind.BOLT, Color("ffcc33"), 18), "1262", "Energie"))
	row.add_child(_stat(HudStyle.icon(HudIcon.Kind.BOLT, Color("ff6a2a"), 18), "558", "Leistung"))
	row.add_child(_stat(HudStyle.label("XP", 13, Color("ff8a1e"), true), "77538", "Erfahrung"))
	box.add_child(row)

	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	var weather_lines := VBoxContainer.new()
	weather_lines.add_theme_constant_override("separation", -3)
	var weather_top := HBoxContainer.new()
	weather_top.add_theme_constant_override("separation", 0)
	weather_top.add_child(HudStyle.label("Sonnig, klar » ", 11))
	weather_top.add_child(HudStyle.label("33°C", 11, HudStyle.GOOD))
	weather_lines.add_child(weather_top)
	weather_lines.add_child(HudStyle.label("keine Besonderheiten", 10, HudStyle.TEXT_DIM))
	info.add_child(_info_box(HudStyle.icon(HudIcon.Kind.SUN, Color("ffc93a"), 28), weather_lines, 190))

	var wind_lines := VBoxContainer.new()
	wind_lines.add_theme_constant_override("separation", -3)
	wind_lines.add_child(HudStyle.label("Orkan", 11))
	wind_lines.add_child(HudStyle.label("142 km/h", 10, HudStyle.TEXT_DIM))
	info.add_child(_info_box(HudStyle.icon(HudIcon.Kind.WIND, Color("c8ccd4"), 24), wind_lines, 92))
	box.add_child(info)
	return box


func _stat(icon: Control, value: String, tooltip: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.tooltip_text = tooltip
	row.add_child(icon)
	row.add_child(HudStyle.label(value, 15, HudStyle.TEXT, true))
	return row


func _info_box(icon: Control, content: Control, min_width: float) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = min_width
	var style := HudStyle.panel_box(Color("131315"), Color("1c1c1f"), 3, 3)
	style.content_margin_left = 6
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(icon)
	row.add_child(content)
	panel.add_child(row)
	return panel


# --- Hauptbereich ---------------------------------------------------------

func _build_view_frame() -> Control:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = SIZE_EXPAND_FILL
	frame.size_flags_vertical = SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", HudStyle.panel_box(HudStyle.PANEL, HudStyle.BORDER, 3, 14))

	_view = SolarSystemView.new()
	_view.clip_contents = true
	frame.add_child(_view)

	_info_panel = PlanetInfoPanel.new()
	_info_panel.anchor_top = 0.5
	_info_panel.anchor_bottom = 0.5
	_info_panel.offset_left = 12
	_info_panel.grow_vertical = GROW_DIRECTION_BOTH
	_view.add_child(_info_panel)

	_view.planet_selected.connect(_info_panel.show_planet)
	_info_panel.close_requested.connect(_view.clear_selection)
	_info_panel.surface_requested.connect(func(p): print("Planetenoberfläche öffnen: ", p.name))
	return frame


func _build_side_buttons() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_vertical = SIZE_SHRINK_BEGIN
	box.add_child(_side_button(HudIcon.Kind.STAR, "16", HudStyle.ACCENT))
	box.add_child(_side_button(HudIcon.Kind.TARGET, "0", HudStyle.TEXT_DIM))
	return box


func _side_button(kind: HudIcon.Kind, text: String, color: Color) -> Button:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	var icon := HudStyle.icon(kind, color, 28)
	icon.size_flags_horizontal = SIZE_SHRINK_CENTER
	content.add_child(icon)
	var label := HudStyle.label(text, 15, color, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(label)
	return HudStyle.content_button(content, Vector2(58, 68))


# --- Demodaten ------------------------------------------------------------

func _demo_planets() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		_planet("Ignis", "Lavaplanet", 110, 12, 12600, 0.3, 2_400_000, 0),
		_planet("Vulkan", "Lavaplanet", 150, 16, 22300, 3.9, 4_100_000, 1),
		_planet("Nyx", "Gasriese", 195, 21, 32800, 2.2, 31_500_000, 0),
		_planet("Rubra", "Wüstenplanet", 245, 11, 44600, 5.5, 1_900_000, 0),
		_planet("Kharon", "Wüstenplanet", 300, 34, 58700, 1.6, 22_800_000, 1),
		_planet("Anthe", "Eisplanet", 370, 26, 70800, 2.35, 14_000_000, 0),
		_planet("Tessa", "Wüstenplanet", 405, 15, 86400, 0.4, 3_300_000, 0),
		_planet("Boreas", "Eisplanet", 440, 36, 113400, 1.2, 41_000_000, 2),
		_planet("Verdis", "Dschungelplanet", 470, 30, 136800, 3.6, 26_400_000, 1),
		_planet("Silva", "Dschungelplanet", 500, 24, 162000, 5.9, 18_200_000, 0),
	]
	return list


func _planet(p_name: String, type: String, orbit: int, px_size: float, period: int, phase: float, mass: int, moons: int) -> Dictionary:
	return _styled({
		"name": p_name, "type": type, "orbit": orbit, "size": px_size,
		"period": period, "phase": phase, "mass": mass, "moons": moons,
	})


func _styled(planet: Dictionary) -> Dictionary:
	planet.merge(type_styles[planet.type])
	return planet


## Runde Planeten-Plakette in der Mitte der oberen Leiste.
class PlanetBadge extends Control:
	var planet: Dictionary

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		draw_circle(c, r, Color("0e0e10"), true, -1.0, true)
		PlanetPainter.draw_planet(self, c, r * 0.8, planet)
		draw_arc(c, r - 1.5, 0, TAU, 64, Color("3a3a3e"), 3.0, true)
