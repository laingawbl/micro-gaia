@tool
extends MeshInstance3D

signal changed

enum TangentType { CATMULL_ROM, CARDINAL, FINITE_DIFFERENCE, MONOTONISH }

@export var SegCount: int = 4:
	set = _set_SegCount,
	get = _get_SegCount
@export var SplineTension: float = 0:
	set = _set_SplineTension,
	get = _get_SplineTension
@export var Points: Array[Vector3]:
	set = _set_Points,
	get = _get_Points
@export var SplineMat: Material:
	set = _set_SplineMat,
	get = _get_SplineMat
@export var SplineTangentType: TangentType = TangentType.CATMULL_ROM:
	set = _set_SplineTangentType,
	get = _get_SplineTangentType
@export var SplineStartHandle: Vector3 = Vector3.ZERO:
	set = _set_SplineStartHandle,
	get = _get_SplineStartHandle
@export var SplineEndHandle: Vector3 = Vector3.ZERO:
	set = _set_SplineEndHandle,
	get = _get_SplineEndHandle

@export var UseVertexColours: bool = false:
	set = _set_UseVertexColours,
	get = _get_UseVertexColours
@export var UniformUVSampling: bool = false:
	set = _set_UniformUVSampling,
	get = _get_UniformUVSampling
@export var VertexColours: Gradient:
	set = _set_VertexColours,
	get = _get_VertexColours
@export var ShowUniformPoints: bool = false:
	set = _set_ShowUniformPoints,
	get = _get_ShowUniformPoints
@export var UniformPointSpacing: float = 1.0:
	set = _set_UniformPointSpacing,
	get = _get_UniformPointSpacing

var _vert_list: Array[Vector3] = []
var _normal_list: Array[Vector3] = []
var processed_once: bool = false


func _set_SegCount(p) -> void:
	SegCount = max(1, p)
	if processed_once:
		remesh()


func _get_SegCount() -> int:
	return SegCount


func _set_SplineTension(p) -> void:
	SplineTension = clamp(p, 0.0, 1.0)
	if processed_once:
		remesh()


func _get_SplineTension() -> float:
	return SplineTension


func _set_SplineTangentType(p) -> void:
	SplineTangentType = p
	if processed_once:
		remesh()


func _get_SplineTangentType() -> TangentType:
	return SplineTangentType


func _set_Points(p) -> void:
	Points = p
	if processed_once:
		remesh()


func _get_Points() -> Array[Vector3]:
	return Points


func _set_SplineMat(p) -> void:
	SplineMat = p
	if processed_once:
		mesh.surface_set_material(0, SplineMat)


func _get_SplineMat() -> Material:
	return SplineMat


func _set_UseVertexColours(p) -> void:
	UseVertexColours = p
	if SplineMat is StandardMaterial3D:
		SplineMat.vertex_color_use_as_albedo = UseVertexColours
		mesh.surface_set_material(0, SplineMat)
	if processed_once and UseVertexColours and VertexColours != null:
		remesh()


func _get_UseVertexColours() -> bool:
	return UseVertexColours


func _set_UniformUVSampling(p) -> void:
	UniformUVSampling = p
	if processed_once:
		remesh()


func _get_UniformUVSampling() -> bool:
	return UniformUVSampling


func _set_VertexColours(p) -> void:
	VertexColours = p
	if processed_once and UseVertexColours:
		remesh()


func _get_VertexColours() -> Gradient:
	return VertexColours


func _set_ShowUniformPoints(p) -> void:
	ShowUniformPoints = p
	if processed_once:
		remesh()


func _get_ShowUniformPoints() -> bool:
	return ShowUniformPoints


func _set_UniformPointSpacing(p) -> void:
	UniformPointSpacing = max(0.0, p)
	if processed_once:
		remesh()


func _get_UniformPointSpacing() -> float:
	return UniformPointSpacing


func _set_SplineStartHandle(p) -> void:
	SplineStartHandle = p
	if processed_once:
		remesh()


func _get_SplineStartHandle() -> Vector3:
	return SplineStartHandle


func _set_SplineEndHandle(p) -> void:
	SplineEndHandle = p
	if processed_once:
		remesh()


func _get_SplineEndHandle() -> Vector3:
	return SplineEndHandle


# METHODS #


func hermite(p1: float, p2: float, v1: float, v2: float, t: float) -> float:
	var t2 = t * t
	var t3 = t * t * t
	var a = 1 - 3 * t2 + 2 * t3
	var b = t2 * (3 - 2 * t)
	var c = t * (t - 1) * (t - 1)
	var d = t2 * (t - 1)
	return a * p1 + b * p2 + c * v1 + d * v2


func initial_tangent() -> Vector3:
	if SplineStartHandle != Vector3.ZERO:
		return SplineStartHandle
	return Points[0].direction_to(Points[1])


func final_tangent() -> Vector3:
	if SplineEndHandle != Vector3.ZERO:
		return SplineEndHandle
	var lp = len(Points)
	return Points[lp - 2].direction_to(Points[lp - 1])


func tangent(prev: Vector3, curr: Vector3, next: Vector3) -> Vector3:
	match SplineTangentType:
		TangentType.CATMULL_ROM:
			return (next - prev) * 0.5
		TangentType.CARDINAL:
			var d = 1.0 / prev.distance_to(next)
			return (1.0 - SplineTension) * (next - prev) * d
		TangentType.FINITE_DIFFERENCE:
			var d1 = 1.0 / prev.distance_to(curr)
			var d2 = 1.0 / curr.distance_to(next)
			return ((next - curr) * d2 + (curr - prev) * d1) * 0.5
		TangentType.MONOTONISH:
			var d1 = prev.distance_to(curr)
			var d2 = curr.distance_to(next)
			var dra = min(d1, d2) / (d1 + d2)
			return (next - prev) * ((0.5 * (1.0 - SplineTension)) + (dra * SplineTension))
		_:
			return Vector3.ZERO


func remesh():
	if len(Points) < 2:
		mesh = ArrayMesh.new()
		return

	_vert_list = []
	var vertices: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	var prev_tangent: Vector3 = initial_tangent()

	var total_arc: float = 0.0
	var arc: float = 0.0
	var vert_cols: Array[Color] = []
	var canUseVC: bool = UseVertexColours and VertexColours
	if canUseVC:
		# first, we need total arc length to do uniform vertex colouring
		if UniformUVSampling:
			total_arc = len(Points) - 1.0
		else:
			for n in range(1, len(Points)):
				total_arc += Points[n - 1].distance_to(Points[n])

	for n in range(1, len(Points)):
		var prev: Vector3 = Points[n - 1]
		var curr: Vector3 = Points[n]
		var this_interval: float
		if UniformUVSampling:
			this_interval = 1.0
		else:
			this_interval = prev.distance_to(curr)

		# calculate the tangent at `curr`
		var curr_tangent: Vector3
		if n == len(Points) - 1:
			curr_tangent = final_tangent()
		else:
			var next: Vector3 = Points[n + 1]
			curr_tangent = tangent(prev, curr, next)

		# add vertices along interval
		vertices.append(prev)
		_vert_list.append(prev)
		uvs.append(Vector2(arc / total_arc, 0))
		if canUseVC:
			var col = VertexColours.sample(arc / total_arc)
			vert_cols.append(col)

		for k in range(1, SegCount):
			var t = float(k) / SegCount
			var xt = hermite(prev.x, curr.x, prev_tangent.x, curr_tangent.x, t)
			var yt = hermite(prev.y, curr.y, prev_tangent.y, curr_tangent.y, t)
			var zt = hermite(prev.z, curr.z, prev_tangent.z, curr_tangent.z, t)
			var seg_next = Vector3(xt, yt, zt)

			vertices.append(seg_next)
			vertices.append(seg_next)
			_vert_list.append(seg_next)

			var seg_uv = (arc + this_interval * t) / total_arc
			uvs.append(Vector2(seg_uv, 0))
			uvs.append(Vector2(seg_uv, 0))
			if canUseVC:
				var col = VertexColours.sample(seg_uv)
				vert_cols.append(col)
				vert_cols.append(col)

		vertices.append(curr)
		prev_tangent = curr_tangent

		arc += this_interval
		uvs.append(Vector2(arc / total_arc, 0))
		if canUseVC:
			var col = VertexColours.sample(arc / total_arc)
			vert_cols.append(col)

	_vert_list.append(Points[len(Points) - 1])

	# finally, build the surf from the arrays

	var surf = SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_LINES)

	for k in range(len(vertices)):
		surf.set_uv(uvs[k])
		if canUseVC:
			surf.set_color(vert_cols[k])
		surf.add_vertex(vertices[k])

	surf.index()
	mesh = surf.commit()
	mesh.surface_set_material(0, SplineMat)

	# calculate normals for each vertex
	_normal_list = []
	_normal_list.append(Vector3.FORWARD)
	for k in range(1, len(_vert_list) - 1):
		var a: Vector3 = _vert_list[k - 1]
		var b: Vector3 = _vert_list[k]
		var c: Vector3 = _vert_list[k + 1]
		var d1 = a.direction_to(b)
		var d2 = b.direction_to(c)
		_normal_list.append((d1 - d2).normalized())

	# copy normals to endpoints
	var first_normal = _normal_list[1]
	var last_normal = _normal_list[len(_normal_list) - 1]
	_normal_list[0] = first_normal
	_normal_list.append(last_normal)

	if ShowUniformPoints:
		debug_draw_uniform_points()

	emit_signal("changed")


# Get uniform points along the spline every `spacing` units. `ofs` controls the
# offset or phase from 0 to 1 (in units of spacing, i.e., ofs=0.5 means the
# first point will be (0.5*spacing) units from the start).
# Beware that the arc length is calculated along straight-line elements, and so
# is only an approximation, which improves as SegCount increases.
func get_uniform_points(spacing: float, ofs: float = 0.5) -> Array[Vector3]:
	if len(_vert_list) < 2:
		return []

	var arc: float = 0.0
	var nextPoint: float = clamp(ofs, 0.0, 1.0) * spacing
	var points: Array[Vector3] = []
	for k in range(1, len(_vert_list)):
		var a = _vert_list[k - 1]
		var b = _vert_list[k]
		var segLen = a.distance_to(b)
		while arc + segLen > nextPoint:
			var t = nextPoint - arc
			var dir = a.direction_to(b)
			var newPt: Vector3 = a + dir * t
			points.append(newPt)
			nextPoint += spacing

		arc += segLen

	return points


func get_uniform_normals(spacing: float, ofs: float = 0.5) -> Array[Vector3]:
	if len(_vert_list) < 2:
		return []

	var arc: float = 0.0
	var nextPoint: float = clamp(ofs, 0.0, 1.0) * spacing
	var points: Array[Vector3] = []
	for k in range(1, len(_vert_list)):
		var a = _vert_list[k - 1]
		var b = _vert_list[k]
		var nA: Vector3 = _normal_list[k - 1]
		var nB: Vector3 = _normal_list[k - 2]
		var segLen = a.distance_to(b)
		while arc + segLen > nextPoint:
			var t = (nextPoint - arc) / segLen
			var newNorm: Vector3 = nB.slerp(nA, t)
			points.append(newNorm.normalized())
			nextPoint += spacing

		arc += segLen

	return points


func get_arc_length() -> float:
	if len(_vert_list) < 2:
		return 0.0

	var arc: float = 0.0
	for k in range(1, len(_vert_list)):
		var a = _vert_list[k - 1]
		var b = _vert_list[k]
		arc += a.distance_to(b)
	return arc


func get_spline_vertices() -> Array[Vector3]:
	return _vert_list


func get_spline_normals() -> Array[Vector3]:
	return _normal_list


func debug_draw_uniform_points() -> void:
	var pts = get_uniform_points(UniformPointSpacing, 0.5)

	var surf = SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_POINTS)

	for p in pts:
		surf.add_vertex(p)
	surf.index()
	surf.commit(mesh)
	mesh.surface_set_material(1, _debug_mat)


@export var _debug_mat: Material


func _enter_tree():
	remesh()


func _process(delta):
	processed_once = true
