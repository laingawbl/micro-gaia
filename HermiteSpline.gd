@tool
extends MeshInstance3D

var processed_once: bool = false

enum TangentType { CATMULL_ROM, CARDINAL, FINITE_DIFFERENCE }

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
@export var UseVertexColours: bool = false:
	set = _set_UseVertexColours,
	get = _get_UseVertexColours
@export var UniformUVSampling: bool = false:
	set = _set_UniformUVSampling,
	get = _get_UniformUVSampling
@export var VertexColours: Gradient:
	set = _set_VertexColours,
	get = _get_VertexColours


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


func hermite(p1: float, p2: float, v1: float, v2: float, t: float) -> float:
	var t2 = t * t
	var t3 = t * t * t
	var a = 1 - 3 * t2 + 2 * t3
	var b = t2 * (3 - 2 * t)
	var c = t * (t - 1) * (t - 1)
	var d = t2 * (t - 1)
	return a * p1 + b * p2 + c * v1 + d * v2


func initial_tangent() -> Vector3:
	return Points[0].direction_to(Points[1])


func final_tangent() -> Vector3:
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
		_:
			return Vector3.ZERO


func remesh():
	if len(Points) < 2:
		mesh = ArrayMesh.new()
		return

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


func _enter_tree():
	remesh()


func _process(delta):
	processed_once = true
