extends SceneTree


var app
var game
var failures := []
var remixes := 0
var trigger_y := -1000.0


func _initialize():
	call_deferred("run_checks")


func check(condition: bool, message: String):
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func on_remix(mom):
	remixes += 1
	trigger_y = mom.global_position.y


func make_piece(piece_type: int, point: Vector2):
	var piece = game.FruitScene.instance()
	game.fruits.add_child(piece)
	piece.type = piece_type
	piece.global_position = point
	game._connect_piece(piece)
	piece.connect("remix_triggered", self, "on_remix")
	piece.grow()
	return piece


func run_checks():
	app = load("res://App.tscn").instance()
	game = app.get_node("Game")
	game.specials_enabled = false
	root.add_child(app)
	yield(create_timer(1.2), "timeout")
	game.speech_timer.stop()
	var faces := [
		make_piece(Fruit.Type.STRAWBERRY, Vector2(-270, -43)),
		make_piece(Fruit.Type.GRAPES, Vector2(0, -59)),
		make_piece(Fruit.Type.LEMON, Vector2(250, -75)),
	]
	var mom = make_piece(Fruit.Type.MOM, Vector2(0, -700))
	check(mom.level_badge.text == "엄마", "mom has her own portrait and Korean name")
	yield(create_timer(0.3), "timeout")
	for piece in faces:
		piece.fall(0)
	mom.fall(800)
	var passed_through := false
	for _i in range(120):
		yield(self, "physics_frame")
		if remixes > 0:
			break
		if mom.global_position.distance_to(faces[1].global_position) < mom.radius + faces[1].radius - 10.0:
			passed_through = true
	check(passed_through, "mom passes through an occupied face without triggering early")
	print("Mom floor trigger y=", trigger_y, " count=", remixes)
	check(remixes == 1 and trigger_y > -69.0 and trigger_y < -44.0, "mom activates once only at the floor, allowing one fast physics step of contact penetration")
	yield(create_timer(0.12), "timeout")
	check(game.family_speech.label.text == "빨리빨리!", "floor burst shouts the requested message")
	for piece in faces:
		check(is_instance_valid(piece) and not piece.deleting and not piece.popping, "remix preserves every dropped face, including distant ones")
		check(abs(piece.linear_velocity.x) > 30.0 and piece.linear_velocity.y < -30.0, "all faces receive sideways and upward motion")
		check(abs(piece.angular_velocity) > 0.3, "remixed faces spin")
		check(piece.invincible and piece.merge_delay > 0.0, "brief grace protects the reshuffle")
	check(game.score == 0, "remix itself neither deletes faces nor awards points")
	check(game.claw.current_fruit.mode == RigidBody2D.MODE_STATIC and game.claw.next_fruit.mode == RigidBody2D.MODE_STATIC, "held and preview balls remain untouched")
	yield(create_timer(3.2), "timeout")
	check(game.playing and remixes == 1, "shuffle does not trigger a duplicate burst or immediate game over")
	for piece in faces:
		check(not piece.invincible and piece.merge_delay == 0.0, "normal danger and merging resume after the grace period")

	game.reset()
	yield(create_timer(0.25), "timeout")
	game.playing = true
	remixes = 0
	mom = make_piece(Fruit.Type.MOM, Vector2(-296, -500))
	yield(create_timer(0.3), "timeout")
	mom.fall(0)
	yield(create_timer(0.25), "timeout")
	check(remixes == 0, "touching the side wall above the floor does not trigger mom")
	mom.apply_central_impulse(Vector2.DOWN * mom.mass * 800.0)
	yield(create_timer(0.9), "timeout")
	check(remixes == 1, "mom still triggers on the floor after touching a wall first")

	game.reset()
	yield(create_timer(0.25), "timeout")
	game.playing = true
	mom = make_piece(Fruit.Type.MOM, Vector2(0, -64))
	game._on_remix_triggered(mom)
	game.reset()
	yield(create_timer(0.25), "timeout")
	check(not game.family_speech.visible, "reset cancels a queued mom burst and its speech")
	app.queue_free()
	yield(create_timer(0.15), "timeout")
	app = null
	game = null
	faces.clear()
	mom = null
	if failures.empty():
		print("PASS: mom passes through faces, floor-only single burst, global non-destructive remix, protected claw, grace and reset")
		quit(0)
	else:
		quit(1)
