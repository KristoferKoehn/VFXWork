@tool
extends Node2D

@export var line : Line2D
@export_tool_button("fire")
var button : Callable

@export var small_zaps : GPUParticles2D
@export var big_zaps : GPUParticles2D
@export var target : Sprite2D
@export var ParticleNode : Node2D

@export var line_particles1 : GPUParticles2D
@export var line_particles2 : GPUParticles2D


@export var impact_particles : GPUParticles2D


func _ready() -> void:
	button = emit_zaps
	pass
	
func _process(delta: float) -> void:
	ParticleNode.global_position = target.global_position
	pass

func fire(target_position: Vector2) -> void:
	line.material.set("shader_parameter/alpha", 1.0)
	
	var t : Tween = create_tween()
	t.tween_property(line.material,"shader_parameter/alpha", 0.0, 0.2)
	line.clear_points()
	var dist = (global_position - target.global_position).length()
	var freq = int(dist / 100) + 1
	for p in freq:
		var r = Vector2(randf_range(-29, 20), randf_range(-29, 20))
		var r2 = Vector2(randf_range(-29, 20), randf_range(-29, 20))
		line.add_point(Vector2(p * 100, 15) + r)
		line.add_point(Vector2(p * 100 + 50, -15) + r2)
	
	var rand = randi_range(0, line.points.size() - 1)
	
	line.look_at(target_position)
	
	line_particles1.global_position = line.global_transform * to_global(line.get_point_position(rand))
	line_particles2.global_position = line.global_transform * to_global(line.get_point_position((rand + line.points.size()/ 2) % (line.points.size() - 1)))
	
	impact_particles.global_position = target_position
	impact_particles.look_at(global_position)

func emit_zaps():
	fire(target.global_position)
	small_zaps.emitting = true
	big_zaps.emitting = true
	
	line_particles1.emitting = true
	line_particles2.emitting = true
	
	impact_particles.emitting = true
	pass

func _unhandled_input(event):
	print(event.to_string())

func _input(event):
	print(event.to_string())
