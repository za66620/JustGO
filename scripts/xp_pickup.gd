class_name XPPickup
extends Node2D

var value := 5
var target: Node2D
var pickup_radius := 145.0

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var distance := global_position.distance_to(target.global_position)
	if distance < pickup_radius:
		var speed := lerpf(110.0, 430.0, 1.0 - distance / pickup_radius)
		global_position = global_position.move_toward(target.global_position, speed * delta)

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0)]), Color("6cf6e3"))
	draw_polyline(PackedVector2Array([Vector2(0, -8), Vector2(7, 0), Vector2(0, 8), Vector2(-7, 0), Vector2(0, -8)]), Color("d9fff7"), 2.0)
