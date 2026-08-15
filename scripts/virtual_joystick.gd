class_name NightVirtualJoystick
extends Control

signal direction_changed(direction: Vector2)

@export var radius := 72.0
@export var deadzone := 0.12

var direction := Vector2.ZERO
var active_touch := -1
var dragging_mouse := false

func _ready() -> void:
	clip_contents = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var local_position := _screen_to_local(event.position)
		if event.pressed and active_touch == -1 and Rect2(Vector2.ZERO, size).has_point(local_position):
			active_touch = event.index
			update_stick(local_position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			reset_stick()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == active_touch:
		update_stick(_screen_to_local(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_position := _screen_to_local(event.position)
		if event.pressed and Rect2(Vector2.ZERO, size).has_point(mouse_position):
			dragging_mouse = true
			update_stick(mouse_position)
		elif not event.pressed and dragging_mouse:
			dragging_mouse = false
			reset_stick()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging_mouse:
		update_stick(_screen_to_local(event.position))
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		active_touch = -1
		dragging_mouse = false
		reset_stick()

func _screen_to_local(screen_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_position

func update_stick(local_position: Vector2) -> void:
	var center := size * 0.5
	var offset := local_position - center
	direction = offset.limit_length(radius) / radius
	if direction.length() < deadzone:
		direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func reset_stick() -> void:
	direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius + 15.0, Color(0.03, 0.07, 0.13, 0.58))
	draw_circle(center, radius + 15.0, Color(0.26, 0.9, 0.83, 0.32), false, 3.0)
	draw_circle(center, radius, Color(0.16, 0.26, 0.37, 0.36))
	draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), Color(0.7, 0.95, 0.95, 0.12), 2.0)
	draw_line(center - Vector2(0, radius), center + Vector2(0, radius), Color(0.7, 0.95, 0.95, 0.12), 2.0)
	var knob_position := center + direction * radius
	draw_circle(knob_position, 31.0, Color(0.32, 0.83, 0.78, 0.86))
	draw_circle(knob_position, 31.0, Color(0.88, 1.0, 0.97, 0.72), false, 3.0)
