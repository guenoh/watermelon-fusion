extends RigidBody2D
class_name Fruit


signal fusionned(fruit)
signal bomb_triggered(bomb)
signal special_triggered(special, target)
signal remix_triggered(mom)


enum Type {
	CHERRY,
	STRAWBERRY,
	GRAPES,
	LEMON,
	ORANGE,
	APPLE,
	PEAR,
	PEACH,
	PINEAPPLE,
	MELON,
	WATERMELON,
	BOMB,
	SUAN,
	SUMIN,
	MOM,
}

const SCENE := "Fruit.tscn"
const FACE_ATLAS := preload("res://Game/Personal/face-atlas.png")
const FACE_FONT := preload("res://Menu/Theme/LilitaOne-Regular-NotoSans-Black.ttf")
const BOMB_TEXTURE := preload("res://Game/Fruits/bomb.svg")
const SPECIAL_ATLAS := preload("res://Game/Personal/special-portraits.png")
const KOREAN_FONT := preload("res://Game/HUD/Fonts/FamilySansKR-Semibold.ttf")
const MOM_TEXTURE := preload("res://Game/Personal/mom-portrait.png")
const FACE_CELL_SIZE := 512.0
const ORIGINAL_ART_RADIUS := 186.0
const FACE_CELLS := [Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(0, 1), Vector2(1, 1)]
const FACE_ORDER := [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 4]
const LEVEL_COLORS := [
	Color("#ff829d"), Color("#ff9b70"), Color("#bd92ed"),
	Color("#ffe065"), Color("#ffb845"), Color("#f47378"),
	Color("#87cf8c"), Color("#62c7ce"), Color("#80acfa"),
	Color("#b3df70"), Color("#f1c453"),
]
const PARAMS := {
	Type.CHERRY: {
		"texture": preload("Cherry.tres"),
		"radius": 26,
		"points": 2,
		"color": Color("#ff7679"),
	},
	
	Type.STRAWBERRY: {
		"texture": preload("Strawberry.tres"),
		"radius": 36,
		"points": 4,
		"color": Color("#e61f26"),
	},
	
	Type.GRAPES: {
		"texture": preload("Grapes.tres"),
		"radius": 46,
		"points": 6,
		"color": Color("#ac74b1"),
	},
	
	Type.LEMON: {
		"texture": preload("Lemon.tres"),
		"radius": 56,
		"points": 8,
		"color": Color("#fdd504"),
	},
	
	Type.ORANGE: {
		"texture": preload("Orange.tres"),
		"radius": 66,
		"points": 10,
		"color": Color("#fdd504"),
	},
	
	Type.APPLE: {
		"texture": preload("Apple.tres"),
		"radius": 76,
		"points": 12,
		"color": Color("#aad641"),
	},

	Type.PEAR: {
		"texture": preload("Pear.tres"),
		"radius": 86,
		"points": 14,
		"color": Color("#e1d600"),
	},

	Type.PEACH: {
		"texture": preload("Peach.tres"),
		"radius": 96,
		"points": 16,
		"color": Color("#fead78"),
	},
	
	Type.PINEAPPLE: {
		"texture": preload("Pineapple.tres"),
		"radius": 106,
		"points": 18,
		"color": Color("#ffd437"),
	},
	
	Type.MELON: {
		"texture": preload("Melon.tres"),
		"radius": 116,
		"points": 20,
		"color": Color("#8fd165"),
	},
	
	Type.WATERMELON: {
		"texture": preload("Watermelon.tres"),
		"radius": 126,
		"points": 22,
		"color": Color("#82bd54"),
	},
	Type.BOMB: {
		"texture": BOMB_TEXTURE,
		"radius": 50,
		"points": 0,
		"color": Color("#ff91b5"),
	},
	Type.SUAN: {"radius": 64, "points": 0, "color": Color("#53c9ed")},
	Type.SUMIN: {"radius": 64, "points": 0, "color": Color("#f487c1")},
	Type.MOM: {"radius": 64, "points": 0, "color": Color("#ffbe55")},
}

const FACES := [
	preload("Faces/Shy.tres"),
	preload("Faces/Cool.tres"),
	preload("Faces/Angry.tres"),
]

const GROW_DURATION: float = 0.25 # sec
#const INVINCIBILITY_DURATION: float = 0.5 # sec
const FALLING_VELOCITY_THRESHOLD: float = 200.0
const CRUSHED_CONTACT_THRESHOLD: int = 4
const ROLLING_VOLOCITY_THRESHOLD: float = 1.5


export(Type) var type: int = Type.CHERRY setget set_type
var radius: float = 27
var points := 1

var face_ratio := 1.0
var size := 0.0 setget set_size

var fusionned := false
var invincible := true

var falling := false
var rolling := false
var crushed := false
var in_danger := false setget set_in_danger

var deleting := false
var popping := false
var blast_requested := false
var special_requested := false
var merge_delay := 0.0
var remix_requested := false
var remix_floor_y := 0.0
var delete_pos := Vector2.ZERO
var deleting_speed := 1000
var visual_size := 0.0
var level_font := DynamicFont.new()
var level_badge := Label.new()


onready var tween := $Tween
onready var animation_player := $AnimationPlayer
onready var invincibility_timer := $Timer
onready var sprite := $Sprite
onready var animated_face := $AnimatedSprite
onready var collision_shape := $CollisionShape2D

onready var particules := $Particles2D
onready var audio_player_a := $AudioStreamPlayer2DA
onready var audio_player_b := $AudioStreamPlayer2DB


static func get_evolution_type_of(p_type: int) -> int:
	return int(min(p_type + 1, Type.WATERMELON))


static func is_special_type(p_type: int) -> bool:
	return p_type >= Type.BOMB


static func get_texture(p_type: int) -> Texture:
	if p_type == Type.BOMB:
		return BOMB_TEXTURE
	if p_type == Type.MOM:
		return MOM_TEXTURE
	if p_type == Type.SUAN or p_type == Type.SUMIN:
		var special_portrait := AtlasTexture.new()
		special_portrait.atlas = SPECIAL_ATLAS
		var cell_size: float = SPECIAL_ATLAS.get_width() * 0.5
		special_portrait.region = Rect2(Vector2((p_type - Type.SUAN) * cell_size, 0), Vector2.ONE * cell_size)
		special_portrait.filter_clip = true
		return special_portrait
	var portrait := AtlasTexture.new()
	portrait.atlas = FACE_ATLAS
	var cell: Vector2 = FACE_CELLS[FACE_ORDER[int(clamp(p_type, 0, len(FACE_ORDER) - 1))]]
	portrait.region = Rect2(cell * FACE_CELL_SIZE, Vector2.ONE * FACE_CELL_SIZE)
	portrait.filter_clip = true
	return portrait


func set_type(p_type):
	type = p_type
	
	var params = PARAMS.get(type, PARAMS[Type.CHERRY])
	radius = params.get("radius", radius)
	points = params.get("points", points)
	face_ratio = radius / ORIGINAL_ART_RADIUS
	
	mass = float(radius) #/PARAMS[Type.CHERRY].radius)
	
	if not is_inside_tree():
		return
	
	sprite.texture = get_texture(type)
	level_font.size = int(max(16.0, radius * 0.23))
	level_badge.text = "" if type == Type.BOMB else str(type + 1)
	level_badge.rect_size = Vector2.ONE * radius * 0.42
	level_font.font_data = KOREAN_FONT if type >= Type.SUAN else FACE_FONT
	if type >= Type.SUAN:
		level_font.size = 24
		level_badge.text = {Type.SUAN: "수안", Type.SUMIN: "수민 ×5", Type.MOM: "엄마"}[type]
		level_badge.rect_size = Vector2(radius * 1.8, 30)
	
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.set_deferred("shape", shape)
	
	animated_face.scale = face_ratio * Vector2.ONE
	
	particules.modulate = params.get("color", Color.white)
	particules.scale = face_ratio * Vector2.ONE
	
	self.size = 0.0


func _ready():
	animation_player.play("RESET")
	animated_face.hide()
	level_font.font_data = FACE_FONT
	level_font.use_filter = true
	level_font.outline_size = 2
	level_font.outline_color = Color("#254532")
	level_badge.add_font_override("font", level_font)
	level_badge.align = Label.ALIGN_CENTER
	level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(level_badge)


func get_collision_shape() -> Shape2D:
	return $CollisionShape2D.shape


func grow(from_fusion := false):
	
	if from_fusion:
		audio_player_a.pitch_scale = rand_range(0.95, 1.05)
		audio_player_b.pitch_scale = rand_range(0.98, 1.02)
		animation_player.play("fusion")
	
	tween.interpolate_method(self, "set_size", 0.0,  1.0,
		GROW_DURATION, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
		
	tween.start()
	yield(tween, "tween_all_completed")


func set_size(p_scale: float):
	visual_size = p_scale
	sprite.scale = p_scale * Vector2.ONE * (radius * 2.0 / sprite.texture.get_width())
	level_badge.rect_scale = p_scale * Vector2.ONE
	level_badge.rect_position = Vector2(radius * 0.38, radius * 0.38) * p_scale
	if type >= Type.SUAN:
		level_badge.rect_position = Vector2(-radius * 0.9, radius * 0.55) * p_scale
	animated_face.scale = p_scale * face_ratio * Vector2.ONE
	collision_shape.shape.radius = radius * p_scale
	update()


func _draw():
	if visual_size <= 0.0:
		return
	var r := radius * visual_size
	var level_color: Color = PARAMS[type].color if is_special_type(type) else LEVEL_COLORS[type]
	draw_circle(Vector2.ZERO, r, level_color.lightened(0.62))
	draw_arc(Vector2.ZERO, r - max(1.0, r * 0.045), 0.0, TAU, 80,
		level_color, max(2.0, r * 0.09), true)
	draw_arc(Vector2.ZERO, r - max(1.0, r * 0.09), 0.0, TAU, 80,
		Color.white, max(1.0, r * 0.02), true)


func set_in_danger(p_danger: bool):
	in_danger = p_danger
	
	if in_danger:
		if not (animation_player.is_playing() and animation_player.current_animation == "warning"):
			animation_player.play("warning")
	else:
		animation_player.play("RESET")
#		modulate = Color.white


func fall(impulse: int = 1):
	contacts_reported = 4
	contact_monitor = true
	collision_shape.set_deferred("disabled", false)
	mode = MODE_RIGID
	if type == Type.MOM:
		# Only the box occupies layer 2. Other balls cannot block mom's descent.
		collision_layer = 0
		collision_mask = 2
	apply_central_impulse(mass * impulse * Vector2.DOWN) # small impulse to feel gravity again
	invincibility_timer.start()


func _on_invincibility_timeout():
	invincible = false



func pop():
	if popping or deleting:
		return
	popping = true
	contacts_reported = 0
	set_deferred("contact_monitor", false)
	set_deferred("mode", MODE_KINEMATIC)
	collision_shape.set_deferred("disabled", true)
	collision_mask = 0
	collision_layer = 0
	
	audio_player_a.pitch_scale = rand_range(0.95, 1.05)
	animation_player.play("pop")
	yield(animation_player, "animation_finished")
	
	queue_free()


func delete(pos: Vector2 = global_position):
	contacts_reported = 0
	set_deferred("contact_monitor", false)
	set_deferred("mode", MODE_KINEMATIC)
	collision_shape.set_deferred("disabled", true)
	collision_mask = 0
	collision_layer = 0
	
	deleting = true
	delete_pos = pos



func _physics_process(delta):
	if merge_delay > 0.0:
		merge_delay = max(0.0, merge_delay - delta)
		if merge_delay == 0.0:
			call_deferred("_retry_merge_contacts")
	
	if not deleting:
		return
	
	if deleting_speed*0.1 < global_position.distance_squared_to(delete_pos):
		var movement := global_position.direction_to(delete_pos)* deleting_speed
		global_position += movement*delta
	
	else:
		queue_free()


func _retry_merge_contacts():
	if mode != MODE_RIGID or deleting or popping or fusionned:
		return
	for body in get_colliding_bodies():
		_on_body_entered(body)
		if fusionned or deleting or popping:
			break


func _integrate_forces(state: Physics2DDirectBodyState):
	if type == Type.MOM:
		if not remix_requested and state.get_contact_count() > 0 and state.transform.origin.y + radius >= remix_floor_y - 4.0:
			remix_requested = true
			emit_signal("remix_triggered", self)
		return
	# Perfectly centered circles have no sideways collision force. Break only
	# that unstable balance, then let gravity and friction handle the roll.
	for contact in range(state.get_contact_count()):
		var support = state.get_contact_collider_object(contact)
		if not is_instance_valid(support) or support.get_script() != get_script():
			continue
		if support.type == type or support.mode != MODE_RIGID or support.deleting or support.popping:
			continue
		var offset: Vector2 = state.transform.origin - support.global_position
		var balance_tolerance: float = max(2.0, radius * 0.03)
		if offset.y < 0.0 and abs(offset.x) < balance_tolerance and abs(state.linear_velocity.x) < 4.0:
			var direction := sign(offset.x)
			if direction == 0.0:
				direction = -1.0 if get_instance_id() % 2 == 0 else 1.0
			state.linear_velocity.x = direction * max(12.0, radius * 0.2)
			break
	falling = bool(state.linear_velocity.y > FALLING_VELOCITY_THRESHOLD)
	crushed = bool(state.get_contact_count() >= CRUSHED_CONTACT_THRESHOLD)
	rolling = bool(abs(state.angular_velocity) > ROLLING_VOLOCITY_THRESHOLD)


func _on_body_entered(body):
	if deleting or popping or fusionned:
		return
	if type == Type.MOM:
		return # The floor contact is checked even if a wall was touched first.
	if type == Type.BOMB:
		if mode == MODE_RIGID and not blast_requested:
			blast_requested = true
			emit_signal("bomb_triggered", self)
		return
	if body.get_script() != get_script():
		return
	if body.deleting or body.popping or body.fusionned:
		return
	if type >= Type.SUAN:
		# Walls and other rare items do not consume a face-targeting ability.
		if special_requested or body.mode != MODE_RIGID or is_special_type(body.type):
			return
		special_requested = true
		fusionned = true
		body.fusionned = true
		emit_signal("special_triggered", self, body)
		return
	if is_special_type(body.type) or merge_delay > 0.0 or body.merge_delay > 0.0:
		return
	
	if body.type != type:
		return
	if body.deleting or body.popping or body.fusionned:
		return
	
	if body.name > name: # only one body raise the collision
		return
	
	if fusionned: # don't fusion with another in the mean time
		return
	
	fusionned = true
	emit_signal("fusionned", body)

