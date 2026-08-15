extends Node2D

const EnemyScript = preload("res://scripts/enemy.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const PickupScript = preload("res://scripts/xp_pickup.gd")
const BLADE_TEXTURE := preload("res://assets/source/weapons/blade_ring.png")
const LIGHTNING_TEXTURE := preload("res://assets/source/weapons/lightning.png")
const SOURCE_SPRITE_MATERIAL := preload("res://assets/shaders/source_sprite_mask.tres")

const WEAPON_NAMES := {
	"gun": "旧式短铳",
	"blade": "回响环刃",
	"fireball": "灵火磁芯",
	"lightning": "夜雷线圈",
}

@onready var player: SurvivorPlayer = $Entities/Player
@onready var enemies: Node2D = $Entities/Enemies
@onready var projectiles: Node2D = $Entities/Projectiles
@onready var pickups: Node2D = $Entities/Pickups
@onready var effects: Node2D = $Entities/Effects
@onready var joystick: NightVirtualJoystick = $UI/VirtualJoystick
@onready var stats_label: Label = $UI/HUD/Margin/VBox/Stats
@onready var health_text: Label = $UI/HUD/Margin/VBox/HealthText
@onready var health_bar: ProgressBar = $UI/HUD/Margin/VBox/HealthBar
@onready var xp_text: Label = $UI/HUD/Margin/VBox/XPText
@onready var xp_bar: ProgressBar = $UI/HUD/Margin/VBox/XPBar
@onready var shield_text: Label = $UI/HUD/Margin/VBox/ShieldText
@onready var shield_bar: ProgressBar = $UI/HUD/Margin/VBox/ShieldBar
@onready var timer_label: Label = $UI/Timer
@onready var build_text: Label = $UI/BuildPanel/Margin/VBox/BuildText
@onready var upgrade_overlay: Control = $UI/UpgradeOverlay
@onready var upgrade_level_text: Label = $UI/UpgradeOverlay/Center/Margin/VBox/LevelText
@onready var choice_buttons: Array[Button] = [
	$UI/UpgradeOverlay/Center/Margin/VBox/Choices/Choice1,
	$UI/UpgradeOverlay/Center/Margin/VBox/Choices/Choice2,
	$UI/UpgradeOverlay/Center/Margin/VBox/Choices/Choice3,
]

var elapsed := 0.0
var spawn_timer := 0.0
var gun_timer := 0.0
var fireball_timer := 0.0
var lightning_timer := 0.0
var blade_tick_timer := 0.0
var hud_timer := 0.0
var kills := 0
var level := 1
var xp := 0
var next_xp := 20
var pending_levelups := 0
var game_over := false

var weapon_levels := {
	"gun": 1,
	"blade": 0,
	"fireball": 0,
	"lightning": 0,
}
var damage_multiplier := 1.0
var attack_speed_multiplier := 1.0
var pickup_radius := 145.0

var upgrade_choices: Array[Dictionary] = []
var blade_root: Node2D
var blade_visuals: Array[Sprite2D] = []
var blade_angle := 0.0

func _ready() -> void:
	joystick.direction_changed.connect(player.set_move_input)
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	for index in choice_buttons.size():
		choice_buttons[index].pressed.connect(_on_upgrade_pressed.bind(index))
	blade_root = Node2D.new()
	blade_root.name = "BladeOrbit"
	blade_root.z_index = 2
	player.add_child(blade_root)
	for i in range(8):
		spawn_enemy(i * TAU / 8.0)
	refresh_blade_visuals()
	update_build_ui()
	update_hud()

func _process(delta: float) -> void:
	if game_over:
		return
	elapsed += delta
	spawn_timer -= delta
	gun_timer -= delta
	fireball_timer -= delta
	lightning_timer -= delta
	blade_tick_timer -= delta
	hud_timer -= delta

	if spawn_timer <= 0.0 and enemies.get_child_count() < enemy_cap():
		var amount := 1 + mini(2, int(elapsed / 180.0))
		for i in range(amount):
			spawn_enemy(randf() * TAU)
		spawn_timer = maxf(0.28, 0.9 - elapsed * 0.0007)

	if int(weapon_levels["gun"]) > 0 and gun_timer <= 0.0:
		fire_gun()
		gun_timer = _gun_interval()
	if int(weapon_levels["fireball"]) > 0 and fireball_timer <= 0.0:
		fire_fireballs()
		fireball_timer = _fireball_interval()
	if int(weapon_levels["lightning"]) > 0 and lightning_timer <= 0.0:
		cast_lightning()
		lightning_timer = _lightning_interval()
	if int(weapon_levels["blade"]) > 0:
		update_blade_orbit(delta)
		if blade_tick_timer <= 0.0:
			apply_blade_damage()
			blade_tick_timer = maxf(0.12, 0.28 / attack_speed_multiplier)

	resolve_collisions()
	if hud_timer <= 0.0:
		update_hud()
		hud_timer = 0.1

func enemy_cap() -> int:
	return mini(240, 70 + int(elapsed / 8.0))

func spawn_enemy(angle: float) -> void:
	var enemy: NightEnemy = EnemyScript.new()
	var distance := randf_range(560.0, 760.0)
	enemy.global_position = player.global_position + Vector2.from_angle(angle) * distance
	var available_variants := clampi(2 + int(elapsed / 90.0), 2, 8)
	var variant := randi_range(0, available_variants - 1)
	enemy.setup(player, elapsed / 120.0, variant)
	enemies.add_child(enemy)

func nearest_enemy() -> NightEnemy:
	var nearest: NightEnemy
	var nearest_distance := INF
	for child in enemies.get_children():
		var enemy := child as NightEnemy
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest

func fire_gun() -> void:
	var target := nearest_enemy()
	if target == null:
		return
	var weapon_level := int(weapon_levels["gun"])
	var direction := player.global_position.direction_to(target.global_position)
	player.facing = direction
	var bullet: NightProjectile = ProjectileScript.new()
	bullet.global_position = player.global_position + direction * 28.0
	bullet.velocity = direction * (680.0 + weapon_level * 8.0)
	bullet.configure_gun(10.0 * (1.0 + (weapon_level - 1) * 0.16) * damage_multiplier, weapon_level)
	projectiles.add_child(bullet)

func fire_fireballs() -> void:
	var target := nearest_enemy()
	if target == null:
		return
	var weapon_level := int(weapon_levels["fireball"])
	var base_direction := player.global_position.direction_to(target.global_position)
	var amount := 1 + int(weapon_level >= 6) + int(weapon_level >= 10)
	for index in amount:
		var spread := (index - (amount - 1) * 0.5) * 0.16
		var direction := base_direction.rotated(spread)
		var fireball: NightProjectile = ProjectileScript.new()
		fireball.global_position = player.global_position + direction * 32.0
		fireball.velocity = direction * (420.0 + weapon_level * 5.0)
		fireball.configure_fireball(18.0 * (1.0 + (weapon_level - 1) * 0.22) * damage_multiplier, weapon_level)
		projectiles.add_child(fireball)

func cast_lightning() -> void:
	var target := nearest_enemy()
	if target == null:
		return
	var weapon_level := int(weapon_levels["lightning"])
	var strike_position := target.global_position
	var radius := 68.0 + weapon_level * 4.0
	var damage := 26.0 * (1.0 + (weapon_level - 1) * 0.2) * damage_multiplier
	spawn_lightning_visual(strike_position, weapon_level)
	for child in enemies.get_children():
		var enemy := child as NightEnemy
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_squared_to(strike_position) <= pow(radius + enemy.radius, 2.0):
			if enemy.hit(damage):
				kill_enemy(enemy)

func spawn_lightning_visual(strike_position: Vector2, weapon_level: int) -> void:
	var visual := Sprite2D.new()
	visual.texture = LIGHTNING_TEXTURE
	visual.material = SOURCE_SPRITE_MATERIAL
	visual.scale = Vector2(0.135, 0.135) * (1.0 + weapon_level * 0.018)
	visual.global_position = strike_position + Vector2(0.0, -67.0)
	visual.z_index = 8
	if weapon_level >= 10:
		visual.modulate = Color(0.72, 0.86, 1.45, 1.0)
	effects.add_child(visual)
	var tween := visual.create_tween()
	tween.tween_interval(0.18)
	tween.tween_property(visual, "modulate:a", 0.0, 0.16)
	tween.tween_callback(visual.queue_free)

func refresh_blade_visuals() -> void:
	for child in blade_root.get_children():
		child.queue_free()
	blade_visuals.clear()
	var weapon_level := int(weapon_levels["blade"])
	if weapon_level <= 0:
		return
	var amount := 1 + int((weapon_level - 1) / 3.0)
	for index in amount:
		var visual := Sprite2D.new()
		visual.texture = BLADE_TEXTURE
		visual.material = SOURCE_SPRITE_MATERIAL
		visual.scale = Vector2(0.064, 0.064) * (1.0 + weapon_level * 0.018)
		if weapon_level >= 10:
			visual.modulate = Color(1.35, 0.82, 1.5, 1.0)
		blade_root.add_child(visual)
		blade_visuals.append(visual)
	update_blade_orbit(0.0)

func update_blade_orbit(delta: float) -> void:
	var weapon_level := int(weapon_levels["blade"])
	blade_angle = fmod(blade_angle + delta * (2.2 + weapon_level * 0.08) * attack_speed_multiplier, TAU)
	var orbit_radius := 70.0 + weapon_level * 2.0
	for index in blade_visuals.size():
		var angle := blade_angle + TAU * index / blade_visuals.size()
		blade_visuals[index].position = Vector2.from_angle(angle) * orbit_radius
		blade_visuals[index].rotation = angle + PI * 0.25

func apply_blade_damage() -> void:
	var weapon_level := int(weapon_levels["blade"])
	var damage := 7.0 * (1.0 + (weapon_level - 1) * 0.2) * damage_multiplier
	for child in enemies.get_children():
		var enemy := child as NightEnemy
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		for blade in blade_visuals:
			var blade_position := blade_root.to_global(blade.position)
			if blade_position.distance_squared_to(enemy.global_position) <= pow(17.0 + enemy.radius, 2.0):
				if enemy.hit(damage):
					kill_enemy(enemy)
				break

func _gun_interval() -> float:
	return maxf(0.1, 0.42 * pow(0.94, int(weapon_levels["gun"]) - 1) / attack_speed_multiplier)

func _fireball_interval() -> float:
	return maxf(0.42, 1.8 * pow(0.93, int(weapon_levels["fireball"]) - 1) / attack_speed_multiplier)

func _lightning_interval() -> float:
	return maxf(0.62, 2.6 * pow(0.92, int(weapon_levels["lightning"]) - 1) / attack_speed_multiplier)

func resolve_collisions() -> void:
	for enemy_node in enemies.get_children():
		var enemy := enemy_node as NightEnemy
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.touch_cooldown <= 0.0 and enemy.global_position.distance_squared_to(player.global_position) < pow(enemy.radius + 18.0, 2.0):
			enemy.touch_cooldown = 0.75
			player.take_damage(enemy.damage)

	for bullet_node in projectiles.get_children():
		var bullet := bullet_node as NightProjectile
		if not is_instance_valid(bullet) or bullet.is_queued_for_deletion():
			continue
		for enemy_node in enemies.get_children():
			var enemy := enemy_node as NightEnemy
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
				continue
			var enemy_id := enemy.get_instance_id()
			if not bullet.can_hit(enemy_id):
				continue
			if bullet.global_position.distance_squared_to(enemy.global_position) <= pow(bullet.radius + enemy.radius, 2.0):
				var consumed := bullet.register_hit(enemy_id)
				if enemy.hit(bullet.damage):
					kill_enemy(enemy)
				if consumed:
					bullet.queue_free()
					break

	for pickup_node in pickups.get_children():
		var pickup := pickup_node as XPPickup
		if is_instance_valid(pickup) and pickup.global_position.distance_squared_to(player.global_position) < 28.0 * 28.0:
			gain_xp(pickup.value)
			pickup.queue_free()

func kill_enemy(enemy: NightEnemy) -> void:
	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
		return
	kills += 1
	var pickup: XPPickup = PickupScript.new()
	pickup.global_position = enemy.global_position
	pickup.target = player
	pickup.pickup_radius = pickup_radius
	pickups.add_child(pickup)
	enemy.queue_free()

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= next_xp:
		xp -= next_xp
		level += 1
		next_xp = int(16.0 + pow(level, 1.28) * 7.0)
		pending_levelups += 1
	update_hud()
	if pending_levelups > 0 and not upgrade_overlay.visible:
		show_upgrade_choices()

func show_upgrade_choices() -> void:
	if pending_levelups <= 0 or game_over:
		return
	upgrade_choices = roll_upgrade_choices()
	upgrade_level_text.text = "LEVEL %02d  ·  升级三选一" % level
	for index in choice_buttons.size():
		var option := upgrade_choices[index]
		choice_buttons[index].text = "%s\n\n%s" % [option["title"], option["description"]]
	upgrade_overlay.visible = true
	joystick.reset_stick()
	get_tree().paused = true

func roll_upgrade_choices() -> Array[Dictionary]:
	var ids: Array[String] = []
	for weapon_id in ["gun", "blade", "fireball", "lightning"]:
		if int(weapon_levels[weapon_id]) < 10:
			ids.append(weapon_id)
	ids.append_array(["damage", "fire_rate", "max_health", "shield", "move_speed", "pickup"])
	ids.shuffle()
	var result: Array[Dictionary] = []
	for index in 3:
		result.append(make_upgrade_option(ids[index]))
	return result

func make_upgrade_option(id: String) -> Dictionary:
	if weapon_levels.has(id):
		var current := int(weapon_levels[id])
		var next_level := current + 1
		var verb := "获得武器" if current == 0 else "武器强化"
		var details: String = {
			"gun": "伤害与射速提升；高等级可贯穿敌人",
			"blade": "环绕角色切割怪群；等级提升增加环刃",
			"fireball": "发射高伤穿透火球；高等级增加数量",
			"lightning": "对目标区域降下落雷并造成范围伤害",
		}[id]
		return {"id": id, "title": "%s  Lv.%d" % [WEAPON_NAMES[id], next_level], "description": "%s\n%s" % [verb, details]}
	var stat_options := {
		"damage": {"title": "火力校准", "description": "全部武器伤害 +12%\n数值强化 · 不限次数"},
		"fire_rate": {"title": "超频扳机", "description": "全部武器攻击速度 +10%\n数值强化 · 不限次数"},
		"max_health": {"title": "生命扩容", "description": "生命上限 +10，并恢复10点生命\n数值强化 · 不限次数"},
		"shield": {"title": "护盾电池", "description": "护盾上限 +10，并补充10点护盾\n数值强化 · 不限次数"},
		"move_speed": {"title": "轻量靴底", "description": "移动速度 +12\n数值强化 · 不限次数"},
		"pickup": {"title": "磁力拾取", "description": "经验拾取范围 +18\n数值强化 · 不限次数"},
	}
	var option: Dictionary = stat_options[id].duplicate()
	option["id"] = id
	return option

func _on_upgrade_pressed(index: int) -> void:
	if not upgrade_overlay.visible or index < 0 or index >= upgrade_choices.size():
		return
	apply_upgrade(String(upgrade_choices[index]["id"]))
	pending_levelups = maxi(0, pending_levelups - 1)
	upgrade_overlay.visible = false
	refresh_blade_visuals()
	update_build_ui()
	update_hud()
	if pending_levelups > 0:
		show_upgrade_choices()
	else:
		get_tree().paused = false

func apply_upgrade(id: String) -> void:
	match id:
		"gun", "blade", "fireball", "lightning":
			weapon_levels[id] = mini(10, int(weapon_levels[id]) + 1)
		"damage":
			damage_multiplier *= 1.12
		"fire_rate":
			attack_speed_multiplier *= 1.1
		"max_health":
			player.max_health += 10.0
			player.health = minf(player.max_health, player.health + 10.0)
			player.health_changed.emit(player.health, player.max_health)
		"shield":
			player.max_shield += 10.0
			player.shield = minf(player.max_shield, player.shield + 10.0)
			player.health_changed.emit(player.health, player.max_health)
		"move_speed":
			player.move_speed += 12.0
		"pickup":
			pickup_radius += 18.0
			for child in pickups.get_children():
				var pickup := child as XPPickup
				if is_instance_valid(pickup):
					pickup.pickup_radius = pickup_radius

func update_build_ui() -> void:
	build_text.text = "枪械  Lv.%d\n环刃  Lv.%d\n火球  Lv.%d\n落雷  Lv.%d" % [
		int(weapon_levels["gun"]),
		int(weapon_levels["blade"]),
		int(weapon_levels["fireball"]),
		int(weapon_levels["lightning"]),
	]

func update_hud() -> void:
	var seconds := int(elapsed)
	timer_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	stats_label.text = "等级 %02d    击破 %d" % [level, kills]
	health_text.text = "生命  %d / %d" % [ceili(player.health), ceili(player.max_health)]
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	xp_text.text = "经验  %d / %d" % [xp, next_xp]
	xp_bar.max_value = next_xp
	xp_bar.value = xp
	shield_text.text = "护盾  %d / %d" % [ceili(player.shield), ceili(player.max_shield)]
	shield_bar.max_value = maxf(1.0, player.max_shield)
	shield_bar.value = player.shield

func _on_health_changed(_current: float, _maximum: float) -> void:
	update_hud()

func _on_player_died() -> void:
	game_over = true
	upgrade_overlay.visible = false
	get_tree().paused = true
	stats_label.text = "本轮结束 · 存活 %s · 击破 %d" % [timer_label.text, kills]
