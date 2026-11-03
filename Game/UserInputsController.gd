extends Node2D


signal fruit_moved(pos)
signal fruit_dropped(pos)
signal fruit_grabbed(pos)
signal drag_cancelled



# The first pointer stream owns a gesture; ignore its emulated counterpart.
var active_touch := -1
var active_mouse := false
var enabled := true



func cancel_drag():
	active_touch = -1
	active_mouse = false
	emit_signal("drag_cancelled")


func set_enabled(value: bool):
	enabled = value
	if not enabled:
		cancel_drag()


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT or what == MainLoop.NOTIFICATION_APP_PAUSED:
		cancel_drag()


func _input(event):
	if not enabled:
		return
	# Catch the end of a gesture even when released over a GUI control.
	if event is InputEventScreenTouch and not event.pressed and event.index == active_touch:
		var local_event = make_input_local(event)
		active_touch = -1
		emit_signal("fruit_dropped", local_event.position.x)
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed and active_mouse:
		active_mouse = false
		emit_signal("fruit_dropped", make_input_local(event).position.x)


func _unhandled_input(event):
	if not enabled:
		return
	event = make_input_local(event)
	if event is InputEventScreenTouch and event.pressed:
		# Other fingers cannot take over a drag. GUI presses are consumed
		# before reaching this method.
		if active_touch != -1 or active_mouse:
			return
		active_touch = event.index
		emit_signal("fruit_grabbed", event.position.x)
	elif event is InputEventScreenDrag and event.index == active_touch:
		emit_signal("fruit_moved", event.position.x)
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if active_touch != -1 or active_mouse:
			return
		active_mouse = true
		emit_signal("fruit_grabbed", event.position.x)
	elif event is InputEventMouseMotion and active_mouse:
		emit_signal("fruit_moved", event.position.x)
	elif OS.is_debug_build() and event.is_action_pressed("ui_accept") and active_touch == -1 and not active_mouse:
		emit_signal("fruit_grabbed", get_local_mouse_position().x)
		emit_signal("fruit_dropped", get_local_mouse_position().x)
