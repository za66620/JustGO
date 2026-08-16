class_name PlayerWeaponRig
extends Node2D

const MUZZLE_DISTANCE := 25.0

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
	# The node origin is the grip in the player's hand. Only the weapon turns here;
	# its position is maintained by the player's animated hand anchor.
	scale.y = -1.0 if aim_direction.x < 0.0 else 1.0
	z_index = -1 if aim_direction.y < -0.42 else 3

func muzzle_global_position() -> Vector2:
	if is_instance_valid(muzzle):
		return muzzle.global_position
	return global_position + aim_direction * MUZZLE_DISTANCE

func _draw() -> void:
	# Compact placeholder gun. The origin (0, 0) is the grip/hand pivot and the
	# muzzle Marker2D is positioned at the end of the barrel.
	draw_rect(Rect2(-3.0, -4.0, 21.0, 8.0), Color("253249"), true)
	draw_rect(Rect2(1.0, -2.5, 17.0, 3.0), Color("60728c"), true)
	draw_rect(Rect2(17.0, -2.0, 8.0, 4.0), Color("69e6da"), true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-1.0, 3.0), Vector2(5.0, 3.0),
		Vector2(3.0, 11.0), Vector2(-2.0, 11.0),
	]), Color("182238"))
