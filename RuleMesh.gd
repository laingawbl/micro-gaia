@tool
extends Node3D

var processed_once: bool = false

const split = 0.1
const depth = 0.1
const angleLimit = 0.035

@export var nX: int = 16: set = _set_nX, get = _get_nX
@export var nR: int = 16: set = _set_nR, get = _get_nR
@export var maxR: float = 20: set = _set_maxR, get = _get_maxR
@export var scaleR: float = 1e-5: set = _set_scaleR, get = _get_scaleR

@export var mat: Material

var rows: Array = []

func _set_nX(p) -> void:
	nX = max(0, p)
	if processed_once:
		remesh()
		
func _get_nX() -> int:
	return nX
	
func _set_nR(p) -> void:
	nR = max(0, p)
	if processed_once:
		remesh()
		
func _get_nR() -> int:
	return nR
	
func _set_maxR(p) -> void:
	maxR = max(0.0, p)
	if processed_once:
		remesh()
		
func _get_maxR() -> float:
	return maxR
	
func _set_scaleR(p) -> void:
	scaleR = max(0.0, p)
	if processed_once:
		remesh()
		
func _get_scaleR() -> float:
	return scaleR

func remesh() -> void:
	if get_child_count() != nR:
		# one MultiMeshInstance3D per vertical "row".
		for n in get_children():
			remove_child(n)
			n.queue_free()
		rows = []
		for k in range(nR):
			var row = MultiMeshInstance3D.new()
			var mm = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			row.multimesh = mm
			rows.append(row)
			add_child.call_deferred(row)
	
	var sweep = PI / nX
	var worldSpaceExtent = maxR * scaleR
	var rowHeight = float(worldSpaceExtent) / float(nR)
	var CylMesher = preload("res://cylindrical_section.gd").new()
	
	for k in range(nR):
		var row: MultiMeshInstance3D = rows[k]
		var mm = row.multimesh
		
		var baseHeight = 1.0 + rowHeight * k
		var cell_mesh = CylMesher.build_cylindrical_section(sweep, depth, rowHeight, baseHeight, angleLimit, true, split)

		mm.mesh = cell_mesh
		mm.mesh.surface_set_material(0, mat)
		mm.instance_count = nX
		for i in range(nX):
			var rot = Basis(Vector3.FORWARD, i * PI / nX)
			var tf = Transform3D(rot, Vector3.ZERO)
			mm.set_instance_transform(i, tf)

func _ready():
	remesh()


func _process(_delta):
	processed_once = true
