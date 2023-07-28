@tool
extends Node3D

# X is normalised [0 .. 1]
# Y is in km

@export var Points: Array[Vector2]:
	set(p):
		Points = p
		if processed_once:
			remesh()
	get:
		return Points

@export var IsLoop: bool:
	set(p):
		IsLoop = p
		if processed_once:
			remesh()
	get:
		return IsLoop

@export var Segments: int:
	set(p):
		Segments = clamp(p, 1, 64)
		if processed_once:
			remesh()
	get:
		return Segments

var processed_once: bool = false


func remesh():
	if len(Points) < 2:
		return

	var knots: Array[Vector3] = []
	for p2 in Points:
		var p3 = Vector3(p2.x, p2.y, 0.0)
		knots.append(p3)

	var hcBuilder = HermiteCubic.new()
	(
		hcBuilder
		. build_hermite_spline(
			knots,
			Segments,
			Vector3.RIGHT * 0.01,
			Vector3.RIGHT * 0.01,
			HermiteCubic.TangentType.CATMULL_ROM,
			false,
			0.0
		)
	)

	# transform points to the cylindrical domain, and copy front to back
	var verts: Array[Vector3] = []
	var back_verts: Array[Vector3] = []
	var depth_ofs = Vector3.BACK * 0.1
	for v in hcBuilder.vert_list:
		var r = 1.0 + (v.y * 1e-2)
		var p3 = Vector3.UP.rotated(Vector3.BACK, v.x * PI) * r

		verts.append(p3)
		back_verts.append(p3 + depth_ofs)

	back_verts.reverse()
	verts.append_array(back_verts)
	verts.append(verts[0])
	# setup line strip
	var surf = SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_LINE_STRIP)
	for v in verts:
		surf.add_vertex(v)
	surf.index()
	$RibbonMesh.mesh = surf.commit()


func _ready():
	remesh()


func _process(_delta):
	processed_once = true
