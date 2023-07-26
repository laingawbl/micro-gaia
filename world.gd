@tool
extends Node3D


func _ready():
	SimData.connect("ic_update", Callable(self, "on_ics_changed"))


func on_ics_changed():
	print(SimData.lidRadius)
	$Area3D/CollisionShape3D.set_scale(Vector3.ONE * (SimData.lidRadius + 0.01))
	$RuleMesh.maxR = SimData.MaxZ
	$RuleMesh.scaleR = SimData.VertScale


func _on_area_3d_input_event(
	_camera, event: InputEvent, input_position: Vector3, _normal, _shape_idx
):
	$RuleMeshLabel.position = input_position
	var input_rad = (input_position.length() - 1.0) / SimData.VertScale
	if input_rad < -1.0 or input_rad > SimData.MaxZ + 1.0:
		$RuleMeshLabel.visible = false
	else:
		$RuleMeshLabel.visible = true
		$RuleMeshLabel.text = (
			String.num(clamp(input_rad, 0.0, SimData.MaxZ), 1).pad_decimals(1) + " km"
		)


func _on_area_3d_mouse_exited():
	$RuleMeshLabel.visible = false
