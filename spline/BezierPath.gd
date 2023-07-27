@tool
extends MeshInstance3D

var processed_once: bool = false

@export var SegCount: int = 4:
	set = _set_SegCount,
	get = _get_SegCount
@export var Points: Array[Vector3]:
	set = _set_Points,
	get = _get_Points
@export var StartHandle: Vector3 = Vector3.ZERO:
	set = _set_StartHandle,
	get = _get_StartHandle
@export var EndHandle: Vector3 = Vector3.ZERO:
	set = _set_EndHandle,
	get = _get_EndHandle
@export var TangentMatching: float = 1.0:
	set = _set_TangentMatching,
	get = _get_TangentMatching
@export var LabelSpacing: float = 1.0:
	set = _set_LabelSpacing,
	get = _get_LabelSpacing
@export var LabelText: String = "foo":
	set = _set_LabelText,
	get = _get_LabelText

@onready var LabelExemplar: Label3D = $Label3D
@export var mat: Material

var labels: Array[Label3D] = []


func _set_SegCount(p) -> void:
	SegCount = max(1, p)
	if processed_once:
		remesh()


func _get_SegCount() -> int:
	return SegCount


func _set_TangentMatching(p) -> void:
	TangentMatching = max(0.0, p)
	if processed_once:
		remesh()


func _get_TangentMatching() -> float:
	return TangentMatching


func _set_LabelSpacing(p) -> void:
	LabelSpacing = max(0.0, p)
	if processed_once:
		remesh()


func _get_LabelSpacing() -> float:
	return LabelSpacing


func _set_LabelText(p) -> void:
	LabelText = p
	if processed_once:
		set_label_text()


func _get_LabelText() -> String:
	return LabelText


func _set_Points(p) -> void:
	Points = p
	if processed_once:
		remesh()


func _get_Points() -> Array[Vector3]:
	return Points


func _set_StartHandle(p) -> void:
	StartHandle = p
	if processed_once:
		remesh()


func _get_StartHandle() -> Vector3:
	return StartHandle


func _set_EndHandle(p) -> void:
	EndHandle = p
	if processed_once:
		remesh()


func _get_EndHandle() -> Vector3:
	return EndHandle


func _process(_delta):
	processed_once = true


func _enter_tree():
	remesh()


func insert_label(p: Vector3):
	var lbl = LabelExemplar.duplicate()
	lbl.text = LabelText
	lbl.visible = true
	lbl.position = p
	labels.append(lbl)
	add_child.call_deferred(lbl)


func set_label_text():
	for l in labels:
		l.text = LabelText


func remesh():
	for n in labels:
		remove_child(n)
		n.queue_free()
	labels = []

	if len(Points) < 2:
		return

	var t = 0
	var next = LabelSpacing * 0.5
	var vertices: Array = []
	var last_tangent: Vector3
	if StartHandle.is_zero_approx():
		last_tangent = Points[0] - Points[1]
	else:
		last_tangent = StartHandle

	for i in range(1, len(Points)):
		var a: Vector3 = Points[i - 1]
		var b: Vector3 = Points[i]

		var next_tangent: Vector3
		if i == len(Points) - 1:
			if EndHandle.is_zero_approx():
				next_tangent = (Points[i - 1] - Points[i])
			else:
				next_tangent = EndHandle
		else:
			next_tangent = TangentMatching * (Points[i - 1] - Points[i + 1]) * 0.25

		vertices.append(a)
		var last_pt = a
		for k in range(1, SegCount):
			var interp: Vector3 = (
				a . bezier_interpolate(a - last_tangent, b + next_tangent, b, float(k) / SegCount)
			)
			vertices.append(interp)
			vertices.append(interp)
			t += last_pt.distance_to(interp)
			if t >= next:
				insert_label(interp)
				next += LabelSpacing
			last_pt = interp
		t += last_pt.distance_to(b)
		if t >= next:
			insert_label(b)
			next += LabelSpacing
		vertices.append(b)

		last_tangent = next_tangent

	mesh = ArrayMesh.new()
	var surf = SurfaceTool.new()
	surf.begin(Mesh.PRIMITIVE_LINES)
	for v in vertices:
		surf.add_vertex(v)
	surf.index()
	surf.commit(mesh)
	mesh.surface_set_material(0, mat)
