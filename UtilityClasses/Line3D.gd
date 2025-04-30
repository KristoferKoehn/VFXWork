@tool
extends Node3D
class_name Line3D

@export var points: Array[Vector3] = []
@export var width: float = 0.5
@export var material: Material
@export var local_coordinates: bool = true

var mesh_instance := MeshInstance3D.new()
var mesh := ArrayMesh.new()

func _ready():
	mesh_instance.top_level = true
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

func _process(_delta):
	refresh()

func add_point(pos : Vector3) -> void:
	points.append(pos)
	refresh()

func set_points(new_points: Array[Vector3]) -> void:
	points = new_points
	refresh()

func clear_points() -> void:
	points = []
	refresh()

func set_material(new_material: Material) -> void:
	material = new_material
	mesh_instance.material_override = material

func refresh():
	_update_mesh()

func _build_frames(points: Array[Vector3]) -> Array:
	var frames: Array = []
	if points.size() < 2:
		return frames

	var tangent = (points[1] - points[0]).normalized()
	var normal = tangent.cross(Vector3.UP).normalized()
	if normal.length() < 0.01:
		normal = tangent.cross(Vector3.FORWARD).normalized()
	var binormal = tangent.cross(normal).normalized()

	var frame = Basis(binormal, normal, tangent)
	frames.append(frame)

	for i in range(1, points.size()):
		var next_tangent = (points[i] - points[i - 1]).normalized()
		var rot_axis = tangent.cross(next_tangent)
		var angle = acos(clamp(tangent.dot(next_tangent), -1.0, 1.0))

		if rot_axis.length_squared() > 1e-6 and angle != 0.0:
			frame = frame.rotated(rot_axis.normalized(), angle)

		frames.append(frame)
		tangent = next_tangent

	return frames

func _update_mesh():
	var pts = points
	if pts.size() < 2:
		mesh.clear_surfaces()
		return

	var frames = _build_frames(pts)
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idxs := PackedInt32Array()

	var dists := [0.0]
	for i in range(1, pts.size()):
		dists.append(dists[-1] + (pts[i] - pts[i - 1]).length())
	var total_len : float = dists[-1] if dists[-1] > 0.0 else 1.0

	for i in pts.size():
		var pos = pts[i] if !local_coordinates else global_transform * pts[i]
		var frame = frames[i]
		var side = frame.x * width * 0.5
		var cross = frame.y * width * 0.5

		var v = [
			pos - side,
			pos + side,
			pos - cross,
			pos + cross
		]
		for p in v:
			verts.append(p)
		var uvy = dists[i] / total_len
		uvs.append(Vector2(0, uvy))
		uvs.append(Vector2(1, uvy))
		uvs.append(Vector2(0, uvy))
		uvs.append(Vector2(1, uvy))
		for x in range(4):
			cols.append(Color.WHITE)

		if i < pts.size() - 1:
			var j = i * 4
			idxs.append_array([j, j+1, j+4, j+1, j+5, j+4])
			idxs.append_array([j+2, j+3, j+6, j+3, j+7, j+6])

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idxs

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
