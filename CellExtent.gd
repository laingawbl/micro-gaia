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
var vertices: Array = []


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


func split_vertices() -> void:
	if split != 0:
		var tmp: Array = []
		for v in vertices:
			tmp.append(v)
		vertices = []
		for i in range(0, len(tmp) / 2):
			var a = tmp[i * 2]
			var b = tmp[i * 2 + 1]
			var mid = b - a
			vertices.append(a)
			vertices.append(a + mid * split)
			vertices.append(b)
			vertices.append(b - mid * split)


func remesh() -> void:
	vertices.clear()

	var seg_count: int = int(ceil(sweep / angle_limit))
	var sweep_incr = sweep / seg_count

	var lhs_vert = Vector3.UP
	var rhs_vert = Vector3.UP.rotated(Vector3.FORWARD, sweep)
	var depth_ofs = Vector3.FORWARD * depth
	var top_radius = 1.0 + height

	# forward edges
	vertices.append(lhs_vert)

	for i in range(1, seg_count):
		var vert = Vector3.UP.rotated(Vector3.FORWARD, i * sweep_incr)
		vertices.append(vert)
		vertices.append(vert)

	vertices.append(rhs_vert)

	vertices.append(lhs_vert * top_radius)

	for i in range(1, seg_count):
		var vert = Vector3.UP.rotated(Vector3.FORWARD, i * sweep_incr) * top_radius
		vertices.append(vert)
		vertices.append(vert)

	vertices.append(rhs_vert * top_radius)

	if depth != 0:
		# forward->back connectors
		vertices.append(lhs_vert)
		vertices.append(lhs_vert + depth_ofs)

		vertices.append(rhs_vert)
		vertices.append(rhs_vert + depth_ofs)

		vertices.append(lhs_vert * top_radius)
		vertices.append(lhs_vert * top_radius + depth_ofs)

		vertices.append(rhs_vert * top_radius)
		vertices.append(rhs_vert * top_radius + depth_ofs)

		# back edges

		vertices.append(lhs_vert + depth_ofs)

		for i in range(1, seg_count):
			var vert = Vector3.UP.rotated(Vector3.FORWARD, i * sweep_incr) + depth_ofs
			vertices.append(vert)
			vertices.append(vert)

		vertices.append(rhs_vert + depth_ofs)

		vertices.append(lhs_vert * top_radius + depth_ofs)

		for i in range(1, seg_count):
			var vert = Vector3.UP.rotated(Vector3.FORWARD, i * sweep_incr) * top_radius + depth_ofs
			vertices.append(vert)
			vertices.append(vert)

		vertices.append(rhs_vert * top_radius + depth_ofs)

	if sides:
		vertices.append(lhs_vert)
		vertices.append(lhs_vert * top_radius)

		vertices.append(rhs_vert)
		vertices.append(rhs_vert * top_radius)

		if depth != 0:
			vertices.append(lhs_vert + depth_ofs)
			vertices.append(lhs_vert * top_radius + depth_ofs)

			vertices.append(rhs_vert + depth_ofs)
			vertices.append(rhs_vert * top_radius + depth_ofs)

	split_vertices()

	var _mesh = ArrayMesh.new()
	var _surf = SurfaceTool.new()

	_surf.begin(Mesh.PRIMITIVE_LINES)
	for v in vertices:
		_surf.add_vertex(v)
	_surf.index()
	_surf.commit(_mesh)
	set_mesh(_mesh)
	vertices.clear()


func _ready():
	remesh()


func _process(_delta):
	processed_once = true
