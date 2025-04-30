@tool
extends Node3D

@export var line : Line3D
@export var target : Node3D
@export var sparks : GPUParticles3D
@export var zap_cloud : GPUParticles3D

@export_tool_button("fire")
var button : Callable

# Called when the node enters the scene tree for the first time.
func _ready():
	button = fire;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func fire():
	line.local_coordinates = true
	line.material.set("shader_parameter/alpha", 1.0)
	
	var t : Tween = create_tween()
	t.tween_property(line.material,"shader_parameter/alpha", 0.0, 0.1)
	line.clear_points()
	var dist = (global_position - target.global_position).length()
	var freq = int(dist / 10) + 1
	for p in (freq - 1):
		var r = Vector3(randf_range(-6, 6), randf_range(-6, 6), 0)
		var r2 = Vector3(randf_range(-6, 6), randf_range(-6, 6), 0)
		line.add_point(Vector3(0, 0, -p * 10) + r)
		line.add_point(Vector3(0, 0, -p * 10 - 5) + r2)
		
	line.add_point(Vector3(0, 0, -(target.global_position - global_position).length()))
	
	line.look_at(target.global_position)
	zap_cloud.global_position = target.global_position
	sparks.global_position = target.global_position
	sparks.look_at(global_position)
	
	zap_cloud.emitting = true
	sparks.emitting = true
	pass
