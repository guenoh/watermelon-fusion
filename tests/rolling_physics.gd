extends SceneTree


var world
var pieces := []
var failures := []
var max_rotation := 0.0


func _initialize():
	call_deferred("run_checks")


func check(condition: bool, message: String):
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func make_piece(piece_type: int, point: Vector2):
	var piece = load("res://Game/Fruits/Fruit.tscn").instance()
	world.add_child(piece)
	piece.type = piece_type
	piece.position = point
	# Let the deferred per-piece collision shape be installed before sizing it.
	yield(self, "idle_frame")
	piece.size = 1.0
	piece.fall(800)
	pieces.append(piece)
	return piece


func run_checks():
	world = Node2D.new()
	root.add_child(world)
	var box = load("res://Game/Box/Box.tscn").instance()
	world.add_child(box)
	box.set_size(Vector2(720, 930))
	# Different levels cannot merge: reproduce the perfectly centered tower
	# from the reported screenshot, rather than testing an artificial shove.
	for piece_type in [Fruit.Type.LEMON, Fruit.Type.GRAPES, Fruit.Type.STRAWBERRY, Fruit.Type.GRAPES, Fruit.Type.LEMON, Fruit.Type.GRAPES]:
		yield(make_piece(piece_type, Vector2(0, -800)), "completed")
		yield(create_timer(0.85), "timeout")
	for _i in range(240):
		yield(self, "physics_frame")
		for piece in pieces:
			max_rotation = max(max_rotation, abs(piece.rotation))
	var min_x := 1000.0
	var max_x := -1000.0
	var highest_y := 0.0
	for piece in pieces:
		min_x = min(min_x, piece.position.x)
		max_x = max(max_x, piece.position.x)
		highest_y = min(highest_y, piece.position.y - piece.radius)
		check(abs(piece.position.x) + piece.radius < 363.0, "rolling faces stay inside the side walls")
		check(piece.position.y + piece.radius < 3.0, "rolling faces stay above the floor")
	print("Rolling spread=", max_x - min_x, " height=", -highest_y, " rotation=", max_rotation)
	check(max_x - min_x > 180.0, "six centered drops spread sideways instead of forming a needle tower")
	check(highest_y > -450.0, "centered drops settle into a low pile")
	check(max_rotation > 0.25, "faces actually rotate while rolling")
	for piece in pieces:
		piece.queue_free()
	pieces.clear()
	yield(self, "idle_frame")
	# The largest circles must also leave the perfectly balanced position.
	var base = yield(make_piece(Fruit.Type.WATERMELON, Vector2(0, -Fruit.PARAMS[Fruit.Type.WATERMELON].radius - 4)), "completed")
	yield(create_timer(0.3), "timeout")
	var top = yield(make_piece(Fruit.Type.MELON, Vector2(0, -800)), "completed")
	yield(create_timer(5.0), "timeout")
	print("Large pair offset=", abs(top.position.x - base.position.x))
	check(abs(top.position.x - base.position.x) > (top.radius + base.radius) * 0.25, "large faces roll away by at least a quarter of their combined radii")
	world.queue_free()
	yield(create_timer(0.1), "timeout")
	pieces.clear()
	world = null
	box = null
	base = null
	top = null
	if failures.empty():
		print("PASS: centered drops roll into a low pile, rotate, and remain within the box")
		quit(0)
	else:
		quit(1)
