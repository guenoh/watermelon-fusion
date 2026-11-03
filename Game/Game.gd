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
const SPECIAL_CHANCE := 0.02
const SPECIAL_TYPES := [Fruit.Type.BOMB, Fruit.Type.SUAN, Fruit.Type.SUMIN, Fruit.Type.MOM, Fruit.Type.DAD]
const DAD_MESSAGES := ["꿀꿀~", "시우야 안녕!"]
const COPY_COUNT := 5
const COPY_MERGE_DELAY := 1.25
const REMIX_DANGER_GRACE := 8.0
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
var specials_enabled := true
var special_rng := RandomNumberGenerator.new()
var speech_rng := RandomNumberGenerator.new()
var speech_timer := Timer.new()
var dad_speech_timer := Timer.new()
var family_speech = Speech.new()
var message_cursor := 0
var dad_message_cursor := 0
var round_id := 0


onready var foreground := $Foreground #HUD

onready var multiplicator_timer := $MultiplicatorTimer
onready var pop_timer := $PopTimer
onready var claw := $Claw
onready var box := $Box
onready var fruits := $Fruits
onready var camera := $Camera2D


func _ready():
	special_rng.randomize()
	speech_rng.randomize()
	speech_timer.one_shot = true
	speech_timer.connect("timeout", self, "_on_speech_timeout")
	add_child(speech_timer)
	dad_speech_timer.one_shot = true
	dad_speech_timer.connect("timeout", self, "_on_dad_speech_timeout")
	add_child(dad_speech_timer)
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
	if specials_enabled and _is_special_roll(special_rng.randf()):
		return SPECIAL_TYPES[special_rng.randi_range(0, len(SPECIAL_TYPES) - 1)]
	var type = Fruit.Type.CHERRY
	if claw_index < len(CLAW_START_SEQUENCE):
		type = CLAW_START_SEQUENCE[claw_index] # in this order
		claw_index += 1 
		
	else:
		var rn := randi() % len(fruits_unlocked)
		type =  fruits_unlocked[rn]
	
	return type


func _is_special_roll(roll: float) -> bool:
	return roll >= 0.0 and roll < SPECIAL_CHANCE


func load_claw():
	
	var fruit: Fruit = FruitScene.instance()
	fruits.add_child(fruit)
	fruit.type = next_fruit_type
	_connect_piece(fruit)
	
	claw.load_fruit(fruit)
	
	unlock_fruit(fruit.type)
	self.next_fruit_type = roll_next_fruit()
	

func _on_Claw_armed():
	if is_instance_valid(claw.current_fruit):
		match claw.current_fruit.type:
			Fruit.Type.BOMB:
				family_speech.say("폭탄이다!\n살짝 내려놔~", claw.current_fruit)
			Fruit.Type.SUAN:
				family_speech.say("수안이 등장!\n어떤 얼굴이든 합체!", claw.current_fruit)
			Fruit.Type.SUMIN:
				family_speech.say("수민이 등장!\n처음 닿은 얼굴이 5개!", claw.current_fruit)
			Fruit.Type.MOM:
				family_speech.say("엄마 왔다!\n바닥까지 쭉~", claw.current_fruit)
			Fruit.Type.DAD:
				family_speech.say("아빠 등장!\n아래 공들은 비켜~", claw.current_fruit)
	load_claw()


func _connect_piece(fruit):
	fruit.connect("fusionned", self, "_on_fruit_fusionned", [fruit])
	fruit.connect("bomb_triggered", self, "_on_bomb_triggered")
	fruit.connect("special_triggered", self, "_on_special_triggered")
	fruit.connect("remix_triggered", self, "_on_remix_triggered")
	fruit.connect("dad_dropped", self, "_on_dad_dropped")
	fruit.remix_floor_y = box.global_position.y


func _on_fruit_fusionned(fruit_a: Fruit, fruit_b: Fruit):
	if not playing or fruit_a.deleting or fruit_b.deleting or fruit_a.popping or fruit_b.popping:
		return
	if Fruit.is_special_type(fruit_a.type) or Fruit.is_special_type(fruit_b.type):
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
	_connect_piece(new_fruit)
	
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
	box.set_monitoring_enabled(true)
	$UserInputsController.set_enabled(true)
	message_cursor = 0
	dad_message_cursor = 0
	speech_timer.start(2.2)
	self.next_fruit_type = roll_next_fruit()
	load_claw()



func end():
	
	if not playing:
		return
	playing = false
	var ending_round := round_id
	box.set_monitoring_enabled(false)
	$UserInputsController.set_enabled(false)
	speech_timer.stop()
	dad_speech_timer.stop()
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
		if ending_round != round_id or playing:
			return
	
	
	pop_timer.start(1.0)
	yield(pop_timer, "timeout")
	if ending_round != round_id or playing:
		return
	emit_signal("ended")


func _comp_fruit_heigth(fruit_a: Fruit, fruit_b: Fruit):
	if fruit_a.in_danger == fruit_b.in_danger:
		return fruit_a.global_position.y < fruit_b.global_position.y
	
	return fruit_a.in_danger



func reset():
	playing = false
	round_id += 1
	pop_timer.stop()
	box.set_monitoring_enabled(false)
	$UserInputsController.set_enabled(false)
	speech_timer.stop()
	dad_speech_timer.stop()
	dad_message_cursor = 0
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
	if family_speech.visible:
		speech_timer.start(2.0)
		return
	var speaker = claw.current_fruit
	if is_instance_valid(speaker) and speaker.type == Fruit.Type.DAD:
		speech_timer.start(2.0)
		return
	if not is_instance_valid(speaker):
		for fruit in fruits.get_children():
			if not fruit.deleting and not fruit.popping and fruit.type != Fruit.Type.BOMB and fruit.type != Fruit.Type.DAD:
				speaker = fruit
				break
	if is_instance_valid(speaker):
		family_speech.say(FAMILY_MESSAGES[message_cursor % len(FAMILY_MESSAGES)], speaker)
		message_cursor += 1
	speech_timer.start(speech_rng.randf_range(7.0, 11.0))


func _on_dad_dropped(dad):
	call_deferred("_clear_below_dad", dad, round_id)


func _clear_below_dad(dad, source_round: int):
	if not playing or source_round != round_id or not is_instance_valid(dad) or dad.deleting or dad.popping or dad.dad_smash_used:
		return
	dad.dad_smash_used = true
	var center: Vector2 = dad.global_position
	for fruit in fruits.get_children():
		if fruit == dad or fruit == claw.current_fruit or fruit == claw.next_fruit:
			continue
		if fruit.mode != RigidBody2D.MODE_RIGID or fruit.deleting or fruit.popping:
			continue
		if fruit.global_position.y > center.y:
			self.score += fruit.points
			fruit.fusionned = true
			fruit.pop()
	var burst = BombBurst.new()
	burst.caption = "쿵!"
	burst.sound_pitch = 0.75
	burst.blast_radius = claw.half_width * 1.5
	add_child(burst)
	burst.global_position = center
	dad_speech_timer.start(2.0)


func _on_dad_speech_timeout():
	if not playing:
		return
	var dads := []
	for fruit in fruits.get_children():
		if fruit.type == Fruit.Type.DAD and fruit.dad_smash_used and fruit.mode == RigidBody2D.MODE_RIGID and not fruit.deleting and not fruit.popping:
			dads.append(fruit)
	if dads.empty():
		return
	var speaker = dads[dad_message_cursor % dads.size()]
	if family_speech.visible or speaker.linear_velocity.length_squared() > 3600.0:
		dad_speech_timer.start(1.0)
		return
	family_speech.say(DAD_MESSAGES[dad_message_cursor % DAD_MESSAGES.size()], speaker)
	dad_message_cursor += 1
	dad_speech_timer.start(speech_rng.randf_range(5.0, 8.0))


func _on_bomb_triggered(bomb):
	call_deferred("_explode_bomb", bomb, round_id)


func _on_special_triggered(special, target):
	call_deferred("_activate_special", special, target, round_id)


func _on_remix_triggered(mom):
	call_deferred("_remix_faces", mom, round_id)


func _remix_faces(mom, source_round: int):
	if not playing or source_round != round_id or not is_instance_valid(mom) or mom.deleting or mom.popping:
		return
	var center: Vector2 = mom.global_position
	var burst = BombBurst.new()
	burst.caption = "빨리빨리!"
	burst.sound_pitch = 0.9
	burst.blast_radius = claw.half_width * 1.8
	add_child(burst)
	burst.global_position = center
	family_speech.say("빨리빨리!", null, burst.get_global_transform_with_canvas().origin)
	mom.fusionned = true
	mom.pop()
	# Give a running danger countdown a fresh start after the remix settles.
	box.reset_danger(REMIX_DANGER_GRACE)
	var index := 0
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	for fruit in fruits.get_children():
		if fruit == mom or fruit == claw.current_fruit or fruit == claw.next_fruit:
			continue
		if fruit.mode != RigidBody2D.MODE_RIGID or fruit.deleting or fruit.popping or fruit.fusionned:
			continue
		var direction := -1.0 if index % 2 == 0 else 1.0
		var rise := max(0.0, fruit.global_position.y - (box.limit_area.global_position.y + fruit.radius + 24.0))
		# Bound the upward kick by the free headroom so the effect itself does
		# not launch a nearly-full pile through the game-over line.
		var upward := min(320.0, sqrt(2.0 * gravity * rise) * 0.8)
		var velocity := Vector2(direction * (220.0 + (index % 3) * 35.0), -upward)
		fruit.sleeping = false
		fruit.apply_central_impulse(fruit.mass * (velocity - fruit.linear_velocity))
		fruit.angular_velocity = direction * (2.0 + (index % 3) * 0.5)
		fruit.merge_delay = max(fruit.merge_delay, 1.0)
		fruit.invincible = true
		fruit.invincibility_timer.start(3.0)
		fruit.in_danger = false
		index += 1


func _activate_special(special, target, source_round: int):
	if not playing or source_round != round_id or not is_instance_valid(special) or special.deleting or special.popping:
		return
	if not is_instance_valid(target) or target.deleting or target.popping:
		special.special_requested = false
		special.fusionned = false
		special.call_deferred("_retry_merge_contacts")
		return
	var target_type: int = target.type
	var center: Vector2 = target.global_position
	var target_radius: float = target.radius
	special.delete(center)
	target.delete(center)
	if special.type == Fruit.Type.SUAN:
		self.multiplicator = min(MULTIPLICATOR_MAX, multiplicator + 1)
		self.score += target.points * 2 * multiplicator
		multiplicator_timer.start()
		new_fruit_fusion(Fruit.get_evolution_type_of(target_type), center, source_round)
		family_speech.say("수안이랑 합체!", null, special.get_global_transform_with_canvas().origin)
	elif special.type == Fruit.Type.SUMIN:
		var positions := _copy_positions(center, target_radius)
		for point in positions:
			var copy: Fruit = FruitScene.instance()
			fruits.add_child(copy)
			copy.type = target_type
			copy.global_position = point
			copy.merge_delay = COPY_MERGE_DELAY
			_connect_piece(copy)
			copy.fall(0)
			copy.grow()
		var burst = BombBurst.new()
		burst.caption = "×5!"
		burst.sound_pitch = 1.3
		burst.blast_radius = 110.0
		add_child(burst)
		burst.global_position = center
		family_speech.say("수민이 마법!\n같은 얼굴이 5개!", null, burst.get_global_transform_with_canvas().origin)


func _copy_positions(center: Vector2, radius: float) -> Array:
	var result := []
	var occupied := []
	for fruit in fruits.get_children():
		if fruit.mode == RigidBody2D.MODE_RIGID and not fruit.deleting and not fruit.popping:
			occupied.append({"position": fruit.global_position, "radius": fruit.radius})
	var spacing := radius * 2.0 + 12.0
	var columns := int(min(COPY_COUNT, max(1, floor((claw.half_width * 2.0 - 16.0) / spacing))))
	for i in range(COPY_COUNT):
		var row := int(i / columns)
		var row_count := int(min(columns, COPY_COUNT - row * columns))
		var row_half_width := (row_count - 1) * spacing * 0.5 + radius
		var row_center := clamp(center.x, -claw.half_width + row_half_width + 4.0, claw.half_width - row_half_width - 4.0)
		var point := Vector2(row_center + (i % columns - (row_count - 1) * 0.5) * spacing, min(center.y, -radius - 2.0) - row * spacing)
		# Search upward for free room instead of spawning overlapping colliders,
		# including when the target was against a wall or in a crowded pile.
		for _attempt in range(len(occupied) + COPY_COUNT + 1):
			var clear := true
			var next_y := point.y
			for other in occupied:
				if point.distance_to(other.position) < radius + other.radius + 6.0:
					clear = false
					next_y = min(next_y, other.position.y - radius - other.radius - 7.0)
			if clear:
				break
			point.y = next_y
		result.append(point)
		occupied.append({"position": point, "radius": radius})
	return result


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
