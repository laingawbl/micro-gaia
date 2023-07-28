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

@export var Tension: float:
	set(p):
		Tension = clamp(p, 0.0, 1.0)
		if processed_once:
			remesh()
	get:
		return Tension

@export var LabelSpacing: float:
	set(p):
		LabelSpacing = clamp(p, 0.05, 1.0)
		if processed_once:
			remesh()
	get:
		return LabelSpacing

@export var Text: String:
	set(p):
		Text = p
		if processed_once:
			relabel()
	get:
		return Text

@export var Mat: Material:
	set = set_mat,
	get = get_mat

@export var Segments: int:
	set(p):
		Segments = clamp(p, 1, 64)
		if processed_once:
			remesh()
	get:
		return Segments

var processed_once: bool = false
var label_points: Array[Vector3] = []
var label_tangents: Array[Vector3] = []
var label_normals: Array[Vector3] = []
var labels: Array[Label3D] = []


func set_mat(p: Material) -> void:
	$RibbonMesh.material_override = p


func get_mat() -> Material:
	return $RibbonMesh.material_override


func relabel():
	# clear old labels
	for l in labels:
		$Labels.remove_child(l)
		l.queue_free.call_deferred()
	labels = []

	if len(Text) == 0:
		return

	var labEx: Label3D = Label3D.new()
	labEx.text = Text
	labEx.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	labEx.pixel_size = 1e-4
	labEx.outline_modulate = Color.DARK_SLATE_GRAY
	labEx.outline_size = 12
	for k in range(len(label_points)):
		var p = label_points[k] + Vector3.BACK * 0.01
		var l = labEx.duplicate()
		var n: Vector3 = label_normals[k]
		var t: Vector3 = label_tangents[k]
		var b = Vector3.BACK

		if n.is_zero_approx():
			n = p.normalized()

		if n.angle_to(Vector3.UP) > PI / 2.0:
			n = -n
		if t.cross(n).z < 0.0:
			n = -n

		l.position = p
		l.basis = Basis(t, n, b).orthonormalized()
		labels.append(l)
		$Labels.add_child(l)


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
			HermiteCubic.TangentType.MONOTONISH,
			false,
			Tension
		)
	)

	# transform points to the cylindrical domain, and copy front to back
	var verts: Array[Vector3] = []
	var back_verts: Array[Vector3] = []
	var depth_ofs = Vector3.BACK * 0.1
	for v in hcBuilder.vert_list:
		var r = 1.0 + v.y
		var p3 = Vector3.UP.rotated(Vector3.FORWARD, v.x * PI) * r

		verts.append(p3)
		back_verts.append(p3 - depth_ofs)

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

	label_points = hcBuilder.get_uniform_points(LabelSpacing)
	label_normals = hcBuilder.get_uniform_normals(LabelSpacing)
	if len(label_points) > 2:
		for k in range(len(label_points)):
			var v = label_points[k]
			var r = 1.0 + v.y
			var p3 = Vector3.UP.rotated(Vector3.FORWARD, v.x * PI) * r
			label_points[k] = p3
			label_normals[k] = label_normals[k].rotated(Vector3.FORWARD, v.x * PI)
		label_tangents = []
		label_tangents.append(label_points[0].direction_to(label_points[1]))
		for k in range(1, len(label_points) - 1):
			label_tangents.append(label_points[k - 1].direction_to(label_points[k + 1]))
		var llp = len(label_points)
		label_tangents.append(label_points[llp - 2].direction_to(label_points[llp - 1]))
		relabel()


func _ready():
	remesh()


func _process(_delta):
	processed_once = true
