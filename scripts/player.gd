class_name SurvivorPlayer
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal died

const PLAYER_TEXTURE := preload("res://assets/source/player.png")
const SOURCE_SPRITE_MATERIAL := preload("res://assets/shaders/source_sprite_mask.tres")

@export var move_speed := 220.0
@export var max_health := 50.0
@export var max_shield := 0.0

var health := 50.0
var shield := 0.0
var move_input := Vector2.ZERO
var facing := Vector2.RIGHT
var invulnerable_time := 0.0
var visual: Sprite2D

func _ready() -> void:
	health = max_health
	shield = max_shield
	visual = Sprite2D.new()
	visual.texture = PLAYER_TEXTURE
	visual.material = SOURCE_SPRITE_MATERIAL
	visual.scale = Vector2(0.105, 0.105)
	visual.position = Vector2(0.0, -3.0)
	add_child(visual)

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
	visual.flip_h = facing.x < -0.08
	var moving := direction.length_squared() > 0.01
	visual.position.y = -3.0 + (sin(Time.get_ticks_msec() * 0.012) * 1.5 if moving else 0.0)
	visual.modulate = Color(1.6, 1.6, 1.6, 1.0) if invulnerable_time > 0.0 and int(invulnerable_time * 18.0) % 2 == 0 else Color.WHITE

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
