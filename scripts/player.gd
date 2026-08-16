class_name SurvivorPlayer
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal died

const PLAYER_SHEET := preload("res://assets/characters/survivor_sheet.png")
const WeaponRigScript := preload("res://scripts/player_weapon_rig.gd")

const FRAME_SIZE := Vector2(256.0, 256.0)
const FRAME_COUNT := 4

@export var move_speed := 220.0
@export var max_health := 50.0
@export var max_shield := 0.0

var health := 50.0
var shield := 0.0
var move_input := Vector2.ZERO
var facing := Vector2.RIGHT
var invulnerable_time := 0.0
var visual: AnimatedSprite2D
var weapon_rig: PlayerWeaponRig

func _ready() -> void:
	health = max_health
	shield = max_shield
	visual = AnimatedSprite2D.new()
	visual.name = "AnimatedVisual"
	visual.sprite_frames = _build_sprite_frames()
	visual.scale = Vector2(0.27, 0.27)
	visual.position = Vector2(0.0, -21.0)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.play("idle")
	add_child(visual)

	weapon_rig = WeaponRigScript.new()
	weapon_rig.name = "WeaponRig"
	weapon_rig.position = Vector2(0.0, -8.0)
	add_child(weapon_rig)

func _physics_process(delta: float) -> void:
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := move_input if move_input.length_squared() > 0.01 else keyboard
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	velocity = direction * move_speed
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	move_and_slide()

	var moving := direction.length_squared() > 0.01
	var next_animation := &"walk" if moving else &"idle"
	if visual.animation != next_animation:
		visual.play(next_animation)
	visual.flip_h = facing.x < -0.08
	visual.modulate = Color(1.6, 1.6, 1.6, 1.0) if invulnerable_time > 0.0 and int(invulnerable_time * 18.0) % 2 == 0 else Color.WHITE

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 4.0)
	frames.set_animation_loop(&"idle", true)
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 9.0)
	frames.set_animation_loop(&"walk", true)
	for frame_index in FRAME_COUNT:
		frames.add_frame(&"idle", _atlas_frame(frame_index, 0))
		frames.add_frame(&"walk", _atlas_frame(frame_index, 1))
	return frames

func _atlas_frame(column: int, row: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = PLAYER_SHEET
	frame.region = Rect2(Vector2(column, row) * FRAME_SIZE, FRAME_SIZE)
	return frame

func aim_weapon(direction: Vector2) -> void:
	if is_instance_valid(weapon_rig):
		weapon_rig.aim(direction)

func gun_muzzle_position() -> Vector2:
	if is_instance_valid(weapon_rig):
		return weapon_rig.muzzle_global_position()
	return global_position

func set_move_input(value: Vector2) -> void:
	move_input = Vector2.ZERO if value.length() < 0.16 else value.limit_length(1.0)

func take_damage(amount: float) -> void:
	if invulnerable_time > 0.0 or health <= 0.0:
		return
	var remaining := amount
	if shield > 0.0:
		var absorbed := minf(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
	health = maxf(0.0, health - remaining)
	invulnerable_time = 0.45
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()
