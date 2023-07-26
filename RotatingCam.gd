extends Camera3D

var panning: bool = false
var fastPanning: bool = false
var clicking: bool = false

@onready var vp: Viewport = get_viewport()
@onready var vp_size: Vector2 = get_viewport().size

const panDelta = 0.005
const fastPanDelta = 0.01


func _ready():
	vp.connect("size_changed", func(): vp_size = vp.size)


func _unhandled_input(event):
	var delta: Vector2 = Vector2.ZERO
	var motion = false
	if event is InputEventKey:
		match event.keycode:
			KEY_CTRL:
				panning = event.pressed
			KEY_SHIFT:
				fastPanning = event.pressed
			KEY_LEFT:
				if event.pressed:
					delta.x = -(fastPanDelta if fastPanning else panDelta)
					motion = true
			KEY_RIGHT:
				if event.pressed:
					delta.x = (fastPanDelta if fastPanning else panDelta)
					motion = true
			KEY_UP:
				if event.pressed:
					delta.y = -(fastPanDelta if fastPanning else panDelta)
					motion = true
			KEY_DOWN:
				if event.pressed:
					delta.y = (fastPanDelta if fastPanning else panDelta)
					motion = true

	if event is InputEventMouseButton:
		# This is not great at large angles. But works for now
		var rel_mouse_ofs = get_window().get_mouse_position() / vp_size - Vector2(0.5, 0.0)
		var mouse_vert = rel_mouse_ofs.length() - 0.5
		var mouse_ang = rel_mouse_ofs.angle() - PI / 2

		match event.button_index:
			MOUSE_BUTTON_LEFT:
				clicking = event.pressed
			MOUSE_BUTTON_WHEEL_UP:
				position.z = clamp(position.z - 0.01, 0.1, 1.0)
				if position.z > 0.11:
					delta.y += mouse_vert * panDelta * 4
					delta.x -= mouse_ang * panDelta * 2
				motion = true
			MOUSE_BUTTON_WHEEL_DOWN:
				position.z = clamp(position.z + 0.01, 0.1, 1.0)
				if position.z < 0.99:
					delta.y -= mouse_vert * panDelta * 4
					delta.x += mouse_ang * panDelta * 2
				motion = true

	if event is InputEventMouseMotion and panning and clicking:
		delta = -event.relative / vp_size
		motion = true

	#clamping
	if motion:
		position = position.rotated(Vector3.FORWARD, delta.x)

		var pos_xy: Vector2 = Vector2(position.x, position.y)
		pos_xy *= (1.0 - delta.y)
		var minRadius = 1.0 - 0.5 * position.z
		var rad = pos_xy.length()
		if rad < minRadius:
			pos_xy *= minRadius / rad
		elif rad > SimData.lidRadius:
			pos_xy *= SimData.lidRadius / rad
		position.x = pos_xy.x
		position.y = pos_xy.y

		if atan2(pos_xy.y, pos_xy.x) > PI / 2:
			position = Vector3.UP * pos_xy.length() + Vector3.BACK * position.z
		elif atan2(pos_xy.y, pos_xy.x) < -PI / 2:
			position = Vector3.DOWN * pos_xy.length() + Vector3.BACK * position.z


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var posFlat = position
	posFlat.z = 0
	var localUp = posFlat.normalized()
	look_at(position + Vector3.FORWARD, localUp)
