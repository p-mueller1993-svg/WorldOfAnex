class_name ColonyInfoPanel
extends PanelContainer
## Infopanel zur ausgewählten Kolonie auf der Planetenoberfläche.

signal close_requested
signal action_requested(action: String, colony: Dictionary)

var _colony: Dictionary
var _tag_label: Label
var _player_label: Label
var _name_label: Label
var _distance_value: Label
var _strength_value: Label
var _hostile_buttons: Array[Button] = []


func _init() -> void:
	custom_minimum_size.x = 268
	add_theme_stylebox_override("panel", HudStyle.panel_box(Color("121214"), HudStyle.BORDER, 3, 0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	add_child(column)

	# Kopfzeile
	var header := HudStyle.margin(10, 6)
	var head_row := HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 6)
	head_row.add_child(HudStyle.icon(HudIcon.Kind.USER, HudStyle.ACCENT, 16))
	head_row.add_child(HudStyle.label("Kolonie", 15, HudStyle.TEXT, true))
	head_row.add_child(HudStyle.spacer())
	var close := HudStyle.close_button()
	close.pressed.connect(_on_close_pressed)
	head_row.add_child(close)
	header.add_child(head_row)
	column.add_child(header)

	# Titelblock: [Allianz] Spieler / Kolonienname
	var title := PanelContainer.new()
	title.add_theme_stylebox_override("panel", HudStyle.panel_box(HudStyle.PANEL_DARK, HudStyle.PANEL_DARK, 0, 8))
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 0)
	var owner_row := HBoxContainer.new()
	owner_row.alignment = BoxContainer.ALIGNMENT_CENTER
	owner_row.add_theme_constant_override("separation", 4)
	_tag_label = HudStyle.label("", 11, HudStyle.TEXT, true)
	_player_label = HudStyle.label("", 11, HudStyle.TEXT_DIM)
	owner_row.add_child(_tag_label)
	owner_row.add_child(_player_label)
	_name_label = HudStyle.label("", 20, HudStyle.ACCENT, true)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(owner_row)
	title_box.add_child(_name_label)
	title.add_child(title_box)
	column.add_child(title)

	# Werte
	var rows_margin := HudStyle.margin(12, 12)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	_distance_value = HudStyle.label("", 14)
	_strength_value = HudStyle.label("", 14)
	_add_row(rows, HudIcon.Kind.COMPASS, "Entfernung", _distance_value)
	_add_row(rows, HudIcon.Kind.STAR, "Stärke", _strength_value)
	rows_margin.add_child(rows)
	column.add_child(rows_margin)

	# Aktionen
	var actions_margin := HudStyle.margin(10, 10)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	var red_bg := Color("4a1212")
	var red := Color("d8484a")
	_hostile_buttons.append(_action_button(HudStyle.tinted_button(HudIcon.Kind.TARGET, red_bg, red, Color("ff8a8a")), "spy", "Spionieren"))
	_hostile_buttons.append(_action_button(HudStyle.tinted_button(HudIcon.Kind.ROCKET, red_bg, red, Color("ff8a8a")), "attack", "Angreifen"))
	for b in _hostile_buttons:
		actions.add_child(b)
	actions.add_child(HudStyle.spacer())
	actions.add_child(_action_button(HudStyle.tinted_button(HudIcon.Kind.SEND, Color("10233a"), HudStyle.ACCENT, Color("9fd0ff")), "send", "Truppen senden"))
	actions_margin.add_child(actions)
	column.add_child(actions_margin)


func show_colony(colony: Dictionary) -> void:
	_colony = colony
	_tag_label.text = "[%s]" % colony.tag
	_player_label.text = colony.player
	_name_label.text = colony.name
	_distance_value.text = "%d AE" % colony.distance
	_strength_value.text = str(colony.strength)
	for b in _hostile_buttons:
		b.visible = not colony.own
	visible = true


func _action_button(b: Button, action: String, tooltip: String) -> Button:
	b.tooltip_text = tooltip
	b.pressed.connect(func(): action_requested.emit(action, _colony))
	return b


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
