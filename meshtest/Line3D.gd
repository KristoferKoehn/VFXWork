@tool
extends Node3D

@export var points: Array[Vector3] = []
@export var width: float = 0.5
@export var material: Material


var mesh_instance: MeshInstance3D
var mesh: ArrayMesh

func _ready():
	mesh = ArrayMesh.new()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.top_level = true
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

func _process(delta: float) -> void:
	refresh()

func set_points(new_points: Array[Vector3]) -> void:
	points = new_points
	refresh()

func set_material(new_material: Material) -> void:
	material = new_material
	mesh_instance.material_override = material

func refresh() -> void:
	_update_mesh()

func _update_mesh() -> void:
	if points.size() < 2:
		mesh.clear_surfaces()
		return

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices: PackedVector3Array = []
	var uvs: PackedVector2Array = []
	var colors: PackedColorArray = []
	var indices: PackedInt32Array = []

	# 1. Cumulative distance for UVs
	var cumulative_distances: Array[float] = [0.0]
	var total_distance = 0.0
	for i in range(1, points.size()):
		var segment = points[i] - points[i-1]
		var dist = segment.length()
		total_distance += dist
		cumulative_distances.append(total_distance)
	
	if total_distance == 0:
		total_distance = 1.0  # Prevent division by zero

	# 2. Generate vertices
	for i in range(points.size()):
		var pos = points[i]

		# Tangent
		var tangent: Vector3
		if i == points.size() - 1:
			tangent = (points[i] - points[i-1]).normalized()
		else:
			tangent = (points[i+1] - points[i]).normalized()

		# Find perpendiculars
		var up = Vector3.UP
		if abs(tangent.dot(up)) > 0.9:
			up = Vector3(1, 0, 0)
		
		var side = tangent.cross(up).normalized() * width * 0.5
		
		var v0 = pos - side
		var v1 = pos + side
		
		vertices.append(v0)
		vertices.append(v1)

		var uv_y = cumulative_distances[i] / total_distance
		uvs.append(Vector2(0, uv_y))
		uvs.append(Vector2(1, uv_y))

		colors.append(Color(1,1,1,1))
		colors.append(Color(1,1,1,1))

		if i < points.size() - 1:
			var j = i * 2
			indices.append_array([
				j, j+1, j+2,
				j+1, j+3, j+2
			])

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
