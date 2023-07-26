# this is a port of methods from belzecue/frankiezafe_godot-wireframe
@tool
extends MeshInstance3D

@export var sides: bool = true:
	set = _set_sides,
	get = _get_sides
@export var split: float = 0:
	set = _set_split,
	get = _get_split
@export var sweep: float = PI / 4:
	set = _set_sweep,
	get = _get_sweep
@export var depth: float = 0.5:
	set = _set_depth,
	get = _get_depth
@export var height: float = 0.25:
	set = _set_height,
	get = _get_height
@export var angle_limit: float = 5 * PI / 180:
	set = _set_angle_limit,
	get = _get_angle_limit

var processed_once: bool = false


func _set_sides(p) -> void:
	sides = p
	if processed_once:
		remesh()


func _get_sides() -> bool:
	return sides


func _set_split(p) -> void:
	split = clampf(p, 0.0, 0.5)
	if processed_once:
		remesh()


func _get_split() -> float:
	return split


func _set_sweep(p) -> void:
	sweep = clampf(p, 0.0, PI)
	if processed_once:
		remesh()


func _get_sweep() -> float:
	return sweep


func _set_angle_limit(p) -> void:
	angle_limit = clampf(p, 0.0, PI)
	if processed_once:
		remesh()


func _get_angle_limit() -> float:
	return angle_limit


func _get_depth() -> float:
	return depth


func _set_depth(p) -> void:
	depth = clampf(p, 0.0, 10.0)
	if processed_once:
		remesh()


func _get_height() -> float:
	return height


func _set_height(p) -> void:
	height = clampf(p, 0.0, 10.0)
	if processed_once:
		remesh()


func remesh() -> void:
	var CylMesher = preload("res://cylindrical_section.gd").new()
	set_mesh(CylMesher.build_cylindrical_section(sweep, depth, height, 1.0, angle_limit, sides, split))


func _ready():
	remesh()


func _process(_delta):
	processed_once = true
