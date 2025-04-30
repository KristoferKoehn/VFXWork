@tool
extends Node3D

@export var trail_length: int = 30
@export var trail_width: float = 0.5
@export var trail_color: Color = Color(1, 1, 1, 1)
@export var trail_material: Material
@export var fps: float = 30

const MIN_SEGMENT_LENGTH = 0.01  # Minimum distance to add a new trail point

var trail_points: Array[Dictionary] = []  # Each item is {position: Vector3, age: float}
var POINT_LIFETIME = trail_length / fps  # How long a full trail lives

var time_accumulator := 0.0
var UPDATE_INTERVAL := 1.0 / fps

var line: Line3D

func _ready():
	line = Line3D.new()
	line.width = trail_width
	line.material = trail_material
	line.local_coordinates = false
	add_child(line)

func _process(delta):
	time_accumulator += delta

	while time_accumulator >= UPDATE_INTERVAL:
		if trail_points.size() == 0 or (global_position - trail_points.back()["position"]).length() > MIN_SEGMENT_LENGTH:
			trail_points.append({"position": global_position, "age": 0.0})

		time_accumulator -= UPDATE_INTERVAL

	# Age all points
	for point in trail_points:
		point["age"] += delta

	# Remove old points
	trail_points = trail_points.filter(func(p): return p["age"] < trail_length / fps)

	# Update visual trail
	_update_line()

func _update_line():
	var positions: Array[Vector3] = []
	for point in trail_points:
		positions.append(point["position"])
	line.set_points(positions)
