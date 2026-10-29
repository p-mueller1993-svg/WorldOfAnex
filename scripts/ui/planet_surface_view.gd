class_name PlanetSurfaceView
extends Control
## Isometrische Planetenoberfläche mit 10×10 bis 700×700 Kacheln.
## Das Gelände ist eine Rauschtextur mit einem Pixel pro Kachel, die isometrisch verzerrt in einem
## einzigen Draw-Call gezeichnet wird. Objekte (Kolonien, Kristalle) werden deterministisch aus Seed
## und Kachelkoordinate berechnet und pro Chunk gecacht; gezeichnet wird nur der sichtbare Ausschnitt.

signal colony_selected(colony: Dictionary)
signal selection_cleared

const MIN_MAP_SIZE := 10
const MAX_MAP_SIZE := 700
const TILE_W := 64.0
const TILE_H := 32.0
const MIN_ZOOM := 0.35
const MAX_ZOOM := 2.5
const AE_PER_TILE := 37.0
const HOME_NAME := "Woox 5"
const OWN_TAG := "WOX"
const CHUNK := 32
## Geländegrenzen im normierten Rauschwert (0..1): darunter Senke, darüber Anhöhe
const LOW_LEVEL := 0.42
const HIGH_LEVEL := 0.64

enum Obj { NONE, COLONY, CRYSTAL, GRASS }

const PALETTES := {
	"Eisplanet": {"low": Color("8ad8ec"), "mid": Color("e6f2f7"), "high": Color("fbfdff"), "grid": Color("b9d6e2"), "decor": Color("8d9b70"), "dome": Color("2c5482"), "crystal": Color("2f86e8")},
	"Wüstenplanet": {"low": Color("b5652a"), "mid": Color("dc9a55"), "high": Color("efc27f"), "grid": Color("a8693a"), "decor": Color("6f7a3a"), "dome": Color("5a4a6a"), "crystal": Color("c9d3e0")},
	"Lavaplanet": {"low": Color("e0521c"), "mid": Color("3a2622"), "high": Color("54392f"), "grid": Color("1e1412"), "decor": Color("ff8a3a"), "dome": Color("6a7380"), "crystal": Color("ffcc33")},
	"Gasriese": {"low": Color("6a2a8e"), "mid": Color("8a45b0"), "high": Color("b27ad0"), "grid": Color("5a2478"), "decor": Color("e05a8a"), "dome": Color("2a3550"), "crystal": Color("4fa0ff")},
	"Dschungelplanet": {"low": Color("3f8fb0"), "mid": Color("4f9a34"), "high": Color("6fb84a"), "grid": Color("3d7a2a"), "decor": Color("2e5e1f"), "dome": Color("3a4f7a"), "crystal": Color("3fd25a")},
}

const NAME_PARTS := ["Syndi", "Nova", "Krat", "Vel", "Orio", "Zan", "Tera", "Mor", "Lux", "Qua", "Dra", "Hel"]
const NAME_ENDS := ["cate", "ra", "on", "ix", "heim", "polis", "dor", "ka", "ys", "ar"]
const TAGS := ["BPD", "WOX", "KRN", "ZRX", "NOV", "ICE"]
const PLAYERS := ["leuschtrauschkugel", "Frostbeule", "xXSniperXx", "Zarkon", "MiraNova", "Eiszapfen", "DarkNebula", "Quasar77"]

var map_size := 50

var _planet: Dictionary = {}
var _palette: Dictionary = PALETTES["Eisplanet"]
var _seed := 0
var _noise := FastNoiseLite.new()
var _ground := NoiseTexture2D.new()
## normierte Rauschwerte (0..255) pro Kachel, zeilenweise
var _terrain_bytes := PackedByteArray()
## Chunk-Koordinate -> Array von [Vector2i, Obj]
var _chunks := {}
var _home := Vector2i.ZERO
var _selected := Vector2i(-1, -1)
var _hovered := Vector2i(-1, -1)
## Weltpunkt (isometrische Pixel bei Zoom 1), der in der Mitte der Ansicht liegt
var _camera := Vector2.ZERO
var _zoom := 1.0
var _mouse_down := false
var _dragging := false
var _press_pos := Vector2.ZERO


func _init() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	clip_contents = true
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 0.12
	_noise.fractal_octaves = 2
	_ground.noise = _noise
	_ground.generate_mipmaps = false
	_ground.changed.connect(queue_redraw)
	texture_filter = TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)


func open(planet: Dictionary, size_in_tiles: int) -> void:
	_planet = planet
	_palette = PALETTES.get(planet.type, PALETTES["Eisplanet"])
	_seed = hash(planet.name)
	_noise.seed = _seed
	_ground.color_ramp = _ground_ramp()
	set_map_size(size_in_tiles)


func set_map_size(size_in_tiles: int) -> void:
	map_size = clampi(size_in_tiles, MIN_MAP_SIZE, MAX_MAP_SIZE)
	# Textur und Geländedaten nutzen dieselbe Normierung, damit Farbe und Logik übereinstimmen
	var img := _noise.get_image(map_size, map_size)
	img.convert(Image.FORMAT_L8)
	_terrain_bytes = img.get_data()
	_ground.width = map_size
	_ground.height = map_size
	_chunks.clear()
	_home = Vector2i(map_size / 2, map_size / 2)
	_zoom = 1.0
	_hovered = Vector2i(-1, -1)
	clear_selection()
	center_on_home()


func center_on_home() -> void:
	_camera = _tile_to_world(Vector2(_home))
	queue_redraw()


func zoom_by(factor: float) -> void:
	_zoom_at(size * 0.5, factor)


func clear_selection() -> void:
	_selected = Vector2i(-1, -1)
	queue_redraw()
	selection_cleared.emit()


func home_colony() -> Dictionary:
	return _colony_data(_home)


# --- Koordinaten ----------------------------------------------------------

func _tile_to_world(t: Vector2) -> Vector2:
	return Vector2((t.x - t.y) * TILE_W * 0.5, (t.x + t.y) * TILE_H * 0.5)


func _world_to_tile(w: Vector2) -> Vector2:
	var fx := w.x / (TILE_W * 0.5)
	var fy := w.y / (TILE_H * 0.5)
	return Vector2((fx + fy) * 0.5, (fy - fx) * 0.5)


func _screen_to_world(p: Vector2) -> Vector2:
	return (p - size * 0.5) / _zoom + _camera


func _world_to_screen(w: Vector2) -> Vector2:
	return (w - _camera) * _zoom + size * 0.5


func _screen_to_tile(p: Vector2) -> Vector2i:
	var t := _world_to_tile(_screen_to_world(p))
	return Vector2i(roundi(t.x), roundi(t.y))


func _in_map(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < map_size and t.y < map_size


## Kachelbereich, der den Bildschirm abdeckt (plus Rand für hochragende Objekte)
func _visible_tiles() -> Rect2i:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]:
		var t := _world_to_tile(_screen_to_world(p))
		lo = lo.min(t)
		hi = hi.max(t)
	var x0 := clampi(floori(lo.x) - 1, 0, map_size)
	var y0 := clampi(floori(lo.y) - 1, 0, map_size)
	var x1 := clampi(ceili(hi.x) + 3, 0, map_size)
	var y1 := clampi(ceili(hi.y) + 3, 0, map_size)
	return Rect2i(x0, y0, x1 - x0, y1 - y0)


# --- Prozedurale Welt -----------------------------------------------------

func _ground_ramp() -> Gradient:
	var low: Color = _palette.low
	var mid: Color = _palette.mid
	var high: Color = _palette.high
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.3, LOW_LEVEL, 0.53, HIGH_LEVEL])
	g.colors = PackedColorArray([low.darkened(0.08), low, mid.darkened(0.03), mid, high])
	return g


func _terrain(x: int, y: int) -> int:
	var v := _terrain_bytes[y * map_size + x] / 255.0
	if v < LOW_LEVEL:
		return 0
	return 2 if v > HIGH_LEVEL else 1


func _tile_hash(x: int, y: int) -> int:
	return hash(Vector3i(x, y, _seed))


func _object_at(x: int, y: int, h: int, terrain: int) -> int:
	if absi(x - _home.x) <= 1 and absi(y - _home.y) <= 1:
		return Obj.NONE
	var roll := posmod(h, 10000)
	var colony_rate := 110 if map_size > 50 else 350
	if roll < colony_rate:
		return Obj.COLONY
	if roll < colony_rate + 160:
		return Obj.CRYSTAL
	if terrain == 1 and roll < colony_rate + 900:
		return Obj.GRASS
	return Obj.NONE


func _chunk_objects(chunk: Vector2i) -> Array:
	if _chunks.has(chunk):
		return _chunks[chunk]
	var list := []
	for y in range(chunk.y * CHUNK, mini((chunk.y + 1) * CHUNK, map_size)):
		for x in range(chunk.x * CHUNK, mini((chunk.x + 1) * CHUNK, map_size)):
			var obj := _object_at(x, y, _tile_hash(x, y), _terrain(x, y))
			if obj != Obj.NONE:
				list.append([Vector2i(x, y), obj])
	_chunks[chunk] = list
	return list


func _is_colony(t: Vector2i) -> bool:
	if not _in_map(t):
		return false
	return t == _home or _object_at(t.x, t.y, _tile_hash(t.x, t.y), _terrain(t.x, t.y)) == Obj.COLONY


func _colony_data(t: Vector2i) -> Dictionary:
	if t == _home:
		return {"name": HOME_NAME, "tag": OWN_TAG, "player": "Bümsbüdä2000!", "strength": 2270,
			"distance": 0, "own": true, "home": true, "scale": 1.0, "tile": t}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(t.x, t.y, _seed + 1))
	var colony_name: String = NAME_PARTS[rng.randi() % NAME_PARTS.size()] + NAME_ENDS[rng.randi() % NAME_ENDS.size()]
	if rng.randf() < 0.4:
		colony_name += str(rng.randi_range(1, 9))
	var tag: String = TAGS[rng.randi() % TAGS.size()]
	var strength := rng.randi_range(150, 3200)
	return {
		"name": colony_name, "tag": tag, "player": PLAYERS[rng.randi() % PLAYERS.size()], "strength": strength,
		"distance": roundi(Vector2(t).distance_to(Vector2(_home)) * AE_PER_TILE),
		"own": tag == OWN_TAG, "home": false, "scale": remap(strength, 150, 3200, 0.75, 1.25), "tile": t,
	}


# --- Zeichnen -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0a0d12"))
	if _planet.is_empty():
		return
	var hw := TILE_W * 0.5 * _zoom
	var hh := TILE_H * 0.5 * _zoom
	var origin := _world_to_screen(Vector2.ZERO)

	# Gelände: Texturpixel (x, y) wird auf die Raute der Kachel (x, y) abgebildet
	draw_set_transform_matrix(Transform2D(Vector2(hw, hh), Vector2(-hw, hh), origin + Vector2(0, -hh)))
	draw_texture(_ground, Vector2.ZERO)
	draw_set_transform_matrix(Transform2D.IDENTITY)

	var vis := _visible_tiles()
	if _zoom >= 0.5:
		_draw_grid(vis, origin, hw, hh)

	var objects: Array = []
	for cy in range(vis.position.y / CHUNK, (vis.end.y - 1) / CHUNK + 1):
		for cx in range(vis.position.x / CHUNK, (vis.end.x - 1) / CHUNK + 1):
			for o in _chunk_objects(Vector2i(cx, cy)):
				var t: Vector2i = o[0]
				if vis.has_point(t):
					_collect_object(objects, t, o[1], origin, hw, hh)
	if vis.has_point(_home):
		_collect_object(objects, _home, Obj.NONE, origin, hw, hh)
	# angehobene Kacheln ohne Objekt sind sonst nicht in der Liste
	for t in [_hovered, _selected]:
		if _in_map(t) and vis.has_point(t) and t != _home \
				and _object_at(t.x, t.y, _tile_hash(t.x, t.y), _terrain(t.x, t.y)) == Obj.NONE:
			_collect_object(objects, t, Obj.NONE, origin, hw, hh)

	# Objekte von hinten nach vorne, damit vordere Kuppeln hintere überdecken
	objects.sort_custom(func(a, b): return a[0] < b[0])
	for o in objects:
		_draw_object(o[1], o[2], o[3])


func _collect_object(objects: Array, t: Vector2i, obj: int, origin: Vector2, hw: float, hh: float) -> void:
	var c := origin + Vector2((t.x - t.y) * hw, (t.x + t.y) * hh)
	if c.x < -hw * 2.0 or c.x > size.x + hw * 2.0 or c.y < -hh * 2.0 or c.y > size.y + hh * 6.0:
		return
	objects.append([t.x + t.y, t, c, obj])


func _draw_grid(vis: Rect2i, origin: Vector2, hw: float, hh: float) -> void:
	var pts := PackedVector2Array()
	var y0 := vis.position.y - 0.5
	var y1 := vis.end.y - 0.5
	for x in range(vis.position.x, vis.end.x + 1):
		pts.append(origin + Vector2((x - 0.5 - y0) * hw, (x - 0.5 + y0) * hh))
		pts.append(origin + Vector2((x - 0.5 - y1) * hw, (x - 0.5 + y1) * hh))
	var x0 := vis.position.x - 0.5
	var x1 := vis.end.x - 0.5
	for y in range(vis.position.y, vis.end.y + 1):
		pts.append(origin + Vector2((x0 - y + 0.5) * hw, (x0 + y - 0.5) * hh))
		pts.append(origin + Vector2((x1 - y + 0.5) * hw, (x1 + y - 0.5) * hh))
	if not pts.is_empty():
		draw_multiline(pts, Color(_palette.grid, 0.7), 1.0)


func _draw_object(t: Vector2i, tile_center: Vector2, obj: int) -> void:
	var c := tile_center
	if t == _hovered or t == _selected:
		c = _draw_raised_tile(t, c)
	if t == _home or obj == Obj.COLONY:
		var data := _colony_data(t)
		if data.own:
			_draw_tile_marker(c, Color(1.0, 0.72, 0.3, 0.35), Color("f0a640"))
		if t == _selected:
			_draw_tile_marker(c, Color(0.24, 0.6, 1.0, 0.3), HudStyle.ACCENT)
		if t == _home:
			_draw_home(c, _zoom)
		else:
			_draw_dome(c, _zoom * data.scale, _palette.dome)
	elif obj == Obj.CRYSTAL:
		_draw_crystal(c, _zoom)
	elif obj == Obj.GRASS and _zoom >= 0.5:
		_draw_grass(c, _zoom, t)


## Zeichnet die Kachel als angehobenen Block und gibt die Mitte der Oberseite zurück.
func _draw_raised_tile(t: Vector2i, c: Vector2) -> Vector2:
	var hw := TILE_W * 0.5 * _zoom
	var hh := TILE_H * 0.5 * _zoom
	var top := c - Vector2(0, 12.0 * _zoom)
	var color := _ground.color_ramp.sample(_terrain_bytes[t.y * map_size + t.x] / 255.0)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-hw, 0), c + Vector2(0, hh), top + Vector2(0, hh), top + Vector2(-hw, 0)]), color.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, hh), c + Vector2(hw, 0), top + Vector2(hw, 0), top + Vector2(0, hh)]), color.darkened(0.38))
	var face := PackedVector2Array([top + Vector2(0, -hh), top + Vector2(hw, 0), top + Vector2(0, hh), top + Vector2(-hw, 0)])
	draw_colored_polygon(face, color.lightened(0.08))
	face.append(face[0])
	draw_polyline(face, Color(1, 1, 1, 0.6), maxf(1.0, _zoom), true)
	return top


func _draw_tile_marker(c: Vector2, fill: Color, line: Color) -> void:
	var hw := TILE_W * 0.5 * _zoom
	var hh := TILE_H * 0.5 * _zoom
	var pts := PackedVector2Array([c + Vector2(0, -hh), c + Vector2(hw, 0), c + Vector2(0, hh), c + Vector2(-hw, 0)])
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, line, maxf(1.0, 2.0 * _zoom), true)


func _draw_dome(c: Vector2, z: float, color: Color) -> void:
	var rx := 21.0 * z
	var ry := 18.0 * z
	var base := c + Vector2(0, 2.0 * z)
	draw_colored_polygon(_ellipse(base + Vector2(3.0 * z, 1.5 * z), rx * 1.15, rx * 0.45), Color(0, 0, 0, 0.18))
	# obere Kuppel plus abgeflachter Sockel als ein Polygon
	var pts := _arc(base, rx, ry, PI, TAU, 14)
	pts.append_array(_arc(base, rx, rx * 0.35, PI / 8, PI - PI / 8, 6))
	draw_colored_polygon(pts, color)
	draw_colored_polygon(_ellipse(base + Vector2(-rx * 0.3, -ry * 0.55), rx * 0.38, ry * 0.26), color.lightened(0.3))
	if z >= 0.5:
		var mast_top := base + Vector2(rx * 1.05, -ry * 0.8)
		draw_line(base + Vector2(rx * 1.05, 0), mast_top, Color("1d2733"), maxf(1.0, 1.5 * z))
		draw_circle(mast_top, 1.5 * z, Color("1d2733"))


func _draw_home(c: Vector2, z: float) -> void:
	var hw := TILE_W * 0.5 * z
	var hh := TILE_H * 0.5 * z
	draw_rect(Rect2(c + Vector2(-2.0 * z, -hh - 22.0 * z), Vector2(4.0 * z, 18.0 * z)), Color("1d2733"))
	draw_circle(c + Vector2(0, -hh - 22.0 * z), 3.0 * z, HudStyle.ACCENT)
	_draw_dome(c + Vector2(-hw * 0.4, -hh * 0.15), z * 0.7, _palette.dome)
	_draw_dome(c + Vector2(hw * 0.4, -hh * 0.15), z * 0.7, _palette.dome)
	_draw_dome(c + Vector2(0, hh * 0.3), z * 0.9, _palette.dome.lightened(0.1))


func _draw_crystal(c: Vector2, z: float) -> void:
	var color: Color = _palette.crystal
	for shard in [[Vector2(-5, 1), 8.0], [Vector2(0, -1), 13.0], [Vector2(5, 2), 7.0]]:
		var p: Vector2 = c + shard[0] * z
		var h: float = shard[1] * z
		var w := 3.5 * z
		var tip := p + Vector2(0, -h)
		var bottom := p + Vector2(0, h * 0.25)
		draw_colored_polygon(PackedVector2Array([tip, p + Vector2(w, -h * 0.3), bottom, p + Vector2(-w, -h * 0.3)]), color)
		draw_colored_polygon(PackedVector2Array([tip, bottom, p + Vector2(-w, -h * 0.3)]), color.lightened(0.4))


func _draw_grass(c: Vector2, z: float, t: Vector2i) -> void:
	var h := hash(t)
	var offset := Vector2(posmod(h, 17) - 8, posmod(h / 17, 9) - 4) * z
	for k in 3:
		var base := c + offset + Vector2((k - 1) * 2.0 * z, 0)
		draw_line(base, base + Vector2((k - 1) * 2.0 * z, -6.0 * z), _palette.decor, maxf(1.0, z))


func _arc(center: Vector2, rx: float, ry: float, from: float, to: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments + 1:
		var a := lerpf(from, to, float(i) / segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# --- Eingabe --------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_at(event.position, 1.15)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_at(event.position, 1.0 / 1.15)
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				if event.pressed:
					_mouse_down = true
					_dragging = false
					_press_pos = event.position
				else:
					if not _dragging and event.button_index == MOUSE_BUTTON_LEFT:
						_click(event.position)
					_mouse_down = false
					_dragging = false
	elif event is InputEventMouseMotion:
		# Loslassen kann verloren gehen (z. B. über einem Popup) – dann zählt der aktuelle Tastenzustand
		if event.button_mask == 0:
			_mouse_down = false
			_dragging = false
		if _mouse_down and not _dragging and event.position.distance_to(_press_pos) > 4.0:
			_dragging = true
		if _dragging:
			_camera -= event.relative / _zoom
			_clamp_camera()
			queue_redraw()
		else:
			_update_hover(event.position)
	elif event is InputEventMagnifyGesture:
		_zoom_at(event.position, event.factor)
	elif event is InputEventPanGesture:
		_camera += event.delta * 20.0 / _zoom
		_clamp_camera()
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _hovered != Vector2i(-1, -1):
		_hovered = Vector2i(-1, -1)
		queue_redraw()


## Kachel unter dem Mauszeiger. Kuppeln ragen nach oben in die Kacheln dahinter,
## darum gewinnt eine Kolonie auf einer der Kacheln davor.
func _pick(p: Vector2) -> Vector2i:
	var t := _screen_to_tile(p)
	for candidate in [t, t + Vector2i(1, 1), t + Vector2i(1, 0), t + Vector2i(0, 1)]:
		if _is_colony(candidate):
			return candidate
	return t if _in_map(t) else Vector2i(-1, -1)


func _update_hover(p: Vector2) -> void:
	var t := _pick(p)
	mouse_default_cursor_shape = CURSOR_POINTING_HAND if _is_colony(t) else CURSOR_ARROW
	if t != _hovered:
		_hovered = t
		queue_redraw()


func _click(p: Vector2) -> void:
	var t := _pick(p)
	if _is_colony(t):
		_selected = t
		queue_redraw()
		colony_selected.emit(_colony_data(t))
	else:
		clear_selection()


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := _screen_to_world(screen_pos)
	_zoom = clampf(_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	_camera += before - _screen_to_world(screen_pos)
	_clamp_camera()
	queue_redraw()


func _clamp_camera() -> void:
	var half_width := map_size * TILE_W * 0.5
	_camera.x = clampf(_camera.x, -half_width, half_width)
	_camera.y = clampf(_camera.y, 0.0, map_size * TILE_H)
