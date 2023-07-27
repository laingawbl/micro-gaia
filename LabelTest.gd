@tool
extends Node3D

var processed_once = false
var labels = []

@export var spacing: float = 1.0:
	set(p):
		spacing = max(0.1, p)
		if processed_once:
			redraw()
	get:
		return spacing


func redraw():
	for n in labels:
		remove_child.call_deferred(n)
		n.queue_free()
	labels = []
	var pts = $HermiteSpline.get_uniform_points(spacing, 0.5)
	var norms = $HermiteSpline.get_uniform_normals(spacing, 0.5)

	for k in range(len(pts)):
		var p: Vector3 = pts[k]
		var n: Vector3 = norms[k]
		if n.angle_to(Vector3.UP) > PI / 2.0:
			n = -n
		var lbl: Label3D = $Label3D.duplicate()
		lbl.position = p
		lbl.visible = true
		lbl.quaternion = Quaternion(Vector3.UP, n)
		labels.append(lbl)
		add_child.call_deferred(lbl)


# Called when the node enters the scene tree for the first time.
func _ready():
	redraw()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	processed_once = true


func _on_hermite_spline_changed():
	if processed_once:
		redraw()
