@tool
extends Node3D

@onready var RuleMesh: Node3D = $CoordinateMeshes/RuleMesh
@onready var RuleMeshLabel: Label3D = $CoordinateMeshes/RuleMeshLabel


func _ready():
	SimData.connect("ic_update", Callable(self, "on_ics_changed"))


func on_ics_changed():
	$Area3D/CollisionShape3D.set_scale(Vector3.ONE * (SimData.lidRadius + 0.01))
	RuleMesh.maxR = SimData.MaxZ
	RuleMesh.scaleR = SimData.VertScale


func _on_area_3d_input_event(
	_camera, event: InputEvent, input_position: Vector3, _normal, _shape_idx
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

	var rowLevels = RuleMesh.rowLevels
	var foundLevel = -1
	for k in range(len(rowLevels)):
		if inputRad < rowLevels[k]:
			foundLevel = k - 1
			break
	RuleMesh.hlRow = foundLevel


func _on_area_3d_mouse_exited():
	RuleMeshLabel.visible = false
