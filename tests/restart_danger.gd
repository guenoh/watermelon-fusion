extends SceneTree


var failures := []
var limit_signals := 0


func _initialize():
	call_deferred("run_checks")


func check(condition: bool, message: String):
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func on_limit():
	limit_signals += 1


func suspended_face(world, velocity: Vector2):
	var piece = load("res://Game/Fruits/Fruit.tscn").instance()
	world.add_child(piece)
	piece.type = Fruit.Type.STRAWBERRY
	piece.position = Vector2(200, -1020)
	piece.gravity_scale = 0.0
	yield(self, "idle_frame")
	piece.size = 1.0
	piece.fall(0)
	piece.invincibility_timer.stop()
	piece.invincible = false
	piece.apply_central_impulse(piece.mass * velocity)
	return piece


func run_checks():
	var app = load("res://App.tscn").instance()
	var game = app.get_node("Game")
	game.specials_enabled = false
	root.add_child(app)
	yield(create_timer(1.1), "timeout")
	var menu = app.get_node("Menus/Menu")
	var previous_round: int = game.round_id
	menu.open_end_game(10, 10)
	yield(create_timer(0.35), "timeout")
	menu._on_ReplayButton_pressed()
	menu._on_ReplayButton_pressed() # Repeated presses during closing are ignored.
	yield(create_timer(0.95), "timeout")
	print("Replay round increments=", game.round_id - previous_round, " armed=", game.claw.armed)
	check(game.round_id == previous_round + 1, "one replay button press starts exactly one round")
	check(game.claw.armed, "replay leaves a usable armed ball")
	app.queue_free()
	yield(create_timer(0.15), "timeout")
	app = null
	game = null
	menu = null

	var world := Node2D.new()
	root.add_child(world)
	var box = load("res://Game/Box/Box.tscn").instance()
	world.add_child(box)
	box.set_size(Vector2(720, 930))
	box.connect("limit_reached", self, "on_limit")
	# The invincible preview stays above the line even after a launched ball
	# has returned below it. It must not keep an old countdown alive.
	var preview = load("res://Game/Fruits/Fruit.tscn").instance()
	world.add_child(preview)
	preview.type = Fruit.Type.CHERRY
	preview.position = Vector2(0, -1200)
	yield(self, "idle_frame")
	preview.size = 1.0
	var returning = yield(suspended_face(world, Vector2.ZERO), "completed")
	yield(create_timer(1.2), "timeout")
	returning.apply_central_impulse(Vector2.DOWN * returning.mass * 500.0)
	yield(create_timer(2.3), "timeout")
	print("False danger signals after return=", limit_signals, " position=", returning.global_position)
	check(returning.global_position.y > -800, "return fixture physically travels below the danger line")
	check(limit_signals == 0, "a ball returning below the line clears its danger countdown even with a preview above it")
	returning.queue_free()
	returning = yield(suspended_face(world, Vector2.UP * 140.0), "completed")
	yield(create_timer(3.4), "timeout")
	check(limit_signals == 0, "an airborne remix flyover never counts as a settled overflow")
	returning.queue_free()
	returning = yield(suspended_face(world, Vector2.ZERO), "completed")
	yield(create_timer(3.4), "timeout")
	check(limit_signals == 1, "a genuinely settled overflow still ends the round after continuous danger")
	box.reset_danger(2.0)
	yield(create_timer(2.4), "timeout")
	check(limit_signals == 1, "remix grace expires into a fresh warning rather than a stale game over")
	returning.apply_central_impulse(Vector2.DOWN * returning.mass * 500.0)
	yield(create_timer(3.2), "timeout")
	check(limit_signals == 1, "returning below the line after grace cancels the new warning too")
	world.queue_free()
	yield(create_timer(0.15), "timeout")
	world = null
	box = null
	preview = null
	returning = null
	if failures.empty():
		print("PASS: single replay, ready ball, return/airborne danger cancellation, remix grace and legitimate settled game over")
		quit(0)
	else:
		quit(1)
