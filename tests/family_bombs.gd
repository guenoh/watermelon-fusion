extends SceneTree


var app
var game
var failures := []
var detonations := 0


func _initialize():
	call_deferred("run_checks")


func check(condition: bool, message: String):
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func on_bomb(_bomb):
	detonations += 1


func make_piece(piece_type: int, point: Vector2):
	var piece = game.FruitScene.instance()
	game.fruits.add_child(piece)
	piece.type = piece_type
	piece.global_position = point
	piece.connect("bomb_triggered", game, "_on_bomb_triggered")
	piece.connect("fusionned", game, "_on_fruit_fusionned", [piece])
	piece.grow()
	return piece


func run_checks():
	app = load("res://App.tscn").instance()
	game = app.get_node("Game")
	game.specials_enabled = false
	root.add_child(app)
	yield(create_timer(1.2), "timeout")
	game.speech_timer.stop()
	check(game.claw.current_fruit.type != Fruit.Type.BOMB, "no guaranteed starting bomb")
	check(game._is_special_roll(0.0) and game._is_special_roll(0.019999), "rolls below two percent produce rare pieces")
	check(not game._is_special_roll(0.02) and not game._is_special_roll(0.99), "two percent boundary is exclusive")
	var hits := 0
	for i in range(1000):
		if game._is_special_roll(float(i) / 1000.0):
			hits += 1
	check(hits == 20, "combined rare-piece chance is exactly two percent of the roll interval")
	var expected_rng := RandomNumberGenerator.new()
	expected_rng.seed = 13579
	game.special_rng.seed = 13579
	game.specials_enabled = true
	for _i in range(1000):
		var expected := expected_rng.randf() < 0.02
		var expected_type := -1
		if expected:
			expected_type = game.SPECIAL_TYPES[expected_rng.randi_range(0, 3)]
		var actual_type: int = game.roll_next_fruit()
		check(Fruit.is_special_type(actual_type) == expected, "piece queue applies one combined independent 2% roll per piece")
		if expected:
			check(actual_type == expected_type, "one of the four rare types is chosen only after a rare roll")
	game.specials_enabled = false
	game.family_speech.say("박근오 아빠,\n사랑해요!", game.claw.current_fruit)
	yield(create_timer(0.1), "timeout")
	check(game.family_speech.visible and game.family_speech.label.text.find("사랑해요") >= 0, "Korean speech is shown")
	check(game.family_speech.mouse_filter == Control.MOUSE_FILTER_IGNORE, "speech does not consume drag input")
	game.reset()
	yield(create_timer(0.2), "timeout")
	check(not game.family_speech.visible, "reset clears old speech")
	game.playing = true
	game.next_fruit_type = Fruit.Type.CHERRY
	var bomb = make_piece(Fruit.Type.BOMB, Vector2.ZERO)
	bomb.connect("bomb_triggered", self, "on_bomb")
	game.claw.load_fruit(bomb)
	yield(create_timer(0.8), "timeout")
	check(game.claw.armed and game.claw.current_fruit == bomb, "bomb can be held in the regular claw")
	check(bomb.level_badge.text == "", "bomb has its own icon instead of a face level")
	var nearby = make_piece(Fruit.Type.CHERRY, Vector2(0, -40))
	var far = make_piece(Fruit.Type.CHERRY, Vector2(300, -40))
	yield(create_timer(0.3), "timeout")
	nearby.fall(0)
	far.fall(0)
	game.claw.drop()
	yield(create_timer(1.5), "timeout")
	check(detonations == 1, "falling bomb detonates exactly once on contact")
	check(not is_instance_valid(bomb) and not is_instance_valid(nearby), "bomb clears nearby dropped faces")
	check(is_instance_valid(far) and not far.popping, "faces outside blast radius survive")
	check(is_instance_valid(game.claw.current_fruit) and is_instance_valid(game.claw.next_fruit), "blast protects held and preview pieces")
	check(game.score == 2, "cleared faces award their points once")
	game.reset()
	yield(create_timer(0.2), "timeout")
	game.playing = true
	var face_a = make_piece(Fruit.Type.CHERRY, Vector2(0, -120))
	var face_b = make_piece(Fruit.Type.CHERRY, Vector2(0, -230))
	yield(create_timer(0.3), "timeout")
	face_a.fall(800)
	face_b.fall(800)
	yield(create_timer(1.2), "timeout")
	var merged_faces := 0
	for piece in game.fruits.get_children():
		if not piece.deleting and not piece.popping and piece.type == Fruit.Type.STRAWBERRY:
			merged_faces += 1
	check(merged_faces == 1 and game.score == 4, "ordinary faces still merge once with their usual score: score=" + str(game.score) + " merged=" + str(merged_faces))
	app.queue_free()
	yield(create_timer(0.15), "timeout")
	app = null
	game = null
	bomb = null
	nearby = null
	far = null
	face_a = null
	face_b = null
	if failures.empty():
		print("PASS: Korean speech, combined independent 2% rare queue, normal claw use, single bomb blast, radius and preview protection")
		quit(0)
	else:
		quit(1)
