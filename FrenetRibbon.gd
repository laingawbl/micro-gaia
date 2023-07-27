@tool
extends MeshInstance3D

enum RibbonType { NORMAL, BITANGENT }

@export var SegCount: int = 4:
	set = _set_SegCount,
	get = _get_SegCount
@export var SplineTension: float = 0:
	set = _set_SplineTension,
	get = _get_SplineTension
@export var Points: Array[Vector3]:
	set = _set_Points,
	get = _get_Points
@export var SplineMat: Material:
	set = _set_SplineMat,
	get = _get_SplineMat
@export var SplineTangentType: HermiteCubic.TangentType = HermiteCubic.TangentType.CATMULL_ROM:
	set = _set_SplineTangentType,
	get = _get_SplineTangentType
@export var StartHandle: Vector3 = Vector3.ZERO:
	set = _set_SplineStartHandle,
	get = _get_SplineStartHandle
@export var EndHandle: Vector3 = Vector3.ZERO:
	set = _set_SplineEndHandle,
	get = _get_SplineEndHandle
@export var Ribbon: RibbonType:
	set = _set_Ribbon,
	get = _get_Ribbon

@export var UseVertexColours: bool = false:
	set = _set_UseVertexColours,
	get = _get_UseVertexColours
@export var UniformUVSampling: bool = false:
	set = _set_UniformUVSampling,
	get = _get_UniformUVSampling
@export var VertexColours: Gradient:
	set = _set_VertexColours,
	get = _get_VertexColours

var processed_once: bool = false


func _set_SegCount(p) -> void:
	SegCount = max(1, p)
	if processed_once:
		remesh()


func _get_SegCount() -> int:
	return SegCount


func _set_SplineTension(p) -> void:
	SplineTension = clamp(p, 0.0, 1.0)
	if processed_once:
		remesh()


func _get_SplineTension() -> float:
	return SplineTension


func _set_SplineTangentType(p) -> void:
	SplineTangentType = p
	if processed_once:
		remesh()


func _get_SplineTangentType() -> HermiteCubic.TangentType:
	return SplineTangentType


func _set_Points(p) -> void:
	Points = p
	if processed_once:
		remesh()


func _get_Points() -> Array[Vector3]:
	return Points


func _set_SplineMat(p) -> void:
	SplineMat = p
	if processed_once:
		mesh.surface_set_material(0, SplineMat)


func _get_SplineMat() -> Material:
	return SplineMat


func _set_UseVertexColours(p) -> void:
	UseVertexColours = p
	if SplineMat is StandardMaterial3D:
		SplineMat.vertex_color_use_as_albedo = UseVertexColours
		mesh.surface_set_material(0, SplineMat)
	if processed_once and UseVertexColours and VertexColours != null:
		remesh()


func _get_UseVertexColours() -> bool:
	return UseVertexColours


func _set_UniformUVSampling(p) -> void:
	UniformUVSampling = p
	if processed_once:
		remesh()


func _get_UniformUVSampling() -> bool:
	return UniformUVSampling


func _set_VertexColours(p) -> void:
	VertexColours = p
	if processed_once and UseVertexColours:
		remesh()


func _get_VertexColours() -> Gradient:
	return VertexColours


func _set_SplineStartHandle(p) -> void:
	StartHandle = p
	if processed_once:
		remesh()


func _get_SplineStartHandle() -> Vector3:
	return StartHandle


func _set_SplineEndHandle(p) -> void:
	EndHandle = p
	if processed_once:
		remesh()


func _get_SplineEndHandle() -> Vector3:
	return EndHandle


func _set_Ribbon(p) -> void:
	Ribbon = p
	if processed_once:
		remesh()


func _get_Ribbon() -> RibbonType:
	return Ribbon


func remesh():
	var hc = HermiteCubic.new()
	var strip_verts: Array[Vector3] = []
	(
		hc
		. build_hermite_spline(
			Points,
			SegCount,
			StartHandle,
			EndHandle,
			SplineTangentType,
			UniformUVSampling,
			SplineTension
		)
	)

	for k in range(len(hc.vert_list)):
		var v = hc.vert_list[k]
		var n = hc.normal_list[k].normalized()
		if n.angle_to(Vector3.UP) > PI / 2.0:
			n = -n
		match Ribbon:
			RibbonType.NORMAL:
				strip_verts.append(v + n)
				strip_verts.append(v - n)
			RibbonType.BITANGENT:
				var tang: Vector3
				var lh: int = len(hc.vert_list)
				if k == 1:
					tang = hc.vert_list[0].direction_to(hc.vert_list[1])
				elif k == lh - 1:
					tang = hc.vert_list[lh - 2].direction_to(hc.vert_list[lh - 1])
				else:
					tang = (
						(hc.vert_list[k - 1].direction_to(v) + v.direction_to(hc.vert_list[k + 1]))
						* 0.5
					)
				var bn = tang.cross(n)
				strip_verts.append(v + bn)
				strip_verts.append(v - bn)
			_:
				pass

	var surf = SurfaceTool.new()

	surf.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	for v in strip_verts:
		surf.add_vertex(v)

	surf.index()
	mesh = surf.commit()
	mesh.surface_set_material(0, SplineMat)


func _enter_tree():
	remesh()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	processed_once = true
