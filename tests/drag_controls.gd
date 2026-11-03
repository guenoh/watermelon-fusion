extends SceneTree


var app
var game
var controller
var claw
var drops := 0
var failures := []


func _initialize():
	call_deferred("run_checks")


func check(condition: bool, message: String):
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)


func touch(x: float, pressed: bool, finger := 0):
	var event := InputEventScreenTouch.new()
	event.index = finger
	event.pressed = pressed
	event.position = controller.get_global_transform_with_canvas().xform(Vector2(x, claw.position.y + 60))
	if pressed:
		controller._unhandled_input(event)
	else:
		controller._input(event)


func drag(x: float, finger := 0):
	var event := InputEventScreenDrag.new()
	event.index = finger
	event.position = controller.get_global_transform_with_canvas().xform(Vector2(x, claw.position.y + 60))
	controller._unhandled_input(event)


func on_drop():
	drops += 1


func run_checks():
	app = load("res://App.tscn").instance()
	root.add_child(app)
	game = app.get_node("Game")
	controller = game.get_node("UserInputsController")
	claw = game.get_node("Claw")
	claw.connect("dropped", self, "on_drop")
	yield(create_timer(1.2), "timeout")
	check(claw.armed, "first ball becomes ready")
	if not claw.armed:
		quit(1)
		return

	var held = claw.current_fruit
	touch(0, true)
	drag(150)
	yield(create_timer(0.1), "timeout")
	check(abs(held.global_position.x - 150) < 2.0, "held ball follows drag before release")
	check(drops == 0 and claw.current_fruit == held, "pressing and dragging do not drop")

	touch(-150, true, 1)
	drag(-150, 1)
	touch(-150, false, 1)
	yield(create_timer(0.08), "timeout")
	check(drops == 0 and abs(held.global_position.x - 150) < 2.0, "second finger cannot move or release the ball")

	drag(10000)
	yield(create_timer(0.08), "timeout")
	check(held.global_position.x <= claw.half_width - held.radius, "right wall clamps the whole ball")
	check(drops == 0, "touching a wall while holding does not drop")
	drag(-10000)
	yield(create_timer(0.08), "timeout")
	check(held.global_position.x >= -claw.half_width + held.radius, "left wall clamps the whole ball")

	touch(-140, false)
	yield(create_timer(0.08), "timeout")
	check(drops == 1 and held.mode == RigidBody2D.MODE_RIGID, "release drops exactly once")
	check(abs(held.global_position.x + 140) < 2.0, "release uses the final pointer position")
	yield(create_timer(0.8), "timeout")
	check(claw.armed and abs(claw.current_fruit.global_position.x + 140) < 2.0, "next ball keeps the previous aim")

	touch(100, true)
	controller._notification(MainLoop.NOTIFICATION_WM_FOCUS_OUT)
	touch(100, false)
	yield(create_timer(0.08), "timeout")
	check(drops == 1, "losing focus cancels rather than drops a gesture")
	touch(80, true)
	game._on_MenuButton_pressed()
	touch(80, false)
	yield(create_timer(0.08), "timeout")
	check(drops == 1, "opening a menu cancels the gesture")
	app.get_node("Menus/Menu").close()
	yield(create_timer(0.35), "timeout")

	touch(80, true)
	touch(80, false)
	yield(create_timer(0.08), "timeout")
	check(drops == 2, "quick taps still drop one ball")
	app.queue_free()
	yield(create_timer(0.1), "timeout")
	app = null
	game = null
	controller = null
	claw = null
	held = null

	if failures.empty():
		print("PASS: drag follows pointer, waits for release, clamps at walls, ignores extra fingers, cancels safely, and supports taps")
		quit(0)
	else:
		quit(1)
