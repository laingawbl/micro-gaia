@tool
extends Node3D

@onready var RuleMesh: Node3D = $CoordinateMeshes/RuleMesh
@onready var RuleMeshLabel: Label3D = $CoordinateMeshes/RuleMeshLabel

@export var RibbonMat: BaseMaterial3D
@export var FillRibbonMat: BaseMaterial3D
@export var RibbonGradient: Gradient

var level_mesh_ribbons: Array = []


func _ready():
	var ribbonScene = preload("res://ribbon_in_slice.tscn")
	
	for r in range(SimData.nR):
		var ribbon = ribbonScene.instantiate()
		ribbon.Segments = 4
		ribbon.LabelSpacing = 0.15

		var matcopy: BaseMaterial3D = RibbonMat.duplicate()
		var fillmatcopy: BaseMaterial3D = FillRibbonMat.duplicate()
		
		var t = (SimData.halfLevels[r] - SimData.Pt) / (SimData.Po - SimData.Pt)
		var base = RibbonGradient.sample(1.0 - t)
		var faded = Color((base + Color.WHITE) * 0.5, 0.2)
		matcopy.set_albedo(base)
		fillmatcopy.set_albedo(faded)
		ribbon.Mat = matcopy
		ribbon.FillMat = fillmatcopy

		level_mesh_ribbons.append(ribbon)
		$CoordinateMeshes/LevelMeshes.add_child.call_deferred(ribbon)
	SimData.connect("ic_update", Callable(self, "on_ics_changed"))


func on_ics_changed():
	print("on_ics_changed")
	$Area3D/CollisionShape3D.set_scale(Vector3.ONE * (SimData.lidRadius + 0.01))
	RuleMesh.maxR = SimData.MaxZ
	RuleMesh.scaleR = SimData.VertScale

	# draw level meshes
	for r in range(SimData.nR):
		var data_at_level: Array[Vector2] = []
		for x in range(SimData.nX):
			var xu = float(x) / SimData.nX
			var yu = SimData.ZLevels[x][r] * SimData.VertScale * 1e-3
			data_at_level.append(Vector2(xu, yu))
		level_mesh_ribbons[r].Points = data_at_level
		level_mesh_ribbons[r].Text = String.num(SimData.levels[r+1] * 1e-3, 1) + "kPa"


func _on_area_3d_input_event(
	camera: Camera3D, event: InputEvent, input_position: Vector3, _normal, _shape_idx
):
	RuleMeshLabel.position = input_position
	var inputRad = input_position.length()
	var inputZ = (inputRad - 1.0) / SimData.VertScale
	if inputZ < -1.0 or inputZ > SimData.MaxZ + 1.0:
		RuleMeshLabel.visible = false
	else:
		RuleMeshLabel.visible = true
		RuleMeshLabel.text = (
			String.num(clamp(inputZ, 0.0, SimData.MaxZ), 1).pad_decimals(1) + " km"
		)

	# find out which vertical rule level is highlighted
	var rowLevels = RuleMesh.rowLevels
	var foundLevel = -1
	for k in range(len(rowLevels)):
		if inputRad < rowLevels[k]:
			foundLevel = k - 1
			break
	RuleMesh.hlRow = foundLevel


func _on_area_3d_mouse_exited():
	RuleMeshLabel.visible = false
