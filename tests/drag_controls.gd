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
	app.get_node("Game").specials_enabled = false
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
	var origin_x: float = held.global_position.x
	touch(210, true)
	yield(create_timer(0.06), "timeout")
	check(abs(held.global_position.x - origin_x) < 0.1, "pressing away from the ball does not teleport it")
	drag(310)
	yield(create_timer(0.04), "timeout")
	check(held.global_position.x > origin_x and held.global_position.x < origin_x + 99.0, "ball follows progressively instead of jumping to the drag target")
	yield(create_timer(0.3), "timeout")
	check(abs(held.global_position.x - (origin_x + 100.0)) < 2.0, "drag preserves the initial grab offset")
	check(drops == 0 and claw.current_fruit == held, "pressing and dragging do not drop")

	touch(-150, true, 1)
	drag(-150, 1)
	touch(-150, false, 1)
	yield(create_timer(0.08), "timeout")
	check(drops == 0 and abs(held.global_position.x - (origin_x + 100.0)) < 2.0, "second finger cannot move or release the ball")

	drag(10000)
	yield(create_timer(0.3), "timeout")
	check(held.global_position.x <= claw.half_width - held.radius, "right wall clamps the whole ball")
	check(drops == 0, "touching a wall while holding does not drop")
	drag(-10000)
	yield(create_timer(0.5), "timeout")
	check(held.global_position.x >= -claw.half_width + held.radius, "left wall clamps the whole ball")

	drag(270)
	yield(create_timer(0.04), "timeout")
	var release_x: float = held.global_position.x
	touch(1000, false)
	yield(create_timer(0.08), "timeout")
	check(drops == 1 and held.mode == RigidBody2D.MODE_RIGID, "release drops exactly once")
	check(abs(held.global_position.x - release_x) < 2.0, "release drops from the visible ball position without a final snap")
	yield(create_timer(0.8), "timeout")
	check(claw.armed and abs(claw.current_fruit.global_position.x - release_x) < 2.0, "next ball keeps the previous visible aim position")

	touch(100, true)
	drag(200)
	yield(create_timer(0.04), "timeout")
	controller._notification(MainLoop.NOTIFICATION_WM_FOCUS_OUT)
	var cancelled_x: float = claw.current_fruit.global_position.x
	touch(100, false)
	yield(create_timer(0.12), "timeout")
	check(drops == 1, "losing focus cancels rather than drops a gesture")
	check(abs(claw.current_fruit.global_position.x - cancelled_x) < 0.1, "cancelling stops the trailing movement")
	touch(80, true)
	drag(130)
	yield(create_timer(0.04), "timeout")
	game._on_MenuButton_pressed()
	touch(80, false)
	yield(create_timer(0.08), "timeout")
	check(drops == 1, "opening a menu cancels the gesture")
	app.get_node("Menus/Menu").close()
	yield(create_timer(0.35), "timeout")

	var tap_ball = claw.current_fruit
	var tap_x: float = tap_ball.global_position.x
	touch(250, true)
	touch(250, false)
	yield(create_timer(0.08), "timeout")
	check(drops == 2, "quick taps still drop one ball")
	check(abs(tap_ball.global_position.x - tap_x) < 2.0, "tap does not teleport the ball to the pressed position")
	app.queue_free()
	yield(create_timer(0.1), "timeout")
	app = null
	game = null
	controller = null
	claw = null
	held = null
	tap_ball = null

	if failures.empty():
		print("PASS: no press teleport, smooth relative dragging, release at visible position, wall limits, multi-touch, cancellation, and taps")
		quit(0)
	else:
		quit(1)
