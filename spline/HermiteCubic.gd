class_name HermiteCubic extends Object

var vert_list: Array[Vector3] = []
var normal_list: Array[Vector3] = []
var uv_list: Array[Vector2] = []
var tangent_list: Array[Vector3] = []
var segment_lengths: Array[float] = []

enum TangentType { CATMULL_ROM, CARDINAL, FINITE_DIFFERENCE, MONOTONISH }

var _weights: Array[float] = []
var _weight_squares: Array[float] = []
var _weight_cubes: Array[float] = []


func indexed_hermite(p1: float, p2: float, v1: float, v2: float, s: int) -> float:
	var t = _weights[s]
	var t2 = _weight_squares[s]
	var t3 = _weight_cubes[s]

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


func make_tangents(
	Points: Array[Vector3], SplineTangentType: TangentType, SplineTension: float
) -> void:
	var point_count = len(Points)
	match SplineTangentType:
		TangentType.CATMULL_ROM:
			for k in range(1, point_count - 1):
				var prev: Vector3 = Points[k - 1]
				var next: Vector3 = Points[k + 1]
				tangent_list[k] = (next - prev) * 0.5

		TangentType.CARDINAL:
			for k in range(1, point_count - 1):
				var prev: Vector3 = Points[k - 1]
				var next: Vector3 = Points[k + 1]
				var d = segment_lengths[k - 1] + segment_lengths[k]
				tangent_list[k] = (1.0 - SplineTension) * (next - prev) * d

		TangentType.FINITE_DIFFERENCE:
			var prev: Vector3 = Points[0]
			var curr: Vector3 = Points[1]
			for k in range(1, point_count - 1):
				var next: Vector3 = Points[k + 1]
				var d1 = segment_lengths[k - 1]
				var d2 = segment_lengths[k]
				tangent_list[k] = ((next - curr) / d2 + (curr - prev) / d1) * 0.5
				prev = curr
				curr = next

		TangentType.MONOTONISH:
			for k in range(1, point_count - 1):
				var prev: Vector3 = Points[k - 1]
				var next: Vector3 = Points[k + 1]
				var d1 = segment_lengths[k - 1]
				var d2 = segment_lengths[k]
				var d_ratio = min(d1, d2) / (d1 + d2)
				var w = 0.5 * (1.0 - SplineTension) + d_ratio * SplineTension
				tangent_list[k] = (next - prev) * w
		_:
			pass


func build_hermite_spline(
	Points: Array[Vector3],
	SegCount: int = 8,
	StartHandle: Vector3 = Vector3.ZERO,
	EndHandle: Vector3 = Vector3.ZERO,
	SplineTangentType: TangentType = TangentType.CATMULL_ROM,
	UniformUVSampling: bool = false,
	SplineTension: float = 0.0
):
	var t_start = Time.get_ticks_usec()
	if len(Points) < 2:
		return

	# first, precompute weights and their squares and cubes.
	_weights.resize(SegCount)
	_weight_squares.resize(SegCount)
	_weight_cubes.resize(SegCount)
	for seg_number in range(SegCount):
		var t = float(seg_number) / SegCount
		_weights[seg_number] = t
		_weight_squares[seg_number] = t * t
		_weight_cubes[seg_number] = t * t * t

	# resize all arrays to expected number of vertices.
	var point_count = len(Points)
	var vertex_count = (point_count - 1) * SegCount + 1
	vert_list.resize(vertex_count)
	uv_list.resize(vertex_count)
	normal_list.resize(vertex_count)

	tangent_list.resize(point_count)
	segment_lengths.resize(point_count - 1)

	# set up segment lengths, and if not using point-uniform UV, total arc.
	var total_arc: float = 0.0
	for k in range(1, point_count):
		var this_seg_length = Points[k - 1].distance_to(Points[k])
		segment_lengths[k - 1] = this_seg_length
		if not UniformUVSampling:
			total_arc += this_seg_length

	if UniformUVSampling:
		total_arc = float(point_count) - 1.0

	# set up tangents, including end handles.
	if StartHandle != Vector3.ZERO:
		tangent_list[0] = StartHandle
	else:
		tangent_list[0] = Points[0].direction_to(Points[1])

	if EndHandle != Vector3.ZERO:
		tangent_list[point_count - 1] = EndHandle
	else:
		tangent_list[point_count - 1] = (
			Points[point_count - 2] . direction_to(Points[point_count - 1])
		)

	make_tangents(Points, SplineTangentType, SplineTension)

	# now we are ready to do the actual interpolation
	var arc: float = 0.0
	var prev: Vector3 = Points[0]
	var prev_tangent: Vector3 = tangent_list[0]

	for k in range(1, point_count):
		var base: int = (k - 1) * SegCount
		var interval: float = segment_lengths[k - 1]

		var curr: Vector3 = Points[k]
		var curr_tangent: Vector3 = tangent_list[k]

		# add vertices along the interval from `prev` to `curr`
		vert_list[base] = prev
		uv_list[base] = Vector2(arc / total_arc, 0)

		for s in range(1, SegCount):
			var xt = indexed_hermite(prev.x, curr.x, prev_tangent.x, curr_tangent.x, s)
			var yt = indexed_hermite(prev.y, curr.y, prev_tangent.y, curr_tangent.y, s)
			var zt = indexed_hermite(prev.z, curr.z, prev_tangent.z, curr_tangent.z, s)
			var seg_uv = (arc + interval * _weights[s]) / total_arc
			vert_list[base + s] = Vector3(xt, yt, zt)
			uv_list[base + s] = Vector2(seg_uv, 0)

		prev_tangent = curr_tangent
		prev = curr
		arc += interval

	vert_list[vertex_count - 1] = Points[point_count - 1]
	uv_list[vertex_count - 1] = Vector2(1.0, 0.0)

	# calculate normals for each vertex
	for k in range(1, vertex_count - 1):
		var a: Vector3 = vert_list[k - 1]
		var b: Vector3 = vert_list[k]
		var c: Vector3 = vert_list[k + 1]
		var d1 = a.direction_to(b)
		var d2 = b.direction_to(c)
		normal_list[k] = d1.direction_to(d2)

	# copy normals to endpoints
	if len(normal_list) > 2:
		normal_list[0] = normal_list[1]
		normal_list[len(normal_list) - 1] = normal_list[len(normal_list) - 2]
	else:
		normal_list[0] = Vector3.UP
		normal_list[1] = Vector3.UP

	var t_end = Time.get_ticks_usec()
	var dur = (t_end - t_start) * 1e-3
	print(
		(
			"Hermite: "
			+ str(len(Points))
			+ " points took "
			+ String.num(dur, 2)
			+ " ms\t"
			+ str(len(vert_list))
			+ " verts, "
			+ String.num(dur / len(vert_list) * 1e3, 2)
			+ " us / vert"
		)
	)


func get_uniform_points(spacing: float, ofs: float = 0.5) -> Array[Vector3]:
	if len(vert_list) < 2:
		return []

	var arc: float = 0.0
	var nextPoint: float = clamp(ofs, 0.0, 1.0) * spacing
	var points: Array[Vector3] = []
	for k in range(1, len(vert_list)):
		var a = vert_list[k - 1]
		var b = vert_list[k]
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
	if len(vert_list) < 2:
		return []

	var arc: float = 0.0
	var nextPoint: float = clamp(ofs, 0.0, 1.0) * spacing
	var points: Array[Vector3] = []
	for k in range(1, len(vert_list)):
		var a = vert_list[k - 1]
		var b = vert_list[k]
		var nA: Vector3 = normal_list[k - 1]
		var nB: Vector3 = normal_list[k - 2]
		var segLen = a.distance_to(b)
		while arc + segLen > nextPoint:
			var t = (nextPoint - arc) / segLen
			var newNorm: Vector3 = nB.slerp(nA, t)
			points.append(newNorm.normalized())
			nextPoint += spacing

		arc += segLen

	return points
