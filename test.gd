@tool
extends Node3D

@export var segments: int:
	set = _set_segments,
	get = _get_segments

var processed_once: bool = false


func _get_segments() -> int:
	return segments


func _set_segments(p) -> void:
	segments = clamp(p, 0, 2048)
	if processed_once:
		remesh()


func remesh():
	$CellExtent.split = 0
	$CellExtent.sweep = PI / segments
	$CellExtent.remesh()
	var cell_mesh: ArrayMesh = $CellExtent.mesh
	var err = ResourceSaver.save(cell_mesh, "res://cell.mesh")
	if err != OK:
		print("Error saving cell mesh: ", error_string(err))

	var mm: MultiMesh = $CellRow.multimesh
	mm.mesh = cell_mesh
	mm.instance_count = segments
	for i in range(segments):
		var rot = Basis(Vector3.FORWARD, i * PI / segments)
		var tf = Transform3D(rot, Vector3.ZERO)
		mm.set_instance_transform(i, tf)


func _ready():
	remesh()


func _process(_delta) -> void:
	processed_once = true
