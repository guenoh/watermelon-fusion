extends SceneTree


var app
var game
var failures := []
var activations := 0


func _initialize():
	call_deferred("run_checks")


func check(condition: bool, message: String):
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func on_special(_special, _target):
	activations += 1


func make_piece(piece_type: int, point: Vector2):
	var piece = game.FruitScene.instance()
	game.fruits.add_child(piece)
	piece.type = piece_type
	piece.global_position = point
	game._connect_piece(piece)
	piece.connect("special_triggered", self, "on_special")
	piece.grow()
	return piece


func active_faces(piece_type := -1) -> Array:
	var result := []
	for piece in game.fruits.get_children():
		if piece == game.claw.current_fruit or piece == game.claw.next_fruit:
			continue
		if not piece.deleting and not piece.popping and (piece_type == -1 or piece.type == piece_type):
			result.append(piece)
	return result


func fresh_round():
	game.reset()
	yield(create_timer(0.25), "timeout")
	game.start()
	yield(create_timer(0.9), "timeout")
	game.speech_timer.stop()
	activations = 0


func run_checks():
	app = load("res://App.tscn").instance()
	game = app.get_node("Game")
	game.specials_enabled = false
	root.add_child(app)
	yield(create_timer(1.2), "timeout")
	game.speech_timer.stop()
	# A long seeded queue tests the total rate and split without depending on
	# a lucky roll during the short interactive checks.
	game.special_rng.seed = 24680
	game.specials_enabled = true
	var counts := [0, 0, 0, 0]
	for _i in range(100000):
		var piece_type: int = game.roll_next_fruit()
		if Fruit.is_special_type(piece_type):
			counts[piece_type - Fruit.Type.BOMB] += 1
	var total: int = counts[0] + counts[1] + counts[2] + counts[3]
	print("Rare queue /100000: bomb=", counts[0], " Suan=", counts[1], " Sumin=", counts[2], " Mom=", counts[3])
	check(total > 850 and total < 1150, "all four rare bubbles share one combined 1% chance")
	for count in counts:
		check(count > 170 and count < 340, "rare roll splits evenly across the four items")
	game.specials_enabled = false

	yield(fresh_round(), "completed")
	var target = make_piece(Fruit.Type.STRAWBERRY, Vector2(0, -43))
	var untouched = make_piece(Fruit.Type.CHERRY, Vector2(200, -26))
	var suan = make_piece(Fruit.Type.SUAN, Vector2(0, -400))
	check(suan.level_badge.text == "수안" and suan.get_texture(Fruit.Type.SUAN).get_width() > 0, "Suan uses his own portrait and Korean name")
	yield(create_timer(0.3), "timeout")
	target.fall(0)
	untouched.fall(0)
	suan.fall(800)
	yield(create_timer(0.9), "timeout")
	check(activations == 1, "Suan activates exactly once on the first face")
	check(active_faces(Fruit.Type.GRAPES).size() == 1 and game.score == 8, "wildcard upgrades the target's level with pair scoring")
	check(is_instance_valid(untouched) and not untouched.deleting, "Suan leaves a second face alone")
	check(is_instance_valid(game.claw.current_fruit) and is_instance_valid(game.claw.next_fruit), "special activation protects held and preview pieces")

	yield(fresh_round(), "completed")
	target = make_piece(Fruit.Type.WATERMELON, Vector2(0, -186))
	suan = make_piece(Fruit.Type.SUAN, Vector2(0, -700))
	yield(create_timer(0.3), "timeout")
	target.fall(0)
	suan.fall(800)
	yield(create_timer(0.9), "timeout")
	check(activations == 1 and active_faces(Fruit.Type.WATERMELON).size() == 1, "Suan also combines with the final level without creating a bomb")
	check(active_faces(Fruit.Type.BOMB).empty(), "final-level upgrade stays capped at the final face")

	yield(fresh_round(), "completed")
	target = make_piece(Fruit.Type.CHERRY, Vector2(290, -26))
	var sumin = make_piece(Fruit.Type.SUMIN, Vector2(290, -350))
	check(sumin.level_badge.text == "수민 ×5", "Sumin uses her own named five-copy bubble")
	yield(create_timer(0.3), "timeout")
	target.fall(0)
	sumin.fall(800)
	yield(create_timer(0.65), "timeout")
	var copies := active_faces(Fruit.Type.CHERRY)
	check(activations == 1 and copies.size() == 5, "Sumin replaces the first target with exactly five total faces")
	check(game.score == 0, "copy creation does not award merge points")
	for piece in copies:
		check(abs(piece.global_position.x) + piece.radius < game.claw.half_width + 1.0, "copies near the wall fit inside the box")
		check(piece.merge_delay > 0.0, "copies are visible separately before merging resumes")
		for other in copies:
			if piece != other:
				check(piece.global_position.distance_to(other.global_position) > piece.radius + other.radius - 1.0, "copy colliders do not start overlapping")
	yield(create_timer(1.3), "timeout")
	if copies.size() == 5:
		copies[0].apply_central_impulse(Vector2(copies[0].mass * 100.0, 0))
	yield(create_timer(0.8), "timeout")
	check(game.score > 0, "copies can merge normally after the short reveal delay")
	# Small copies must clear a crowded pile containing much larger circles.
	yield(fresh_round(), "completed")
	var blockers := []
	for y in [-186, -558, -930]:
		var blocker = make_piece(Fruit.Type.WATERMELON, Vector2(0, y))
		blocker.fall(0)
		blockers.append(blocker)
	var points: Array = game._copy_positions(Vector2(0, -26), 26.0)
	check(points.size() == 5, "crowded pile still gets five copy positions")
	for point in points:
		for blocker in blockers:
			check(point.distance_to(blocker.global_position) > 26.0 + blocker.radius, "small copies clear all large occupied circles")
	blockers.clear()

	yield(fresh_round(), "completed")
	suan = make_piece(Fruit.Type.SUAN, Vector2(-294, -64))
	yield(create_timer(0.3), "timeout")
	suan.fall(0)
	yield(create_timer(0.3), "timeout")
	check(activations == 0 and not suan.special_requested, "floor and wall contact preserve a rare face ability")
	target = make_piece(Fruit.Type.CHERRY, Vector2(-294, -350))
	yield(create_timer(0.3), "timeout")
	target.fall(800)
	yield(create_timer(0.8), "timeout")
	check(activations == 1 and active_faces(Fruit.Type.STRAWBERRY).size() == 1, "a resting wildcard still activates when a face lands on it")

	# Defer a first-contact effect, then reset before it can spawn old copies.
	yield(fresh_round(), "completed")
	sumin = make_piece(Fruit.Type.SUMIN, Vector2.ZERO)
	target = make_piece(Fruit.Type.CHERRY, Vector2(0, -300))
	target.fall(0)
	sumin._on_body_entered(target)
	game.reset()
	yield(create_timer(0.35), "timeout")
	check(active_faces().empty(), "reset invalidates a queued special effect")
	app.queue_free()
	yield(create_timer(0.15), "timeout")
	app = null
	game = null
	if failures.empty():
		print("PASS: combined 1% split, first-face wildcard, final-level cap, five copies, normal merges, wall survival and reset protection")
		quit(0)
	else:
		quit(1)
