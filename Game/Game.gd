extends Node2D


signal menu_pressed

signal score_updated(score)
signal multiplicator_updated(multiplicator)
signal next_fruit_updated(type)

signal ended


const TOP_SCREEN_MARIN := 350 #px
const BOTTOM_SCREEN_MARGIN := 50 #px
const CLAW_BOX_MARING := 105


const CLAW_FRUITS := [Fruit.Type.CHERRY, Fruit.Type.STRAWBERRY, Fruit.Type.GRAPES, Fruit.Type.LEMON, Fruit.Type.ORANGE]
const CLAW_START_SEQUENCE := [Fruit.Type.CHERRY, Fruit.Type.CHERRY, Fruit.Type.STRAWBERRY, Fruit.Type.GRAPES]
const FRUIT_FALL_FUSION_IMPULSE := 500

const MULTIPLICATOR_MAX := 8
const BOMB_CHANCE := 0.01
const BOMB_BLAST_RADIUS := 185.0
const Speech := preload("res://Game/HUD/FamilySpeech.gd")
const BombBurst := preload("res://Game/Effects/BombBurst.gd")
const FAMILY_MESSAGES := [
	"박근오 아빠,\n사랑해요!",
	"정윤정 엄마,\n사랑해요!",
	"아빠 엄마 사랑해요!",
	"메롱~",
	"꿀꿀이! 꿀꿀~",
	"고릴라! 우끼끼~",
]

export(PackedScene) var FruitScene

var claw_index := 0 # total amout of fruits loaded
var fruits_unlocked = [] # fruit autorized to be loaded, fruit of the claw list can only be loaded if already seen in the current game

var next_fruit_type: int setget set_next_fruit_type

var score := 0 setget set_score
var multiplicator := 0 setget set_multiplicator
var playing := false
var bombs_enabled := true
var bomb_rng := RandomNumberGenerator.new()
var speech_rng := RandomNumberGenerator.new()
var speech_timer := Timer.new()
var family_speech = Speech.new()
var message_cursor := 0
var round_id := 0


onready var foreground := $Foreground #HUD

onready var multiplicator_timer := $MultiplicatorTimer
onready var pop_timer := $PopTimer
onready var claw := $Claw
onready var box := $Box
onready var fruits := $Fruits
onready var camera := $Camera2D


func _ready():
	bomb_rng.randomize()
	speech_rng.randomize()
	speech_timer.one_shot = true
	speech_timer.connect("timeout", self, "_on_speech_timeout")
	add_child(speech_timer)
	foreground.add_child(family_speech)


func _on_MenuButton_pressed():
	$UserInputsController.cancel_drag()
	emit_signal("menu_pressed")


func set_area(p_view_rect: Rect2, p_safe_rect: Rect2):
	
	var margin_top := abs(p_view_rect.position.y - p_safe_rect.position.y)
	var margin_bottom := abs(p_view_rect.size.y - p_safe_rect.size.y) - margin_top
	
	claw.position.y = -(p_safe_rect.size.y - TOP_SCREEN_MARIN + CLAW_BOX_MARING - margin_top)
	
	var box_area := p_safe_rect.size
	box_area.y -= TOP_SCREEN_MARIN + margin_top
	box.set_size(box_area)
	claw.set_horizontal_bounds(box_area.x)
	
	camera.position.y = -(p_view_rect.size.y*0.5) + margin_bottom + BOTTOM_SCREEN_MARGIN


func set_score(p_score: int):
	score = p_score
	emit_signal("score_updated", score)


func set_multiplicator(p_multiplicator: int):
	multiplicator = p_multiplicator
	emit_signal("multiplicator_updated", multiplicator)


func set_next_fruit_type(p_type: int):
	next_fruit_type = p_type
	emit_signal("next_fruit_updated", next_fruit_type)


func unlock_fruit(type: int):
	if not type in CLAW_FRUITS:
		return
	
	if type in fruits_unlocked:
		return
	
	fruits_unlocked.append(type)


func roll_next_fruit() -> int:
	if bombs_enabled and _is_bomb_roll(bomb_rng.randf()):
		return Fruit.Type.BOMB
	var type = Fruit.Type.CHERRY
	if claw_index < len(CLAW_START_SEQUENCE):
		type = CLAW_START_SEQUENCE[claw_index] # in this order
		claw_index += 1 
		
	else:
		var rn := randi() % len(fruits_unlocked)
		type =  fruits_unlocked[rn]
	
	return type


func _is_bomb_roll(roll: float) -> bool:
	return roll >= 0.0 and roll < BOMB_CHANCE


func load_claw():
	
	var fruit: Fruit = FruitScene.instance()
	fruits.add_child(fruit)
	fruit.type = next_fruit_type
	fruit.connect("fusionned", self, "_on_fruit_fusionned", [fruit])
	fruit.connect("bomb_triggered", self, "_on_bomb_triggered")
	
	claw.load_fruit(fruit)
	
	unlock_fruit(fruit.type)
	self.next_fruit_type = roll_next_fruit()
	

func _on_Claw_armed():
	if is_instance_valid(claw.current_fruit) and claw.current_fruit.type == Fruit.Type.BOMB:
		family_speech.say("폭탄이다!\n살짝 내려놔~", claw.current_fruit)
	load_claw()


func _on_fruit_fusionned(fruit_a: Fruit, fruit_b: Fruit):
	if not playing or fruit_a.deleting or fruit_b.deleting or fruit_a.popping or fruit_b.popping:
		return
	if fruit_a.type == Fruit.Type.BOMB or fruit_b.type == Fruit.Type.BOMB:
		return
	if Fruit.Type.WATERMELON == fruit_a.type:
		return
	fruit_a.fusionned = true
	fruit_b.fusionned = true
	
	self.multiplicator = min(MULTIPLICATOR_MAX, multiplicator + 1)
	self.score += (fruit_a.points + fruit_b.points) * multiplicator
	multiplicator_timer.start()
	
	var pos: Vector2 = (fruit_a.global_position + fruit_b.global_position) * 0.5 # center betwen two points
	fruit_a.delete(pos)
	fruit_b.delete(pos)
	
	call_deferred("new_fruit_fusion", Fruit.get_evolution_type_of(fruit_a.type), pos, round_id)


func new_fruit_fusion(p_type, pos, source_round := -1):
	if not playing or (source_round != -1 and source_round != round_id):
		return
	var new_fruit: Fruit = FruitScene.instance()
	fruits.add_child(new_fruit)
	new_fruit.type = p_type
	new_fruit.connect("fusionned", self, "_on_fruit_fusionned", [new_fruit])
	new_fruit.connect("bomb_triggered", self, "_on_bomb_triggered")
	
	unlock_fruit(new_fruit.type)
	
	new_fruit.global_position = pos
	new_fruit.fall(FRUIT_FALL_FUSION_IMPULSE)
	yield(new_fruit.grow(true), "completed")


func _on_MultiplicatorTimer_timeout():
	self.multiplicator = 0


func _on_Box_limit_reached():
	end()


func start():
	playing = true
	message_cursor = 0
	speech_timer.start(2.2)
	self.next_fruit_type = roll_next_fruit()
	load_claw()



func end():
	
	if not playing:
		return
	playing = false
	speech_timer.stop()
	family_speech.clear()
	$UserInputsController.cancel_drag()
	claw.unload()
	
	var fruits_sorted := fruits.get_children()
	fruits_sorted.sort_custom(self, "_comp_fruit_heigth")
	
	var max_time := 0.35
	var min_time := 0.1
	var fruits_amount = len(fruits_sorted)
	
	var i := 0
	for fruit in fruits_sorted:
		if not is_instance_valid(fruit) or fruit.deleting or fruit.popping:
			continue
		
		self.score += fruit.points
		fruit.pop()
	
		var time = lerp(max_time, min_time, float(i/5.0))
		i += 1
		
		pop_timer.start(time)
		yield(pop_timer, "timeout")
	
	
	pop_timer.start(1.0)
	yield(pop_timer, "timeout")
	emit_signal("ended")


func _comp_fruit_heigth(fruit_a: Fruit, fruit_b: Fruit):
	if fruit_a.in_danger == fruit_b.in_danger:
		return fruit_a.global_position.y < fruit_b.global_position.y
	
	return fruit_a.in_danger



func reset():
	playing = false
	round_id += 1
	speech_timer.stop()
	family_speech.clear()
	$UserInputsController.cancel_drag()
	self.score = 0
	self.multiplicator = 0
	multiplicator_timer.stop()
	
	claw_index = 0
	fruits_unlocked.clear()
	claw.unload()
	
	for fruit in fruits.get_children():
		fruit.delete()


func _on_speech_timeout():
	if not playing:
		return
	var speaker = claw.current_fruit
	if not is_instance_valid(speaker):
		for fruit in fruits.get_children():
			if not fruit.deleting and not fruit.popping and fruit.type != Fruit.Type.BOMB:
				speaker = fruit
				break
	if is_instance_valid(speaker):
		family_speech.say(FAMILY_MESSAGES[message_cursor % len(FAMILY_MESSAGES)], speaker)
		message_cursor += 1
	speech_timer.start(speech_rng.randf_range(7.0, 11.0))


func _on_bomb_triggered(bomb):
	call_deferred("_explode_bomb", bomb, round_id)


func _explode_bomb(bomb, source_round: int):
	if not playing or source_round != round_id or not is_instance_valid(bomb) or bomb.popping or bomb.deleting:
		return
	var center: Vector2 = bomb.global_position
	var burst = BombBurst.new()
	burst.blast_radius = BOMB_BLAST_RADIUS
	add_child(burst)
	burst.global_position = center
	family_speech.say("펑! 신난다~", null, burst.get_global_transform_with_canvas().origin)
	for fruit in fruits.get_children():
		if fruit == claw.current_fruit or fruit == claw.next_fruit:
			continue
		if fruit.mode != RigidBody2D.MODE_RIGID or fruit.deleting or fruit.popping:
			continue
		if fruit == bomb or center.distance_to(fruit.global_position) <= BOMB_BLAST_RADIUS + fruit.radius:
			self.score += fruit.points
			fruit.fusionned = true
			fruit.pop()
