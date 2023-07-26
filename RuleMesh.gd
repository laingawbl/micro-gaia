@tool
extends Node3D

var processed_once: bool = false

const split = 0.1
const depth = 0.1
const angleLimit = 0.035

@export var nX: int = 16:
	set = _set_nX,
	get = _get_nX
@export var strideR: int = 4:
	set = _set_strideR,
	get = _get_strideR
@export var maxR: float = 20:
	set = _set_maxR,
	get = _get_maxR
@export var scaleR: float = 1e-5:
	set = _set_scaleR,
	get = _get_scaleR

@export var mat: Material
@export var hlMat: Material

@export var hlRow: int = -1:
	set = _set_hlRow,
	get = _get_hlRow

var rows: Array = []
var rowLevels: Array = []


func _set_nX(p) -> void:
	nX = max(0, p)
	if processed_once:
		remesh()


func _get_nX() -> int:
	return nX


func _set_strideR(p) -> void:
	strideR = max(0, p)
	if processed_once:
		remesh()


func _get_strideR() -> int:
	return strideR


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


func _set_hlRow(p) -> void:
	if hlRow != -1 and hlRow < len(rows):
		rows[hlRow].multimesh.mesh.surface_set_material(0, mat)
	if p >= 0 and p < len(rows):
		hlRow = p
		rows[hlRow].multimesh.mesh.surface_set_material(0, hlMat)
	else:
		hlRow = -1


func _get_hlRow() -> int:
	return hlRow


func remesh() -> void:
	var nR = ceil(maxR / strideR)
	var worldSpaceExtent = maxR * scaleR
	var topOfRegularMeshes = (nR - 1) * strideR * scaleR
	var rowHeight = float(topOfRegularMeshes) / float(nR - 1)
	var topRowHt = worldSpaceExtent - topOfRegularMeshes

	var omitTopRow: bool = topRowHt < 1e-3
	if omitTopRow:
		nR -= 1

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

	rowLevels = []

	# Do the regular meshes

	var sweep = PI / nX
	var CylMesher = preload("res://cylindrical_section.gd").new()

	for k in range(nR if omitTopRow else nR - 1):
		var row: MultiMeshInstance3D = rows[k]
		var mm = row.multimesh
		var baseHeight = 1.0 + rowHeight * k

		var cell_mesh = (
			CylMesher
			. build_cylindrical_section(
				sweep, depth, rowHeight, baseHeight, angleLimit, true, split
			)
		)

		mm.mesh = cell_mesh
		mm.mesh.surface_set_material(0, mat)
		mm.instance_count = nX
		for i in range(nX):
			var rot = Basis(Vector3.FORWARD, i * PI / nX)
			var tf = Transform3D(rot, Vector3.ZERO)
			mm.set_instance_transform(i, tf)

		rowLevels.append(baseHeight)

	# Do the last, possibly truncated mesh
	if !omitTopRow:
		var top_row: MultiMeshInstance3D = rows[nR - 1]
		var top_mm = top_row.multimesh

		var cell_mesh = (
			CylMesher
			. build_cylindrical_section(
				sweep, depth, topRowHt, 1.0 + topOfRegularMeshes, angleLimit, true, split
			)
		)

		top_mm.mesh = cell_mesh
		top_mm.mesh.surface_set_material(0, mat)
		top_mm.instance_count = nX
		for i in range(nX):
			var rot = Basis(Vector3.FORWARD, i * PI / nX)
			var tf = Transform3D(rot, Vector3.ZERO)
			top_mm.set_instance_transform(i, tf)

		rowLevels.append(1.0 + topOfRegularMeshes)
		rowLevels.append(1.0 + worldSpaceExtent)


func _enter_tree():
	remesh()


func _process(_delta):
	processed_once = true
