class_name HermiteCubic extends Object

var vert_list: Array[Vector3] = []
var normal_list: Array[Vector3] = []
var uv_list: Array[Vector3] = []
var line_strip: Array[Vector3] = []

enum TangentType { CATMULL_ROM, CARDINAL, FINITE_DIFFERENCE }


func hermite(p1: float, p2: float, v1: float, v2: float, t: float) -> float:
	var t2 = t * t
	var t3 = t * t * t
	var a = 1 - 3 * t2 + 2 * t3
	var b = t2 * (3 - 2 * t)
	var c = t * (t - 1) * (t - 1)
	var d = t2 * (t - 1)
	return a * p1 + b * p2 + c * v1 + d * v2


func tangent(
	prev: Vector3,
	curr: Vector3,
	next: Vector3,
	SplineTangentType: TangentType,
	SplineTension: float = 0.0
) -> Vector3:
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


func build_hermite_spline(
	Points: Array[Vector3],
	SegCount: int = 8,
	StartHandle: Vector3 = Vector3.ZERO,
	EndHandle: Vector3 = Vector3.ZERO,
	SplineTangentType: TangentType = TangentType.CATMULL_ROM,
	UniformUVSampling: bool = false,
	SplineTension: float = 0.0
):
	if len(Points) < 2:
		return

	vert_list = []
	var vertices: Array[Vector3] = []
	var uvs: Array[Vector2] = []

	var prev_tangent: Vector3
	if StartHandle != Vector3.ZERO:
		prev_tangent = StartHandle
	else:
		prev_tangent = Points[0].direction_to(Points[1])

	var total_arc: float = 0.0
	var arc: float = 0.0
	var vert_cols: Array[Color] = []

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
			if EndHandle != Vector3.ZERO:
				curr_tangent = EndHandle
			else:
				var lp = len(Points)
				curr_tangent = Points[lp - 2].direction_to(Points[lp - 1])
		else:
			var next: Vector3 = Points[n + 1]
			curr_tangent = tangent(prev, curr, next, SplineTangentType, SplineTension)

		# add vertices along interval
		vert_list.append(prev)
		uvs.append(Vector2(arc / total_arc, 0))

		for k in range(1, SegCount):
			var t = float(k) / SegCount
			var xt = hermite(prev.x, curr.x, prev_tangent.x, curr_tangent.x, t)
			var yt = hermite(prev.y, curr.y, prev_tangent.y, curr_tangent.y, t)
			var zt = hermite(prev.z, curr.z, prev_tangent.z, curr_tangent.z, t)
			var seg_next = Vector3(xt, yt, zt)
			vert_list.append(seg_next)

			var seg_uv = (arc + this_interval * t) / total_arc
			uvs.append(Vector2(seg_uv, 0))

		vertices.append(curr)
		prev_tangent = curr_tangent

		arc += this_interval

	vert_list.append(Points[len(Points) - 1])
	uvs.append(Vector2(1.0, 0.0))

	# calculate normals for each vertex
	normal_list = []
	normal_list.append(Vector3.FORWARD)
	for k in range(1, len(vert_list) - 1):
		var a: Vector3 = vert_list[k - 1]
		var b: Vector3 = vert_list[k]
		var c: Vector3 = vert_list[k + 1]
		var d1 = a.direction_to(b)
		var d2 = b.direction_to(c)
		normal_list.append((d1 - d2).normalized())

	# copy normals to endpoints
	if len(normal_list) > 1:
		var first_normal = normal_list[1]
		var last_normal = normal_list[len(normal_list) - 1]
		normal_list[0] = first_normal
		normal_list.append(last_normal)

	else:
		normal_list[0] = Vector3.BACK
		normal_list.append(Vector3.BACK)
