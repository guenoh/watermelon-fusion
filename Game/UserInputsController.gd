extends Node2D


signal fruit_moved(pos)
signal fruit_dropped(pos)
signal fruit_grabbed(pos)
signal drag_cancelled



# Mouse input is emulated as screen touches by project.godot, so a mouse
# gesture and a real touch follow the same path without dropping twice.
var active_touch := -1



func cancel_drag():
	var was_dragging := active_touch != -1
	active_touch = -1
	if was_dragging:
		emit_signal("drag_cancelled")


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT or what == MainLoop.NOTIFICATION_APP_PAUSED:
		cancel_drag()


func _input(event):
	# Catch the end of a gesture even when released over a GUI control.
	if event is InputEventScreenTouch and not event.pressed and event.index == active_touch:
		var local_event = make_input_local(event)
		active_touch = -1
		emit_signal("fruit_dropped", local_event.position.x)


func _unhandled_input(event):
	event = make_input_local(event)
	if event is InputEventScreenTouch and event.pressed:
		# Other fingers cannot take over a drag. GUI presses are consumed
		# before reaching this method.
		if active_touch != -1:
			return
		active_touch = event.index
		emit_signal("fruit_grabbed", event.position.x)
	elif event is InputEventScreenDrag and event.index == active_touch:
		emit_signal("fruit_moved", event.position.x)
	elif OS.is_debug_build() and event.is_action_pressed("ui_accept"):
		emit_signal("fruit_dropped", get_local_mouse_position().x)
