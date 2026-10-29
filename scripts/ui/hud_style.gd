class_name HudStyle
extends RefCounted
## Gemeinsame Farben, Styleboxen und Widget-Helfer für das dunkle Spiel-HUD.

const BG := Color("0b0b0c")
const PANEL := Color("151516")
const PANEL_DARK := Color("0e0e0f")
const BORDER := Color("2a2a2d")
const ACCENT := Color("3d9bff")
const TEXT := Color("d8d8da")
const TEXT_DIM := Color("7c7c82")
const GOOD := Color("5ad65a")

static var _bold: FontVariation


static func bold_font() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.7
	return _bold


static func panel_box(bg := PANEL, border := BORDER, radius := 4, pad := 8.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(pad)
	sb.anti_aliasing = true
	return sb


static func label(text: String, font_size := 14, color := TEXT, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", bold_font())
	return l


static func icon(kind: HudIcon.Kind, color: Color, px := 16.0) -> HudIcon:
	var i := HudIcon.new()
	i.kind = kind
	i.color = color
	i.custom_minimum_size = Vector2(px, px)
	i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return i


static func margin(h: int, v: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", h)
	m.add_theme_constant_override("margin_right", h)
	m.add_theme_constant_override("margin_top", v)
	m.add_theme_constant_override("margin_bottom", v)
	return m


static func style_button(b: Button, radius := 4) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", panel_box(PANEL, BORDER, radius, 0))
	b.add_theme_stylebox_override("hover", panel_box(Color("1e1e21"), Color("3c3c41"), radius, 0))
	b.add_theme_stylebox_override("pressed", panel_box(Color("101012"), ACCENT.darkened(0.3), radius, 0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Button ohne Text, dessen Inhalt (Icons, Labels) zentriert als Kind-Container liegt.
static func content_button(content: Control, min_size: Vector2, radius := 4) -> Button:
	var b := Button.new()
	b.custom_minimum_size = min_size
	style_button(b, radius)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(content)
	b.add_child(center)
	_ignore_mouse(content)
	return b


static func icon_button(kind: HudIcon.Kind, min_size: Vector2, color := TEXT_DIM, circular := false) -> Button:
	var px := minf(min_size.x, min_size.y) * 0.55
	var radius := int(min_size.y * 0.5) if circular else 4
	return content_button(icon(kind, color, px), min_size, radius)


static func tinted_button(kind: HudIcon.Kind, bg: Color, border: Color, icon_color: Color, min_size := Vector2(34, 34)) -> Button:
	var b := icon_button(kind, min_size, icon_color)
	b.add_theme_stylebox_override("normal", panel_box(bg, border.darkened(0.2), 3, 0))
	b.add_theme_stylebox_override("hover", panel_box(bg.lightened(0.1), border, 3, 0))
	b.add_theme_stylebox_override("pressed", panel_box(bg.darkened(0.2), border, 3, 0))
	return b


static func close_button() -> Button:
	var b := Button.new()
	b.text = "×"
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_color_override("font_color", TEXT_DIM)
	b.add_theme_color_override("font_hover_color", TEXT)
	return b


static func spacer() -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


static func progress_bar(width := 86.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 5)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("1b2433")
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## 14000000 -> "14.000.000"
static func format_thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = "." + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out


## 70800 -> "19:40:00"
static func format_duration(seconds: int) -> String:
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]


static func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
