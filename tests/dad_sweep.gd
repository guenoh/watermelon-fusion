extends SceneTree


var app
var game
var failures := []
var sweeps := 0


func _initialize():
	call_deferred("run_checks")


func check(condition: bool, message: String):
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func on_sweep(_dad):
	sweeps += 1


func make_piece(piece_type: int, point: Vector2):
	var piece = game.FruitScene.instance()
	game.fruits.add_child(piece)
	piece.type = piece_type
	piece.global_position = point
	game._connect_piece(piece)
	piece.connect("dad_dropped", self, "on_sweep")
	piece.grow()
	return piece


func run_checks():
	app = load("res://App.tscn").instance()
	game = app.get_node("Game")
	game.specials_enabled = false
	root.add_child(app)
	yield(create_timer(1.0), "timeout")
	game.reset()
	yield(create_timer(0.25), "timeout")
	game.playing = true
	# A suspended above-dad face is an artificial fixture, not an overflow.
	game.box.set_monitoring_enabled(false)
	game.next_fruit_type = Fruit.Type.CHERRY
	var dad = make_piece(Fruit.Type.DAD, Vector2.ZERO)
	game.claw.load_fruit(dad)
	yield(create_timer(0.75), "timeout")
	check(game.claw.current_fruit == dad and game.claw.armed, "dad uses the normal draggable claw")
	check(dad.level_badge.text == "아빠" and dad.points == 0, "dad has his portrait/name and no idle score")
	check(sweeps == 0 and not dad.dad_smash_used, "holding dad does not clear the board")
	var left = make_piece(Fruit.Type.CHERRY, Vector2(-270, -26))
	var middle = make_piece(Fruit.Type.STRAWBERRY, Vector2(0, -36))
	var right = make_piece(Fruit.Type.LEMON, Vector2(260, -56))
	var bomb = make_piece(Fruit.Type.BOMB, Vector2(-140, -400))
	var above = make_piece(Fruit.Type.CHERRY, Vector2(270, game.claw.position.y - 180))
	above.gravity_scale = 0.0
	yield(create_timer(0.3), "timeout")
	for piece in [left, middle, right, bomb, above]:
		piece.fall(0)
	var preview = game.claw.next_fruit
	game.family_speech.clear()
	game.claw.drop()
	yield(create_timer(0.65), "timeout")
	check(sweeps == 1 and dad.dad_smash_used, "dad's drop starts one sweep")
	for piece in [left, middle, right, bomb]:
		check(not is_instance_valid(piece), "all below balls clear across the width, including a bomb without a chain blast")
	check(is_instance_valid(above) and not above.popping, "a dropped ball above dad survives")
	check(is_instance_valid(preview) and is_instance_valid(game.claw.current_fruit) and is_instance_valid(game.claw.next_fruit), "the next/held queue survives dad's sweep")
	check(game.score == 14, "destroyed ordinary faces award their points once")
	check(is_instance_valid(dad) and not dad.popping and not dad.deleting, "dad survives his own ability")
	yield(create_timer(1.75), "timeout")
	check(abs(dad.global_position.y + dad.radius) < 4.0, "dad reaches the floor and remains as a physical ball")
	check(game.family_speech.label.text == "꿀꿀~" and game.family_speech.speaker_ref.get_ref() == dad, "settled dad automatically gives his first idle message")
	check(game.dad_speech_timer.time_left > 2.0, "dad chatter has a pause between messages")

	var later = make_piece(Fruit.Type.CHERRY, Vector2(dad.global_position.x, -270))
	yield(create_timer(0.3), "timeout")
	later.fall(800)
	yield(create_timer(0.85), "timeout")
	check(is_instance_valid(later) and not later.popping and not later.deleting, "new balls touching dad after the sweep are not destroyed or merged")
	dad.fall(0)
	game._clear_below_dad(dad, game.round_id)
	yield(create_timer(0.1), "timeout")
	check(sweeps == 1 and game.score == 14 and is_instance_valid(later), "moving dad or a duplicate callback cannot sweep again")
	game.family_speech.clear()
	game._on_dad_speech_timeout()
	check(game.family_speech.label.text == "시우야 안녕!" and game.family_speech.speaker_ref.get_ref() == dad, "dad alternates to the requested greeting")

	game.reset()
	check(game.dad_speech_timer.is_stopped() and not game.family_speech.visible, "restart clears dad chatter")
	yield(create_timer(0.25), "timeout")
	game.start()
	var stale_dad = make_piece(Fruit.Type.DAD, Vector2(0, -300))
	stale_dad.fall(0)
	game.reset()
	game.start()
	var survivor = make_piece(Fruit.Type.CHERRY, Vector2(0, -26))
	yield(create_timer(0.5), "timeout")
	check(is_instance_valid(survivor) and not survivor.popping and game.score == 0, "a queued sweep from the previous round cannot clear new balls")
	game.dad_speech_timer.start(0.1)
	game.end()
	check(game.dad_speech_timer.is_stopped(), "ending the round stops dad chatter")
	app.queue_free()
	yield(create_timer(0.15), "timeout")
	app = null
	game = null
	if failures.empty():
		print("PASS: one-time below-dad sweep, width/above/queue protection, persistent inert dad, idle chatter and round cleanup")
		quit(0)
	else:
		quit(1)
