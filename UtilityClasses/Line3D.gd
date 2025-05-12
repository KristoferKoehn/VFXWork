@tool
extends MeshInstance3D
class_name Line3D
@export var line_width : float = 1.0
@export var points : Array[Vector3]
var uv_y : Array[float]

func _ready() -> void:
	mesh = ArrayMesh.new()
	pass

func _process(delta: float) -> void:
	_update_mesh()

func _update_mesh():
	if points.size() < 2:
		return
	
	var Camera : Camera3D
	if Engine.is_editor_hint():
		Camera = EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	else:
		Camera = get_viewport().get_camera_3d()
	
	Camera.projection
	var dir = Camera.global_position
	
	var vertices : PackedVector3Array
	var UVs : PackedVector2Array
	var idxs : PackedInt32Array
	
	for i in range(0,points.size()-1):
		var UV_y_cumulative : float = 0.0
		var SegmentRay = (points[i] - points[i+1]).normalized()
		var whisker_0 = (dir - points[i]).cross(SegmentRay).normalized() * line_width * 0.5
		var whisker_1 = (dir - points[i]).cross(SegmentRay).normalized() * line_width  * 0.5
		#print(whisker_0 + points[i], -whisker_0 + points[i])
		UVs.append_array([ Vector2(0, UV_y_cumulative), Vector2(1, UV_y_cumulative),
							Vector2(1,UV_y_cumulative + (points[i] - points[i + 1]).length()),
							Vector2(0, UV_y_cumulative + (points[i] - points[i + 1]).length())])
		UV_y_cumulative += (points[i] - points[i + 1]).length()
		idxs.append_array([
			vertices.size() + 0 ,vertices.size() + 1, vertices.size() + 2,
			vertices.size() + 0 ,vertices.size() + 2, vertices.size() + 3])
		vertices.append_array(
			[-whisker_0 + points[i], whisker_0+ points[i], 
			whisker_1 + points[i + 1], -whisker_1 + points[i + 1]])
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_TEX_UV] = UVs
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = idxs
	
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

# create a plane by taking the average of the *axes* of the two segments
# extrude the point along the axis of the segment until the value = 0
func add_points(points : Array[Vector3]):
	self.points = points
	_update_mesh()

func clear_points():
	points = []
