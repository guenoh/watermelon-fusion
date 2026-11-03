extends KinematicBody2D


signal armed
signal dropped

const FRUIT_DROP_IMPULSE := 800
const ARM_DURATION := 0.22 # sec
const AIM_FOLLOW_RATE := 42.0
const MAX_AIM_SPEED := 4800.0


var loaded := false
var armed := false
var arming := false

var drop_position_x := 0.0
var half_width := 360.0
var dragging := false
var gesture_fruit: Fruit
var grab_offset_x := 0.0
var generation := 0

var next_fruit: Fruit
var current_fruit: Fruit

onready var tween := $Tween
onready var timer := $Timer
onready var next_fruit_position: Vector2 = $Position2D.position
onready var collision_shape := $CollisionShape2D


func load_fruit(fruit):
	var loading_generation := generation
	
	fruit.global_position.x = 0
	fruit.global_position.y = global_position.y + next_fruit_position.y
	
	next_fruit = fruit
	loaded = false
	
	yield(next_fruit.grow(), "completed")
	if loading_generation != generation or not is_instance_valid(fruit) or next_fruit != fruit:
		return
	loaded = true
	if not armed and not arming:
		arm()


func unload():
	generation += 1
	tween.stop_all()
	tween.remove_all()
	collision_shape.set_deferred("disabled", true)
	loaded = false
	armed = false
	arming = false
	dragging = false
	gesture_fruit = null
	current_fruit = null
	next_fruit = null
	position.x = 0.0
	drop_position_x = 0.0


func arm():
	if not loaded or arming:
		return
	
	var fruit = next_fruit
	var arming_generation := generation
	var limit := max(0.0, half_width - fruit.radius - 2.0)
	position.x = clamp(drop_position_x, -limit, limit)
	
	loaded = false
	next_fruit = null
	arming = true
	current_fruit = fruit
	dragging = false
	gesture_fruit = null
	
	fruit.global_position.x = position.x
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(fruit, "global_position:y", fruit.global_position.y, global_position.y,
		ARM_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	
	if arming_generation != generation or not is_instance_valid(fruit) or current_fruit != fruit:
		return
	
	arming = false
	armed = true
	collision_shape.shape = current_fruit.get_collision_shape().duplicate()
	collision_shape.set_deferred("disabled", false)
	emit_signal("armed")



func set_horizontal_bounds(width: float):
	half_width = max(1.0, width * 0.5)


func _on_UserInputsController_fruit_moved(pos_x):
	if dragging and armed and is_instance_valid(gesture_fruit) and gesture_fruit == current_fruit:
		var fruit = current_fruit
		var limit := max(0.0, half_width - fruit.radius - 2.0)
		var requested: float = pos_x + grab_offset_x
		drop_position_x = clamp(requested, -limit, limit)
		# Re-anchor at the wall so reversing the finger moves immediately,
		# without making the player drag back across an overshoot dead zone.
		if requested != drop_position_x:
			grab_offset_x = drop_position_x - pos_x


func _on_UserInputsController_fruit_grabbed(pos_x):
	if not armed or not is_instance_valid(current_fruit):
		_on_UserInputsController_drag_cancelled()
		return
	dragging = true
	gesture_fruit = current_fruit
	grab_offset_x = position.x - pos_x
	drop_position_x = position.x


func _on_UserInputsController_drag_cancelled():
	dragging = false
	gesture_fruit = null
	drop_position_x = position.x


func _physics_process(delta):
	if not armed or not is_instance_valid(current_fruit):
		return
	if not dragging or gesture_fruit != current_fruit:
		return

	# A frame-rate-independent follow keeps small movements responsive and
	# limits large jumps when a pointer moves quickly across the playfield.
	var limit := max(0.0, half_width - current_fruit.radius - 2.0)
	var target_x := clamp(drop_position_x, -limit, limit)
	var follow := 1.0 - exp(-AIM_FOLLOW_RATE * delta)
	var step := clamp((target_x - position.x) * follow, -MAX_AIM_SPEED * delta, MAX_AIM_SPEED * delta)
	move_and_collide(Vector2(step, 0.0))
	current_fruit.global_position.x = position.x
	if armed:
		current_fruit.global_position.y = position.y


func _on_UserInputsController_fruit_dropped(_pos_x):
	# A release belongs only to the ready ball grabbed by this gesture.
	# Never carry taps through loading/arming into a later ball.
	var release_ready: bool = armed and dragging and is_instance_valid(gesture_fruit) and gesture_fruit == current_fruit
	dragging = false
	gesture_fruit = null
	drop_position_x = position.x
	if release_ready:
		drop()



func drop():
	if not armed or not is_instance_valid(current_fruit):
		return
	
	if is_instance_valid(current_fruit):
		current_fruit.fall(FRUIT_DROP_IMPULSE)
		current_fruit = null
	
	armed = false
	dragging = false
	gesture_fruit = null
	drop_position_x = position.x
	
	if not armed and loaded:
		arm()
	
	emit_signal("dropped")

