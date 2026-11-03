extends StaticBody2D


signal limit_reached

const ANIM_NAME := "in_limit"
const DANGER_DURATION := 3.1
const SETTLED_SPEED := 75.0

var monitoring_enabled := true
var danger_elapsed := {}
var grace_remaining := 0.0
var limit_reported := false

onready var animation_player := $AnimationPlayer
onready var alarm := $AudioStreamPlayer
onready var limit_area: Area2D = $Limit
onready var wall_left := $WallLeft
onready var wall_right := $WallRight


func set_size(p_size: Vector2):
	limit_area.position.y = -abs(p_size.y)
	var half_width := float(abs(p_size.x) * 0.5)
	wall_left.position.x = -(half_width + wall_left.shape.extents.x)
	wall_right.position.x = half_width + wall_right.shape.extents.x


func set_monitoring_enabled(value: bool):
	monitoring_enabled = value
	reset_danger()


func reset_danger(grace := 0.0):
	danger_elapsed.clear()
	grace_remaining = grace
	limit_reported = false
	animation_player.stop()
	alarm.stop()
	for body in limit_area.get_overlapping_bodies():
		if body is Fruit and body.in_danger:
			body.in_danger = false


func _on_Limit_body_entered(_body):
	pass


func _on_Limit_body_exited(body):
	if body is Fruit:
		danger_elapsed.erase(body.get_instance_id())
		if body.in_danger:
			body.in_danger = false


func _physics_process(delta):
	if not monitoring_enabled or limit_reported:
		return
	grace_remaining = max(0.0, grace_remaining - delta)
	var current := {}
	var longest := 0.0
	for body in limit_area.get_overlapping_bodies():
		if not body is Fruit:
			continue
		# Only a dropped, settled ball continuously above the line can end a
		# round. Previews, old/deleted balls and remix flyovers are excluded.
		var dangerous: bool = grace_remaining == 0.0 and body.mode == RigidBody2D.MODE_RIGID and not body.invincible and not body.deleting and not body.popping and not body.fusionned and body.linear_velocity.length_squared() <= SETTLED_SPEED * SETTLED_SPEED
		if not dangerous:
			if body.in_danger:
				body.in_danger = false
			continue
		var id: int = body.get_instance_id()
		var elapsed: float = danger_elapsed.get(id, 0.0) + delta
		current[id] = elapsed
		longest = max(longest, elapsed)
		if not body.in_danger:
			body.in_danger = true
	danger_elapsed = current
	if current.empty():
		animation_player.stop()
		alarm.stop()
		return
	if not animation_player.is_playing():
		animation_player.play(ANIM_NAME)
	if longest >= DANGER_DURATION:
		limit_reported = true
		emit_signal("limit_reached")
