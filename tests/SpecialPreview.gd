# Manual fixture, excluded from the production web export.
extends Node


var game
var busy := false


func _ready():
	var app = preload("res://App.tscn").instance()
	game = app.get_node("Game")
	game.specials_enabled = false
	add_child(app)
	var controls := CanvasLayer.new()
	add_child(controls)
	var font := DynamicFont.new()
	font.font_data = preload("res://Game/HUD/Fonts/FamilySansKR-Semibold.ttf")
	font.size = 25
	for i in range(4):
		var button := Button.new()
		button.text = ["수안 합체", "수민 ×5", "엄마 섞기", "왕모자"][i]
		button.add_font_override("font", font)
		button.rect_position = Vector2(30 + i * 166, 300)
		button.rect_size = Vector2(160, 58)
		controls.add_child(button)
		button.connect("pressed", self, "prepare", [[Fruit.Type.SUAN, Fruit.Type.SUMIN, Fruit.Type.MOM, Fruit.Type.WATERMELON][i]])
	var hint := Label.new()
	hint.text = "동작 검사 · 선택 후 화면을 눌러 떨어뜨리기"
	hint.add_font_override("font", font)
	hint.add_color_override("font_color", Color("#654254"))
	hint.rect_position = Vector2(55, 370)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.add_child(hint)
	yield(get_tree().create_timer(1.2), "timeout")
	prepare(Fruit.Type.MOM)


func make_piece(piece_type: int, point: Vector2):
	var piece = game.FruitScene.instance()
	game.fruits.add_child(piece)
	piece.type = piece_type
	piece.global_position = point
	game._connect_piece(piece)
	return piece


func prepare(piece_type: int):
	if busy:
		return
	busy = true
	game.reset()
	yield(get_tree().create_timer(0.3), "timeout")
	game.playing = true
	game.next_fruit_type = Fruit.Type.CHERRY
	var held_type: int = Fruit.Type.MELON if piece_type == Fruit.Type.WATERMELON else piece_type
	var special = make_piece(held_type, Vector2.ZERO)
	game.claw.position.x = 0.0
	game.claw.drop_position_x = 0.0
	game.claw.load_fruit(special)
	var types := [Fruit.Type.LEMON]
	var xs := [0]
	if piece_type == Fruit.Type.SUMIN:
		types = [Fruit.Type.STRAWBERRY]
	elif piece_type == Fruit.Type.WATERMELON:
		types = [Fruit.Type.MELON]
	elif piece_type == Fruit.Type.MOM:
		types = [Fruit.Type.CHERRY, Fruit.Type.STRAWBERRY, Fruit.Type.GRAPES, Fruit.Type.STRAWBERRY, Fruit.Type.CHERRY]
		xs = [-270, -135, 0, 135, 270]
	for i in range(types.size()):
		var face = make_piece(types[i], Vector2(xs[i], -Fruit.PARAMS[types[i]].radius))
		face.grow()
		face.fall(0)
	yield(get_tree().create_timer(0.9), "timeout")
	game.get_node("UserInputsController").set_enabled(true)
	busy = false
