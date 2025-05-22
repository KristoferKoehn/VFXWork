@tool
extends Node3D

var t : Timer = Timer.new()
@export var trail_mesh : MeshInstance3D
@export var subject_mesh : MeshInstance3D

func _ready() -> void:
	# Positions for each face (4 vertices per face)
	var vertices = PackedVector3Array([
		# Back face (-Z)
		Vector3(-1, -1, -1),
		Vector3( 1, -1, -1),
		Vector3( 1,  1, -1),
		Vector3(-1,  1, -1),

		# Front face (+Z)
		Vector3( 1, -1, 1),
		Vector3(-1, -1, 1),
		Vector3(-1,  1, 1),
		Vector3( 1,  1, 1),

		# Left face (-X)
		Vector3(-1, -1,  1),
		Vector3(-1, -1, -1),
		Vector3(-1,  1, -1),
		Vector3(-1,  1,  1),

		# Right face (+X)
		Vector3(1, -1, -1),
		Vector3(1, -1,  1),
		Vector3(1,  1,  1),
		Vector3(1,  1, -1),

		# Bottom face (-Y)
		Vector3(-1, -1,  1),
		Vector3( 1, -1,  1),
		Vector3( 1, -1, -1),
		Vector3(-1, -1, -1),

		# Top face (+Y)
		Vector3(-1, 1, -1),
		Vector3( 1, 1, -1),
		Vector3( 1, 1,  1),
		Vector3(-1, 1,  1),
	])

	# Indices (two triangles per face)
	var indices = PackedInt32Array([
		0, 1, 2,   2, 3, 0,       # Back
		4, 5, 6,   6, 7, 4,       # Front
		8, 9,10,  10,11, 8,       # Left
	   12,13,14,  14,15,12,       # Right
	   16,17,18,  18,19,16,       # Bottom
	   20,21,22,  22,23,20        # Top
	])

	# Flat normals (one per face, duplicated per vertex)
	var normals = PackedVector3Array([
		Vector3( 0,  0, -1), Vector3( 0,  0, -1), Vector3( 0,  0, -1), Vector3( 0,  0, -1),
		Vector3( 0,  0,  1), Vector3( 0,  0,  1), Vector3( 0,  0,  1), Vector3( 0,  0,  1),
		Vector3(-1,  0,  0), Vector3(-1,  0,  0), Vector3(-1,  0,  0), Vector3(-1,  0,  0),
		Vector3( 1,  0,  0), Vector3( 1,  0,  0), Vector3( 1,  0,  0), Vector3( 1,  0,  0),
		Vector3( 0, -1,  0), Vector3( 0, -1,  0), Vector3( 0, -1,  0), Vector3( 0, -1,  0),
		Vector3( 0,  1,  0), Vector3( 0,  1,  0), Vector3( 0,  1,  0), Vector3( 0,  1,  0),
	])

	# Simple UVs (you can expand for proper mapping)
	var uvs = PackedVector2Array([
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), # back
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), # front
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), # left
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), # right
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), # bottom
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0), # top
	])


	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	subject_mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	add_child(t)
	t.start(0.2)
	var f = func():
		ghost_trail(subject_mesh)
	t.timeout.connect(f)

func _process(delta: float) -> void:
	pass

func ghost_trail(mesh : MeshInstance3D):
	trail_mesh.mesh = mesh.mesh
	trail_mesh.global_transform = mesh.global_transform
	var t = get_tree().create_tween()
	t.tween_property(trail_mesh.material_override, "albedo_color:a", 0.0, 0.15).from(0.5)
	pass
