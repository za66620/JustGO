class_name PlayerWeaponRig
extends Node2D

const MUZZLE_DISTANCE := 35.0

var muzzle: Marker2D
var aim_direction := Vector2.RIGHT

func _ready() -> void:
	z_index = 3
	muzzle = Marker2D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector2(MUZZLE_DISTANCE, 0.0)
	add_child(muzzle)
	queue_redraw()

func aim(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	aim_direction = direction.normalized()
	rotation = aim_direction.angle()
	# Turn the weapon over on the left side so its grip does not appear upside down.
	scale.y = -1.0 if aim_direction.x < 0.0 else 1.0

func muzzle_global_position() -> Vector2:
	if is_instance_valid(muzzle):
		return muzzle.global_position
	return global_position + aim_direction * MUZZLE_DISTANCE

func _draw() -> void:
	# Temporary weapon art: the rig, pivot and muzzle are now correct and can later
	# receive a dedicated gun sprite without changing aiming or projectile logic.
	draw_rect(Rect2(7.0, -6.0, 27.0, 12.0), Color("253249"), true)
	draw_rect(Rect2(11.0, -4.0, 19.0, 4.0), Color("60728c"), true)
	draw_rect(Rect2(29.0, -3.0, 8.0, 6.0), Color("69e6da"), true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(13.0, 5.0), Vector2(21.0, 5.0),
		Vector2(18.0, 16.0), Vector2(11.0, 16.0),
	]), Color("182238"))
