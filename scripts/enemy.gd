class_name NightEnemy
extends Node2D

const SOURCE_SPRITE_MATERIAL := preload("res://assets/shaders/source_sprite_mask.tres")
const MONSTER_TEXTURES: Array[Texture2D] = [
	preload("res://assets/source/monsters/monster_01.png"),
	preload("res://assets/source/monsters/monster_02.png"),
	preload("res://assets/source/monsters/monster_03.png"),
	preload("res://assets/source/monsters/monster_04.png"),
	preload("res://assets/source/monsters/monster_05.png"),
	preload("res://assets/source/monsters/monster_06.png"),
	preload("res://assets/source/monsters/monster_07.png"),
	preload("res://assets/source/monsters/monster_08.png"),
]
const SPEED_FACTORS := [1.0, 0.72, 0.86, 1.62, 0.68, 1.24, 1.42, 1.08]
const HEALTH_FACTORS := [1.0, 1.85, 1.35, 0.62, 2.2, 1.05, 0.82, 1.55]
const DAMAGE_FACTORS := [1.0, 1.15, 1.35, 0.82, 1.55, 1.65, 1.05, 1.25]
const RADII := [16.0, 20.0, 19.0, 14.0, 23.0, 16.0, 15.0, 19.0]
const VISUAL_SCALES := [0.086, 0.088, 0.096, 0.088, 0.105, 0.086, 0.082, 0.088]

var target: Node2D
var speed := 74.0
var health := 18.0
var max_health := 18.0
var damage := 6.0
var radius := 16.0
var touch_cooldown := 0.0
var hit_flash := 0.0
var visual: Sprite2D

func setup(player: Node2D, difficulty: float, variant: int = 0) -> void:
	target = player
	var index := clampi(variant, 0, MONSTER_TEXTURES.size() - 1)
	speed *= SPEED_FACTORS[index] * (1.0 + difficulty * 0.08)
	health *= HEALTH_FACTORS[index] * (1.0 + difficulty * 0.28)
	max_health = health
	damage *= DAMAGE_FACTORS[index] * (1.0 + difficulty * 0.14)
	radius = RADII[index]
	visual = Sprite2D.new()
	visual.texture = MONSTER_TEXTURES[index]
	visual.material = SOURCE_SPRITE_MATERIAL
	visual.scale = Vector2(VISUAL_SCALES[index], VISUAL_SCALES[index])
	visual.position.y = -4.0
	add_child(visual)

func _process(delta: float) -> void:
	touch_cooldown = maxf(0.0, touch_cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	if is_instance_valid(target):
		var direction := global_position.direction_to(target.global_position)
		global_position += direction * speed * delta
		visual.flip_h = direction.x < -0.08
	visual.modulate = Color(1.8, 1.8, 1.8, 1.0) if hit_flash > 0.0 else Color.WHITE

func hit(amount: float) -> bool:
	health -= amount
	hit_flash = 0.08
	queue_redraw()
	return health <= 0.0

func _draw() -> void:
	if health >= max_health:
		return
	var width := radius * 2.0
	draw_rect(Rect2(-radius, radius + 7.0, width, 3.0), Color(0.05, 0.07, 0.12, 0.85))
	draw_rect(Rect2(-radius, radius + 7.0, width * clampf(health / max_health, 0.0, 1.0), 3.0), Color("ff657f"))
