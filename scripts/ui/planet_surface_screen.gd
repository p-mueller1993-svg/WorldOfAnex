class_name PlanetSurfaceScreen
extends Control
## Planetenoberfläche: isometrische Karte mit Kolonie-Infopanel, Truppenübersicht,
## Zoom-Steuerung, Kartengrößen-Option und Planetenwahl.

signal system_requested
signal planet_requested(planet_name: String)

const MAP_SIZES := [10, 25, 50, 100, 200, 300, 500, 700]

var _view: PlanetSurfaceView
var _colony_panel: ColonyInfoPanel
var _troops_panel: TroopsPanel
var _size_option: OptionButton
var _globe: PlanetBadge
var _planet_button: Button
var _planet_label: Label
var _planet_menu: PopupMenu
var _planets: Array[Dictionary] = []


func _init() -> void:
	clip_contents = true
	_view = PlanetSurfaceView.new()
	_view.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_view)

	_colony_panel = ColonyInfoPanel.new()
	_colony_panel.anchor_top = 1.0
	_colony_panel.anchor_bottom = 1.0
	_colony_panel.offset_left = 12
	_colony_panel.offset_bottom = -12
	_colony_panel.grow_vertical = GROW_DIRECTION_BEGIN
	_colony_panel.visible = false
	add_child(_colony_panel)

	_troops_panel = TroopsPanel.new()
	_troops_panel.anchor_left = 1.0
	_troops_panel.anchor_right = 1.0
	_troops_panel.anchor_top = 1.0
	_troops_panel.anchor_bottom = 1.0
	_troops_panel.offset_right = -12
	_troops_panel.offset_bottom = -12
	_troops_panel.grow_horizontal = GROW_DIRECTION_BEGIN
	_troops_panel.grow_vertical = GROW_DIRECTION_BEGIN
	add_child(_troops_panel)

	add_child(_build_bottom_bar())

	_planet_menu = PopupMenu.new()
	_planet_menu.id_pressed.connect(_on_planet_menu_id)
	add_child(_planet_menu)

	_view.colony_selected.connect(_colony_panel.show_colony)
	_view.selection_cleared.connect(func(): _colony_panel.visible = false)
	_colony_panel.close_requested.connect(_view.clear_selection)
	_colony_panel.action_requested.connect(func(action, colony): print("Aktion '%s' auf Kolonie %s" % [action, colony.name]))


func open(planet: Dictionary, planets: Array[Dictionary]) -> void:
	_planets = planets
	_planet_label.text = planet.name
	_globe.planet = planet
	var map_size := nearest_map_size(planet.get("surface_size", 100))
	_size_option.select(MAP_SIZES.find(map_size))
	_view.open(planet, map_size)
	_show_home_troops()


static func nearest_map_size(tiles: int) -> int:
	var best: int = MAP_SIZES[0]
	for s in MAP_SIZES:
		if absi(s - tiles) < absi(best - tiles):
			best = s
	return best


func _show_home_troops() -> void:
	var Unit := TroopsPanel.UnitIcon.Unit
	var units := [
		{"unit": Unit.INFANTRY, "count": 10}, {"unit": Unit.SHIELD, "count": 9},
		{"unit": Unit.TANK, "count": 7}, {"unit": Unit.HEAVY_TANK, "count": 10},
		{"unit": Unit.DRONE, "count": 9}, {"unit": Unit.MECH, "count": 9},
	]
	_troops_panel.show_troops(_view.home_colony().name, units, 747, 2270, 0)


func _build_bottom_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_bottom = -6
	bar.grow_horizontal = GROW_DIRECTION_BOTH
	bar.grow_vertical = GROW_DIRECTION_BEGIN
	bar.add_theme_constant_override("separation", 10)

	var controls := HBoxContainer.new()
	controls.size_flags_vertical = SIZE_SHRINK_END
	controls.add_theme_constant_override("separation", 8)
	var zoom_in := HudStyle.icon_button(HudIcon.Kind.PLUS, Vector2(36, 36), HudStyle.TEXT, true)
	zoom_in.tooltip_text = "Hineinzoomen"
	zoom_in.pressed.connect(func(): _view.zoom_by(1.25))
	var zoom_out := HudStyle.icon_button(HudIcon.Kind.MINUS, Vector2(36, 36), HudStyle.TEXT, true)
	zoom_out.tooltip_text = "Herauszoomen"
	zoom_out.pressed.connect(func(): _view.zoom_by(0.8))
	var home := HudStyle.icon_button(HudIcon.Kind.SEARCH, Vector2(36, 36), HudStyle.TEXT, true)
	home.tooltip_text = "Zur eigenen Kolonie"
	home.pressed.connect(_view.center_on_home)
	controls.add_child(zoom_in)
	controls.add_child(zoom_out)
	controls.add_child(home)

	_size_option = OptionButton.new()
	_size_option.tooltip_text = "Kartengröße"
	_size_option.focus_mode = FOCUS_NONE
	_size_option.custom_minimum_size = Vector2(130, 36)
	for state in ["normal", "hover", "pressed"]:
		var box := HudStyle.panel_box(HudStyle.PANEL, HudStyle.BORDER, 18, 0)
		if state == "hover":
			box.bg_color = Color("1e1e21")
		elif state == "pressed":
			box.border_color = HudStyle.ACCENT
		box.content_margin_left = 14
		box.content_margin_right = 10
		_size_option.add_theme_stylebox_override(state, box)
	_size_option.add_theme_color_override("font_color", HudStyle.TEXT)
	for s in MAP_SIZES:
		_size_option.add_item("%d × %d" % [s, s], s)
	_size_option.item_selected.connect(func(index): _view.set_map_size(_size_option.get_item_id(index)))
	controls.add_child(_size_option)
	bar.add_child(controls)

	# Globus mit Planetenwahl
	var globe_box := Control.new()
	globe_box.custom_minimum_size = Vector2(136, 136)
	_globe = PlanetBadge.new()
	_globe.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_globe.mouse_filter = MOUSE_FILTER_IGNORE
	globe_box.add_child(_globe)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_planet_label = HudStyle.label("", 13, Color.WHITE)
	row.add_child(_planet_label)
	row.add_child(HudStyle.icon(HudIcon.Kind.CHEVRON_UP, Color.WHITE, 10))
	_planet_button = HudStyle.content_button(row, Vector2(104, 30))
	_planet_button.add_theme_stylebox_override("normal", HudStyle.panel_box(Color(0.06, 0.14, 0.24, 0.9), HudStyle.ACCENT.darkened(0.2), 3, 0))
	_planet_button.add_theme_stylebox_override("hover", HudStyle.panel_box(Color(0.09, 0.2, 0.34, 0.95), HudStyle.ACCENT, 3, 0))
	_planet_button.anchor_left = 0.5
	_planet_button.anchor_right = 0.5
	_planet_button.anchor_top = 0.5
	_planet_button.anchor_bottom = 0.5
	_planet_button.grow_horizontal = GROW_DIRECTION_BOTH
	_planet_button.grow_vertical = GROW_DIRECTION_BOTH
	_planet_button.pressed.connect(_show_planet_menu)
	globe_box.add_child(_planet_button)
	bar.add_child(globe_box)
	return bar


func _show_planet_menu() -> void:
	_planet_menu.clear()
	_planet_menu.add_item("« Sonnensystem", 0)
	_planet_menu.add_separator()
	for i in _planets.size():
		_planet_menu.add_item(_planets[i].name, i + 1)
	_planet_menu.reset_size()
	var pos := _planet_button.get_screen_position()
	pos.y -= _planet_menu.size.y + 4
	_planet_menu.popup(Rect2i(Vector2i(pos), _planet_menu.size))


func _on_planet_menu_id(id: int) -> void:
	if id == 0:
		system_requested.emit()
	else:
		planet_requested.emit(_planets[id - 1].name)
