class_name NightProjectile
extends Node2D

const FIREBALL_TEXTURE := preload("res://assets/source/weapons/fireball.png")
const SOURCE_SPRITE_MATERIAL := preload("res://assets/shaders/source_sprite_mask.tres")

var velocity := Vector2.ZERO
var damage := 10.0
var lifetime := 1.8
var radius := 5.0
var pierce := 1
var weapon_level := 1
var kind := "gun"
var hit_targets: Dictionary = {}
var visual: Sprite2D

func configure_gun(new_damage: float, level: int) -> void:
	damage = new_damage
	weapon_level = level
	radius = 5.0 + floorf((level - 1) / 3.0)
	pierce = 1 + int(level / 5.0)
	lifetime = 1.8 + level * 0.035
	queue_redraw()

func configure_fireball(new_damage: float, level: int) -> void:
	kind = "fireball"
	damage = new_damage
	weapon_level = level
	radius = 11.0 + level * 0.65
	pierce = 1 + int((level - 1) / 3.0)
	lifetime = 2.35
	visual = Sprite2D.new()
	visual.texture = FIREBALL_TEXTURE
	visual.material = SOURCE_SPRITE_MATERIAL
	visual.scale = Vector2(0.058, 0.058) * (1.0 + level * 0.025)
	if level >= 10:
		visual.modulate = Color(1.25, 0.65, 1.45, 1.0)
	add_child(visual)
	queue_redraw()

func _process(delta: float) -> void:
	global_position += velocity * delta
	if kind == "fireball":
		rotation += delta * 2.8
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func can_hit(instance_id: int) -> bool:
	return not hit_targets.has(instance_id)

func register_hit(instance_id: int) -> bool:
	hit_targets[instance_id] = true
	pierce -= 1
	return pierce <= 0

func _draw() -> void:
	if kind == "fireball":
		draw_circle(Vector2.ZERO, radius + 7.0, Color(1.0, 0.22, 0.08, 0.14))
		return
	var core := Color("66f4dd")
	if weapon_level >= 10:
		core = Color("f4c95d")
	elif weapon_level >= 7:
		core = Color("b47cff")
	draw_circle(Vector2.ZERO, radius + 4.0, Color(core, 0.2))
	draw_circle(Vector2.ZERO, radius, core)
