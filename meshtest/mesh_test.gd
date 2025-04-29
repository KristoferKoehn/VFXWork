@tool
extends Node3D

@export var trail_length: int = 30
@export var trail_width: float = 0.5
@export var trail_color: Color = Color(1, 1, 1, 1)
@export var Trail_Material : Material
@export var fps : float = 30

const MIN_SEGMENT_LENGTH = 0.01  # Adjust as needed

var trail_points: Array[Dictionary] = []  # Each item is {position: Vector3, age: float}
var POINT_LIFETIME = trail_length / fps  # How long a full trail lives (approx.)

var positions: Array[Vector3] = []
var mesh_instance: MeshInstance3D
var mesh: ArrayMesh

func _ready():
	mesh = ArrayMesh.new()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.top_level = true
	mesh_instance.mesh = mesh
	add_child(mesh_instance)

var time_accumulator := 0.0
var UPDATE_INTERVAL := 1.0 / fps  # 30 times per second

func _process(delta):
	time_accumulator += delta
	
	while time_accumulator >= UPDATE_INTERVAL:
		if trail_points.size() == 0 or (global_position - trail_points.back()["position"]).length() > MIN_SEGMENT_LENGTH:
			trail_points.append({"position": global_position, "age": 0.0})
		
		time_accumulator -= UPDATE_INTERVAL
	
	# Always age points every frame, even if no new ones
	for point in trail_points:
		point["age"] += delta
	
	# Remove points that are too old
	trail_points = trail_points.filter(func(p): return p["age"] < POINT_LIFETIME)
	
	_update_trail()


func _update_trail():
	if trail_points.size() < 2:
		return

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices: PackedVector3Array = []
	var uvs: PackedVector2Array = []
	var colors: PackedColorArray = []
	var indices: PackedInt32Array = []

	# Precompute cumulative distances
	var cumulative_distances: Array[float] = [0.0]
	var total_distance = 0.0
	for i in range(1, trail_points.size()):
		var segment = trail_points[i]["position"] - trail_points[i-1]["position"]
		var dist = segment.length()
		total_distance += dist
		cumulative_distances.append(total_distance)

	if total_distance == 0:
		total_distance = 1.0

	# Generate geometry
	for i in range(trail_points.size()):
		var pos = trail_points[i]["position"]
		
		var tangent: Vector3
		if i == trail_points.size() - 1:
			tangent = (trail_points[i]["position"] - trail_points[i-1]["position"]).normalized()
		else:
			tangent = (trail_points[i+1]["position"] - trail_points[i]["position"]).normalized()
		
		var up = Vector3.UP
		if abs(tangent.dot(up)) > 0.9:
			up = Vector3(1, 0, 0)
		
		var side1 = tangent.cross(up).normalized() * trail_width * 0.5
		var side2 = tangent.cross(side1).normalized() * trail_width * 0.5
		
		var v0 = pos - side1
		var v1 = pos + side1
		var v2 = pos - side2
		var v3 = pos + side2
		
		vertices.append(v0)
		vertices.append(v1)
		vertices.append(v2)
		vertices.append(v3)
		
		var uv_y = cumulative_distances[i] / total_distance
		uvs.append(Vector2(0, uv_y))
		uvs.append(Vector2(1, uv_y))
		uvs.append(Vector2(0, uv_y))
		uvs.append(Vector2(1, uv_y))
		
		colors.append(trail_color)
		colors.append(trail_color)
		colors.append(trail_color)
		colors.append(trail_color)
		
		if i < trail_points.size() - 1:
			var j = i * 4
			indices.append_array([
				j, j+1, j+4,
				j+1, j+5, j+4,
				j+2, j+3, j+6,
				j+3, j+7, j+6
			])

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, Trail_Material)
