extends Node2D

@export var target_path: NodePath = NodePath("../Entities/Player")
var target: Node2D
const CELL := 96.0
const AREA := 1100.0

func _ready() -> void:
	target = get_node_or_null(target_path)
	queue_redraw()

func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		return
	var snapped := Vector2(round(target.global_position.x / CELL), round(target.global_position.y / CELL)) * CELL
	if snapped != global_position:
		global_position = snapped
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-AREA, -AREA, AREA * 2.0, AREA * 2.0), Color("070b18"))
	var count := int(AREA / CELL) + 2
	var origin_cell := Vector2i(roundi(global_position.x / CELL), roundi(global_position.y / CELL))
	for x in range(-count, count + 1):
		for y in range(-count, count + 1):
			var p := Vector2(x * CELL, y * CELL)
			var world_cell := origin_cell + Vector2i(x, y)
			var value := _cell_hash(world_cell.x, world_cell.y)
			var region := _cell_hash(floori(world_cell.x / 4.0), floori(world_cell.y / 4.0))
			var tile_color := Color("0b1425") if posmod(region, 5) < 3 else Color("0e182a")
			if posmod(value, 9) < 3:
				tile_color = tile_color.lightened(0.025)
			draw_rect(Rect2(p - Vector2(CELL * 0.5, CELL * 0.5), Vector2(CELL - 1.0, CELL - 1.0)), tile_color)
			draw_line(p + Vector2(-CELL * 0.5, CELL * 0.5 - 1.0), p + Vector2(CELL * 0.5, CELL * 0.5 - 1.0), Color(0.18, 0.27, 0.42, 0.075), 1.0)
			_draw_decoration(p, value)

func _draw_decoration(center: Vector2, value: int) -> void:
	var kind := posmod(value, 41)
	var offset := Vector2(posmod(value / 43, 39) - 19, posmod(value / 97, 35) - 17)
	var p := center + offset
	if kind == 0:
		draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 9), p + Vector2(-7, -5), p + Vector2(3, -11), p + Vector2(13, 7)]), Color("26334a"))
		draw_line(p + Vector2(-6, -3), p + Vector2(5, -7), Color(0.42, 0.5, 0.62, 0.35), 2.0)
	elif kind == 1:
		draw_rect(Rect2(p - Vector2(13, 7), Vector2(26, 14)), Color("1d293d"))
		draw_rect(Rect2(p - Vector2(9, 4), Vector2(18, 3)), Color(0.35, 0.44, 0.58, 0.22))
	elif kind == 2:
		draw_line(p + Vector2(-8, 9), p + Vector2(-2, -9), Color("183a38"), 3.0)
		draw_line(p + Vector2(-2, 1), p + Vector2(8, -4), Color("1f4b47"), 2.0)
	elif kind == 3:
		draw_circle(p, 4.0, Color(0.2, 0.72, 0.68, 0.18))
		draw_circle(p, 1.5, Color(0.52, 0.95, 0.88, 0.45))

func _cell_hash(x: int, y: int) -> int:
	var value := x * 374761393 + y * 668265263
	value = (value ^ (value >> 13)) * 1274126177
	return absi(value ^ (value >> 16))
