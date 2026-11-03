extends Node2D


const HEART := preload("res://Game/Fruits/heart-particle.svg")
const FONT_DATA := preload("res://Game/HUD/Fonts/FamilySansKR-Semibold.ttf")
var blast_radius := 185.0
var elapsed := 0.0
var shout := Label.new()
var caption := "펑!"
var sound_pitch := 0.65


func _ready():
	var font := DynamicFont.new()
	font.font_data = FONT_DATA
	font.size = 48
	font.outline_size = 4
	font.outline_color = Color.white
	shout.add_font_override("font", font)
	shout.add_color_override("font_color", Color("#f4759e"))
	shout.text = caption
	shout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shout.rect_size = font.get_string_size(caption)
	shout.rect_position = Vector2(-shout.rect_size.x * 0.5, -68)
	add_child(shout)
	var audio := AudioStreamPlayer.new()
	audio.stream = preload("res://Game/Fruits/pop.mp3")
	audio.pitch_scale = sound_pitch
	audio.volume_db = -6.0
	add_child(audio)
	audio.play()


func _process(delta):
	elapsed += delta
	if elapsed >= 0.75:
		queue_free()
		return
	shout.modulate.a = 1.0 - elapsed / 0.75
	shout.rect_position.y = -68.0 - elapsed * 35.0
	update()


func _draw():
	var t := clamp(elapsed / 0.75, 0.0, 1.0)
	var radius := blast_radius * (1.0 - pow(1.0 - t, 3.0))
	draw_arc(Vector2.ZERO, max(1.0, radius), 0.0, TAU, 80, Color(1.0, 0.56, 0.71, (1.0 - t) * 0.8), max(1.0, 9.0 * (1.0 - t)), true)
	for i in range(12):
		var direction := Vector2.UP.rotated(TAU * float(i) / 12.0)
		var position := direction * radius * (0.65 + float(i % 3) * 0.12)
		var size := 34.0 * (1.0 - t) + 8.0
		var color := Color(1.0, 0.5, 0.69, 1.0 - t) if i % 2 == 0 else Color(1.0, 0.78, 0.38, 1.0 - t)
		draw_texture_rect(HEART, Rect2(position - Vector2.ONE * size * 0.5, Vector2.ONE * size), false, color)
