extends Control


const FONT_DATA := preload("res://Game/HUD/Fonts/FamilySansKR-Semibold.ttf")
var remaining := 0.0
var speaker_ref
var anchor := Vector2.ZERO
var speaker_radius := 35.0
var tail_top := false
var tail_x := 80.0
var panel := Panel.new()
var label := Label.new()
var font := DynamicFont.new()
var panel_height := 80.0


func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font.font_data = FONT_DATA
	font.size = 30
	font.use_filter = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffafc")
	style.border_color = Color("#ef8eae")
	style.set_border_width_all(3)
	style.set_corner_radius_all(22)
	panel.add_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	label.add_font_override("font", font)
	label.add_color_override("font_color", Color("#654254"))
	label.align = Label.ALIGN_CENTER
	label.valign = Label.VALIGN_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	hide()


func say(message: String, speaker = null, point := Vector2.ZERO):
	speaker_ref = weakref(speaker) if is_instance_valid(speaker) else null
	anchor = point
	label.text = message
	var width := 0.0
	for line in message.split("\n"):
		width = max(width, font.get_string_size(line).x)
	panel_height = float(message.split("\n").size()) * 41.0 + 28.0
	rect_size = Vector2(clamp(width + 44.0, 180.0, 440.0), panel_height + 14.0)
	remaining = 2.8
	modulate.a = 1.0
	show()
	_update_position()


func clear():
	remaining = 0.0
	speaker_ref = null
	hide()


func _process(delta):
	if remaining <= 0.0:
		return
	remaining -= delta
	if remaining <= 0.0:
		clear()
		return
	modulate.a = min(1.0, remaining / 0.35)
	_update_position()


func _update_position():
	var speaker = speaker_ref.get_ref() if speaker_ref else null
	if is_instance_valid(speaker):
		anchor = speaker.get_global_transform_with_canvas().origin
		speaker_radius = speaker.radius
	var viewport_size := get_viewport_rect().size
	tail_top = anchor.y < 320.0
	var y := anchor.y + speaker_radius + 16.0 if tail_top else anchor.y - speaker_radius - rect_size.y - 16.0
	rect_position = Vector2(clamp(anchor.x - rect_size.x * 0.5, 16.0, viewport_size.x - rect_size.x - 16.0), clamp(y, 190.0, viewport_size.y - rect_size.y - 16.0))
	tail_x = clamp(anchor.x - rect_position.x, 24.0, rect_size.x - 24.0)
	panel.rect_position = Vector2(0.0, 14.0 if tail_top else 0.0)
	panel.rect_size = Vector2(rect_size.x, panel_height)
	label.rect_position = panel.rect_position + Vector2(16.0, 10.0)
	label.rect_size = panel.rect_size - Vector2(32.0, 20.0)
	update()


func _draw():
	var tip_y := 0.0 if tail_top else rect_size.y
	var base_y := 16.0 if tail_top else panel_height - 2.0
	var points := PoolVector2Array([Vector2(tail_x - 13.0, base_y), Vector2(tail_x, tip_y), Vector2(tail_x + 13.0, base_y)])
	draw_colored_polygon(points, Color("#fffafc"))
	draw_polyline(points, Color("#ef8eae"), 3.0, true)
