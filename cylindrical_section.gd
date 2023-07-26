extends Object

var vertices: Array = []


func _split_vertices(split: float) -> void:
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


func build_cylindrical_section(sweep: float, depth: float, height: float, 
	base_radius: float = 1.0, angle_limit: float = 0.1,
	sides: bool = true, split: float = 0.0
) -> ArrayMesh:
	vertices.clear()

	var seg_count: int = int(ceil(sweep / angle_limit))
	var sweep_incr = sweep / seg_count

	var lhs_vert = Vector3.UP
	var rhs_vert = Vector3.UP.rotated(Vector3.FORWARD, sweep)
	var depth_ofs = Vector3.FORWARD * depth
	var top_radius = base_radius + height

	# forward edges
	vertices.append(lhs_vert * base_radius)

	for i in range(1, seg_count):
		var vert = Vector3.UP.rotated(Vector3.FORWARD, i * sweep_incr) * base_radius
		vertices.append(vert)
		vertices.append(vert)

	vertices.append(rhs_vert * base_radius)

	vertices.append(lhs_vert * top_radius)

	for i in range(1, seg_count):
		var vert = Vector3.UP.rotated(Vector3.FORWARD, i * sweep_incr) * top_radius
		vertices.append(vert)
		vertices.append(vert)

	vertices.append(rhs_vert * top_radius)

	if depth != 0:
		# forward->back connectors
		vertices.append(lhs_vert * base_radius)
		vertices.append(lhs_vert * base_radius + depth_ofs)

		vertices.append(rhs_vert * base_radius)
		vertices.append(rhs_vert * base_radius + depth_ofs)

		vertices.append(lhs_vert * top_radius)
		vertices.append(lhs_vert * top_radius + depth_ofs)

		vertices.append(rhs_vert * top_radius)
		vertices.append(rhs_vert * top_radius + depth_ofs)

		# back edges

		vertices.append(lhs_vert * base_radius + depth_ofs)

		for i in range(1, seg_count):
			var vert = Vector3.UP.rotated(Vector3.FORWARD, i * sweep_incr) * base_radius + depth_ofs
			vertices.append(vert)
			vertices.append(vert)

		vertices.append(rhs_vert * base_radius + depth_ofs)

		vertices.append(lhs_vert * top_radius + depth_ofs)

		for i in range(1, seg_count):
			var vert = Vector3.UP.rotated(Vector3.FORWARD, i * sweep_incr) * top_radius + depth_ofs
			vertices.append(vert)
			vertices.append(vert)

		vertices.append(rhs_vert * top_radius + depth_ofs)

	if sides:
		vertices.append(lhs_vert * base_radius)
		vertices.append(lhs_vert * top_radius)

		vertices.append(rhs_vert * base_radius)
		vertices.append(rhs_vert * top_radius)

		if depth != 0:
			vertices.append(lhs_vert * base_radius + depth_ofs)
			vertices.append(lhs_vert * top_radius + depth_ofs)

			vertices.append(rhs_vert * base_radius + depth_ofs)
			vertices.append(rhs_vert * top_radius + depth_ofs)

	_split_vertices(split)

	var _mesh = ArrayMesh.new()
	var _surf = SurfaceTool.new()

	_surf.begin(Mesh.PRIMITIVE_LINES)
	for v in vertices:
		_surf.add_vertex(v)
	_surf.index()
	_surf.commit(_mesh)
	return _mesh
