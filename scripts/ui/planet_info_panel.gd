class_name PlanetInfoPanel
extends PanelContainer
## Infopanel zum ausgewählten Planeten (Masse, Orbit, Umlaufzeit, Primärrohstoff).

signal surface_requested(planet: Dictionary)
signal close_requested

var _planet: Dictionary
var _type_label: Label
var _name_label: Label
var _mass_value: Label
var _orbit_value: Label
var _period_value: Label
var _resource_icon: HudIcon


func _init() -> void:
	custom_minimum_size.x = 260
	add_theme_stylebox_override("panel", HudStyle.panel_box(Color("121214"), HudStyle.BORDER, 3, 0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	add_child(column)

	# Kopfzeile
	var header := HudStyle.margin(10, 6)
	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 6)
	head_row.add_child(HudStyle.icon(HudIcon.Kind.PLANET, HudStyle.ACCENT, 16))
	head_row.add_child(HudStyle.label("Planet", 15, HudStyle.TEXT, true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	head_row.add_child(spacer)
	var close := Button.new()
	close.text = "×"
	close.flat = true
	close.focus_mode = FOCUS_NONE
	close.add_theme_color_override("font_color", HudStyle.TEXT_DIM)
	close.add_theme_color_override("font_hover_color", HudStyle.TEXT)
	close.pressed.connect(_on_close_pressed)
	head_row.add_child(close)
	header.add_child(head_row)
	column.add_child(header)

	# Titelblock
	var title := PanelContainer.new()
	title.add_theme_stylebox_override("panel", HudStyle.panel_box(HudStyle.PANEL_DARK, HudStyle.PANEL_DARK, 0, 8))
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 0)
	_type_label = HudStyle.label("", 11, HudStyle.TEXT_DIM)
	_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label = HudStyle.label("", 20, HudStyle.ACCENT, true)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(_type_label)
	title_box.add_child(_name_label)
	title.add_child(title_box)
	column.add_child(title)

	# Werte
	var rows_margin := HudStyle.margin(12, 12)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	_mass_value = HudStyle.label("", 14)
	_orbit_value = HudStyle.label("", 14)
	_period_value = HudStyle.label("", 14)
	_resource_icon = HudStyle.icon(HudIcon.Kind.CUBE, HudStyle.ACCENT, 20)
	_add_row(rows, HudIcon.Kind.RING, "Masse", _mass_value)
	_add_row(rows, HudIcon.Kind.HALF, "Orbit Radius", _orbit_value)
	_add_row(rows, HudIcon.Kind.CLOCK, "Umlaufzeit", _period_value)
	_add_row(rows, HudIcon.Kind.LIST, "Primärrohstoff", _resource_icon)
	rows_margin.add_child(rows)
	column.add_child(rows_margin)

	# Aktion
	var button_margin := HudStyle.margin(10, 10)
	var surface := Button.new()
	surface.text = "Planetenoberfläche"
	surface.custom_minimum_size.y = 38
	surface.focus_mode = FOCUS_NONE
	surface.add_theme_stylebox_override("normal", HudStyle.panel_box(Color("10233a"), HudStyle.ACCENT.darkened(0.15), 3, 0))
	surface.add_theme_stylebox_override("hover", HudStyle.panel_box(Color("163050"), HudStyle.ACCENT, 3, 0))
	surface.add_theme_stylebox_override("pressed", HudStyle.panel_box(Color("0c1a2c"), HudStyle.ACCENT, 3, 0))
	surface.add_theme_color_override("font_color", Color("9fd0ff"))
	surface.add_theme_color_override("font_hover_color", Color.WHITE)
	surface.pressed.connect(func(): surface_requested.emit(_planet))
	button_margin.add_child(surface)
	column.add_child(button_margin)


func show_planet(planet: Dictionary) -> void:
	_planet = planet
	_type_label.text = planet.type
	_name_label.text = planet.name
	_mass_value.text = HudStyle.format_thousands(planet.mass)
	_orbit_value.text = str(planet.orbit)
	_period_value.text = HudStyle.format_duration(planet.period)
	_resource_icon.kind = planet.resource
	_resource_icon.color = planet.resource_color
	visible = true


func _add_row(parent: Control, kind: HudIcon.Kind, title: String, value: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(HudStyle.icon(kind, HudStyle.ACCENT, 16))
	var label := HudStyle.label(title, 14, HudStyle.TEXT, true)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(label)
	row.add_child(value)
	parent.add_child(row)


func _on_close_pressed() -> void:
	visible = false
	close_requested.emit()
