@tool
extends MeshInstance3D

var processed_once: bool = false

enum TangentType {
	CATMULL_ROM,
	CARDINAL,
	FINITE_DIFFERENCE
}

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
	var prev_tangent: Vector3 = initial_tangent()

	for n in range(1, len(Points)):
		var prev: Vector3 = Points[n - 1]
		var curr: Vector3 = Points[n]

		# calculate the tangent at `curr`
		var curr_tangent: Vector3
		if n == len(Points) - 1:
			curr_tangent = final_tangent()
		else:
			var next: Vector3 = Points[n + 1]
			curr_tangent = tangent(prev, curr, next)

		vertices.append(prev)
		for k in range(1, SegCount):
			var t = float(k) / SegCount
			var xt = hermite(prev.x, curr.x, prev_tangent.x, curr_tangent.x, t)
			var yt = hermite(prev.y, curr.y, prev_tangent.y, curr_tangent.y, t)
			var zt = hermite(prev.z, curr.z, prev_tangent.z, curr_tangent.z, t)
			var vert = Vector3(xt, yt, zt)

			vertices.append(vert)
			vertices.append(vert)

		vertices.append(curr)
		prev_tangent = curr_tangent

	var surf = SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_LINES)
	for v in vertices:
		surf.add_vertex(v)
	surf.index()
	mesh = surf.commit()
	mesh.surface_set_material(0, SplineMat)


func _enter_tree():
	remesh()


func _process(delta):
	processed_once = true
